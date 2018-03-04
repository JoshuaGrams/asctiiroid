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
	player.indicator = true
end

function love.draw()
	camera:use()

	love.graphics.setColor(15, 15, 15)
	local b = camera.bounds
	grid:draw(b.xMin, b.yMin, b.xMax-b.xMin, b.yMax-b.yMin)

	love.graphics.setColor(130, 130, 80)
	grid:forCells(function(actor, col, row)
		local px, py = grid:toPixel(col, row)
		love.graphics.push()
		love.graphics.translate(px, py)
		actor:draw()
		love.graphics.pop()
	end)

	--[[
	love.graphics.setColor(128, 128, 255, 200)
	local x, y = grid:toPixel(2, 1)
	x, y = x + grid.a/2, y + grid.a/3
	love.graphics.circle('fill', x, y, grid.a/8)
	--]]
end

local function nextTurn()
	grid:forCells(function(actor, col, row)
		actor:update(col, row)
	end)
	local cells = {}
	grid:forCells(function(actor, col, row)
		col, row = actor:hex()
		if not cells[col] then cells[col] = {} end
		cells[col][row] = actor
	end)
	grid.cells = cells
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	else
		if player:keypressed(k, s) then nextTurn() end
	end
end
