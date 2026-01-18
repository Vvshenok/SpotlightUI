# Getting Started

This tutorial shows you how to set up SpotlightUI and teaches you the basic implementation patterns.

## Installation

Get the module from the [GitHub repository](https://github.com/Vvshenok/SpotlightUI/releases) and download the latest release.

!!! Note
    For the purposes of this tutorial, we assume the module is placed in `ReplicatedStorage.SpotlightUI`.

After you insert the module into your place, add a new LocalScript to `StarterPlayer.StarterPlayerScripts` or `StarterGui` and paste the following code:

```lua
-- Import the module
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SpotlightUI = require(ReplicatedStorage.SpotlightUI)
```

The next part of the code defines the variables we'll use:

```lua
-- Get references to UI elements
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local MyGui = PlayerGui:WaitForChild("ScreenGui")
local Button = MyGui:WaitForChild("StartButton")

-- Or reference a part in the workspace
local ImportantDoor = workspace:WaitForChild("TutorialDoor")

-- Create a new Spotlight instance
local Spotlight = SpotlightUI.new()
```

!!! Note
    `SpotlightUI.new()` is a constructor that creates a new Spotlight instance. You can reuse the same Spotlight object throughout your tutorial by calling different methods on it.

---

## Method 1: Using Single Spotlights

The simplest way to use SpotlightUI is to highlight a single element:

### Highlighting UI Elements

To spotlight a GUI element, use the `FocusUI` method:

```lua
Spotlight
    :FocusUI(Button, 20, "Click this button to start!")
    :Show()
```

This creates a spotlight around the button with 20 pixels of padding and displays the hint text "Click this button to start!"

### Customizing the Spotlight

You can chain additional methods to customize the appearance:

```lua
Spotlight
    :SetShape("Circle")        -- Options: "Circle", "Square", "Triangle"
    :EnablePulse(10)           -- Adds a pulsing animation (10 pixel expansion)
    :FocusUI(Button, 20, "Click this button to start!")
    :Show()
```

### Highlighting World Objects

To spotlight a part or model in the 3D world:

```lua
Spotlight
    :FocusWorld(ImportantDoor.Position, 5, "Go to this door")
    :SetShape("Triangle")
    :Show()
```

The second parameter (5) is the radius in studs around the position.

### Following Moving Objects

If you need the spotlight to track a moving object, use `FollowPart`:

```lua
local MovingNPC = workspace.NPC

Spotlight
    :FollowPart(MovingNPC, "Follow this character")
    :EnablePulse(15)
    :Show()
```

The spotlight will automatically update its position to track the object in real-time.

---

## Method 2: Using Step-Based Tutorials

For multi-step tutorials, SpotlightUI provides a powerful step system:

```lua
local Spotlight = SpotlightUI.new()

Spotlight:SetSteps({
    {
        UI = MyGui.Button1,
        Text = "Welcome! Click this button first",
        Shape = "Circle",
        Padding = 15,
        Pulse = 10
    },
    {
        Part = workspace.Checkpoint1,
        Text = "Now go to this checkpoint",
        Shape = "Triangle"
    },
    {
        UI = MyGui.InventoryButton,
        Text = "Finally, open your inventory",
        Shape = "Square",
        Padding = 20
    }
})

Spotlight:Start()
```

Each step is a table with the following optional properties:

| Property | Type | Description |
|----------|------|-------------|
| `UI` | GuiObject | The GUI element to spotlight |
| `Part` | BasePart/Model | The 3D object to spotlight |
| `World` | Vector3 | A specific position in the world |
| `Radius` | number | Radius for world spotlights (default: 80) |
| `Text` | string | Hint text to display |
| `Shape` | string | "Circle", "Square", or "Triangle" |
| `Padding` | number | Extra space around UI elements |
| `Pulse` | number | Pulse animation amount (pixels) |

!!! Warning
    Each step should have either `UI`, `Part`, or `World` defined, but not multiple.

### Advancing Through Steps

The tutorial automatically starts with the first step when you call `:Start()`. To manually advance:

```lua
-- Advance to next step
Spotlight:Next()

-- Skip the entire tutorial
Spotlight:Skip()
```

### Listening to Step Events

You can react to tutorial progress using signals:

```lua
-- Fires when each step is completed
Spotlight.stepCompleted:Connect(function(stepIndex)
    print("Completed step:", stepIndex)
end)

-- Fires when the entire sequence finishes
Spotlight.sequenceCompleted:Connect(function()
    print("Tutorial complete!")
    -- Award player or save progress
end)
```

### Interactive Tutorials

Here's a complete example of an interactive tutorial that advances when the player clicks buttons:

```lua
local Spotlight = SpotlightUI.new()

Spotlight:SetSteps({
    { UI = gui.PlayButton, Text = "Click to play", Shape = "Circle", Pulse = 10 },
    { UI = gui.ShopButton, Text = "Check out the shop", Shape = "Square" },
    { UI = gui.SettingsButton, Text = "Customize your settings", Shape = "Circle" }
})

-- Advance when player clicks the right button
gui.PlayButton.Activated:Connect(function()
    if Spotlight._stepIndex == 1 then
        Spotlight:Next()
    end
end)

gui.ShopButton.Activated:Connect(function()
    if Spotlight._stepIndex == 2 then
        Spotlight:Next()
    end
end)

gui.SettingsButton.Activated:Connect(function()
    if Spotlight._stepIndex == 3 then
        Spotlight:Next()
    end
end)

Spotlight:Start()
```

---

## Method 3: Hybrid Approach

You can combine both approaches for maximum flexibility:

```lua
local Spotlight = SpotlightUI.new()

-- Start with a single spotlight
Spotlight
    :FocusUI(gui.WelcomeScreen.CloseButton, 20, "Close this to begin")
    :Show()

-- When player closes welcome screen, start the tutorial
gui.WelcomeScreen.CloseButton.Activated:Connect(function()
    gui.WelcomeScreen.Visible = false
    
    -- Now start step-based tutorial
    Spotlight:SetSteps({
        { Part = workspace.SpawnLocation, Text = "This is your spawn", Shape = "Circle" },
        { UI = gui.HealthBar, Text = "This is your health", Shape = "Square", Padding = 10 },
        { Part = workspace.QuestGiver, Text = "Talk to NPCs for quests", Shape = "Triangle" }
    })
    Spotlight:Start()
end)
```

---

## Cleaning Up

When you're done with a spotlight, always clean it up:

```lua
Spotlight:Hide()  -- Hides the spotlight
Spotlight:Destroy()  -- Completely removes it and cleans up connections
```

The `Destroy()` method uses Janitor internally to ensure all connections and tweens are properly cleaned up.

---

## Best Practices

1. **One Spotlight per Tutorial** - Create a new Spotlight instance for each distinct tutorial flow
2. **Clear Instructions** - Keep hint text concise and actionable
3. **Appropriate Shapes** - Use circles for points of interest, squares for UI elements, triangles for directions
4. **Pulse Sparingly** - Only use pulse on the most important steps to avoid overwhelming players
5. **Test on Different Screen Sizes** - Ensure spotlights work well on mobile and desktop

---

## Complete Example

Here's a full working example combining everything:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local SpotlightUI = require(ReplicatedStorage.SpotlightUI)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local gui = player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")

-- Create the spotlight
local Tutorial = SpotlightUI.new()

-- Set up the tutorial steps
Tutorial:SetSteps({
    {
        Part = character:WaitForChild("HumanoidRootPart"),
        Text = "This is you! Use WASD to move",
        Shape = "Circle",
        Pulse = 15
    },
    {
        UI = gui.Minimap,
        Text = "Use the minimap to navigate",
        Shape = "Square",
        Padding = 10
    },
    {
        Part = workspace.QuestBoard,
        Text = "Check the quest board for missions",
        Shape = "Triangle"
    },
    {
        UI = gui.InventoryButton,
        Text = "Open your inventory here",
        Shape = "Circle",
        Padding = 20,
        Pulse = 10
    }
})

-- Listen for completion
Tutorial.stepCompleted:Connect(function(step)
    print("Player completed step:", step)
    task.wait(3)  -- Wait 3 seconds before next step
    Tutorial:Next()
end)

Tutorial.sequenceCompleted:Connect(function()
    print("Tutorial finished!")
    -- Save that player completed tutorial
    player:SetAttribute("CompletedTutorial", true)
end)

-- Start the tutorial
Tutorial:Start()
```

---

## Next Steps

Now that you understand the basics, explore:

- [API Reference](../api/reference.md) - Complete method and property documentation
- [Examples](../examples/circle.md) - Code snippets for common use cases
- [Advanced Patterns](advanced-usage.md) - Complex tutorial flows and edge cases