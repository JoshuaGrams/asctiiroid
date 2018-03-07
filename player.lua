local parent = require 'actor'

local controls = {
	upleft     = { dir = 3 },
	up         = { dir = 4 },
	upright    = { dir = 5 },
	downright  = { dir = 0 },
	down       = { dir = 1 },
	downleft   = { dir = 2 },
	wait       = {},
	accelerate = { accelerate = true }
}

local function keypressed(self, k, s)
	local name = self.scancodes[s]
	if name then
		local c = controls[name]
		if c.dir then self.controls.dir = c.dir end
		if c.accelerate then self.controls.accelerate = true end
		return true
	end
	return false
end

local function update(self, G)
	if self.controls.accelerate then
		local dir = G.dirs[1+self.dir]
		self.ax = self.ax + dir[1] * self.acceleration
		self.ay = self.ay + dir[2] * self.acceleration
		self.controls.accelerate = false
	end
	if self.controls.dir then
		self.dir = self.controls.dir
		self.controls.dir = false
	end
	parent.methods.update(self, G)
end

local methods = {
	keypressed = keypressed,
	update = update,
}
local class = { __index = setmetatable(methods, parent.class) }

local function new(char, hx, hy, dir, color, acceleration)
	local p = parent.new(char, hx, hy, dir, color)
	p.acceleration = acceleration or 0.25
	p.controls = {}
	p.scancodes = {
		w = 'upleft',
		e = 'up',
		r = 'upright',
		s = 'downleft',
		d = 'down',
		f = 'downright',
		a = 'accelerate',
		z = 'wait'
	}
	return setmetatable(p, class)
end

return { new = new, methods = methods, class = class }
