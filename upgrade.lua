local parent = require 'actor'

local upgradeTypes = {
	boost = { ch = '+', properties = {boost=10} },
	energy = { ch = '!', properties = {shot='single', bulletType='energy'} },
	bounce = { ch = 'z', properties = {shot='single', bulletType='bounce'} },
	crystal = { ch = 'C', properties = {shield='crystal'} },
	force = { ch = 'B', properties = {shield='bounce'} },
	multi = { ch = 'w', properties = {shot='multi'} }
}

local methods = {}
local class = { __index = setmetatable(methods, parent.class) }

local function new(kind, hx, hy)
	local u = upgradeTypes[kind]
	local self = parent.new(u.ch, hx, hy, 4, {20, 120, 20})
	self.properties = u.properties
	local x, y = grid:toPixel(hx, hy)
	self.collider = { x=x, y=y, r=grid.a }
	self.collide = false
	grid:set(hx, hy, self)
	world:add(self, true)
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
