-- BrainrotFactory: turns a BrainrotData definition into a living Model made
-- only of Parts — body, head, eyes, legs and one accessory — plus a floating
-- name label (name, rarity, money per second) and a ProximityPrompt the
-- services wire up. Nothing here needs an asset id or the network.

local BrainrotData = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BrainrotData"))

local BrainrotFactory = {}

local MUTATION_COLORS = {
	Gold = Color3.fromRGB(255, 215, 0),
	Diamond = Color3.fromRGB(140, 230, 255),
	Rainbow = Color3.fromRGB(255, 100, 200),
	Lava = Color3.fromRGB(255, 80, 0),
	Void = Color3.fromRGB(60, 0, 90),
}

local function addPart(model, name, size, offset, color, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = model:GetPivot() * CFrame.new(offset)
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = true
	part.Parent = model
	return part
end

local function addEyes(model, head, headSize)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.5, 0.7, 0.3)
		eye.CFrame = head.CFrame * CFrame.new(side * (headSize.X * 0.22), headSize.Y * 0.08, headSize.Z / 2 + 0.15)
		eye.Color = Color3.fromRGB(255, 255, 255)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = false
		eye.CanCollide = false
		eye.Parent = model
		local pupil = Instance.new("Part")
		pupil.Name = "Pupil"
		pupil.Size = Vector3.new(0.25, 0.35, 0.15)
		pupil.CFrame = eye.CFrame * CFrame.new(0, 0, 0.16)
		pupil.Color = Color3.fromRGB(20, 20, 20)
		pupil.Material = Enum.Material.SmoothPlastic
		pupil.Anchored = false
		pupil.CanCollide = false
		pupil.Parent = model
	end
end

local function addAccessory(model, def, head, headSize)
	local kind = def.accessory
	if kind == "none" then
		return
	end
	if kind == "crown" then
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(headSize.X * 0.8, 0.8, headSize.Z * 0.8)
		crown.CFrame = head.CFrame * CFrame.new(0, headSize.Y / 2 + 0.4, 0)
		crown.Color = Color3.fromRGB(255, 215, 0)
		crown.Material = Enum.Material.Metal
		crown.Anchored = false
		crown.CanCollide = false
		crown.Parent = model
	elseif kind == "hat" then
		local hat = Instance.new("Part")
		hat.Name = "Hat"
		hat.Size = Vector3.new(headSize.X * 1.1, 0.5, headSize.Z * 1.1)
		hat.CFrame = head.CFrame * CFrame.new(0, headSize.Y / 2 + 0.25, 0)
		hat.Color = def.accent
		hat.Material = Enum.Material.SmoothPlastic
		hat.Anchored = false
		hat.CanCollide = false
		hat.Parent = model
	elseif kind == "shades" then
		local shades = Instance.new("Part")
		shades.Name = "Shades"
		shades.Size = Vector3.new(headSize.X * 0.9, 0.5, 0.4)
		shades.CFrame = head.CFrame * CFrame.new(0, headSize.Y * 0.1, headSize.Z / 2 + 0.1)
		shades.Color = Color3.fromRGB(20, 20, 20)
		shades.Material = Enum.Material.SmoothPlastic
		shades.Anchored = false
		shades.CanCollide = false
		shades.Parent = model
	elseif kind == "log" then
		local log = Instance.new("Part")
		log.Name = "Log"
		log.Size = Vector3.new(1.2, 1.2, 5)
		log.CFrame = head.CFrame * CFrame.new(0, headSize.Y / 2 + 0.5, 0)
		log.Color = Color3.fromRGB(150, 100, 60)
		log.Material = Enum.Material.Wood
		log.Anchored = false
		log.CanCollide = false
		log.Parent = model
	elseif kind == "gem" then
		-- A glowing gem floating just above the head.
		local gem = Instance.new("Part")
		gem.Name = "Gem"
		gem.Size = Vector3.new(0.9, 0.9, 0.9)
		gem.Shape = Enum.PartType.Ball
		gem.CFrame = head.CFrame * CFrame.new(0, headSize.Y / 2 + 0.8, 0)
		gem.Color = def.accent
		gem.Material = Enum.Material.Neon
		gem.Anchored = false
		gem.CanCollide = false
		gem.Parent = model
	end
end

-- Build the Model for one brainrot. position is where it stands; the model
-- is welded together so it moves as one piece.
function BrainrotFactory.buildBrainrotModel(def, mutation, mutationMult, position)
	local model = Instance.new("Model")
	model.Name = def.name

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(3, 1, 3)
	root.CFrame = CFrame.new(position)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.Parent = model
	model.PrimaryPart = root

	-- Body by shape.
	local bodySize = Vector3.new(3, 3, 3)
	local body
	if def.body == "log" then
		bodySize = Vector3.new(2.5, 2.5, 5)
		body = addPart(model, "Body", bodySize, Vector3.new(0, 2, 0), def.bodyColor)
	elseif def.body == "ball" then
		bodySize = Vector3.new(3.4, 3.4, 3.4)
		body = addPart(model, "Body", bodySize, Vector3.new(0, 2.2, 0), def.bodyColor)
		body.Shape = Enum.PartType.Ball
	elseif def.body == "shark" then
		bodySize = Vector3.new(2.5, 2.5, 6)
		body = addPart(model, "Body", bodySize, Vector3.new(0, 2, 0), def.bodyColor)
		local fin = addPart(model, "Fin", Vector3.new(0.4, 2, 2), Vector3.new(0, 4, -0.5), def.accent)
		fin.Shape = Enum.PartType.Wedge
	elseif def.body == "croc" then
		bodySize = Vector3.new(2.5, 2, 6)
		body = addPart(model, "Body", bodySize, Vector3.new(0, 1.8, 0), def.bodyColor)
		addPart(model, "Snout", Vector3.new(2, 1, 2), Vector3.new(0, 1.6, 3.5), def.headColor)
	elseif def.body == "cat" then
		bodySize = Vector3.new(3, 2.5, 4)
		body = addPart(model, "Body", bodySize, Vector3.new(0, 1.8, 0), def.bodyColor)
		addPart(model, "Ear", Vector3.new(0.8, 1.2, 0.4), Vector3.new(-1, 3.6, 1.2), def.bodyColor)
		addPart(model, "Ear", Vector3.new(0.8, 1.2, 0.4), Vector3.new(1, 3.6, 1.2), def.bodyColor)
	elseif def.body == "bird" then
		bodySize = Vector3.new(3, 3, 3)
		body = addPart(model, "Body", bodySize, Vector3.new(0, 2.2, 0), def.bodyColor)
		body.Shape = Enum.PartType.Ball
		addPart(model, "Beak", Vector3.new(1, 0.6, 1.2), Vector3.new(0, 2.2, 2), Color3.fromRGB(255, 180, 40))
	else
		body = addPart(model, "Body", bodySize, Vector3.new(0, 2, 0), def.bodyColor)
	end

	-- Head sits on top of the body, facing +Z.
	local headSize = Vector3.new(2.4, 2.2, 2.4)
	local head = addPart(model, "Head", headSize, Vector3.new(0, 2 + bodySize.Y / 2 + headSize.Y / 2 - 0.3, bodySize.Z / 2 - 0.4), def.headColor)
	addEyes(model, head, headSize)
	addAccessory(model, def, head, headSize)

	-- Two stubby legs so it can waddle.
	addPart(model, "Leg", Vector3.new(0.9, 1, 0.9), Vector3.new(-0.8, 0.5, 0), def.accent)
	addPart(model, "Leg", Vector3.new(0.9, 1, 0.9), Vector3.new(0.8, 0.5, 0), def.accent)

	-- Mutation tint: a glowing outline part under the body.
	if mutation ~= "None" then
		local glow = addPart(model, "MutationGlow", Vector3.new(4.5, 0.4, 4.5), Vector3.new(0, 0.3, 0), MUTATION_COLORS[mutation] or Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
		glow.CanCollide = false
		glow.Transparency = 0.3
	end

	-- Weld every part to the root so the model moves as one piece.
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part ~= root then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
			part.Anchored = false
		end
	end

	-- Floating label: name, rarity, mutation, money per second.
	local rarity = BrainrotData.getRarity(def.rarity)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.fromOffset(140, 64)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = root
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = def.name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = billboard
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.45, 0)
	rarityLabel.BackgroundTransparency = 1
	local mutationText = mutation ~= "None" and (" " .. mutation) or ""
	rarityLabel.Text = rarity.name .. mutationText
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.FredokaOne
	rarityLabel.TextColor3 = rarity.color
	rarityLabel.TextStrokeTransparency = 0
	rarityLabel.Parent = billboard
	local incomeLabel = Instance.new("TextLabel")
	incomeLabel.Name = "IncomeLabel"
	incomeLabel.Size = UDim2.new(1, 0, 0.25, 0)
	incomeLabel.Position = UDim2.new(0, 0, 0.75, 0)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Text = BrainrotData.formatMoney(BrainrotData.incomeOf(def, mutationMult)) .. "/s"
	incomeLabel.TextScaled = true
	incomeLabel.Font = Enum.Font.FredokaOne
	incomeLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
	incomeLabel.TextStrokeTransparency = 0
	incomeLabel.Parent = billboard

	model:SetAttribute("BrainrotId", def.id)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("MutationMult", mutationMult)
	return model
end

return BrainrotFactory
