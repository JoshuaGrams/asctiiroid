
local function bounds(self, aspect)
	local cx, cy = self.cx, self.cy
	local area, angle = self.area, self.angle
	local s2 = 0.5*math.sqrt(area)  -- half side length if viewport were square
	local as = math.sqrt(aspect)
	local w2, h2 = s2*as, s2/as
	local c, s = math.cos(angle), math.sin(angle)
	local wx, wy = c*w2, s*w2   -- rotated half-width vector
	local hx, hy = -s*h2, c*h2  -- rotated half-height vector
	local trx, try =  wx-hx,  wy-hy  -- top-right  (of original non-rotated rectangle)
	local brx, bry =  wx+hx,  wy+hy  -- bottom-right
	return {
		xMin = cx + math.min(trx, -trx, brx, -brx),
		xMax = cx + math.max(trx, -trx, brx, -brx),
		yMin = cy + math.min(try, -try, bry, -bry),
		yMax = cy + math.max(try, -try, bry, -bry),
	}
end

local function use(self)
	local w, h = love.graphics.getDimensions()
	local scale = math.sqrt(w*h / self.area)
	self.bounds = bounds(self, w/h)
	love.graphics.translate(w/2, h/2)
	love.graphics.rotate(self.angle)
	love.graphics.scale(scale)
	love.graphics.translate(-self.cx, -self.cy)
end

local function toWorld(self, xWindow, yWindow)
	local w, h = love.graphics.getDimensions()
	local scale = math.sqrt(self.area / (w*h))
	local cos, sin = math.cos(self.angle), math.sin(self.angle)
	local x, y = scale * (xWindow - w/2), scale * (yWindow - h/2)
	local xWorld = x*cos + y*sin + self.cx
	local yWorld = -x*sin + y*cos + self.cy
	return xWorld, yWorld
end

local function toWindow(self, xWorld, yWorld)
	local w, h = love.graphics.getDimensions()
	local scale = math.sqrt(self.area / (w*h))
	local cos, sin = math.cos(-self.angle), math.sin(-self.angle)
	local x, y = xWorld - self.cx, yWorld - self.cy
	x, y = x / scale, y / scale
	local xWindow = x*cos + y*sin + w/2
	local yWindow = -x*sin + y*cos + h/2
	return xWindow, yWindow
end

local methods = { use = use, toWorld = toWorld, toWindow = toWindow }
local class = { __index = methods }

local function new(cx, cy, area, angle)
	local w, h = love.graphics.getDimensions()
	local camera = {
		cx = cx or w/2,  cy = cy or h/2,
		area = area or w*h,
		angle = angle or 0
	}
	camera.bounds = bounds(camera, w/h)
	return setmetatable(camera, class)
end

return { new = new, methods = methods, class = class }
