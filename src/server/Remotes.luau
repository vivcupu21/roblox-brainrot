-- Remotes: creates every RemoteEvent the game uses, once, and hands the same
-- table to every service that needs one. Client-to-server: LockBase, Rebirth,
-- BuyGamepass, BuyProduct. Server-to-client: CashUpdate, Notify, EventBanner,
-- LeaderboardUpdate, ShopUpdate, DailyReward.
-- Buys and steals go through ProximityPrompts, so they need no remote at all.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local folder = Instance.new("Folder")
folder.Name = "BrainrotRemotes"
folder.Parent = ReplicatedStorage

local function makeRemote(name)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	Remotes[name] = remote
	return remote
end

makeRemote("LockBase")
makeRemote("Rebirth")
makeRemote("TeleportToBase")
makeRemote("BuyGamepass")
makeRemote("BuyProduct")
makeRemote("CashUpdate")
makeRemote("Notify")
makeRemote("EventBanner")
makeRemote("LeaderboardUpdate")
makeRemote("ShopUpdate")
makeRemote("DailyReward")

return Remotes
