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

local function condition(old, dt, x, y)
	-- Apply threshold and square result.
	local r0, s = 0.15, 0
	local r = sqrt(x * x + y * y)
	if r > r0 then
		s = max(0, r - r0) / (1 - r0)
		s = s * s / r
	end
	x, y = x * s, y * s
	-- Smooth over time.
	local ct = 0.1  -- seconds of smoothing
	local k = 1 - (1 - 0.9)^(dt/ct)
	x = old.x + k * (x - old.x)
	y = old.y + k * (y - old.y)
	old.x, old.y = x, y
	return x, y
end

local function roundTo(x, unit)
	return floor(0.5 + x / unit) * unit
end

local function inCones(x, y, cx, cy, w, posDir, negDir)
	local rc2 = 1 / (cx * cx + cy * cy)  -- reciprocal of |c|^2
	local along = (x * cx + y * cy) * rc2
	if abs(along) < 1 then return false end
	local xCross, yCross = x - along * cx, y - along * cy
	local rr2 = 1 / (x * x + y * y)
	local across2 = (xCross * xCross + yCross * yCross) * rr2
	if across2 > w * w then return false end
	return along < 0 and negDir or posDir
end

local sector = TURN / 6
local hexAxes = {
	{ cos(0.5 * sector), sin(0.5 * sector), 1, 4 },
	{ cos(1.5 * sector), sin(1.5 * sector), 2, 5 },
	{ cos(2.5 * sector), sin(2.5 * sector), 3, 6 }
}

-- return direction or false (released) or nil (ambiguous).
local function toHex(x, y, r, w)
	local released = true
	for _,axis in ipairs(hexAxes) do
		local cx, cy, posDir, negDir = unpack(axis)
		local d = inCones(x, y, r * cx, r * cy, w, posDir, negDir)
		if d then return d, false end
		local r2, w2 = r * 0.8, w * 1.1
		d = inCones(x, y, r2 * cx, r2 * cy, w2, posDir, negDir)
		released = released and not d
	end
	return false, released
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
	x, y = condition(self, dt, x, y)
	local dir, released = toHex(x, y, self.rt, self.wt)
	self.length = sqrt(x * x + y * y)

	local inputSent = false

	if dir then
		if dir ~= self.direction then
			self.direction, inputSent = dir, true
			self.pressed(self.aimControls[dir])
		end
	elseif released then
		if self.direction then
			self.direction, inputSent = false, true
			self.released(self.aimControls[dir])
		end
	end

	for name,b in pairs(self.buttons) do
		local down = false
		for _,i in ipairs(b) do
			down = button(i.device, i.button) or down
		end
		if down ~= b.down then
			b.down, inputSent = down, true
			if down then self.pressed(name) else self.released(name) end
		end
	end

	if x*x + y*y > 0.01 and not inputSent then
		self.pressed('stick-moved')
	end
end

local function draw(self, x, y, r, dr, alpha)
	alpha = alpha or 0.6

	love.graphics.push()
	love.graphics.translate(x, y)
	local lw = love.graphics.getLineWidth()
	local c = { love.graphics.getColor() }

	love.graphics.setColor(0.5, 0.5, 0.5, alpha)
	love.graphics.polygon('fill', {
		self.x * r, self.y * r,
		(-self.x - self.y) * 0.2 * r, (-self.y + self.x) * 0.2 * r,
		0, 0,
		(-self.x + self.y) * 0.2 * r, (-self.y - self.x) * 0.2 * r,
	})

	love.graphics.setLineWidth(2)
	for i=0,5 do
		local rt = self.rt * r
		local wt = self.wt * rt
		local angle = (i + 0.5) * sector
		local ux, uy = cos(angle), sin(angle)
		local vx, vy = -uy * wt, ux * wt
		ux, uy = ux * rt, uy * rt
		love.graphics.line(ux - vx, uy - vy, ux + vx, uy + vy)
	end

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
		x = 0, y = 0,
		rt = 0.8, wt = sin(0.8 * sector/2),
		direction = 0, length = 0, down = false,
		pressed = function(self, name) end,
		released = function(self, name) end
	}, class)
end

return { new = new, class = class, methods = methods }
