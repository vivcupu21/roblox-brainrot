-- BrainrotData: the whole cast of Steal a Brainrot — Meme Madness.
-- Every character is data: name, rarity, cost, money per second, colours and a
-- blocky body plan the factory builds from Parts. No asset ids, no network,
-- so the game runs offline in Studio. Rarities climb from Common to Secret.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local BrainrotData = {}

BrainrotData.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(180, 180, 180), weight = 36 },
	{ name = "Rare", color = Color3.fromRGB(80, 160, 255), weight = 28 },
	{ name = "Epic", color = Color3.fromRGB(170, 90, 255), weight = 16 },
	{ name = "Legendary", color = Color3.fromRGB(255, 180, 40), weight = 10 },
	{ name = "Mythic", color = Color3.fromRGB(255, 80, 120), weight = 6 },
	{ name = "Brainrot God", color = Color3.fromRGB(255, 230, 0), weight = 3 },
	{ name = "Secret", color = Color3.fromRGB(0, 230, 190), weight = 1 },
}

-- body: "log" (long box), "ball" (sphere), "box" (cube), "shark" (long + fin),
-- "croc" (long + snout), "cat" (box + ears), "bird" (ball + beak)
-- accessory: "crown", "hat", "shades", "log", "gem", "none"
-- ADDING A CHARACTER: add one row here. Cost is roughly income x 9-10, and
-- income doubles about every two rarity steps. Nothing else needs to change.
BrainrotData.CHARACTERS = {
	-- Common
	{ id = "noobini", name = "Noobini Pizzanini", rarity = 1, cost = 15, income = 2, body = "box", bodyColor = Color3.fromRGB(255, 210, 120), headColor = Color3.fromRGB(255, 220, 150), accessory = "hat", accent = Color3.fromRGB(220, 60, 60) },
	{ id = "pipikiwi", name = "Pipi Kiwi", rarity = 1, cost = 25, income = 3, body = "ball", bodyColor = Color3.fromRGB(120, 200, 90), headColor = Color3.fromRGB(150, 220, 100), accessory = "none", accent = Color3.fromRGB(90, 60, 30) },
	{ id = "trippi", name = "Trippi Troppi", rarity = 1, cost = 40, income = 5, body = "box", bodyColor = Color3.fromRGB(120, 200, 255), headColor = Color3.fromRGB(160, 220, 255), accessory = "shades", accent = Color3.fromRGB(40, 40, 40) },
	{ id = "bambini", name = "Bambini Crostini", rarity = 1, cost = 60, income = 7, body = "box", bodyColor = Color3.fromRGB(230, 190, 130), headColor = Color3.fromRGB(245, 210, 150), accessory = "hat", accent = Color3.fromRGB(180, 120, 40) },
	{ id = "pippopop", name = "Pippo Popcorn", rarity = 1, cost = 80, income = 9, body = "ball", bodyColor = Color3.fromRGB(255, 240, 200), headColor = Color3.fromRGB(255, 250, 220), accessory = "none", accent = Color3.fromRGB(220, 60, 60) },
	-- Rare
	{ id = "tungtung", name = "Tung Tung Tung Sahur", rarity = 2, cost = 100, income = 12, body = "log", bodyColor = Color3.fromRGB(150, 100, 60), headColor = Color3.fromRGB(180, 130, 80), accessory = "log", accent = Color3.fromRGB(90, 60, 30) },
	{ id = "chimpanzini", name = "Chimpanzini Bananini", rarity = 2, cost = 150, income = 18, body = "box", bodyColor = Color3.fromRGB(120, 80, 40), headColor = Color3.fromRGB(150, 110, 70), accessory = "none", accent = Color3.fromRGB(255, 230, 60) },
	{ id = "lirili", name = "Lirili Larila", rarity = 2, cost = 200, income = 25, body = "ball", bodyColor = Color3.fromRGB(255, 200, 140), headColor = Color3.fromRGB(255, 220, 180), accessory = "hat", accent = Color3.fromRGB(80, 180, 120) },
	{ id = "kucingkopi", name = "Kucing Kopi Susu", rarity = 2, cost = 250, income = 30, body = "cat", bodyColor = Color3.fromRGB(220, 180, 130), headColor = Color3.fromRGB(240, 200, 150), accessory = "none", accent = Color3.fromRGB(100, 60, 30) },
	{ id = "capybara", name = "Capybara Cappuccino", rarity = 2, cost = 350, income = 42, body = "cat", bodyColor = Color3.fromRGB(170, 130, 90), headColor = Color3.fromRGB(190, 150, 110), accessory = "gem", accent = Color3.fromRGB(120, 80, 50) },
	{ id = "gattogelato", name = "Gatto Gelato", rarity = 2, cost = 450, income = 55, body = "cat", bodyColor = Color3.fromRGB(255, 230, 240), headColor = Color3.fromRGB(255, 245, 250), accessory = "shades", accent = Color3.fromRGB(255, 150, 200) },
	-- Epic
	{ id = "tralalero", name = "Tralalero Tralala", rarity = 3, cost = 400, income = 50, body = "shark", bodyColor = Color3.fromRGB(100, 160, 220), headColor = Color3.fromRGB(140, 190, 240), accessory = "shades", accent = Color3.fromRGB(255, 255, 255) },
	{ id = "brrpatapim", name = "Brr Brr Patapim", rarity = 3, cost = 600, income = 75, body = "ball", bodyColor = Color3.fromRGB(230, 190, 150), headColor = Color3.fromRGB(240, 210, 170), accessory = "hat", accent = Color3.fromRGB(60, 140, 90) },
	{ id = "boneca", name = "Boneca Ambalabu", rarity = 3, cost = 800, income = 95, body = "box", bodyColor = Color3.fromRGB(255, 150, 200), headColor = Color3.fromRGB(255, 190, 220), accessory = "crown", accent = Color3.fromRGB(255, 220, 0) },
	{ id = "ayamgeprek", name = "Ayam Geprek Supreme", rarity = 3, cost = 900, income = 110, body = "bird", bodyColor = Color3.fromRGB(255, 240, 200), headColor = Color3.fromRGB(255, 220, 150), accessory = "none", accent = Color3.fromRGB(230, 60, 40) },
	{ id = "spagyetti", name = "Spaghetti Yetii", rarity = 3, cost = 1200, income = 140, body = "log", bodyColor = Color3.fromRGB(250, 250, 250), headColor = Color3.fromRGB(255, 255, 255), accessory = "hat", accent = Color3.fromRGB(220, 60, 60) },
	{ id = "pinguino", name = "Pinguino Espresso", rarity = 3, cost = 1400, income = 165, body = "bird", bodyColor = Color3.fromRGB(40, 40, 60), headColor = Color3.fromRGB(60, 60, 80), accessory = "gem", accent = Color3.fromRGB(255, 200, 60) },
	-- Legendary
	{ id = "bombardiro", name = "Bombardiro Crocodilo", rarity = 4, cost = 1500, income = 180, body = "croc", bodyColor = Color3.fromRGB(90, 160, 80), headColor = Color3.fromRGB(120, 190, 100), accessory = "hat", accent = Color3.fromRGB(60, 60, 60) },
	{ id = "frigo", name = "Frigo Camelo", rarity = 4, cost = 2000, income = 240, body = "log", bodyColor = Color3.fromRGB(200, 220, 240), headColor = Color3.fromRGB(220, 235, 250), accessory = "none", accent = Color3.fromRGB(120, 180, 220) },
	{ id = "ballerina", name = "Ballerina Cappuccina", rarity = 4, cost = 2500, income = 300, body = "box", bodyColor = Color3.fromRGB(255, 230, 210), headColor = Color3.fromRGB(255, 240, 225), accessory = "crown", accent = Color3.fromRGB(255, 150, 180) },
	{ id = "esteh", name = "Es Teh Manis", rarity = 4, cost = 3000, income = 360, body = "box", bodyColor = Color3.fromRGB(255, 170, 60), headColor = Color3.fromRGB(255, 200, 110), accessory = "shades", accent = Color3.fromRGB(255, 255, 255) },
	{ id = "elefante", name = "Elefante Espresso", rarity = 4, cost = 4500, income = 540, body = "log", bodyColor = Color3.fromRGB(160, 160, 180), headColor = Color3.fromRGB(190, 190, 210), accessory = "gem", accent = Color3.fromRGB(120, 80, 40) },
	-- Mythic
	{ id = "cappuccino", name = "Cappuccino Assassino", rarity = 5, cost = 5000, income = 600, body = "box", bodyColor = Color3.fromRGB(90, 60, 40), headColor = Color3.fromRGB(120, 85, 60), accessory = "shades", accent = Color3.fromRGB(255, 220, 0) },
	{ id = "lavaca", name = "La Vaca Saturno Saturnita", rarity = 5, cost = 7500, income = 900, body = "ball", bodyColor = Color3.fromRGB(240, 240, 240), headColor = Color3.fromRGB(255, 255, 255), accessory = "crown", accent = Color3.fromRGB(255, 200, 0) },
	{ id = "giraffa", name = "Giraffa Celeste", rarity = 5, cost = 10000, income = 1200, body = "log", bodyColor = Color3.fromRGB(255, 220, 130), headColor = Color3.fromRGB(255, 235, 160), accessory = "none", accent = Color3.fromRGB(255, 150, 80) },
	{ id = "nasipadang", name = "Nasi Padang Power", rarity = 5, cost = 12000, income = 1450, body = "box", bodyColor = Color3.fromRGB(255, 255, 255), headColor = Color3.fromRGB(255, 245, 220), accessory = "hat", accent = Color3.fromRGB(200, 40, 40) },
	{ id = "tortuga", name = "Tortuga Tacos", rarity = 5, cost = 15000, income = 1800, body = "ball", bodyColor = Color3.fromRGB(90, 180, 90), headColor = Color3.fromRGB(120, 200, 120), accessory = "gem", accent = Color3.fromRGB(255, 200, 60) },
	-- Brainrot God
	{ id = "tralaleritos", name = "Los Tralaleritos", rarity = 6, cost = 25000, income = 3000, body = "shark", bodyColor = Color3.fromRGB(80, 140, 210), headColor = Color3.fromRGB(120, 175, 235), accessory = "crown", accent = Color3.fromRGB(255, 220, 0) },
	{ id = "tralaleritas", name = "Las Tralaleritas", rarity = 6, cost = 40000, income = 4800, body = "shark", bodyColor = Color3.fromRGB(255, 140, 200), headColor = Color3.fromRGB(255, 180, 220), accessory = "crown", accent = Color3.fromRGB(255, 220, 0) },
	{ id = "graipuss", name = "Graipuss Medussi", rarity = 6, cost = 60000, income = 7000, body = "cat", bodyColor = Color3.fromRGB(150, 90, 200), headColor = Color3.fromRGB(180, 120, 230), accessory = "crown", accent = Color3.fromRGB(0, 220, 180) },
	-- Secret
	{ id = "garama", name = "Garama and Madundung", rarity = 7, cost = 150000, income = 18000, body = "log", bodyColor = Color3.fromRGB(255, 90, 90), headColor = Color3.fromRGB(255, 130, 130), accessory = "crown", accent = Color3.fromRGB(255, 220, 0) },
	{ id = "pothotspot", name = "Pot Hotspot", rarity = 7, cost = 250000, income = 30000, body = "ball", bodyColor = Color3.fromRGB(255, 120, 40), headColor = Color3.fromRGB(255, 160, 80), accessory = "shades", accent = Color3.fromRGB(40, 40, 40) },
	{ id = "nuclearo", name = "Nuclearo Dinossauro", rarity = 7, cost = 500000, income = 60000, body = "croc", bodyColor = Color3.fromRGB(80, 220, 120), headColor = Color3.fromRGB(110, 240, 150), accessory = "crown", accent = Color3.fromRGB(255, 230, 0) },
	{ id = "ondel", name = "Ondel Ondel Oni", rarity = 7, cost = 750000, income = 90000, body = "box", bodyColor = Color3.fromRGB(220, 40, 40), headColor = Color3.fromRGB(240, 80, 80), accessory = "crown", accent = Color3.fromRGB(255, 220, 0) },
}

-- Fast lookup by id, built once when the module loads.
local byId = {}
for _, def in ipairs(BrainrotData.CHARACTERS) do
	byId[def.id] = def
end

function BrainrotData.getById(id)
	return byId[id]
end

function BrainrotData.getRarity(index)
	return BrainrotData.RARITIES[index]
end

-- Roll a rarity index from the weighted table. mythicBoost multiplies the
-- weights of Mythic and above (used by the Brainrot Rain event).
function BrainrotData.rollRarity(mythicBoost)
	local total = 0
	for _, rarity in ipairs(BrainrotData.RARITIES) do
		local weight = rarity.weight
		if mythicBoost and rarity.name ~= "Common" and rarity.name ~= "Rare" and rarity.name ~= "Epic" then
			weight *= 3
		end
		total += weight
	end
	local roll = math.random() * total
	for index, rarity in ipairs(BrainrotData.RARITIES) do
		local weight = rarity.weight
		if mythicBoost and rarity.name ~= "Common" and rarity.name ~= "Rare" and rarity.name ~= "Epic" then
			weight *= 3
		end
		roll -= weight
		if roll <= 0 then
			return index
		end
	end
	return 1
end

-- Pick a random character of the given rarity.
function BrainrotData.rollCharacter(rarityIndex)
	local pool = {}
	for _, def in ipairs(BrainrotData.CHARACTERS) do
		if def.rarity == rarityIndex then
			table.insert(pool, def)
		end
	end
	return pool[math.random(#pool)]
end

-- Roll a mutation from Config.MUTATIONS (rarest first). Returns the name
-- and its income multiplier, or "None", 1 when nothing hits.
function BrainrotData.rollMutation()
	local roll = math.random()
	local cumulative = 0
	for _, mutation in ipairs(Config.MUTATIONS) do
		cumulative += mutation.chance
		if roll < cumulative then
			return mutation.name, mutation.mult
		end
	end
	return "None", 1
end

-- Money per second of one owned brainrot, after its mutation.
function BrainrotData.incomeOf(def, mutationMult)
	return def.income * mutationMult
end

-- Short money text: 1500 -> "$1.5K", 2500000 -> "$2.5M".
function BrainrotData.formatMoney(amount)
	if amount >= 1e9 then
		return string.format("$%.1fB", amount / 1e9)
	elseif amount >= 1e6 then
		return string.format("$%.1fM", amount / 1e6)
	elseif amount >= 1e3 then
		return string.format("$%.1fK", amount / 1e3)
	else
		return string.format("$%d", math.floor(amount + 0.5))
	end
end

return BrainrotData
