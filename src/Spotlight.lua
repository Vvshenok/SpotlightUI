--!nonstrict
--[[
	Created by: @Vvshenok
	Repository: https://github.com/Vvshenok/SpotlightUI
	License: MIT

	SpotlightUI – Guided Focus Module (v2)

	Packages (first-party, ./Packages/):
		Spring        – critically-damped spring integrator
		ScrollLock    – ScrollingFrame lock/unlock + scroll offset
		PositionUtil  – screen-space clamping, hint placement, edge projection
		Highlight     – world-object Highlight lifecycle + pulse
		AnimationUtil – tween factory helpers

	Vendors (third-party, ./Vendors/):
		GoodSignal
		Janitor

	Methods:
		spotlight:Show()
		spotlight:Hide()
		spotlight:SetShape(shape)          "Circle" | "Square" | "Rounded" | "Rectangle"
		spotlight:FocusUI(ui, padding, text, offsetX, offsetY, offsetYScale)
		spotlight:FollowUI(ui, padding, text)
		spotlight:FocusWorld(position, radius, text)
		spotlight:FollowPart(inst, text)
		spotlight:EnablePulse(amount)
		spotlight:DisablePulse()
		spotlight:HideHint()
		spotlight:ShowHint()
		spotlight:SetSteps(steps)
		spotlight:Start()
		spotlight:Next()
		spotlight:Skip()
		spotlight:Destroy()
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Spring = require(script.Packages.Spring)
local ScrollLock = require(script.Packages.ScrollLock)
local PositionUtil = require(script.Packages.PositionUtil)
local Highlight = require(script.Packages.Highlight)
local AnimationUtil = require(script.Packages.AnimationUtil)

local Types = require(script.Types)
local Signal = require(script.Vendors.GoodSignal)
local Janitor = require(script.Vendors.Janitor)

export type Spotlight = Types.Spotlight
export type SpotlightStep = Types.SpotlightStep

local BaselineHeight = 1080

local function screenRatio(camera: Camera): number
	return camera.ViewportSize.Y / BaselineHeight
end

local Config = {
	OverlayAlpha = 0.6,
	DefaultSpotlightSize = Vector2.new(160, 160),
	HintSize = Vector2.new(300, 60),
	HintOffset = 20,
	HintPadding = 10,
	WorldRadiusPadding = 1.5,
	OverlayColor = Color3.new(0, 0, 0),
	HintBackgroundColor = Color3.fromRGB(20, 20, 20),
	HintTextColor = Color3.new(1, 1, 1),
	HintCornerRadius = 8,
	CircleCornerRadius = UDim.new(0.5, 0),
	SquareCornerRadius = UDim.new(0.06, 0),
	RoundedCornerRadius = UDim.new(0.18, 0),
	RectCornerRadius = UDim.new(0, 12),
	HintFont = Enum.Font.GothamBold,
	HintTextSize = 18,
	OverlayZIndex = 5,
	HintZIndex = 11,
	ArrowSize = 28,
	ArrowZIndex = 12,
	ArrowEdgeMargin = 32,
	StrokeThickness = 10000,
}

local UIBuilder = {}

function UIBuilder.CreateFrame(parent: Instance, properties: { [string]: any }?): Frame
	local frame = Instance.new("Frame")
	frame.BackgroundColor3 = Config.OverlayColor
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = parent

	if properties then
		for key, value in properties do
			(frame :: any)[key] = value
		end
	end

	return frame
end

function UIBuilder.CreateHintLabel(parent: Instance, ratio: number): TextLabel
	local hw = Config.HintSize.X * ratio
	local hh = Config.HintSize.Y * ratio

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.fromOffset(hw, hh)
	hint.BackgroundColor3 = Config.HintBackgroundColor
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Config.HintTextColor
	hint.Font = Config.HintFont
	hint.TextSize = math.round(Config.HintTextSize * ratio)
	hint.TextWrapped = true
	hint.BorderSizePixel = 0
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Text = ""
	hint.ZIndex = Config.HintZIndex
	hint.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, math.round(Config.HintCornerRadius * ratio))
	corner.Parent = hint

	return hint
end

function UIBuilder.CreateArrow(parent: Instance, ratio: number): ImageLabel
	local sz = math.round(Config.ArrowSize * ratio)

	local arrow = Instance.new("ImageLabel")
	arrow.Name = "OffScreenArrow"
	arrow.Size = UDim2.fromOffset(sz, sz)
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.BackgroundTransparency = 1
	arrow.Image = "rbxassetid://6034818389"
	arrow.ImageColor3 = Color3.new(1, 1, 1)
	arrow.ImageTransparency = 1
	arrow.ZIndex = Config.ArrowZIndex
	arrow.Parent = parent

	return arrow
end

local player = Players.LocalPlayer :: Player

local Spotlight = {} :: any
Spotlight.__index = Spotlight

function Spotlight.new(): Types.Spotlight
	local camera = workspace.CurrentCamera :: Camera
	local ratio = screenRatio(camera)
	local janitor = Janitor.new()

	local stepCompletedSignal = Signal.new()
	local sequenceCompletedSignal = Signal.new()

	local defaultSize = Config.DefaultSpotlightSize * ratio

	local self = setmetatable({
		gui = nil :: any,
		container = nil :: any,
		circleMask = nil :: any,
		circleStroke = nil :: any,
		circleCorner = nil :: any,
		hint = nil :: any,
		hintCorner = nil :: any,
		arrow = nil :: any,

		spotlightPos = Vector2.zero,
		spotlightSize = defaultSize,
		active = false,
		pulseEnabled = false,
		rectSize = nil :: Vector2?,
		hintEnabled = true,
		currentShape = "Circle",
		steps = {} :: { SpotlightStep },
		stepIndex = 0,

		spring = Spring.newBundle(0, 0, defaultSize.X),

		pulseDriver = nil :: any,
		pulseAmount = 0,

		targetPos = Vector2.zero,
		targetSize = defaultSize.X,

		scrollUnlock = nil :: (() -> ())?,

		highlightController = nil :: any,

		camera = camera,
		ratio = ratio,
		janitor = janitor,
		stepCompleted = stepCompletedSignal,
		sequenceCompleted = sequenceCompletedSignal,
	}, Spotlight)

	self:buildUI()
	self:setupDrivers()
	self:startUpdateLoop()

	return self :: any
end

function Spotlight:buildUI()
	local ratio = self.ratio

	local gui = Instance.new("ScreenGui")
	gui.Name = "SpotlightGui"
	gui.IgnoreGuiInset = true
	gui.ClipToDeviceSafeArea = false
	gui.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 255
	gui.Parent = player:WaitForChild("PlayerGui")
	self.gui = gui
	self.janitor:Add(gui, "Destroy")

	local container = UIBuilder.CreateFrame(gui, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	})
	self.container = container

	local circleMask = UIBuilder.CreateFrame(container, {
		Name = "CircleMask",
		BackgroundTransparency = 1,
		ZIndex = Config.OverlayZIndex,
	})
	self.circleMask = circleMask

	local circleCorner = Instance.new("UICorner")
	circleCorner.CornerRadius = Config.CircleCornerRadius
	circleCorner.Parent = circleMask
	self.circleCorner = circleCorner

	local circleStroke = Instance.new("UIStroke")
	circleStroke.Color = Config.OverlayColor
	circleStroke.Thickness = Config.StrokeThickness
	circleStroke.Transparency = 1
	circleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	circleStroke.Parent = circleMask
	self.circleStroke = circleStroke

	self.hint = UIBuilder.CreateHintLabel(container, ratio)
	self.hintCorner = self.hint:FindFirstChildOfClass("UICorner") :: UICorner
	self.arrow = UIBuilder.CreateArrow(container, ratio)
end

function Spotlight:setupDrivers()
	local pulseDriver = Instance.new("NumberValue")
	pulseDriver.Value = 0
	self.pulseDriver = pulseDriver
end

function Spotlight:startUpdateLoop()
	self.janitor:Add(RunService.Heartbeat:Connect(function(dt: number)
		if not self.active then return end

		local sx = self.spring.X:Update(dt, self.targetPos.X)
		local sy = self.spring.Y:Update(dt, self.targetPos.Y)
		local ss = self.spring.Size:Update(dt, self.targetSize + self.pulseDriver.Value)

		self.spotlightPos = Vector2.new(sx, sy)
		self.spotlightSize = self.rectSize or Vector2.new(ss, ss)

		if self.highlightController then
			self.highlightController:Pulse(dt)
		end

		self:updateSpotlightLayout()
		self:updateHintPosition()
		self:updateArrow()
	end), "Disconnect")
end

function Spotlight:updateSpotlightLayout()
	local cx = self.spotlightPos.X
	local cy = self.spotlightPos.Y
	local w = self.spotlightSize.X
	local h = self.spotlightSize.Y

	self.circleMask.Position = UDim2.fromOffset(cx - w / 2, cy - h / 2)
	self.circleMask.Size = UDim2.fromOffset(w, h)
end

function Spotlight:updateHintPosition()
	local ratio = self.ratio
	local screen = self.container.AbsoluteSize
	local hintSize = self.hint.AbsoluteSize

	local position = PositionUtil.GetHintPosition(
		self.spotlightPos,
		self.spotlightSize,
		hintSize,
		screen,
		Config.HintOffset * ratio,
		Config.HintPadding * ratio
	)

	self.hint.Position = UDim2.fromOffset(position.X, position.Y)
end

function Spotlight:updateArrow()
	local arrow = self.arrow
	local screen = self.container.AbsoluteSize
	local margin = Config.ArrowEdgeMargin * self.ratio

	local onScreen = PositionUtil.IsOnScreen(self.targetPos, screen)

	if onScreen then
		if arrow.ImageTransparency < 1 then
			arrow.ImageTransparency = 1
		end
		return
	end

	arrow.ImageTransparency = math.max(0, arrow.ImageTransparency - 0.1)

	local edgePos, angle = PositionUtil.ProjectToEdge(self.targetPos, screen, margin)
	arrow.Position = UDim2.fromOffset(edgePos.X, edgePos.Y)
	arrow.Rotation = math.deg(angle)
end

function Spotlight:fadeOverlay(show: boolean)
	local transparency = show and (1 - Config.OverlayAlpha) or 1

	AnimationUtil.FadePlay(self.circleStroke, { Transparency = transparency })

	local hasText = self.hintEnabled and self.hint.Text ~= ""
	AnimationUtil.FadePlay(self.hint, {
		BackgroundTransparency = (show and hasText) and 0.15 or 1,
		TextTransparency = (show and hasText) and 0 or 1,
	})
end

function Spotlight:disconnectFollow()
	self.janitor:Remove("FollowConnection")
	self:detachHighlight()
end

function Spotlight:unlockScrollFrames()
	if self.scrollUnlock then
		self.scrollUnlock()
		self.scrollUnlock = nil
	end
end

function Spotlight:attachHighlight(inst: Instance)
	self:detachHighlight()
	self.highlightController = Highlight.new(inst)
end

function Spotlight:detachHighlight()
	if self.highlightController then
		self.highlightController:Detach()
		self.highlightController = nil
	end
end

function Spotlight:applyFocusUI(
	ui: GuiObject,
	padding: number?,
	text: string?,
	offsetX: number?,
	offsetY: number?,
	offsetYScale: number?,
	snapInstantly: boolean?
)
	local ratio = self.ratio
	local guiInsetOffset = Vector2.zero
	local uiScreenGui = ui:FindFirstAncestorOfClass("ScreenGui")

	if uiScreenGui then
		local inset = GuiService:GetGuiInset()
		local uiIgnores = uiScreenGui.IgnoreGuiInset
		local spotIgnores = self.gui.IgnoreGuiInset

		if uiIgnores and not spotIgnores then
			guiInsetOffset = Vector2.new(0, -inset.Y)
		elseif not uiIgnores and spotIgnores then
			guiInsetOffset = Vector2.new(0, inset.Y)
		end
	end

	local screenH = self.container.AbsoluteSize.Y
	local scrollOff = ScrollLock.GetScrollOffset(ui)
	local pos = ui.AbsolutePosition + guiInsetOffset - scrollOff
	local size = ui.AbsoluteSize
	local ox = offsetX or 0
	local oy = (offsetY or 0) + (offsetYScale or 0) * screenH
	local pad = (padding or 0) * ratio
	local centerX = pos.X + size.X / 2 + ox
	local centerY = pos.Y + size.Y / 2 + oy

	if self.currentShape == "Rectangle" then
		local w = size.X + pad * 2
		local h = size.Y + pad * 2
		self.rectSize = Vector2.new(w, h)
		self.targetPos = Vector2.new(centerX, centerY)
		self.targetSize = math.max(w, h)
	else
		self.rectSize = nil
		local maxDim = math.max(size.X, size.Y) + pad * 2
		self.targetPos = Vector2.new(centerX, centerY)
		self.targetSize = maxDim
	end

	if snapInstantly then
		self.spring.X:Snap(self.targetPos.X)
		self.spring.Y:Snap(self.targetPos.Y)
		self.spring.Size:Snap(self.targetSize)
	end

	self.hint.Text = text or ""
end

function Spotlight:worldRadiusToPixels(worldPos: Vector3, worldRadius: number): number
	local cam = self.camera
	local center, onScreen = cam:WorldToScreenPoint(worldPos)

	if not onScreen or center.Z <= 0 then return 0 end

	local depth = center.Z
	local fov = math.rad(cam.FieldOfView)
	local screenH = cam.ViewportSize.Y
	local pixPerStud = (screenH / 2) / (math.tan(fov / 2) * depth)

	return worldRadius * pixPerStud
end

function Spotlight:getWorldRadiusFromInstance(inst: Instance): number
	local radius: number

	if inst:IsA("BasePart") then
		radius = math.max(inst.Size.X, inst.Size.Y, inst.Size.Z) / 2
	elseif inst:IsA("Model") then
		local _, size = inst:GetBoundingBox()
		radius = math.max(size.X, size.Y, size.Z) / 2
	else
		error("Unsupported instance type for spotlight sizing")
	end

	return radius * Config.WorldRadiusPadding
end

function Spotlight:Show()
	self.gui.Enabled = true
	self.active = true
	self:fadeOverlay(true)
	return self
end

function Spotlight:Hide()
	self.active = false
	self:disconnectFollow()
	self:DisablePulse()
	self:unlockScrollFrames()
	self:detachHighlight()
	self:fadeOverlay(false)
	self.arrow.ImageTransparency = 1

	task.delay(AnimationUtil.Defaults.Fade.Duration, function()
		if self.gui then
			self.gui.Enabled = false
		end
	end)

	return self
end

function Spotlight:SetShape(shape: string)
	shape = shape or "Circle"
	self.currentShape = shape

	local corner = self.circleCorner
	if shape == "Circle" then
		AnimationUtil.ShapePlay(corner, { CornerRadius = Config.CircleCornerRadius })
	elseif shape == "Square" then
		AnimationUtil.ShapePlay(corner, { CornerRadius = Config.SquareCornerRadius })
	elseif shape == "Rounded" then
		AnimationUtil.ShapePlay(corner, { CornerRadius = Config.RoundedCornerRadius })
	elseif shape == "Rectangle" then
		AnimationUtil.ShapePlay(corner, { CornerRadius = Config.RectCornerRadius })
	end

	return self
end

function Spotlight:EnablePulse(amount: number)
	if self.pulseEnabled then return self end
	self.pulseEnabled = true
	self.pulseAmount = amount

	local thread = task.spawn(function()
		while self.active and self.pulseEnabled do
			AnimationUtil.PulsePlay(self.pulseDriver, { Value = amount })
			task.wait(AnimationUtil.Defaults.Pulse.Duration)
			if not self.pulseEnabled then break end
			AnimationUtil.PulsePlay(self.pulseDriver, { Value = 0 })
			task.wait(AnimationUtil.Defaults.Pulse.Duration)
		end
	end)

	self.janitor:Add(function()
		self.pulseEnabled = false
		task.cancel(thread)
	end, true, "PulseThread")

	return self
end

function Spotlight:DisablePulse()
	self.pulseEnabled = false
	self.janitor:Remove("PulseThread")
	self.pulseDriver.Value = 0
	self.pulseAmount = 0
	return self
end

function Spotlight:FocusUI(
	ui: GuiObject,
	padding: number?,
	text: string?,
	offsetX: number?,
	offsetY: number?,
	offsetYScale: number?
)
	self:disconnectFollow()
	self:unlockScrollFrames()
	self.scrollUnlock = ScrollLock.Lock(ui)
	self:applyFocusUI(ui, padding, text, offsetX, offsetY, offsetYScale, true)

	self.janitor:Add(RunService.Heartbeat:Connect(function()
		if not self.active or not ui or not ui.Parent then return end
		self:applyFocusUI(ui, padding, text, offsetX, offsetY, offsetYScale, false)
	end), "Disconnect", "FollowConnection")

	return self
end

function Spotlight:FollowUI(ui: GuiObject, padding: number?, text: string?)
	return self:FocusUI(ui, padding, text)
end

function Spotlight:FocusWorld(position: Vector3, radius: number, text: string?)
	local v, onScreen = self.camera:WorldToScreenPoint(position)

	if not onScreen or v.Z <= 0 then
		self.targetPos = Vector2.new(v.X, v.Y)
		self.container.Visible = false
		return self
	end

	self.container.Visible = true

	local pixelRadius = self:worldRadiusToPixels(position, radius)
	self.targetPos = Vector2.new(v.X, v.Y)
	self.targetSize = pixelRadius * 2
	self.hint.Text = text or ""

	return self
end

function Spotlight:FollowPart(inst: Instance, text: string?)
	self:disconnectFollow()
	self.container.Visible = true
	self.rectSize = nil

	if inst:IsA("BasePart") or inst:IsA("Model") then
		self:attachHighlight(inst)
	end

	local function getWorldPos(): Vector3
		if inst:IsA("Model") then
			local cf, _ = inst:GetBoundingBox()
			return cf.Position
		else
			return (inst :: BasePart).Position
		end
	end

	local cachedRadius = self:getWorldRadiusFromInstance(inst)

	if inst and inst.Parent then
		local worldPos = getWorldPos()
		local v, onScreen = self.camera:WorldToScreenPoint(worldPos)
		if onScreen and v.Z > 0 then
			local pixelRadius = self:worldRadiusToPixels(worldPos, cachedRadius)
			self.targetPos = Vector2.new(v.X, v.Y)
			self.targetSize = pixelRadius * 2
			self.spring.X:Snap(v.X)
			self.spring.Y:Snap(v.Y)
			self.spring.Size:Snap(pixelRadius * 2)
		end
	end

	self.hint.Text = text or ""

	self.janitor:Add(RunService.Heartbeat:Connect(function()
		if not self.active or not inst or not inst.Parent then return end

		local worldPos = getWorldPos()
		local v, onScreen = self.camera:WorldToScreenPoint(worldPos)

		if not onScreen or v.Z <= 0 then
			self.container.Visible = false
			return
		end

		self.container.Visible = true

		local pixelRadius = self:worldRadiusToPixels(worldPos, cachedRadius)
		self.targetPos = Vector2.new(v.X, v.Y)
		self.targetSize = pixelRadius * 2
		self.hint.Text = text or ""
	end), "Disconnect", "FollowConnection")

	return self
end

function Spotlight:SetSteps(steps: { SpotlightStep })
	self.steps = steps
	self.stepIndex = 0
	return self
end

function Spotlight:Next()
	self:unlockScrollFrames()

	self.stepIndex += 1
	local step: SpotlightStep? = self.steps[self.stepIndex]

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

	self.stepCompleted:Fire(self.stepIndex)
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

function Spotlight:HideHint()
	self.hintEnabled = false
	AnimationUtil.FadePlay(self.hint, {
		BackgroundTransparency = 1,
		TextTransparency = 1,
	})
	return self
end

function Spotlight:ShowHint()
	self.hintEnabled = true
	if self.active and self.hint.Text ~= "" then
		AnimationUtil.FadePlay(self.hint, {
			BackgroundTransparency = 0.15,
			TextTransparency = 0,
		})
	end
	return self
end

function Spotlight:Destroy()
	self:unlockScrollFrames()
	self:detachHighlight()
	self.stepCompleted:DisconnectAll()
	self.sequenceCompleted:DisconnectAll()
	self.janitor:Destroy()
end

print(`🔎 Running SpotLightUI v2 by @Vvshenok & Interactive Studios`)

return Spotlight :: Types.StaticSpotlight