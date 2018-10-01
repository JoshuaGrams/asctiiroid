local parent = require 'actor'
local Bullet = require 'bullet'
local Jelly = require 'jelly'
local Shake = require 'shake'
local Turret = require 'turret'
local Upgrade = require 'upgrade'

local controls = {
	upleft     = { dir = 3 },
	up         = { dir = 4 },
	upright    = { dir = 5 },
	downright  = { dir = 0 },
	down       = { dir = 1 },
	downleft   = { dir = 2 },
	wait       = {},
	use        = { use = true },
	fire       = { fire = true },
	accelerate = { accelerate = 1 },
	boost      = { accelerate = 3 },
}

local function input(self, name)
	local c = controls[name]
	if not c then return false end
	if c.dir then self.controls.dir = c.dir end
	if c.instant and type(c.instant) == 'function' then
		c.instant(self)
	end
	for k,v in pairs(c) do
		if k ~= 'dir' and k ~= 'instant' then
			self.controls[k] = v
		end
	end
	return not c.instant
end

local function fire(self, G)
	local dirs = G.dirs
	local angles = (self.shot == 'multi') and {0,-1,1} or {0}
	for _,angle in ipairs(angles) do
		if self.ammo > 0 then
			self.ammo = self.ammo - 1
			local b = Bullet.new(self, self.bulletType)
			local d = (self.dir + angle) % 6
			local ox = (dirs[1+d][1] + dirs[1+self.dir][1])/2
			local oy = (dirs[1+d][2] + dirs[1+self.dir][2])/2
			b.hx, b.hy = self.hx + 0.75*ox, self.hy + 0.75*oy
			b.vx, b.vy = b.vx + ox/4, b.vy + oy/4
			b.collider.x, b.collider.y = G:toPixel(b.hx, b.hy)
			if self.shot == 'multi' then
				-- short range
				b.turns = math.ceil(b.turns/2.5)
			end
			local c = b.collider
			c.vx, c.vy = G:toPixel(b.vx, b.vy)
		end
	end
end

local function update(self, G)
	if self.controls.accelerate then
		local a = self.controls.accelerate
		if a > 1 then
			if self.boost > 0 then
				self.boost = self.boost - 1
			else
				a = 1  -- no more boost fuel
			end
		end
		local a = a * self.acceleration
		local dir = G.dirs[1+self.dir]
		self.ax = self.ax + a * dir[1]
		self.ay = self.ay + a * dir[2]
		self.controls.accelerate = false
	end

	parent.methods.update(self, G)

	if self.controls.dir then
		self.dir = self.controls.dir
		self.controls.dir = false
	end

	if self.controls.fire then
		fire(self, G)
		self.controls.fire = false
	end

	self.controls.use = nil
end

local function die(self)
	self.controls = {}
	self.food = -1
	endGame()
end

local function collide(self, other, t)
	if instanceOf(other, Upgrade) then
		if self.controls.use and other ~= self.used then
			self.used = other
			for k,v in pairs(other.properties) do
				if k == 'depth' then
					local d = math.max(0, math.min(#levels, depth + v))
					if d ~= depth then
						if d == 0 then
							d = depth
							endGame()
						end
						self.hx, self.hy = other.hx, other.hy
						depth, level = d, levels[d]
						generateLevel()
						return
					end
				elseif k == 'food' then
					self.food = self.food + v
				else
					self[k] = v
				end
			end
			world:remove(other, true)
			grid:set(other.hx, other.hy, false)
			other.spawn[other.spawnIndex] = false
			other.spawn.n = other.spawn.n - 1
		end
	else
		parent.methods.collide(self, other, t)
	end
end

local function hitShake()
	shake = Shake.new(2.5, 0.005, 0.6, 13)
end

local function collisionResponse(self)
	local other = self.collider.other
	if other then
		local bullet = instanceOf(other, Bullet)
		local rock = instanceOf(other, Rock)
		local jelly = instanceOf(other, Jelly)
		local turret = instanceOf(other, Turret)
		if bullet or jelly or turret or rock then
			if rock and self.shield == 'bounce' then
				self.collider.e = 0.7
				hitShake()
				return true
			elseif self.shield == 'crystal' then
				self.shield = nil
				self.collider.e = 0.2
				hitShake()
				return true
			else
				die(self)
				self.collider.e = 0
				hitShake()
				return true
			end
		end
	end
	return true
end

local drawActor = parent.methods.draw
local function draw(self, G, ox, oy)
	drawActor(self, G, ox, oy)
	if self.shield then
		local color
		if self.shield == 'crystal' then
			color = {unpack(self.color)}
		elseif self.shield == 'bounce' then
			color = {0.48, 0.48, 0.32}
		end
		local oldColor = { love.graphics.getColor() }
		color[4] = 1
		love.graphics.setColor(color)

		local x, y = G:toPixel(self.hx, self.hy)
		love.graphics.circle('line', x, y, 0.9 * G.a)
		love.graphics.setColor(oldColor)
	end
end

local methods = {
	input = input,
	keypressed = keypressed,
	update = update,
	collide = collide,
	collisionResponse = collisionResponse,
	draw = draw
}
local class = { __index = setmetatable(methods, parent.class) }

local function new(char, hx, hy, dir, color, acceleration)
	help = true
	local p = parent.new(char, hx, hy, dir, color)
	p.acceleration = acceleration or 0.25
	p.ammo = 3
	p.controls = {}
	p.boost = 0
	p.food = 0
	p.bulletType = 'energy'
	p.scancodes = {
		u = {'upleft', 1},
		i = {'up', 1},
		o = {'upright', 1},
		j = {'downleft', 1},
		k = {'down', 1},
		l = {'downright', 1},
		w = {'use', 2},
		e = {'boost', 1},
		r = {'use', 1},
		s = {'fire', 2},
		d = {'accelerate', 1},
		f = {'fire', 1},
		space = {'wait', 1}
	}
	return setmetatable(p, class)
end

return { new = new, methods = methods, class = class }
