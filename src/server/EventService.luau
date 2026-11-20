-- EventService: the world fights back on a timer. The rotation, the banner
-- text and the lengths all come from EventsData; this module only holds one
-- handler function per event id. ADDING AN EVENT: one row in EventsData plus
-- one handler here — the loop picks it up on its own.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local EventsData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("EventsData"))
local EconomyService = require(script.Parent.EconomyService)
local ConveyorService = require(script.Parent.ConveyorService)
local Remotes = require(script.Parent.Remotes)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local EventService = {}
EventService.wave = nil
EventService.waveActive = false
EventService.currentEvent = nil

function EventService.broadcastBanner(title, subtitle, seconds)
	Remotes.EventBanner:FireAllClients(title, subtitle, seconds)
end

-- The tsunami: the wave part sweeps from the north edge to the south edge.
-- Anyone it touches gets flung toward spawn and stunned for a few seconds.
function EventService.startTsunami(eventDef)
	EventService.currentEvent = "Tsunami"
	EventService.broadcastBanner(eventDef.title, eventDef.subtitle, Config.EVENT_WARNING)
	task.wait(Config.EVENT_WARNING)
	EventService.broadcastBanner(eventDef.runningTitle, eventDef.runningSubtitle, Config.TSUNAMI_SWEEP_SECONDS)
	local wave = EventService.wave
	if not wave then
		EventService.currentEvent = nil
		return
	end
	EventService.waveActive = true
	local startZ = -200
	local endZ = 200
	local startTime = os.clock()
	local hitPlayers = {}
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - startTime) / Config.TSUNAMI_SWEEP_SECONDS
		if t >= 1 then
			connection:Disconnect()
			EventService.waveActive = false
			wave.Position = Vector3.new(0, 21, -200)
			EventService.currentEvent = nil
			return
		end
		local z = startZ + (endZ - startZ) * t
		wave.Position = Vector3.new(0, 21, z)
		for _, player in ipairs(Players:GetPlayers()) do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if root and humanoid and not hitPlayers[player] then
				if math.abs(root.Position.Z - z) < 6 then
					hitPlayers[player] = true
					humanoid.WalkSpeed = 0
					humanoid.JumpPower = 0
					root.AssemblyLinearVelocity = Vector3.new(0, 30, 60)
					Remotes.Notify:FireClient(player, "The TSUNAMI got you! Stunned!")
					task.delay(Config.TSUNAMI_STUN_SECONDS, function()
						if humanoid.Parent then
							humanoid.WalkSpeed = 16
							humanoid.JumpPower = 50
						end
					end)
				end
			end
		end
	end)
end

function EventService.startGoldenHour(eventDef)
	EventService.currentEvent = "Golden Hour"
	EconomyService.eventMult = Config.GOLDEN_HOUR_MULT
	EventService.broadcastBanner(eventDef.title, eventDef.subtitle, Config.GOLDEN_HOUR_SECONDS)
	task.wait(Config.GOLDEN_HOUR_SECONDS)
	EconomyService.eventMult = 1
	EventService.currentEvent = nil
end

function EventService.startBrainrotRain(eventDef)
	EventService.currentEvent = "Brainrot Rain"
	ConveyorService.spawnIntervalMult = 0.5
	ConveyorService.mythicBoost = true
	EventService.broadcastBanner(eventDef.title, eventDef.subtitle, Config.RAIN_SECONDS)
	task.wait(Config.RAIN_SECONDS)
	ConveyorService.spawnIntervalMult = 1
	ConveyorService.mythicBoost = false
	EventService.currentEvent = nil
end

-- Meteor Shower: every few seconds a flaming rock crashes onto the conveyor
-- and drops a guaranteed Rare-or-better brainrot with a mutation. The
-- meteor is a visual only — it never hurts anyone — so the event is pure
-- upside and the whole map runs to the conveyor when it fires.
function EventService.startMeteorShower(eventDef)
	EventService.currentEvent = "Meteor Shower"
	EventService.broadcastBanner(eventDef.title, eventDef.subtitle, Config.METEOR_SECONDS)
	local startTime = os.clock()
	while os.clock() - startTime < Config.METEOR_SECONDS do
		local strikeX = math.random(Config.CONVEYOR_START_X + 10, Config.CONVEYOR_END_X - 10)
		local meteor = Instance.new("Part")
		meteor.Name = "Meteor"
		meteor.Size = Vector3.new(4, 4, 4)
		meteor.Shape = Enum.PartType.Ball
		meteor.Color = Color3.fromRGB(255, 120, 0)
		meteor.Material = Enum.Material.Neon
		meteor.Anchored = true
		meteor.CanCollide = false
		meteor.CFrame = CFrame.new(strikeX, 60, Config.CONVEYOR_Z)
		meteor.Parent = Workspace
		local light = Instance.new("PointLight")
		light.Brightness = 2
		light.Range = 24
		light.Color = Color3.fromRGB(255, 150, 50)
		light.Parent = meteor
		-- Fall fast, flash on impact, then vanish.
		local fallStart = os.clock()
		while os.clock() - fallStart < 0.8 do
			meteor.CFrame = CFrame.new(strikeX, 60 - (60 - 2) * ((os.clock() - fallStart) / 0.8), Config.CONVEYOR_Z)
			task.wait()
		end
		meteor.Color = Color3.fromRGB(255, 240, 120)
		meteor.Size = Vector3.new(8, 8, 8)
		ConveyorService.spawnBrainrot({
			position = Vector3.new(strikeX, 1, Config.CONVEYOR_Z),
			minRarity = 2, -- Rare or better
			forceMutation = true,
		})
		task.wait(0.4)
		meteor:Destroy()
		task.wait(Config.METEOR_STRIKE_INTERVAL)
	end
	EventService.currentEvent = nil
end

-- One handler per event id in EventsData. The loop below walks the table.
local HANDLERS = {
	tsunami = EventService.startTsunami,
	goldenHour = EventService.startGoldenHour,
	brainrotRain = EventService.startBrainrotRain,
	meteorShower = EventService.startMeteorShower,
}

function EventService.startEventLoop()
	task.spawn(function()
		while true do
			task.wait(Config.EVENT_INTERVAL)
			for _, eventDef in ipairs(EventsData.EVENTS) do
				local handler = HANDLERS[eventDef.id]
				if handler then
					task.spawn(handler, eventDef)
					-- Let the handler claim currentEvent first, then wait
					-- for it to finish before the next event.
					task.wait(0.5)
					while EventService.currentEvent ~= nil do
						task.wait(1)
					end
				end
				task.wait(Config.EVENT_INTERVAL)
			end
		end
	end)
end

function EventService.init(world)
	EventService.wave = world.wave
	EventService.startEventLoop()
end

return EventService
