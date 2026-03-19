--!strict
--[[
	AnimationUtil
	Tween factory helpers for SpotlightUI's three animation categories:
	fade (show/hide), pulse (breathing size/alpha), and shape (corner radius).

	Every function accepts an optional TweenConfig override table so callers can
	adjust duration or easing on a per-call basis without touching the module
	defaults. The Play variants fire-and-forget; the non-Play variants return the
	Tween for manual control (pause, cancel, chaining).

	Usage:
		local AnimationUtil = require(path.to.AnimationUtil)

		-- Fire and forget:
		AnimationUtil.FadePlay(hint, { BackgroundTransparency = 0 })

		-- Manual control:
		local t = AnimationUtil.Fade(hint, { TextTransparency = 1 })
		t:Play()
		t.Completed:Wait()

		-- Override duration for one call:
		AnimationUtil.FadePlay(hint, { BackgroundTransparency = 1 }, {
			Duration = 0.1,
		})

	Accessing defaults:
		AnimationUtil.Defaults.Fade.Duration  --> 0.25
		AnimationUtil.Defaults.Pulse.Duration --> 1.2
		AnimationUtil.Defaults.Shape.Duration --> 0.4
--]]

local TweenService = game:GetService("TweenService")

-- ─── Types ────────────────────────────────────────────────────────────────────

type TweenPreset = {
	Duration: number,
	EasingStyle: Enum.EasingStyle,
	EasingDirection: Enum.EasingDirection,
}

export type TweenConfig = {
	Duration: number?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
	RepeatCount: number?,
	Reverses: boolean?,
	DelayTime: number?,
}

export type AnimationUtilType = {
	Fade: (instance: Instance, properties: { [string]: any }, overrides: TweenConfig?) -> Tween,
	FadePlay: (instance: Instance, properties: { [string]: any }, overrides: TweenConfig?) -> (),
	Pulse: (instance: Instance, properties: { [string]: any }, overrides: TweenConfig?) -> Tween,
	PulsePlay: (instance: Instance, properties: { [string]: any }, overrides: TweenConfig?) -> (),
	Shape: (instance: Instance, properties: { [string]: any }, overrides: TweenConfig?) -> Tween,
	ShapePlay: (instance: Instance, properties: { [string]: any }, overrides: TweenConfig?) -> (),
	Custom: (instance: Instance, properties: { [string]: any }, config: TweenConfig) -> Tween,
	CustomPlay: (instance: Instance, properties: { [string]: any }, config: TweenConfig) -> (),
	Defaults: {
		Fade: TweenPreset,
		Pulse: TweenPreset,
		Shape: TweenPreset,
	},
}

-- ─── Defaults ─────────────────────────────────────────────────────────────────

local Defaults: { Fade: TweenPreset, Pulse: TweenPreset, Shape: TweenPreset } = {
	Fade = {
		Duration = 0.25,
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,
	},
	Pulse = {
		Duration = 1.2,
		EasingStyle = Enum.EasingStyle.Sine,
		EasingDirection = Enum.EasingDirection.InOut,
	},
	Shape = {
		Duration = 0.4,
		EasingStyle = Enum.EasingStyle.Quint,
		EasingDirection = Enum.EasingDirection.Out,
	},
}

-- ─── Internal factory ─────────────────────────────────────────────────────────

local function buildTween(
	instance: Instance,
	properties: { [string]: any },
	preset: TweenPreset,
	overrides: TweenConfig?
): Tween
	local cfg = overrides or {}
	local info = TweenInfo.new(
		cfg.Duration or preset.Duration,
		cfg.EasingStyle or preset.EasingStyle,
		cfg.EasingDirection or preset.EasingDirection,
		cfg.RepeatCount or 0,
		cfg.Reverses or false,
		cfg.DelayTime or 0
	)
	return TweenService:Create(instance, info, properties)
end

-- ─── Public API ───────────────────────────────────────────────────────────────

local AnimationUtil = {}

--[=[
	Creates a fade tween. Used for opacity transitions: showing and hiding
	overlays, hint labels, and the spotlight stroke.

	@param instance   -- The Instance to tween.
	@param properties -- Property table, e.g. { BackgroundTransparency = 0 }.
	@param overrides  -- Optional TweenConfig overrides.
	@return Tween
]=]
function AnimationUtil.Fade(
	instance: Instance,
	properties: { [string]: any },
	overrides: TweenConfig?
): Tween
	return buildTween(instance, properties, Defaults.Fade, overrides)
end

--[=[
	Creates and immediately plays a fade tween (fire-and-forget).

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param overrides  -- Optional TweenConfig overrides.
]=]
function AnimationUtil.FadePlay(
	instance: Instance,
	properties: { [string]: any },
	overrides: TweenConfig?
)
	buildTween(instance, properties, Defaults.Fade, overrides):Play()
end

--[=[
	Creates a pulse tween. Used for breathing size/alpha animations on the
	spotlight and pulse driver.

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param overrides  -- Optional TweenConfig overrides.
	@return Tween
]=]
function AnimationUtil.Pulse(
	instance: Instance,
	properties: { [string]: any },
	overrides: TweenConfig?
): Tween
	return buildTween(instance, properties, Defaults.Pulse, overrides)
end

--[=[
	Creates and immediately plays a pulse tween (fire-and-forget).

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param overrides  -- Optional TweenConfig overrides.
]=]
function AnimationUtil.PulsePlay(
	instance: Instance,
	properties: { [string]: any },
	overrides: TweenConfig?
)
	buildTween(instance, properties, Defaults.Pulse, overrides):Play()
end

--[=[
	Creates a shape tween. Used for animating UICorner CornerRadius when
	transitioning between spotlight shapes (Circle → Square → Rounded etc.).

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param overrides  -- Optional TweenConfig overrides.
	@return Tween
]=]
function AnimationUtil.Shape(
	instance: Instance,
	properties: { [string]: any },
	overrides: TweenConfig?
): Tween
	return buildTween(instance, properties, Defaults.Shape, overrides)
end

--[=[
	Creates and immediately plays a shape tween (fire-and-forget).

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param overrides  -- Optional TweenConfig overrides.
]=]
function AnimationUtil.ShapePlay(
	instance: Instance,
	properties: { [string]: any },
	overrides: TweenConfig?
)
	buildTween(instance, properties, Defaults.Shape, overrides):Play()
end

--[=[
	Creates a fully custom tween with an explicit TweenConfig. Use this when
	none of the three presets fit and you need exact control over all parameters.

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param config     -- Full TweenConfig (all fields optional, defaults to Fade preset for any missing).
	@return Tween
]=]
function AnimationUtil.Custom(
	instance: Instance,
	properties: { [string]: any },
	config: TweenConfig
): Tween
	return buildTween(instance, properties, Defaults.Fade, config)
end

--[=[
	Creates and immediately plays a custom tween (fire-and-forget).

	@param instance   -- The Instance to tween.
	@param properties -- Property table.
	@param config     -- Full TweenConfig.
]=]
function AnimationUtil.CustomPlay(
	instance: Instance,
	properties: { [string]: any },
	config: TweenConfig
)
	buildTween(instance, properties, Defaults.Fade, config):Play()
end

AnimationUtil.Defaults = Defaults

return AnimationUtil :: AnimationUtilType