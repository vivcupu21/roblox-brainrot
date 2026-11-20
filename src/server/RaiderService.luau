-- RaiderService: enemy NPCs that give solo players something to fight.
-- Every couple of minutes a wave of raiders walks in from the map centre,
-- heads for a random player's plot, and tries to grab one brainrot off it.
-- The player fights back with the Slap tool they already have: each slap
-- knocks a raider back and stuns it, and 3 slaps drive it off for a cash
-- bonus. If a raider finishes its 2-second grab, it runs off with the
-- brainrot — slap it 3 times while it flees to make it drop the loot.
-- Raiders never touch a locked base, an empty plot, or a spectating player,
-- and they never interfere with player-vs-player stealing. All tuning
-- numbers live in Config (RAIDER_*), so difficulty is one config edit.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))
local BrainrotFactory = require(script.Parent.BrainrotFactory)
local PlayerState = require(script.Parent.PlayerState)
local PlotService = require(script.Parent.PlotService)
local EconomyService = require(script.Parent.EconomyService)

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RaiderService = {}
RaiderService.raiders = {} -- list of raider tables, see spawnRaider

-- Red enemy tag above the model, so a raider is unmistakable at a glance.
local function markAsRaider(model)
	local root = model.PrimaryPart
	local tag = Instance.new("BillboardGui")
	tag.Name = "RaiderTag"
	tag.Size = UDim2.fromOffset(180, 36)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	tag.AlwaysOnTop = true
	tag.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "👹 RAIDER — SLAP IT!"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 60, 60)
	label.TextStrokeTransparency = 0
	label.Parent = tag
	local light = Instance.new("PointLight")
	light.Brightness = 1
	light.Range = 12
	light.Color = Color3.fromRGB(255, 60, 60)
	light.Parent = root
end

-- Players a wave is allowed to attack: they have a plot, at least one
-- brainrot on it, and their base is not locked.
local function eligibleTargets()
	local targets = {}
	for _, state in pairs(PlayerState.players) do
		local player = state.player
		if player and player.Parent then
			local plot = PlotService.getPlotOf(player)
			if plot and #state.owned > 0 and not PlayerState.isBaseLocked(state) then
				table.insert(targets, { player = player, state = state, plot = plot })
			end
		end
	end
	return targets
end

local function pickOwned(state)
	if #state.owned == 0 then
		return nil
	end
	return state.owned[math.random(#state.owned)]
end

-- Walk one model toward a point by up to step studs. Returns true when it
-- arrives (within 0.5 studs). Movement is scripted (PivotTo), like the
-- conveyor walk, so walls never block a raider.
local function walkToward(model, target, step)
	local pivot = model:GetPivot()
	local pos = pivot.Position
	local delta = target - pos
	delta = Vector3.new(delta.X, 0, delta.Z)
	local distance = delta.Magnitude
	if distance <= 0.5 then
		return true
	end
	local dir = delta.Unit
	local move = math.min(step, distance)
	local newPos = pos + dir * move
	model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, math.atan2(dir.X, dir.Z), 0))
	return distance - move <= 0.5
end

function RaiderService.spawnRaider(target, wave)
	if #RaiderService.raiders >= Config.RAIDER_MAX_ALIVE then
		return nil
	end
	local owned = pickOwned(target.state)
	if not owned or owned.slotIndex == nil then
		return nil
	end
	local slot = target.plot.slots[owned.slotIndex]
	if not slot then
		return nil
	end
	-- Raiders are brainrot models too — a random Common or Rare, so they
	-- look like part of the game, with the red RAIDER tag on top.
	local def = BrainrotData.rollCharacter(math.random(1, 2))
	local spawnPos = Vector3.new(math.random(-20, 20), 1, math.random(-20, 20))
	local model = BrainrotFactory.buildBrainrotModel(def, "None", 1, spawnPos)
	model.Name = "Raider " .. def.name
	model.Parent = Workspace
	markAsRaider(model)
	local speed = math.min(Config.RAIDER_WALK_SPEED + Config.RAIDER_SPEED_PER_WAVE * (wave - 1), Config.RAIDER_SPEED_MAX)
	local raider = {
		model = model,
		def = def,
		targetPlayer = target.player,
		targetPlot = target.plot,
		targetOwned = owned,
		targetSlotPos = slot.position,
		state = "hunt", -- "hunt" | "grab" | "flee"
		hits = 0,
		stunnedUntil = 0,
		grabStart = nil,
		warned = false,
		speed = speed,
		wave = wave,
		carrying = nil, -- the stolen owned entry, while fleeing
		fleeDir = Vector3.new(0, 0, 1),
		fleeStart = 0,
	}
	table.insert(RaiderService.raiders, raider)
	EconomyService.notify(target.player, "👹 A RAIDER is coming for your base! Get ready to slap!")
	return raider
end

-- Give the loot back when a fleeing raider is driven off.
local function returnLoot(raider)
	local stolen = raider.carrying
	if not stolen then
		return
	end
	raider.carrying = nil
	local victim = raider.targetPlayer
	local victimState = victim and PlayerState.get(victim)
	local victimPlot = victim and PlotService.getPlotOf(victim)
	if victimState and victimPlot then
		local slotIndex = PlotService.findFreeSlot(victimPlot)
		if slotIndex then
			table.insert(victimState.owned, stolen)
			PlotService.placeOnSlot(victimPlot, slotIndex, stolen)
			-- Lazy require: StealService requires this module, so the
			-- reference is only safe to take at call time.
			local StealService = require(script.Parent.StealService)
			StealService.attachStealPrompt(stolen, victimPlot)
			EconomyService.pushCashUpdate(victimState)
			EconomyService.notify(victim, "You saved your " .. stolen.def.name .. " from the raider!")
			return
		end
	end
	stolen.model:Destroy()
end

local function removeRaider(index)
	local raider = RaiderService.raiders[index]
	if raider then
		if raider.model.Parent then
			raider.model:Destroy()
		end
		table.remove(RaiderService.raiders, index)
	end
end

-- Drive one off: return its loot, pay the bonus, despawn.
local function driveOff(raider, index, byPlayer)
	returnLoot(raider)
	local reward = Config.RAIDER_REWARD_CASH + Config.RAIDER_REWARD_PER_WAVE * (raider.wave - 1)
	local state = byPlayer and PlayerState.get(byPlayer)
	if state then
		state.cash += reward
		EconomyService.pushCashUpdate(state)
		EconomyService.notify(byPlayer, "Raider driven off! +$" .. reward .. " bonus")
	end
	removeRaider(index)
end

-- The steal itself: lift the brainrot off its slot and run with it.
local function stealFromPlot(raider)
	local owned = raider.targetOwned
	local plot = raider.targetPlot
	local victim = raider.targetPlayer
	local victimState = victim and PlayerState.get(victim)
	if not owned or not plot or not victimState then
		raider.state = "flee"
		raider.fleeStart = os.clock()
		return
	end
	if owned.slotIndex == nil or plot.slots[owned.slotIndex].occupiedBy ~= owned then
		-- Someone else already took it — find another target or leave.
		local next = pickOwned(victimState)
		if next and next.slotIndex ~= nil then
			raider.targetOwned = next
			raider.targetSlotPos = plot.slots[next.slotIndex].position
			raider.state = "hunt"
			raider.grabStart = nil
			raider.warned = false
			return
		end
		raider.state = "flee"
		raider.fleeStart = os.clock()
		return
	end
	PlotService.removeFromSlot(plot, owned.slotIndex)
	for i, item in ipairs(victimState.owned) do
		if item == owned then
			table.remove(victimState.owned, i)
			break
		end
	end
	local prompt = owned.model.PrimaryPart:FindFirstChild("StealPrompt")
	if prompt then
		prompt:Destroy()
	end
	EconomyService.pushCashUpdate(victimState)
	EconomyService.notify(victim, "👹 Raider stole your " .. owned.def.name .. "! Slap it 3 times to get it back!")
	raider.carrying = owned
	raider.state = "flee"
	raider.fleeStart = os.clock()
	local pos = raider.model:GetPivot().Position
	local away = pos - plot.center
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 1 then
		away = Vector3.new(0, 0, 1)
	end
	raider.fleeDir = away.Unit
end

-- One wave: 1 raider first, +1 each wave up to the cap, each hunting a
-- random eligible player. A wave with nobody to attack is quietly skipped.
function RaiderService.spawnWave(wave)
	local targets = eligibleTargets()
	if #targets == 0 then
		return
	end
	local count = math.min(Config.RAIDER_BASE_COUNT + Config.RAIDER_COUNT_PER_WAVE * (wave - 1), Config.RAIDER_MAX_COUNT)
	for _ = 1, count do
		local target = targets[math.random(#targets)]
		RaiderService.spawnRaider(target, wave)
	end
end

-- The Slap tool calls this after missing a player thief: nearest raider in
-- slap range takes the hit. Returns true when a raider was hit.
function RaiderService.trySlapRaider(player, rootPos)
	local bestIndex = nil
	local bestDistance = Config.SLAP_RANGE
	for index, raider in ipairs(RaiderService.raiders) do
		if raider.model.Parent then
			local distance = (raider.model:GetPivot().Position - rootPos).Magnitude
			if distance <= bestDistance then
				bestDistance = distance
				bestIndex = index
			end
		end
	end
	if not bestIndex then
		return false
	end
	local raider = RaiderService.raiders[bestIndex]
	raider.hits += 1
	raider.stunnedUntil = os.clock() + Config.RAIDER_STUN_SECONDS
	-- Knockback: away from the slapper, and a grab in progress is broken.
	local away = raider.model:GetPivot().Position - rootPos
	away = Vector3.new(away.X, 0, away.Z)
	if away.Magnitude < 1 then
		away = Vector3.new(0, 0, 1)
	end
	local pos = raider.model:GetPivot().Position + away.Unit * Config.RAIDER_KNOCKBACK_STUDS
	raider.model:PivotTo(CFrame.new(Vector3.new(pos.X, 1, pos.Z)))
	if raider.state == "grab" then
		raider.state = "hunt"
		raider.grabStart = nil
		raider.warned = false
	end
	if raider.hits >= Config.RAIDER_HITS_TO_FLEE then
		driveOff(raider, bestIndex, player)
	else
		EconomyService.notify(player, "Slapped the raider! (" .. raider.hits .. "/" .. Config.RAIDER_HITS_TO_FLEE .. ")")
	end
	return true
end

-- Move every raider one step. Runs on Heartbeat, like the conveyor walk.
function RaiderService.stepRaiders(dt)
	local i = 1
	while i <= #RaiderService.raiders do
		local raider = RaiderService.raiders[i]
		local model = raider.model
		if not model.Parent then
			table.remove(RaiderService.raiders, i)
		else
			-- A fleeing raider carries the loot above its head.
			if raider.carrying and raider.carrying.model.Parent then
				raider.carrying.model:PivotTo(model:GetPivot() * CFrame.new(0, 4.5, 0))
			end
			if os.clock() < raider.stunnedUntil then
				i += 1
			elseif raider.state == "hunt" then
				-- Target gone (player left, rebirth, base locked)? Give up.
				local victimState = PlayerState.get(raider.targetPlayer)
				if not victimState or not raider.targetPlayer.Parent or PlayerState.isBaseLocked(victimState) then
					removeRaider(i)
				elseif walkToward(model, raider.targetSlotPos, raider.speed * dt) then
					raider.state = "grab"
					raider.grabStart = os.clock()
					if not raider.warned then
						raider.warned = true
						EconomyService.notify(raider.targetPlayer, "👹 A RAIDER is grabbing your " .. raider.targetOwned.def.name .. "! Slap it off NOW!")
					end
					i += 1
				else
					i += 1
				end
			elseif raider.state == "grab" then
				local victimState = PlayerState.get(raider.targetPlayer)
				if not victimState or not raider.targetPlayer.Parent or PlayerState.isBaseLocked(victimState) then
					removeRaider(i)
				elseif os.clock() - (raider.grabStart or os.clock()) >= Config.RAIDER_GRAB_SECONDS then
					stealFromPlot(raider)
					i += 1
				else
					i += 1
				end
			elseif raider.state == "flee" then
				local step = raider.speed * Config.RAIDER_FLEE_SPEED_MULT * dt
				local pos = model:GetPivot().Position + raider.fleeDir * step
				model:PivotTo(CFrame.new(Vector3.new(pos.X, 1, pos.Z)) * CFrame.Angles(0, math.atan2(raider.fleeDir.X, raider.fleeDir.Z), 0))
				local escaped = Vector3.new(pos.X, 0, pos.Z).Magnitude > 210 or os.clock() - raider.fleeStart > 25
				if escaped then
					-- Got away with the loot — it is gone for good.
					if raider.carrying then
						EconomyService.notify(raider.targetPlayer, "The raider got away with your " .. raider.carrying.def.name .. "!")
						raider.carrying.model:Destroy()
						raider.carrying = nil
					end
					removeRaider(i)
				else
					i += 1
				end
			else
				i += 1
			end
		end
	end
end

function RaiderService.startWaveLoop()
	task.spawn(function()
		task.wait(Config.RAIDER_FIRST_WAVE_DELAY)
		local wave = 1
		while true do
			RaiderService.spawnWave(wave)
			local interval = math.max(Config.RAIDER_WAVE_INTERVAL - Config.RAIDER_WAVE_INTERVAL_STEP * (wave - 1), Config.RAIDER_WAVE_INTERVAL_MIN)
			task.wait(interval)
			wave += 1
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		RaiderService.stepRaiders(dt)
	end)
end

function RaiderService.init()
	RaiderService.startWaveLoop()
end

return RaiderService
