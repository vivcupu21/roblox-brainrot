-- ConveyorService: the heart of the game loop. Brainrots roll off the spawn
-- gate, walk down the central conveyor, and despawn at the far end. A player
-- who holds E on one buys it — if they can afford it and have a free slot —
-- and it walks over to their base and starts earning.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)
local PlotService = require(script.Parent.PlotService)
local EconomyService = require(script.Parent.EconomyService)
local StealService = require(script.Parent.StealService)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ConveyorService = {}
ConveyorService.walking = {} -- list of { model, def, mutation, mutationMult }
ConveyorService.spawnIntervalMult = 1 -- halved by the Brainrot Rain event
ConveyorService.mythicBoost = false -- raised by the Brainrot Rain event

local function attachBuyPrompt(model, def, mutation, mutationMult)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy"
	prompt.ObjectText = def.name .. " — " .. BrainrotData.formatMoney(def.cost)
	prompt.HoldDuration = Config.STEAL_HOLD_SECONDS
	prompt.MaxActivationDistance = 25
	prompt.RequiresLineOfSight = false
	prompt.Parent = model.PrimaryPart
	prompt.Triggered:Connect(function(player)
		ConveyorService.buyBrainrot(player, model, def, mutation, mutationMult)
	end)
	-- Backup: clicking the brainrot buys it too, in case the prompt UI
	-- never renders for a player. buyBrainrot guards double-buys.
	local clicker = Instance.new("ClickDetector")
	clicker.MaxActivationDistance = 25
	clicker.MouseClick:Connect(function(player)
		ConveyorService.buyBrainrot(player, model, def, mutation, mutationMult)
	end)
	clicker.Parent = model.PrimaryPart
end

-- options: { position (Vector3), minRarity (number), forceMutation (bool) }.
-- Events use the overrides (a meteor strike drops a rare mutated brainrot
-- where it lands); the normal spawner calls it with no options.
function ConveyorService.spawnBrainrot(options)
	if #ConveyorService.walking >= Config.MAX_CONVEYOR_BRAINROTS then
		return
	end
	options = options or {}
	local rarityIndex = BrainrotData.rollRarity(ConveyorService.mythicBoost)
	if options.minRarity and rarityIndex < options.minRarity then
		rarityIndex = options.minRarity
	end
	local def = BrainrotData.rollCharacter(rarityIndex)
	local mutation, mutationMult = BrainrotData.rollMutation()
	if options.forceMutation and mutation == "None" then
		mutation, mutationMult = "Gold", 2
	end
	local position = options.position or Vector3.new(Config.CONVEYOR_SPAWN_X, 1, Config.CONVEYOR_Z)
	local model = BrainrotFactory.buildBrainrotModel(def, mutation, mutationMult, position)
	model.Parent = Workspace
	attachBuyPrompt(model, def, mutation, mutationMult)
	table.insert(ConveyorService.walking, {
		model = model,
		def = def,
		mutation = mutation,
		mutationMult = mutationMult,
	})
end

-- Walk every conveyor brainrot one step toward +X, and despawn the ones that
-- reached the far end. Runs on Heartbeat so the walk is smooth.
function ConveyorService.stepWalking(dt)
	local i = 1
	while i <= #ConveyorService.walking do
		local entry = ConveyorService.walking[i]
		local model = entry.model
		if not model.Parent then
			table.remove(ConveyorService.walking, i)
		else
			local pivot = model:GetPivot()
			local nextX = pivot.Position.X + Config.CONVEYOR_WALK_SPEED * dt
			if nextX >= Config.CONVEYOR_END_X then
				model:Destroy()
				table.remove(ConveyorService.walking, i)
			else
				model:PivotTo(CFrame.new(nextX, pivot.Position.Y, Config.CONVEYOR_Z) * CFrame.Angles(0, math.pi / 2, 0))
				i += 1
			end
		end
	end
end

function ConveyorService.buyBrainrot(player, model, def, mutation, mutationMult)
	local state = PlayerState.get(player)
	if not state or not model.Parent then
		return
	end
	-- The brainrot may already be gone (bought by someone a frame earlier).
	local stillWalking = false
	for _, entry in ipairs(ConveyorService.walking) do
		if entry.model == model then
			stillWalking = true
			break
		end
	end
	if not stillWalking then
		return
	end
	if state.cash < def.cost then
		EconomyService.notify(player, "Need " .. BrainrotData.formatMoney(def.cost) .. " for " .. def.name)
		return
	end
	local plot = PlotService.getPlotOf(player)
	if not plot then
		EconomyService.notify(player, "No base yet — wait a moment and try again")
		return
	end
	local slotIndex = PlotService.findFreeSlot(plot)
	if not slotIndex then
		EconomyService.notify(player, "Your base is FULL! Sell the idea of a rebirth or make room")
		return
	end
	state.cash -= def.cost
	for i, entry in ipairs(ConveyorService.walking) do
		if entry.model == model then
			table.remove(ConveyorService.walking, i)
			break
		end
	end
	local prompt = model.PrimaryPart:FindFirstChild("BuyPrompt")
	if prompt then
		prompt:Destroy()
	end
	local owned = { def = def, mutation = mutation, mutationMult = mutationMult, model = model }
	table.insert(state.owned, owned)
	PlotService.placeOnSlot(plot, slotIndex, owned)
	StealService.attachStealPrompt(owned, plot)
	EconomyService.pushCashUpdate(state)
	-- Instant feedback: what you bought, what it cost, and your new income
	-- rate — so the first purchase feels like a win, not a quiet deduction.
	EconomyService.notify(player, "Bought " .. def.name .. " for " .. BrainrotData.formatMoney(def.cost) .. "! Now earning +" .. BrainrotData.formatMoney(EconomyService.incomePerSecond(state)) .. "/s")
end

function ConveyorService.startSpawner()
	task.spawn(function()
		while true do
			task.wait(Config.SPAWN_INTERVAL * ConveyorService.spawnIntervalMult)
			ConveyorService.spawnBrainrot()
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		ConveyorService.stepWalking(dt)
	end)
end

return ConveyorService
