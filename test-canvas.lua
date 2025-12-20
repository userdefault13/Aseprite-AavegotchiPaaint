-- Test: Create 128x128 canvas
-- Simple test to verify sprite creation works

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local FRAME_WIDTH = 64
local FRAME_HEIGHT = 64

print("=== Creating 128x128 Canvas ===")
print("")

-- Create sprite sheet: 2x2 = 128x128
local sheetWidth = FRAME_WIDTH * 2
local sheetHeight = FRAME_HEIGHT * 2

print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
local sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
print("Sprite created successfully")

app.activeSprite = sheetSprite
print("Sprite set as active")

-- Get the first frame (Aseprite creates one by default)
print("Getting frame...")
local sheetFrame = sheetSprite.frames[1]
if not sheetFrame then
    print("ERROR: No frame found")
    os.exit(1)
end
print("Frame obtained")

-- Save the test canvas (even with default layer, just to test)
local outputPath = assetsPath .. "/Output/test-canvas.aseprite"
print("Saving to: " .. outputPath)
sheetSprite:saveAs(outputPath)
print("Saved successfully")

print("")
print("SUCCESS: Canvas created and saved!")
print("Dimensions: " .. sheetSprite.width .. "x" .. sheetSprite.height)
print("Frames: " .. #sheetSprite.frames)
print("Layers: " .. #sheetSprite.layers)

print("")
print("=== Test Complete ===")

