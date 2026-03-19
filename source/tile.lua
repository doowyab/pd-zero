import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

class("tile").extends()

local roadImage = gfx.image.new("sprites/road")
local railImage = gfx.image.new("sprites/rail")

assert(roadImage, "Missing sprite: sprites/road.png")
assert(railImage, "Missing sprite: sprites/rail.png")

function tile:init(x, y)
	self.x = x
	self.y = y
	self:randomizeImage()
end

function tile:randomizeImage()
	self.image = math.random(2) == 1 and roadImage or railImage
end

function tile:draw()
	self.image:draw(self.x, self.y)
end
