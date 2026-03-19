import "tile"
local firstTile = tile(0, 0)
local secondTile = tile(64, 0)

local gfx <const> = playdate.graphics

local function loadGame()
	playdate.display.setRefreshRate(50) -- Sets framerate to 50 fps
	math.randomseed(playdate.getSecondsSinceEpoch()) -- seed for math.random
end

local function updateGame()
	if playdate.buttonJustPressed(playdate.kButtonA) then
		firstTile:randomizeImage()
		secondTile:randomizeImage()
	end
end

local function drawGame()
	gfx.clear() -- Clears the screen
	firstTile:draw()
	secondTile:draw()
end

loadGame()

function playdate.update()
	updateGame()
	drawGame()
	playdate.drawFPS(0,0) -- FPS widget
end
