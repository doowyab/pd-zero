import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

class("tile").extends()

local FACE_COUNT <const> = 6
local diceTables = {
	gfx.imagetable.new("sprites/tiles-white-col-1-table-64-64"),
	gfx.imagetable.new("sprites/tiles-white-col-2-table-64-64"),
	gfx.imagetable.new("sprites/tiles-white-col-3-table-64-64"),
	gfx.imagetable.new("sprites/tiles-white-col-4-table-64-64")
}
local TILE_SIZE <const> = 64
local SELECTED_SCALE <const> = 1.12
local WIGGLE_SPEED <const> = 0.0035
local WIGGLE_AMOUNT <const> = 6
local BORDER_PADDING <const> = 4
local LOCK_SPEED <const> = 0.18
local LOCK_THRESHOLD <const> = 0.5

for index, diceTable in ipairs(diceTables) do
	assert(diceTable, "Missing sprite table: sprites/tiles-white-col-" .. index .. "-table-64-64.png")
end

function tile:init(tableIndex)
	self.tableIndex = tableIndex
	self.isPlaced = false
	self.scaledImages = {}
	self.rotation = 0
	self:randomizeAppearance()
end

function tile:randomizeAppearance()
	self.faceIndex = math.random(FACE_COUNT)
	self.image = diceTables[self.tableIndex]:getImage(self.faceIndex)
	assert(self.image, "Missing die face " .. self.faceIndex .. " for die " .. self.tableIndex)
	self.scaledImages = {}
	self.rotation = 0
end

function tile:randomizeImage()
	self:randomizeAppearance()
end

local function normalizeAngle(angle)
	return ((angle % 360) + 360) % 360
end

local function shortestAngleDelta(fromAngle, toAngle)
	return ((toAngle - fromAngle + 540) % 360) - 180
end

local function nearestRightAngle(angle)
	return math.floor((angle + 45) / 90) * 90
end

function tile:rotateBy(delta)
	self.rotation = normalizeAngle(self.rotation + delta)
end

function tile:snapRotationToRightAngle()
	self.rotation = normalizeAngle(nearestRightAngle(self.rotation))
end

function tile:updateRotationLock()
	local targetRotation = nearestRightAngle(self.rotation)
	local delta = shortestAngleDelta(self.rotation, targetRotation)

	if math.abs(delta) <= LOCK_THRESHOLD then
		self.rotation = normalizeAngle(targetRotation)
		return
	end

	self.rotation = normalizeAngle(self.rotation + (delta * LOCK_SPEED))
end

function tile:getDrawState(centerX, centerY, scale, isSelected)
	local rotation = self.rotation

	if isSelected then
		local time = playdate.getCurrentTimeMilliseconds()
		rotation += math.sin(time * WIGGLE_SPEED) * WIGGLE_AMOUNT
		scale *= SELECTED_SCALE
	end

	return centerX, centerY, rotation, scale
end

function tile:drawSelectionBorder(centerX, centerY, rotation, size)
	local radius = (size / 2) + BORDER_PADDING
	local radians = math.rad(rotation)
	local cosAngle = math.cos(radians)
	local sinAngle = math.sin(radians)
	local corners = {
		{ x = -radius, y = -radius },
		{ x = radius, y = -radius },
		{ x = radius, y = radius },
		{ x = -radius, y = radius }
	}

	for index, corner in ipairs(corners) do
		local nextCorner = corners[(index % #corners) + 1]
		local x1 = centerX + (corner.x * cosAngle) - (corner.y * sinAngle)
		local y1 = centerY + (corner.x * sinAngle) + (corner.y * cosAngle)
		local x2 = centerX + (nextCorner.x * cosAngle) - (nextCorner.y * sinAngle)
		local y2 = centerY + (nextCorner.x * sinAngle) + (nextCorner.y * cosAngle)
		gfx.drawLine(x1, y1, x2, y2)
	end
end

function tile:getScaledImage(size)
	local imageSize = math.floor(size + 0.5)

	if imageSize >= TILE_SIZE then
		return self.image
	end

	if not self.scaledImages[imageSize] then
		local scale = imageSize / TILE_SIZE
		self.scaledImages[imageSize] = self.image:scaledImage(scale)
	end

	return self.scaledImages[imageSize]
end

function tile:drawAt(centerX, centerY, size, isSelected)
	local baseImage = self:getScaledImage(size)
	local drawCenterX, drawCenterY, rotation, drawScale = self:getDrawState(centerX, centerY, 1, isSelected)

	if isSelected or rotation ~= 0 or drawScale ~= 1 then
		baseImage:drawRotated(drawCenterX, drawCenterY, rotation, drawScale)
	else
		local imageWidth, imageHeight = baseImage:getSize()
		baseImage:draw(drawCenterX - (imageWidth / 2), drawCenterY - (imageHeight / 2))
	end

	if isSelected then
		self:drawSelectionBorder(drawCenterX, drawCenterY, rotation, size * drawScale)
	end
end
