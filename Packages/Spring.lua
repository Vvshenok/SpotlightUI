--!strict
--[[
	Spring
	A critically-damped spring integrator for smooth, physics-feel UI movement.

	Each Spring tracks a single scalar value (position) and its velocity,
	accelerating toward a target each frame. With the default parameters the
	spring is critically damped — it reaches the target as fast as possible
	without overshooting, which is ideal for UI animation.

	Stiffness controls how aggressively the spring accelerates toward the
	target; higher values feel snappier. Damping controls how quickly
	oscillation decays; at exactly 2 * sqrt(stiffness) the spring is
	critically damped. The defaults (220 / 30) are tuned for snappy UI.

	Usage:
		local Spring = require(path.to.Spring)

		local s = Spring.new(0)

		RunService.Heartbeat:Connect(function(dt)
			local pos = s:Update(dt, targetValue)
			frame.Position = UDim2.fromOffset(pos, 0)
		end)

	Spring3 bundles:
		For position + size tracking, use Spring.newBundle which returns a
		{ X, Y, Size } table of three independent springs sharing the same
		stiffness / damping.

		local bundle = Spring.newBundle(startX, startY, startSize)
		bundle.X:Update(dt, targetX)
		bundle.Y:Update(dt, targetY)
		bundle.Size:Update(dt, targetSize)
--]]

-- ─── Types ────────────────────────────────────────────────────────────────────

export type Spring = {
	position: number,
	velocity: number,
	stiffness: number,
	damping: number,
	Update: (self: Spring, dt: number, target: number) -> number,
	Snap: (self: Spring, position: number) -> (),
	IsSettled: (self: Spring, epsilon: number?) -> boolean,
}

export type Spring3 = {
	X: Spring,
	Y: Spring,
	Size: Spring,
}

-- ─── Constants ────────────────────────────────────────────────────────────────

local DefaultStiffness = 220
local DefaultDamping = 30
local DefaultSettledEpsilon = 0.05

-- ─── Implementation ───────────────────────────────────────────────────────────

-- Internal type used by the class methods so self fields are known under --!strict.
-- The public Spring export type is what callers see.
type SpringImpl = {
	position: number,
	velocity: number,
	stiffness: number,
	damping: number,
}

local SpringClass = {}
SpringClass.__index = SpringClass

--[=[
	Creates a new Spring.

	@param initial   -- Starting position value.
	@param stiffness -- Spring stiffness. Higher = snappier. Default: 220.
	@param damping   -- Damping coefficient. Default: 30 (critically damped).
	@return Spring
]=]
function SpringClass.new(initial: number, stiffness: number?, damping: number?): Spring
	local self: SpringImpl = {
		position = initial,
		velocity = 0,
		stiffness = stiffness or DefaultStiffness,
		damping = damping or DefaultDamping,
	}
	return setmetatable(self, SpringClass) :: any
end

--[=[
	Integrates the spring one step forward using semi-implicit Euler integration.
	Call every Heartbeat with the elapsed delta time and the current target value.

	@param dt     -- Delta time in seconds.
	@param target -- The value the spring is moving toward.
	@return number -- The new spring position.
]=]
function SpringClass:Update(dt: number, target: number): number
	local self = self :: SpringImpl
	local displacement = self.position - target
	local acceleration = -self.stiffness * displacement - self.damping * self.velocity
	self.velocity += acceleration * dt
	self.position += self.velocity * dt
	return self.position
end

--[=[
	Instantly teleports the spring to `position` with zero velocity.
	Use for first-frame placement or hard cuts between targets.

	@param position -- The position to snap to.
]=]
function SpringClass:Snap(position: number)
	local self = self :: SpringImpl
	self.position = position
	self.velocity = 0
end

--[=[
	Returns true if the spring has effectively settled at its last target.
	Useful for skipping layout work when nothing is moving.

	@param epsilon -- Settlement threshold. Default: 0.05.
	@return boolean
]=]
function SpringClass:IsSettled(epsilon: number?): boolean
	local self = self :: SpringImpl
	local e = epsilon or DefaultSettledEpsilon
	return math.abs(self.velocity) < e
end

-- ─── Bundle ───────────────────────────────────────────────────────────────────

--[=[
	Creates a Spring3 bundle — three independent springs for X, Y, and Size —
	all sharing the same stiffness and damping parameters.

	@param x         -- Initial X position.
	@param y         -- Initial Y position.
	@param size      -- Initial size value.
	@param stiffness -- Optional stiffness override.
	@param damping   -- Optional damping override.
	@return Spring3
]=]
function SpringClass.newBundle(
	x: number,
	y: number,
	size: number,
	stiffness: number?,
	damping: number?
): Spring3
	return {
		X = SpringClass.new(x, stiffness, damping),
		Y = SpringClass.new(y, stiffness, damping),
		Size = SpringClass.new(size, stiffness, damping),
	}
end

-- ─── Static ───────────────────────────────────────────────────────────────────

export type StaticSpring = {
	new: (initial: number, stiffness: number?, damping: number?) -> Spring,
	newBundle: (x: number, y: number, size: number, stiffness: number?, damping: number?) -> Spring3,
}

return SpringClass :: StaticSpring