-- init: the server entry point. Builds the world, starts every service, and
-- hands each joining player a plot, starting cash and a Slap tool. When a
-- player leaves, their plot is freed and their stolen goods go with them.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local WorldBuilder = require(script.Parent.WorldBuilder)
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlotService = require(script.Parent.PlotService)
local PlayerState = require(script.Parent.PlayerState)
local Remotes = require(script.Parent.Remotes)
local EconomyService = require(script.Parent.EconomyService)
local ConveyorService = require(script.Parent.ConveyorService)
local StealService = require(script.Parent.StealService)
local RaiderService = require(script.Parent.RaiderService)
local EventService = require(script.Parent.EventService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local MonetizationService = require(script.Parent.MonetizationService)
local DailyRewardService = require(script.Parent.DailyRewardService)

local world = WorldBuilder.buildWorld()
PlotService.init(world)
EconomyService.init()
StealService.init()
RaiderService.init()
EventService.init(world)
LeaderboardService.init()
MonetizationService.init()
DailyRewardService.init()
ConveyorService.startSpawner()

-- Teleport button: drops the player ON their own plot, facing the first
-- brainrot on a slot, so the base is impossible to miss.
Remotes.TeleportToBase.OnServerEvent:Connect(function(player)
	local plot = PlotService.getPlotOf(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not plot or not root then
		return
	end
	local targetPos = plot.center + Vector3.new(0, 3, 0)
	for _, slot in ipairs(plot.slots) do
		if slot.occupiedBy then
			targetPos = Vector3.new(slot.position.X, 3, slot.position.Z)
			break
		end
	end
	root.CFrame = CFrame.lookAt(plot.center + Vector3.new(0, 5, 0), targetPos)
end)

-- A new player joins with one free Common already earning on their plot,
-- so the first minute is never spent waiting. Uses the same pieces as a
-- purchase (model on a slot, steal prompt, cash update), just free.
local function grantStarterBrainrot(player, state, plot)
	if not Config.STARTER_BRAINROT_ENABLED then
		return
	end
	if not plot then
		return
	end
	local slotIndex = PlotService.findFreeSlot(plot)
	if not slotIndex then
		return
	end
	local def = BrainrotData.rollCharacter(Config.STARTER_BRAINROT_RARITY)
	local model = BrainrotFactory.buildBrainrotModel(def, "None", 1, plot.slots[slotIndex].position)
	model.Parent = Workspace
	local owned = { def = def, mutation = "None", mutationMult = 1, model = model }
	table.insert(state.owned, owned)
	PlotService.placeOnSlot(plot, slotIndex, owned)
	StealService.attachStealPrompt(owned, plot)
	EconomyService.notify(player, "Welcome! Your free " .. def.name .. " is earning +" .. BrainrotData.formatMoney(def.income) .. "/s!")
end

local function onPlayerAdded(player)
	local state = PlayerState.newPlayer(player)
	local plot = PlotService.assignPlot(player)
	if not plot then
		EconomyService.notify(player, "All bases are taken — you are spectating this round")
	else
		grantStarterBrainrot(player, state, plot)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		StealService.giveSlapTool(player)
		EconomyService.pushCashUpdate(state)
	end)
	EconomyService.pushCashUpdate(state)
end

local function onPlayerRemoving(player)
	local state = PlayerState.get(player)
	if state and state.carrying then
		-- A thief who leaves drops the loot: it returns to its old base.
		local carrying = state.carrying
		local fromPlot = carrying.fromPlayer and PlotService.getPlotOf(carrying.fromPlayer)
		local fromState = carrying.fromPlayer and PlayerState.get(carrying.fromPlayer)
		if fromPlot and fromState then
			local slotIndex = PlotService.findFreeSlot(fromPlot)
			if slotIndex then
				local owned = { def = carrying.def, mutation = carrying.mutation, mutationMult = carrying.mutationMult, model = carrying.model }
				table.insert(fromState.owned, owned)
				PlotService.placeOnSlot(fromPlot, slotIndex, owned)
				StealService.attachStealPrompt(owned, fromPlot)
			else
				carrying.model:Destroy()
			end
		else
			carrying.model:Destroy()
		end
	end
	PlotService.releasePlot(player)
	PlayerState.removePlayer(player)
	LeaderboardService.broadcastLeaderboard()
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

print("Steal a Brainrot — Meme Madness is live: 8 plots, conveyor running, events armed.")
