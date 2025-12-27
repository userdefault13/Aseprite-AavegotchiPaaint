-- Aavegotchi Composer CLI Module
-- Reusable composition logic for both interactive and batch modes

local ComposerCLI = {}

-- Compose Aavegotchi from spritesheets
function ComposerCLI.composeFromSpritesheets(bodySprite, handsSprite, mouthSprite, eyesSprite, collateralSprite, assetsPath, outputPath)
    if not bodySprite then
        return nil, "Body sprite is required"
    end
    
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
    
    -- Create frames based on body sprite
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
    
    -- Copy collateral layers and cels (composite over body, under hands)
    if collateralSprite then
        print("Copying collateral layers...")
        for layerIdx, collateralLayer in ipairs(collateralSprite.layers) do
            local composedLayer = composedSprite:newLayer(collateralLayer.name)
            print("  Created layer: " .. collateralLayer.name)
            
            -- Collateral typically has 2 frames, use frame 1 for all frames
            local collateralFrame = collateralSprite.frames[1]
            local collateralCel = collateralLayer:cel(collateralFrame)
            
            if collateralCel and collateralCel.image then
                for frameIdx = 1, #composedSprite.frames do
                    local composedFrame = composedSprite.frames[frameIdx]
                    local composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
                    composedImage:drawImage(collateralCel.image, Point(0, 0))
                    composedSprite:newCel(composedLayer, composedFrame, composedImage)
                end
            end
        end
    end
    
    -- Copy hands layers and cels (composite over body and collateral)
    if handsSprite then
        print("Copying hands layers...")
        for layerIdx, handsLayer in ipairs(handsSprite.layers) do
            local composedLayer = composedSprite:newLayer(handsLayer.name)
            print("  Created layer: " .. handsLayer.name)
            
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
                        composedImage = composedCel.image
                    else
                        composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
                    end
                    
                    composedImage:drawImage(handsCel.image, Point(0, 0))
                    
                    if not composedCel then
                        composedSprite:newCel(composedLayer, composedFrame, composedImage)
                    end
                end
            end
        end
    end
    
    -- Copy eyes layers and cels (composite over hands)
    if eyesSprite then
        print("Copying eyes layers...")
        for layerIdx, eyesLayer in ipairs(eyesSprite.layers) do
            local composedLayer = composedSprite:newLayer(eyesLayer.name)
            print("  Created layer: " .. eyesLayer.name)
            
            local maxEyesFrame = #eyesSprite.frames
            
            for frameIdx = 1, #composedSprite.frames do
                local eyesFrameIdx = math.min(frameIdx, maxEyesFrame)
                local eyesFrame = eyesSprite.frames[eyesFrameIdx]
                local eyesCel = eyesLayer:cel(eyesFrame)
                
                if eyesCel and eyesCel.image then
                    local composedFrame = composedSprite.frames[frameIdx]
                    local composedCel = composedLayer:cel(composedFrame)
                    local composedImage = nil
                    
                    if composedCel and composedCel.image then
                        composedImage = composedCel.image
                    else
                        composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
                    end
                    
                    composedImage:drawImage(eyesCel.image, Point(0, 0))
                    
                    if not composedCel then
                        composedSprite:newCel(composedLayer, composedFrame, composedImage)
                    end
                end
            end
        end
    end
    
    -- Copy mouth layers and cels (composite on top of everything)
    if mouthSprite then
        print("Copying mouth layers...")
        for layerIdx, mouthLayer in ipairs(mouthSprite.layers) do
            local composedLayer = composedSprite:newLayer(mouthLayer.name)
            print("  Created layer: " .. mouthLayer.name)
            
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
                        composedImage = composedCel.image
                    else
                        composedImage = Image(composedSprite.width, composedSprite.height, ColorMode.RGB)
                    end
                    
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
    if outputPath then
        app.activeSprite = composedSprite
        composedSprite:saveAs(outputPath)
        print("Saved to: " .. outputPath)
    end
    
    return composedSprite, nil
end

-- Load sprite from file path
function ComposerCLI.loadSprite(filePath)
    if not filePath or not app.fs.isFile(filePath) then
        return nil, "File not found: " .. (filePath or "nil")
    end
    
    local sprite = app.open(filePath)
    if not sprite then
        return nil, "Failed to load sprite: " .. filePath
    end
    
    return sprite, nil
end

-- Close sprite safely
function ComposerCLI.closeSprite(sprite)
    if sprite then
        pcall(function()
            app.activeSprite = sprite
            app.command.CloseFile()
        end)
    end
end

return ComposerCLI

