--!strict
--[[
	SpotlightUI – Guided Focus Module
	
	Created by: @Vvshenok
	Repository: https://github.com/Vvshenok/SpotlightUI
	Documentation: https://vvshenok.github.io/SpotlightUI/
	License: MIT

	A lightweight spotlight library for drawing player attention to
	UI elements or world objects. Designed for tutorials, onboarding,
	feature highlights, and guided experiences.

	Features:
		• Circle, square, and triangle spotlights
		• Follows UI elements or world objects in real time
		• Optional pulse animation
		• Step-based system for tutorials
		• Simple, chainable API
		• Automatic cleanup with Janitor

	Basic Usage:
		local SpotlightUI = require(path.to.SpotlightUI)

		-- Single spotlight
		SpotlightUI.new()
			:FocusUI(button, 20, "Click here to start!")
			:SetShape("Circle")
			:EnablePulse(10)
			:Show()

	Step-based Tutorial:
		local spotlight = SpotlightUI.new()
		spotlight:SetSteps({
			{ UI = gui.Button1, Text = "First, click this", Shape = "Circle", Pulse = 10 },
			{ Part = workspace.Door, Text = "Now walk to the door", Shape = "Triangle" },
			{ UI = gui.Settings, Text = "Finally, open settings", Shape = "Square" }
		})
		spotlight:Start()

	API Reference:
		See full documentation at https://vvshenok.github.io/SpotlightUI/api/reference/
--]]


local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Types = require(script.Types)
local Signal = require(script.Packages.GoodSignal)
local Janitor = require(script.Packages.Janitor)

export type Spotlight = Types.Spotlight
export type SpotlightStep = Types.SpotlightStep

local Constants = {
	OVERLAY_ALPHA = 0.6,
	DEFAULT_SPOTLIGHT_SIZE = Vector2.new(160, 160),
	HINT_SIZE = Vector2.new(300, 60),
	HINT_OFFSET = 20,
	HINT_PADDING = 10,
	WORLD_RADIUS_PADDING = 1.5,
	TWEEN_DURATION = 0.5,
	FADE_DURATION = 0.25,
	PULSE_DURATION = 1.2,
	SHAPE_TWEEN_DURATION = 0.4,
	MOVE_EASING_STYLE = Enum.EasingStyle.Quint,
	MOVE_EASING_DIRECTION = Enum.EasingDirection.Out,
	FADE_EASING_STYLE = Enum.EasingStyle.Quad,
	FADE_EASING_DIRECTION = Enum.EasingDirection.Out,
	PULSE_EASING_STYLE = Enum.EasingStyle.Sine,
	SHAPE_EASING_STYLE = Enum.EasingStyle.Quint,
	SHAPE_EASING_DIRECTION = Enum.EasingDirection.Out,
	OVERLAY_COLOR = Color3.new(0, 0, 0),
	HINT_BACKGROUND_COLOR = Color3.fromRGB(20, 20, 20),
	HINT_TEXT_COLOR = Color3.new(1, 1, 1),
	HINT_CORNER_RADIUS = 8,
	CIRCLE_CORNER_RADIUS = UDim.new(0.5, 0),
	SQUARE_CORNER_RADIUS = UDim.new(0, 8),
	HINT_FONT = Enum.Font.GothamBold,
	HINT_TEXT_SIZE = 18,
	OVERLAY_ZINDEX = 5,
	HINT_ZINDEX = 11,
}

type SpotlightClass = {
	__index: SpotlightClass,
	new: () -> Spotlight,
	Show: (self: Types.SpotlightImpl) -> Types.SpotlightImpl,
	Hide: (self: Types.SpotlightImpl) -> Types.SpotlightImpl,
	SetShape: (self: Types.SpotlightImpl, shape: string) -> Types.SpotlightImpl,
	EnablePulse: (self: Types.SpotlightImpl, amount: number) -> Types.SpotlightImpl,
	DisablePulse: (self: Types.SpotlightImpl) -> Types.SpotlightImpl,
	FocusUI: (self: Types.SpotlightImpl, ui: GuiObject, padding: number?, text: string?) -> Types.SpotlightImpl,
	FocusWorld: (self: Types.SpotlightImpl, position: Vector3, radius: number, text: string?) -> Types.SpotlightImpl,
	FollowPart: (self: Types.SpotlightImpl, inst: Instance, text: string?) -> Types.SpotlightImpl,
	SetSteps: (self: Types.SpotlightImpl, steps: {SpotlightStep}) -> Types.SpotlightImpl,
	Next: (self: Types.SpotlightImpl) -> Types.SpotlightImpl,
	Start: (self: Types.SpotlightImpl) -> Types.SpotlightImpl,
	Skip: (self: Types.SpotlightImpl) -> Types.SpotlightImpl,
	Destroy: (self: Types.SpotlightImpl) -> (),
	_buildUI: (self: Types.SpotlightImpl) -> (),
	_setupDrivers: (self: Types.SpotlightImpl) -> (),
	_startUpdateLoop: (self: Types.SpotlightImpl) -> (),
	_updateSpotlightLayout: (self: Types.SpotlightImpl) -> (),
	_updateHintPosition: (self: Types.SpotlightImpl) -> (),
	_fadeOverlay: (self: Types.SpotlightImpl, show: boolean) -> (),
	_disconnectFollow: (self: Types.SpotlightImpl) -> (),
	_worldRadiusToPixels: (self: Types.SpotlightImpl, worldPos: Vector3, worldRadius: number) -> number,
	_getWorldRadiusFromInstance: (self: Types.SpotlightImpl, inst: Instance) -> number,
}

local PositionUtil = {}

function PositionUtil.ClampToScreen(pos: Vector2, size: Vector2, screenSize: Vector2): Vector2
	local x = math.clamp(pos.X, size.X / 2, screenSize.X - size.X / 2)
	local y = math.clamp(pos.Y, 0, screenSize.Y - size.Y - Constants.HINT_PADDING)
	return Vector2.new(x, y)
end

function PositionUtil.GetHintPosition(spotlightPos: Vector2, spotlightSize: Vector2, hintSize: Vector2, screenSize: Vector2): Vector2
	local centerX = spotlightPos.X + spotlightSize.X / 2
	local bottomY = spotlightPos.Y + spotlightSize.Y + Constants.HINT_OFFSET
	return PositionUtil.ClampToScreen(Vector2.new(centerX, bottomY), hintSize, screenSize)
end

local AnimationUtil = {
	CreateMoveTween = function(instance: Instance, properties: {[string]: any}): Tween
		local tweenInfo = TweenInfo.new(
			Constants.TWEEN_DURATION,
			Constants.MOVE_EASING_STYLE,
			Constants.MOVE_EASING_DIRECTION
		)
		return TweenService:Create(instance, tweenInfo, properties)
	end,
	CreateFadeTween = function(instance: Instance, properties: {[string]: any}): Tween
		local tweenInfo = TweenInfo.new(
			Constants.FADE_DURATION,
			Constants.FADE_EASING_STYLE,
			Constants.FADE_EASING_DIRECTION
		)
		return TweenService:Create(instance, tweenInfo, properties)
	end,
	CreatePulseTween = function(instance: Instance, properties: {[string]: any}): Tween
		local tweenInfo = TweenInfo.new(
			Constants.PULSE_DURATION,
			Constants.PULSE_EASING_STYLE
		)
		return TweenService:Create(instance, tweenInfo, properties)
	end,
	CreateShapeTween = function(instance: Instance, properties: {[string]: any}): Tween
		local tweenInfo = TweenInfo.new(
			Constants.SHAPE_TWEEN_DURATION,
			Constants.SHAPE_EASING_STYLE,
			Constants.SHAPE_EASING_DIRECTION
		)
		return TweenService:Create(instance, tweenInfo, properties)
	end,
}

local UIBuilder = {
	CreateFrame = function(parent: Instance, properties: {[string]: any}?): Frame
		local frame = Instance.new("Frame")
		frame.BackgroundColor3 = Constants.OVERLAY_COLOR
		frame.BackgroundTransparency = 1
		frame.BorderSizePixel = 0
		frame.Parent = parent

		if properties then
			for key, value in properties do
				(frame :: any)[key] = value
			end
		end

		return frame
	end,
	CreateHintLabel = function(parent: Instance): TextLabel
		local hint = Instance.new("TextLabel")
		hint.Size = UDim2.fromOffset(Constants.HINT_SIZE.X, Constants.HINT_SIZE.Y)
		hint.BackgroundColor3 = Constants.HINT_BACKGROUND_COLOR
		hint.BackgroundTransparency = 1
		hint.TextColor3 = Constants.HINT_TEXT_COLOR
		hint.Font = Constants.HINT_FONT
		hint.TextSize = Constants.HINT_TEXT_SIZE
		hint.TextWrapped = true
		hint.BorderSizePixel = 0
		hint.AnchorPoint = Vector2.new(0.5, 0)
		hint.Text = ""
		hint.ZIndex = Constants.HINT_ZINDEX
		hint.Parent = parent

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, Constants.HINT_CORNER_RADIUS)
		corner.Parent = hint

		return hint
	end,
	CreateTriangle = function(parent: Instance): (Frame, UIStroke)
		local container = Instance.new("Frame")
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		container.Visible = false
		container.ZIndex = Constants.OVERLAY_ZINDEX
		container.Parent = parent

		local triangle = Instance.new("Frame")
		triangle.Size = UDim2.fromScale(1.414, 1.414)
		triangle.Position = UDim2.fromScale(0.5, 0.7)
		triangle.AnchorPoint = Vector2.new(0.5, 0.5)
		triangle.BackgroundTransparency = 1
		triangle.Rotation = 45
		triangle.BorderSizePixel = 0
		triangle.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = triangle

		local stroke = Instance.new("UIStroke")
		stroke.Color = Constants.OVERLAY_COLOR
		stroke.Thickness = 10000
		stroke.Transparency = 1
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Parent = triangle

		local clipper = Instance.new("Frame")
		clipper.Size = UDim2.fromScale(1, 0.5)
		clipper.Position = UDim2.fromScale(0, 0)
		clipper.BackgroundTransparency = 1
		clipper.BorderSizePixel = 0
		clipper.ClipsDescendants = true
		clipper.Parent = container

		triangle.Parent = clipper

		return container, stroke
	end,
}

local player = Players.LocalPlayer :: Player

local Spotlight: SpotlightClass = {} :: SpotlightClass
Spotlight.__index = Spotlight

function Spotlight.new(): Types.Spotlight
	local camera = workspace.CurrentCamera :: Camera
	local janitor = Janitor.new()
	local guiInsetService = game:GetService("GuiService")

	local stepCompletedSignal = Signal.new()
	local sequenceCompletedSignal = Signal.new()

	janitor:Add(stepCompletedSignal, "DisconnectAll")
	janitor:Add(sequenceCompletedSignal, "DisconnectAll")

	local self: Types.SpotlightImpl = setmetatable({
		_gui = (nil :: any) :: ScreenGui,
		_container = (nil :: any) :: Frame,
		_circleMask = (nil :: any) :: Frame,
		_circleStroke = (nil :: any) :: UIStroke,
		_circleCorner = (nil :: any) :: UICorner,
		_triangle = (nil :: any) :: ImageLabel,
		_triangleStroke = (nil :: any) :: UIStroke,
		_hint = (nil :: any) :: TextLabel,
		_hintCorner = (nil :: any) :: UICorner,
		_spotlightPos = Vector2.zero,
		_spotlightSize = Constants.DEFAULT_SPOTLIGHT_SIZE,
		_active = false,
		_pulseEnabled = false,
		_currentShape = "Circle",
		_steps = {},
		_stepIndex = 0,
		_tweenDriver = (nil :: any) :: Vector3Value,
		_pulseDriver = (nil :: any) :: NumberValue,
		_camera = camera,
		_guiInsetService = guiInsetService,
		_pulseThread = (nil :: any) :: thread,
		janitor = janitor,
		stepCompleted = stepCompletedSignal,
		sequenceCompleted = sequenceCompletedSignal,
	}, Spotlight) :: any

	self:_buildUI()
	self:_setupDrivers()
	self:_startUpdateLoop()

	return self :: Types.Spotlight
end

function Spotlight:_buildUI()
	local gui = Instance.new("ScreenGui")
	gui.Name = "SpotlightGui"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	self._gui = gui
	self.janitor:Add(gui, "Destroy")

	local container = UIBuilder.CreateFrame(gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self._container = container

	local circleMask = UIBuilder.CreateFrame(container, {
		Name = "CircleMask",
		BackgroundTransparency = 1,
		ZIndex = Constants.OVERLAY_ZINDEX,
	})
	self._circleMask = circleMask

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = Constants.CIRCLE_CORNER_RADIUS
	circleCorner.Parent = circleMask
	self._circleCorner = circleCorner

	local circleStroke = Instance.new("UIStroke")
	circleStroke.Color = Constants.OVERLAY_COLOR
	circleStroke.Thickness = 10000
	circleStroke.Transparency = 1
	circleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	circleStroke.Parent = circleMask
	self._circleStroke = circleStroke

	local triangleContainer = Instance.new("Frame")
	triangleContainer.BackgroundTransparency = 1
	triangleContainer.BorderSizePixel = 0
	triangleContainer.Visible = false
	triangleContainer.ZIndex = Constants.OVERLAY_ZINDEX
	triangleContainer.Parent = container
	self._triangle = triangleContainer

	local rotatedSquare = Instance.new("Frame")
	rotatedSquare.Size = UDim2.fromScale(1.414, 1.414)
	rotatedSquare.Position = UDim2.fromScale(0.5, 0.65)
	rotatedSquare.AnchorPoint = Vector2.new(0.5, 0.5)
	rotatedSquare.BackgroundTransparency = 1
	rotatedSquare.Rotation = 45
	rotatedSquare.BorderSizePixel = 0

	local squareCorner = Instance.new("UICorner")
	squareCorner.CornerRadius = UDim.new(0, 8)
	squareCorner.Parent = rotatedSquare

	local triangleStroke = Instance.new("UIStroke")
	triangleStroke.Color = Constants.OVERLAY_COLOR
	triangleStroke.Thickness = 10000
	triangleStroke.Transparency = 1
	triangleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	triangleStroke.Parent = rotatedSquare
	self._triangleStroke = triangleStroke

	local clipper = Instance.new("Frame")
	clipper.Size = UDim2.fromScale(1, 0.55)
	clipper.Position = UDim2.fromScale(0, 0)
	clipper.BackgroundTransparency = 1
	clipper.BorderSizePixel = 0
	clipper.ClipsDescendants = true
	clipper.Parent = triangleContainer

	rotatedSquare.Parent = clipper

	local hint = UIBuilder.CreateHintLabel(container)
	self._hint = hint
	self._hintCorner = hint:FindFirstChildOfClass("UICorner") :: UICorner
end

function Spotlight:_setupDrivers()
	local tweenDriver = Instance.new("Vector3Value")
	tweenDriver.Value = Vector3.new(
		self._spotlightPos.X,
		self._spotlightPos.Y,
		self._spotlightSize.X
	)
	self._tweenDriver = tweenDriver

	local pulseDriver = Instance.new("NumberValue")
	pulseDriver.Value = 0
	self._pulseDriver = pulseDriver
end

function Spotlight:_startUpdateLoop()
	self.janitor:Add(RunService.RenderStepped:Connect(function()
		if not self._active then return end

		self._spotlightPos = Vector2.new(
			self._tweenDriver.Value.X,
			self._tweenDriver.Value.Y
		)

		local baseSize: number = self._tweenDriver.Value.Z
		local pulseOffset: number = self._pulseDriver.Value

		self._spotlightSize = Vector2.new(
			baseSize + pulseOffset,
			baseSize + pulseOffset
		)

		self:_updateSpotlightLayout()
		self:_updateHintPosition()
	end), "Disconnect")
end

function Spotlight:_updateSpotlightLayout()
	local x = self._spotlightPos.X
	local y = self._spotlightPos.Y
	local size = self._spotlightSize.X

	if self._currentShape == "Triangle" then
		self._circleMask.Visible = false
		self._triangle.Visible = true
		self._triangle.Position = UDim2.fromOffset(x, y)
		self._triangle.Size = UDim2.fromOffset(size, size)
	else
		self._circleMask.Visible = true
		self._triangle.Visible = false
		self._circleMask.Position = UDim2.fromOffset(x, y)
		self._circleMask.Size = UDim2.fromOffset(size, size)
	end
end

function Spotlight:_updateHintPosition()
	local screen: Vector2 = self._container.AbsoluteSize
	local hintSize: Vector2 = self._hint.AbsoluteSize

	local position = PositionUtil.GetHintPosition(
		self._spotlightPos,
		self._spotlightSize,
		hintSize,
		screen
	)

	self._hint.Position = UDim2.fromOffset(position.X, position.Y)
end

function Spotlight:_fadeOverlay(show: boolean)
	local transparency = show and (1 - Constants.OVERLAY_ALPHA) or 1

	AnimationUtil.CreateFadeTween(self._circleStroke, {
		Transparency = transparency
	}):Play()

	AnimationUtil.CreateFadeTween(self._triangleStroke, {
		Transparency = transparency
	}):Play()

	AnimationUtil.CreateFadeTween(self._hint, {
		BackgroundTransparency = show and 0.15 or 1,
		TextTransparency = show and 0 or 1
	}):Play()
end

function Spotlight:_disconnectFollow()
	self.janitor:Remove("FollowConnection")
end

function Spotlight:_worldRadiusToPixels(worldPos: Vector3, worldRadius: number): number
	local cam = self._camera
	local center, onScreen = cam:WorldToViewportPoint(worldPos)
	if not onScreen or center.Z <= 0 then
		return 0
	end

	local depth = center.Z
	local fov = math.rad(cam.FieldOfView)
	local pixelsPerStud = (cam.ViewportSize.Y / 2) / (math.tan(fov / 2) * depth)

	return worldRadius * pixelsPerStud
end

function Spotlight:_getWorldRadiusFromInstance(inst: Instance): number
	local radius: number

	if inst:IsA("BasePart") then
		radius = math.max(inst.Size.X, inst.Size.Y, inst.Size.Z) / 2
	elseif inst:IsA("Model") then
		local _, size = inst:GetBoundingBox()
		radius = math.max(size.X, size.Y, size.Z) / 2
	else
		error("Unsupported instance type for spotlight sizing")
	end

	return radius * Constants.WORLD_RADIUS_PADDING
end

function Spotlight:Show()
	self._gui.Enabled = true
	self._active = true
	self:_fadeOverlay(true)
	return self
end

function Spotlight:Hide()
	self._active = false
	self:_disconnectFollow()
	self:DisablePulse()
	self:_fadeOverlay(false)

	self.janitor:Add(task.delay(Constants.FADE_DURATION, function()
		if self._gui then
			self._gui.Enabled = false
		end
	end), "cancel", "HideDelay")
	return self
end

function Spotlight:SetShape(shape: string)
	shape = shape or "Circle"
	self._currentShape = shape

	if shape == "Circle" then
		AnimationUtil.CreateShapeTween(self._circleCorner, {
			CornerRadius = Constants.CIRCLE_CORNER_RADIUS
		}):Play()
	elseif shape == "Square" then
		AnimationUtil.CreateShapeTween(self._circleCorner, {
			CornerRadius = Constants.SQUARE_CORNER_RADIUS
		}):Play()
	end

	return self
end

function Spotlight:EnablePulse(amount: number): Types.SpotlightImpl
	if self._pulseEnabled then return self end
	self._pulseEnabled = true

	self._pulseThread = task.spawn(function()
		while self._active and self._pulseEnabled do
			AnimationUtil.CreatePulseTween(self._pulseDriver, {
				Value = amount
			}):Play()

			task.wait(Constants.PULSE_DURATION)
			if not self._pulseEnabled then break end

			AnimationUtil.CreatePulseTween(self._pulseDriver, {
				Value = 0
			}):Play()

			task.wait(Constants.PULSE_DURATION)
		end
	end)

	self.janitor:Add(function()
		self._pulseEnabled = false
		if self._pulseThread then
			task.cancel(self._pulseThread)
			self._pulseThread = nil
		end
	end, true, "PulseThread")
	return self
end

function Spotlight:DisablePulse()
	self._pulseEnabled = false
	self.janitor:Remove("PulseThread")
	if self._pulseThread then
		task.cancel(self._pulseThread)
		self._pulseThread = nil
	end
	self._pulseDriver.Value = 0
	return self
end

function Spotlight:FocusUI(ui: GuiObject, padding: number?, text: string?)
	self:_disconnectFollow()

	local uiScreenGui = ui:FindFirstAncestorOfClass("ScreenGui")
	local guiInsetOffset = Vector2.zero

	if uiScreenGui and not uiScreenGui.IgnoreGuiInset then
		local topbarInset = self._guiInsetService:GetGuiInset()
		guiInsetOffset = Vector2.new(0, topbarInset.Y)
	end

	local pos = ui.AbsolutePosition + guiInsetOffset
	local size = ui.AbsoluteSize
	local pad = padding or 0

	local maxDim = math.max(size.X, size.Y) + (pad * 2)
	local centerX = pos.X + (size.X / 2) - (maxDim / 2)
	local centerY = pos.Y + (size.Y / 2) - (maxDim / 2)

	AnimationUtil.CreateMoveTween(self._tweenDriver, {
		Value = Vector3.new(centerX, centerY, maxDim)
	}):Play()

	self._hint.Text = text or ""
	return self
end

function Spotlight:FocusWorld(position: Vector3, radius: number, text: string?)
	local v, onScreen = self._camera:WorldToViewportPoint(position)
	if not onScreen or v.Z <= 0 then
		self._container.Visible = false
		return self
	end

	self._container.Visible = true

	local pixelRadius = self:_worldRadiusToPixels(position, radius)
	local size = pixelRadius * 2

	self._tweenDriver.Value = Vector3.new(
		v.X - pixelRadius,
		v.Y - pixelRadius,
		size
	)

	self._hint.Text = text or ""
	return self
end

function Spotlight:FollowPart(inst: Instance, text: string?)
	self:_disconnectFollow()
	self._container.Visible = true

	self.janitor:Add(RunService.RenderStepped:Connect(function()
		if not self._active or not inst or not inst.Parent then return end
		local partInstance = inst :: BasePart
		local radius = self:_getWorldRadiusFromInstance(inst)
		self:FocusWorld(partInstance.Position, radius, text)
	end), "Disconnect", "FollowConnection")
	return self
end

function Spotlight:SetSteps(steps: {SpotlightStep})
	self._steps = steps
	self._stepIndex = 0
	return self
end

function Spotlight:Next()
	self._stepIndex += 1
	local step: SpotlightStep? = self._steps[self._stepIndex]

	if not step then
		self:Hide()
		self.sequenceCompleted:Fire()
		return self
	end

	if step.Shape then
		self:SetShape(step.Shape)
	end

	if step.UI then
		self:FocusUI(step.UI, step.Padding or 15, step.Text)
	elseif step.World then
		self:FocusWorld(step.World, step.Radius or 80, step.Text)
	elseif step.Part then
		self:FollowPart(step.Part, step.Text)
	end

	if step.Pulse then
		self:EnablePulse(step.Pulse)
	else
		self:DisablePulse()
	end

	self.stepCompleted:Fire(self._stepIndex)
	return self
end

function Spotlight:Start()
	self:Show()
	self:Next()
	return self
end

function Spotlight:Skip()
	self:Hide()
	return self
end

function Spotlight:Destroy()
	self.janitor:Destroy()
end

print(`🔎 Running SpotLightUI by @Vvshenok & Interactive Studios`)

return Spotlight :: Types.StaticSpotlight