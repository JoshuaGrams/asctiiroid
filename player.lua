local parent = require 'actor'
local Bullet = require 'bullet'
local Jelly = require 'jelly'
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

local function keypressed(self, k, s)
	local name = self.scancodes[s]
	if name then
		local c = controls[name]
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
	return false
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
				return true
			elseif self.shield == 'crystal' then
				self.shield = nil
				self.collider.e = 0.1
				return true
			else
				die(self)
				self.collider.e = 0
				return true
			end
		end
	end
	return true
end

local function drawUI(self, x, y, w)
	local old = love.graphics.getFont()
	local f = uiFont
	love.graphics.setFont(f)


	love.graphics.setColor(0, 0, 0, 0.59)
	love.graphics.rectangle('fill', x, y, w, 64)

	local x, y = x + 16, y + 16
	local spacing = 32

	local str = 'L' .. depth
	love.graphics.setColor(self.color)
	love.graphics.print(str, x, y)
	x = x + f:getWidth(str) + spacing

	local str = 'boost:'
	for i=1,5 do
		if i > math.ceil(0.5 * self.boost) then
			str = str .. '-'
		else
			str = str .. '#'
		end
	end
	love.graphics.setColor(self.color)
	love.graphics.print(str, x, y)
	x = x + f:getWidth(str) + spacing

	local b = Bullet.types[self.bulletType]
	local str = 'shots (' .. self.bulletType ..'): '
	for i=1,self.ammo do str = str .. '*' end
	love.graphics.setColor(b.color)
	love.graphics.print(str, x, y)
	x = x + f:getWidth(str) + spacing


	if self.shield then
		str = self.shield .. ' shield'
		love.graphics.setColor(self.color)
		love.graphics.print(str, x, y)
		x = x + f:getWidth(str) + spacing
	end

	str = 'food: ' .. tostring(self.food)
	love.graphics.print(str, x, y)
	x = f:getWidth(str) + spacing

	love.graphics.setFont(old)
end

local methods = {
	keypressed = keypressed,
	update = update,
	collide = collide,
	collisionResponse = collisionResponse,
	drawUI = drawUI
}
local class = { __index = setmetatable(methods, parent.class) }

local function new(char, hx, hy, dir, color, acceleration)
	local p = parent.new(char, hx, hy, dir, color)
	p.acceleration = acceleration or 0.25
	p.ammo = 3
	p.controls = {}
	p.boost = 0
	p.food = 0
	p.bulletType = 'energy'
	p.scancodes = {
		u = 'upleft',
		i = 'up',
		o = 'upright',
		j = 'downleft',
		k = 'down',
		l = 'downright',
		w = 'use',
		e = 'boost',
		r = 'use',
		s = 'fire',
		d = 'accelerate',
		f = 'fire',
		space = 'wait'
	}
	return setmetatable(p, class)
end

return { new = new, methods = methods, class = class }
