-- Sprite Sheet Generator
-- Generates sprite sheets organized like Zelda reference
-- Each row = one animation, frames arranged horizontally

-- Helper to resolve script paths (works in both GUI and CLI)
local function resolveScriptPath(scriptName)
    -- Try relative path first (for GUI mode)
    if app.fs.isFile(scriptName) then
        return scriptName
    end
    -- Try absolute path (for CLI mode)
    local absolutePath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint/" .. scriptName
    if app.fs.isFile(absolutePath) then
        return absolutePath
    end
    -- Fallback to relative
    return scriptName
end

local Composer = dofile(resolveScriptPath("aavegotchi-composer.lua"))
local FileResolver = dofile(resolveScriptPath("file-resolver.lua"))

local SpriteSheetGenerator = {}

-- Frame size constants
local FRAME_WIDTH = 64
local FRAME_HEIGHT = 64

-- Animation row definitions
local ANIMATION_ROWS = {
    {name = "idle", frames = 2, view = 0},  -- Front view
    {name = "down", frames = 2, view = 0},  -- Front view
    {name = "left", frames = 2, view = 1},  -- Left view
    {name = "right", frames = 2, view = 2}, -- Right view
    {name = "up", frames = 2, view = 3},    -- Back view
    {name = "use_items_front", frames = 4, view = 0},
    {name = "use_items_left", frames = 4, view = 1},
    {name = "use_items_right", frames = 4, view = 2},
    {name = "use_items_back", frames = 4, view = 3}
}

-- Eye rarity definitions (6 rarities)
local EYE_RARITIES = {
    "common",
    "uncommon_low",
    "uncommon_high",
    "rare_low",
    "rare_high",
    "mythical_low"
}

-- Resolve shadow .aseprite file path by index
local function resolveShadowPathByIndex(assetsPath, collateral, shadowIndex)
    local shadowIndexPadded = string.format("%02d", shadowIndex)
    local shadowPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/shadow/shadow_" .. shadowIndexPadded .. "_" .. collateral .. ".aseprite"
    return shadowPath
end

-- Apply Y-offset to a sprite by translating specific layers (body, hands, collateral)
local function applyYOffset(sprite, yOffset)
    if yOffset == 0 then
        return true, nil
    end
    
    -- Get the first frame
    local frame = sprite.frames[1]
    if not frame then
        return false, "Sprite has no frames"
    end
    
    -- Translate body, hands, and collateral layers (not shadow, eyes, mouth, wearables)
    local layersToOffset = {"Body", "Hands", "Collateral"}
    for _, layer in ipairs(sprite.layers) do
        if layer.name then
            local shouldOffset = false
            for _, namePattern in ipairs(layersToOffset) do
                if layer.name:match(namePattern) then
                    shouldOffset = true
                    break
                end
            end
            
            if shouldOffset then
                local cel = layer:cel(frame)
                if cel and cel.image then
                    -- Create new image with offset
                    local newImage = Image(sprite.width, sprite.height, ColorMode.RGB)
                    newImage:drawImage(cel.image, Point(0, yOffset))
                    cel.image = newImage
                end
            end
        end
    end
    
    return true, nil
end

-- Generate a single frame
function SpriteSheetGenerator.generateFrame(config, frameIndex, shadowIndex, yOffset, assetsPath, excludeEyes)
    -- Load shadow .aseprite file directly
    local shadowPath = resolveShadowPathByIndex(assetsPath, config.collateral, shadowIndex)
    
    if not app.fs.isFile(shadowPath) then
        return nil, "Shadow file not found: " .. shadowPath
    end
    
    local shadowSprite = app.open(shadowPath)
    if not shadowSprite then
        return nil, "Failed to open shadow file: " .. shadowPath
    end
    
    -- Determine hand pose based on animation type and frame
    local handPose = config.handPose or "down_open"
    if config.animationType and config.animationType:match("use_items") then
        -- Cycle through hand poses for use items
        local poses = {"down_closed", "down_open", "up", "down_open"}
        handPose = poses[(frameIndex % #poses) + 1]
    end
    
    -- Create config for composer
    local composerConfig = {
        collateral = config.collateral,
        view = config.view or 0,
        handPose = handPose,
        eyeRange = config.eyeRange,
        eyeRarity = config.eyeRarity,
        eyeExpression = config.eyeExpression or "happy",
        mouthExpression = config.mouthExpression or "neutral",
        wearables = config.wearables or {},
        canvasSize = FRAME_WIDTH
    }
    
    -- Generate frame using composer
    local result = Composer.composeAavegotchi(composerConfig, assetsPath, config.wearablesWithNames)
    if not result.success then
        -- Clean up shadow sprite
        if shadowSprite then
            pcall(function() app.activeSprite = shadowSprite; app.command.CloseFile() end)
        end
        return nil, "Composer failed: " .. table.concat(result.errors, ", ")
    end
    
    local sprite = result.sprite
    
    -- Replace shadow with our specific shadow frame
    -- Find or create shadow layer
    local shadowLayer = nil
    for _, layer in ipairs(sprite.layers) do
        if layer.name and layer.name:match("Shadow") then
            shadowLayer = layer
            break
        end
    end
    
    -- Create shadow layer if it doesn't exist
    if not shadowLayer then
        shadowLayer = sprite:newLayer("Shadow (" .. config.collateral .. ")")
    end
    
    -- Get or create cel for shadow
    local targetFrame = sprite.frames[1]
    if not targetFrame then
        targetFrame = sprite:newFrame(1)
    end
    
    local targetCel = shadowLayer:cel(targetFrame)
    if not targetCel then
        local shadowImage = Image(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
        targetCel = sprite:newCel(shadowLayer, targetFrame, shadowImage)
    end
    
    -- Replace shadow image
    local shadowCel = shadowSprite.layers[1]:cel(shadowSprite.frames[1])
    if shadowCel and shadowCel.image then
        -- Create new image and draw shadow on it (replaces old shadow)
        local newImage = Image(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
        newImage:drawImage(shadowCel.image, Point(0, 0))
        targetCel.image = newImage
    end
    
    -- Clean up shadow sprite immediately after use
    if shadowSprite then
        pcall(function() 
            app.activeSprite = shadowSprite
            app.command.CloseFile()
        end)
        shadowSprite = nil  -- Clear reference
    end
    
    -- Force garbage collection to free memory
    collectgarbage("collect")
    
    -- Apply Y-offset
    local offsetSuccess, offsetErr = applyYOffset(sprite, yOffset)
    if not offsetSuccess then
        return nil, "Failed to apply Y-offset: " .. (offsetErr or "Unknown error")
    end
    
    -- Remove eyes layer if excludeEyes is true
    if excludeEyes then
        for i = #sprite.layers, 1, -1 do
            local layer = sprite.layers[i]
            if layer.name and layer.name:match("Eyes") then
                sprite:deleteLayer(layer)
            end
        end
    end
    
    return sprite, nil
end

-- Generate all frames for an animation row
function SpriteSheetGenerator.generateAnimationRow(animationType, config, assetsPath, excludeEyes)
    local rowDef = nil
    for _, def in ipairs(ANIMATION_ROWS) do
        if def.name == animationType then
            rowDef = def
            break
        end
    end
    
    if not rowDef then
        return nil, "Unknown animation type: " .. animationType
    end
    
    local frames = {}
    local numFrames = rowDef.frames
    local view = rowDef.view
    
    -- Update config with view
    local rowConfig = {}
    for k, v in pairs(config) do
        rowConfig[k] = v
    end
    rowConfig.view = view
    rowConfig.animationType = animationType
    
    for frameIndex = 0, numFrames - 1 do
        local shadowIndex = frameIndex % 2  -- Alternate between shadow 0 and 1
        local yOffset = (frameIndex % 2 == 1) and -1 or 0  -- Frame 1, 3, etc. get Y-offset
        
        local sprite, err = SpriteSheetGenerator.generateFrame(rowConfig, frameIndex, shadowIndex, yOffset, assetsPath, excludeEyes)
        if not sprite then
            -- Clean up already generated frames
            for _, f in ipairs(frames) do
                pcall(function() app.activeSprite = f; app.command.CloseFile() end)
            end
            return nil, "Failed to generate frame " .. frameIndex .. ": " .. (err or "Unknown error")
        end
        
        table.insert(frames, sprite)
        
        -- Force garbage collection periodically to prevent memory buildup
        if frameIndex % 4 == 0 then
            collectgarbage("collect")
        end
    end
    
    return frames, nil
end

-- Arrange frames into a sprite sheet grid
function SpriteSheetGenerator.arrangeFramesIntoSheet(frameRows)
    if not frameRows or #frameRows == 0 then
        return nil, "No frame rows provided"
    end
    
    -- Calculate dimensions
    local maxFrames = 0
    for _, row in ipairs(frameRows) do
        if #row > maxFrames then
            maxFrames = #row
        end
    end
    
    local numRows = #frameRows
    local sheetWidth = maxFrames * FRAME_WIDTH
    local sheetHeight = numRows * FRAME_HEIGHT
    
    -- Create new sprite for the sheet
    local sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
    app.activeSprite = sheetSprite
    
    -- Remove default layer
    if #sheetSprite.layers > 0 then
        sheetSprite:deleteLayer(sheetSprite.layers[1])
    end
    
    -- Create a single layer for the sheet
    local sheetLayer = sheetSprite:newLayer("Sprite Sheet")
    local sheetFrame = sheetSprite:newFrame(1)
    local sheetImage = Image(sheetWidth, sheetHeight, ColorMode.RGB)
    local sheetCel = sheetSprite:newCel(sheetLayer, sheetFrame, sheetImage)
    
    -- Copy each frame to its position
    for rowIndex, row in ipairs(frameRows) do
        for colIndex, frameSprite in ipairs(row) do
            -- Flatten all layers of the frame into a single image
            local frameImage = Image(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
            local frameFrame = frameSprite.frames[1]
            
            if frameFrame then
                -- Draw all layers onto the frame image
                for _, layer in ipairs(frameSprite.layers) do
                    local cel = layer:cel(frameFrame)
                    if cel and cel.image then
                        frameImage:drawImage(cel.image, Point(0, 0))
                    end
                end
                
                -- Calculate position
                local x = (colIndex - 1) * FRAME_WIDTH
                local y = (rowIndex - 1) * FRAME_HEIGHT
                
                -- Draw frame onto sheet
                sheetImage:drawImage(frameImage, Point(x, y))
            end
        end
    end
    
    return sheetSprite, nil
end

-- Export sprite as PNG
local function exportAsPng(sprite, outputPath)
    -- Store original sprite
    local originalSprite = app.activeSprite
    
    -- Set sprite as active
    app.activeSprite = sprite
    
    -- Export as PNG
    -- Note: Aseprite's saveAs with .png extension should work, but if it doesn't,
    -- the user may need to manually export or use File > Export Sprite Sheet
    local success, err = pcall(function()
        sprite:saveAs(outputPath)
    end)
    
    -- Restore original sprite
    if originalSprite then
        app.activeSprite = originalSprite
    end
    
    if not success then
        return false, "Failed to export PNG file: " .. tostring(err) .. ". You may need to manually export the sprite sheet."
    end
    
    return true, nil
end

-- Generate complete sprite sheet
function SpriteSheetGenerator.generateSpriteSheet(config, outputPath, assetsPath, excludeEyes)
    if not config.collateral then
        return false, "Collateral not specified in config"
    end
    
    assetsPath = assetsPath or config.assetsPath
    if not assetsPath then
        return false, "Assets path not specified"
    end
    
    local frameRows = {}
    
    -- Generate each animation row
    for _, rowDef in ipairs(ANIMATION_ROWS) do
        local frames, err = SpriteSheetGenerator.generateAnimationRow(rowDef.name, config, assetsPath, excludeEyes)
        if not frames then
            -- Clean up already generated rows
            for _, row in ipairs(frameRows) do
                for _, sprite in ipairs(row) do
                    pcall(function() app.activeSprite = sprite; app.command.CloseFile() end)
                end
            end
            return false, "Failed to generate " .. rowDef.name .. ": " .. (err or "Unknown error")
        end
        
        table.insert(frameRows, frames)
    end
    
    -- Arrange into sprite sheet
    local sheetSprite, err = SpriteSheetGenerator.arrangeFramesIntoSheet(frameRows)
    if not sheetSprite then
        -- Clean up frames
        for _, row in ipairs(frameRows) do
            for _, sprite in ipairs(row) do
                pcall(function() app.activeSprite = sprite; app.command.CloseFile() end)
            end
        end
        return false, "Failed to arrange frames: " .. (err or "Unknown error")
    end
    
    -- Clean up individual frame sprites immediately after arranging
    for _, row in ipairs(frameRows) do
        for _, sprite in ipairs(row) do
            pcall(function() 
                app.activeSprite = sprite
                app.command.CloseFile()
            end)
        end
    end
    frameRows = nil  -- Clear reference
    
    -- Force garbage collection before export
    collectgarbage("collect")
    
    -- Export as PNG
    local exportSuccess, exportErr = exportAsPng(sheetSprite, outputPath)
    if not exportSuccess then
        pcall(function() app.activeSprite = sheetSprite; app.command.CloseFile() end)
        return false, "Failed to export PNG: " .. (exportErr or "Unknown error")
    end
    
    -- Close sheet sprite
    pcall(function() app.activeSprite = sheetSprite; app.command.CloseFile() end)
    
    return true, nil
end

-- Generate body sprite sheets for all collaterals (without eyes)
function SpriteSheetGenerator.generateAllCollateralBodySpriteSheets(assetsPath, outputDir, baseConfig)
    local collaterals = FileResolver.scanForCollaterals(assetsPath)
    if not collaterals or #collaterals == 0 then
        return {}, "No collaterals found"
    end
    
    -- Ensure output directory exists (Aseprite API might not support directory creation)
    -- User should ensure the directory exists before calling
    
    local results = {}
    
    for _, collateral in ipairs(collaterals) do
        -- Create config for this collateral
        local config = {}
        for k, v in pairs(baseConfig) do
            config[k] = v
        end
        config.collateral = collateral
        config.assetsPath = assetsPath
        
        -- Generate output path
        local collateralLower = collateral:lower()
        local outputPath = app.fs.joinPath(outputDir, collateralLower .. "-body-sprite-sheet.png")
        
        -- Generate sprite sheet (exclude eyes)
        local success, err = SpriteSheetGenerator.generateSpriteSheet(config, outputPath, assetsPath, true)
        
        results[collateral] = {
            success = success,
            error = err,
            outputPath = outputPath
        }
        
        -- Force garbage collection after each collateral to prevent memory buildup
        collectgarbage("collect")
    end
    
    return results, nil
end

-- Generate a single eye-only frame
function SpriteSheetGenerator.generateEyeFrame(config, frameIndex, assetsPath)
    -- Create a minimal config for composer (we only need eyes)
    local composerConfig = {
        collateral = config.collateral or "amaave",  -- Default collateral, eyes are the same across collaterals
        view = config.view or 0,
        handPose = "down_open",  -- Doesn't matter for eyes
        eyeRange = config.eyeRange,
        eyeRarity = config.eyeRarity,
        eyeExpression = config.eyeExpression or "happy",
        mouthExpression = "neutral",  -- Doesn't matter for eyes
        wearables = {},
        canvasSize = FRAME_WIDTH
    }
    
    -- Generate frame using composer
    local result = Composer.composeAavegotchi(composerConfig, assetsPath, {})
    if not result.success then
        return nil, "Composer failed: " .. table.concat(result.errors, ", ")
    end
    
    local sprite = result.sprite
    
    -- Extract only the eyes layer
    local eyesLayer = nil
    for _, layer in ipairs(sprite.layers) do
        if layer.name and layer.name:match("Eyes") then
            eyesLayer = layer
            break
        end
    end
    
    -- Create new sprite with only eyes
    local eyeSprite = Sprite(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
    app.activeSprite = eyeSprite
    
    -- Remove default layer
    if #eyeSprite.layers > 0 then
        eyeSprite:deleteLayer(eyeSprite.layers[1])
    end
    
    -- Create transparent background layer
    local bgLayer = eyeSprite:newLayer("Background")
    local bgFrame = eyeSprite:newFrame(1)
    local bgImage = Image(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
    local bgCel = eyeSprite:newCel(bgLayer, bgFrame, bgImage)
    
    -- Copy eyes layer if it exists
    if eyesLayer then
        local eyeLayer = eyeSprite:newLayer("Eyes")
        local eyeFrame = eyeSprite.frames[1]
        local eyeCel = eyesLayer:cel(sprite.frames[1])
        if eyeCel and eyeCel.image then
            local eyeImage = Image(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
            eyeImage:drawImage(eyeCel.image, Point(0, 0))
            eyeSprite:newCel(eyeLayer, eyeFrame, eyeImage)
        end
    end
    
    -- Clean up original sprite
    pcall(function() app.activeSprite = sprite; app.command.CloseFile() end)
    
    return eyeSprite, nil
end

-- Generate eye sprite sheet for a specific eyeRange with all 6 rarities
-- Structure: 54 rows total (9 animation rows × 6 rarities)
function SpriteSheetGenerator.generateEyeSpriteSheet(eyeRange, assetsPath, outputPath)
    if not eyeRange then
        return false, "Eye range not specified"
    end
    
    if not assetsPath then
        return false, "Assets path not specified"
    end
    
    -- Get a collateral to use (eyes are the same across collaterals, but we need one for path resolution)
    local collaterals = FileResolver.scanForCollaterals(assetsPath)
    if not collaterals or #collaterals == 0 then
        return false, "No collaterals found"
    end
    local collateral = collaterals[1]  -- Use first available collateral
    
    local frameRows = {}
    
    -- Generate rows for each rarity (6 rarities)
    for rarityIndex, rarity in ipairs(EYE_RARITIES) do
        -- Generate all 9 animation rows for this rarity
        for _, rowDef in ipairs(ANIMATION_ROWS) do
            local frames = {}
            local numFrames = rowDef.frames
            local view = rowDef.view
            
            -- For back view, create empty transparent frames
            if view == 3 then  -- Back view
                for frameIndex = 0, numFrames - 1 do
                    local emptySprite = Sprite(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
                    app.activeSprite = emptySprite
                    if #emptySprite.layers > 0 then
                        emptySprite:deleteLayer(emptySprite.layers[1])
                    end
                    local bgLayer = emptySprite:newLayer("Background")
                    local bgFrame = emptySprite:newFrame(1)
                    local bgImage = Image(FRAME_WIDTH, FRAME_HEIGHT, ColorMode.RGB)
                    emptySprite:newCel(bgLayer, bgFrame, bgImage)
                    table.insert(frames, emptySprite)
                end
            else
                -- Generate frames with eyes
                for frameIndex = 0, numFrames - 1 do
                    local eyeConfig = {
                        collateral = collateral,
                        eyeRange = eyeRange,
                        eyeRarity = rarity,
                        view = view
                    }
                    
                    local eyeSprite, err = SpriteSheetGenerator.generateEyeFrame(eyeConfig, frameIndex, assetsPath)
                    if not eyeSprite then
                        -- Clean up already generated frames
                        for _, f in ipairs(frames) do
                            pcall(function() app.activeSprite = f; app.command.CloseFile() end)
                        end
                        -- Clean up already generated rows
                        for _, row in ipairs(frameRows) do
                            for _, sprite in ipairs(row) do
                                pcall(function() app.activeSprite = sprite; app.command.CloseFile() end)
                            end
                        end
                        return false, "Failed to generate eye frame for " .. eyeRange .. " " .. rarity .. " " .. rowDef.name .. ": " .. (err or "Unknown error")
                    end
                    
                    table.insert(frames, eyeSprite)
                end
            end
            
            table.insert(frameRows, frames)
        end
    end
    
    -- Arrange into sprite sheet
    local sheetSprite, err = SpriteSheetGenerator.arrangeFramesIntoSheet(frameRows)
    if not sheetSprite then
        -- Clean up frames
        for _, row in ipairs(frameRows) do
            for _, sprite in ipairs(row) do
                pcall(function() app.activeSprite = sprite; app.command.CloseFile() end)
            end
        end
        return false, "Failed to arrange frames: " .. (err or "Unknown error")
    end
    
    -- Clean up individual frame sprites immediately after arranging
    for _, row in ipairs(frameRows) do
        for _, sprite in ipairs(row) do
            pcall(function() 
                app.activeSprite = sprite
                app.command.CloseFile()
            end)
        end
    end
    frameRows = nil  -- Clear reference
    
    -- Force garbage collection before export
    collectgarbage("collect")
    
    -- Export as PNG
    local exportSuccess, exportErr = exportAsPng(sheetSprite, outputPath)
    if not exportSuccess then
        pcall(function() app.activeSprite = sheetSprite; app.command.CloseFile() end)
        return false, "Failed to export PNG: " .. (exportErr or "Unknown error")
    end
    
    -- Close sheet sprite
    pcall(function() app.activeSprite = sheetSprite; app.command.CloseFile() end)
    
    return true, nil
end

-- Generate eye sprite sheet for a specific eyeRange (includes all 6 rarities)
function SpriteSheetGenerator.generateEyeSpriteSheetForConfig(eyeRange, assetsPath, outputDir)
    if not eyeRange then
        return false, "Eye range not specified"
    end
    
    if not assetsPath then
        return false, "Assets path not specified"
    end
    
    -- Generate output path
    local eyeRangeSafe = eyeRange:gsub("[^%w%-_]", "_")  -- Sanitize for filename
    local outputPath = app.fs.joinPath(outputDir, eyeRangeSafe .. "-eye-sprite-sheet.png")
    
    -- Generate sprite sheet
    local success, err = SpriteSheetGenerator.generateEyeSpriteSheet(eyeRange, assetsPath, outputPath)
    
    if success then
        return true, nil, outputPath
    else
        return false, err, nil
    end
end

-- Generate eye sprite sheets for all eye ranges
function SpriteSheetGenerator.generateAllEyeRangeSpriteSheets(assetsPath, outputDir)
    if not assetsPath then
        return {}, "Assets path not specified"
    end
    
    -- Get a collateral to scan eye ranges (eyes are the same across collaterals)
    local collaterals = FileResolver.scanForCollaterals(assetsPath)
    if not collaterals or #collaterals == 0 then
        return {}, "No collaterals found"
    end
    local collateral = collaterals[1]  -- Use first available collateral
    
    -- Scan for all eye ranges
    local eyeRanges = FileResolver.scanEyeShapeRanges(assetsPath, collateral)
    if not eyeRanges or #eyeRanges == 0 then
        return {}, "No eye ranges found"
    end
    
    local results = {}
    
    for _, eyeRange in ipairs(eyeRanges) do
        local success, err, outputPath = SpriteSheetGenerator.generateEyeSpriteSheetForConfig(eyeRange, assetsPath, outputDir)
        
        results[eyeRange] = {
            success = success,
            error = err,
            outputPath = outputPath
        }
    end
    
    return results, nil
end

return SpriteSheetGenerator


