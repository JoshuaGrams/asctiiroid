local Upgrade = require 'upgrade'
local parent = require 'actor'
local class

local bulletType = {
	energy = {
		ch = '*',
		e = 0,  -- elasticity (don't bounce)
		v = 2,  -- velocity (hexes per turn)
		turns = 9,
		color = {0.31, 0.63, 0.43}
	},
	slow_energy = {
		ch = '*',
		e = 0, v = 1.25,
		turns = 15,
		color = {0.31, 0.63, 0.43}
	},
	bouncy = {
		ch = '*',
		e = 0.95, v = 1.75,
		turns = 30,
		color = {0.57, 0.57, 0.31}
	}
}

local function remove(self)
	if not self.removed then
		world:remove(self)
		self.owner.ammo = self.owner.ammo + 1
		self.removed = true
	end
end

local function update(self, G)
	self.turns = self.turns - 1
	if self.turns < 0 then
		remove(self)
	end
	parent.methods.update(self, G)
end

local function collide(self, other, t)
	if getmetatable(other) ~= class then
		parent.methods.collide(self, other, t)
	end
end

local function collisionResponse(self)
	if self.collider.e == 0 then
		if not instanceOf(self.collider.other, Upgrade) then
			remove(self)
		end
		return false
	else
		if self.bounces then
			self.bounces = self.bounces - 1
			if self.bounces < 0 then
				remove(self)
				return false
			end
		end
		return true
	end
end

local methods = {
	remove = remove,  update = update,
	collide = collide,
	collisionResponse = collisionResponse
}
class = { __index = setmetatable(methods, parent.class) }

local function new(ship, kind)
	local t = bulletType[kind]
	local dx, dy = unpack(grid.dirs[1+ship.dir])
	local hx, hy = ship.hx + dx, ship.hy + dy
	local b = parent.new(t.ch, hx, hy, ship.dir, t.color)

	b.tip = "Bullet"
	b.owner, b.turns = ship, t.turns
	b.vx, b.vy = ship.vx + t.v*dx, ship.vy + t.v*dy
	local px, py = grid:toPixel(b.hx, b.hy)
	local c = {
		x = px, y = py, r = 0.3*grid.a,
		e = t.e
	}
	c.vx, c.vy = grid:toPixel(b.vx, b.vy)
	b.collider = c
	table.insert(newActors, b)
	return setmetatable(b, class)
end

return {
	new = new, types = bulletType,
	methods = methods, class = class
}
