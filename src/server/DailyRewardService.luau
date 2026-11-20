-- DailyRewardService: the lightest retention hook that works. A player who
-- comes back on a new day gets cash that grows with their streak (day 1 =
-- base cash, day 7 = base x 7). The streak lives in a DataStore when Roblox
-- allows it; every DataStore call is pcall-guarded, and when the store is
-- unreachable (Studio without API access, an unpublished place) the reward
-- still pays once per session instead of crashing the game. One missed day
-- resets the streak to 1.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local EconomyService = require(script.Parent.EconomyService)
local Remotes = require(script.Parent.Remotes)

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local DailyRewardService = {}

local function todayNumber()
	return math.floor(os.time() / 86400)
end

local function loadDailyData(player)
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(Config.DAILY_DATASTORE_NAME)
	end)
	if not ok or not store then
		return nil
	end
	local okRead, data = pcall(function()
		return store:GetAsync("daily_" .. player.UserId)
	end)
	if not okRead then
		return nil
	end
	return store, data
end

local function saveDailyData(store, player, data)
	pcall(function()
		store:SetAsync("daily_" .. player.UserId, data)
	end)
end

-- Grant today's reward once, on join. Never grants twice in one session.
function DailyRewardService.grantDailyReward(player)
	local state = PlayerState.get(player)
	if not state or state.dailyClaimedToday then
		return
	end
	local today = todayNumber()
	local store, saved = loadDailyData(player)
	local streak = 1
	if saved and type(saved) == "table" then
		if saved.lastDay == today then
			-- Already claimed today (previous session): no double pay.
			state.lastDailyDay = today
			state.dailyStreak = saved.streak or 1
			state.dailyClaimedToday = true
			Remotes.DailyReward:FireClient(player, state.dailyStreak, 0, true)
			return
		elseif saved.lastDay == today - 1 then
			streak = math.min((saved.streak or 0) + 1, Config.DAILY_REWARD_STREAK_MAX)
		end
	end
	local reward = Config.DAILY_REWARD_BASE_CASH * streak
	state.cash += reward
	state.lastDailyDay = today
	state.dailyStreak = streak
	state.dailyClaimedToday = true
	if store then
		saveDailyData(store, player, { lastDay = today, streak = streak })
	end
	EconomyService.pushCashUpdate(state)
	Remotes.DailyReward:FireClient(player, streak, reward, false)
	EconomyService.notify(player, "Daily reward! Day " .. streak .. ": +" .. reward .. " cash! Come back tomorrow for more!")
end

function DailyRewardService.init()
	Players.PlayerAdded:Connect(function(player)
		-- Wait one beat so PlayerState exists before the grant.
		task.wait(1)
		DailyRewardService.grantDailyReward(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(1)
			DailyRewardService.grantDailyReward(player)
		end)
	end
end

return DailyRewardService
