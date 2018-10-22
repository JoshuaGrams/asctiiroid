local Bullet = require 'bullet'
local NinePatch = require 'nine-patch'
local stretchyKey = NinePatch.new('img/key.png', 10)

local function scancodesForControl(scancodes, name)
	local ret = {}
	for s,nm in pairs(scancodes) do
		if nm[1] == name then
			ret[nm[2]] = s
		end
	end
	return ret
end

local function keysForControl(scancodes, name)
	local scan = scancodesForControl(scancodes, name)
	for i,s in ipairs(scan) do
		scan[i] = love.keyboard.getKeyFromScancode(s)
	end
	return scan
end

local dirNames = {
	'downright', 'down', 'downleft',
	'upleft', 'up', 'upright'
}

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

local function showKey(char, img, x, y, sc, cw, ch, alpha, label, lx, ly)
	local iw, ih = img:getDimensions()
	love.graphics.setColor(1, 1, 1, alpha)
	love.graphics.draw(img, x, y, 0, sc, sc, iw/2, ih/2)
	if char then
		love.graphics.setColor(0, 0, 0, alpha)
		love.graphics.print(char, x, y, 0, 1, 1, cw/2, ch/2)
	end
	if label then
		x, y = x + lx, y + ly
		local hAlign = lx < 0 and 'right' or (lx == 0 and 'middle' or 'left')
		local vAlign = ly < 0 and 'bottom' or (ly == 0 and 'middle' or 'top')
		love.graphics.setColor(0.45, 0.45, 0.85, alpha)
		printAligned(label, x, y, hAlign, vAlign)
	end
end

local function showHelp(player)
	local alpha = type(help) == "number" and math.min(help, 1) or 1
	love.graphics.setColor(0.1, 0.1, 0.1, alpha * 0.6)
	love.graphics.rectangle('fill', 0, 0, w, h)
	local font = love.graphics.getFont()
	local lh = font:getHeight() * font:getLineHeight()
	love.graphics.setColor(0.45, 0.45, 0.85, alpha)
	local x, y = camera:toWindow(grid:toPixel(player.hx + 2, player.hy - 7))
	printAligned("Mouse over objects to identify them.", x, y, 'center', 'center')
	printAligned("\"Shadows\" show where things will be next turn.", x, y + 1.5 * lh, 'center', 'center')
end

local function showButtons(player, img)
	local alpha = type(help) == "number" and math.min(help, 1) or 1
	local font = love.graphics.getFont()
	local iw, ih = img:getDimensions()
	local sc = (h / 18) / ih
	local lh = font:getHeight() * font:getLineHeight()
	local cw = font:getWidth('@')
	local x, y = camera:toWindow(grid:toPixel(player.hx, player.hy))
	gamepadInput:draw(x, y, 4 * grid.a, 0.75 * grid.a, 0.2)
	x = x + 11 * grid.a
	y = y + 2.5 * grid.a
	local sp = 2 * grid.a
	showKey(false, img, x, y, sc, cw, lh, alpha, 'Use item/exit', 1, -1.5 * grid.a)
	showKey(false, img, x - sp, y + sp, sc, cw, lh, alpha, 'Accelerate', -2 * grid.a, 0)
	showKey(false, img, x + sp, y + sp, sc, cw, lh, alpha, 'Fire', 2 * grid.a, 0)
	showKey(false, img, x, y + 2 * sp, sc, cw, lh, alpha, 'Coast', 1, 1.5 * grid.a)
end

local function showKeys(player, img)
	local scancodes = player.scancodes
	local alpha = type(help) == "number" and math.min(help, 1) or 1
	local font = love.graphics.getFont()
	local iw, ih = img:getDimensions()
	local sc = (h / 18) / ih
	local lh = font:getHeight() * font:getLineHeight()
	local cw = font:getWidth('@')
	local x, y = camera:toWindow(grid:toPixel(player.hx, player.hy + 3))
	printAligned("Aim ship", x, y, 'center', 'bottom')
	for i,dir in ipairs(grid.dirs) do
		local hx, hy = player.hx + 1.5 * dir[1], player.hy + 1.5 * dir[2]
		local x, y = camera:toWindow(grid:toPixel(hx, hy))
		local key = keysForControl(scancodes, dirNames[i])[1]
		showKey(key, img, x, y, sc, cw, lh, alpha)
	end

	x, y = camera:toWindow(grid:toPixel(player.hx, player.hy))
	x = x - 11 * grid.a
	y = y - 0.5 * grid.a
	local pad = grid.a / 2.5
	local kw, kh = iw * sc + pad, ih * sc + pad
	local actions = {
		{{'boost', "Afterburner"}, {'use', "Use item/exit"}},
		{{'accelerate', "Accelerate"}, {'fire', "Fire"}}
	}
	for r,row in ipairs(actions) do
		for c,item in ipairs(row) do
			local ctrl, tip = unpack(item)
			local px, py = x + (c - 3) * kw, y + (r - 1.5) * kh
			local tx, ty = (c - 1.5) * 2, (r - 1.5) * 3 * grid.a
			local key = keysForControl(scancodes, ctrl)[1]
			showKey(key, img, px, py, sc, cw, lh, alpha, tip, tx, ty)
		end
	end
	love.graphics.setColor(1, 1, 1, alpha)
	local px, py = x - 2.5 * kw, y + 2.5 * kh
	stretchyKey:draw(px, py, 2 * kw * sc, ih * sc)
	love.graphics.setColor(0, 0, 0, alpha)
	love.graphics.print('space', px + 0.25 * kw, py + (ih * sc - lh) / 2)
	love.graphics.setColor(0.45, 0.45, 0.85, alpha)
	printAligned('Coast', px + kw, py + kh, 'top', 'left')
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
	if help then
		showHelp(self)
		if lastInputDevice == 'keyboard' then
			showKeys(self, img.key)
		elseif lastInputDevice == 'gamepad' then
			showButtons(self, img.button)
		end
	end
	if tip then showTip() end

	love.graphics.setFont(old)
end

return drawUI
