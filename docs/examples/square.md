# Square Spotlight Examples

The square spotlight is perfect for highlighting UI panels, buttons, and rectangular interface elements.

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

## Square Spotlight for Panels

Perfect for highlighting entire UI panels or frames.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Square")
    :FocusUI(gui.InventoryPanel, 15, "Manage your items here")
    :EnablePulse(8)
    :Show()
```

---

## Highlighting Multiple UI Elements

Use squares to guide players through a series of UI controls.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        UI = gui.TopBar.CoinsDisplay,
        Text = "This shows your current coins",
        Shape = "Square",
        Padding = 12
    },
    {
        UI = gui.TopBar.GemsDisplay,
        Text = "This shows your premium currency",
        Shape = "Square",
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
        Shape = "Square",
        Padding = 10
    },
    {
        UI = gui.SettingsPanel.GraphicsDropdown,
        Text = "Choose your graphics quality",
        Shape = "Square",
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

-- Tight fit for small buttons
spotlight
    :SetShape("Square")
    :FocusUI(gui.CloseButton, 5, "Close this window")
    :Show()

task.wait(3)

-- Generous padding for larger panels
spotlight
    :FocusUI(gui.QuestPanel, 25, "Track your active quests")
    :Show()
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

-- Hide when mail is opened
gui.MailButton.Activated:Connect(function()
    spotlight:Hide()
end)
```

---

## Step-by-Step UI Tutorial

Complete onboarding flow using square spotlights.

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
        Shape = "Square",
        Padding = 18
    },
    {
        UI = gui.MainMenu.FriendsButton,
        Text = "Invite friends to play",
        Shape = "Square",
        Padding = 18
    }
})

-- Manual advancement on button clicks
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

-- Show tooltips on hover
gui.SkillButton.MouseEnter:Connect(function()
    local tip = ShowTooltip(gui.SkillButton, "Use special abilities")
    
    gui.SkillButton.MouseLeave:Connect(function()
        tip:Hide()
        tip:Destroy()
    end)
end)
```

---

## Highlighting Dropdown Menus

Guide users through menu selections.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Square")
    :FocusUI(gui.SettingsDropdown, 15, "Click to see options")
    :Show()

-- When dropdown opens
gui.SettingsDropdown.Activated:Connect(function()
    task.wait(0.5)
    spotlight
        :FocusUI(gui.SettingsDropdown.OptionsList, 10, "Select your preference")
end)
```

---

## Square Spotlight for Building UI

Guide players through building/crafting interfaces.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        UI = gui.BuildMenu.CategoryTabs,
        Text = "Choose a category",
        Shape = "Square",
        Padding = 12
    },
    {
        UI = gui.BuildMenu.ItemGrid,
        Text = "Select an item to place",
        Shape = "Square",
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
        Shape = "Square",
        Padding = 10
    }
})

spotlight:Start()
```

---

## Contextual Square Hints

Show hints only when relevant actions are available.

```lua
local spotlight = SpotlightUI.new()

-- Show crafting hint when player has materials
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

## Square Spotlight Animation Sequence

Create a smooth sequence highlighting multiple UI regions.

```lua
local spotlight = SpotlightUI.new()
local uiElements = {
    {gui.TopBar, "This is the top bar"},
    {gui.LeftSidebar, "Quick access menu"},
    {gui.RightPanel, "Stats and information"},
    {gui.BottomControls, "Game controls"}
}

local function highlightSequence()
    for i, data in uiElements do
        spotlight
            :SetShape("Square")
            :FocusUI(data[1], 15, data[2])
            :Show()
        
        task.wait(2.5)
    end
    
    spotlight:Hide()
end

highlightSequence()
```

---

## Best Practices for Square Spotlights

- **UI-first choice** - Squares are the natural choice for rectangular UI elements
- **Match UI shapes** - Use squares for buttons, panels, and frames
- **Padding consistency** - Use 10-20 pixel padding for most UI elements
- **Panel highlighting** - Perfect for entire frames or dialog boxes
- **Form guidance** - Excellent for multi-field forms and settings screens
- **Avoid on circles** - Don't use square spotlights on circular UI elements