-- Configure buttons as follows?
-- A = accelerate
-- X = fire
-- B = afterburner
-- Y = grab

local abs, sqrt = math.abs, math.sqrt
local cos, sin, atan2 = math.cos, math.sin, math.atan2
local PI, TURN = math.pi, 2 * math.pi
local floor = math.floor
local min, max = math.min, math.max

local function mergeAxes(a, b)
	return max(a, b, 0) + min(a, b, 0)
end

local function mergeSticks(ax, ay, bx, by)
	local x, y = mergeAxes(ax, bx), mergeAxes(ay, by)
	local d2 = x * x + y * y
	local s = d2 > 1 and 1 / sqrt(d2) or 1
	return x * s, y * s
end

local function axis(device, axis, dir)
	local x
	if type(axis) == 'number' then
		x = device:getAxis(axis)
	elseif type(axis) == 'string' then
		x = device:getGamepadAxis(axis)
	else
		error("Axis must be a number(joystick axis) or string (gamepad axis).")
	end
	return x * (dir or 1)
end

local function stick(device, xAxis, yAxis, xDir, yDir)
	local x = axis(device, xAxis, xDir)
	local y = axis(device, yAxis, yDir)
	local r2 = x * x + y * y
	local s = (r2 > 1) and 1 / sqrt(r2) or 1
	return x * s, y * s
end

local function button(device, button)
	local x
	if type(button) == 'number' then
		x = device:isDown(button)
	elseif type(button) == 'string' then
		x = device:isGamepadDown(button)
	else
		error("Button must be a number (joystick button) or string (gamepad button).")
	end
	return x
end

-- Convert to polar coordinates, apply threshold and square radius.
local function toPolar(x, y)
	local r = sqrt(x * x + y * y)
	local th = (r > 0) and atan2(y, x) or 0
	local r0 = 0.15
	r = (r - r0) / (1 - r0)
	r = r * r
	return r, th
end

local function toHex(r, th)
	local stick = (6 * th / TURN) % 6
	local left = floor(stick)
	-- Does the stick region cover the whole sector?
	local d = 0.2
	local isDown = left >= stick - r and left + 1 < stick + r
	local isUp = left < stick - d * r or left + 1 >= stick + d * r
	return left, r, isDown, isUp
end

local function addStick(self, device, xAxis, yAxis, xDir, yDir)
	table.insert(self.sticks, {
		device = device,
		xAxis = xAxis, yAxis = yAxis,
		xDir = xDir, yDir = yDir,
	})
end

local function removeStick(self, device, xAxis, yAxis)
	for n,i in ipairs(self.sticks) do
		if i.device == device and i.xAxis == xAxis and i.yAxis == yAxis then
			table.remove(self.sticks, n)
			return true
		end
	end
	return false
end

local function addButton(self, device, button, name)
	if not self.buttons[name] then
		self.buttons[name] = { down = false }
	end
	table.insert(self.buttons[name], {
		device = device, button = button
	})
end

local function removeButton(self, device, button, name)
	for n,b in ipairs(self.buttons[name] or {}) do
		if b.device == device and b.button == button then
			table.remove(self.buttons, n)
			return true
		end
	end
	return false
end

local function removeDevice(self, device)
	for i,s in ipairs(self.sticks) do
		if s.device == device then
			table.remove(self.sticks, i)
		end
	end

	for _,button in pairs(self.buttons) do
		for i,b in ipairs(button) do
			if b.device == device then
				table.remove(b, i)
			end
		end
	end
end

local function update(self, dt)
	local x, y = 0, 0
	for _,i in ipairs(self.sticks) do
		local x2, y2 = stick(i.device, i.xAxis, i.yAxis, i.xDir, i.yDir)
		x, y = mergeSticks(x, y, x2, y2)
	end
	local ct = 0.1  -- seconds of smoothing
	local k = 1 - (1 - 0.9)^(dt/ct)
	x = self.x + k * (x - self.x)
	y = self.y + k * (y - self.y)
	self.x, self.y = x, y
	local r, th = toPolar(x, y)
	local dir, len, isDown, isUp = toHex(self.rScale * r, th)
	self.angle, self.direction, self.length = th, dir, len

	if isDown then
		if not self.down then
			self.down = true
			self.pressed(self.aimControls[dir + 1])
		end
	elseif isUp then
		if self.down then
			self.down = false
			self.released(self.aimControls[dir + 1])
		end
	end

	for name,b in pairs(self.buttons) do
		local down = false
		for _,i in ipairs(b) do
			down = button(i.device, i.button) or down
		end
		if down ~= b.down then
			b.down = down
			if down then self.pressed(name) else self.released(name) end
		end
	end
end

local poly = {}
local nSegs = 30
for i=0,nSegs-1 do
	local dir = 6 * i / nSegs
	local ddir = abs(dir - math.floor(0.5 + dir))
	local len, th = max(ddir, 1 - ddir), dir * TURN / 6
	table.insert(poly, len * cos(th))
	table.insert(poly, len * sin(th))
end

local function draw(self, x, y, r, dr, alpha)
	alpha = alpha or 0.6
	local sector = TURN / 6
	local th = self.angle
	local dth = self.length * sector

	local lw = love.graphics.getLineWidth()
	local c = { love.graphics.getColor() }

	local ourCircle = {}
	for _,c in ipairs(poly) do
		table.insert(ourCircle, c * r/self.rScale)
	end

	love.graphics.push()
	love.graphics.translate(x, y)
	love.graphics.setLineWidth(dr)
	love.graphics.setColor(0.2, 0.2, 0.2, alpha)
	love.graphics.polygon('line', ourCircle)
	love.graphics.setColor(0.5, 0.5, 0.5, alpha)
	love.graphics.line(0, 0, r * self.length * cos(th), r * self.length * sin(th))
	love.graphics.setColor(c)
	love.graphics.setLineWidth(lw)
	love.graphics.pop()
end

local methods = {
	addStick = addStick,
	removeStick = removeStick,
	addButton = addButton,
	removeButton = removeButton,
	removeDevice = removeDevice,
	update = update,
	draw = draw
}
local class = { __index = methods }

local function new()
	return setmetatable({
		sticks = {},
		buttons = {},
		aimControls = {
			'downright', 'down', 'downleft',
			'upleft', 'up', 'upright'
		},
		x = 0, y = 0, rScale = 0.9,
		direction = 0, length = 0, down = false,
		pressed = function(self, name) end,
		released = function(self, name) end
	}, class)
end

return { new = new, class = class, methods = methods }
