function instanceOf(obj, type)
	return getmetatable(obj) == type.class
end

local function cell(size, x, y)
	local col = 1 + math.floor(x / size)
	local row = 1 + math.floor(y / size)
	return col, row
end

local function sortInto(g, size, obj)
	local c = obj.collider
	local x0, y0 = cell(size, c.x, c.y)
	local x1, y1 = cell(size, c.x + (c.vx or 0), c.y + (c.vy or 0))
	if x0 > x1 then x0, x1 = x1, x0 end
	if y0 > y1 then y0, y1 = y1, y0 end
	for x = x0,x1 do
		for y = y0,y1 do
			if not g[x] then g[x] = {} end
			if not g[x][y] then g[x][y] = {} end
			g[x][y][obj] = obj
		end
	end
end

local function add(self, obj, fixed)
	if fixed then
		sortInto(self.fixed, self.size, obj)
	elseif not self.objects[obj] then
		self.objects[obj] = obj
		obj.id = self.id
		self.id = self.id + 1
		local c = obj.collider
		if not (c.vx and c.vy) then
			c.vx, c.vy = 0, 0
		end
	end
end

local function remove(self, obj, fixed)
	if fixed then
		local x, y = cell(self.size, obj.collider.x, obj.collider.y)
		local objects = self.fixed[x][y]
		objects[obj] = nil
	else
		self.objects[obj] = nil
	end
end

local function clear(self)
	self.fixed, self.objects = {}, {}
	self.id = 0
end

local function sort(self)
	self.moveable = {}
	for _,o in pairs(self.objects) do
		sortInto(self.moveable, self.size, o)
	end
end

----------------------------------------------------------------
-- Time of collision (if any) between two moving circles.

local function solveQuadratic(a, b, c)
	-- Divide by a, then halve b to get: x^2 - 2bx + c.
	-- Complete the square to find the solutions:
	-- b +/- sqrt(b^2 - c)
	b, c = -b/(2*a), c/a

	-- If the discriminant is negative there are no real solutions.
	local d = b*b - c;  if d < 0 then return end
	-- For numerical stability, use the one with larger magnitude.
	local x0 = b + math.sqrt(d) * (b<0 and -1 or 1)
	-- Notice that x0*x1 = b^2 - (b^2 - c) = c, so x1 = c/x0.
	return x0, c/x0
end

local function collisionTime(c1, c2)
	local px, py = c2.x - c1.x, c2.y - c1.y
	local vx, vy = (c2.vx or 0) - c1.vx, (c2.vy or 0) - c1.vy
	local r = c1.r + c2.r

	-- Find the time when |p + t*v| = r, by squaring both
	-- sides and solving the resulting quadratic:
	-- t^2*|v|^2 + t*2*dot(v,p) + |p|^2 - r^2 = 0.
	local a = vx*vx + vy*vy
	local b = 2*(vx*px + vy*py)
	local c = (px*px + py*py) - r*r
	if c < 0 then return 0 end  -- already overlapping

	local t1, t2 = solveQuadratic(a, b, c)
	if t1 then
		if t1 >= 0 and t1 < t2 then return t1
		elseif t2 >= 0 then return t2 end
	end
	return false
end


----------------------------------------------------------------
-- Collision checking against grid cells.

local function collide_objects(a, b, out)
	if a == b then return end
	local t = collisionTime(a.collider, b.collider)
	if t and t <= 1 then
		table.insert(out, {a=a, b=b, t=t})
	end
end

local function collisions_within(set, out)
	for _,a in pairs(set) do
		for _,b in next,set,a do
			collide_objects(a, b, out)
		end
	end
	return out
end

local function collisions_between(set1, set2, out)
	for _,a in pairs(set1) do
		for _,b in pairs(set2) do
			collide_objects(a, b, out)
		end
	end
	return out
end

local function collide_cells(self, col, row, neighbors, objects, grid, out)
	for _,n in ipairs(neighbors) do
		local x, y = col + n[1], row + n[2]
		local objects2 = grid[x] and grid[x][y]
		if objects2 then
			if objects == objects2 then
				collisions_within(objects, out)
			else
				collisions_between(objects, objects2, out)
			end
		end
	end
	return out
end

local all = {
	{-1,-1}, {0,-1}, {1,-1},
	{-1,0},  {0,0},  {1,0},
	{-1,1},  {0,1},  {1,1}
}

local dr = {  -- down-right
	{0,0}, {1,0},
	{0,1}, {1,1}
}

local function collisions(self, out)
	out = out or {}
	sort(self)
	for x,col in pairs(self.moveable) do
		for y,objects in pairs(col) do
			collide_cells(self, x, y, all, objects, self.fixed, out)
			collide_cells(self, x, y, dr, objects, self.moveable, out)
		end
	end
	return out
end

-- Assumes all objects are already sorted.
local function pick(self, x, y, r)
	local pickers = {{collider = { x = x, y = y, r = r or 0, vx = 0, vy = 0 }}}
	local col, row = cell(self.size, x, y)
	local contacts = collide_cells(self, col, row, all, pickers, self.moveable, {})
	local out = {}
	for _,c in ipairs(contacts) do
		table.insert(out, c.a == pickers[1] and c.b or c.a)
	end
	return out
end


----------------------------------------------------------------

local methods = {
	add = add, remove = remove, clear = clear,
	sort = sort, collisions = collisions, pick = pick
}
local class = { __index = methods }

local function new(cellSize)
	return setmetatable({
		size = cellSize, id = 0,
		fixed = {}, moveable = {},
		objects = {}
	}, class)
end

return { new = new, methods = methods, class = class }
