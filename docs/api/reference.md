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

!!! Warning
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

Hides the spotlight with a fade-out animation and deactivates all tracking.

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:Hide()
```

!!! Note
    The spotlight GUI is disabled after the fade animation completes (0.25 seconds). Pulse animations are automatically disabled.

---

#### :SetShape(shape)

Changes the spotlight shape with a smooth transition.

**Parameters:**

- `shape` (string) - The shape type: `"Circle"` or `"Square"`

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:SetShape("Circle")  -- Circular spotlight
spotlight:SetShape("Square")  -- Rounded square spotlight
```

**Default:** `"Circle"`

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

!!! Info
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

#### :FocusUI(ui, padding?, text?)

Focuses the spotlight on a GUI element.

**Parameters:**

- `ui` (GuiObject) - The GUI element to highlight (Frame, TextButton, ImageLabel, etc.)
- `padding` (number?) - Optional padding around the element in pixels (default: 0)
- `text` (string?) - Optional hint text to display below the spotlight

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:FocusUI(gui.PlayButton, 20, "Click to start!")
```

!!! Note
    The spotlight automatically sizes to create a circle/square that encompasses the UI element. The padding expands this area. The method accounts for GuiInset automatically.

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

!!! Warning
    If the position is behind the camera or off-screen, the spotlight container becomes invisible. It reappears when the position returns to view.

---

#### :FollowPart(instance, text?)

Makes the spotlight continuously track a moving BasePart or Model.

**Parameters:**

- `instance` (BasePart | Model) - The part or model to track
- `text` (string?) - Optional hint text to display below the spotlight

**Returns:** `self` (chainable)

**Example:**
```lua
spotlight:FollowPart(workspace.NPC, "Follow this character")
spotlight:FollowPart(character.HumanoidRootPart, "This is you!")
```

!!! Info
    The spotlight uses `RenderStepped` to update every frame. The radius is automatically calculated based on the part's size (uses the largest dimension). Models use their bounding box.

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
    { Part = workspace.Door, Text = "Go to the door", Shape = "Square" },
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

!!! Note
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

Completely removes the spotlight, cleans up all connections, tweens, and UI elements.

**Returns:** none

**Example:**
```lua
spotlight:Destroy()
```

!!! Danger
    After calling `:Destroy()`, the spotlight object cannot be reused. Create a new instance if needed.

---

### Properties

#### .stepCompleted

**Type:** `Signal<number>`

Fires when a step is completed, passing the step index (1-based).

**Example:**
```lua
spotlight.stepCompleted:Connect(function(stepIndex)
    print("Completed step:", stepIndex)
    
    -- Automatically advance after 2 seconds
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
| `_active` | boolean | Whether the spotlight is currently visible |
| `_pulseEnabled` | boolean | Whether pulse animation is running |
| `_currentShape` | string | Current shape: "Circle" or "Square" |
| `_steps` | table | Array of step configurations |
| `_stepIndex` | number | Current step index (0-based internally) |
| `_spotlightPos` | Vector2 | Current position on screen |
| `_spotlightSize` | Vector2 | Current size of spotlight |

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
| `Shape` | string | No | "Circle" or "Square" |
| `Padding` | number | No | Padding for `UI` spotlights (default: 0) |
| `Pulse` | number | No | Pulse amount in pixels (disabled if omitted) |

\* One of `UI`, `Part`, or `World` is required per step

### Example Step Configurations

**UI Step:**
```lua
{
    UI = playerGui.ScreenGui.ShopButton,
    Text = "Open the shop here",
    Shape = "Square",
    Padding = 15,
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
    FocusUI: (self: Spotlight, ui: GuiObject, padding: number?, text: string?) -> Spotlight,
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

## Constants

Internal constants used by SpotlightUI (not configurable):

| Constant | Value | Description |
|----------|-------|-------------|
| `OVERLAY_ALPHA` | 0.6 | Opacity of the dark overlay |
| `DEFAULT_SPOTLIGHT_SIZE` | Vector2(160, 160) | Default spotlight dimensions |
| `TWEEN_DURATION` | 0.5s | Duration of movement animations |
| `FADE_DURATION` | 0.25s | Duration of show/hide fades |
| `PULSE_DURATION` | 1.2s | Duration of one pulse half-cycle |
| `WORLD_RADIUS_PADDING` | 1.5 | Multiplier for world object radius |

---

## Error Handling

SpotlightUI includes basic error handling for common issues:

**Unsupported Instance Type:**
```lua
spotlight:FollowPart(workspace.Terrain)  -- Error: Unsupported instance type
```

**Solution:** Only use BaseParts or Models with `:FollowPart()`

**Off-Screen World Positions:**

When using `:FocusWorld()` on a position behind the camera, the spotlight automatically hides and reappears when the position comes back into view.

---

## Performance Notes

- **RenderStepped Usage:** `:FollowPart()` uses `RenderStepped` for smooth tracking. Limit the number of simultaneously tracking spotlights.
- **Tween Cleanup:** All tweens are automatically cleaned up via Janitor when calling `:Destroy()` or `:Hide()`.
- **World-to-Screen Conversion:** Calculated every frame when using `:FollowPart()`. This is generally performant but avoid tracking dozens of objects simultaneously.