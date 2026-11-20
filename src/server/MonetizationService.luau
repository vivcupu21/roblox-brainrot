-- MonetizationService: the game's shop and its long-term money foundation.
-- Everything about a purchase lives in Config.MONETIZATION: one row per
-- gamepass or developer product. Add a row there, create the pass/product
-- on the Creator Dashboard, paste its real asset id in, and the shop, the
-- prompts and the benefits all work — no code change.
--
-- Safety rule: assetId 0 means "not created yet". The shop shows it as
-- coming soon and the server NEVER prompts a purchase for it, so a
-- placeholder can never charge anyone. Marketplace calls are all
-- pcall-guarded: if Roblox cannot be reached (Studio without API access,
-- an unpublished place), the game just plays on without paid benefits.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local PlayerState = require(script.Parent.PlayerState)
local EconomyService = require(script.Parent.EconomyService)
local Remotes = require(script.Parent.Remotes)

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local MonetizationService = {}
local processedReceipts = {} -- [PurchaseId] = true, so a retried receipt never pays twice

local function findGamepass(id)
	for _, pass in ipairs(Config.MONETIZATION.gamepasses) do
		if pass.id == id then
			return pass
		end
	end
	return nil
end

local function findProduct(id)
	for _, product in ipairs(Config.MONETIZATION.developerProducts) do
		if product.id == id then
			return product
		end
	end
	return nil
end

-- What the client needs to draw the shop: every item, its price, whether
-- it can be bought yet, and whether this player already owns it.
function MonetizationService.pushShopUpdate(player)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	local gamepasses = {}
	for _, pass in ipairs(Config.MONETIZATION.gamepasses) do
		local owned = false
		if pass.id == "doubleCash" then
			owned = state.hasDoubleCash
		elseif pass.id == "vip" then
			owned = state.isVip
		end
		table.insert(gamepasses, {
			id = pass.id,
			name = pass.name,
			description = pass.description,
			priceRobux = pass.priceRobux,
			available = pass.assetId > 0,
			owned = owned,
		})
	end
	local products = {}
	for _, product in ipairs(Config.MONETIZATION.developerProducts) do
		table.insert(products, {
			id = product.id,
			name = product.name,
			description = product.description,
			priceRobux = product.priceRobux,
			available = product.assetId > 0,
		})
	end
	Remotes.ShopUpdate:FireClient(player, gamepasses, products)
end

-- Apply a gamepass's benefit to a player who owns it.
function MonetizationService.applyGamepass(player, passId)
	local state = PlayerState.get(player)
	if not state then
		return
	end
	if passId == "doubleCash" then
		state.hasDoubleCash = true
	elseif passId == "vip" then
		state.isVip = true
		MonetizationService.attachVipTag(player)
	end
	PlayerState.recomputePassMult(state)
	EconomyService.pushCashUpdate(state)
	MonetizationService.pushShopUpdate(player)
end

-- A golden VIP tag floating above the player's head. Re-attached on every
-- respawn while the player is VIP.
function MonetizationService.attachVipTag(player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root or root:FindFirstChild("VipTag") then
		return
	end
	local tag = Instance.new("BillboardGui")
	tag.Name = "VipTag"
	tag.Size = UDim2.fromOffset(80, 26)
	tag.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	tag.AlwaysOnTop = true
	tag.Parent = root
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "★ VIP ★"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextStrokeTransparency = 0
	label.Parent = tag
end

-- Check the gamepasses this player already owns (for example bought on a
-- previous visit) and apply them. Runs on join; errors mean "not owned".
function MonetizationService.checkOwnedPasses(player)
	for _, pass in ipairs(Config.MONETIZATION.gamepasses) do
		if pass.assetId > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.assetId)
			end)
			if ok and owns then
				MonetizationService.applyGamepass(player, pass.id)
			end
		end
	end
	MonetizationService.pushShopUpdate(player)
end

-- Developer products pay out here. Roblox retries a receipt it never got
-- an answer for, so processed PurchaseIds are remembered in this session.
function MonetizationService.processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if processedReceipts[receiptInfo.PurchaseId] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	for _, product in ipairs(Config.MONETIZATION.developerProducts) do
		if product.assetId > 0 and receiptInfo.ProductId == product.assetId then
			local state = PlayerState.get(player)
			if not state then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end
			processedReceipts[receiptInfo.PurchaseId] = true
			state.cash += product.cash
			EconomyService.pushCashUpdate(state)
			EconomyService.notify(player, product.name .. " bought! +" .. product.cash .. " cash!")
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function MonetizationService.init()
	Remotes.BuyGamepass.OnServerEvent:Connect(function(player, passId)
		local pass = findGamepass(passId)
		if not pass then
			return
		end
		if pass.assetId <= 0 then
			EconomyService.notify(player, pass.name .. " is coming soon — the owner is still setting it up!")
			return
		end
		local ok = pcall(function()
			MarketplaceService:PromptGamePassPurchase(player, pass.assetId)
		end)
		if not ok then
			EconomyService.notify(player, "The shop is unavailable right now, try again later.")
		end
	end)

	Remotes.BuyProduct.OnServerEvent:Connect(function(player, productId)
		local product = findProduct(productId)
		if not product then
			return
		end
		if product.assetId <= 0 then
			EconomyService.notify(player, product.name .. " is coming soon — the owner is still setting it up!")
			return
		end
		local ok = pcall(function()
			MarketplaceService:PromptProductPurchase(player, product.assetId)
		end)
		if not ok then
			EconomyService.notify(player, "The shop is unavailable right now, try again later.")
		end
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end
		for _, pass in ipairs(Config.MONETIZATION.gamepasses) do
			if pass.assetId == gamePassId then
				MonetizationService.applyGamepass(player, pass.id)
				EconomyService.notify(player, pass.name .. " unlocked! Enjoy the boost!")
				break
			end
		end
	end)

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return MonetizationService.processReceipt(receiptInfo)
	end

	Players.PlayerAdded:Connect(function(player)
		-- Wait one beat so PlayerState exists before the ownership check.
		task.wait(1)
		MonetizationService.checkOwnedPasses(player)
		player.CharacterAdded:Connect(function()
			local state = PlayerState.get(player)
			if state and state.isVip then
				task.wait(0.5)
				MonetizationService.attachVipTag(player)
			end
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(1)
			MonetizationService.checkOwnedPasses(player)
		end)
	end
end

return MonetizationService
