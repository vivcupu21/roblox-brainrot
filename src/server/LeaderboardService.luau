-- LeaderboardService: ranks every player by cash and pushes the top list to
-- all clients every few seconds, so the race for first place is always
-- visible on screen.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local Remotes = require(script.Parent.Remotes)

local LeaderboardService = {}

function LeaderboardService.broadcastLeaderboard()
	local rows = {}
	for _, state in pairs(PlayerState.players) do
		if state.player and state.player.Parent then
			-- VIPs get a star next to their name on the board.
			table.insert(rows, { name = state.player.DisplayName, cash = math.floor(state.cash), vip = state.isVip })
		end
	end
	table.sort(rows, function(a, b)
		return a.cash > b.cash
	end)
	while #rows > Config.LEADERBOARD_SIZE do
		table.remove(rows)
	end
	Remotes.LeaderboardUpdate:FireAllClients(rows)
end

function LeaderboardService.init()
	task.spawn(function()
		while true do
			task.wait(Config.LEADERBOARD_REFRESH)
			LeaderboardService.broadcastLeaderboard()
		end
	end)
end

return LeaderboardService
