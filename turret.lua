local parent = require 'actor'
local Bullet = require 'bullet'

local function update(self)
	-- Aim at player
	local vx, vy = player.hx - self.hx, player.hy - self.hy
	vx, vy = grid:toPixel(vx, vy)
	len2 = vx*vx + vy*vy
	local dir
	if len2 > 0.001 then
		dir = math.atan2(vy, vx) / (math.pi/3)
		dir = math.floor(dir) % 6
	else
		dir = 0
	end
	self.dir = dir

	self.turns = self.turns - 1
	if self.turns <= 0 and math.sqrt(len2) < 22 * grid.a then
		self.turns = self.timeout
		Bullet.new(self, self.bulletType)
	end
end

local function collide(self, other, t)
	if instanceOf(other, Bullet) or other == player then
		world:remove(self)
		self.spawn[self.spawnIndex] = false
	end
end

local methods = { update = update, collide = collide }
local class = { __index = setmetatable(methods, parent.class) }

local function new(hx, hy, timeout, bulletType)
	local dir = math.random(0, 5)
	local self = parent.new('v', hx, hy, dir, {0.59, 0.12, 0.04})
	self.tip = "Turret"
	self.base_dir = 5
	self.timeout = timeout or 10
	self.turns = math.random(math.min(3, self.timeout), self.timeout)
	self.bulletType = bulletType or 'slow_energy'
	self.ammo = 0  -- dummy variable: our bullets need this

	local x, y = grid:toPixel(hx, hy)
	self.collider = { x=x, y=y, r=grid.a }
	table.insert(newActors, self)
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
