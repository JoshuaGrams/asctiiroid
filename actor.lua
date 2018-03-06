-- One turn passes
local function update(self, g)
	self.hx, self.hy = self.hx + self.vx, self.hy + self.vy
	self.vx, self.vy = self.vx + self.ax, self.vy + self.ay
	self.ax, self.ay = 0, 0
end

local function draw(self, G, ox, oy)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.push()
	love.graphics.translate(G:toPixel(self.hx, self.hy))
	-- Characters start facing up, so we need to rotate them
	-- an extra 2 units to have direction 0 be down-right (the
	-- positive x-axis).
	local th = (self.dir+2)%6 * math.pi/3

	local color
	if self.color then
		-- make a copy so we can modify alpha
		color = {unpack(self.color)}
	else
		color = {love.graphics.getColor()}
	end
	local d = math.sqrt(self.vx*self.vx + self.vy*self.vy)
	local n = math.ceil(2*d)  -- two shadows per hex-grid unit.
	for i=0,n-1 do
		color[4] = math.min(128, 48 + 64*i)
		love.graphics.setColor(color)
		local vx, vy = G:toPixel(self.vx, self.vy)
		local k = (n - i)/n
		love.graphics.print(self.ch, k*vx, k*vy, th, 1, 1, ox, oy)
	end
	color[4] = 255
	love.graphics.setColor(color)
	love.graphics.print(self.ch, 0, 0, th, 1, 1, ox, oy)

	love.graphics.pop()
	love.graphics.setColor(r, g, b, a)
end

local methods = { update = update, draw = draw }
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

return { new = new, methods = methods, class = class }
