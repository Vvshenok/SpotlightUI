# Development Roadmap

SpotlightUI is actively maintained and continuously improved. This page outlines planned features, bug fixes, and future enhancements.

---

## Current Version: v1.0

### What's New in v1

- **Four spotlight shapes** — Circle, Square, Rounded, and Rectangle with smooth animated transitions
- **Spring-based movement** — Critically-damped spring integrator replaces the old tween driver for smooth, physics-feel following
- **Screen-ratio-aware sizing** — All pixel values scale proportionally with viewport size, so layouts look correct on any screen
- **ScrollFrame locking** — Ancestor ScrollingFrames are disabled during a step so the user can't scroll away from the highlighted element
- **Off-screen arrow indicator** — When a target is outside the viewport, an animated arrow appears at the screen edge pointing toward it
- **World object Highlight pulse** — A pulsing Roblox Highlight instance is automatically attached to parts and models during FollowPart steps
- **Live UI tracking** — FocusUI now re-evaluates every frame, so spotlights automatically adjust when elements move or resize
- **FollowPart camera fix** — Spotlight stays locked to the correct screen pixel regardless of camera movement
- **First-party Packages** — Spring, ScrollLock, PositionUtil, Highlight, and AnimationUtil are independently usable modules

---

## Known Issues

- Mobile device compatibility improvements in progress
- Performance not yet tested with more than a few simultaneous spotlights

---

## Version 2.1 (Next Release)

### Bug Fixes
- Improved mobile touch detection
- Performance profiling and optimisation pass for multiple spotlights

### New Features
- **Custom Color Themes** - Customize overlay, hint, and pulse colors
- **Click-to-Advance** - Automatically progress to the next step when the user interacts with the highlighted element
- **Progress Indicators** - Display "Step 2 of 5" to show tutorial progress
- **Step Callbacks** - Per-step OnShow and OnComplete callbacks

---

## Version 2.2 (Planned)

### Features
- **Multi-Target Highlighting** - Spotlight multiple UI elements or objects simultaneously
- **Animation Presets** - Built-in entrance/exit animations (fade, bounce, zoom, slide)
- **Replay Controls** - Add skip, previous, and replay buttons to tutorials
- **Mobile Gestures** - Swipe and tap gesture support for mobile users

---

## Version 3.0 (Future)

### Advanced Features
- **Conditional Steps** - Show steps based on player level, achievements, or custom conditions
- **Branching Tutorials** - Create multiple tutorial paths based on user choices
- **Voice-Over Integration** - Play audio clips with tutorial steps
- **World Space UI** - Spotlight billboard GUIs attached to parts

### Polish & Accessibility
- **High Contrast Mode** - Improved visibility for accessibility
- **Reduced Motion** - Option to disable animations for motion sensitivity
- **Analytics & Metrics** - Track completion rates, drop-off points, and average time per step

---

## Community Requests

Have a feature request? Open an issue on [GitHub](https://github.com/Vvshenok/SpotlightUI/issues) or start a discussion!

### Top Community Requests
- Particle effects around spotlights (sparkles, glow, confetti)
- Tooltip system for quick hints
- Integration with popular UI libraries (Fusion, Roact, React-Lua)
- More shape options (hexagon, star, arrow)
- Custom easing functions for animations

---

**Last Updated:** March 2026