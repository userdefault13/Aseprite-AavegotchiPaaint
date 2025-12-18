-- AavegotchiSprites: Create sprite sheet with body layers for each view
-- Each body sprite is a separate layer positioned in its quadrant

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local collateral = "amAAVE"
local FRAME_WIDTH = 64
local FRAME_HEIGHT = 64

print("=== AavegotchiSprites ===")
print("Collateral: " .. collateral)
print("")

-- Determine paths
local bodyPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/body"
local handsPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/hands"
local collateralPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/collateral"
local shadowPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/shadow"
print("Body path: " .. bodyPath)
print("Hands path: " .. handsPath)
print("Collateral path: " .. collateralPath)
print("Shadow path: " .. shadowPath)

-- Views configuration: name, view index, body fileName, hand fileName, collateral fileName
local views = {
    {name = "Front", viewIndex = 0, bodyFileName = "body_front_amaave.aseprite", handFileName = "hands_down_open_amAAVE.aseprite", collateralFileName = "collateral_front_amAAVE.aseprite"},
    {name = "Left", viewIndex = 1, bodyFileName = "body_left_amaave.aseprite", handFileName = "hands_left_amAAVE.aseprite", collateralFileName = "collateral_left_amAAVE.aseprite"},
    {name = "Right", viewIndex = 2, bodyFileName = "body_right_amaave.aseprite", handFileName = "hands_right_amAAVE.aseprite", collateralFileName = "collateral_right_amAAVE.aseprite"},
    {name = "Back", viewIndex = 3, bodyFileName = "body_back_amaave.aseprite", handFileName = "hands_down_open_amAAVE.aseprite", collateralFileName = nil}  -- No collateral for back view
}

-- Create sprite sheet: 2x4 grid = 128x256
-- Frame layout (top-left going right, then down):
-- Frame 1: Front (0,0)      Frame 2: Front offset (1,0)
-- Frame 3: Left (0,1)       Frame 4: Left offset (1,1)
-- Frame 5: Right (0,2)      Frame 6: Right offset (1,2)
-- Frame 7: Back (0,3)       Frame 8: Back offset (1,3)
local sheetWidth = FRAME_WIDTH * 2
local sheetHeight = FRAME_HEIGHT * 4

print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
local sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
app.activeSprite = sheetSprite

-- Get the first frame
local sheetFrame = sheetSprite.frames[1]
if not sheetFrame then
    print("ERROR: No frame found")
    os.exit(1)
end

-- Remove default layer if it exists
if #sheetSprite.layers > 0 then
    local defaultLayer = sheetSprite.layers[1]
    sheetSprite:deleteLayer(defaultLayer)
end

-- Process each view (creates 2 frames per view: normal and offset)
for viewIdx, viewInfo in ipairs(views) do
    local bodyFilePath = bodyPath .. "/" .. viewInfo.bodyFileName
    local handFilePath = handsPath .. "/" .. viewInfo.handFileName
    local collateralFilePath = viewInfo.collateralFileName and (collateralPath .. "/" .. viewInfo.collateralFileName) or nil
    
    print("Processing " .. viewInfo.name .. " view...")
    print("  Body file: " .. bodyFilePath)
    print("  Hand file: " .. handFilePath)
    if collateralFilePath then
        print("  Collateral file: " .. collateralFilePath)
    else
        print("  Collateral: (none - back view)")
    end
    print("  Shadow files: shadow_00 (normal), shadow_01 (offset)")
    
    -- Check if file exists
    if not app.fs.isFile(bodyFilePath) then
        print("  WARNING: File not found: " .. bodyFilePath)
        print("  Skipping this view")
    else
        -- Load the body sprite
        print("  Loading body sprite...")
        local bodySprite = nil
        local ok, err = pcall(function()
            bodySprite = app.open(bodyFilePath)
        end)
        
        if not ok or not bodySprite then
            print("  ERROR: Failed to open body sprite: " .. (err or "Unknown error"))
        else
            print("  Body sprite loaded successfully")
            
            -- Ensure sprite is active before accessing properties
            app.activeSprite = bodySprite
            
            -- Get the body image from the first frame and first layer
            local bodyFrame = nil
            local bodyLayerSrc = nil
            local bodyCel = nil
            
            ok, err = pcall(function()
                if #bodySprite.frames > 0 then
                    bodyFrame = bodySprite.frames[1]
                end
                if #bodySprite.layers > 0 then
                    bodyLayerSrc = bodySprite.layers[1]
                end
                if bodyFrame and bodyLayerSrc then
                    bodyCel = bodyLayerSrc:cel(bodyFrame)
                end
            end)
            
            if not ok then
                print("  ERROR: Failed to access body sprite properties: " .. (err or "Unknown error"))
                bodyCel = nil
            end
            
            if bodyCel and bodyCel.image then
                -- Calculate grid position for this view
                -- Frame 1,3,5,7 are at (0,0), (0,1), (0,2), (0,3)
                -- Frame 2,4,6,8 are at (1,0), (1,1), (1,2), (1,3)
                local row = viewIdx - 1  -- 0, 1, 2, 3
                
                -- Frame 1,3,5,7: normal position (left column)
                local frameNumNormal = (viewIdx * 2) - 1
                local gridXNormal = 0
                local gridYNormal = row
                local xNormal = gridXNormal * FRAME_WIDTH
                local yNormal = gridYNormal * FRAME_HEIGHT
                
                -- Frame 2,4,6,8: offset position (right column, y=-1)
                local frameNumOffset = viewIdx * 2
                local gridXOffset = 1
                local gridYOffset = row
                local xOffset = gridXOffset * FRAME_WIDTH
                local yOffset = gridYOffset * FRAME_HEIGHT
                
                -- Ensure sheet sprite is active before creating layers
                app.activeSprite = sheetSprite
                
                -- Create layer for normal frame
                local layerNameNormal = viewInfo.name .. " - Body (Frame " .. frameNumNormal .. ")"
                print("  Creating layer: " .. layerNameNormal)
                local bodyLayerNormal = sheetSprite:newLayer(layerNameNormal)
                bodyLayerNormal.name = layerNameNormal  -- Explicitly set layer name
                
                -- Create image for normal position
                local layerImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                layerImageNormal:drawImage(bodyCel.image, Point(xNormal, yNormal))
                sheetSprite:newCel(bodyLayerNormal, sheetFrame, layerImageNormal)
                layerImageNormal = nil  -- Clear reference
                print("  Normal frame positioned at (" .. xNormal .. ", " .. yNormal .. ")")
                
                -- Create layer for offset frame
                local layerNameOffset = viewInfo.name .. " - Body (Frame " .. frameNumOffset .. ", y=-1)"
                print("  Creating layer: " .. layerNameOffset)
                local bodyLayerOffset = sheetSprite:newLayer(layerNameOffset)
                
                -- Create image for offset position (y=-1)
                local layerImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                layerImageOffset:drawImage(bodyCel.image, Point(xOffset, yOffset - 1))
                sheetSprite:newCel(bodyLayerOffset, sheetFrame, layerImageOffset)
                layerImageOffset = nil  -- Clear reference
                print("  Offset frame positioned at (" .. xOffset .. ", " .. (yOffset - 1) .. ")")
                
                -- Clear body cel reference
                bodyCel = nil
            else
                print("  WARNING: No image data found in body sprite")
            end
            
            -- Close the body sprite
            pcall(function()
                app.activeSprite = bodySprite
                app.command.CloseFile()
            end)
            bodySprite = nil  -- Clear reference
            
            -- Restore sheet sprite as active
            app.activeSprite = sheetSprite
            
            -- Force garbage collection after body
            collectgarbage("step")
        end
    end
    
    -- Now process hands for this view
    print("  Processing hands...")
    if not app.fs.isFile(handFilePath) then
        print("  WARNING: Hand file not found: " .. handFilePath)
    else
        -- Load the hand sprite
        local handSprite = nil
        local ok, err = pcall(function()
            handSprite = app.open(handFilePath)
        end)
        
        if not ok or not handSprite then
            print("  ERROR: Failed to open hand sprite: " .. (err or "Unknown error"))
        else
            print("  Hand sprite loaded successfully")
            
            -- Ensure sprite is active before accessing properties
            app.activeSprite = handSprite
            
            -- Get the hand image from the first frame and first layer
            local handFrame = nil
            local handLayerSrc = nil
            local handCel = nil
            
            ok, err = pcall(function()
                if #handSprite.frames > 0 then
                    handFrame = handSprite.frames[1]
                end
                if #handSprite.layers > 0 then
                    handLayerSrc = handSprite.layers[1]
                end
                if handFrame and handLayerSrc then
                    handCel = handLayerSrc:cel(handFrame)
                end
            end)
            
            if not ok then
                print("  ERROR: Failed to access hand sprite properties: " .. (err or "Unknown error"))
                handCel = nil
            end
            
            if handCel and handCel.image then
                -- Calculate grid positions (same as body)
                local row = viewIdx - 1
                local frameNumNormal = (viewIdx * 2) - 1
                local frameNumOffset = viewIdx * 2
                local xNormal = 0 * FRAME_WIDTH
                local yNormal = row * FRAME_HEIGHT
                local xOffset = 1 * FRAME_WIDTH
                local yOffset = row * FRAME_HEIGHT
                
                -- Ensure sheet sprite is active before creating layers
                app.activeSprite = sheetSprite
                
                -- Create layer for normal frame hands
                local handLayerNameNormal = viewInfo.name .. " - Hands (Frame " .. frameNumNormal .. ")"
                print("  Creating hand layer: " .. handLayerNameNormal)
                local handLayerNormal = sheetSprite:newLayer(handLayerNameNormal)
                handLayerNormal.name = handLayerNameNormal  -- Explicitly set layer name
                
                -- Create image for normal position hands
                local handImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                handImageNormal:drawImage(handCel.image, Point(xNormal, yNormal))
                sheetSprite:newCel(handLayerNormal, sheetFrame, handImageNormal)
                handImageNormal = nil  -- Clear reference
                print("  Normal hand frame positioned at (" .. xNormal .. ", " .. yNormal .. ")")
                
                -- Create layer for offset frame hands
                local handLayerNameOffset = viewInfo.name .. " - Hands (Frame " .. frameNumOffset .. ", y=-1)"
                print("  Creating hand layer: " .. handLayerNameOffset)
                local handLayerOffset = sheetSprite:newLayer(handLayerNameOffset)
                
                -- Create image for offset position hands (y=-1)
                local handImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                handImageOffset:drawImage(handCel.image, Point(xOffset, yOffset - 1))
                sheetSprite:newCel(handLayerOffset, sheetFrame, handImageOffset)
                handImageOffset = nil  -- Clear reference
                print("  Offset hand frame positioned at (" .. xOffset .. ", " .. (yOffset - 1) .. ")")
                
                -- Clear hand cel reference
                handCel = nil
            else
                print("  WARNING: No image data found in hand sprite")
            end
            
            -- Close the hand sprite
            pcall(function()
                app.activeSprite = handSprite
                app.command.CloseFile()
            end)
            handSprite = nil  -- Clear reference
            
            -- Restore sheet sprite as active
            app.activeSprite = sheetSprite
            
            -- Force garbage collection after hands
            collectgarbage("step")
        end
    end
    
    -- Now process collateral for this view (skip if back view)
    if viewInfo.collateralFileName then
        print("  Processing collateral...")
        if not app.fs.isFile(collateralFilePath) then
            print("  WARNING: Collateral file not found: " .. collateralFilePath)
        else
            -- Load the collateral sprite
            local collateralSprite = nil
            local ok, err = pcall(function()
                collateralSprite = app.open(collateralFilePath)
            end)
            
            if not ok or not collateralSprite then
                print("  ERROR: Failed to open collateral sprite: " .. (err or "Unknown error"))
            else
                print("  Collateral sprite loaded successfully")
                
                -- Ensure sprite is active before accessing properties
                app.activeSprite = collateralSprite
                
                -- Get the collateral image from the first frame and first layer
                local collateralFrame = nil
                local collateralLayerSrc = nil
                local collateralCel = nil
                
                ok, err = pcall(function()
                    if #collateralSprite.frames > 0 then
                        collateralFrame = collateralSprite.frames[1]
                    end
                    if #collateralSprite.layers > 0 then
                        collateralLayerSrc = collateralSprite.layers[1]
                    end
                    if collateralFrame and collateralLayerSrc then
                        collateralCel = collateralLayerSrc:cel(collateralFrame)
                    end
                end)
                
                if not ok then
                    print("  ERROR: Failed to access collateral sprite properties: " .. (err or "Unknown error"))
                    collateralCel = nil
                end
                
                if collateralCel and collateralCel.image then
                    -- Calculate grid positions (same as body and hands)
                    local row = viewIdx - 1
                    local frameNumNormal = (viewIdx * 2) - 1
                    local frameNumOffset = viewIdx * 2
                    local xNormal = 0 * FRAME_WIDTH
                    local yNormal = row * FRAME_HEIGHT
                    local xOffset = 1 * FRAME_WIDTH
                    local yOffset = row * FRAME_HEIGHT
                    
                    -- Ensure sheet sprite is active before creating layers
                    app.activeSprite = sheetSprite
                    
                    -- Create layer for normal frame collateral
                    local collateralLayerNameNormal = viewInfo.name .. " - Collateral (Frame " .. frameNumNormal .. ")"
                    print("  Creating collateral layer: " .. collateralLayerNameNormal)
                    local collateralLayerNormal = sheetSprite:newLayer(collateralLayerNameNormal)
                    collateralLayerNormal.name = collateralLayerNameNormal  -- Explicitly set layer name
                    
                    -- Create image for normal position collateral
                    local collateralImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    collateralImageNormal:drawImage(collateralCel.image, Point(xNormal, yNormal))
                    sheetSprite:newCel(collateralLayerNormal, sheetFrame, collateralImageNormal)
                    collateralImageNormal = nil  -- Clear reference
                    print("  Normal collateral frame positioned at (" .. xNormal .. ", " .. yNormal .. ")")
                    
                    -- Create layer for offset frame collateral
                    local collateralLayerNameOffset = viewInfo.name .. " - Collateral (Frame " .. frameNumOffset .. ", y=-1)"
                    print("  Creating collateral layer: " .. collateralLayerNameOffset)
                    local collateralLayerOffset = sheetSprite:newLayer(collateralLayerNameOffset)
                    
                    -- Create image for offset position collateral (y=-1)
                    local collateralImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    collateralImageOffset:drawImage(collateralCel.image, Point(xOffset, yOffset - 1))
                    sheetSprite:newCel(collateralLayerOffset, sheetFrame, collateralImageOffset)
                    collateralImageOffset = nil  -- Clear reference
                    print("  Offset collateral frame positioned at (" .. xOffset .. ", " .. (yOffset - 1) .. ")")
                    
                    -- Clear collateral cel reference
                    collateralCel = nil
                else
                    print("  WARNING: No image data found in collateral sprite")
                end
                
                -- Close the collateral sprite
                pcall(function()
                    app.activeSprite = collateralSprite
                    app.command.CloseFile()
                end)
                collateralSprite = nil  -- Clear reference
                
                -- Restore sheet sprite as active
                app.activeSprite = sheetSprite
            end
        end
    else
        print("  Skipping collateral (back view)")
    end
    
    -- Now process shadows for this view
    -- shadow_00 goes in frames 1,3,5,7 (normal frames)
    -- shadow_01 goes in frames 2,4,6,8 (offset frames)
    print("  Processing shadows...")
    
    local shadow00FilePath = shadowPath .. "/shadow_00_" .. collateral .. ".aseprite"
    local shadow01FilePath = shadowPath .. "/shadow_01_" .. collateral .. ".aseprite"
    
    -- Calculate grid positions
    local row = viewIdx - 1
    local frameNumNormal = (viewIdx * 2) - 1
    local frameNumOffset = viewIdx * 2
    local xNormal = 0 * FRAME_WIDTH
    local yNormal = row * FRAME_HEIGHT
    local xOffset = 1 * FRAME_WIDTH
    local yOffset = row * FRAME_HEIGHT
    
    -- Process shadow_00 for normal frame
    if app.fs.isFile(shadow00FilePath) then
        local shadow00Sprite = nil
        local ok, err = pcall(function()
            shadow00Sprite = app.open(shadow00FilePath)
        end)
        
        if ok and shadow00Sprite then
            app.activeSprite = shadow00Sprite
            
            local shadow00Frame = nil
            local shadow00LayerSrc = nil
            local shadow00Cel = nil
            
            ok, err = pcall(function()
                if #shadow00Sprite.frames > 0 then
                    shadow00Frame = shadow00Sprite.frames[1]
                end
                if #shadow00Sprite.layers > 0 then
                    shadow00LayerSrc = shadow00Sprite.layers[1]
                end
                if shadow00Frame and shadow00LayerSrc then
                    shadow00Cel = shadow00LayerSrc:cel(shadow00Frame)
                end
            end)
            
            if ok and shadow00Cel and shadow00Cel.image then
                app.activeSprite = sheetSprite
                
                local shadowLayerNameNormal = viewInfo.name .. " - Shadow_00 (Frame " .. frameNumNormal .. ")"
                print("  Creating shadow layer: " .. shadowLayerNameNormal)
                local shadowLayerNormal = sheetSprite:newLayer(shadowLayerNameNormal)
                shadowLayerNormal.name = shadowLayerNameNormal  -- Explicitly set layer name
                
                local shadowImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                shadowImageNormal:drawImage(shadow00Cel.image, Point(xNormal, yNormal))
                sheetSprite:newCel(shadowLayerNormal, sheetFrame, shadowImageNormal)
                shadowImageNormal = nil
                print("  Normal shadow positioned at (" .. xNormal .. ", " .. yNormal .. ")")
                
                shadow00Cel = nil
            end
            
            pcall(function()
                app.activeSprite = shadow00Sprite
                app.command.CloseFile()
            end)
            shadow00Sprite = nil
            app.activeSprite = sheetSprite
            collectgarbage("step")
        end
    end
    
    -- Process shadow_01 for offset frame
    if app.fs.isFile(shadow01FilePath) then
        local shadow01Sprite = nil
        local ok, err = pcall(function()
            shadow01Sprite = app.open(shadow01FilePath)
        end)
        
        if ok and shadow01Sprite then
            app.activeSprite = shadow01Sprite
            
            local shadow01Frame = nil
            local shadow01LayerSrc = nil
            local shadow01Cel = nil
            
            ok, err = pcall(function()
                if #shadow01Sprite.frames > 0 then
                    shadow01Frame = shadow01Sprite.frames[1]
                end
                if #shadow01Sprite.layers > 0 then
                    shadow01LayerSrc = shadow01Sprite.layers[1]
                end
                if shadow01Frame and shadow01LayerSrc then
                    shadow01Cel = shadow01LayerSrc:cel(shadow01Frame)
                end
            end)
            
            if ok and shadow01Cel and shadow01Cel.image then
                app.activeSprite = sheetSprite
                
                local shadowLayerNameOffset = viewInfo.name .. " - Shadow_01 (Frame " .. frameNumOffset .. ", y=-1)"
                print("  Creating shadow layer: " .. shadowLayerNameOffset)
                local shadowLayerOffset = sheetSprite:newLayer(shadowLayerNameOffset)
                shadowLayerOffset.name = shadowLayerNameOffset  -- Explicitly set layer name
                
                local shadowImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                shadowImageOffset:drawImage(shadow01Cel.image, Point(xOffset, yOffset))
                sheetSprite:newCel(shadowLayerOffset, sheetFrame, shadowImageOffset)
                shadowImageOffset = nil
                print("  Offset shadow positioned at (" .. xOffset .. ", " .. yOffset .. ")")
                
                shadow01Cel = nil
            end
            
            pcall(function()
                app.activeSprite = shadow01Sprite
                app.command.CloseFile()
            end)
            shadow01Sprite = nil
            app.activeSprite = sheetSprite
            collectgarbage("step")
        end
    end
    
    -- Force garbage collection after each view
    collectgarbage("collect")
    
    print("")
end

-- Save the sprite sheet
local outputPath = assetsPath .. "/Output/aavegotchi-sprites-" .. collateral:lower() .. ".aseprite"
print("Saving to: " .. outputPath)
sheetSprite:saveAs(outputPath)
print("Saved successfully")

print("")
print("SUCCESS: Sprite sheet created!")
print("Dimensions: " .. sheetSprite.width .. "x" .. sheetSprite.height)
print("Frames: " .. #sheetSprite.frames)
print("Layers: " .. #sheetSprite.layers)

-- List all layers
for i, layer in ipairs(sheetSprite.layers) do
    print("  Layer " .. i .. ": " .. (layer.name or "unnamed"))
end

print("")
print("=== Complete ===")
