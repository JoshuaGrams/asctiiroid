local G, F, ox, oy

local function hex(self)
	return G:round(self.hx, self.hy)
end

-- One turn passes
local function update(self, col, row)
	self.hx, self.hy = self.hx + self.vx, self.hy + self.vy
	self.vx, self.vy = self.vx + self.ax, self.vy + self.ay
	self.ax, self.ay = 0, 0
end

local function draw(self)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.push()
	love.graphics.translate(G:toPixel(self.hx, self.hy))
	local th = self.dir * math.pi/3

	local color
	if self.color then
		-- make a copy so we can modify alpha
		color = {unpack(self.color)}
	else
		color = {love.graphics.getColor()}
	end
	if math.abs(self.vx) > 0.01 or math.abs(self.vy) > 0.01 then
		color[4] = 48
		love.graphics.setColor(color)
		local vx, vy = G:toPixel(self.vx, self.vy)
		love.graphics.print(self.ch, vx, vy, th, 1, 1, ox, oy)
	end
	color[4] = 255
	love.graphics.setColor(color)
	love.graphics.print(self.ch, 0, 0, th, 1, 1, ox, oy)

	love.graphics.pop()
	love.graphics.setColor(r, g, b, a)
end

local methods = { hex = hex, update = update, draw = draw }
local class = { __index = methods }

local function new(char, hx, hy, dir)
	local a = setmetatable({
		ch = char,
		hx = hx, hy = hy,
		vx = 0, vy = 0,
		ax = 0, ay = 0,
		dir = dir or 0
	}, class)
	return a
end

local function init(grid, font, xCharCenter, yCharCenter)
	G, F = grid, font
	ox, oy = xCharCenter, yCharCenter
end

return {
	new = new, init = init,
	methods = methods, class = class
}
