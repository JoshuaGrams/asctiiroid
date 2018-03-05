local parent = require 'actor'

-- clockwise from straight up.
local directions = {
	{0,-1}, {1,-1}, {1,0}, {0,1}, {-1,1}, {-1,0}
}

local controls = {
	upleft     = { dir = 5 },
	up         = { dir = 0 },
	upright    = { dir = 1 },
	downright  = { dir = 2 },
	down       = { dir = 3 },
	downleft   = { dir = 4 },
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

local function update(self)
	if self.controls.accelerate then
		local dir = directions[1+self.dir]
		self.ax = self.ax + dir[1] * self.acceleration
		self.ay = self.ay + dir[2] * self.acceleration
		self.controls.accelerate = false
	end
	if self.controls.dir then
		self.dir = self.controls.dir
		self.controls.dir = false
	end
	parent.methods.update(self)
end

local methods = {
	keypressed = keypressed,
	update = update,
}
local class = { __index = setmetatable(methods, parent.class) }

local function new(char, hx, hy, dir, acceleration)
	local p = parent.new(char, hx, hy, dir)
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
