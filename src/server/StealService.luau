-- StealService: the threat that makes the game tense. Hold E on a brainrot
-- in someone else's base to snatch it — unless their base lock is up — then
-- carry it home on your head. The victim can slap you with the Slap tool to
-- knock it loose, and it waddles back to its old base. The lock button buys
-- sixty seconds of safety on a two-minute cooldown.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local PlayerState = require(script.Parent.PlayerState)
local PlotService = require(script.Parent.PlotService)
local EconomyService = require(script.Parent.EconomyService)
local RaiderService = require(script.Parent.RaiderService)
local Remotes = require(script.Parent.Remotes)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StealService = {}

-- A steal prompt lives on every brainrot standing on a plot. It is armed
-- only for players who do not own that plot, and only while the base is
-- unlocked.
function StealService.attachStealPrompt(owned, plot)
	local model = owned.model
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = "Steal"
	prompt.ObjectText = owned.def.name
	prompt.HoldDuration = Config.STEAL_HOLD_SECONDS
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		StealService.stealBrainrot(player, owned, plot)
	end)
end

function StealService.stealBrainrot(player, owned, plot)
	local state = PlayerState.get(player)
	if not state or state.carrying then
		return
	end
	if plot.owner == player then
		return
	end
	local ownerState = PlayerState.get(plot.owner)
	if ownerState and PlayerState.isBaseLocked(ownerState) then
		EconomyService.notify(player, "That base is LOCKED!")
		return
	end
	if owned.slotIndex == nil then
		return
	end
	PlotService.removeFromSlot(plot, owned.slotIndex)
	if ownerState then
		for i, item in ipairs(ownerState.owned) do
			if item == owned then
				table.remove(ownerState.owned, i)
				break
			end
		end
		EconomyService.pushCashUpdate(ownerState)
	end
	local prompt = owned.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt:Destroy()
	end
	state.carrying = {
		def = owned.def,
		mutation = owned.mutation,
		mutationMult = owned.mutationMult,
		model = owned.model,
		fromPlayer = plot.owner,
	}
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = humanoid.WalkSpeed * Config.CARRY_SPEED_MULT
	end
	EconomyService.notify(player, "STOLEN! Run it home to your base!")
	if plot.owner then
		EconomyService.notify(plot.owner, player.DisplayName .. " stole your " .. owned.def.name .. "! Slap them!")
	end
end

-- Carrying a stolen brainrot home: it rides above your head, and the moment
-- you step onto your own plot it drops into your first free slot.
function StealService.stepCarrying()
	for _, state in pairs(PlayerState.players) do
		local carrying = state.carrying
		if carrying and carrying.model.Parent then
			local character = state.player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root then
				carrying.model:PivotTo(root.CFrame * CFrame.new(0, 4.5, 0))
			end
			local plot = PlotService.getPlotOf(state.player)
			if plot and root and PlotService.isPointInPlot(plot, root.Position) then
				StealService.depositStolen(state, plot)
			end
		end
	end
end

function StealService.depositStolen(state, plot)
	local carrying = state.carrying
	if not carrying then
		return
	end
	local slotIndex = PlotService.findFreeSlot(plot)
	if not slotIndex then
		EconomyService.notify(state.player, "Your base is FULL — the stolen brainrot got away!")
		carrying.model:Destroy()
		state.carrying = nil
		StealService.restoreWalkSpeed(state)
		return
	end
	local owned = { def = carrying.def, mutation = carrying.mutation, mutationMult = carrying.mutationMult, model = carrying.model }
	table.insert(state.owned, owned)
	PlotService.placeOnSlot(plot, slotIndex, owned)
	StealService.attachStealPrompt(owned, plot)
	state.carrying = nil
	StealService.restoreWalkSpeed(state)
	EconomyService.pushCashUpdate(state)
	EconomyService.notify(state.player, "Stashed " .. owned.def.name .. " in your base! +" .. BrainrotData.formatMoney(owned.def.income * owned.mutationMult) .. "/s")
end

-- A slap knocks the brainrot loose: it waddles back to the base it came
-- from, if that base still has a free slot.
function StealService.slapPlayer(slapper, victim)
	local victimState = PlayerState.get(victim)
	if not victimState or not victimState.carrying then
		return false
	end
	local carrying = victimState.carrying
	victimState.carrying = nil
	StealService.restoreWalkSpeed(victimState)
	local fromPlayer = carrying.fromPlayer
	local fromState = fromPlayer and PlayerState.get(fromPlayer)
	local fromPlot = fromPlayer and PlotService.getPlotOf(fromPlayer)
	if fromState and fromPlot then
		local slotIndex = PlotService.findFreeSlot(fromPlot)
		if slotIndex then
			local owned = { def = carrying.def, mutation = carrying.mutation, mutationMult = carrying.mutationMult, model = carrying.model }
			table.insert(fromState.owned, owned)
			PlotService.placeOnSlot(fromPlot, slotIndex, owned)
			StealService.attachStealPrompt(owned, fromPlot)
			EconomyService.pushCashUpdate(fromState)
			EconomyService.notify(fromPlayer, "Your " .. owned.def.name .. " is back home!")
		else
			carrying.model:Destroy()
		end
	else
		carrying.model:Destroy()
	end
	EconomyService.notify(victim, "SLAPPED! You dropped the brainrot!")
	EconomyService.notify(slapper, "Nice slap! You saved the brainrot!")
	return true
end

function StealService.restoreWalkSpeed(state)
	local character = state.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
	end
end

-- The Slap tool: every player gets one on spawn. Click a nearby thief to
-- knock their stolen brainrot loose.
function StealService.giveSlapTool(player)
	local backpack = player:WaitForChild("Backpack")
	local tool = Instance.new("Tool")
	tool.Name = "Slap"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 0.6, 2.2)
	handle.Color = Color3.fromRGB(255, 200, 150)
	handle.Material = Enum.Material.SmoothPlastic
	handle.Parent = tool
	tool.Parent = backpack
	tool.Activated:Connect(function()
		local state = PlayerState.get(player)
		if not state then
			return
		end
		if os.clock() - state.lastSlapAt < Config.SLAP_COOLDOWN then
			return
		end
		state.lastSlapAt = os.clock()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			return
		end
		local bestVictim = nil
		local bestDistance = Config.SLAP_RANGE
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= player then
				local otherState = PlayerState.get(other)
				local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if otherState and otherState.carrying and otherRoot then
					local distance = (otherRoot.Position - root.Position).Magnitude
					if distance <= bestDistance then
						bestDistance = distance
						bestVictim = other
					end
				end
			end
		end
		if bestVictim then
			StealService.slapPlayer(player, bestVictim)
		elseif RaiderService.trySlapRaider(player, root.Position) then
			-- The raider took the hit; its own handler did the rest.
		end
	end)
end

function StealService.init()
	Remotes.LockBase.OnServerEvent:Connect(function(player)
		local state = PlayerState.get(player)
		if not state then
			return
		end
		if not PlayerState.canLockBase(state) then
			local wait = math.ceil(state.lockCooldownUntil - os.clock())
			EconomyService.notify(player, "Base lock recharging — " .. wait .. "s left")
			return
		end
		PlayerState.lockBase(state)
		EconomyService.notify(player, "Base LOCKED for 60s! Nobody can steal from you")
	end)
	RunService.Heartbeat:Connect(function()
		StealService.stepCarrying()
	end)
end

return StealService
