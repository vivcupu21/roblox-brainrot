-- WorldBuilder: builds the entire 3D world from Parts at runtime — the
-- conveyor belt down the middle, eight player plots in a ring, the spawn,
-- palm trees, lamps, clouds and the tsunami wave. No static models, no
-- asset ids: everything here is code, so Rojo builds it and Studio runs it.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

local Workspace = game:GetService("Workspace")

local function makePart(name, size, position, color, material, anchored, canCollide)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.Parent = Workspace
	return part
end

local function makeLabel(parent, text, size, textSize, color)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(size.X, size.Y)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.Parent = parent
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	return gui
end

-- One player plot: floor, low walls on three sides, ten slot pads, a sign
-- pole. Returns the plot table the services use.
function WorldBuilder.buildPlot(plotId, center, facingAngle)
	local plot = {
		id = plotId,
		center = center,
		owner = nil,
		slots = {}, -- [slotIndex] = { position, occupiedBy }
	}
	local cf = CFrame.new(center) * CFrame.Angles(0, facingAngle, 0)

	local floor = makePart("PlotFloor", Vector3.new(Config.PLOT_WIDTH, 2, Config.PLOT_DEPTH), center + Vector3.new(0, 1, 0), Color3.fromRGB(40, 140, 255), Enum.Material.Neon)
	floor.TopSurface = Enum.SurfaceType.Smooth

	-- Beacon: a tall neon pillar so a plot is visible from anywhere on the
	-- map — no more hunting a flat floor on green grass.
	local beacon = makePart("PlotBeacon", Vector3.new(2, 60, 2), center + Vector3.new(0, 31, 0), Color3.fromRGB(80, 255, 180), Enum.Material.Neon)
	beacon.CanCollide = false

	-- Low walls: back and both sides, front stays open toward the centre.
	local wallColor = Color3.fromRGB(90, 160, 230)
	local back = makePart("PlotWall", Vector3.new(Config.PLOT_WIDTH, 4, 1), (cf * CFrame.new(0, 2, -Config.PLOT_DEPTH / 2)).Position, wallColor, Enum.Material.SmoothPlastic)
	back.CFrame = cf * CFrame.new(0, 2, -Config.PLOT_DEPTH / 2)
	local left = makePart("PlotWall", Vector3.new(1, 4, Config.PLOT_DEPTH), (cf * CFrame.new(-Config.PLOT_WIDTH / 2, 2, 0)).Position, wallColor, Enum.Material.SmoothPlastic)
	left.CFrame = cf * CFrame.new(-Config.PLOT_WIDTH / 2, 2, 0)
	local right = makePart("PlotWall", Vector3.new(1, 4, Config.PLOT_DEPTH), (cf * CFrame.new(Config.PLOT_WIDTH / 2, 2, 0)).Position, wallColor, Enum.Material.SmoothPlastic)
	right.CFrame = cf * CFrame.new(Config.PLOT_WIDTH / 2, 2, 0)

	-- Ten slot pads: two rows of five.
	local slotIndex = 0
	for _, rowZ in ipairs(Config.SLOT_ROWS_Z) do
		for _, colX in ipairs(Config.SLOT_COLUMNS_X) do
			slotIndex += 1
			local localPos = Vector3.new(colX, 2.1, rowZ)
			local worldPos = (cf * CFrame.new(localPos)).Position
			local pad = makePart("SlotPad", Vector3.new(4, 0.2, 4), worldPos, Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
			pad.Transparency = 0.6
			pad.CanCollide = false
			plot.slots[slotIndex] = { position = worldPos, pad = pad, occupiedBy = nil }
		end
	end

	-- Sign pole at the front corner with the owner's name.
	local signPos = (cf * CFrame.new(Config.PLOT_WIDTH / 2 - 2, 3, Config.PLOT_DEPTH / 2 - 2)).Position
	local pole = makePart("PlotSign", Vector3.new(1, 6, 1), signPos, Color3.fromRGB(80, 60, 40), Enum.Material.Wood)
	makeLabel(pole, "FREE PLOT", Vector2.new(120, 36), 24, Color3.fromRGB(255, 255, 255))
	plot.signPart = pole
	plot.signGui = pole:FindFirstChild("Label")

	return plot
end

function WorldBuilder.setPlotSign(plot, text, color)
	local label = plot.signGui and plot.signGui:FindFirstChildOfClass("TextLabel")
	if label then
		label.Text = text
		label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	end
end

function WorldBuilder.buildWorld()
	-- Afternoon light: warm sun, soft haze, sun rays. Cheap, and it makes
	-- every screenshot look better.
	local lighting = game:GetService("Lighting")
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Density = 0.25
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(255, 230, 200)
	atmosphere.Decay = Color3.fromRGB(120, 140, 180)
	atmosphere.Parent = lighting
	local sunRays = Instance.new("SunRaysEffect")
	sunRays.Intensity = 0.15
	sunRays.Spread = 0.7
	sunRays.Parent = lighting

	-- Central conveyor belt with yellow edge strips and a start gate.
	local belt = makePart("ConveyorBelt", Vector3.new(200, 1, Config.CONVEYOR_WIDTH), Vector3.new(0, 0.5, Config.CONVEYOR_Z), Color3.fromRGB(60, 60, 70), Enum.Material.SmoothPlastic)
	belt.TopSurface = Enum.SurfaceType.Smooth
	for _, side in ipairs({ -1, 1 }) do
		makePart("ConveyorEdge", Vector3.new(200, 1.2, 0.6), Vector3.new(0, 0.6, Config.CONVEYOR_Z + side * (Config.CONVEYOR_WIDTH / 2)), Color3.fromRGB(255, 210, 40), Enum.Material.Neon)
	end
	-- Spawn gate: brainrots walk out from under this arch.
	makePart("SpawnGate", Vector3.new(1, 10, Config.CONVEYOR_WIDTH + 2), Vector3.new(Config.CONVEYOR_START_X, 5, Config.CONVEYOR_Z), Color3.fromRGB(255, 120, 60), Enum.Material.SmoothPlastic)
	makePart("SpawnGate", Vector3.new(1, 10, Config.CONVEYOR_WIDTH + 2), Vector3.new(Config.CONVEYOR_END_X, 5, Config.CONVEYOR_Z), Color3.fromRGB(255, 120, 60), Enum.Material.SmoothPlastic)
	local gateTop = makePart("SpawnGateTop", Vector3.new(3, 2, Config.CONVEYOR_WIDTH + 4), Vector3.new(Config.CONVEYOR_START_X, 11, Config.CONVEYOR_Z), Color3.fromRGB(255, 180, 40), Enum.Material.SmoothPlastic)
	makeLabel(gateTop, "BRAINROT INCOMING", Vector2.new(220, 40), 28, Color3.fromRGB(255, 255, 255))

	-- Eight plots in a ring, each facing the map centre.
	local plots = {}
	for i = 1, Config.PLOT_COUNT do
		local angle = (i - 1) * (math.pi * 2 / Config.PLOT_COUNT)
		local center = Vector3.new(math.sin(angle) * Config.PLOT_RADIUS, 0, math.cos(angle) * Config.PLOT_RADIUS)
		-- Face the centre: the plot's -Z side (walls) points outward.
		local facing = math.atan2(center.X, center.Z) + math.pi
		plots[i] = WorldBuilder.buildPlot(i, center, facing)
	end

	-- Spawn area at the south edge, with a welcome arch.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(24, 1, 24)
	spawn.Position = Vector3.new(0, 0.5, 175)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Color = Color3.fromRGB(255, 220, 90)
	spawn.Parent = Workspace
	local archLeft = makePart("WelcomeArch", Vector3.new(2, 14, 2), Vector3.new(-14, 7, 165), Color3.fromRGB(255, 100, 100), Enum.Material.SmoothPlastic)
	_ = archLeft
	local archRight = makePart("WelcomeArch", Vector3.new(2, 14, 2), Vector3.new(14, 7, 165), Color3.fromRGB(255, 100, 100), Enum.Material.SmoothPlastic)
	_ = archRight
	local archTop = makePart("WelcomeArchTop", Vector3.new(30, 3, 3), Vector3.new(0, 15, 165), Color3.fromRGB(255, 200, 40), Enum.Material.SmoothPlastic)
	makeLabel(archTop, "STEAL A BRAINROT", Vector2.new(420, 60), 36, Color3.fromRGB(255, 255, 255))

	-- Palm trees around the rim.
	for i = 1, 12 do
		local angle = (i - 1) * (math.pi * 2 / 12) + 0.26
		local x = math.sin(angle) * 200
		local z = math.cos(angle) * 200
		local trunk = makePart("PalmTrunk", Vector3.new(2, 14, 2), Vector3.new(x, 7, z), Color3.fromRGB(140, 100, 50), Enum.Material.Wood)
		trunk.CanCollide = false
		local leaves = makePart("PalmLeaves", Vector3.new(10, 4, 10), Vector3.new(x, 16, z), Color3.fromRGB(40, 180, 70), Enum.Material.SmoothPlastic)
		leaves.Shape = Enum.PartType.Ball
		leaves.CanCollide = false
	end

	-- Lamp posts flanking the conveyor.
	for _, x in ipairs({ -80, -40, 0, 40, 80 }) do
		for _, side in ipairs({ -1, 1 }) do
			makePart("Lamp", Vector3.new(1, 9, 1), Vector3.new(x, 4.5, Config.CONVEYOR_Z + side * 10), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
			local bulb = makePart("LampBulb", Vector3.new(2, 2, 2), Vector3.new(x, 9.5, Config.CONVEYOR_Z + side * 10), Color3.fromRGB(255, 240, 160), Enum.Material.Neon)
			bulb.Shape = Enum.PartType.Ball
			bulb.CanCollide = false
			local light = Instance.new("PointLight")
			light.Brightness = 1
			light.Range = 18
			light.Parent = bulb
		end
	end

	-- Clouds drifting high above the map.
	for i = 1, 6 do
		local angle = (i - 1) * (math.pi * 2 / 6)
		local cloud = makePart("Cloud", Vector3.new(24, 6, 14), Vector3.new(math.sin(angle) * 120, 65 + i * 3, math.cos(angle) * 120), Color3.fromRGB(255, 255, 255), Enum.Material.SmoothPlastic)
		cloud.Shape = Enum.PartType.Ball
		cloud.CanCollide = false
		cloud.Transparency = 0.15
	end

	-- The tsunami wave: hidden until the event fires, then it sweeps the map.
	local wave = makePart("TsunamiWave", Vector3.new(240, 42, 6), Vector3.new(0, 21, -200), Color3.fromRGB(40, 140, 255), Enum.Material.SmoothPlastic)
	wave.Transparency = 0.4
	wave.CanCollide = false
	wave.Name = "TsunamiWave"

	-- Neon meme signs around the central area: colour, jokes and pointers
	-- to the shop and the daily reward, all visible in screenshots.
	local signs = {
		{ text = "BRAINROT!", color = Color3.fromRGB(255, 100, 200), position = Vector3.new(-60, 7, -45), angle = math.rad(35) },
		{ text = "GET RICH!", color = Color3.fromRGB(120, 255, 120), position = Vector3.new(60, 7, -45), angle = math.rad(-35) },
		{ text = "SHOP = 2X CASH!", color = Color3.fromRGB(255, 220, 90), position = Vector3.new(-60, 7, 45), angle = math.rad(-35) },
		{ text = "DAILY REWARD!", color = Color3.fromRGB(140, 230, 255), position = Vector3.new(60, 7, 45), angle = math.rad(35) },
	}
	for _, sign in ipairs(signs) do
		local board = makePart("NeonSign", Vector3.new(16, 6, 0.6), sign.position, sign.color, Enum.Material.Neon)
		board.CFrame = CFrame.new(sign.position) * CFrame.Angles(0, sign.angle, 0)
		board.CanCollide = false
		local face = Instance.new("SurfaceGui")
		face.Face = Enum.NormalId.Front
		face.Parent = board
		local text = Instance.new("TextLabel")
		text.Size = UDim2.new(1, 0, 1, 0)
		text.BackgroundTransparency = 1
		text.Text = sign.text
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.TextColor3 = Color3.fromRGB(255, 255, 255)
		text.TextStrokeTransparency = 0
		text.Parent = face
		local post = makePart("SignPost", Vector3.new(1, 7, 1), sign.position + Vector3.new(0, -6.5, 0), Color3.fromRGB(50, 50, 55), Enum.Material.Metal)
		post.CanCollide = false
	end

	-- Grass tufts scattered on the rim, so the green is not one flat slab.
	for i = 1, 14 do
		local angle = (i - 1) * (math.pi * 2 / 14) + 0.12
		local x = math.sin(angle) * (150 + (i % 3) * 12)
		local z = math.cos(angle) * (150 + (i % 3) * 12)
		local tuft = makePart("GrassTuft", Vector3.new(5, 3, 5), Vector3.new(x, 1.5, z), Color3.fromRGB(60, 200, 80), Enum.Material.SmoothPlastic)
		tuft.Shape = Enum.PartType.Ball
		tuft.CanCollide = false
	end

	return {
		plots = plots,
		spawnLocation = spawn,
		wave = wave,
	}
end

return WorldBuilder
