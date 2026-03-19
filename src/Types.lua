--!nonstrict

-- ─── Packages ─────────────────────────────────────────────────────────────────

type Connection<T...> = {
	Disconnect: (self: Connection<T...>) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, func: (T...) -> ()) -> Connection<T...>,
	Once: (self: Signal<T...>, func: (T...) -> ()) -> Connection<T...>,
	Wait: (self: Signal<T...>) -> T...,
	Fire: (self: Signal<T...>, T...) -> (),
	DisconnectAll: (self: Signal<T...>) -> (),
}

export type Janitor = {
	CurrentlyCleaning: boolean,
	Add: (self: Janitor, Object: any, MethodName: (string | boolean)?, Index: any?) -> any,
	Remove: (self: Janitor, Index: any) -> Janitor,
	Get: (self: Janitor, Index: any) -> any?,
	Cleanup: (self: Janitor) -> (),
	Destroy: (self: Janitor) -> (),
	LinkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> any,
}

-- ─── Spring (mirrors Packages/Spring) ────────────────────────────────────────

export type Spring = {
	position: number,
	velocity: number,
	stiffness: number,
	damping: number,
	Update: (self: Spring, dt: number, target: number) -> number,
	Snap: (self: Spring, position: number) -> (),
}

export type Spring3 = {
	X: Spring,
	Y: Spring,
	Size: Spring,
}

-- ─── Highlight (mirrors Packages/Highlight) ───────────────────────────────────

export type HighlightController = {
	Pulse: (self: HighlightController, dt: number) -> (),
	Detach: (self: HighlightController) -> (),
	IsAlive: (self: HighlightController) -> boolean,
}

-- ─── Step ─────────────────────────────────────────────────────────────────────

export type SpotlightStep = {
	UI: GuiObject?,
	World: Vector3?,
	Part: BasePart?,
	Radius: number?,
	Padding: number?,
	Text: string?,
	Shape: string?,
	Pulse: number?,
}

-- ─── Public surface (what callers see) ───────────────────────────────────────

export type Spotlight = {
	janitor: Janitor,
	stepCompleted: Signal<number>,
	sequenceCompleted: Signal<>,

	Show: (self: Spotlight) -> Spotlight,
	Hide: (self: Spotlight) -> Spotlight,
	SetShape: (self: Spotlight, shape: string) -> Spotlight,
	EnablePulse: (self: Spotlight, amount: number) -> Spotlight,
	DisablePulse: (self: Spotlight) -> Spotlight,
	HideHint: (self: Spotlight) -> Spotlight,
	ShowHint: (self: Spotlight) -> Spotlight,

	FocusUI: (
		self: Spotlight,
		ui: GuiObject,
		padding: number?,
		text: string?,
		offsetX: number?,
		offsetY: number?,
		offsetYScale: number?
	) -> Spotlight,
	FollowUI: (
		self: Spotlight,
		ui: GuiObject,
		padding: number?,
		text: string?
	) -> Spotlight,
	FocusWorld: (self: Spotlight, position: Vector3, radius: number, text: string?) -> Spotlight,
	FollowPart: (self: Spotlight, inst: Instance, text: string?) -> Spotlight,

	SetSteps: (self: Spotlight, steps: { SpotlightStep }) -> Spotlight,
	Start: (self: Spotlight) -> Spotlight,
	Next: (self: Spotlight) -> Spotlight,
	Skip: (self: Spotlight) -> Spotlight,
	Destroy: (self: Spotlight) -> (),
}

-- ─── Implementation surface (internal, used inside init.lua) ─────────────────

export type SpotlightImpl = {
	-- UI refs
	_gui: ScreenGui,
	_container: Frame,
	_circleMask: Frame,
	_circleStroke: UIStroke,
	_circleCorner: UICorner,
	_hint: TextLabel,
	_hintCorner: UICorner,
	_arrow: ImageLabel,

	-- State
	_spotlightPos: Vector2,
	_spotlightSize: Vector2,
	_active: boolean,
	_pulseEnabled: boolean,
	_pulseAmount: number,
	_rectSize: Vector2?,
	_hintEnabled: boolean,
	_currentShape: string,
	_steps: { SpotlightStep },
	_stepIndex: number,

	-- Spring driver (replaces old Vector3Value _tweenDriver)
	_spring: Spring3,
	_targetPos: Vector2,
	_targetSize: number,

	-- Pulse driver (NumberValue, size offset only)
	_pulseDriver: NumberValue,

	-- ScrollFrame cleanup closure (from ScrollLock package)
	_scrollUnlock: (() -> ())?,

	-- World Highlight controller (from Highlight package)
	_highlightController: HighlightController?,

	-- Misc
	_camera: Camera,
	_ratio: number,
	janitor: Janitor,
	stepCompleted: Signal<number>,
	sequenceCompleted: Signal<>,

	-- Public methods (same as Spotlight)
	Show: (self: SpotlightImpl) -> SpotlightImpl,
	Hide: (self: SpotlightImpl) -> SpotlightImpl,
	SetShape: (self: SpotlightImpl, shape: string) -> SpotlightImpl,
	EnablePulse: (self: SpotlightImpl, amount: number) -> SpotlightImpl,
	DisablePulse: (self: SpotlightImpl) -> SpotlightImpl,
	HideHint: (self: SpotlightImpl) -> SpotlightImpl,
	ShowHint: (self: SpotlightImpl) -> SpotlightImpl,
	FocusUI: (
		self: SpotlightImpl,
		ui: GuiObject,
		padding: number?,
		text: string?,
		offsetX: number?,
		offsetY: number?,
		offsetYScale: number?
	) -> SpotlightImpl,
	FollowUI: (self: SpotlightImpl, ui: GuiObject, padding: number?, text: string?) -> SpotlightImpl,
	FocusWorld: (self: SpotlightImpl, position: Vector3, radius: number, text: string?) -> SpotlightImpl,
	FollowPart: (self: SpotlightImpl, inst: Instance, text: string?) -> SpotlightImpl,
	SetSteps: (self: SpotlightImpl, steps: { SpotlightStep }) -> SpotlightImpl,
	Start: (self: SpotlightImpl) -> SpotlightImpl,
	Next: (self: SpotlightImpl) -> SpotlightImpl,
	Skip: (self: SpotlightImpl) -> SpotlightImpl,
	Destroy: (self: SpotlightImpl) -> (),

	-- Private methods
	_buildUI: (self: SpotlightImpl) -> (),
	_setupDrivers: (self: SpotlightImpl) -> (),
	_startUpdateLoop: (self: SpotlightImpl) -> (),
	_updateSpotlightLayout: (self: SpotlightImpl) -> (),
	_updateHintPosition: (self: SpotlightImpl) -> (),
	_updateArrow: (self: SpotlightImpl) -> (),
	_fadeOverlay: (self: SpotlightImpl, show: boolean) -> (),
	_disconnectFollow: (self: SpotlightImpl) -> (),
	_unlockScrollFrames: (self: SpotlightImpl) -> (),
	_attachHighlight: (self: SpotlightImpl, inst: Instance) -> (),
	_detachHighlight: (self: SpotlightImpl) -> (),
	_applyFocusUI: (
		self: SpotlightImpl,
		ui: GuiObject,
		padding: number?,
		text: string?,
		offsetX: number?,
		offsetY: number?,
		offsetYScale: number?,
		snapInstantly: boolean?
	) -> (),
	_worldRadiusToPixels: (self: SpotlightImpl, worldPos: Vector3, worldRadius: number) -> number,
	_getWorldRadiusFromInstance: (self: SpotlightImpl, inst: Instance) -> number,
}

-- ─── Static (the module itself) ──────────────────────────────────────────────

export type StaticSpotlight = {
	new: () -> Spotlight,
}

return {}