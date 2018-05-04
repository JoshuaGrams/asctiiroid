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

local function separateThousands(n)
	local first, last = '', ''
	if n < 0 then n, first = -n, '-' end
	while n >= 1000 do
		last = string.format(",%03d", n % 1000) .. last
		n = math.floor(n / 1000)
	end
	return first .. tostring(n) .. last
end

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
		levels[depth+1].seed = math.floor(math.random() * 1e6)
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

local function newGame()
	depth = 1
	level = levels[depth]
	generateLevel(level, true)
end

function love.load(args)
	for _,arg in ipairs(args) do
		local n = tonumber(arg)
		if n then levels[1].seed = math.floor(n) end
	end
	state = 'menu'
	options = {
		'New Game',
		'Continue Game',
		'Restart',
		'Exit',
		selected = 2
	}
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

	newGame()
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

local function highlightOption(x, y, w, h)
	local oldColor = {love.graphics.getColor()}
	love.graphics.setColor(0.6, 0.6, 0.3)

	local triangle = { 0, 0, -19, -11, -19, 11 }

	love.graphics.push()
	love.graphics.translate(x - 5, y + 0.5 * h)
	love.graphics.polygon('fill', triangle)
	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(x + w + 5, y + 0.5 * h)
	love.graphics.rotate(math.pi)
	love.graphics.polygon('fill', triangle)
	love.graphics.pop()

	love.graphics.setColor(oldColor)
end

local function menuSelect()
	player.dead = nil
	local option = options[options.selected]
	if option == 'New Game' then
		levels[1].seed = nil
		newGame()
		state = 'play'
	elseif option == 'Continue Game' then
		state = 'play'
	elseif option == 'Restart' then
		newGame()
		state = 'play'
	elseif option == 'Exit' then
		love.event.quit()
	end
end

local function drawMenu(w, h)
	-- Fade game.
	if player.dead then
		love.graphics.setColor(0.3, 0, 0, 0.5)
		if options.selected == 2 then options.selected = 1 end
	else
		love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
	end
	love.graphics.rectangle('fill', 0, 0, w, h)

	love.graphics.setFont(font)
	love.graphics.setColor(0.5, 0.8, 0.35)
	local name = 'The Asctiiroid'
	local x = 0.5 * (w - font:getWidth(name))
	love.graphics.print(name, x, 50)

	local lineHeight = font:getHeight() * font:getLineHeight()
	local y = 0.5 * (h - #options * lineHeight)
	for i,option in ipairs(options) do
		if option == 'Restart' then
			option = option .. ' #' .. separateThousands(levels[1].seed)
		end
		local optionWidth = font:getWidth(option)
		local x = 0.5 * (w - optionWidth)
		if i == options.selected then
			highlightOption(x, y, optionWidth, lineHeight)
		end
		if player.dead and i == 2 then
			love.graphics.setColor(0.15, 0.15, 0.25)
		else
			love.graphics.setColor(0.3, 0.3, 0.5)
		end
		love.graphics.print(option, x, y)
		y = y + lineHeight
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

	if state == 'menu' then
		drawMenu(w, h)
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
	if player.deadWait then
		player.deadWait = player.deadWait - dt
		if player.deadWait <= 0 then
			player.deadWait = nil
		else
			return
		end
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
	if state == 'menu' and not player.deadWait then
		if k == 'down' or s == 'k' then
			options.selected = 1 + options.selected % #options
			if player.dead and options.selected == 2 then
				options.selected = 3
			end
		elseif k == 'up' or s == 'i' then
			options.selected = 1 + (options.selected - 2) % #options
			if player.dead and options.selected == 2 then
				options.selected = 1
			end
		elseif k == 'return' or k == 'space' then
			menuSelect()
		elseif k == 'escape' then
			love.event.quit()
		end
	elseif state == 'play' then
		if k == 'escape' then
			state = 'menu'
		elseif player:keypressed(k, s) then
			nextTurn()
		end
	end
end
