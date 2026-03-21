import "CoreLibs/graphics"
import "CoreLibs/object"
import "tile"

local gfx <const> = playdate.graphics

class("gamestate").extends()

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240
local DICE_COUNT <const> = 4
local GRID_SIZE <const> = 7
local MODE_GRID <const> = "grid"
local MODE_SELECT <const> = "select"
local MODE_PLACE <const> = "place"
local GRID_LINE_WIDTH <const> = 1
local CELL_SIZE <const> = math.floor(SCREEN_WIDTH / (GRID_SIZE + 1))
local EDGE_GAP <const> = math.floor(CELL_SIZE * 0.5)
local GRID_PIXEL_SIZE <const> = CELL_SIZE * GRID_SIZE
local GRID_X <const> = math.floor((SCREEN_WIDTH - GRID_PIXEL_SIZE) / 2)
local GRID_WORLD_Y <const> = EDGE_GAP
local GRID_BOTTOM_MARGIN <const> = EDGE_GAP
local CAMERA_PADDING <const> = 18
local BONUS_START_INDEX <const> = 3
local BONUS_SIZE <const> = 3
local BONUS_BORDER_THICKNESS <const> = 3
local PICKER_HEIGHT <const> = 78
local PICKER_PADDING <const> = 12
local PICKER_DIE_SIZE <const> = 44
local PLACED_DIE_SIZE <const> = CELL_SIZE - 10
local PREVIEW_DIE_SIZE <const> = CELL_SIZE - 8
local CRANK_DEADZONE <const> = 0.1

function gamestate:init()
	self.dice = {}
	self.board = {}
	self.cursorRow = 1
	self.cursorColumn = 1
	self.mode = MODE_GRID
	self.selectedDieIndex = nil
	self.previewSelectionIndex = 1
	self.cameraY = 0

	for row = 1, GRID_SIZE do
		self.board[row] = {}
		for column = 1, GRID_SIZE do
			self.board[row][column] = nil
		end
	end

	for index = 1, DICE_COUNT do
		self.dice[index] = tile(index)
	end
end

function gamestate:resetBoard()
	for row = 1, GRID_SIZE do
		for column = 1, GRID_SIZE do
			self.board[row][column] = nil
		end
	end
end

function gamestate:rollDice()
	for _, die in ipairs(self.dice) do
		die.isPlaced = false
		die:randomizeImage()
	end
end

function gamestate:getGridHeight()
	return GRID_PIXEL_SIZE
end

function gamestate:getMaxCameraY()
	local fullHeight = GRID_WORLD_Y + self:getGridHeight() + GRID_BOTTOM_MARGIN
	return math.max(0, fullHeight - SCREEN_HEIGHT)
end

function gamestate:updateCamera()
	local cellTop = GRID_WORLD_Y + ((self.cursorRow - 1) * CELL_SIZE)
	local cellBottom = cellTop + CELL_SIZE
	local visibleTop = self.cameraY + CAMERA_PADDING
	local visibleBottom = self.cameraY + SCREEN_HEIGHT - CAMERA_PADDING

	if cellTop < visibleTop then
		self.cameraY = cellTop - CAMERA_PADDING
	elseif cellBottom > visibleBottom then
		self.cameraY = cellBottom - SCREEN_HEIGHT + CAMERA_PADDING
	end

	if self.cameraY < 0 then
		self.cameraY = 0
	end

	local maxCameraY = self:getMaxCameraY()
	if self.cameraY > maxCameraY then
		self.cameraY = maxCameraY
	end
end

function gamestate:enter()
	self:resetBoard()
	self:rollDice()
	self.cursorRow = 1
	self.cursorColumn = 1
	self.mode = MODE_SELECT
	self.selectedDieIndex = nil
	self.previewSelectionIndex = 1
	self.cameraY = 0
	self:updateCamera()
	self:openDieSelection()
end

function gamestate:getAvailableDiceIndices()
	local available = {}

	for index, die in ipairs(self.dice) do
		if not die.isPlaced then
			table.insert(available, index)
		end
	end

	return available
end

function gamestate:hasAvailableDice()
	return #self:getAvailableDiceIndices() > 0
end

function gamestate:isCurrentCellEmpty()
	return self.board[self.cursorRow][self.cursorColumn] == nil
end

function gamestate:moveCursor(dx, dy)
	self.cursorColumn = ((self.cursorColumn - 1 + dx) % GRID_SIZE) + 1
	self.cursorRow = ((self.cursorRow - 1 + dy) % GRID_SIZE) + 1
	self:updateCamera()
end

function gamestate:movePreviewSelection(step)
	local available = self:getAvailableDiceIndices()
	local count = #available

	if count == 0 then
		self.previewSelectionIndex = 1
		return
	end

	self.previewSelectionIndex = ((self.previewSelectionIndex - 1 + step) % count) + 1
end

function gamestate:getPreviewDieIndex()
	local available = self:getAvailableDiceIndices()
	if #available == 0 then
		return nil
	end

	return available[self.previewSelectionIndex]
end

function gamestate:getActiveDie()
	if self.mode == MODE_SELECT then
		local previewDieIndex = self:getPreviewDieIndex()
		if previewDieIndex then
			return self.dice[previewDieIndex]
		end
	elseif self.mode == MODE_PLACE and self.selectedDieIndex then
		return self.dice[self.selectedDieIndex]
	end

	return nil
end

function gamestate:updateDieRotation()
	local activeDie = self:getActiveDie()
	local crankChange = playdate.getCrankChange()
	local isCranking = math.abs(crankChange) > CRANK_DEADZONE

	if activeDie and isCranking then
		activeDie:rotateBy(crankChange)
	end

	for _, die in ipairs(self.dice) do
		if die ~= activeDie or not isCranking then
			die:updateRotationLock()
		end
	end
end

function gamestate:openDieSelection()
	local available = self:getAvailableDiceIndices()
	if #available == 0 then
		self.mode = MODE_GRID
		self.selectedDieIndex = nil
		return
	end

	self.mode = MODE_SELECT
	self.selectedDieIndex = nil
	if self.previewSelectionIndex > #available then
		self.previewSelectionIndex = 1
	end
end

function gamestate:confirmDieSelection()
	local available = self:getAvailableDiceIndices()
	if #available == 0 then
		return
	end

	self.selectedDieIndex = available[self.previewSelectionIndex]
	self.mode = MODE_PLACE
	self:updateCamera()
end

function gamestate:placeSelectedDie()
	if not self.selectedDieIndex or not self:isCurrentCellEmpty() then
		return
	end

	local die = self.dice[self.selectedDieIndex]
	die:snapRotationToRightAngle()
	die.isPlaced = true
	self.board[self.cursorRow][self.cursorColumn] = self.selectedDieIndex
	self.selectedDieIndex = nil
	self.previewSelectionIndex = 1

	if self:hasAvailableDice() then
		self:openDieSelection()
	else
		self.mode = MODE_GRID
	end
end

function gamestate:handleGridInput()
	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		self:moveCursor(-1, 0)
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		self:moveCursor(1, 0)
	elseif playdate.buttonJustPressed(playdate.kButtonUp) then
		self:moveCursor(0, -1)
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		self:moveCursor(0, 1)
	elseif playdate.buttonJustPressed(playdate.kButtonA) then
		self:openDieSelection()
	end
end

function gamestate:handleSelectInput()
	if playdate.buttonJustPressed(playdate.kButtonLeft) or playdate.buttonJustPressed(playdate.kButtonUp) then
		self:movePreviewSelection(-1)
	elseif playdate.buttonJustPressed(playdate.kButtonRight) or playdate.buttonJustPressed(playdate.kButtonDown) then
		self:movePreviewSelection(1)
	elseif playdate.buttonJustPressed(playdate.kButtonA) then
		self:confirmDieSelection()
	elseif playdate.buttonJustPressed(playdate.kButtonB) then
		self.mode = MODE_GRID
	end
end

function gamestate:handlePlaceInput()
	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		self:moveCursor(-1, 0)
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		self:moveCursor(1, 0)
	elseif playdate.buttonJustPressed(playdate.kButtonUp) then
		self:moveCursor(0, -1)
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		self:moveCursor(0, 1)
	elseif playdate.buttonJustPressed(playdate.kButtonA) then
		self:placeSelectedDie()
	elseif playdate.buttonJustPressed(playdate.kButtonB) then
		self:openDieSelection()
	end
end

function gamestate:update()
	self:updateDieRotation()

	if self.mode == MODE_GRID and playdate.buttonJustPressed(playdate.kButtonB) then
		return "start"
	end

	if self.mode == MODE_GRID then
		self:handleGridInput()
	elseif self.mode == MODE_SELECT then
		self:handleSelectInput()
	elseif self.mode == MODE_PLACE then
		self:handlePlaceInput()
	end

	return "game"
end

function gamestate:toScreenY(worldY)
	return worldY - self.cameraY
end

function gamestate:getCellScreenRect(row, column)
	local x = GRID_X + ((column - 1) * CELL_SIZE)
	local y = self:toScreenY(GRID_WORLD_Y + ((row - 1) * CELL_SIZE))
	return x, y, CELL_SIZE, CELL_SIZE
end

function gamestate:drawRectOutline(x, y, width, height, thickness)
	for offset = 0, thickness - 1 do
		gfx.drawRect(x - offset, y - offset, width + (offset * 2), height + (offset * 2))
	end
end

function gamestate:drawZoneFrames()
	local bonusX = GRID_X + ((BONUS_START_INDEX - 1) * CELL_SIZE)
	local bonusY = self:toScreenY(GRID_WORLD_Y + ((BONUS_START_INDEX - 1) * CELL_SIZE))
	local bonusSize = BONUS_SIZE * CELL_SIZE

	self:drawRectOutline(bonusX, bonusY, bonusSize, bonusSize, BONUS_BORDER_THICKNESS)
end

function gamestate:drawGrid()
	local gridTop = self:toScreenY(GRID_WORLD_Y)
	local gridBottom = gridTop + GRID_PIXEL_SIZE

	for index = 0, GRID_SIZE do
		local x = GRID_X + (index * CELL_SIZE)
		local y = gridTop + (index * CELL_SIZE)
		if y >= -CELL_SIZE and y <= SCREEN_HEIGHT + CELL_SIZE then
			gfx.drawLine(GRID_X, y, GRID_X + GRID_PIXEL_SIZE, y)
		end
		gfx.drawLine(x, gridTop, x, gridBottom)
	end
end

function gamestate:drawPlacedDice()
	for row = 1, GRID_SIZE do
		for column = 1, GRID_SIZE do
			local dieIndex = self.board[row][column]
			if dieIndex then
				local x, y, width, height = self:getCellScreenRect(row, column)
				if y + height >= 0 and y <= SCREEN_HEIGHT then
					local centerX = x + (width / 2)
					local centerY = y + (height / 2)
					self.dice[dieIndex]:drawAt(centerX, centerY, PLACED_DIE_SIZE, false)
				end
			end
		end
	end
end

function gamestate:drawCursor()
	local x, y, width, height = self:getCellScreenRect(self.cursorRow, self.cursorColumn)
	local inset = GRID_LINE_WIDTH
	local drawX = x + inset
	local drawY = y + inset
	local drawSize = width - (inset * 2)
	local showPlacementPreview = self.mode == MODE_PLACE and self.selectedDieIndex and self:isCurrentCellEmpty()

	if showPlacementPreview then
		self.dice[self.selectedDieIndex]:drawAt(drawX + (drawSize / 2), drawY + (drawSize / 2), PREVIEW_DIE_SIZE, true)
	end

	gfx.drawRect(drawX, drawY, drawSize, drawSize)
	if showPlacementPreview then
		gfx.drawRect(drawX - 1, drawY - 1, drawSize + 2, drawSize + 2)
	end
end

function gamestate:drawHeader()
	local label = "Cell " .. self.cursorColumn .. "," .. self.cursorRow
	gfx.fillRect(0, 0, SCREEN_WIDTH, 10)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextAligned(label, 200, 1, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function gamestate:drawModeHint()
	local text

	if self.mode == MODE_SELECT then
		text = "Choose a die"
	elseif self.mode == MODE_PLACE then
		if self:isCurrentCellEmpty() then
			text = "Pick a cell"
		else
			text = "Cell occupied"
		end
	elseif self:hasAvailableDice() then
		text = "A: choose die  B: back"
	else
		text = "All dice placed"
	end

	gfx.fillRect(110, SCREEN_HEIGHT - 14, 180, 12)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextAligned(text, 200, SCREEN_HEIGHT - 13, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function gamestate:drawDiePicker()
	if self.mode ~= MODE_SELECT then
		return
	end

	local available = self:getAvailableDiceIndices()
	local pickerWidth = SCREEN_WIDTH - (PICKER_PADDING * 2)
	local pickerY = SCREEN_HEIGHT - PICKER_HEIGHT - 8
	local centerY = pickerY + 42

	gfx.fillRoundRect(PICKER_PADDING, pickerY, pickerWidth, PICKER_HEIGHT, 10)
	gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
	gfx.drawTextAligned("Choose a die", 200, pickerY + 8, kTextAlignment.center)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)

	if #available == 0 then
		return
	end

	local totalWidth = (#available * PICKER_DIE_SIZE) + ((#available - 1) * 12)
	local startX = math.floor((SCREEN_WIDTH - totalWidth) / 2) + (PICKER_DIE_SIZE / 2)

	for previewIndex, dieIndex in ipairs(available) do
		local centerX = startX + ((previewIndex - 1) * (PICKER_DIE_SIZE + 12))
		local isSelected = previewIndex == self.previewSelectionIndex
		self.dice[dieIndex]:drawAt(centerX, centerY, PICKER_DIE_SIZE, isSelected)
	end
end

function gamestate:draw()
	gfx.clear()
	self:drawZoneFrames()
	self:drawGrid()
	self:drawPlacedDice()
	self:drawCursor()
	self:drawHeader()
	self:drawModeHint()
	self:drawDiePicker()
end
