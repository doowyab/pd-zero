import "startscreen"
import "gamestate"

local STATE_START <const> = "start"
local STATE_GAME <const> = "game"

local startScreen = startscreen()
local gameScreen = gamestate()
local gameState = STATE_START

local function loadGame()
	playdate.display.setRefreshRate(50)
	math.randomseed(playdate.getSecondsSinceEpoch())
end

local function changeState(nextState)
	if nextState == STATE_GAME and gameState ~= STATE_GAME then
		gameScreen:enter()
	end

	gameState = nextState
end

local function updateStart()
	if startScreen:update() then
		changeState(STATE_GAME)
	end
end

local function updateInGame()
	local nextState = gameScreen:update()
	if nextState ~= gameState then
		changeState(nextState)
	end
end

loadGame()

function playdate.update()
	if gameState == STATE_START then
		updateStart()
		startScreen:draw()
	else
		updateInGame()
		gameScreen:draw()
	end
end
