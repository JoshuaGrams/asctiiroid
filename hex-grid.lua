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

-- Clockwise from x-axis (down-right).
local dirs = {
	{1,0}, {0,1}, {-1,1}, {-1,0}, {0,-1}, {1,-1}
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

local function forCellsIn(g, b, fn, ...)
	local pw, ph = b.xMax - b.xMin, b.yMax - b.yMin
	local x0, y0 = g:round(g:fromPixel(b.xMin - g.b, b.yMin))
	local w, h = math.ceil(pw/g.dx), math.ceil(0.5 + ph/g.dy)
	local p = g.points
	for ix=x0,x0+w do
		local ox = ix - (x0-1)
		local y0 = y0 - math.floor(0.5*ox)
		for iy=y0,y0+h do
			fn(g, ix, iy, ...)
		end
	end
end

local function drawGridHex(g, ix, iy)
	if g.fillExisting and g:get(ix, iy) then
		g:drawHex(ix, iy, true)
	else
		local x, y = g:toPixel(ix, iy)
		local p = g.points
		love.graphics.line(
		x+p[11], y+p[12],
		x+p[1], y+p[2],
		x+p[3], y+p[4],
		x+p[5], y+p[6])
	end
end

local function drawGrid(g, b)
	forCellsIn(g, b, drawGridHex)
end

local function forCells(g, fn)
	for ix,col in pairs(g.cells) do
		for iy,cell in pairs(col) do
			fn(g, cell, ix, iy)
		end
	end
end

local function get(g, x, y)
	return g.cells[x] and g.cells[x][y]
end

local function set(g, x, y, value)
	if not g.cells[x] then g.cells[x] = {} end
	if g.cells[x][y] == nil then g.n = g.n + 1 end
	g.cells[x][y] = value
end

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
	g.n = 0
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

----------------------------------------------------------------
-- Random-walk map generation

local function generateSeedFromClock()
	local seed = os.time() + math.floor(1000*os.clock())
	seed = seed * seed % 1000000
	seed = seed * seed % 1000000
	return seed
end

local function normalizeWeights(items)
	local totalWeight = 0
	for item,weight in pairs(items) do
		totalWeight = totalWeight + weight
	end

	local out = {}
	for item,weight in pairs(items) do
		out[item] = weight / totalWeight
	end
	return out
end

local function randomWeighted(items)
	local w, r = 0, math.random()
	for item,weight in pairs(items) do
		w = w + weight
		if r <= w then return item end
	end
	error('Weights should sum to 1.')
end

local function exitRandomly(map, walker, room, xDir, yDir)
	local dir = randomWeighted(map.dirWeights) - 1
	local exit = room.exits[dir+1]
	local ex = exit[1]*xDir[1] + exit[2]*yDir[1]
	local ey = exit[1]*xDir[2] + exit[2]*yDir[2]
	walker.x = walker.x + ex
	walker.y = walker.y + ey
	if map.absoluteDirections then
		walker.dir = dir
	else
		walker.dir = (walker.dir + dir) % #map.dirs
	end
end

local function addRoom(map, room, walker)
	-- Add floor tiles
	local x0, y0, d = walker.x, walker.y, walker.dir+1
	local xDir = map.dirs[d]
	local yDir = map.dirs[1 + (d % #map.dirs)]
	for _,tile in ipairs(room) do
		local tx = x0 + tile[1]*xDir[1] + tile[2]*yDir[1]
		local ty = y0 + tile[1]*xDir[2] + tile[2]*yDir[2]
		set(map, tx, ty, false)
	end

	exitRandomly(map, walker, room, xDir, yDir)
end

local function walker(w)
	return {
		x = w and w.x or 0,
		y = w and w.y or 0,
		dir = w and w.dir or 0
	}
end

local function stepWalkers(map)
	if math.random() <= map.branchWeight then
		local old = map.walkers[math.random(#map.walkers)]
		table.insert(map.walkers, walker(old))
	end

	for _,w in ipairs(map.walkers) do
		local r = randomWeighted(map.roomWeights)
		addRoom(map, map.rooms[r], w)
	end
end

local function initMap(g, tileCount, rooms, weights, seed)
	clear(g)
	g.walkers = { walker() }
	g.absoluteDirections = false
	g.limit = tileCount
	g.rooms = rooms
	g.dirWeights = normalizeWeights(weights.directions)
	g.roomWeights = normalizeWeights(weights.rooms)
	g.branchWeight = weights.branch
	math.randomseed(seed or generateSeedFromClock())
end

local function generate(map, tileCount, rooms, weights, seed)
	initMap(map, tileCount, rooms, weights, seed)
	while map.n < map.limit do
		stepWalkers(map)
	end
end


----------------------------------------------------------------

local methods = {
	toPixel = toPixel,  fromPixel = fromPixel,
	round = roundHex,
	toRect = toRect,  fromRect = fromRect,
	drawHex = drawHex, draw = drawGrid,
	forCellsIn = forCellsIn,
	forCells = forCells, set = set, get = get,
	dirs = dirs, neighbors = neighbors,
	sequences = sequences,
	clear = clear, floodFill = floodFill,
	generate = generate
}
local class = { __index = methods }

local function new(a, b)
	if b == nil then a, b = unpack(sizes[a]) end
	return setmetatable({
		a = a, b = b,
		dx = 3*b, dy = 2*a,
		cells = {}, n = 0,
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
