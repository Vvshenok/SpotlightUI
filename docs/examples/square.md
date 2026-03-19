# Square & Rectangle Spotlight Examples

Square and Rectangle spotlights are perfect for highlighting UI panels, buttons, and rectangular interface elements.

---

## Basic Square Spotlight

Highlight a UI button with a square spotlight.

```lua
local SpotlightUI = require(ReplicatedStorage.SpotlightUI)
local gui = player.PlayerGui.ScreenGui

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Square")
    :FocusUI(gui.MenuButton, 20, "Open the main menu")
    :Show()
```

---

## Rectangle Spotlight for Panels

Rectangle wraps the element's exact width and height — ideal for wide frames and banners.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Rectangle")
    :FocusUI(gui.InventoryPanel, 12, "Manage your items here")
    :EnablePulse(8)
    :Show()
```

---

## Highlighting Multiple UI Elements

Use spotlights to guide players through a series of UI controls.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        UI = gui.TopBar.CoinsDisplay,
        Text = "This shows your current coins",
        Shape = "Rectangle",
        Padding = 12
    },
    {
        UI = gui.TopBar.GemsDisplay,
        Text = "This shows your premium currency",
        Shape = "Rectangle",
        Padding = 12
    },
    {
        UI = gui.SideMenu.ShopButton,
        Text = "Purchase items in the shop",
        Shape = "Square",
        Padding = 15,
        Pulse = 10
    }
})

spotlight.stepCompleted:Connect(function()
    task.wait(3)
    spotlight:Next()
end)

spotlight:Start()
```

---

## Square Spotlight for Forms

Guide users through filling out forms or settings.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        UI = gui.SettingsPanel.UsernameInput,
        Text = "Enter your username",
        Shape = "Rectangle",
        Padding = 10
    },
    {
        UI = gui.SettingsPanel.GraphicsDropdown,
        Text = "Choose your graphics quality",
        Shape = "Rectangle",
        Padding = 10
    },
    {
        UI = gui.SettingsPanel.SaveButton,
        Text = "Save your settings",
        Shape = "Square",
        Padding = 15,
        Pulse = 10
    }
})

spotlight:Start()
```

---

## Square with Custom Padding

Adjust padding to fit different UI layouts.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Square")
    :FocusUI(gui.CloseButton, 5, "Close this window")
    :Show()

task.wait(3)

spotlight:FocusUI(gui.QuestPanel, 25, "Track your active quests")
```

---

## Highlighting Notification Badges

Draw attention to notification indicators.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Square")
    :FocusUI(gui.MailButton.NotificationBadge, 15, "You have new mail!")
    :EnablePulse(12)
    :Show()

gui.MailButton.Activated:Connect(function()
    spotlight:Hide()
end)
```

---

## Step-by-Step UI Tutorial

Complete onboarding flow using square and rectangle spotlights.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        UI = gui.WelcomeScreen.ContinueButton,
        Text = "Welcome! Click continue",
        Shape = "Square",
        Padding = 20,
        Pulse = 15
    },
    {
        UI = gui.MainMenu.PlayButton,
        Text = "Start playing here",
        Shape = "Square",
        Padding = 18
    },
    {
        UI = gui.MainMenu.CustomizeButton,
        Text = "Customize your character",
        Shape = "Rectangle",
        Padding = 18
    },
    {
        UI = gui.MainMenu.FriendsButton,
        Text = "Invite friends to play",
        Shape = "Square",
        Padding = 18
    }
})

gui.WelcomeScreen.ContinueButton.Activated:Connect(function()
    spotlight:Next()
end)

spotlight:Start()
```

---

## Square Spotlight for Tooltips

Create tooltip-style hints for UI elements.

```lua
local function ShowTooltip(element, text)
    local tooltip = SpotlightUI.new()

    tooltip
        :SetShape("Square")
        :FocusUI(element, 8, text)
        :Show()

    return tooltip
end

local tip
gui.SkillButton.MouseEnter:Connect(function()
    tip = ShowTooltip(gui.SkillButton, "Use special abilities")
end)

gui.SkillButton.MouseLeave:Connect(function()
    if tip then
        tip:Hide()
        tip:Destroy()
        tip = nil
    end
end)
```

---

## Square Spotlight for Building UI

Guide players through building or crafting interfaces.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        UI = gui.BuildMenu.CategoryTabs,
        Text = "Choose a category",
        Shape = "Rectangle",
        Padding = 12
    },
    {
        UI = gui.BuildMenu.ItemGrid,
        Text = "Select an item to place",
        Shape = "Rectangle",
        Padding = 15
    },
    {
        UI = gui.BuildMenu.PlaceButton,
        Text = "Click to place the item",
        Shape = "Square",
        Padding = 18,
        Pulse = 10
    },
    {
        UI = gui.BuildMenu.RotateButtons,
        Text = "Rotate before placing",
        Shape = "Rectangle",
        Padding = 10
    }
})

spotlight:Start()
```

---

## Contextual Hints

Show hints only when relevant actions are available.

```lua
local spotlight = SpotlightUI.new()

player:GetAttributeChangedSignal("HasCraftingMaterials"):Connect(function()
    if player:GetAttribute("HasCraftingMaterials") then
        spotlight
            :SetShape("Square")
            :FocusUI(gui.CraftButton, 15, "You can craft something!")
            :EnablePulse(10)
            :Show()
    else
        spotlight:Hide()
    end
end)
```

---

## Best Practices for Square & Rectangle Spotlights

- **Rectangle for wide elements** - Use Rectangle for horizontal bars, panels, and banners
- **Square for buttons** - Use Square for roughly equal-sized interactive elements
- **Match UI shapes** - Let the element's aspect ratio guide your shape choice
- **Padding consistency** - Use 10-20 pixel padding for most UI elements
- **Avoid on circles** - Don't use square spotlights on circular UI elements