-- Test Opening Shadow File Directly
-- Run with: aseprite --script test-shadow-open.lua

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local shadowPath = assetsPath .. "/Aseprites/Collaterals/amAAVE/shadow/shadow_00_amAAVE.aseprite"

print("=== Testing Shadow File Opening ===")
print("Shadow Path: " .. shadowPath)
print("")

if not app.fs.isFile(shadowPath) then
    print("ERROR: Shadow file not found!")
    os.exit(1)
end

print("Shadow file exists. Opening...")
local shadowSprite = app.open(shadowPath)

if not shadowSprite then
    print("ERROR: Failed to open shadow file!")
    os.exit(1)
end

print("SUCCESS: Shadow file opened!")
print("Sprite dimensions: " .. shadowSprite.width .. "x" .. shadowSprite.height)
print("Frames: " .. #shadowSprite.frames)
print("Layers: " .. #shadowSprite.layers)

for i, layer in ipairs(shadowSprite.layers) do
    print("  Layer " .. i .. ": " .. (layer.name or "unnamed"))
end

-- Close the sprite
app.command.CloseFile()
print("")
print("Shadow sprite closed successfully.")
print("=== Test Complete ===")

