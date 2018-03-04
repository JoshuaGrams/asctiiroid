local G, F, ox, oy

local function hex(self)
	return G:round(self.hx, self.hy)
end

-- One turn passes
local function update(self, col, row)
	self.vx, self.vy = self.vx + self.ax, self.vy + self.ay
	self.hx, self.hy = self.hx + self.vx, self.hy + self.vy
end

local function draw(self)
	local r, g, b, a = love.graphics.getColor()

	if self.color then love.graphics.setColor(self.color) end
	local c, th = self.ch, self.dir * math.pi/3
	love.graphics.print(c, 0, 0, th, 1, 1, ox, oy)

	if self.indicator then
		love.graphics.setColor(128, 128, 255, 180)
		local ix, iy = G:round(self.hx, self.hy)
		local dx, dy = self.hx - ix, self.hy - iy
		local x0, y0 = G:toPixel(dx, dy)
		local x1, y1 = G:toPixel(dx + self.vx, dy + self.vy)
		local r0, r1 = G.a/5, G.a/9
		local ux, uy = x1 - x0, y1 - y0
		local d = math.sqrt(ux*ux + uy*uy)
		local th0, th1 = -math.pi/2, math.pi/2
		if d > 1 then
			ux, uy = ux/d, uy/d
			local vx, vy = -uy, ux
			th0, th1 = math.atan2(vy, vx), math.atan2(-vy, -vx)
			love.graphics.polygon('fill', {
				x0 - r0*vx, y0 - r0*vy,  -- back left
				x1 - r1*vx, y1 - r1*vy,  -- front left
				x1 + r1*vx, y1 + r1*vy,  -- front right
				x0 + r0*vx, y0 + r0*vy   -- back right
			})
		end
		love.graphics.arc('fill', 'closed', x0, y0, r0, th0, th0+math.pi)
		love.graphics.arc('fill', 'closed', x1, y1, r1, th1, th1+math.pi)
	end

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
	local ix, iy = G:round(hx, hy)
	G:set(ix, iy, a)
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
