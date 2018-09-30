local Bullet = require 'bullet'

local function scancodeForControl(player, name)
	local ret = {}
	for s,nm in pairs(player.scancodes) do
		if nm[1] == name then
			ret[nm[2]] = s
		end
	end
	return ret
end

local function keyForControl(player, name)
	local scan = scancodeForControl(player, name)
	for i,s in ipairs(scan) do
		scan[i] = love.keyboard.getKeyFromScancode(s)
	end
	return scan
end

local dirNames = {
	'downright', 'down', 'downleft',
	'upleft', 'up', 'upright'
}

local function keyForDirection(player, dir)
	return keyForControl(player, dirNames[dir + 1])
end

local function printAligned(text, x, y, horiz, vert)
	local f = love.graphics.getFont()
	local h = f:getHeight() * f:getLineHeight()
	local w = f:getWidth(text)
	-- Default horizontal alignment is "left".
	if horiz == 'center' or horiz == 'middle' then x = x - w/2
	elseif horiz == 'right' then x = x - w end
	-- Default vertical alignment is "top".
	if vert == 'center' or vert == 'middle' then y = y - h/2
	elseif vert == 'bottom' then y = y - h end
	love.graphics.print(text, x, y)
end

local function showKeys(player, img)
	local alpha = type(help) == "number" and math.min(help, 1) or 1
	love.graphics.setColor(0.1, 0.1, 0.1, alpha * 0.6)
	love.graphics.rectangle('fill', 0, 0, w, h)
	local font = love.graphics.getFont()
	local iw, ih = img.key:getDimensions()
	local sc = (h / 18) / ih
	local lh = font:getHeight() * font:getLineHeight()
	local cw = font:getWidth('@')
	love.graphics.setColor(0.45, 0.45, 0.85, alpha)
	local x, y = camera:toWindow(grid:toPixel(player.hx, player.hy + 3))
	printAligned("Aim ship", x, y, 'center', 'bottom')
	x, y = camera:toWindow(grid:toPixel(player.hx + 2, player.hy - 7))
	printAligned("Mouse over objects to identify them.", x, y, 'center', 'center')
	printAligned("\"Shadows\" show where things will be next turn.", x, y + 1.5 * lh, 'center', 'center')
	for i,dir in ipairs(grid.dirs) do
		local key = keyForDirection(player, i - 1)[1]
		if not key then
			error("no control found for direction " .. i)
		end
		local hx, hy = player.hx + 1.5 * dir[1], player.hy + 1.5 * dir[2]
		local x, y = camera:toWindow(grid:toPixel(hx, hy))
		love.graphics.setColor(1, 1, 1, alpha)
		love.graphics.draw(img.key, x, y, 0, sc, sc, iw/2, ih/2)
		love.graphics.setColor(0, 0, 0, alpha)
		love.graphics.print(key, x, y, 0, 1, 1, cw/2, lh/2)
	end

	x, y = camera:toWindow(grid:toPixel(player.hx, player.hy))
	x = x - 11 * grid.a
	y = y - 0.5 * grid.a
	local pad = grid.a / 2.5
	local coords = {
		{
			{
				x - 2*(iw*sc + pad),  y - (ih*sc + pad)/2,
				key=keyForControl(player, 'boost')[1],
				tip = "Afterburner", tx = -1, ty = -1.5*grid.a
			},
			{
				x - 1*(iw*sc + pad),  y - (ih*sc + pad)/2,
				key=keyForControl(player, 'use')[2],
				tip = "Use item/exit", tx = 1, ty = -1.5*grid.a
			},
		}, {
			{
				x - 2*(iw*sc + pad),  y + (ih*sc + pad)/2,
				key=keyForControl(player, 'accelerate')[1],
				tip = "Accelerate", tx = -1, ty = 1.5*grid.a
			},
			{
				x - 1*(iw*sc + pad),  y + (ih*sc + pad)/2,
				key=keyForControl(player, 'fire')[2],
				tip = "Fire", tx = 1, ty = 1.5*grid.a
			}
		}
	}
	for _,row in ipairs(coords) do
		for _,item in ipairs(row) do
			love.graphics.setColor(1, 1, 1, alpha)
			local px, py = unpack(item)
			love.graphics.draw(img.key, px, py, 0, sc, sc, iw/2, ih/2)
			love.graphics.setColor(0, 0, 0, alpha)
			love.graphics.print(item.key, px, py, 0, 1, 1, cw/2, lh/2)
			px, py = px + item.tx, py + item.ty
			local hAlign = item.tx < 0 and 'right' or 'leftt'
			local vAlign = item.ty < 0 and 'bottom' or 'top'
			love.graphics.setColor(0.45, 0.45, 0.85, alpha)
			printAligned(item.tip, px, py, hAlign, vAlign)
		end
	end
end

local function showTip()
	love.graphics.setColor(0.1, 0.1, 0.1, 0.6)
	local pad = 3
	love.graphics.rectangle('fill', tip.x - pad, tip.y - pad, tip.w + 2*pad, tip.h + 2*pad)
	love.graphics.setColor(0.45, 0.45, 0.85)
	love.graphics.setFont(uiFont)
	love.graphics.print(tip.text, tip.x, tip.y)
end

local function drawUI(self, x, y, w)
	local old = love.graphics.getFont()
	local f = uiFont
	love.graphics.setFont(f)

	love.graphics.setColor(0, 0, 0, 0.59)
	love.graphics.rectangle('fill', x, y, w, 64)

	local x, y = x + 16, y + 16
	local spacing = 32

	local str = 'L' .. depth
	love.graphics.setColor(self.color)
	love.graphics.print(str, x, y)
	x = x + f:getWidth(str) + spacing

	local str = 'boost:'
	for i=1,5 do
		if i > math.ceil(0.5 * self.boost) then
			str = str .. '-'
		else
			str = str .. '#'
		end
	end
	love.graphics.setColor(self.color)
	love.graphics.print(str, x, y)
	x = x + f:getWidth(str) + spacing

	local b = Bullet.types[self.bulletType]
	local str = 'shots (' .. self.bulletType ..'): '
	for i=1,3 do str = str .. (i <= self.ammo and '*' or ' ') end
	love.graphics.setColor(b.color)
	love.graphics.print(str, x, y)
	x = x + f:getWidth(str) + spacing


	if self.shield then
		str = self.shield .. ' shield'
		love.graphics.setColor(self.color)
		love.graphics.print(str, x, y)
		x = x + f:getWidth(str) + spacing
	end

	str = 'food: ' .. tostring(self.food)
	love.graphics.print(str, x, y)
	x = f:getWidth(str) + spacing

	if help ~= true then
		local alpha = type(help) == "number" and math.min(help, 1) or 0
		local lh = f:getHeight() * f:getLineHeight()
		local q = '?'
		local qx, qy, qr = w - 2 * lh,  h - 2 * lh,  0.75 * lh
		local qw = f:getWidth(q)
		love.graphics.setColor(0.7, 0.7, 0.3, 0.45 * (1 - alpha))
		love.graphics.circle('fill', qx+qr, qy+qr, qr)
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(q, qx + (2*qr - qw)/2, qy + (2*qr - lh)/2)
	end
	if help then showKeys(self, img) end
	if tip then showTip() end

	love.graphics.setFont(old)
end

return drawUI
