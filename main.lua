local Camera = require 'camera'
local HexGrid = require 'hex-grid'
local Map = require 'map'
local Actor = require 'actor'
local Player = require 'player'

local function drawChar(g, ch, hx, hy, dir)
	local px, py = g:toPixel(hx, hy)
	dir = dir or 0
	love.graphics.print(ch, px, py, dir*math.pi/3, 1, 1, xc, yc)
end

local dirs = {
	{ 0,-1, weight=3 },
	{ 1,-1, weight=1 },
	{ 1,0, weight=1 },
	{ 0,1, weight=1 },
	{ -1,1, weight=1 },
	{ -1,0, weight=1 }
}

local rooms = {
	{
		{0,0}, weight=1, exits = {
			{0,-1}, {1,-1}, {1,0}, {0,1}, {-1,1}, {-1,0}
		}
	}
}

function love.load()
	camera = Camera.new(0, 0)

	font = love.graphics.newFont('RobotoMono-Regular.ttf', 24)
	love.graphics.setFont(font)
	xc = 0.5 * font:getWidth('@')
	yc = 0.55 * font:getHeight()

	grid = HexGrid.new(2)
	grid.drawChar = drawChar

	map = Map.new(150, 0.002, dirs, rooms)
	map:generate()

	Actor.init(grid, font, xc, yc)
	player = Player.new('A', 0, 0, 0)

	actors = { player }
end

function love.draw()
	camera:use()

	love.graphics.setColor(15, 15, 15)
	local b = camera.bounds
	local three = {
		{15, 15, 15}, {18, 15, 12}, {11, 11, 11}
	}
	grid:triColor(b.xMin, b.yMin, b.xMax-b.xMin, b.yMax-b.yMin, three)

	love.graphics.setColor(128, 0, 0, 128)
	map:forTiles(function(hx, hy)
		local px, py = grid:toPixel(hx, hy)
		love.graphics.circle('line', px, py, grid.a)
	end)

	love.graphics.setColor(130, 130, 80)
	for _,actor in ipairs(actors) do
		actor:draw()
	end
end

local function scaleBounds(b, s)
	local w, h = b.xMax - b.xMin, b.yMax - b.yMin
	local dx, dy = s*w/2, s*h/2
	return {
		xMin = b.xMin + dx,
		yMin = b.yMin + dy,
		xMax = b.xMax - dx,
		yMax = b.yMax - dy
	}
end

local function nextTurn()
	for _,actor in ipairs(actors) do
		actor:update(col, row)
	end

	local b = scaleBounds(camera.bounds, 0.6)
	local px, py = grid:toPixel(player.hx, player.hy)
	if px < b.xMin then
		camera.cx = camera.cx - (b.xMin - px)
	elseif px > b.xMax then
		camera.cx = camera.cx - (b.xMax - px)
	end
	if py < b.yMin then
		camera.cy = camera.cy - (b.yMin - py)
	elseif py > b.yMax then
		camera.cy = camera.cy - (b.yMax - py)
	end
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	else
		if player:keypressed(k, s) then nextTurn() end
	end
end
