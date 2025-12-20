-- Test Shadow Loading (Single Frame)
-- Run with: aseprite --script test-shadow-loading.lua

local SpriteSheetGenerator = dofile("sprite-sheet-generator.lua")

-- Set paths
local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local outputDir = assetsPath .. "/Output"

print("=== Testing Shadow Loading ===")
print("Assets Path: " .. assetsPath)
print("")

-- Test with a single frame
local config = {
    collateral = "amAAVE",
    view = 0,
    frameIndex = 0,
    shadowIndex = 0,
    yOffset = 0,
    excludeEyes = true,
    handPose = "down_open",
    mouthExpression = "neutral",
    wearables = {}
}

print("Generating test frame for " .. config.collateral .. "...")
print("Shadow index: " .. config.shadowIndex)
print("")

local sprite, err = SpriteSheetGenerator.generateFrame(
    config,
    config.frameIndex,
    config.shadowIndex,
    config.yOffset,
    assetsPath,
    config.excludeEyes
)

if err then
    print("ERROR: " .. err)
    os.exit(1)
else
    print("SUCCESS: Frame generated!")
    print("Sprite dimensions: " .. sprite.width .. "x" .. sprite.height)
    print("Layers: " .. #sprite.layers)
    
    -- List layers
    for i, layer in ipairs(sprite.layers) do
        print("  Layer " .. i .. ": " .. (layer.name or "unnamed"))
    end
    
    -- Save test output
    local testPath = outputDir .. "/test-shadow-frame.aseprite"
    app.activeSprite = sprite
    sprite:saveAs(testPath)
    print("")
    print("Saved test frame to: " .. testPath)
    
    -- Close sprite
    app.command.CloseFile()
    
    print("")
    print("=== Test Complete ===")
end


