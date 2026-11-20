-- PlotService: owns the eight plots — who owns which, which slots are free,
-- and putting a brainrot on a slot or taking it off again.

local WorldBuilder = require(script.Parent.WorldBuilder)
local PlayerState = require(script.Parent.PlayerState)

local PlotService = {}
PlotService.plots = {}

function PlotService.init(world)
	PlotService.plots = world.plots
end

function PlotService.assignPlot(player)
	for _, plot in ipairs(PlotService.plots) do
		if plot.owner == nil then
			plot.owner = player
			local state = PlayerState.get(player)
			if state then
				state.plotId = plot.id
			end
			WorldBuilder.setPlotSign(plot, player.DisplayName .. "'s Base", Color3.fromRGB(120, 255, 120))
			return plot
		end
	end
	return nil
end

function PlotService.getPlotOf(player)
	local state = PlayerState.get(player)
	if not state or not state.plotId then
		return nil
	end
	return PlotService.plots[state.plotId]
end

function PlotService.releasePlot(player)
	local plot = PlotService.getPlotOf(player)
	if not plot then
		return
	end
	-- Every brainrot on the plot walks off and despawns with its owner.
	for _, slot in ipairs(plot.slots) do
		if slot.occupiedBy and slot.occupiedBy.model then
			slot.occupiedBy.model:Destroy()
		end
		slot.occupiedBy = nil
	end
	plot.owner = nil
	WorldBuilder.setPlotSign(plot, "FREE PLOT", Color3.fromRGB(255, 255, 255))
end

-- First free slot on a plot, or nil when the base is full.
function PlotService.findFreeSlot(plot)
	for index, slot in ipairs(plot.slots) do
		if slot.occupiedBy == nil then
			return index, slot
		end
	end
	return nil, nil
end

-- Stand a brainrot model on a slot and record the ownership.
function PlotService.placeOnSlot(plot, slotIndex, owned)
	local slot = plot.slots[slotIndex]
	if not slot or slot.occupiedBy ~= nil then
		return false
	end
	slot.occupiedBy = owned
	owned.slotIndex = slotIndex
	owned.model:PivotTo(CFrame.new(slot.position))
	return true
end

-- Lift a brainrot off its slot (steal or rebirth). The model is NOT destroyed.
function PlotService.removeFromSlot(plot, slotIndex)
	local slot = plot.slots[slotIndex]
	if not slot then
		return nil
	end
	local owned = slot.occupiedBy
	slot.occupiedBy = nil
	if owned then
		owned.slotIndex = nil
	end
	return owned
end

-- Is this point inside the given plot's floor rectangle? Used to notice when
-- a player carrying a stolen brainrot walks home with it.
function PlotService.isPointInPlot(plot, point)
	local dx = math.abs(point.X - plot.center.X)
	local dz = math.abs(point.Z - plot.center.Z)
	return dx <= 17 and dz <= 13
end

return PlotService
