-- Config: every tuning number of Steal a Brainrot — Meme Madness lives here,
-- so a balance change is one edit in one place and nothing else moves.
-- Long-term rule: new content is DATA, not logic — a new character is one
-- row in BrainrotData, a new event one row in EventsData, a new gamepass
-- one row in MONETIZATION below. Written for roblox-brainrot-01 (make.fun).

local Config = {}

-- Plots
Config.PLOT_COUNT = 8
Config.PLOT_RADIUS = 130 -- studs from the map centre to a plot centre
Config.PLOT_WIDTH = 34
Config.PLOT_DEPTH = 26
Config.SLOTS_PER_PLOT = 10
Config.SLOT_SPACING_X = 6
Config.SLOT_ROWS_Z = { -6, 6 }
Config.SLOT_COLUMNS_X = { -12, -6, 0, 6, 12 }

-- Conveyor: brainrots walk from -X to +X across the middle of the map.
-- Tuned so the first minute already feels busy: a spawn every 1.5 seconds,
-- up to 24 walkers, and the first ones are cheap on purpose. New spawns
-- start closer to the middle of the belt (SPAWN_X) so they reach the
-- players in seconds instead of walking the whole belt first.
Config.CONVEYOR_START_X = -95
Config.CONVEYOR_SPAWN_X = -40 -- where new brainrots actually appear
Config.CONVEYOR_END_X = 95
Config.CONVEYOR_Z = 0
Config.CONVEYOR_WIDTH = 12
Config.CONVEYOR_WALK_SPEED = 7.5 -- studs per second
Config.SPAWN_INTERVAL = 1.5 -- seconds between spawns (halved during Brainrot Rain)
Config.MAX_CONVEYOR_BRAINROTS = 24

-- Economy
Config.INCOME_TICK = 1 -- seconds between cash ticks
Config.START_CASH = 500 -- enough to buy several Commons right away
-- A new player joins with one free Common already earning on their plot,
-- so the first minute is never spent waiting. The free one is a random
-- Common (rarity 1); turn it off here and nobody gets one.
Config.STARTER_BRAINROT_ENABLED = true
Config.STARTER_BRAINROT_RARITY = 1
Config.REBIRTH_BASE_COST = 75000 -- first rebirth lands after ~5 minutes of play
Config.REBIRTH_COST_EXPONENT = 2 -- cost = base * (rebirths + 1) ^ exponent
Config.REBIRTH_MULT_PER_LEVEL = 0.25 -- +25% income per rebirth
Config.CARRY_SPEED_MULT = 0.8 -- carrying a stolen brainrot slows you down

-- Stealing
Config.BASE_LOCK_SECONDS = 60
Config.BASE_LOCK_COOLDOWN = 120
Config.SLAP_RANGE = 10 -- studs
Config.SLAP_COOLDOWN = 3 -- seconds between slaps
Config.STEAL_HOLD_SECONDS = 0.5 -- ProximityPrompt hold time

-- Raiders: enemy NPCs that attack solo players' bases. One wave every
-- couple of minutes; each wave brings more (and faster) raiders. A raider
-- walks in from the map centre, grabs one brainrot off a plot, and runs —
-- slap it 3 times to drive it off and win a cash bonus. All numbers here,
-- so difficulty is one config edit. Raiders never touch a locked base, a
-- plot with no brainrots, or a spectating player.
Config.RAIDER_FIRST_WAVE_DELAY = 90 -- seconds after the server starts
Config.RAIDER_WAVE_INTERVAL = 105 -- seconds between waves (wave 1)
Config.RAIDER_WAVE_INTERVAL_STEP = 10 -- each later wave comes this much sooner
Config.RAIDER_WAVE_INTERVAL_MIN = 60 -- waves never come faster than this
Config.RAIDER_BASE_COUNT = 1 -- raiders in wave 1
Config.RAIDER_COUNT_PER_WAVE = 1 -- +1 raider each wave after the first
Config.RAIDER_MAX_COUNT = 3 -- never more than this many in one wave
Config.RAIDER_MAX_ALIVE = 6 -- never more than this many raiders on the map
Config.RAIDER_WALK_SPEED = 8 -- studs per second (wave 1)
Config.RAIDER_SPEED_PER_WAVE = 0.5 -- +speed each wave
Config.RAIDER_SPEED_MAX = 12 -- raiders never run faster than this
Config.RAIDER_HITS_TO_FLEE = 3 -- slaps needed to drive one off
Config.RAIDER_KNOCKBACK_STUDS = 18 -- how far one slap throws a raider back
Config.RAIDER_STUN_SECONDS = 0.7 -- a slapped raider freezes this long
Config.RAIDER_GRAB_SECONDS = 2 -- a raider stands at a brainrot this long before taking it
Config.RAIDER_FLEE_SPEED_MULT = 1.5 -- a raider with loot runs this much faster
Config.RAIDER_REWARD_CASH = 100 -- bonus for driving one off
Config.RAIDER_REWARD_PER_WAVE = 25 -- +bonus per wave number

-- Events: one fires on a rotation, each with its own length.
-- The rotation order and the banner text live in EventsData; the numbers
-- live here so tuning never touches the event logic.
Config.EVENT_INTERVAL = 75 -- seconds between events
Config.EVENT_WARNING = 10 -- seconds of warning banner before the event starts
Config.GOLDEN_HOUR_SECONDS = 60
Config.GOLDEN_HOUR_MULT = 2
Config.RAIN_SECONDS = 60
Config.TSUNAMI_SWEEP_SECONDS = 10
Config.TSUNAMI_STUN_SECONDS = 3
Config.METEOR_SECONDS = 60
Config.METEOR_STRIKE_INTERVAL = 6 -- seconds between meteor strikes

-- Mutations: rolled when a brainrot spawns. Multiplies its income.
-- Read rarest-first: the first row whose cumulative chance the roll hits
-- wins. Add a row to add a mutation — no logic change needed.
Config.MUTATIONS = {
	{ name = "Void", chance = 0.005, mult = 15 },
	{ name = "Rainbow", chance = 0.01, mult = 10 },
	{ name = "Diamond", chance = 0.03, mult = 5 },
	{ name = "Lava", chance = 0.05, mult = 3 },
	{ name = "Gold", chance = 0.08, mult = 2 },
}

-- Leaderboard
Config.LEADERBOARD_SIZE = 8
Config.LEADERBOARD_REFRESH = 5 -- seconds

-- Daily reward: the lightest retention hook. A player who comes back on a
-- new day gets cash that grows with their streak (day 1 = base, day 7 =
-- base * 7). Stored in a DataStore when Roblox allows it; if the DataStore
-- is unreachable the reward still works for the session (see
-- DailyRewardService). Streaks reset after a missed day.
Config.DAILY_REWARD_BASE_CASH = 500
Config.DAILY_REWARD_STREAK_MAX = 7
Config.DAILY_DATASTORE_NAME = "MemeMadnessDaily_v1"

-- Monetization: the long-term money foundation. One gamepass or product is
-- ONE ROW here — add the row, create the pass/product on the Creator
-- Dashboard, paste its real asset id in, and the shop, the prompts and the
-- benefits all work. assetId 0 means "not created yet": the shop shows it
-- as coming soon and NEVER prompts a purchase, so a placeholder can never
-- charge anyone. Never paste another game's asset id here.
Config.MONETIZATION = {
	gamepasses = {
		-- Doubles all cash income while owned. Permanent, one-time buy.
		{ id = "doubleCash", name = "2x Cash", description = "Double cash income forever!", priceRobux = 99, assetId = 0, incomeMult = 2 },
		-- VIP: +50% income, a golden VIP tag above your character, and a
		-- golden name on the leaderboard.
		{ id = "vip", name = "VIP", description = "+50% income + golden VIP tag!", priceRobux = 199, assetId = 0, incomeMult = 1.5 },
	},
	developerProducts = {
		-- One-time cash top-up, buyable again and again.
		{ id = "cashPack", name = "Cash Pack", description = "+$25,000 cash instantly!", priceRobux = 49, assetId = 0, cash = 25000 },
	},
}

return Config
