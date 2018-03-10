local parent = require 'actor'

local methods = {}
local class = { __index = setmetatable(methods, parent.class) }

local function new(char, hx, hy, properties)
	local self = parent.new(char, hx, hy, 4, {20, 120, 20})
	self.properties = properties
	local x, y = grid:toPixel(hx, hy)
	self.collider = { x=x, y=y, r=grid.a }
	self.collide = false
	grid:set(hx, hy, self)
	world:add(self, true)
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
