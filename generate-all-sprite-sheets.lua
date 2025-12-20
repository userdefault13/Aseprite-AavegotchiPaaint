-- Generate All Sprite Sheets
-- This script generates all 16 body sprite sheets and all 18 eye range sprite sheets

local SpriteSheetGenerator = dofile("sprite-sheet-generator.lua")

-- Set paths (same as hardcoded in aavegotchi-paint-panel.lua)
local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local outputDir = assetsPath .. "/Output"

print("=== Sprite Sheet Generator ===")
print("Assets Path: " .. assetsPath)
print("Output Directory: " .. outputDir)
print("")

-- Create output subdirectories (Aseprite might not support mkdir, so we'll try)
-- The user should create these manually if needed
local bodiesDir = outputDir .. "/bodies"
local eyesDir = outputDir .. "/eyes"

print("Generating body sprite sheets...")
print("")

-- Generate all 16 body sprite sheets
local bodyConfig = {
    mouthExpression = "neutral",
    handPose = "down_open",
    wearables = {}
}

local bodyResults, bodyErr = SpriteSheetGenerator.generateAllCollateralBodySpriteSheets(
    assetsPath,
    bodiesDir,
    bodyConfig
)

if bodyErr then
    print("Error: " .. bodyErr)
else
    local successCount = 0
    local failCount = 0
    for collateral, result in pairs(bodyResults) do
        if result.success then
            print("✓ " .. collateral .. ": " .. result.outputPath)
            successCount = successCount + 1
        else
            print("✗ " .. collateral .. ": " .. (result.error or "Unknown error"))
            failCount = failCount + 1
        end
    end
    print("")
    print("Body sheets: " .. successCount .. " succeeded, " .. failCount .. " failed")
end

print("")
print("Generating eye sprite sheets...")
print("")

-- Generate all 18 eye range sprite sheets
local eyeResults, eyeErr = SpriteSheetGenerator.generateAllEyeRangeSpriteSheets(
    assetsPath,
    eyesDir
)

if eyeErr then
    print("Error: " .. eyeErr)
else
    local successCount = 0
    local failCount = 0
    for eyeRange, result in pairs(eyeResults) do
        if result.success then
            print("✓ " .. eyeRange .. ": " .. result.outputPath)
            successCount = successCount + 1
        else
            print("✗ " .. eyeRange .. ": " .. (result.error or "Unknown error"))
            failCount = failCount + 1
        end
    end
    print("")
    print("Eye sheets: " .. successCount .. " succeeded, " .. failCount .. " failed")
end

print("")
print("=== Generation Complete ===")


