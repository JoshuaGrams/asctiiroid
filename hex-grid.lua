-- Hex grid.  Uses flat topped hexes, so there are straight
-- vertical rows.


-- Fractions (a/b) for the square root of 3:
--
-- Hexes will be 2*a in the short direction (side to side)
-- and 4*b in the long direction (point to point).
--
-- Spacing is 2*a in the side-to-side direction
-- and 3*b in the point-to-point direction.
--
-- So hexes are 1.732 times (sqrt(3)) bigger in the
-- point-to-point direction, but are spaced 1.155 times
-- (2/sqrt(3)) farther apart in the side-to-side
-- direction.
--
local sizes = {
	{ 12, 7 },   -- err +0.01777   (1 pixel per 50 hexes)
	{ 19, 11 },  -- err +0.004778  (1 pixel per 200 hexes)
	{ 26, 15 },  -- err -0.001283  (1 pixel per 800 hexes)
	{ 45, 26 },  -- err +0.001282  (1 pixel per 800 hexes)
	{ 71, 41 }   -- err +0.0003435 (1 pixel per 2900 hexes)
}

-- Integer grid coordinates to pixel at hex center.
local function toPixel(g, x, y)
	return x*3*g.b, (x + 2*y)*g.a
end

local function fromPixel(g, px, py)
	local x = px/(3*g.b)
	local y = (py/g.a - x)/2
	return x, y
end

local function roundHex(g, x, y)
	local z = -x - y
	local rx, ry, rz = math.floor(x+.5), math.floor(y+.5), math.floor(z+.5)
	local dx, dy, dz = math.abs(rx-x), math.abs(ry-y), math.abs(rz-z)
	if dx > dy and dy > dz then
		rx = -ry - rz
	elseif dy > dz then
		ry = -rx - rz
	end
	return rx, ry
end

-- Translate from axial coordinates to rectangular
-- block of hexagons.
local function toRect(g, x, y)
	return x, y + math.floor(0.5 * x)
end

local function fromRect(g, rx, ry)
	return rx, ry - math.floor(0.5 * rx)
end

local function drawHex(g, x, y, filled)
	x, y = g:toPixel(x, y)
	local points = {}
	for p=1,#g.points,2 do
		points[p] = x + g.points[p]
		points[p+1] = y + g.points[p+1]
	end
	local mode = 'line'
	if filled then mode = 'fill' end
	love.graphics.polygon(mode, points)
end

local function triColor(g, px, py, pw, ph, colors)
	local x0, y0 = g:round(g:fromPixel(px - g.b, py))
	local w, h = math.ceil(pw/g.dx), math.ceil(0.5 + ph/g.dy)
	local p = g.points
	for ix=x0,x0+w do
		local ox = ix - (x0-1)
		local y0 = y0 - math.floor(0.5*ox)
		for iy=y0,y0+h do
			love.graphics.setColor(colors[1 + (ix-iy)%3])
			drawHex(g, ix, iy, true)
		end
	end
end


local function drawGrid(g, px, py, pw, ph)
	local x0, y0 = g:round(g:fromPixel(px - g.b, py))
	local w, h = math.ceil(pw/g.dx), math.ceil(0.5 + ph/g.dy)
	local p = g.points
	for ix=x0,x0+w do
		local ox = ix - (x0-1)
		local y0 = y0 - math.floor(0.5*ox)
		for iy=y0,y0+h do
			if g.fillExisting and g:get(ix, iy) then
				g:drawHex(ix, iy, true)
			else
				local x, y = g:toPixel(ix, iy)
				love.graphics.line(
					x+p[11], y+p[12],
					x+p[1], y+p[2],
					x+p[3], y+p[4],
					x+p[5], y+p[6])
			end
		end
	end
end

local function forCells(g, fn)
	for ix,col in pairs(g.cells) do
		for iy,cell in pairs(col) do
			fn(cell, ix, iy)
		end
	end
end

local function get(g, x, y)
	return g.cells[x] and g.cells[x][y]
end

local function set(g, x, y, value)
	if not g.cells[x] then g.cells[x] = {} end
	g.cells[x][y] = value
end

-- Clockwise from up-left.
local dirs = {
	{-1,0}, {0,-1}, {1,-1}, {1,0}, {0,1}, {-1,1}
}

local function neighbors(g, x, y)
	local out = {}
	for i,dir in ipairs(dirs) do
		out[i] = get(g, x+dir[1], y+dir[2])
	end
	return out
end

-- Find sequences of adjacent neighbors matching some criteria.
local function sequences(g, col, row, match)
	if type(match) ~= 'function' then
		local val = match
		match = function(x) return x == val end
	end
	local out, n = {}, g:neighbors(col, row)
	for i=1,6 do
		local seq = out[#out]
		if match(n[i]) then 
			if seq and seq.i+seq.n == i then
				seq.n = seq.n + 1
			else
				table.insert(out, { i=i, n=1 })
			end
		end
	end
	local first, last = out[1], out[#out]
	if first and first.i == 1 and last.i+last.n == 7 then
		first.i = last.i
		first.n = first.n + last.n
		table.remove(out)
	end
	return out
end

local function clear(g)
	g.cells = {}
end

local function floodFill(g, bg, val, x0, y0, x1, y1, x, y)
	x, y = x or x0, y or y0
	local ix, iy = g:fromRect(x, y)
	local c = g:get(ix, iy)
	if x<x0 or x>x1 or y<y0 or y>y1 or c ~= bg then
		return
	end

	g:set(ix, iy, val)
	for d,dir in ipairs(dirs) do
		local dx, dy = g:fromRect(dir[1], dir[2])
		floodFill(g, bg, val, x0, y0, x1, y1, x+dx, y+dy)
	end
end


local methods = {
	toPixel = toPixel,  fromPixel = fromPixel,
	round = roundHex,
	toRect = toRect,  fromRect = fromRect,
	drawHex = drawHex, draw = drawGrid,
	triColor = triColor,
	forCells = forCells, set = set, get = get,
	dirs = dirs, neighbors = neighbors,
	sequences = sequences,
	clear = clear, floodFill = floodFill
}
local class = { __index = methods }

local function new(a, b)
	if b == nil then a, b = unpack(sizes[a]) end
	return setmetatable({
		a = a, b = b,
		dx = 3*b, dy = 2*a,
		cells = {},
		points = {
			 2*b,0,  b,a,  -b,a,
			-2*b,0, -b,-a,  b,-a
		}
	}, class)
end

return {
	new = new, methods = methods, class = class,
	sizes = sizes
}
