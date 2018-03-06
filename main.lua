local Camera = require 'camera'
local HexGrid = require 'hex-grid'
local Actor = require 'actor'
local Player = require 'player'
local rooms = require 'rooms'

local function drawChar(g, ch, hx, hy, dir)
	local px, py = g:toPixel(hx, hy)
	dir = dir or 0
	love.graphics.print(ch, px, py, dir*math.pi/3, 1, 1, xc, yc)
end

function love.load()
	camera = Camera.new(0, 0)

	font = love.graphics.newFont('RobotoMono-Regular.ttf', 32)
	love.graphics.setFont(font)
	xc = 0.5 * font:getWidth('@')
	yc = 0.55 * font:getHeight()

	grid = HexGrid.new(2)
	grid.drawChar = drawChar

	grid:generate(1200, rooms, {
		directions = { 8, 5, 4, 0, 3, 3 },
		rooms = { single = 0, four = 2, seven = 7, nineteen = 7 },
		branch = 0.002
	})
	local floorTiles = {}
	grid:forCells(function(g, cell, x, y)
		table.insert(floorTiles, {x, y})
	end)
	for _,t in ipairs(floorTiles) do
		local x0, y0 = unpack(t)
		for i,dir in ipairs(grid.dirs) do
			local x, y = x0 + dir[1], y0 + dir[2]
			if grid:get(x, y) == nil then
				local dir = math.random(0, 5)
				local rock = Actor.new('O', x, y, dir)
				rock.color = {90, 90, 65}
				grid:set(x, y, rock)
			end
		end
	end

	player = Player.new('A', 0, 0, 4)
	player.color = {150, 120, 150}

	actors = { player }
end

local threeColors = {
	{15, 15, 15}, {18, 15, 12}, {11, 11, 11}
}
local function triColorHex(g, col, row)
	local rock = Actor.new('#', 0, 0, 0)
	rock.color = {45, 45, 30}
	love.graphics.setColor(threeColors[1 + (col-row)%3])
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

	love.graphics.setColor(130, 130, 80)
	for _,actor in ipairs(actors) do
		actor:draw(grid, xc, yc)
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
	local b = scaleBounds(camera.bounds, 0.25)
	local px, py = grid:toPixel(player.hx, player.hy)
	local dx, dy = 0, 0
	if px < b.xMin then  dx = px - b.xMin
	elseif px > b.xMax then  dx = px - b.xMax  end
	if py < b.yMin then  dy = py - b.yMin
	elseif py > b.yMax then  dy = py - b.yMax  end

	local d = math.sqrt(dx*dx + dy*dy)
	if d > 0.5 then
		local ct = 0.9
		local k = 1 - (1 - 0.95)^(dt/ct)
		dx, dy = k*dx, k*dy
	end
	camera.cx = camera.cx + dx
	camera.cy = camera.cy + dy
end

local function nextTurn()
	for _,actor in ipairs(actors) do
		actor:update(grid)
	end
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	else
		if player:keypressed(k, s) then nextTurn() end
	end
end
