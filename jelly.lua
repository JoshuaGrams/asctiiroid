local parent = require 'actor'
local Bullet = require 'bullet'

local new

local function toOther(self, other)
	local vx, vy = other.hx - self.hx, other.hy - self.hy
	local px, py = grid:toPixel(vx, vy)
	len2 = px*px + py*py
	local dir
	if len2 > 0.001 then
		dir = math.atan2(py, px) / (math.pi/3)
		dir = math.floor(dir) % 6
	else
		dir = 0
	end
	return dir, math.sqrt(len2) / (2*grid.a)
end

local function update(self, G)
	self.turns = self.turns - 1
	if self.turns < 0 then
		self.turns = self.timeout
		local dir, dist = toOther(self, player)
		if dist < 8 then
			dir = (dir + math.random(-1,1)) % 6
			local dx, dy = unpack(grid.dirs[1+dir])
			local a = 0.25
			local vx, vy = grid:toPixel(self.vx + a*dx, self.vy + a*dy)
			local v = self.vMax * 2*grid.a
			if vx*vx + vy*vy <= v*v then
				self.ax, self.ay = self.ax + a*dx, self.ay + a*dy
			end
		end
	end
	parent.methods.update(self, G)
end

local function die(self)
	world:remove(self)
	if self.whole then
		local w = self.whole
		w.pieces = w.pieces - 1
		if w.pieces <= 0 then
			w.spawn[w.spawnIndex] = false
		end
	end
end

local function split(self, dir)
	self.pieces = 0
	local dirs = { (dir + 2) % 6, (dir - 2) % 6 }
	for _,d in ipairs(dirs) do
		local dx, dy = unpack(grid.dirs[1+d])
		local j = new(self.hx + 0.5*dx, self.hy + 0.5*dy, true, self.timeout, self.vMax)
		j.vx, j.vy = self.vx + 0.25*dx, self.vy + 0.25*dy
		j.whole = self
		self.pieces = self.pieces + 1
	end

	die(self)
end


local function collisionResponse(self)
	local other = self.collider.other
	if other then
		if instanceOf(other, Bullet) or other == player then
			if self.small then
				die(self)
			else
				local dir = toOther(self, other)
				split(self, dir)
			end
		end
	end
	return true
end


local methods = {
	update = update,
	collisionResponse = collisionResponse
}
local class = { __index = setmetatable(methods, parent.class) }

new = function(hx, hy, small, timeout, vMax)
	local dir = math.random(0, 5)
	local ch = small and 'o' or 'O'
	local self = parent.new(ch, hx, hy, dir, {0.43, 0.08, 0.35})
	self.tip = "Acid Jelly"
	self.small = small or false
	self.timeout = timeout or 5
	self.turns = math.random(1, self.timeout)
	self.vMax = vMax or 0.5

	local x, y = grid:toPixel(hx, hy)
	self.collider = { x=x, y=y, r=0.7*grid.a, e=0.5 }
	table.insert(newActors, self)
	return setmetatable(self, class)
end

return { new = new, methods = methods, class = class }
