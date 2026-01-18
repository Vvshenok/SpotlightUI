# Circle Spotlight Examples

The circle spotlight is ideal for drawing attention to points of interest, player characters, or central UI elements.

---

## Basic Circle Spotlight

Highlight a single UI button with a circular spotlight.

```lua
local SpotlightUI = require(ReplicatedStorage.SpotlightUI)
local gui = player.PlayerGui.ScreenGui

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FocusUI(gui.PlayButton, 20, "Click to start your adventure!")
    :Show()
```

---

## Circle with Pulse Animation

Add a pulsing effect to make the spotlight more eye-catching.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FocusUI(gui.ShopButton, 15, "Special sale happening now!")
    :EnablePulse(12)
    :Show()
```

---

## Following a Character

Create a spotlight that follows the player's character.

```lua
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FollowPart(hrp, "This is you! Move with WASD")
    :EnablePulse(15)
    :Show()

task.delay(5, function()
    spotlight:Hide()
end)
```

---

## Highlighting an NPC

Draw attention to an important NPC in the world.

```lua
local questGiver = workspace.NPCs.QuestGiver

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FollowPart(questGiver, "Talk to this NPC for quests")
    :Show()

local character = player.Character
if character then
    local hrp = character:FindFirstChild("HumanoidRootPart")
    while task.wait(0.5) do
        if hrp and (hrp.Position - questGiver.Position).Magnitude < 10 then
            spotlight:Hide()
            break
        end
    end
end
```

---

## World Position Spotlight

Highlight a specific location in the 3D world.

```lua
local targetPosition = Vector3.new(100, 5, 50)

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FocusWorld(targetPosition, 8, "Go to this location")
    :EnablePulse(10)
    :Show()
```

---

## Multi-Step Tutorial with Circles

Create a complete tutorial using only circle spotlights.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        Part = character.HumanoidRootPart,
        Text = "Welcome! This is your character",
        Shape = "Circle",
        Pulse = 15
    },
    {
        UI = gui.HealthBar,
        Text = "This is your health bar",
        Shape = "Circle",
        Padding = 10
    },
    {
        Part = workspace.Checkpoint1,
        Text = "Move to this checkpoint",
        Shape = "Circle",
        Pulse = 12
    },
    {
        UI = gui.InventoryButton,
        Text = "Access your inventory here",
        Shape = "Circle",
        Padding = 20,
        Pulse = 8
    }
})

spotlight.stepCompleted:Connect(function()
    task.wait(4)
    spotlight:Next()
end)

spotlight:Start()
```

---

## Interactive Circle Spotlight

Create a spotlight that waits for player interaction before advancing.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FocusUI(gui.StartButton, 25, "Click this button to begin")
    :EnablePulse(15)
    :Show()

gui.StartButton.Activated:Wait()

spotlight
    :DisablePulse()
    :FocusUI(gui.SettingsButton, 15, "Configure your settings")
```

---

## Circular Spotlight on Moving Object

Track a moving platform or vehicle.

```lua
local movingPlatform = workspace.MovingPlatform

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FollowPart(movingPlatform, "Jump on this moving platform!")
    :EnablePulse(10)
    :Show()

task.delay(10, function()
    spotlight:Hide()
end)
```

---

## Subtle Circle Hint

Use a circle spotlight without pulse for a more subtle hint.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Circle")
    :FocusUI(gui.MinimapFrame, 10, "Use the minimap to navigate")
    :Show()
```

---

## Circle Spotlight for Achievement

Briefly highlight when a player earns an achievement.

```lua
local function ShowAchievementSpotlight(achievementName)
    local spotlight = SpotlightUI.new()
    
    spotlight
        :SetShape("Circle")
        :FocusUI(gui.AchievementPopup, 30, "Achievement unlocked!")
        :EnablePulse(20)
        :Show()
    
    task.delay(3, function()
        spotlight:Hide()
        task.wait(0.5)
        spotlight:Destroy()
    end)
end

player:GetAttributeChangedSignal("Achievements"):Connect(function()
    ShowAchievementSpotlight("First Victory")
end)
```

---

## Best Practices for Circle Spotlights

- **Use for central focus** - Circles naturally draw the eye to the center
- **Ideal for characters and NPCs** - The circular shape works well for humanoid models
- **Moderate padding** - Use 10-20 pixel padding for UI elements
- **Pulse for urgency** - Add pulse animation for time-sensitive or important actions
- **World positions** - Use 5-15 stud radius for world spotlights depending on object size