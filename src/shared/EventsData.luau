-- EventsData: the whole event rotation as data. EventService reads this
-- table in order and calls the handler named by each row's `id`.
-- ADDING AN EVENT: add one row here with its banner text and length, then
-- add one handler function of the same id in EventService. The rotation,
-- the banners and the timing all follow from this table — no other file
-- needs to know the event exists.

local EventsData = {}

EventsData.EVENTS = {
	{
		id = "tsunami",
		title = "TSUNAMI INCOMING!",
		subtitle = "Run to your base — the wave is coming!",
		runningTitle = "TSUNAMI!",
		runningSubtitle = "The wave is sweeping the map!",
		warningSeconds = 10, -- from Config.EVENT_WARNING
		durationSeconds = 10, -- from Config.TSUNAMI_SWEEP_SECONDS
	},
	{
		id = "goldenHour",
		title = "GOLDEN HOUR!",
		subtitle = "Everyone earns DOUBLE for 60 seconds!",
		warningSeconds = 0,
		durationSeconds = 60, -- from Config.GOLDEN_HOUR_SECONDS
	},
	{
		id = "brainrotRain",
		title = "BRAINROT RAIN!",
		subtitle = "Double spawns, triple rare chance for 60 seconds!",
		warningSeconds = 0,
		durationSeconds = 60, -- from Config.RAIN_SECONDS
	},
	{
		id = "meteorShower",
		title = "METEOR SHOWER!",
		subtitle = "Meteors are falling — each one drops a rare mutated brainrot!",
		warningSeconds = 0,
		durationSeconds = 60, -- from Config.METEOR_SECONDS
	},
}

return EventsData
