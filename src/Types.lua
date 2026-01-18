--!nonstrict

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

export type Janitor = {
	CurrentlyCleaning: boolean,
	Add: (self: Janitor, Object: any, MethodName: (string | boolean)?, Index: any?) -> any,
	Remove: (self: Janitor, Index: any) -> Janitor,
	Get: (self: Janitor, Index: any) -> any?,
	Cleanup: (self: Janitor) -> (),
	Destroy: (self: Janitor) -> (),
	LinkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> any,
}

export type Spotlight = {
	janitor: Janitor,
	stepCompleted: Signal<number>,
	sequenceCompleted: Signal<>,

	Show: (self: Spotlight) -> Spotlight,
	Hide: (self: Spotlight) -> Spotlight,
	SetShape: (self: Spotlight, shape: string) -> Spotlight,
	EnablePulse: (self: Spotlight, amount: number) -> Spotlight,
	DisablePulse: (self: Spotlight) -> Spotlight,
	FocusUI: (self: Spotlight, ui: GuiObject, padding: number?, text: string?) -> Spotlight,
	FocusWorld: (self: Spotlight, position: Vector3, radius: number, text: string?) -> Spotlight,
	FollowPart: (self: Spotlight, inst: Instance, text: string?) -> Spotlight,
	SetSteps: (self: Spotlight, steps: {SpotlightStep}) -> Spotlight,
	Next: (self: Spotlight) -> Spotlight,
	Start: (self: Spotlight) -> Spotlight,
	Skip: (self: Spotlight) -> Spotlight,
	Destroy: (self: Spotlight) -> (),
}

export type SpotlightImpl = {
	_gui: ScreenGui,
	_container: Frame,
	_circleMask: Frame,
	_circleStroke: UIStroke,
	_circleCorner: UICorner,
	_triangle: Frame,
	_triangleStroke: UIStroke,
	_hint: TextLabel,
	_hintCorner: UICorner,
	_spotlightPos: Vector2,
	_spotlightSize: Vector2,
	_active: boolean,
	_pulseEnabled: boolean,
	_currentShape: string,
	_steps: {SpotlightStep},
	_stepIndex: number,
	_tweenDriver: Vector3Value,
	_pulseDriver: NumberValue,
	_camera: Camera,
	janitor: Janitor,
	stepCompleted: Signal<number>,
	sequenceCompleted: Signal<>,

	Show: (self: Spotlight) -> Spotlight,
	Hide: (self: Spotlight) -> Spotlight,
	SetShape: (self: Spotlight, shape: string) -> Spotlight,
	EnablePulse: (self: Spotlight, amount: number) -> Spotlight,
	DisablePulse: (self: Spotlight) -> Spotlight,
	FocusUI: (self: Spotlight, ui: GuiObject, padding: number?, text: string?) -> Spotlight,
	FocusWorld: (self: Spotlight, position: Vector3, radius: number, text: string?) -> Spotlight,
	FollowPart: (self: Spotlight, inst: Instance, text: string?) -> Spotlight,
	SetSteps: (self: Spotlight, steps: {SpotlightStep}) -> Spotlight,
	Next: (self: Spotlight) -> Spotlight,
	Start: (self: Spotlight) -> Spotlight,
	Skip: (self: Spotlight) -> Spotlight,
	Destroy: (self: Spotlight) -> (),

	_buildUI: (self: Spotlight) -> (),
	_setupDrivers: (self: Spotlight) -> (),
	_startUpdateLoop: (self: Spotlight) -> (),
	_updateSpotlightLayout: (self: Spotlight) -> (),
	_updateHintPosition: (self: Spotlight) -> (),
	_fadeOverlay: (self: Spotlight, show: boolean) -> (),
	_disconnectFollow: (self: Spotlight) -> (),
	_worldRadiusToPixels: (self: Spotlight, worldPos: Vector3, worldRadius: number) -> number,
	_getWorldRadiusFromInstance: (self: Spotlight, inst: Instance) -> number,
}

export type StaticSpotlight = {
	new: () -> Spotlight,
}

return {}