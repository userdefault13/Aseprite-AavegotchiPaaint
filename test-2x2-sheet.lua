-- Test: Create 2x2 sprite sheet (4 views) for amAAVE
-- Each frame is a separate frame in the sprite
-- Each part (shadow, body, etc.) is a separate layer

-- Helper to resolve script paths
local function resolveScriptPath(scriptName)
    if app.fs.isFile(scriptName) then
        return scriptName
    end
    local absolutePath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint/" .. scriptName
    if app.fs.isFile(absolutePath) then
        return absolutePath
    end
    return scriptName
end

local Composer = dofile(resolveScriptPath("aavegotchi-composer.lua"))

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local collateral = "amAAVE"
local FRAME_WIDTH = 64
local FRAME_HEIGHT = 64

print("=== Creating 2x2 Test Sprite Sheet ===")
print("Collateral: " .. collateral)
print("")

-- Views: 0=front, 1=left, 2=right, 3=back
local views = {
    {index = 0, name = "Front", gridX = 0, gridY = 0},
    {index = 1, name = "Left", gridX = 1, gridY = 0},
    {index = 2, name = "Right", gridX = 0, gridY = 1},
    {index = 3, name = "Back", gridX = 1, gridY = 1}
}

-- Create sprite sheet: 2x2 = 128x128
local sheetWidth = FRAME_WIDTH * 2
local sheetHeight = FRAME_HEIGHT * 2
local sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
app.activeSprite = sheetSprite

-- Remove default layer
if #sheetSprite.layers > 0 then
    sheetSprite:deleteLayer(sheetSprite.layers[1])
end

-- Create a single frame for the sprite sheet
local sheetFrame = sheetSprite:newFrame(1)

-- Process each view
for viewIdx, viewInfo in ipairs(views) do
    print("Composing view " .. viewIdx .. ": " .. viewInfo.name .. " (view " .. viewInfo.index .. ")")
    
    -- Compose Aavegotchi for this view
    local composerConfig = {
        collateral = collateral,
        view = viewInfo.index,
        handPose = "down_open",
        eyeRange = "happy",
        eyeRarity = "common",
        eyeExpression = "happy",
        mouthExpression = "neutral",
        wearables = {},
        canvasSize = FRAME_WIDTH
    }
    
    print("  Calling composeAavegotchi...")
    local result = Composer.composeAavegotchi(composerConfig, assetsPath, {})
    print("  Compose result received")
    
    if not result.success then
        print("ERROR: Failed to compose " .. viewInfo.name .. ": " .. table.concat(result.errors, ", "))
        pcall(function() app.activeSprite = sheetSprite; app.command.CloseFile() end)
        os.exit(1)
    end
    
    print("  Getting sprite from result...")
    local composedSprite = result.sprite
    print("  Sprite obtained, layers: " .. #composedSprite.layers)
    
    -- Calculate position in the 2x2 grid
    local x = viewInfo.gridX * FRAME_WIDTH
    local y = viewInfo.gridY * FRAME_HEIGHT
    
    -- Copy all layers from composed sprite to sheet sprite
    for _, layer in ipairs(composedSprite.layers) do
        -- Create a new layer in the sheet sprite with a name that includes the view
        local layerName = viewInfo.name .. " - " .. layer.name
        local sheetLayer = nil
        
        -- Check if layer already exists
        for _, existingLayer in ipairs(sheetSprite.layers) do
            if existingLayer.name == layerName then
                sheetLayer = existingLayer
                break
            end
        end
        
        if not sheetLayer then
            sheetLayer = sheetSprite:newLayer(layerName)
        end
        
        -- Get the cel from the composed sprite
        local composedFrame = composedSprite.frames[1]
        local composedCel = layer:cel(composedFrame)
        
        if composedCel and composedCel.image then
            -- Get or create cel for this layer in the sheet frame
            local sheetCel = sheetLayer:cel(sheetFrame)
            if not sheetCel then
                -- Create new image for the entire sheet
                local layerImage = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                sheetCel = sheetSprite:newCel(sheetLayer, sheetFrame, layerImage)
            end
            
            -- Draw the composed image at the correct position
            sheetCel.image:drawImage(composedCel.image, Point(x, y))
        end
    end
    
    -- Close the composed sprite
    print("  Closing composed sprite...")
    pcall(function()
        app.activeSprite = composedSprite
        app.command.CloseFile()
    end)
    
    -- Restore sheet sprite as active
    app.activeSprite = sheetSprite
    print("  Completed view " .. viewIdx)
    
    -- Force garbage collection after each view
    collectgarbage("collect")
end

-- Save the test sprite sheet
local outputPath = assetsPath .. "/Output/test-2x2-amAAVE.aseprite"
sheetSprite:saveAs(outputPath)

print("")
print("SUCCESS: Saved test sprite sheet to: " .. outputPath)
print("Frames: " .. #sheetSprite.frames)
print("Layers: " .. #sheetSprite.layers)

-- List all layers
for i, layer in ipairs(sheetSprite.layers) do
    print("  Layer " .. i .. ": " .. (layer.name or "unnamed"))
end

print("")
print("=== Test Complete ===")

