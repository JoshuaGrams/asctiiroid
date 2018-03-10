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
local rockColor = {90, 90, 65}
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
	local floorTiles = {}
	G:forCells(function(g, cell, x, y)
		table.insert(floorTiles, {x, y})
		if math.random() < 0.005 then
			Upgrade.new('multi', x, y)
		end
	end)
	for _,t in ipairs(floorTiles) do
		local x0, y0 = unpack(t)
		for i,dir in ipairs(G.dirs) do
			local x, y = x0 + dir[1], y0 + dir[2]
			if G:get(x, y) == nil then
				newRock(G, W, x, y)
			end
		end
	end
end

function generateLevel(level)
	if not level.seed then
		level.seed = generateSeedFromClock()
	end
	world:clear()
	grid:generate(level.tiles, rooms, level.chances, level.seed)
	createWalls(grid, world)

	player = Player.new('A', 0, 0, 4, {110, 160, 110})
	actorCollision(grid, world, player, 0.7*grid.a)
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
	generateLevel(level)
end

local function triColorHex(g, col, row)
	local rock = Actor.new('#', 0, 0, 0)
	rock.color = {45, 45, 30}
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

	love.graphics.setColor(15, 15, 15)
	grid:forCellsIn(camera.bounds, triColorHex)

	local actors = {}
	for _,actor in pairs(world.objects) do
		table.insert(actors, actor)
	end
	table.sort(actors, function(a, b)
		return a.id < b.id
	end)
	love.graphics.setColor(130, 130, 80)
	for _,actor in ipairs(actors) do
		actor:draw(grid, xc, yc)
	end

	-- Reset transform and draw UI
	love.graphics.origin()
	local w = love.graphics.getWidth()
	player:drawUI(0, 0, w)
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
	local b = scaleBounds(camera.bounds, 0.125)
	local px, py = grid:toPixel(player.hx, player.hy)
	local dx, dy = 0, 0  -- Camera motion to put player in bounds.
	if px < b.xMin then  dx = px - b.xMin
	elseif px > b.xMax then  dx = px - b.xMax  end
	if py < b.yMin then  dy = py - b.yMin
	elseif py > b.yMax then  dy = py - b.yMax  end

	if dx*dx + dy*dy > 1 then  -- More than 1 pixel out of bounds?
		local cf, ct = 0.95, 0.9  -- Converge to 95% in 0.9 seconds.
		local k = 1 - (1 - cf)^(dt/ct)
		dx, dy = k*dx, k*dy
	end
	camera.cx = camera.cx + dx
	camera.cy = camera.cy + dy
end

local function nextTurn()
	local collisions = world:collisions()
	for _,c in ipairs(collisions) do
		if c.a.collide then c.a:collide(c.b, c.t) end
		if c.b.collide then c.b:collide(c.a, c.t) end
	end

	for _,actor in pairs(world.objects) do
		actor:update(grid)
	end

	for i,actor in ipairs(newActors) do
		world:add(actor)
		newActors[i] = nil
	end
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	else
		if player:keypressed(k, s) then nextTurn() end
	end
end
