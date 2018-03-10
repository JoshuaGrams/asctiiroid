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
	if self.turns <= 0 and math.sqrt(len2) < 30 * grid.a then
		self.turns = self.timeout
		Bullet.new(self, self.bulletType)
	end
end

local methods = { update = update }
local class = { __index = setmetatable(methods, parent.class) }

local function new(hx, hy, timeout, bulletType)
	local dir = math.random(0, 5)
	local self = parent.new('v', hx, hy, dir, {150, 30, 10})
	self.base_dir = 5
	self.timeout = timeout or 7
	self.turns = math.random(1, self.timeout)
	self.bulletType = bulletType or 'energy'
	self.ammo = 0  -- dummy variable: bullet sets this

	local x, y = grid:toPixel(hx, hy)
	local vx, vy = unpack(grid.dirs[1+dir])
	self.collider = { x=x, y=y, r=grid.a }
	self.collide = false
	grid:set(hx, hy, self)
	world:add(self)
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
