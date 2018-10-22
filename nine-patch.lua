local draw = love.graphics.draw
local quad = love.graphics.newQuad
local min = math.min

local function drawPieces(self, x, y, w, h)
	local m = self.margins
	local iw, ih = self.img:getDimensions()
	w, h = w or iw, h or ih
	love.graphics.push()
	love.graphics.translate(x, y)
	local xs0, ys0 = min(1, w/(m.l+m.r)), min(1, h/(m.t+m.b))
	love.graphics.scale(xs0, ys0)
	w, h = w / xs0, h / ys0
	local xs = (w - m.l - m.r) / self.size.x
	local ys = (h - m.t - m.b) / self.size.y
	-- Four corners
	draw(self.img, self.tl, 0, 0)
	draw(self.img, self.tr, w-m.r, 0)
	draw(self.img, self.bl, 0, h-m.b)
	draw(self.img, self.br, w-m.r, h-m.b)
	-- Four sides
	draw(self.img, self.l, 0, m.t,  0, 1, ys)
	draw(self.img, self.r, w-m.r, m.t,  0, 1, ys)
	draw(self.img, self.t, m.l, 0,  0, xs, 1)
	draw(self.img, self.b, m.l, h-m.b,  0, xs, 1)
	-- Center
	draw(self.img, self.c, m.l, m.t, 0, xs, ys)
	love.graphics.pop()
end

local methods = { draw = drawPieces }
local class = { __index = methods }

local function new(img, l, t, r, b)
	if type(img) == 'string' then
		img = love.graphics.newImage(img)
	end
	local w, h = img:getDimensions()
	t = t or l
	r = r or l
	b = b or t
	local self = {
		img = img,
		margins = { l = l, t = t, r = r, b = b },
		size = { x = w - r - l, y = h - t - b },
		-- Four corners
		tl = quad(0, 0,  l, t,  w, h),
		tr = quad(w-r, 0,  r, t,  w, h),
		bl = quad(0, h-b,  l, b,  w, h),
		br = quad(w-r, h-b,  r, b,  w, h),
		-- Four sides
		l = quad(0, t,  l, h-t-b,  w, h),
		r = quad(w-r, t,  r, h-t-b,  w, h),
		t = quad(l, 0,  w-r-l, t,  w, h),
		b = quad(l, h-b,  w-r-l, b,  w, h),
		-- Center
		c = quad(l, t,  w-r-l, h-t-b,  w, h)
	}
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
