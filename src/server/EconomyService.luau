-- EconomyService: the money. Every second each player earns the sum of their
-- brainrots' income, times their rebirth multiplier and any running event
-- multiplier. It also handles rebirths: pay the price, lose everything, keep
-- a permanent income boost.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent.PlayerState)
local PlotService = require(script.Parent.PlotService)
local Remotes = require(script.Parent.Remotes)

local EconomyService = {}
EconomyService.eventMult = 1 -- set to 2 by the Golden Hour event

function EconomyService.incomePerSecond(state)
	return PlayerState.baseIncomePerSecond(state) * state.incomeMult * state.passMult * EconomyService.eventMult
end

function EconomyService.pushCashUpdate(state)
	local player = state.player
	if player and player.Parent then
		-- The HUD shows the total multiplier (rebirth x gamepass) so what
		-- the player sees matches what they earn.
		Remotes.CashUpdate:FireClient(player, math.floor(state.cash), EconomyService.incomePerSecond(state), state.rebirths, state.incomeMult * state.passMult)
	end
end

function EconomyService.notify(player, text)
	if player and player.Parent then
		Remotes.Notify:FireClient(player, text)
	end
end

-- One income tick for every player in the game.
function EconomyService.tickIncome()
	for _, state in pairs(PlayerState.players) do
		local gain = EconomyService.incomePerSecond(state) * Config.INCOME_TICK
		state.cash += gain
		EconomyService.pushCashUpdate(state)
	end
end

function EconomyService.startIncomeLoop()
	task.spawn(function()
		while true do
			task.wait(Config.INCOME_TICK)
			EconomyService.tickIncome()
		end
	end)
end

-- Rebirth: pay a growing price, lose your cash and brainrots, gain +25%
-- income forever. The brainrots walk off the plot and despawn.
function EconomyService.rebirthPlayer(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local cost = PlayerState.rebirthCost(state)
	if state.cash < cost then
		EconomyService.notify(player, "Rebirth needs " .. BrainrotData.formatMoney(cost) .. " — you have " .. BrainrotData.formatMoney(state.cash))
		return
	end
	local plot = PlotService.getPlotOf(player)
	if plot then
		for _, slot in ipairs(plot.slots) do
			if slot.occupiedBy and slot.occupiedBy.model then
				slot.occupiedBy.model:Destroy()
			end
			slot.occupiedBy = nil
		end
	end
	state.owned = {}
	state.cash = 0
	state.rebirths += 1
	state.incomeMult = 1 + state.rebirths * Config.REBIRTH_MULT_PER_LEVEL
	EconomyService.pushCashUpdate(state)
	EconomyService.notify(player, "REBIRTH " .. state.rebirths .. "! Income x" .. string.format("%.2f", state.incomeMult) .. " forever")
end

function EconomyService.init()
	Remotes.Rebirth.OnServerEvent:Connect(function(player)
		EconomyService.rebirthPlayer(player)
	end)
	EconomyService.startIncomeLoop()
end

return EconomyService
