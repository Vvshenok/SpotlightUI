--!strict
--[[
	PositionUtil
	Pure 2D screen-space math utilities. No Roblox services, no state, no
	knowledge of SpotlightUI internals — every function takes plain Vector2
	values and returns plain Vector2 values or numbers.

	Functions:
		PositionUtil.ClampToScreen(pos, size, screenSize, padding)
			Clamps the centre of a UI element so its bounds stay fully inside
			the viewport, with an optional bottom-edge padding.

		PositionUtil.GetHintPosition(spotlightPos, spotlightSize, hintSize, screenSize, hintOffset, hintPadding)
			Returns the screen position for a hint label sitting below the
			spotlight, clamped so it never clips outside the viewport.

		PositionUtil.ProjectToEdge(target, screenSize, margin)
			Projects an off-screen point to the nearest viewport edge.
			Returns the clamped edge position and the angle in radians pointing
			from the screen centre toward the target (use for arrow rotation).

		PositionUtil.IsOnScreen(point, screenSize, margin?)
			Returns true if `point` is within the viewport, with an optional
			inward margin.

		PositionUtil.ScreenCentre(screenSize)
			Returns the centre of the screen as a Vector2. Convenience wrapper
			to avoid writing Vector2.new(s.X/2, s.Y/2) everywhere.

		PositionUtil.LerpVector2(a, b, t)
			Linear interpolation between two Vector2 values. Useful for
			manual blending without tweens.
--]]

-- ─── Types ────────────────────────────────────────────────────────────────────

export type EdgeResult = {
	position: Vector2,
	angle: number,
}

-- ─── Implementation ───────────────────────────────────────────────────────────

local PositionUtil = {}

--[=[
	Clamps `pos` (the centre of a UI element) so the element's full bounds stay
	inside the viewport. `padding` reserves extra space at the bottom edge,
	useful when a hint sits below the spotlight.

	@param pos        -- Centre position to clamp.
	@param size       -- Size of the element being clamped.
	@param screenSize -- Viewport size.
	@param padding    -- Extra bottom margin to keep clear.
	@return Vector2
]=]
function PositionUtil.ClampToScreen(
	pos: Vector2,
	size: Vector2,
	screenSize: Vector2,
	padding: number
): Vector2
	local x = math.clamp(pos.X, size.X / 2, screenSize.X - size.X / 2)
	local y = math.clamp(pos.Y, 0, screenSize.Y - size.Y - padding)
	return Vector2.new(x, y)
end

--[=[
	Returns the screen position for a hint label below a spotlight, clamped so
	it stays fully within the viewport.

	@param spotlightPos  -- Centre of the spotlight in screen space.
	@param spotlightSize -- Current size of the spotlight.
	@param hintSize      -- Size of the hint label.
	@param screenSize    -- Viewport size.
	@param hintOffset    -- Gap between the spotlight bottom and the hint top.
	@param hintPadding   -- Bottom-edge padding passed to ClampToScreen.
	@return Vector2
]=]
function PositionUtil.GetHintPosition(
	spotlightPos: Vector2,
	spotlightSize: Vector2,
	hintSize: Vector2,
	screenSize: Vector2,
	hintOffset: number,
	hintPadding: number
): Vector2
	local centreX = spotlightPos.X
	local bottomY = spotlightPos.Y + spotlightSize.Y / 2 + hintOffset
	return PositionUtil.ClampToScreen(
		Vector2.new(centreX, bottomY),
		hintSize,
		screenSize,
		hintPadding
	)
end

--[=[
	Projects an off-screen `target` to the nearest edge of the viewport.
	Uses parametric ray-AABB intersection from the screen centre.

	@param target     -- The off-screen point in screen space.
	@param screenSize -- Viewport size.
	@param margin     -- Minimum distance from the viewport corners.
	@return Vector2   -- Clamped position on the viewport edge.
	@return number    -- Angle in radians from the centre toward the target.
]=]
function PositionUtil.ProjectToEdge(
	target: Vector2,
	screenSize: Vector2,
	margin: number
): (Vector2, number)
	local cx = screenSize.X / 2
	local cy = screenSize.Y / 2
	local dx = target.X - cx
	local dy = target.Y - cy
	local angle = math.atan2(dy, dx)

	local halfW = cx - margin
	local halfH = cy - margin

	-- Find the parametric t at which the ray hits each axis boundary, then
	-- take the smaller t (the boundary hit first).
	local scaleX = if dx ~= 0 then math.abs(halfW / dx) else math.huge
	local scaleY = if dy ~= 0 then math.abs(halfH / dy) else math.huge
	local scale = math.min(scaleX, scaleY)

	local ex = math.clamp(cx + dx * scale, margin, screenSize.X - margin)
	local ey = math.clamp(cy + dy * scale, margin, screenSize.Y - margin)

	return Vector2.new(ex, ey), angle
end

--[=[
	Returns true if `point` is inside the viewport bounds.
	`margin` shrinks the considered area inward on all sides.

	@param point      -- The screen-space point to test.
	@param screenSize -- Viewport size.
	@param margin     -- Optional inward margin. Default: 0.
	@return boolean
]=]
function PositionUtil.IsOnScreen(
	point: Vector2,
	screenSize: Vector2,
	margin: number?
): boolean
	local m = margin or 0
	return point.X >= m
		and point.X <= screenSize.X - m
		and point.Y >= m
		and point.Y <= screenSize.Y - m
end

--[=[
	Returns the centre of the screen as a Vector2.

	@param screenSize -- Viewport size.
	@return Vector2
]=]
function PositionUtil.ScreenCentre(screenSize: Vector2): Vector2
	return Vector2.new(screenSize.X / 2, screenSize.Y / 2)
end

--[=[
	Linearly interpolates between two Vector2 values.

	@param a -- Start value.
	@param b -- End value.
	@param t -- Blend factor, typically 0–1.
	@return Vector2
]=]
function PositionUtil.LerpVector2(a: Vector2, b: Vector2, t: number): Vector2
	return a:Lerp(b, t)
end

return PositionUtil