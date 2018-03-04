local Camera = require 'camera'
local HexGrid = require 'hex-grid'
local Actor = require 'actor'
local Player = require 'player'

local function drawChar(g, ch, hx, hy, dir)
	local px, py = g:toPixel(hx, hy)
	dir = dir or 0
	love.graphics.print(ch, px, py, dir*math.pi/3, 1, 1, xc, yc)
end

function love.load()
	camera = Camera.new(0, 0)

	font = love.graphics.newFont('RobotoMono-Regular.ttf', 24)
	love.graphics.setFont(font)
	xc = 0.5 * font:getWidth('@')
	yc = 0.55 * font:getHeight()

	grid = HexGrid.new(2)
	grid.drawChar = drawChar

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

	love.graphics.setColor(130, 130, 80)
	for _,actor in ipairs(actors) do
		actor:draw()
	end
end

local function nextTurn()
	for _,actor in ipairs(actors) do
		actor:update(col, row)
	end
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	else
		if player:keypressed(k, s) then nextTurn() end
	end
end
