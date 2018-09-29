
local function roundDownTo(x, r)
	local s = x < 0 and -1 or 1
	return s * math.floor(math.abs(x) / r) * r
end

-- One turn passes
local function update(self, g)
	local old_vx, old_vy = self.vx, self.vy
	self.vx, self.vy = self.vx + self.ax, self.vy + self.ay
	self.ax, self.ay = 0, 0

	local t, c = 1, self.collider
	if c then
		c.vx, c.vy = g:toPixel(self.vx, self.vy)
		if c.t then
			local bounce = true
			if self.collisionResponse then
				bounce = self:collisionResponse()
			end
			if bounce then
				t = c.tMin * 0.999
				e = c.e or 0.7  -- elasticity
				-- bounce velocity in pixel coordinates
				local ma, mb = c.m or 1, c.other.m or 1
				local nv = c.dx * c.nx + c.dy * c.ny
				local J = (1 + e) * nv
				if ma ~= 0 and mb ~= 0 then
					J = J * ma * mb / (ma + mb)
				end
				local vx = c.vx - J * c.nx
				local vy = c.vy - J * c.ny
				-- convert to hex and round to quarter units.
				vx, vy = g:fromPixel(vx, vy)
				vx = roundDownTo(vx, 0.25)
				vy = roundDownTo(vy, 0.25)
				self.vx, self.vy = vx, vy
				c.vx, c.vy = g:toPixel(vx, vy)
			end
			c.t, c.tMin = nil, nil
		end
	end

	self.hx = self.hx + roundDownTo(t*old_vx, 0.25)
	self.hy = self.hy + roundDownTo(t*old_vy, 0.25)
	if c then c.x, c.y = g:toPixel(self.hx, self.hy) end
end

local function collide(self, other, t)
	local a = self.collider
	if not a.t or t < a.t then
		a.tMin = math.min(t, a.tMin or 1)
		local b = other.collider
		local ax, ay = a.x + t * a.vx, a.y + t * a.vy
		local bx, by = b.x + t * (b.vx or 0), b.y + t * (b.vy or 0)
		local dx, dy = a.vx - (b.vx or 0), a.vy - (b.vy or 0)
		local nx, ny = ax - bx, ay - by
		local len = math.sqrt(nx*nx + ny*ny)
		-- Should never happen with continuous collision...
		if len < 0.0001 then
			nx, ny = -dx, -dy
			len = math.sqrt(nx*nx + ny*ny)
			if len < 0.0001 then
				len,  nx, ny = 1,  1, 0
			end
		end
		nx, ny = nx/len, ny/len
		local px, py = ax - a.r * nx, ay - a.r * ny
		if dx*nx + dy*ny < 0 then
			a.t = t
			a.other = other
			a.nx, a.ny = nx, ny
			a.px, a.py = px, py
			a.dx, a.dy = dx, dy
		end
	end
end

local function draw(self, G, ox, oy)
	local r, g, b, a = love.graphics.getColor()
	love.graphics.push()
	love.graphics.translate(G:toPixel(self.hx, self.hy))
	-- Characters start facing up, so we need to rotate them
	-- an extra 2 units to have direction 0 be down-right (the
	-- positive x-axis).
	local th = (self.dir+self.base_dir)%6 * math.pi/3

	local color
	if self.color then
		-- make a copy so we can modify alpha
		color = {unpack(self.color)}
	else
		color = {love.graphics.getColor()}
	end
	color[4] = 1
	love.graphics.setColor(color)
	love.graphics.print(self.ch, 0, 0, th, 1, 1, ox, oy)
	color[4] = 0.25
	love.graphics.setColor(color)
	local vx, vy = G:toPixel(self.vx, self.vy)
	love.graphics.print(self.ch, vx, vy, th, 1, 1, ox, oy)
	love.graphics.line(0, 0, vx, vy)

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
		dir = dir or 0, base_dir = 2,
		color = color
	}, class)
	return a
end

return { new = new, methods = methods, class = class }
