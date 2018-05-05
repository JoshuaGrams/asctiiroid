local Colors = require 'colors'

local parent = require 'actor'

local upgradeTypes = {
	boost = { ch = '+', properties = {boost=10} },
	blast = { ch = '!', properties = {shot='single', bulletType='energy'} },
	reflect = { ch = 'z', properties = {shot='single', bulletType='bounce'} },
	multi = { ch = 'w', properties = {shot='multi'} },
	crystal = { ch = 'C', properties = {shield='crystal'} },
	bounce = { ch = 'B', properties = {shield='bounce'} },
	up = { ch = '<', properties = {depth=-1} },
	down = { ch = '>', properties = {depth=1} },
	food = { ch = '&', properties = {food=50} }
}

local methods = {}
local class = { __index = setmetatable(methods, parent.class) }

local function new(kind, hx, hy)
	local u = upgradeTypes[kind]
	local color = Colors.upgrade
	if kind == 'food' then
		color = Colors.food
	elseif kind == 'up' or kind == 'down' then
		color = Colors.stairs
	end
	local self = parent.new(u.ch, hx, hy, 4, color)
	self.properties = u.properties
	local x, y = grid:toPixel(hx, hy)
	self.collider = { x=x, y=y, r=grid.a }
	self.collide = false
	grid:set(hx, hy, self)
	world:add(self, true)
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
