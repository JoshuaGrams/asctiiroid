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

-- clockwise from x-axis (down-right).
local dirs = {
	{ 1,0, weight=3 },  -- don't turn
	{ 0,1, weight=1 },  -- turn right
	{ -1,1, weight=0 }, -- turn double right
	{ -1,0, weight=0 }, -- reverse direction
	{ 0,-1, weight=0 }, -- turn double left
	{ 1,-1, weight=1 }  -- turn left
}

-- A room consists of a list of the tiles which make up the
-- room.  A walker enters at (0, 0). Exits should be just
-- outside the room in the six directions above.
local rooms = {
	{
		-- one-cell
		{0,0},
		weight=2, exits = {
			{1,0}, {0,1}, {-1,1}, {-1,0}, {0,-1}, {1,-1}
		}
	},
	{
		-- four-cell
		{0,0}, {0,1}, {1,0}, {1,1},
		weight=5, exits = {
			{2,1}, {0,2}, {-1,2}, {-1,0}, {0,-1}, {2,-1}
		}
	},
	{
		-- seven-cell
		{0,0}, {0,1}, {1,-1}, {1,0}, {1,1}, {2,-1}, {2,0},
		weight = 3, exits = {
			{3,0}, {1,2}, {-1,2}, {-1,0}, {1,-2}, {3,-2}
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
