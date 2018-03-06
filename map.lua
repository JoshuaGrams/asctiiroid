-- Random walk map generation.

----------------------------------------------------------------
-- Helper functions

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


----------------------------------------------------------------
-- Map methods

local function walker(w)
	return {
		x = w and w.x or 0,
		y = w and w.y or 0,
		dir = w and w.dir or 0
	}
end

local function clear(map)
	map.n = 0
	map.tiles = {}
	map.walkers = { walker() }
	return map
end

local function addTile(map, x, y)
	if not map.tiles[x] then map.tiles[x] = {} end
	if not map.tiles[x][y] then map.n = map.n + 1 end
	map.tiles[x][y] = true
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
		addTile(map, tx, ty)
	end

	exitRandomly(map, walker, room, xDir, yDir)
end

local function stepWalkers(map)
	if math.random() <= map.branch then
		local old = map.walkers[math.random(#map.walkers)]
		table.insert(map.walkers, walker(old))
	end

	for _,w in ipairs(map.walkers) do
		local r = randomWeighted(map.roomWeights)
		addRoom(map, map.rooms[r], w)
	end
end

local function generate(map, seed)
	math.randomseed(seed or generateSeedFromClock())
	clear(map)
	while map.n < map.limit do
		stepWalkers(map)
	end
end

local function forTiles(map, fn)
	for x,col in pairs(map.tiles) do
		for y,cell in pairs(col) do
			fn(x, y)
		end
	end
end


----------------------------------------------------------------
-- Constructor

local methods = {
	stepWalkers = stepWalkers,
	generate = generate,
	forTiles = forTiles
}
local class = { __index = methods }

local function new(tileCount, dirs, rooms, weights)
	return setmetatable(clear({
		absoluteDirections = false,
		limit = tileCount,
		dirs = dirs,
		rooms = rooms,
		dirWeights = normalizeWeights(weights.directions),
		roomWeights = normalizeWeights(weights.rooms),
		branch = weights.branch
	}), class)
end

return { new = new, methods = methods, class = class }
