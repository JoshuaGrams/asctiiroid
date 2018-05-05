local noise = love.math.noise

local function update(s, dt, camera)
	if s.remaining < 0 then return end

	local k = s.remaining / s.duration
	local x = (noise(s.seed, s.remaining * s.freq) - 0.5) * 2
	local y = (noise(s.seed, s.remaining * s.freq) - 0.5) * 2
	local angle = (noise(s.seed, s.remaining * s.freq) - 0.5) * 2
	local d = s.magnitude * k
	x, y = x * d, y * d
	angle = angle * s.rotationMagnitude
	camera.cx, camera.cy = camera.cx + x, camera.cy + y
	camera.angle = camera.angle + angle

	s.remaining = s.remaining - dt
end

local class = { update = update }
class.__index = class

local function new(dist, rot, time, freq)
	return setmetatable({
		seed = math.random() * 1000,
		remaining = time, duration = time,
		freq = freq,
		magnitude = dist, rotationMagnitude = rot
	}, class)
end

return { new = new, class = class }
