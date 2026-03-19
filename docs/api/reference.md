# API Reference

Complete reference for all SpotlightUI methods, properties, and types.

---

## SpotlightUI

The main module for creating spotlight instances.

### SpotlightUI.new()

Creates and returns a new Spotlight instance.

**Returns:** `Spotlight`

**Example:**
```lua
local spotlight = SpotlightUI.new()
```

!!! warning
    Each Spotlight instance manages its own UI and state. Create separate instances for different tutorial flows, but reuse the same instance across steps in a single flow.

---

## Spotlight Instance

A Spotlight object created by `SpotlightUI.new()`.

### Methods

#### :Show()

Displays the spotlight overlay and makes it active.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:Show()
```

---

#### :Hide()

Hides the spotlight with a fade-out animation and deactivates all tracking. Stops pulse, unlocks any ScrollingFrames, detaches the world Highlight, and hides the off-screen arrow.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:Hide()
```

!!! note
    The spotlight GUI is disabled after the fade animation completes (0.25 seconds). Pulse animations are automatically disabled.

---

#### :SetShape(shape)

Changes the spotlight shape with a smooth transition.

**Parameters:**

- `shape` (string) - The shape type: `"Circle"`, `"Square"`, `"Rounded"`, or `"Rectangle"`

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:SetShape("Circle")     -- Circular spotlight
spotlight:SetShape("Square")     -- Tight square with subtle rounding
spotlight:SetShape("Rounded")    -- Noticeably rounded square
spotlight:SetShape("Rectangle")  -- Wraps element width × height tightly
```

**Default:** `"Circle"`

!!! note
    `Rectangle` uses the element's exact width and height plus padding, making it ideal for wide UI elements like frames and banners. The other three shapes use a uniform size based on the largest dimension.

---

#### :EnablePulse(amount)

Enables a pulsing animation that expands and contracts the spotlight.

**Parameters:**

- `amount` (number) - How many pixels to expand during the pulse

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:EnablePulse(10)  -- Subtle pulse
spotlight:EnablePulse(25)  -- More dramatic pulse
```

!!! info
    The pulse completes one full cycle (expand and contract) every 2.4 seconds. Pulses continue until disabled or the spotlight is hidden.

---

#### :DisablePulse()

Stops the pulsing animation and resets to the base size.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:DisablePulse()
```

---

#### :FocusUI(ui, padding?, text?, offsetX?, offsetY?, offsetYScale?)

Focuses the spotlight on a GUI element and continuously tracks it every frame. The spotlight automatically adjusts if the element moves, resizes, or re-parents — no additional calls needed.

Ancestor ScrollingFrames are locked for the duration of this call so the user cannot scroll away from the highlighted element.

**Parameters:**

- `ui` (GuiObject) - The GUI element to highlight
- `padding` (number?) - Optional padding around the element in pixels (default: 0)
- `text` (string?) - Optional hint text to display below the spotlight
- `offsetX` (number?) - Optional horizontal offset in pixels
- `offsetY` (number?) - Optional vertical offset in pixels
- `offsetYScale` (number?) - Optional vertical offset as a fraction of screen height

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:FocusUI(gui.PlayButton, 20, "Click to start!")
spotlight:FocusUI(gui.Icon, 10, "Here!", 0, -30)
```

---

#### :FollowUI(ui, padding?, text?)

Alias for `:FocusUI`. Both methods continuously track the element every frame. Kept for readability and back-compatibility.

**Returns:** `self` (chainable)

```lua
spotlight:FollowUI(gui.MovingFrame, 15, "This moves!")
```

---

#### :HideHint()

Fades out the hint text label without hiding the spotlight itself.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:HideHint()
```

---

#### :ShowHint()

Fades the hint text label back in, if there is text set.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:ShowHint()
```

---

#### :FocusWorld(position, radius, text?)

Focuses the spotlight on a position in the 3D world.

**Parameters:**

- `position` (Vector3) - The world position to highlight
- `radius` (number) - The radius around the position in studs
- `text` (string?) - Optional hint text to display below the spotlight

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:FocusWorld(Vector3.new(100, 5, 50), 8, "Go here")
spotlight:FocusWorld(workspace.Door.Position, 5, "Open this door")
```

!!! warning
    If the position is behind the camera or off-screen, the spotlight container becomes invisible. It reappears when the position returns to view. An off-screen arrow will point toward the target.

---

#### :FollowPart(instance, text?)

Makes the spotlight continuously track a BasePart or Model. The spotlight re-projects the part's world position to screen space every frame so it stays locked regardless of camera movement.

A pulsing `Highlight` instance is automatically attached to the part for additional world-space visual feedback, and removed when the step ends.

**Parameters:**

- `instance` (BasePart | Model) - The part or model to track
- `text` (string?) - Optional hint text to display below the spotlight

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:FollowPart(workspace.NPC, "Follow this character")
spotlight:FollowPart(character.HumanoidRootPart, "This is you!")
```

!!! info
    The spotlight uses `Heartbeat` to update every frame. The radius is automatically calculated based on the part's size (uses the largest dimension). Models use their bounding box.

**Radius Calculation:**
```lua
-- For BaseParts
radius = max(Size.X, Size.Y, Size.Z) / 2 * 1.5

-- For Models
radius = max(BoundingSize.X, BoundingSize.Y, BoundingSize.Z) / 2 * 1.5
```

---

#### :SetSteps(steps)

Configures a sequence of tutorial steps.

**Parameters:**

- `steps` (table) - Array of step configurations (see [Step Configuration](#step-configuration))

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:SetSteps({
    { UI = gui.Button1, Text = "Click here", Shape = "Circle", Pulse = 10 },
    { Part = workspace.Door, Text = "Go to the door", Shape = "Circle" },
    { World = Vector3.new(0, 5, 0), Radius = 10, Text = "Final destination" }
})
```

---

#### :Start()

Shows the spotlight and begins the first step in the sequence.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:SetSteps({...}):Start()
```

!!! note
    Equivalent to calling `:Show()` then `:Next()`.

---

#### :Next()

Advances to the next step in the sequence. If no more steps remain, hides the spotlight and fires the `sequenceCompleted` signal.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:Next()
```

---

#### :Skip()

Immediately hides the spotlight, bypassing any remaining steps.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:Skip()
```

---

#### :Destroy()

Completely removes the spotlight, cleans up all connections, and destroys the UI.

**Returns:** none

**Example:**
```lua
spotlight:Destroy()
```

!!! danger
    After calling `:Destroy()`, the spotlight object cannot be reused. Create a new instance if needed.

---

### Properties

#### .stepCompleted

**Type:** `Signal<number>`

Fires when a step begins, passing the step index (1-based).

**Example:**
```lua
spotlight.stepCompleted:Connect(function(stepIndex)
    print("Started step:", stepIndex)

    task.wait(2)
    spotlight:Next()
end)
```

---

#### .sequenceCompleted

**Type:** `Signal<>`

Fires when all steps in the sequence have been completed.

**Example:**
```lua
spotlight.sequenceCompleted:Connect(function()
    print("Tutorial finished!")
    player:SetAttribute("TutorialComplete", true)
end)
```

---

### Internal Properties

These properties are part of the internal state and generally shouldn't be accessed directly, but are documented for advanced users.

| Property | Type | Description |
|----------|------|-------------|
| `active` | boolean | Whether the spotlight is currently visible |
| `pulseEnabled` | boolean | Whether pulse animation is running |
| `currentShape` | string | Current shape: `"Circle"`, `"Square"`, `"Rounded"`, or `"Rectangle"` |
| `steps` | table | Array of step configurations |
| `stepIndex` | number | Current step index (0-based internally) |
| `spotlightPos` | Vector2 | Current position on screen |
| `spotlightSize` | Vector2 | Current size of spotlight |

---

## Step Configuration

Each step in a tutorial sequence is a table with the following fields:

### Step Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `UI` | GuiObject | * | GUI element to spotlight |
| `Part` | BasePart/Model | * | World object to spotlight |
| `World` | Vector3 | * | World position to spotlight |
| `Radius` | number | No | Radius for `World` spotlights (default: 80) |
| `Text` | string | No | Hint text to display |
| `Shape` | string | No | `"Circle"`, `"Square"`, `"Rounded"`, or `"Rectangle"` |
| `Padding` | number | No | Padding for `UI` spotlights (default: 15) |
| `Pulse` | number | No | Pulse amount in pixels (disabled if omitted) |

\* One of `UI`, `Part`, or `World` is required per step

### Example Step Configurations

**UI Step:**
```lua
{
    UI = playerGui.ScreenGui.ShopButton,
    Text = "Open the shop here",
    Shape = "Rectangle",
    Padding = 12,
    Pulse = 8
}
```

**Part Step:**
```lua
{
    Part = workspace.QuestGiver,
    Text = "Talk to this NPC",
    Shape = "Circle"
}
```

**World Step:**
```lua
{
    World = Vector3.new(100, 5, 100),
    Radius = 10,
    Text = "Go to this location",
    Shape = "Circle",
    Pulse = 12
}
```

---

## Type Definitions

### Spotlight

```lua
type Spotlight = {
    Show: (self: Spotlight) -> Spotlight,
    Hide: (self: Spotlight) -> Spotlight,
    SetShape: (self: Spotlight, shape: string) -> Spotlight,
    EnablePulse: (self: Spotlight, amount: number) -> Spotlight,
    DisablePulse: (self: Spotlight) -> Spotlight,
    HideHint: (self: Spotlight) -> Spotlight,
    ShowHint: (self: Spotlight) -> Spotlight,
    FocusUI: (self: Spotlight, ui: GuiObject, padding: number?, text: string?, offsetX: number?, offsetY: number?, offsetYScale: number?) -> Spotlight,
    FollowUI: (self: Spotlight, ui: GuiObject, padding: number?, text: string?) -> Spotlight,
    FocusWorld: (self: Spotlight, position: Vector3, radius: number, text: string?) -> Spotlight,
    FollowPart: (self: Spotlight, instance: Instance, text: string?) -> Spotlight,
    SetSteps: (self: Spotlight, steps: {SpotlightStep}) -> Spotlight,
    Next: (self: Spotlight) -> Spotlight,
    Start: (self: Spotlight) -> Spotlight,
    Skip: (self: Spotlight) -> Spotlight,
    Destroy: (self: Spotlight) -> (),

    stepCompleted: Signal<number>,
    sequenceCompleted: Signal<>,
}
```

### SpotlightStep

```lua
type SpotlightStep = {
    UI: GuiObject?,
    Part: Instance?,
    World: Vector3?,
    Radius: number?,
    Text: string?,
    Shape: string?,
    Padding: number?,
    Pulse: number?,
}
```

---

## Config Values

Internal values used by SpotlightUI. All pixel-based values are authored at a 1080p baseline and scale automatically with viewport size.

| Key | Value | Description |
|-----|-------|-------------|
| `OverlayAlpha` | 0.6 | Opacity of the dark overlay |
| `DefaultSpotlightSize` | Vector2(160, 160) | Default spotlight size at 1080p |
| `HintOffset` | 20px | Gap between spotlight bottom and hint label |
| `FadeDuration` | 0.25s | Duration of show/hide fades |
| `PulseDuration` | 1.2s | Duration of one pulse half-cycle |
| `WorldRadiusPadding` | 1.5 | Multiplier applied to world object radius |
| `ArrowEdgeMargin` | 32px | Distance the off-screen arrow stays from viewport edges |
| `StrokeThickness` | 10000 | UIStroke thickness used as the overlay mask |

---

## Error Handling

SpotlightUI includes basic error handling for common issues:

**Unsupported Instance Type:**
```lua
spotlight:FollowPart(workspace.Terrain)  -- Error: Unsupported instance type
```

**Solution:** Only use BaseParts or Models with `:FollowPart()`

**Off-Screen World Positions:**

When using `:FocusWorld()` on a position behind the camera, the spotlight automatically hides and an off-screen arrow appears pointing toward the target. The spotlight reappears when the position comes back into view.

---

## Performance Notes

- **Live UI tracking:** `:FocusUI()` and `:FollowUI()` run a `Heartbeat` connection that re-evaluates the target every frame. When the element is stationary the spring receives the same value and stays settled — effectively zero cost.
- **Part tracking:** `:FollowPart()` calls `WorldToScreenPoint` every `Heartbeat` frame so the spotlight stays locked to the correct screen pixel regardless of camera movement. Avoid tracking more than a few parts simultaneously.
- **Tween cleanup:** All connections are managed by Janitor and disconnected automatically on `:Hide()`, `:Next()`, and `:Destroy()`.