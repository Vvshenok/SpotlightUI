# Triangle Spotlight Examples

The triangle spotlight is unique and perfect for directional guidance, pointing players toward objectives or indicating movement.

---

## Basic Triangle Spotlight

Use a triangle to point toward a destination.

```lua
local SpotlightUI = require(ReplicatedStorage.SpotlightUI)

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Triangle")
    :FocusWorld(workspace.Destination.Position, 10, "Go this way!")
    :EnablePulse(12)
    :Show()
```

---

## Directional Guidance

Point players toward an objective with clear direction.

```lua
local checkpoint = workspace.Checkpoints.Checkpoint1

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Triangle")
    :FollowPart(checkpoint, "Head to the checkpoint")
    :EnablePulse(15)
    :Show()

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

while task.wait(0.5) do
    if (hrp.Position - checkpoint.Position).Magnitude < 15 then
        spotlight:Hide()
        break
    end
end
```

---

## Tutorial Path Navigation

Guide players through a series of waypoints.

```lua
local spotlight = SpotlightUI.new()
local waypoints = workspace.TutorialPath:GetChildren()

spotlight:SetSteps({
    {
        Part = waypoints[1],
        Text = "Follow the path to your first objective",
        Shape = "Triangle",
        Pulse = 12
    },
    {
        Part = waypoints[2],
        Text = "Continue following the markers",
        Shape = "Triangle",
        Pulse = 12
    },
    {
        Part = waypoints[3],
        Text = "Almost there!",
        Shape = "Triangle",
        Pulse = 15
    },
    {
        Part = waypoints[4],
        Text = "You've arrived!",
        Shape = "Triangle"
    }
})

local character = player.Character
local hrp = character and character:FindFirstChild("HumanoidRootPart")

spotlight.stepCompleted:Connect(function(stepIndex)
    if not hrp then return end
    
    local targetWaypoint = waypoints[stepIndex]
    
    repeat
        task.wait(0.5)
    until (hrp.Position - targetWaypoint.Position).Magnitude < 10
    
    task.wait(1)
    spotlight:Next()
end)

spotlight:Start()
```

---

## Pointing to Entrances/Exits

Highlight doors, portals, or passages.

```lua
local exitDoor = workspace.ExitDoor

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Triangle")
    :FollowPart(exitDoor, "Exit through this door")
    :EnablePulse(10)
    :Show()
```

---

## Quest Objective Marker

Mark quest locations in the world.

```lua
local function MarkQuestObjective(objectivePart, description)
    local marker = SpotlightUI.new()
    
    marker
        :SetShape("Triangle")
        :FollowPart(objectivePart, description)
        :EnablePulse(12)
        :Show()
    
    return marker
end

local questMarker = MarkQuestObjective(
    workspace.QuestItems.MagicCrystal,
    "Collect the magic crystal"
)

workspace.QuestItems.MagicCrystal.Touched:Connect(function(hit)
    if hit.Parent:FindFirstChild("Humanoid") then
        questMarker:Hide()
        questMarker:Destroy()
    end
end)
```

---

## Movement Tutorial

Teach players how to navigate terrain.

```lua
local spotlight = SpotlightUI.new()

spotlight:SetSteps({
    {
        Part = workspace.WalkTarget,
        Text = "Walk forward using W or ↑",
        Shape = "Triangle",
        Pulse = 10
    },
    {
        Part = workspace.JumpTarget,
        Text = "Jump over obstacles with Space",
        Shape = "Triangle",
        Pulse = 10
    },
    {
        Part = workspace.SprintTarget,
        Text = "Sprint with Shift while moving",
        Shape = "Triangle",
        Pulse = 12
    }
})

spotlight:Start()
```

---

## Following Moving Vehicles

Track moving objects with triangular indicators.

```lua
local movingTrain = workspace.Train

local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Triangle")
    :FollowPart(movingTrain.MainPart, "Board this train!")
    :EnablePulse(15)
    :Show()

while task.wait(0.5) do
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if hrp and (hrp.Position - movingTrain.MainPart.Position).Magnitude < 20 then
        spotlight:Hide()
        break
    end
end
```

---

## Escape Sequence

Guide players during time-sensitive evacuations.

```lua
local spotlight = SpotlightUI.new()

spotlight
    :SetShape("Triangle")
    :FollowPart(workspace.SafeZone, "Get to the safe zone!")
    :EnablePulse(20)
    :Show()

local timeLeft = 30

while timeLeft > 0 do
    task.wait(1)
    timeLeft -= 1
    
    if timeLeft <= 10 then
        spotlight:DisablePulse():EnablePulse(25)
    end
end

spotlight:Hide()
```

---

## Multi-Objective Markers

Show multiple objectives using triangles.

```lua
local objectiveMarkers = {}

local function CreateObjectiveMarker(part, text, priority)
    local marker = SpotlightUI.new()
    
    marker
        :SetShape("Triangle")
        :FollowPart(part, text)
        :EnablePulse(priority or 10)
        :Show()
    
    return marker
end

objectiveMarkers.primary = CreateObjectiveMarker(
    workspace.PrimaryObjective,
    "Main quest objective",
    15
)

objectiveMarkers.secondary = CreateObjectiveMarker(
    workspace.SecondaryObjective,
    "Optional: Side quest",
    8
)

local function CompleteObjective(name)
    if objectiveMarkers[name] then
        objectiveMarkers[name]:Hide()
        task.wait(0.5)
        objectiveMarkers[name]:Destroy()
    end
end
```

---

## Race Checkpoints

Guide players through racing checkpoints.

```lua
local spotlight = SpotlightUI.new()
local checkpoints = workspace.RaceTrack.Checkpoints:GetChildren()

table.sort(checkpoints, function(a, b)
    return tonumber(a.Name) < tonumber(b.Name)
end)

local currentCheckpoint = 1

spotlight
    :SetShape("Triangle")
    :FollowPart(checkpoints[currentCheckpoint], "Checkpoint " .. currentCheckpoint)
    :EnablePulse(15)
    :Show()

for _, checkpoint in checkpoints do
    checkpoint.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") then
            currentCheckpoint += 1
            
            if checkpoints[currentCheckpoint] then
                spotlight
                    :FollowPart(checkpoints[currentCheckpoint], "Checkpoint " .. currentCheckpoint)
            else
                spotlight:Hide()
            end
        end
    end)
end
```

---

## Treasure Hunt

Point toward hidden collectibles.

```lua
local function CreateTreasureHint(treasure)
    local hint = SpotlightUI.new()
    
    hint
        :SetShape("Triangle")
        :FollowPart(treasure, "Treasure nearby!")
        :EnablePulse(12)
        :Show()
    
    treasure.Touched:Connect(function(hit)
        if hit.Parent:FindFirstChild("Humanoid") then
            hint:Hide()
            task.wait(0.5)
            hint:Destroy()
        end
    end)
end

for _, treasure in workspace.Treasures:GetChildren() do
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if hrp and (hrp.Position - treasure.Position).Magnitude < 50 then
        CreateTreasureHint(treasure)
    end
end
```

---

## Enemy/Danger Warning

Use triangles to warn about threats.

```lua
local dangerSpotlight = SpotlightUI.new()

local function WarnAboutDanger(threat, description)
    dangerSpotlight
        :SetShape("Triangle")
        :FollowPart(threat, description or "Danger ahead!")
        :EnablePulse(18)
        :Show()
end

while task.wait(1) do
    local character = player.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    
    if hrp then
        for _, enemy in workspace.Enemies:GetChildren() do
            local distance = (hrp.Position - enemy.PrimaryPart.Position).Magnitude
            
            if distance < 30 then
                WarnAboutDanger(enemy, "Enemy nearby!")
                break
            else
                dangerSpotlight:Hide()
            end
        end
    end
end
```

---

## Best Practices for Triangle Spotlights

- **Directional use** - Triangles naturally suggest "go this way"
- **World objectives** - Perfect for 3D world positions and navigation
- **Movement guidance** - Ideal for teaching players where to walk/run
- **Quest markers** - Excellent for marking objectives and waypoints
- **Pulse for urgency** - Use stronger pulses for time-sensitive objectives
- **Avoid on UI** - Triangles look awkward on flat UI elements; use circles or squares instead