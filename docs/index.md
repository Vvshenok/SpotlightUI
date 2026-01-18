# SpotlightUI

<div style="text-align: center; margin: 2rem 0;">
  <img src="https://img.shields.io/github/stars/Vvshenok/SpotlightUI?style=social" alt="GitHub stars">
  <img src="https://img.shields.io/github/license/Vvshenok/SpotlightUI" alt="License">
  <img src="https://img.shields.io/badge/Roblox-Luau-blue" alt="Luau">
</div>

**SpotlightUI** is a lightweight, powerful guided focus module for Roblox that helps you create elegant tutorials, onboarding flows, and feature highlights with minimal code.

## Why SpotlightUI?

Building effective tutorials shouldn't require hundreds of lines of code. SpotlightUI provides a clean, chainable API that lets you guide players through your game with style.

### Key Features

- **🎯 Multiple Spotlight Shapes** - Circle, Square, and Triangle spotlights
- **🌍 World & UI Support** - Highlight both 3D world objects and GUI elements
- **✨ Real-time Tracking** - Spotlights automatically follow moving objects
- **💫 Pulse Animations** - Draw attention with customizable pulsing effects
- **📚 Step-based System** - Create multi-step tutorials with ease
- **🔗 Chainable API** - Fluent interface for readable, maintainable code
- **🧹 Automatic Cleanup** - Built-in Janitor integration for memory safety

## Quick Example

```lua
local SpotlightUI = require(path.to.SpotlightUI)

-- Single spotlight
SpotlightUI.new()
    :FocusUI(playerGui.MainMenu.PlayButton, 20, "Click here to start!")
    :SetShape("Circle")
    :EnablePulse(10)
    :Show()

-- Multi-step tutorial
local spotlight = SpotlightUI.new()
spotlight:SetSteps({
    { UI = gui.Button1, Text = "First, click this button", Shape = "Circle", Pulse = 10 },
    { Part = workspace.Door, Text = "Now go to the door", Shape = "Triangle" },
    { UI = gui.Settings, Text = "Finally, open settings", Shape = "Square", Padding = 15 }
})
spotlight:Start()
```

## Getting Started

Ready to add guided tutorials to your game? Check out the [Getting Started](guides/getting-started.md) guide to learn the basics, or dive into the [API Reference](api/reference.md) for detailed documentation.

## Installation

Get SpotlightUI from:

- **GitHub**: [Latest Release](https://github.com/Vvshenok/SpotlightUI/releases)
- **Roblox Library**: Coming soon

## Community & Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/Vvshenok/SpotlightUI/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/Vvshenok/SpotlightUI/discussions)

## Credits

Created by [@Vvshenok](https://github.com/Vvshenok) & Interactive Studios

Licensed under MIT - feel free to use in your projects!

---

<div style="text-align: center; margin-top: 3rem; color: #666;">
  <p>Made by Vvshenok, Usefuly Rblx Community Resource.</p>
</div>