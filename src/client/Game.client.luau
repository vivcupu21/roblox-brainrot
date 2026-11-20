-- Game client: the whole interface over the 3D world. Top-centre cash bar
-- (clear of Roblox's own top-left menu buttons), Lock Base and Rebirth
-- buttons at the bottom, a live leaderboard on the right, event banners and
-- toast notifications, a shop panel for gamepasses and cash packs, and a
-- first-minute tutorial that walks a new player through the loop.
-- All money comes from the server; this script only shows it and fires the
-- button remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local LockBaseRemote = remotes:WaitForChild("LockBase")
local RebirthRemote = remotes:WaitForChild("Rebirth")
local TeleportToBaseRemote = remotes:WaitForChild("TeleportToBase")
local BuyGamepassRemote = remotes:WaitForChild("BuyGamepass")
local BuyProductRemote = remotes:WaitForChild("BuyProduct")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BrainrotData = require(Shared:WaitForChild("BrainrotData"))

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local function makeLabel(parent, name, position, size, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextSize = textSize
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = parent
	return label
end

local function makeButton(parent, name, position, size, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = position
	button.Size = size
	button.Text = text
	button.TextSize = 20
	button.Font = Enum.Font.FredokaOne
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

-- Cash bar, top centre: cash, income per second, rebirths, multiplier.
local cashBar = Instance.new("Frame")
cashBar.Name = "CashBar"
cashBar.AnchorPoint = Vector2.new(0.5, 0)
cashBar.Position = UDim2.new(0.5, 0, 0, 12)
cashBar.Size = UDim2.fromOffset(420, 64)
cashBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
cashBar.BackgroundTransparency = 0.25
cashBar.BorderSizePixel = 0
cashBar.Parent = gui
local cashCorner = Instance.new("UICorner")
cashCorner.CornerRadius = UDim.new(0, 12)
cashCorner.Parent = cashBar

local cashLabel = makeLabel(cashBar, "CashLabel", UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 34), 28, Color3.fromRGB(120, 255, 120))
local incomeLabel = makeLabel(cashBar, "IncomeLabel", UDim2.new(0, 0, 0, 38), UDim2.new(1, 0, 0, 22), 16, Color3.fromRGB(255, 255, 255))

-- Buttons, bottom centre.
local baseButton = makeButton(gui, "BaseButton", UDim2.new(0.5, -350, 1, -76), UDim2.fromOffset(120, 56), "🏠 Base", Color3.fromRGB(40, 160, 140))
local lockButton = makeButton(gui, "LockButton", UDim2.new(0.5, -220, 1, -76), UDim2.fromOffset(200, 56), "🔒 Lock Base (60s)", Color3.fromRGB(60, 120, 220))
local rebirthButton = makeButton(gui, "RebirthButton", UDim2.new(0.5, 20, 1, -76), UDim2.fromOffset(200, 56), "✨ Rebirth", Color3.fromRGB(160, 60, 200))
baseButton.Activated:Connect(function()
	TeleportToBaseRemote:FireServer()
end)
lockButton.Activated:Connect(function()
	LockBaseRemote:FireServer()
end)
rebirthButton.Activated:Connect(function()
	RebirthRemote:FireServer()
end)

-- Goal line above the buttons, so a new player always knows the point.
local goalLabel = makeLabel(gui, "GoalLabel", UDim2.new(0.5, -300, 1, -140), UDim2.new(600, 0, 0, 26), 17, Color3.fromRGB(255, 220, 90))
goalLabel.Text = "🎯 Goal: buy brainrots, fill your base, get rich — reach TOP 1!"

-- Hint line above the buttons: how to play, in one breath.
local hintLabel = makeLabel(gui, "HintLabel", UDim2.new(0.5, -300, 1, -112), UDim2.new(600, 0, 0, 26), 16, Color3.fromRGB(255, 255, 255))
hintLabel.Text = "Hold E on a brainrot to BUY it • Hold E on a rival's brainrot to STEAL it • Slap thieves with your Slap tool!"

-- Event banner, centre screen under the cash bar.
local banner = Instance.new("Frame")
banner.Name = "EventBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 92)
banner.Size = UDim2.fromOffset(460, 70)
banner.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
banner.BackgroundTransparency = 0.15
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = banner
local bannerTitle = makeLabel(banner, "BannerTitle", UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 34), 26, Color3.fromRGB(255, 255, 255))
local bannerSubtitle = makeLabel(banner, "BannerSubtitle", UDim2.new(0, 0, 0, 40), UDim2.new(1, 0, 0, 24), 15, Color3.fromRGB(255, 240, 200))

-- Toast notifications, stacked under the banner.
local toastFrame = Instance.new("Frame")
toastFrame.Name = "ToastFrame"
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.Position = UDim2.new(0.5, 0, 0, 172)
toastFrame.Size = UDim2.fromOffset(460, 120)
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = gui

local function showToast(text)
	local toast = Instance.new("TextLabel")
	toast.Size = UDim2.new(1, 0, 0, 30)
	toast.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	toast.BackgroundTransparency = 0.2
	toast.Text = text
	toast.TextSize = 16
	toast.Font = Enum.Font.FredokaOne
	toast.TextColor3 = Color3.fromRGB(255, 255, 255)
	toast.TextStrokeTransparency = 0
	toast.Parent = toastFrame
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast
	-- Stack newest on top, older ones slide down.
	for _, child in ipairs(toastFrame:GetChildren()) do
		if child:IsA("TextLabel") and child ~= toast then
			child.Position += UDim2.new(0, 0, 0, 34)
		end
	end
	task.delay(4, function()
		toast:Destroy()
	end)
end

-- Leaderboard, right side.
local board = Instance.new("Frame")
board.Name = "Leaderboard"
board.AnchorPoint = Vector2.new(1, 0)
board.Position = UDim2.new(1, -12, 0, 12)
board.Size = UDim2.fromOffset(220, 250)
board.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
board.BackgroundTransparency = 0.25
board.BorderSizePixel = 0
board.Parent = gui
local boardCorner = Instance.new("UICorner")
boardCorner.CornerRadius = UDim.new(0, 12)
boardCorner.Parent = board
local boardTitle = makeLabel(board, "BoardTitle", UDim2.new(0, 0, 0, 6), UDim2.new(1, 0, 0, 26), 18, Color3.fromRGB(255, 220, 90))
boardTitle.Text = "🏆 TOP BRAINROTTERS"
local boardList = Instance.new("Frame")
boardList.Name = "BoardList"
boardList.Position = UDim2.new(0, 8, 0, 38)
boardList.Size = UDim2.new(1, -16, 1, -46)
boardList.BackgroundTransparency = 1
boardList.Parent = board

local function updateLeaderboard(rows)
	for _, child in ipairs(boardList:GetChildren()) do
		child:Destroy()
	end
	for i, row in ipairs(rows) do
		local line = Instance.new("TextLabel")
		line.Size = UDim2.new(1, 0, 0, 24)
		line.Position = UDim2.new(0, 0, 0, (i - 1) * 26)
		line.BackgroundTransparency = 1
		local vipStar = row.vip and "★ " or ""
		line.Text = i .. ". " .. vipStar .. row.name .. " — " .. BrainrotData.formatMoney(row.cash)
		line.TextSize = 15
		line.Font = Enum.Font.FredokaOne
		line.TextColor3 = i == 1 and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(255, 255, 255)
		line.TextXAlignment = Enum.TextXAlignment.Left
		line.TextStrokeTransparency = 0
		line.Parent = boardList
	end
end

-- Daily streak chip, under the leaderboard. Hidden until the server tells
-- us the streak (it fires once per join).
local dailyFrame = Instance.new("Frame")
dailyFrame.Name = "DailyStreak"
dailyFrame.AnchorPoint = Vector2.new(1, 0)
dailyFrame.Position = UDim2.new(1, -12, 0, 274)
dailyFrame.Size = UDim2.fromOffset(220, 36)
dailyFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
dailyFrame.BackgroundTransparency = 0.25
dailyFrame.BorderSizePixel = 0
dailyFrame.Visible = false
dailyFrame.Parent = gui
local dailyCorner = Instance.new("UICorner")
dailyCorner.CornerRadius = UDim.new(0, 10)
dailyCorner.Parent = dailyFrame
local dailyLabel = makeLabel(dailyFrame, "DailyLabel", UDim2.new(0, 0, 0, 5), UDim2.new(1, 0, 0, 26), 16, Color3.fromRGB(255, 220, 90))

-- Shop: a button bottom-right and a panel that lists every gamepass and
-- product the server sends. Items the owner has not created yet show as
-- coming soon and cannot be bought.
local shopButton = makeButton(gui, "ShopButton", UDim2.new(1, -132, 1, -76), UDim2.fromOffset(120, 56), "🛒 Shop", Color3.fromRGB(40, 180, 90))

local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(1, 0.5)
shopPanel.Position = UDim2.new(1, -12, 0.5, 0)
shopPanel.Size = UDim2.fromOffset(330, 380)
shopPanel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
shopPanel.BackgroundTransparency = 0.1
shopPanel.BorderSizePixel = 0
shopPanel.Visible = false
shopPanel.Parent = gui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopPanel
local shopTitle = makeLabel(shopPanel, "ShopTitle", UDim2.new(0, 0, 0, 8), UDim2.new(1, 0, 0, 30), 22, Color3.fromRGB(255, 220, 90))
shopTitle.Text = "🛒 SHOP"
local shopClose = makeButton(shopPanel, "ShopClose", UDim2.new(1, -44, 0, 8), UDim2.fromOffset(36, 30), "X", Color3.fromRGB(200, 60, 60))
shopClose.TextSize = 18
local shopList = Instance.new("Frame")
shopList.Name = "ShopList"
shopList.Position = UDim2.new(0, 10, 0, 48)
shopList.Size = UDim2.new(1, -20, 1, -58)
shopList.BackgroundTransparency = 1
shopList.Parent = shopPanel

shopButton.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
end)
shopClose.Activated:Connect(function()
	shopPanel.Visible = false
end)

local function buildShopRow(y, item, isProduct)
	local row = Instance.new("Frame")
	row.Position = UDim2.new(0, 0, 0, y)
	row.Size = UDim2.new(1, 0, 0, 64)
	row.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
	row.BorderSizePixel = 0
	row.Parent = shopList
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 8)
	rowCorner.Parent = row
	local nameLabel = makeLabel(row, "ItemName", UDim2.new(0, 10, 0, 4), UDim2.new(1, -120, 0, 24), 17, Color3.fromRGB(255, 255, 255))
	nameLabel.Text = item.name
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	local descLabel = makeLabel(row, "ItemDesc", UDim2.new(0, 10, 0, 30), UDim2.new(1, -120, 0, 30), 13, Color3.fromRGB(200, 200, 220))
	descLabel.Text = item.description
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.TextWrapped = true
	local buyButton = makeButton(row, "BuyButton", UDim2.new(1, -104, 0, 12), UDim2.fromOffset(94, 40), "", Color3.fromRGB(40, 180, 90))
	buyButton.TextSize = 16
	if item.owned then
		buyButton.Text = "OWNED ✓"
		buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		buyButton.AutoButtonColor = false
	elseif not item.available then
		buyButton.Text = "SOON"
		buyButton.BackgroundColor3 = Color3.fromRGB(90, 90, 110)
		buyButton.AutoButtonColor = false
	else
		buyButton.Text = "R$" .. item.priceRobux
		buyButton.Activated:Connect(function()
			if isProduct then
				BuyProductRemote:FireServer(item.id)
			else
				BuyGamepassRemote:FireServer(item.id)
			end
		end)
	end
	return row
end

local function updateShop(gamepasses, products)
	for _, child in ipairs(shopList:GetChildren()) do
		child:Destroy()
	end
	local y = 0
	local section = makeLabel(shopList, "PassSection", UDim2.new(0, 0, 0, y), UDim2.new(1, 0, 0, 22), 15, Color3.fromRGB(255, 220, 90))
	section.Text = "— GAMEPASSES (forever) —"
	section.TextXAlignment = Enum.TextXAlignment.Left
	y += 26
	for _, item in ipairs(gamepasses) do
		buildShopRow(y, item, false)
		y += 72
	end
	local productSection = makeLabel(shopList, "ProductSection", UDim2.new(0, 0, 0, y), UDim2.new(1, 0, 0, 22), 15, Color3.fromRGB(255, 220, 90))
	productSection.Text = "— CASH (buy again and again) —"
	productSection.TextXAlignment = Enum.TextXAlignment.Left
	y += 26
	for _, item in ipairs(products) do
		buildShopRow(y, item, true)
		y += 72
	end
end

-- Server pushes.
remotes:WaitForChild("CashUpdate").OnClientEvent:Connect(function(cash, incomePerSecond, rebirths, mult)
	cashLabel.Text = BrainrotData.formatMoney(cash)
	incomeLabel.Text = "+" .. BrainrotData.formatMoney(incomePerSecond) .. "/s   •   Rebirth " .. rebirths .. "   •   x" .. string.format("%.2f", mult)
end)

remotes:WaitForChild("Notify").OnClientEvent:Connect(function(text)
	showToast(text)
end)

remotes:WaitForChild("EventBanner").OnClientEvent:Connect(function(title, subtitle, seconds)
	bannerTitle.Text = title
	bannerSubtitle.Text = subtitle
	banner.Visible = true
	task.delay(seconds, function()
		banner.Visible = false
	end)
end)

remotes:WaitForChild("LeaderboardUpdate").OnClientEvent:Connect(function(rows)
	updateLeaderboard(rows)
end)

remotes:WaitForChild("ShopUpdate").OnClientEvent:Connect(function(gamepasses, products)
	updateShop(gamepasses, products)
end)

remotes:WaitForChild("DailyReward").OnClientEvent:Connect(function(streak, reward, alreadyClaimed)
	dailyLabel.Text = "📅 Daily streak: " .. streak .. " day" .. (streak > 1 and "s" or "")
	dailyFrame.Visible = true
	if not alreadyClaimed and reward > 0 then
		showToast("Daily reward! Day " .. streak .. ": +" .. BrainrotData.formatMoney(reward) .. " cash!")
	end
end)

-- First-minute tutorial: three steps, staggered, so a brand-new player is
-- never left guessing what to do.
showToast("Welcome to Steal a Brainrot! Buy brainrots off the conveyor, fill your base, and guard it!")
task.delay(5, function()
	showToast("STEP 1: walk to the conveyor and hold E on a brainrot to BUY it!")
end)
task.delay(11, function()
	showToast("STEP 2: your brainrots earn cash every second in your base. Buy more!")
end)
task.delay(17, function()
	showToast("STEP 3: hold E on a rival's brainrot to STEAL it — or lock your base!")
end)
