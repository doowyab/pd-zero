import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

class("startscreen").extends()

function startscreen:update()
	return playdate.buttonJustPressed(playdate.kButtonA)
end

function startscreen:draw()
	gfx.clear()
	gfx.drawTextAligned("Placeholder Screen", 200, 90, kTextAlignment.center)
	gfx.drawRoundRect(120, 130, 160, 36, 8)
	gfx.drawTextAligned("Press A to Start", 200, 142, kTextAlignment.center)
end
