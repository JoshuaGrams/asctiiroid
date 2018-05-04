local Camera = require 'camera'
local Collision = require 'collision'
local HexGrid = require 'hex-grid'
local Actor = require 'actor'
local Player = require 'player'
local Jelly = require 'jelly'
local Turret = require 'turret'
local Upgrade = require 'upgrade'
Rock = { class = { __index = setmetatable({}, Actor.class) }}  -- for collision identification.

rooms = require 'rooms'
levels = require 'levels'

local function drawChar(g, ch, hx, hy, dir)
	local px, py = g:toPixel(hx, hy)
	dir = dir or 0
	love.graphics.print(ch, px, py, dir*math.pi/3, 1, 1, xc, yc)
end

local function generateSeedFromClock()
	local seed = os.time() + math.floor(1000*os.clock())
	seed = seed * seed % 1000000
	seed = seed * seed % 1000000
	return seed
end

local function actorCollision(G, W, actor, radius, static)
	local x, y = G:toPixel(actor.hx, actor.hy)
	actor.collider = { x=x, y=y, r=radius }
	W:add(actor, static)
	if static then actor.collide = false end
end

local rockChars = { 'O', '0', 'Q' }
local rockColor = {0.35, 0.35, 0.25}
local function newRock(G, W, x, y, ch)
	local dir = math.random(0, 5)
	local ch = rockChars[math.random(#rockChars)]
	local rock = Actor.new(ch, x, y, dir, rockColor)
	setmetatable(rock, Rock.class)
	G:set(x, y, rock)
	actorCollision(G, W, rock, G.a, true)
	return rock
end

local function createWalls(G, W)
	local origin
	-- Get a single list of all floor tiles.
	local floorTiles = {}
	G:forCells(function(g, cell, x, y)
		if x == level.origin.x and y == level.origin.y then
			origin = #floorTiles + 1
		end

		table.insert(floorTiles, {x, y})
	end)

	-- Surround them with rocks.
	for _,t in ipairs(floorTiles) do
		local x0, y0 = unpack(t)
		for i,dir in ipairs(G.dirs) do
			local x, y = x0 + dir[1], y0 + dir[2]
			if G:get(x, y) == nil then
				newRock(G, W, x, y)
			end
		end
	end

	-- Add stairs up
	if depth > 1 then
		Upgrade.new('up', unpack(floorTiles[origin]))
	end
	origin = table.remove(floorTiles, origin)

	-- Add items and enemies
	local destination
	for _,itemType in ipairs(level.contents) do
		if not itemType.actors then itemType.actors = {} end
		local n = itemType.n
		if n then
			if n < 1 then
				n = (math.random() < n) and 1 or 0
			else
				n = math.floor(n)
			end
		else
			n = math.random(itemType.min, itemType.max)
		end
		if not itemType.actors.n then itemType.actors.n = n end
		for i=1,n do
			local item
			local t = math.random(#floorTiles)
			local tile = table.remove(floorTiles, t)
			local hx, hy = unpack(tile)
			if itemType[1] == 'upgrade' then
				item = Upgrade.new(itemType[2], unpack(tile))
				if itemType[2] == 'down' then
					destination = tile
				end
			elseif itemType[1] == 'turret' then
				item = Turret.new(hx, hy, unpack(itemType, 2))
			elseif itemType[1] == 'jelly' then
				item = Jelly.new(hx, hy, unpack(itemType, 2))
			end

			-- We have to do the random generation (to use the
			-- same random numbers in the same place every
			-- time) but we want to remove dead/used items.
			if itemType.actors[i] == false then
				if instanceOf(item, Upgrade) then
					grid:set(item.hx, item.hy, false)
					world:remove(item, true)
				else
					table.remove(newActors)
				end
			else
				itemType.actors[i] = item
				item.spawn = itemType.actors
				item.spawnIndex = i
			end
		end
	end

	return origin, destination
end

function generateLevel(newPlayer)
	level = levels[depth]
	if not level.seed then
		level.seed = generateSeedFromClock()
	end
	if newPlayer then
		for _,i in ipairs(level.contents) do
			i.actors = nil
		end
	end
	world:clear()
	grid:generate(level.origin, level.tiles, rooms, level.chances, level.seed)
	local origin, dest = createWalls(grid, world)
	if levels[depth+1] then
		levels[depth+1].seed = math.random() * 1000000
		levels[depth+1].origin = {x=dest[1], y=dest[2]}
	end

	if newPlayer then
		local x, y = unpack(origin)
		player = Player.new('A', x, y, 4, {0.43, 0.63, 0.43})
	else
		player.ammo = 3
		player.vx, player.vy = 0, 0
		player.controls = {}
	end
	actorCollision(grid, world, player, 0.7*grid.a)
	camera.cx, camera.cy = grid:toPixel(player.hx, player.hy)

	for i,actor in ipairs(newActors) do
		world:add(actor)
		newActors[i] = nil
	end
end

function love.load()
	camera = Camera.new(0, 0)

	font = love.graphics.newFont('RobotoMono-Regular.ttf', 36)
	uiFont = love.graphics.newFont('RobotoMono-Regular.ttf', 24)
	love.graphics.setFont(font)
	xc = 0.5 * font:getWidth('@')
	yc = 0.55 * font:getHeight()

	grid = HexGrid.new(2)
	grid.drawChar = drawChar

	world = Collision.new(3*grid.a)
	newActors = {}

	depth = 1
	level = levels[depth]
	generateLevel(level, true)
end

local function triColorHex(g, col, row)
	local rock = Actor.new('#', 0, 0, 0)
	rock.color = {0.18, 0.18, 0.12}
	local colors = level.background
	love.graphics.setColor(colors[1 + (col-row)%3])
	g:drawHex(col, row, true)
	local a = g:get(col, row)
	if type(a) == 'table' then a:draw(g, xc, yc)
	elseif a == nil then
		rock.hx, rock.hy = col, row
		rock:draw(g, xc, yc)
	end
end

function love.draw()
	camera:use()

	grid:forCellsIn(camera.bounds, triColorHex)

	local actors = {}
	for _,actor in pairs(world.objects) do
		table.insert(actors, actor)
	end
	table.sort(actors, function(a, b)
		return a.id < b.id
	end)
	love.graphics.setColor(0.51, 0.51, 0.31)
	for _,actor in ipairs(actors) do
		actor:draw(grid, xc, yc)
	end

	-- Reset transform and draw UI
	love.graphics.origin()
	local w, h = love.graphics.getDimensions()
	player:drawUI(0, 0, w)

	if player.dead then
		love.graphics.setColor(0.3, 0, 0, 0.5)
		love.graphics.rectangle('fill', 0, 0, w, h)
	end
end

local function scaleBounds(b, s)
	local w, h = b.xMax - b.xMin, b.yMax - b.yMin
	local dx, dy = (1-s)*w/2, (1-s)*h/2
	return {
		xMin = b.xMin + dx,
		yMin = b.yMin + dy,
		xMax = b.xMax - dx,
		yMax = b.yMax - dy
	}
end

function love.update(dt)
	if player.dead then
		player.dead = math.max(0, player.dead - dt)
		return
	end
	local px, py = grid:toPixel(player.hx, player.hy)
	local dx, dy = px - camera.cx, py - camera.cy

	if dx*dx + dy*dy > 1 then  -- More than 1 pixel out of bounds?
		local cf, ct = 0.95, 0.9  -- Converge to 95% in 0.9 seconds.
		local k = 1 - (1 - cf)^(dt/ct)
		dx, dy = k*dx, k*dy
	end
	camera.cx = camera.cx + dx
	camera.cy = camera.cy + dy
end

local function nextTurn()
	local oldDepth = depth
	newActors = {}

	local collisions = world:collisions()
	for _,c in ipairs(collisions) do
		if c.a.collide then c.a:collide(c.b, c.t) end
		if c.b.collide then c.b:collide(c.a, c.t) end
		if depth ~= oldDepth then return end
	end

	for _,actor in pairs(world.objects) do
		actor:update(grid)
		if depth ~= oldDepth then return end
	end

	for i,actor in ipairs(newActors) do
		world:add(actor)
		newActors[i] = nil
	end
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	elseif player.dead then
		if player.dead == 0 then
			player.dead = nil
			depth = 1
			level = levels[depth]
			generateLevel(level, true)
		end
	else
		if player:keypressed(k, s) then nextTurn() end
	end
end
