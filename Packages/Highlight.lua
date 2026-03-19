--!strict
--[[
	Highlight
	Manages a Roblox Highlight instance attached to a BasePart or Model with a
	looping sine-wave pulse on OutlineTransparency. The pulse is driven by
	calling :Pulse(dt) each Heartbeat — the controller owns no connections of
	its own, keeping cleanup simple and deterministic.

	Completely decoupled from SpotlightUI. Use it anywhere you want a pulsing
	selection glow on a world object: map markers, quest targets, tutorial props.

	Usage:
		local Highlight = require(path.to.Highlight)

		local hl = Highlight.new(workspace.SomePart)

		local conn = RunService.Heartbeat:Connect(function(dt)
			hl:Pulse(dt)
		end)

		-- When done:
		conn:Disconnect()
		hl:Detach()

	Custom config:
		local hl = Highlight.new(workspace.SomePart, {
			Color      = Color3.fromRGB(100, 200, 255),
			FillAlpha  = 0.12,
			PulseSpeed = 3.0,
			MinOutline = 0.1,
			MaxOutline = 0.9,
		})
--]]

-- ─── Types ────────────────────────────────────────────────────────────────────

export type HighlightConfig = {
	Color: Color3?,
	FillAlpha: number?,
	PulseSpeed: number?,
	MinOutline: number?,
	MaxOutline: number?,
}

export type HighlightController = {
	Pulse: (self: HighlightController, dt: number) -> (),
	Detach: (self: HighlightController) -> (),
	IsAlive: (self: HighlightController) -> boolean,
	SetColor: (self: HighlightController, color: Color3) -> (),
	SetPulseSpeed: (self: HighlightController, speed: number) -> (),
}

-- ─── Constants ────────────────────────────────────────────────────────────────

local DefaultColor = Color3.fromRGB(255, 220, 80)
local DefaultFillAlpha = 0.08
local DefaultPulseSpeed = 2.0
local DefaultMinOutline = 0.0
local DefaultMaxOutline = 0.8

-- ─── Implementation ───────────────────────────────────────────────────────────

type HighlightData = {
	highlight: Highlight,
	inst: Instance,
	pulseSpeed: number,
	minOutline: number,
	maxOutline: number,
	clock: number,
}

type HighlightImpl = HighlightData & {
	Pulse: (self: HighlightImpl, dt: number) -> (),
	Detach: (self: HighlightImpl) -> (),
	IsAlive: (self: HighlightImpl) -> boolean,
	SetColor: (self: HighlightImpl, color: Color3) -> (),
	SetPulseSpeed: (self: HighlightImpl, speed: number) -> (),
}

local HighlightClass = {}
HighlightClass.__index = HighlightClass

--[=[
	Creates and attaches a Highlight instance to `inst`.

	@param inst   -- The BasePart, Model, or other Instance to adorn.
	@param config -- Optional config overrides.
	@return HighlightController
]=]
function HighlightClass.new(inst: Instance, config: HighlightConfig?): HighlightController
	local cfg = config or {} :: HighlightConfig

	local color = cfg.Color or DefaultColor
	local fillAlpha = cfg.FillAlpha or DefaultFillAlpha
	local pulseSpeed = cfg.PulseSpeed or DefaultPulseSpeed
	local minOutline = cfg.MinOutline or DefaultMinOutline
	local maxOutline = cfg.MaxOutline or DefaultMaxOutline

	local hl = Instance.new("Highlight")
	hl.FillColor = color
	hl.FillTransparency = 1 - fillAlpha
	hl.OutlineColor = color
	hl.OutlineTransparency = minOutline
	hl.Adornee = inst
	hl.Parent = inst

	local self: HighlightData = {
		highlight = hl,
		inst = inst,
		pulseSpeed = pulseSpeed,
		minOutline = minOutline,
		maxOutline = maxOutline,
		clock = 0,
	}

	return setmetatable(self, HighlightClass) :: any
end

--[=[
	Advances the pulse animation by `dt` seconds.
	Call this every Heartbeat for as long as the highlight is active.

	The pulse maps a sine wave to the range [MinOutline, MaxOutline], giving a
	smooth breathing effect on the outline transparency.

	@param dt -- Delta time in seconds.
]=]
function HighlightClass:Pulse(dt: number)
	local self = self :: HighlightImpl
	if not self:IsAlive() then return end

	self.clock += dt * self.pulseSpeed
	local t = (math.sin(self.clock) + 1) / 2
	self.highlight.OutlineTransparency = self.minOutline + t * (self.maxOutline - self.minOutline)
end

--[=[
	Destroys the Highlight instance and releases the reference.
	Safe to call multiple times.
]=]
function HighlightClass:Detach()
	local self = self :: HighlightImpl
	if self.highlight and self.highlight.Parent then
		self.highlight:Destroy()
	end
	self.highlight = nil :: any
end

--[=[
	Returns true if the Highlight is still alive and both the highlight and
	its adorned instance are still parented in the DataModel.

	@return boolean
]=]
function HighlightClass:IsAlive(): boolean
	local self = self :: HighlightImpl
	return self.highlight ~= nil
		and self.highlight.Parent ~= nil
		and self.inst ~= nil
		and self.inst.Parent ~= nil
end

--[=[
	Changes the fill and outline colour on the fly.

	@param color -- The new Color3 to apply.
]=]
function HighlightClass:SetColor(color: Color3)
	local self = self :: HighlightImpl
	if not self:IsAlive() then return end
	self.highlight.FillColor = color
	self.highlight.OutlineColor = color
end

--[=[
	Changes the pulse speed on the fly.

	@param speed -- New speed in radians per second.
]=]
function HighlightClass:SetPulseSpeed(speed: number)
	local self = self :: HighlightImpl
	self.pulseSpeed = speed
end

-- ─── Static ───────────────────────────────────────────────────────────────────

export type StaticHighlight = {
	new: (inst: Instance, config: HighlightConfig?) -> HighlightController,
}

return HighlightClass :: StaticHighlight