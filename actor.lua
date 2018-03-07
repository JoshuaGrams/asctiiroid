-- One turn passes
local function update(self, g)
	local old_vx, old_vy = self.vx, self.vy
	self.vx, self.vy = self.vx + self.ax, self.vy + self.ay
	self.ax, self.ay = 0, 0

	local t, c = 1, self.collider
	if c then
		c.vx, c.vy = g:toPixel(self.vx, self.vy)
		if c.t then
			local nv = c.vx * c.nx + c.vy * c.ny
			if nv < 0 then
				local bounce = true
				if self.collisionResponse then
					bounce = self:collisionResponse()
				end
				if bounce then
					t = c.t * 0.999
					-- bounce velocity in pixel coordinates
					local vx = c.vx - 2 * nv * c.nx
					local vy = c.vy - 2 * nv * c.ny
					-- convert to hex and round to quarter units.
					vx, vy = g:fromPixel(vx, vy)
					vx = math.floor(vx * 4) / 4
					vy = math.floor(vy * 4) / 4
					self.vx, self.vy = vx, vy
					c.vx, c.vy = g:toPixel(vx, vy)
				end
			end
			c.t, c.nx, c.ny, c.other = nil
		end
	end

	self.hx, self.hy = self.hx + t*old_vx, self.hy + t*old_vy
	if c then c.x, c.y = g:toPixel(self.hx, self.hy) end
end

local function collide(self, other, t)
	local c = self.collider
	if not c.t or t < c.t then
		c.t = t
		c.other = other
		local nx = self.collider.x - other.collider.x
		local ny = self.collider.y - other.collider.y
		local len = math.sqrt(nx*nx + ny*ny)
		if len < 0.0001 then
			nx, ny = 1, 0
		else
			nx, ny = nx/len, ny/len
		end
		c.nx, c.ny = nx, ny
	end
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

local methods = {
	collide = collide,
	update = update,
	draw = draw
}
local class = { __index = methods }

local function new(char, hx, hy, dir, color)
	local a = setmetatable({
		ch = char,
		hx = hx, hy = hy,
		vx = 0, vy = 0,
		ax = 0, ay = 0,
		dir = dir or 0,
		color = color
	}, class)
	return a
end

return { new = new, methods = methods, class = class }
