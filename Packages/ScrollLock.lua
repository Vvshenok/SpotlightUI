--!strict
--[[
	ScrollLock
	Walks the ancestor chain of a GuiObject, disables ScrollingEnabled on every
	ScrollingFrame it finds, and returns a cleanup function that restores each
	frame to its original state when called.

	This solves a common tutorial problem: the user can scroll away from the
	element being highlighted mid-step, breaking the visual. Locking the frames
	for the duration of the step prevents this entirely.

	Usage:
		local ScrollLock = require(path.to.ScrollLock)

		-- Lock before the step begins:
		local unlock = ScrollLock.Lock(someGuiElement)

		-- Unlock when the step ends (Next(), Hide(), or Destroy()):
		unlock()

	GetScrollOffset:
		ScrollLock also exposes GetScrollOffset, which computes the total canvas
		offset accumulated across all ancestor ScrollingFrames. This is needed to
		correct AbsolutePosition when an element lives inside a scrolled canvas,
		since AbsolutePosition does not account for CanvasPosition.

		local offset = ScrollLock.GetScrollOffset(someGuiElement)
		local truePos = element.AbsolutePosition - offset
--]]

-- ─── Types ────────────────────────────────────────────────────────────────────

export type UnlockFn = () -> ()

type LockedEntry = {
	frame: ScrollingFrame,
	was: boolean,
}

-- ─── Implementation ───────────────────────────────────────────────────────────

local ScrollLock = {}

--[=[
	Disables ScrollingEnabled on every ancestor ScrollingFrame of `ui`.
	Returns an unlock function that restores each frame's original state.
	Safe to call on elements with no ScrollingFrame ancestors — the returned
	function is a no-op in that case.

	The unlock function clears its internal state after running, so calling it
	multiple times is safe and does nothing on subsequent calls.

	@param ui -- The GuiObject whose ancestors should be locked.
	@return UnlockFn -- Call this to restore all ScrollingFrames.
]=]
function ScrollLock.Lock(ui: GuiObject): UnlockFn
	local locked: { LockedEntry } = {}
	local current: Instance? = ui.Parent

	while current ~= nil do
		if current:IsA("ScrollingFrame") then
			table.insert(locked, {
				frame = current,
				was = current.ScrollingEnabled,
			})
			current.ScrollingEnabled = false
		end

		if current:IsA("ScreenGui") then
			break
		end

		current = current.Parent
	end

	local active = true

	return function()
		if not active then return end
		active = false

		for _, entry in locked do
			if entry.frame and entry.frame.Parent then
				entry.frame.ScrollingEnabled = entry.was
			end
		end

		table.clear(locked)
	end
end

--[=[
	Returns the cumulative CanvasPosition offset across all ancestor
	ScrollingFrames of `ui`. Subtract this from AbsolutePosition to get the
	true screen position of an element inside a scrolled canvas.

	@param ui -- The GuiObject to walk ancestors for.
	@return Vector2 -- Total canvas offset.
]=]
function ScrollLock.GetScrollOffset(ui: GuiObject): Vector2
	local offset = Vector2.zero
	local current: Instance? = ui.Parent

	while current ~= nil do
		if current:IsA("ScrollingFrame") then
			offset += current.CanvasPosition
		end

		if current:IsA("ScreenGui") then
			break
		end

		current = current.Parent
	end

	return offset
end

--[=[
	Returns true if `ui` has at least one ScrollingFrame ancestor.
	Useful for deciding whether to call Lock at all.

	@param ui -- The GuiObject to check.
	@return boolean
]=]
function ScrollLock.HasScrollAncestor(ui: GuiObject): boolean
	local current: Instance? = ui.Parent

	while current ~= nil do
		if current:IsA("ScrollingFrame") then
			return true
		end
		if current:IsA("ScreenGui") then
			break
		end
		current = current.Parent
	end

	return false
end

return ScrollLock