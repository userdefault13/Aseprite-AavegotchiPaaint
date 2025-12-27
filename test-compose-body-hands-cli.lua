-- Test Body, Collateral, Hands, and Mouth Composition via CLI
-- Usage: aseprite -b --script test-compose-body-hands-cli.lua

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local collateral = "amAAVE"
local bodyPath = assetsPath .. "/Output/test-body-spritesheet-" .. collateral:lower() .. ".aseprite"
local collateralPath = assetsPath .. "/Output/test-collateral-spritesheet-" .. collateral:lower() .. ".aseprite"
local handsPath = assetsPath .. "/Output/test-hands-spritesheet-" .. collateral:lower() .. ".aseprite"
local mouthPath = assetsPath .. "/Output/test-mouth-spritesheet-" .. collateral:lower() .. ".aseprite"
local outputPath = assetsPath .. "/Output/test-composed-" .. collateral:lower() .. ".aseprite"

print("=== Testing Body, Collateral, Hands, and Mouth Composition ===")
print("Assets Path: " .. assetsPath)
print("Collateral: " .. collateral)
print("Body Path: " .. bodyPath)
print("Collateral Path: " .. collateralPath)
print("Hands Path: " .. handsPath)
print("Mouth Path: " .. mouthPath)
print("")

-- Check if files exist
if not app.fs.isFile(bodyPath) then
    print("ERROR: Body spritesheet not found: " .. bodyPath)
    print("Please run test-body-spritesheet-cli.lua first")
    os.exit(1)
end

if not app.fs.isFile(handsPath) then
    print("ERROR: Hands spritesheet not found: " .. handsPath)
    print("Please run test-hands-spritesheet-cli.lua first")
    os.exit(1)
end

-- Collateral is optional
local hasCollateral = app.fs.isFile(collateralPath)
if not hasCollateral then
    print("WARNING: Collateral spritesheet not found: " .. collateralPath)
    print("  Will proceed without collateral")
else
    print("Collateral spritesheet found")
end

-- Mouth is optional
local hasMouth = app.fs.isFile(mouthPath)
if not hasMouth then
    print("WARNING: Mouth spritesheet not found: " .. mouthPath)
    print("  Will proceed without mouth")
else
    print("Mouth spritesheet found")
end
print("")

-- Load body sprite
print("Loading body spritesheet...")
local bodySprite = app.open(bodyPath)
if not bodySprite then
    print("ERROR: Failed to load body spritesheet")
    os.exit(1)
end

print("Body sprite loaded: " .. bodySprite.width .. "x" .. bodySprite.height .. ", " .. #bodySprite.frames .. " frames, " .. #bodySprite.layers .. " layers")

-- Load hands sprite
print("Loading hands spritesheet...")
local handsSprite = app.open(handsPath)
if not handsSprite then
    print("ERROR: Failed to load hands spritesheet")
    pcall(function() app.activeSprite = bodySprite; app.command.CloseFile() end)
    os.exit(1)
end

print("Hands sprite loaded: " .. handsSprite.width .. "x" .. handsSprite.height .. ", " .. #handsSprite.frames .. " frames, " .. #handsSprite.layers .. " layers")

-- Load collateral sprite (if available)
local collateralSprite = nil
if hasCollateral then
    print("Loading collateral spritesheet...")
    collateralSprite = app.open(collateralPath)
    if not collateralSprite then
        print("WARNING: Failed to load collateral spritesheet, will proceed without it")
        hasCollateral = false
    else
        print("Collateral sprite loaded: " .. collateralSprite.width .. "x" .. collateralSprite.height .. ", " .. #collateralSprite.frames .. " frames, " .. #collateralSprite.layers .. " layers")
    end
end

-- Load mouth sprite (if available)
local mouthSprite = nil
if hasMouth then
    print("Loading mouth spritesheet...")
    mouthSprite = app.open(mouthPath)
    if not mouthSprite then
        print("WARNING: Failed to load mouth spritesheet, will proceed without it")
        hasMouth = false
    else
        print("Mouth sprite loaded: " .. mouthSprite.width .. "x" .. mouthSprite.height .. ", " .. #mouthSprite.frames .. " frames, " .. #mouthSprite.layers .. " layers")
    end
end
print("")

-- Check dimensions and handle mismatches
if bodySprite.width ~= handsSprite.width or bodySprite.height ~= handsSprite.height then
    print("WARNING: Dimension mismatch!")
    print("  Body: " .. bodySprite.width .. "x" .. bodySprite.height)
    print("  Hands: " .. handsSprite.width .. "x" .. handsSprite.height)
    print("  Using body dimensions as base for composition")
end

-- Handle frame count mismatch (body has 12 frames, hands has 3 frames, mouth has 3 frames)
if #bodySprite.frames ~= #handsSprite.frames then
    print("WARNING: Frame count mismatch!")
    print("  Body frames: " .. #bodySprite.frames)
    print("  Hands frames: " .. #handsSprite.frames)
    print("  Will composite hands frames on matching body frames")
end

if hasMouth and mouthSprite and #bodySprite.frames ~= #mouthSprite.frames then
    print("WARNING: Frame count mismatch with mouth!")
    print("  Body frames: " .. #bodySprite.frames)
    print("  Mouth frames: " .. #mouthSprite.frames)
    print("  Will composite mouth frames on matching body frames")
end
print("")

-- Create composed sprite (use body as base)
print("Creating composed sprite...")
local composedSprite = Sprite(bodySprite.width, bodySprite.height, ColorMode.RGB)
app.activeSprite = composedSprite

-- Remove default layer
pcall(function()
    if #composedSprite.layers > 0 then
        composedSprite:deleteLayer(composedSprite.layers[1])
    end
end)

-- Create frames
for i = 1, #bodySprite.frames do
    if i > 1 then
        composedSprite:newFrame(i)
    end
end

print("Composed sprite created: " .. composedSprite.width .. "x" .. composedSprite.height .. ", " .. #composedSprite.frames .. " frames")
print("")

-- Copy body layers and cels
print("Copying body layers...")
for layerIdx, bodyLayer in ipairs(bodySprite.layers) do
    local composedLayer = composedSprite:newLayer(bodyLayer.name)
    print("  Created layer: " .. bodyLayer.name)
    
    for frameIdx, frame in ipairs(bodySprite.frames) do
        local bodyCel = bodyLayer:cel(frame)
        if bodyCel and bodyCel.image then
            local composedFrame = composedSprite.frames[frameIdx]
            local composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
            composedImage:drawImage(bodyCel.image, Point(0, 0))
            composedSprite:newCel(composedLayer, composedFrame, composedImage)
        end
    end
end

-- Copy collateral layers and cels (will composite over body, under hands)
if hasCollateral and collateralSprite then
    print("Copying collateral layers...")
    for layerIdx, collateralLayer in ipairs(collateralSprite.layers) do
        local composedLayer = composedSprite:newLayer(collateralLayer.name)
        print("  Created layer: " .. collateralLayer.name)
        
        -- Copy collateral frames to matching body frames
        -- Collateral has 1 frame, so use it for all body frames
        local collateralFrame = collateralSprite.frames[1]
        local collateralCel = collateralLayer:cel(collateralFrame)
        
        if collateralCel and collateralCel.image then
            -- Use the same collateral image for all frames
            for frameIdx = 1, #composedSprite.frames do
                local composedFrame = composedSprite.frames[frameIdx]
                local composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
                
                -- Draw collateral over body (composite)
                composedImage:drawImage(collateralCel.image, Point(0, 0))
                composedSprite:newCel(composedLayer, composedFrame, composedImage)
            end
        end
    end
end

-- Copy hands layers and cels (will composite over body and collateral)
print("Copying hands layers...")
for layerIdx, handsLayer in ipairs(handsSprite.layers) do
    local composedLayer = composedSprite:newLayer(handsLayer.name)
    print("  Created layer: " .. handsLayer.name)
    
    -- Copy hands frames to matching body frames
    -- If body has more frames than hands, repeat the last hands frame
    local maxHandsFrame = #handsSprite.frames
    
    for frameIdx = 1, #composedSprite.frames do
        local handsFrameIdx = math.min(frameIdx, maxHandsFrame)
        local handsFrame = handsSprite.frames[handsFrameIdx]
        local handsCel = handsLayer:cel(handsFrame)
        
        if handsCel and handsCel.image then
            local composedFrame = composedSprite.frames[frameIdx]
            local composedCel = composedLayer:cel(composedFrame)
            local composedImage = nil
            
            if composedCel and composedCel.image then
                -- Layer already exists, draw over it
                composedImage = composedCel.image
            else
                -- Create new image
                composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
            end
            
            -- Draw hands over body and collateral (composite)
            composedImage:drawImage(handsCel.image, Point(0, 0))
            
            if not composedCel then
                composedSprite:newCel(composedLayer, composedFrame, composedImage)
            end
        end
    end
end

-- Copy mouth layers and cels (will composite over everything - top layer)
if hasMouth and mouthSprite then
    print("Copying mouth layers...")
    for layerIdx, mouthLayer in ipairs(mouthSprite.layers) do
        local composedLayer = composedSprite:newLayer(mouthLayer.name)
        print("  Created layer: " .. mouthLayer.name)
        
        -- Copy mouth frames to matching body frames
        -- If body has more frames than mouth, repeat the last mouth frame
        local maxMouthFrame = #mouthSprite.frames
        
        for frameIdx = 1, #composedSprite.frames do
            local mouthFrameIdx = math.min(frameIdx, maxMouthFrame)
            local mouthFrame = mouthSprite.frames[mouthFrameIdx]
            local mouthCel = mouthLayer:cel(mouthFrame)
            
            if mouthCel and mouthCel.image then
                local composedFrame = composedSprite.frames[frameIdx]
                local composedCel = composedLayer:cel(composedFrame)
                local composedImage = nil
                
                if composedCel and composedCel.image then
                    -- Layer already exists, draw over it
                    composedImage = composedCel.image
                else
                    -- Create new image
                    composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
                end
                
                -- Draw mouth over everything (composite on top)
                composedImage:drawImage(mouthCel.image, Point(0, 0))
                
                if not composedCel then
                    composedSprite:newCel(composedLayer, composedFrame, composedImage)
                end
            end
        end
    end
end

print("")
print("SUCCESS: Composition complete!")
print("Total layers: " .. #composedSprite.layers)
print("Frames: " .. #composedSprite.frames)

-- Save composed sprite
app.activeSprite = composedSprite
composedSprite:saveAs(outputPath)
print("Saved to: " .. outputPath)

-- Close source sprites
pcall(function()
    app.activeSprite = bodySprite
    app.command.CloseFile()
end)

if hasCollateral and collateralSprite then
    pcall(function()
        app.activeSprite = collateralSprite
        app.command.CloseFile()
    end)
end

pcall(function()
    app.activeSprite = handsSprite
    app.command.CloseFile()
end)

if hasMouth and mouthSprite then
    pcall(function()
        app.activeSprite = mouthSprite
        app.command.CloseFile()
    end)
end

print("Done!")

