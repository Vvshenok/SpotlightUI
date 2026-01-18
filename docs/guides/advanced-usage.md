# Advanced Usage

Learn advanced patterns and techniques for building sophisticated tutorial systems with SpotlightUI.

---

## Conditional Tutorial Flows

Create tutorials that branch based on player choices or game state.

```lua
local SpotlightUI = require(ReplicatedStorage.SpotlightUI)
local player = game.Players.LocalPlayer

local function startCombatTutorial()
    local combat = SpotlightUI.new()
    combat:SetSteps({
        { UI = gui.AttackButton, Text = "Click to attack enemies", Pulse = 10 },
        { UI = gui.DefendButton, Text = "Click to block incoming attacks" },
        { Part = workspace.TrainingDummy, Text = "Practice on this dummy" }
    })
    combat:Start()
end

local function startBuildingTutorial()
    local building = SpotlightUI.new()
    building:SetSteps({
        { UI = gui.BuildMenu, Text = "Open the build menu", Pulse = 8 },
        { UI = gui.PlaceButton, Text = "Select and place structures" }
    })
    building:Start()
end

-- Branch based on player choice
gui.CombatButton.Activated:Connect(startCombatTutorial)
gui.BuildingButton.Activated:Connect(startBuildingTutorial)
```

---

## Multi-Phase Tutorials

Break complex tutorials into phases that can be triggered independently.

```lua
local TutorialManager = {}
TutorialManager.currentPhase = 0
TutorialManager.spotlights = {}

function TutorialManager:StartPhase(phase)
    -- Clean up previous spotlight
    if self.spotlights[self.currentPhase] then
        self.spotlights[self.currentPhase]:Destroy()
    end
    
    self.currentPhase = phase
    local spotlight = SpotlightUI.new()
    self.spotlights[phase] = spotlight
    
    if phase == 1 then
        spotlight:SetSteps({
            { UI = gui.MovementKeys, Text = "Use WASD to move" },
            { UI = gui.JumpButton, Text = "Press Space to jump" }
        })
    elseif phase == 2 then
        spotlight:SetSteps({
            { Part = workspace.Chest, Text = "Collect items from chests" },
            { UI = gui.Inventory, Text = "View items in your inventory" }
        })
    elseif phase == 3 then
        spotlight:SetSteps({
            { Part = workspace.QuestNPC, Text = "Talk to NPCs for quests" },
            { UI = gui.QuestLog, Text = "Track your active quests here" }
        })
    end
    
    spotlight.sequenceCompleted:Connect(function()
        player:SetAttribute("TutorialPhase" .. phase, true)
    end)
    
    spotlight:Start()
end

-- Trigger phases based on game events
player:GetAttributeChangedSignal("Level"):Connect(function()
    local level = player:GetAttribute("Level")
    if level == 5 and not player:GetAttribute("TutorialPhase2") then
        TutorialManager:StartPhase(2)
    elseif level == 10 and not player:GetAttribute("TutorialPhase3") then
        TutorialManager:StartPhase(3)
    end
end)

TutorialManager:StartPhase(1)
```

---

## Interactive Step Validation

Ensure players complete actions before advancing through tutorial steps.

```lua
local spotlight = SpotlightUI.new()
local currentStepIndex = 0
local stepValidations = {}

-- Define validation functions for each step
stepValidations[1] = function()
    return gui.PlayButton.Activated:Wait()
end

stepValidations[2] = function()
    return gui.InventoryButton.Activated:Wait()
end

stepValidations[3] = function()
    -- Wait until player reaches a position
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    repeat
        task.wait(0.5)
    until (hrp.Position - workspace.TargetLocation.Position).Magnitude < 10
end

spotlight:SetSteps({
    { UI = gui.PlayButton, Text = "Click the play button", Shape = "Circle", Pulse = 10 },
    { UI = gui.InventoryButton, Text = "Open your inventory", Shape = "Square" },
    { Part = workspace.TargetLocation, Text = "Walk to this location", Shape = "Triangle" }
})

spotlight.stepCompleted:Connect(function(stepIndex)
    currentStepIndex = stepIndex
    
    -- Wait for validation before advancing
    if stepValidations[stepIndex] then
        task.spawn(function()
            stepValidations[stepIndex]()
            spotlight:Next()
        end)
    else
        -- Auto-advance if no validation
        task.wait(2)
        spotlight:Next()
    end
end)

spotlight:Start()
```

---

## Context-Aware Tutorials

Show different tutorials based on player experience or preferences.

```lua
local TutorialSystem = {}
TutorialSystem.hasSeenTutorial = {}

function TutorialSystem:ShouldShowTutorial(tutorialName)
    -- Check if player has disabled tutorials
    if player:GetAttribute("TutorialsDisabled") then
        return false
    end
    
    -- Check if player has seen this specific tutorial
    if self.hasSeenTutorial[tutorialName] then
        return false
    end
    
    -- Check if player is experienced enough to skip
    local level = player:GetAttribute("Level") or 1
    if tutorialName == "Basic" and level > 5 then
        return false
    end
    
    return true
end

function TutorialSystem:ShowShopTutorial()
    if not self:ShouldShowTutorial("Shop") then return end
    
    local spotlight = SpotlightUI.new()
    spotlight:SetSteps({
        { UI = gui.ShopButton, Text = "Click to open the shop" },
        { UI = gui.ShopFrame.BuyButton, Text = "Purchase items here" },
        { UI = gui.ShopFrame.SellButton, Text = "Sell unwanted items" }
    })
    
    spotlight.sequenceCompleted:Connect(function()
        self.hasSeenTutorial["Shop"] = true
        player:SetAttribute("SeenShopTutorial", true)
    end)
    
    spotlight:Start()
end

-- Trigger when player opens shop for first time
gui.ShopButton.Activated:Connect(function()
    TutorialSystem:ShowShopTutorial()
end)
```

---

## Spotlight Hints with Custom Actions

Add buttons or interactive elements to spotlight hints.

```lua
-- Note: This requires modifying the hint frame, shown here conceptually

local spotlight = SpotlightUI.new()

-- Access internal hint frame (advanced usage)
local hint = spotlight._hint

-- Add a skip button
local skipButton = Instance.new("TextButton")
skipButton.Size = UDim2.new(0, 60, 0, 25)
skipButton.Position = UDim2.new(1, -70, 1, -30)
skipButton.Text = "Skip"
skipButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
skipButton.TextColor3 = Color3.new(1, 1, 1)
skipButton.BorderSizePixel = 0
skipButton.Parent = hint

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 4)
corner.Parent = skipButton

skipButton.Activated:Connect(function()
    spotlight:Skip()
end)

spotlight:SetSteps({
    { UI = gui.Button1, Text = "Step 1 - Click or skip", Pulse = 10 },
    { UI = gui.Button2, Text = "Step 2 - Almost done" }
})

spotlight:Start()
```

---

## Spotlight State Persistence

Save and restore tutorial progress across sessions.

```lua
local DataStoreService = game:GetService("DataStoreService")
local TutorialData = DataStoreService:GetDataStore("TutorialProgress")

local TutorialManager = {}

function TutorialManager:SaveProgress(tutorialName, stepIndex)
    local success, err = pcall(function()
        TutorialData:SetAsync(player.UserId .. "_" .. tutorialName, {
            stepIndex = stepIndex,
            timestamp = os.time()
        })
    end)
    
    if not success then
        warn("Failed to save tutorial progress:", err)
    end
end

function TutorialManager:LoadProgress(tutorialName)
    local success, data = pcall(function()
        return TutorialData:GetAsync(player.UserId .. "_" .. tutorialName)
    end)
    
    if success and data then
        return data.stepIndex or 0
    end
    return 0
end

function TutorialManager:StartResumableTutorial(tutorialName, steps)
    local spotlight = SpotlightUI.new()
    local savedStep = self:LoadProgress(tutorialName)
    
    spotlight:SetSteps(steps)
    
    spotlight.stepCompleted:Connect(function(stepIndex)
        self:SaveProgress(tutorialName, stepIndex)
    end)
    
    spotlight.sequenceCompleted:Connect(function()
        self:SaveProgress(tutorialName, #steps)
    end)
    
    -- Resume from saved progress
    spotlight:Start()
    for i = 1, savedStep do
        spotlight:Next()
    end
end

-- Usage
TutorialManager:StartResumableTutorial("MainQuest", {
    { UI = gui.QuestButton, Text = "Open quests" },
    { Part = workspace.QuestGiver, Text = "Talk to the quest giver" },
    { UI = gui.ObjectiveTracker, Text = "Track your objectives" }
})
```

---

## Dynamic Spotlight Positioning

Adjust spotlight position dynamically based on screen size or orientation.

```lua
local spotlight = SpotlightUI.new()
local camera = workspace.CurrentCamera

-- Detect screen orientation changes
camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    local viewportSize = camera.ViewportSize
    local isPortrait = viewportSize.Y > viewportSize.X
    
    if isPortrait then
        -- Adjust hint positioning for mobile portrait mode
        spotlight._hint.Size = UDim2.fromOffset(250, 80)
    else
        -- Desktop/landscape mode
        spotlight._hint.Size = UDim2.fromOffset(300, 60)
    end
end)

spotlight:SetSteps({
    { UI = gui.MobileButton, Text = "Tap here on mobile" },
    { Part = workspace.Checkpoint, Text = "Navigate to this point" }
})

spotlight:Start()
```

---

## Combining Multiple Spotlights

Layer multiple spotlights for complex scenarios (use carefully to avoid confusion).

```lua
local primarySpotlight = SpotlightUI.new()
local secondarySpotlight = SpotlightUI.new()

-- Primary spotlight for main objective
primarySpotlight
    :FocusUI(gui.ObjectiveButton, 20, "Main objective: Click here")
    :SetShape("Circle")
    :EnablePulse(12)
    :Show()

-- Secondary spotlight for optional hint
secondarySpotlight
    :FocusUI(gui.HintButton, 10, "Optional: Click for a hint")
    :SetShape("Square")
    :Show()

-- Clean up secondary when primary is completed
primarySpotlight.sequenceCompleted:Connect(function()
    secondarySpotlight:Destroy()
end)
```

!!! Warning
    Multiple simultaneous spotlights can overwhelm players. Use this pattern sparingly and ensure the primary spotlight is visually distinct.

---

## Performance Optimization

Tips for maintaining performance with complex tutorials:

### Reuse Spotlight Instances

```lua
-- Bad: Creating new instances repeatedly
for i = 1, 10 do
    local spotlight = SpotlightUI.new()
    spotlight:FocusUI(buttons[i], 10, "Click " .. i):Show()
    task.wait(2)
    spotlight:Destroy()
end

-- Good: Reuse one instance
local spotlight = SpotlightUI.new()
for i = 1, 10 do
    spotlight:FocusUI(buttons[i], 10, "Click " .. i):Show()
    task.wait(2)
end
spotlight:Destroy()
```

### Limit Simultaneous Tracking

```lua
-- Bad: Tracking many objects at once
local spotlights = {}
for _, npc in workspace.NPCs:GetChildren() do
    local s = SpotlightUI.new()
    s:FollowPart(npc):Show()
    table.insert(spotlights, s)
end

-- Good: Track one at a time or use static world positions
local spotlight = SpotlightUI.new()
for _, npc in workspace.NPCs:GetChildren() do
    spotlight:FollowPart(npc, "Talk to " .. npc.Name):Show()
    task.wait(5)
end
```

### Destroy When Done

```lua
local spotlight = SpotlightUI.new()

spotlight.sequenceCompleted:Connect(function()
    task.wait(1)
    spotlight:Destroy()  -- Free up resources
end)

spotlight:SetSteps({...}):Start()
```

---

## Error Handling

Handle edge cases gracefully in production code:

```lua
local function SafeStartTutorial(gui, steps)
    local success, err = pcall(function()
        local spotlight = SpotlightUI.new()
        
        -- Validate steps before starting
        for i, step in steps do
            if step.UI and not step.UI.Parent then
                warn("Step", i, "references a deleted UI element")
                return
            end
            if step.Part and not step.Part.Parent then
                warn("Step", i, "references a deleted Part")
                return
            end
        end
        
        spotlight:SetSteps(steps)
        spotlight:Start()
    end)
    
    if not success then
        warn("Tutorial failed to start:", err)
    end
end

-- Usage
SafeStartTutorial(gui, {
    { UI = gui.Button1, Text = "Click here" },
    { Part = workspace.Door, Text = "Go to door" }
})
```

---

## Integration with Game Systems

### Quest System Integration

```lua
local QuestSystem = {}

function QuestSystem:StartQuest(questId)
    local questData = self:GetQuestData(questId)
    
    -- Create tutorial for first-time quest
    if questData.hasSpotlight and not player:GetAttribute("Quest_" .. questId) then
        local spotlight = SpotlightUI.new()
        
        spotlight:SetSteps({
            { Part = questData.npc, Text = "Talk to " .. questData.npcName },
            { World = questData.objective, Radius = 15, Text = questData.objectiveText },
            { Part = questData.npc, Text = "Return to " .. questData.npcName }
        })
        
        spotlight.sequenceCompleted:Connect(function()
            player:SetAttribute("Quest_" .. questId, true)
        end)
        
        spotlight:Start()
    end
end
```

### Achievement System

```lua
local AchievementSpotlight = {}

function AchievementSpotlight:ShowNewAchievement(achievementName)
    local spotlight = SpotlightUI.new()
    
    spotlight
        :FocusUI(gui.AchievementPopup, 25, "You unlocked: " .. achievementName)
        :SetShape("Square")
        :EnablePulse(15)
        :Show()
    
    -- Auto-hide after 4 seconds
    task.delay(4, function()
        spotlight:Hide()
        task.wait(0.5)
        spotlight:Destroy()
    end)
end
```

---

## Best Practices Summary

1. **Destroy when finished** - Always call `:Destroy()` when done with a spotlight
2. **Validate references** - Check that UI elements and parts exist before creating steps
3. **Limit concurrent spotlights** - Avoid showing multiple spotlights simultaneously
4. **Provide skip options** - Let players who know the game skip tutorials
5. **Test on all platforms** - Ensure spotlights work on mobile, tablet, and desktop
6. **Save progress** - For long tutorials, save progress to DataStores
7. **Use appropriate shapes** - Circles for focus points, squares for UI, triangles for direction
8. **Keep text concise** - Hint text should be brief and actionable