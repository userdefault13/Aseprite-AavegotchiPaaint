-- Test Mouth Spritesheet Generator via CLI
-- Usage: aseprite -b --script test-mouth-spritesheet-cli.lua

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local collateral = "amaave"
local jsonPath = assetsPath .. "/JSONs/Body/collateral-base-amaave.json"

print("=== Testing Mouth Spritesheet Generator ===")
print("Assets Path: " .. assetsPath)
print("Collateral: " .. collateral)
print("JSON Path: " .. jsonPath)
print("")

-- Load modules
local SpriteSheetGenerator = dofile(assetsPath .. "/aavegotchi-spritesheet-generator.lua")

if not SpriteSheetGenerator then
    print("ERROR: Failed to load SpriteSheetGenerator module")
    return
end

print("Module loaded successfully")
print("")

-- Test JSON file exists
if not app.fs.isFile(jsonPath) then
    print("ERROR: JSON file not found: " .. jsonPath)
    return
end

print("JSON file found")
print("")

-- Try to generate the spritesheet
print("Attempting to generate mouth spritesheet...")
print("")

local sprite, err
local ok, result1, result2 = pcall(function()
    return SpriteSheetGenerator.generateMouthSpriteSheet(collateral, jsonPath, assetsPath)
end)

if not ok then
    print("ERROR (pcall failed):")
    print(tostring(result1))  -- result1 contains the error message when pcall fails
    return
end

-- pcall wraps multiple return values, so we need to unpack
sprite = result1
err = result2

if not sprite then
    print("ERROR: Function returned nil")
    print("Error message: " .. (err or "No error message provided"))
    return
end

if err then
    print("WARNING: Function returned error but also sprite: " .. err)
end

print("SUCCESS: Spritesheet generated!")
print("Sprite dimensions: " .. sprite.width .. "x" .. sprite.height)
print("Frames: " .. #sprite.frames)
print("Layers: " .. #sprite.layers)

-- Save the result
local outputPath = assetsPath .. "/Output/test-mouth-spritesheet-" .. collateral:lower() .. ".aseprite"
app.activeSprite = sprite
sprite:saveAs(outputPath)
print("Saved to: " .. outputPath)

