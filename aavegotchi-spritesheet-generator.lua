-- Aavegotchi Sprite Sheet Generator
-- Reusable module for generating layered sprite sheets

local FRAME_WIDTH = 64
local FRAME_HEIGHT = 64

local SpriteSheetGenerator = {}

-- Generate a sprite sheet for a given collateral
function SpriteSheetGenerator.generateSpriteSheet(assetsPath, collateral)
    print("=== Aavegotchi Sprite Sheet Generator ===")
    print("Collateral: " .. collateral)
    print("")
    
    -- Save original active sprite (for GUI mode)
    local originalActiveSprite = app.activeSprite
    
    -- Determine paths
    local bodyPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/body"
    local handsPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/hands"
    local collateralPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/collateral"
    local shadowPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/shadow"
    
    -- Build view configuration based on collateral naming
    local collateralLower = collateral:lower()
    local views = {
        {name = "Front", viewIndex = 0, bodyFileName = "body_front_" .. collateralLower .. ".aseprite", handFileName = "hands_down_open_" .. collateral .. ".aseprite", collateralFileName = "collateral_front_" .. collateral .. ".aseprite"},
        {name = "Left", viewIndex = 1, bodyFileName = "body_left_" .. collateralLower .. ".aseprite", handFileName = "hands_left_" .. collateral .. ".aseprite", collateralFileName = "collateral_left_" .. collateral .. ".aseprite"},
        {name = "Right", viewIndex = 2, bodyFileName = "body_right_" .. collateralLower .. ".aseprite", handFileName = "hands_right_" .. collateral .. ".aseprite", collateralFileName = "collateral_right_" .. collateral .. ".aseprite"},
        {name = "Back", viewIndex = 3, bodyFileName = "body_back_" .. collateralLower .. ".aseprite", handFileName = "hands_down_open_" .. collateral .. ".aseprite", collateralFileName = nil}  -- No collateral for back view
    }
    
    -- Create sprite sheet: 2x4 grid = 128x256
    local sheetWidth = FRAME_WIDTH * 2
    local sheetHeight = FRAME_HEIGHT * 4
    
    print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
    local sheetSprite = nil
    local ok, err = pcall(function()
        sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
        app.activeSprite = sheetSprite
    end)
    
    if not ok or not sheetSprite then
        return nil, "Failed to create sprite: " .. (err or "Unknown error")
    end
    
    -- Get the first frame
    local sheetFrame = nil
    ok, err = pcall(function()
        if #sheetSprite.frames > 0 then
            sheetFrame = sheetSprite.frames[1]
        end
    end)
    
    if not ok or not sheetFrame then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "No frame found"
    end
    
    -- Remove default layer if it exists
    ok, err = pcall(function()
        app.activeSprite = sheetSprite
        if #sheetSprite.layers > 0 then
            local defaultLayer = sheetSprite.layers[1]
            sheetSprite:deleteLayer(defaultLayer)
        end
    end)
    
    -- Process each view (creates 2 frames per view: normal and offset)
    for viewIdx, viewInfo in ipairs(views) do
        local bodyFilePath = bodyPath .. "/" .. viewInfo.bodyFileName
        local handFilePath = handsPath .. "/" .. viewInfo.handFileName
        local collateralFilePath = viewInfo.collateralFileName and (collateralPath .. "/" .. viewInfo.collateralFileName) or nil
        
        print("Processing " .. viewInfo.name .. " view...")
        
        -- Check if file exists
        if not app.fs.isFile(bodyFilePath) then
            print("  WARNING: File not found: " .. bodyFilePath)
            print("  Skipping this view")
        else
            -- Load the body sprite
            local bodySprite = nil
            ok, err = pcall(function()
                bodySprite = app.open(bodyFilePath)
            end)
            
            if not ok or not bodySprite then
                print("  ERROR: Failed to open body sprite: " .. (err or "Unknown error"))
            else
                app.activeSprite = bodySprite
                
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
                    
                    -- FIRST: Create shadow layers (they should be at the bottom/behind everything)
                    local shadow00FilePath = shadowPath .. "/shadow_00_" .. collateral .. ".aseprite"
                    local shadow01FilePath = shadowPath .. "/shadow_01_" .. collateral .. ".aseprite"
                    
                    -- Process shadow_00 for normal frame
                    if app.fs.isFile(shadow00FilePath) then
                        local shadow00Sprite = nil
                        ok, err = pcall(function()
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
                                local shadowLayerNormal = sheetSprite:newLayer(shadowLayerNameNormal)
                                shadowLayerNormal.name = shadowLayerNameNormal
                                
                                local shadowImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                                shadowImageNormal:drawImage(shadow00Cel.image, Point(xNormal, yNormal))
                                sheetSprite:newCel(shadowLayerNormal, sheetFrame, shadowImageNormal)
                                shadowImageNormal = nil
                                
                                shadow00Cel = nil
                            end
                            
                            pcall(function() app.activeSprite = shadow00Sprite; app.command.CloseFile() end)
                            shadow00Sprite = nil
                            app.activeSprite = sheetSprite
                            collectgarbage("step")
                        end
                    end
                    
                    -- Process shadow_01 for offset frame
                    if app.fs.isFile(shadow01FilePath) then
                        local shadow01Sprite = nil
                        ok, err = pcall(function()
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
                                local shadowLayerNameOffset = viewInfo.name .. " - Shadow_01 (Frame " .. frameNumOffset .. ")"
                                local shadowLayerOffset = sheetSprite:newLayer(shadowLayerNameOffset)
                                shadowLayerOffset.name = shadowLayerNameOffset
                                
                                local shadowImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                                shadowImageOffset:drawImage(shadow01Cel.image, Point(xOffset, yOffset))
                                sheetSprite:newCel(shadowLayerOffset, sheetFrame, shadowImageOffset)
                                shadowImageOffset = nil
                                
                                shadow01Cel = nil
                            end
                            
                            pcall(function() app.activeSprite = shadow01Sprite; app.command.CloseFile() end)
                            shadow01Sprite = nil
                            app.activeSprite = sheetSprite
                            collectgarbage("step")
                        end
                    end
                    
                    -- SECOND: Create body layers
                    local layerNameNormal = viewInfo.name .. " - Body (Frame " .. frameNumNormal .. ")"
                    local bodyLayerNormal = sheetSprite:newLayer(layerNameNormal)
                    bodyLayerNormal.name = layerNameNormal
                    
                    local layerImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    layerImageNormal:drawImage(bodyCel.image, Point(xNormal, yNormal))
                    sheetSprite:newCel(bodyLayerNormal, sheetFrame, layerImageNormal)
                    layerImageNormal = nil
                    
                    local layerNameOffset = viewInfo.name .. " - Body (Frame " .. frameNumOffset .. ", y=-1)"
                    local bodyLayerOffset = sheetSprite:newLayer(layerNameOffset)
                    bodyLayerOffset.name = layerNameOffset
                    
                    local layerImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    layerImageOffset:drawImage(bodyCel.image, Point(xOffset, yOffset - 1))
                    sheetSprite:newCel(bodyLayerOffset, sheetFrame, layerImageOffset)
                    layerImageOffset = nil
                    
                    bodyCel = nil
                end
                
                pcall(function()
                    app.activeSprite = bodySprite
                    app.command.CloseFile()
                end)
                bodySprite = nil
                app.activeSprite = sheetSprite
                collectgarbage("step")
            end
        end
        
        -- Process hands
        if app.fs.isFile(handFilePath) then
            local handSprite = nil
            ok, err = pcall(function()
                handSprite = app.open(handFilePath)
            end)
            
            if ok and handSprite then
                app.activeSprite = handSprite
                
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
                
                if ok and handCel and handCel.image then
                    app.activeSprite = sheetSprite
                    
                    local row = viewIdx - 1
                    local frameNumNormal = (viewIdx * 2) - 1
                    local frameNumOffset = viewIdx * 2
                    local xNormal = 0 * FRAME_WIDTH
                    local yNormal = row * FRAME_HEIGHT
                    local xOffset = 1 * FRAME_WIDTH
                    local yOffset = row * FRAME_HEIGHT
                    
                    local handLayerNameNormal = viewInfo.name .. " - Hands (Frame " .. frameNumNormal .. ")"
                    local handLayerNormal = sheetSprite:newLayer(handLayerNameNormal)
                    handLayerNormal.name = handLayerNameNormal
                    
                    local handImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    handImageNormal:drawImage(handCel.image, Point(xNormal, yNormal))
                    sheetSprite:newCel(handLayerNormal, sheetFrame, handImageNormal)
                    handImageNormal = nil
                    
                    local handLayerNameOffset = viewInfo.name .. " - Hands (Frame " .. frameNumOffset .. ", y=-1)"
                    local handLayerOffset = sheetSprite:newLayer(handLayerNameOffset)
                    handLayerOffset.name = handLayerNameOffset
                    
                    local handImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    handImageOffset:drawImage(handCel.image, Point(xOffset, yOffset - 1))
                    sheetSprite:newCel(handLayerOffset, sheetFrame, handImageOffset)
                    handImageOffset = nil
                    
                    handCel = nil
                end
                
                pcall(function() app.activeSprite = handSprite; app.command.CloseFile() end)
                handSprite = nil
                app.activeSprite = sheetSprite
                collectgarbage("step")
            end
        end
        
        -- Process collateral (skip for back view)
        if collateralFilePath and app.fs.isFile(collateralFilePath) then
            local collateralSprite = nil
            ok, err = pcall(function()
                collateralSprite = app.open(collateralFilePath)
            end)
            
            if ok and collateralSprite then
                app.activeSprite = collateralSprite
                
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
                
                if ok and collateralCel and collateralCel.image then
                    app.activeSprite = sheetSprite
                    
                    local row = viewIdx - 1
                    local frameNumNormal = (viewIdx * 2) - 1
                    local frameNumOffset = viewIdx * 2
                    local xNormal = 0 * FRAME_WIDTH
                    local yNormal = row * FRAME_HEIGHT
                    local xOffset = 1 * FRAME_WIDTH
                    local yOffset = row * FRAME_HEIGHT
                    
                    local collateralLayerNameNormal = viewInfo.name .. " - Collateral (Frame " .. frameNumNormal .. ")"
                    local collateralLayerNormal = sheetSprite:newLayer(collateralLayerNameNormal)
                    collateralLayerNormal.name = collateralLayerNameNormal
                    
                    local collateralImageNormal = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    collateralImageNormal:drawImage(collateralCel.image, Point(xNormal, yNormal))
                    sheetSprite:newCel(collateralLayerNormal, sheetFrame, collateralImageNormal)
                    collateralImageNormal = nil
                    
                    local collateralLayerNameOffset = viewInfo.name .. " - Collateral (Frame " .. frameNumOffset .. ", y=-1)"
                    local collateralLayerOffset = sheetSprite:newLayer(collateralLayerNameOffset)
                    collateralLayerOffset.name = collateralLayerNameOffset
                    
                    local collateralImageOffset = Image(sheetWidth, sheetHeight, ColorMode.RGB)
                    collateralImageOffset:drawImage(collateralCel.image, Point(xOffset, yOffset - 1))
                    sheetSprite:newCel(collateralLayerOffset, sheetFrame, collateralImageOffset)
                    collateralImageOffset = nil
                    
                    collateralCel = nil
                end
                
                pcall(function() app.activeSprite = collateralSprite; app.command.CloseFile() end)
                collateralSprite = nil
                app.activeSprite = sheetSprite
                collectgarbage("step")
            end
        end
        
        collectgarbage("collect")
    end
    
    -- Return the sprite (caller should save it)
    app.activeSprite = sheetSprite
    return sheetSprite, nil
end

return SpriteSheetGenerator

