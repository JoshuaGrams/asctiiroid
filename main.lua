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

story = require 'story'


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
local rockColor = {0.27, 0.1, 0.06}
local function newRock(G, W, x, y, ch)
	local dir = math.random(0, 5)
	local ch = rockChars[math.random(#rockChars)]
	local rock = Actor.new(ch, x, y, dir, rockColor)
	setmetatable(rock, Rock.class)
	G:set(x, y, rock)
	actorCollision(G, W, rock, G.a, true)
	return rock
end

local yam = {
	{-2,-1}, {-2,0}, {-2,1},
	{-1,-2}, {-1,-1}, {-1,0}, {-1,1},
	{0,-3}, {0,-2}, {0,-1}, {0,0}, {0,1},
	{1,-3}, {1,-2}, {1,-1}, {1,0}, {1,1},
	{2,-3}, {2,-2}, {2,-1}, {2,0},
	{3,-3}, {3,-2}, {3,-1},
}

local function addYam(G, W)
	-- Find farthest cell from entrance.
	local dist2, cx, cy = 0
	G:forCells(function(g, cell, x, y)
		local dx = x - level.origin.x
		local dy = y - level.origin.y
		dx, dy = G:toPixel(dx, dy)
		local d2 = dx * dx + dy * dy
		if d2 > dist2 then
			dist2, cx, cy = d2, x, y
		end
	end)

	actors.yam = {}
	local cache = actors.yam

	for _,offset in ipairs(yam) do
		local tx, ty = cx + offset[1], cy + offset[2]
		local f = Upgrade.new('food', tx, ty)
		table.insert(cache, f)
		f.spawn, f.spawnIndex = cache, #cache
	end
	cache.n = #cache
end

local function createWalls(G, W)
	if depth == #levels then addYam(G, W) end

	local origin
	-- Get a single list of all floor tiles.
	local floorTiles = {}
	G:forCells(function(g, cell, x, y)
		local tile = {x, y}
		table.insert(floorTiles, tile)
		if x == level.origin.x and y == level.origin.y then
			origin = tile
			origin.index = #floorTiles
		end
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
	Upgrade.new('up', unpack(origin))
	table.remove(floorTiles, origin.index)

	-- Add items and enemies
	local destination
	for _,itemType in ipairs(level.contents) do
		if not actors[itemType] then actors[itemType] = {} end
		local cachedActors = actors[itemType]
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
		if not cachedActors.n then cachedActors.n = n end
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
			if cachedActors[i] == false then
				if instanceOf(item, Upgrade) then
					grid:set(item.hx, item.hy, false)
					world:remove(item, true)
				else
					table.remove(newActors)
				end
			else
				cachedActors[i] = item
				item.spawn = cachedActors
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

function endGame()
	timeout = 0.6
	state = 'ending'
	gameOver = true
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
		selected = 1
	}
	actors = {}

	camera = Camera.new(0, 0)

	font = love.graphics.newFont('RobotoMono-Regular.ttf', 36)
	uiFont = love.graphics.newFont('RobotoMono-Regular.ttf', 24)
	love.graphics.setFont(font)
	xc = 0.5 * font:getWidth('@')
	yc = 0.55 * font:getHeight()

	img = {
		key = love.graphics.newImage('img/key.png'),
	}

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
	gameOver = nil
	local option = options[options.selected]
	if option == 'New Game' then
		levels[1].seed = nil
		actors = {}
		newGame()
		state = 'intro'
	elseif option == 'Continue Game' then
		state = 'play'
	elseif option == 'Restart' then
		actors = {}
		newGame()
		state = 'intro'
	elseif option == 'Exit' then
		love.event.quit()
	end
end

local function drawMenu(w, h)
	-- Fade game.
	love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
	love.graphics.rectangle('fill', 0, 0, w, h)

	love.graphics.setFont(font)
	love.graphics.setColor(0.5, 0.8, 0.35)
	local name = 'The Yam of Endor'
	local x = 0.5 * (w - font:getWidth(name))
	love.graphics.print(name, x, 50)

	if gameOver and options.selected == 2 then
		options.selected = 1
	end
	local lineHeight = font:getHeight() * font:getLineHeight()
	local y = 0.5 * (h - #options * lineHeight)
	for i,option in ipairs(options) do
		if option == 'Restart' then
			option = option .. ' Asteroid ' .. separateThousands(levels[1].seed)
		end
		local optionWidth = font:getWidth(option)
		local x = 0.5 * (w - optionWidth)
		if i == options.selected then
			highlightOption(x, y, optionWidth, lineHeight)
		end
		if gameOver and i == 2 then
			love.graphics.setColor(0.15, 0.15, 0.25)
		else
			love.graphics.setColor(0.3, 0.3, 0.5)
		end
		love.graphics.print(option, x, y)
		y = y + lineHeight
	end
end

function drawText(template, values, bg)
	local oldFont = love.graphics.getFont()
	local w, h = love.graphics.getDimensions()
	if bg then
		love.graphics.setColor(bg)
		love.graphics.rectangle('fill', 0, 0, w, h)
	else
		love.graphics.setBackgroundColor({0.02, 0.02, 0.05})
	end
	love.graphics.setColor(0.65, 0.65, 0.25)
	local f = uiFont
	love.graphics.setFont(f)
	local lineHeight = f:getHeight() * f:getLineHeight()
	local y = 0.5 * (h - #template * lineHeight)
	local x = 0.5 * w
	local lines = {}
	for _,line in ipairs(template) do
		line = string.gsub(line, "%%(%a+)", values or {})
		table.insert(lines, line)
		x = math.min(x, 0.5 * (w - f:getWidth(line)))
	end

	for _,line in ipairs(lines) do
		love.graphics.print(line, x, y)
		y = y + lineHeight
	end

	love.graphics.setFont(oldFont)
end

local function colonistDeaths(food)
	local endings = story.endings
	local loFood, hiFood = endings[3].food, endings[4].food
	local loFoodDeaths, hiFoodDeaths = 300, 50
	local fraction = (food - loFood) / (hiFood - loFood)
	return math.ceil(loFoodDeaths + fraction * (hiFoodDeaths - loFoodDeaths))
end

local function extend(x, y, dx, dy, xMin, xMax, yMin, yMax)
	local lx = (xMax - x) / dx
	if lx < 0 then lx = (xMin - x) / dx end
	local ly = (yMax - y) / dy
	if ly < 0 then ly = (yMin - y) / dy end
	local l = math.min(lx, ly)
	return dx * l, dy * l
end

local function drawSightlines(actor, bounds)
	local lw, lwPrev = 2, love.graphics.getLineWidth()
	love.graphics.setLineWidth(lw)
	love.graphics.setColor(0.8, 0.8, 1.0, 0.08)
	local xMin, xMax = bounds.xMin - lw, bounds.xMax + lw
	local yMin, yMax = bounds.yMin - lw, bounds.yMax + lw
	local x0, y0 = grid:toPixel(actor.hx, actor.hy)
	for _,dir in ipairs(grid.dirs) do
		local dx, dy = grid:toPixel(dir[1], dir[2])
		local x, y = x0 + 3.5 * dx, y0 + 3.5 * dy
		dx, dy = extend(x, y, dx, dy, xMin, xMax, yMin, yMax)
		love.graphics.line(x, y, x + dx, y + dy)
	end
	love.graphics.setLineWidth(lwPrev)
end

function love.draw()
	if state == 'intro' then
		drawText(story.intro)
		return
	end

	camera:use()

	grid:forCellsIn(camera.bounds, triColorHex)
	drawSightlines(player, camera.bounds)

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
	elseif state == 'ending' then
		local ending, values
		for _,e in ipairs(story.endings) do
			if player.food < e.food then break end
			ending = e
			values = {
				food = player.food,
				n = colonistDeaths(player.food)
			}
		end
		drawText(ending, values, {0.02, 0.02, 0.05, 0.8})
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
	if timeout then
		timeout = timeout - dt
		if timeout <= 0 then timeout = nil end
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
	camera.angle = 0
	if shake then shake:update(dt, camera) end
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
	if state == 'intro' then
		state = 'play'
	elseif state == 'ending' and not timeout then
		state = 'menu'
	elseif state == 'menu' and not timeout then
		if k == 'down' or s == 'k' then
			options.selected = 1 + options.selected % #options
			if gameOver and options.selected == 2 then
				options.selected = 3
			end
		elseif k == 'up' or s == 'i' then
			options.selected = 1 + (options.selected - 2) % #options
			if gameOver and options.selected == 2 then
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
			options.selected = 2
		elseif player:keypressed(k, s) then
			nextTurn()
		elseif s == 'tab' then
			help = true
		end
	end
end

function love.keyreleased(k, s)
	if s == 'tab' then
		help = false
	end
end
