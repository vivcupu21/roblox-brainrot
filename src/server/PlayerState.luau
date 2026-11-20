-- PlayerState: the single place all per-player game state lives. Every service
-- reads and writes through this module, so there is one source of truth for a
-- player's cash, brainrots, plot, rebirths and base lock.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local PlayerState = {}
PlayerState.players = {} -- [Player] = state table

function PlayerState.newPlayer(player)
	local state = {
		player = player,
		cash = Config.START_CASH,
		rebirths = 0,
		incomeMult = 1, -- rebirth multiplier
		passMult = 1, -- gamepass multiplier (2x Cash, VIP); set by MonetizationService
		hasDoubleCash = false,
		isVip = false,
		plotId = nil,
		owned = {}, -- list of { def, mutation, mutationMult, model, slotIndex }
		carrying = nil, -- { def, mutation, mutationMult, model, fromPlayer, fromSlot } or nil
		lockUntil = 0,
		lockCooldownUntil = 0,
		lastSlapAt = 0,
		-- Daily reward: day number (days since epoch) of the last claim and
		-- the current streak. DailyRewardService fills these in on join.
		lastDailyDay = 0,
		dailyStreak = 0,
		dailyClaimedToday = false,
	}
	PlayerState.players[player] = state
	return state
end

function PlayerState.get(player)
	return PlayerState.players[player]
end

function PlayerState.removePlayer(player)
	PlayerState.players[player] = nil
end

-- Total money per second from everything this player owns, before the
-- player's own multipliers (rebirth, events).
function PlayerState.baseIncomePerSecond(state)
	local total = 0
	for _, owned in ipairs(state.owned) do
		total += owned.def.income * owned.mutationMult
	end
	return total
end

function PlayerState.isBaseLocked(state)
	return os.clock() < state.lockUntil
end

function PlayerState.canLockBase(state)
	return os.clock() >= state.lockCooldownUntil
end

function PlayerState.lockBase(state)
	state.lockUntil = os.clock() + Config.BASE_LOCK_SECONDS
	state.lockCooldownUntil = os.clock() + Config.BASE_LOCK_COOLDOWN
end

function PlayerState.rebirthCost(state)
	return Config.REBIRTH_BASE_COST * (state.rebirths + 1) ^ Config.REBIRTH_COST_EXPONENT
end

-- Combined gamepass multiplier for one player, read from
-- Config.MONETIZATION so a price or multiplier change is one config edit.
function PlayerState.recomputePassMult(state)
	local mult = 1
	for _, pass in ipairs(Config.MONETIZATION.gamepasses) do
		if pass.id == "doubleCash" and state.hasDoubleCash then
			mult *= pass.incomeMult
		elseif pass.id == "vip" and state.isVip then
			mult *= pass.incomeMult
		end
	end
	state.passMult = mult
	return mult
end

return PlayerState
