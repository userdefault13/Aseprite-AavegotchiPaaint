-- Aavegotchi Composer
-- Loads and composes .aseprite files into a complete Aavegotchi sprite

local FileResolver = dofile("file-resolver.lua")

local Composer = {}

-- Copy image from source sprite to target layer
local function copySpriteToLayer(sourceSprite, targetSprite, targetLayerName)
    if not sourceSprite or not targetSprite then
        return false, "Invalid sprites"
    end
    
    -- Get or create target layer
    local targetLayer = nil
    for _, layer in ipairs(targetSprite.layers) do
        if layer.name == targetLayerName then
            targetLayer = layer
            break
        end
    end
    
    if not targetLayer then
        targetLayer = targetSprite:newLayer(targetLayerName)
        if not targetLayer then
            return false, "Failed to create layer: " .. targetLayerName
        end
    end
    
    -- Get target frame (use first frame)
    local targetFrame = targetSprite.frames[1]
    if not targetFrame then
        targetFrame = targetSprite:newFrame(1)
    end
    
    -- Get source cel from first layer and first frame
    local sourceLayer = sourceSprite.layers[1]
    if not sourceLayer then
        return false, "Source sprite has no layers"
    end
    
    local sourceFrame = sourceSprite.frames[1]
    if not sourceFrame then
        return false, "Source sprite has no frames"
    end
    
    local sourceCel = sourceLayer:cel(sourceFrame)
    if not sourceCel or not sourceCel.image then
        return false, "Source sprite has no image data"
    end
    
    local sourceImage = sourceCel.image
    
    -- Get or create target cel
    local targetCel = targetLayer:cel(targetFrame)
    if not targetCel then
        -- Create new image for target cel (use source dimensions if different)
        local targetImage = Image(targetSprite.width, targetSprite.height, ColorMode.RGB)
        targetCel = targetSprite:newCel(targetLayer, targetFrame, targetImage)
    end
    
    local targetImage = targetCel.image
    
    -- Ensure both images are valid
    if not targetImage then
        return false, "Target image is nil"
    end
    if not sourceImage then
        return false, "Source image is nil"
    end
    
    -- Copy source image to target image, drawing at origin (0,0)
    -- Use drawImage to composite the source image onto the target
    targetImage:drawImage(sourceImage, Point(0, 0))
    
    return true, nil
end

-- Load sprite from file path and copy to target
local function loadAndCopySprite(filePath, targetSprite, targetLayerName)
    if not filePath then
        return false, "No file path provided"
    end
    
    if not app.fs.isFile(filePath) then
        return false, "File does not exist: " .. filePath
    end
    
    -- Store current sprite
    local originalSprite = app.activeSprite
    
    -- Load the source sprite using app.open
    local sourceSprite = app.open(filePath)
    
    if not sourceSprite then
        return false, "Could not open file: " .. filePath
    end
    
    -- Copy to target with error handling
    local success = true
    local errorMsg = nil
    
    local ok, err = pcall(function()
        -- Ensure target sprite is active before copying
        app.activeSprite = targetSprite
        
        local result, msg = copySpriteToLayer(sourceSprite, targetSprite, targetLayerName)
        if not result then
            error(msg or "Copy failed")
        end
    end)
    
    if not ok then
        success = false
        errorMsg = tostring(err)
    end
    
    -- Close the source sprite safely - wrap in pcall to prevent crashes
    pcall(function()
        -- Switch to source sprite if needed before closing
        if sourceSprite then
            -- Check if source sprite is still valid
            local currentSprite = app.activeSprite
            if currentSprite == sourceSprite then
                app.command.CloseFile()
            else
                -- Try to switch to source sprite and close
                app.activeSprite = sourceSprite
                app.command.CloseFile()
            end
        end
    end)
    
    -- Always restore the target sprite as active
    pcall(function()
        if targetSprite then
            app.activeSprite = targetSprite
        elseif originalSprite then
            app.activeSprite = originalSprite
        end
    end)
    
    return success, errorMsg
end

-- Compose Aavegotchi from configuration
-- config should contain: collateral, view, handPose, eyeRange, eyeRarity, mouthExpression, wearables, canvasSize
-- wearablesWithNames should be a table of {slot = {id = id, name = name}}
function Composer.composeAavegotchi(config, assetsPath, wearablesWithNames)
    local collateral = config.collateral
    local viewIndex = config.view or 0
    local handPose = config.handPose or "down_open"
    local eyeExpression = config.eyeExpression or "happy"
    local mouthExpression = config.mouthExpression or "neutral"
    local wearables = config.wearables or {}
    local canvasSize = config.canvasSize or 64
    
    -- Create new sprite
    local sprite = Sprite(canvasSize, canvasSize, ColorMode.RGB)
    app.activeSprite = sprite
    
    -- Remove default layer (we'll create our own)
    -- Wrap in pcall to avoid crashes if deletion fails
    local ok, err = pcall(function()
        if #sprite.layers > 0 then
            sprite:deleteLayer(sprite.layers[1])
        end
    end)
    -- If deletion fails, continue anyway - we'll just use the existing layer
    
    -- Note: Layers will be created dynamically as we load content with descriptive names
    
    -- Load and compose each part
    local errors = {}
    
    -- 1. Shadow
    local shadowPath = FileResolver.resolveShadowPath(assetsPath, collateral, viewIndex)
    if shadowPath then
        local ok, err = loadAndCopySprite(shadowPath, sprite, "Shadow")
        if not ok then
            table.insert(errors, "Shadow: " .. (err or "Failed"))
        end
    end
    
    -- 2. Body
    local bodyPath = FileResolver.resolveBodyPath(assetsPath, collateral, viewIndex)
    if bodyPath then
        local bodyLayerName = "Body (" .. collateral .. ")"
        local ok, err = loadAndCopySprite(bodyPath, sprite, bodyLayerName)
        if not ok then
            table.insert(errors, "Body: " .. (err or "Failed"))
        end
    else
        table.insert(errors, "Body: File not found")
    end
    
    -- 3. Collateral (if exists)
    local viewName = (viewIndex == 0 and "front" or viewIndex == 1 and "left" or viewIndex == 2 and "right" or "back")
    local collateralPath = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/collateral/collateral_" .. viewName .. "_" .. collateral .. ".aseprite"
    if app.fs.isFile(collateralPath) then
        local ok, err = loadAndCopySprite(collateralPath, sprite, "Collateral")
        if not ok then
            -- Not a critical error, collateral might not exist for all views
        end
    end
    
    -- 4. Eyes (uses selected eye range and rarity)
    local eyeRange = config.eyeRange
    local eyeRarity = config.eyeRarity
    if eyeRange and eyeRarity then
        local eyesPath = FileResolver.resolveEyesPath(assetsPath, collateral, eyeRange, eyeRarity, viewIndex)
        if eyesPath then
            local eyesLayerName = "Eyes (" .. eyeRange .. " - " .. eyeRarity .. ")"
            local ok, err = loadAndCopySprite(eyesPath, sprite, eyesLayerName)
            if not ok then
                table.insert(errors, "Eyes: " .. (err or "Failed"))
            end
        else
            table.insert(errors, "Eyes: File not found (range: " .. eyeRange .. ", rarity: " .. eyeRarity .. ")")
        end
    else
        table.insert(errors, "Eyes: Eye range and rarity not specified")
    end
    
    -- 5. Mouth
    local mouthPath = FileResolver.resolveMouthPath(assetsPath, collateral, mouthExpression)
    if mouthPath then
        local mouthLayerName = "Mouth (" .. mouthExpression .. ")"
        local ok, err = loadAndCopySprite(mouthPath, sprite, mouthLayerName)
        if not ok then
            table.insert(errors, "Mouth: " .. (err or "Failed"))
        end
    else
        table.insert(errors, "Mouth: File not found")
    end
    
    -- 6. Hands
    local handsPath = FileResolver.resolveHandsPath(assetsPath, collateral, handPose, viewIndex)
    if handsPath then
        local handsLayerName = "Hands (" .. handPose .. ")"
        local ok, err = loadAndCopySprite(handsPath, sprite, handsLayerName)
        if not ok then
            table.insert(errors, "Hands: " .. (err or "Failed"))
        end
    else
        table.insert(errors, "Hands: File not found")
    end
    
    -- 7. Wearables
    local bodyWearableData = nil
    if wearablesWithNames then
        -- Get slot display names for better labels
        local slotDisplayMap = {
            body = "Body", face = "Face", eyes = "Eyes", head = "Head",
            right_hand = "Right Hand", left_hand = "Left Hand",
            pet = "Pet", background = "Background", aura = "Aura",
            hands = "Hands", weapon_right = "Weapon Right", weapon_left = "Weapon Left"
        }
        
        for slot, wearableData in pairs(wearablesWithNames) do
            local wearableId = wearableData.id
            local wearableName = wearableData.name
            
            -- Track body wearable for sleeves
            if slot == "body" then
                bodyWearableData = wearableData
                if _G.debugLogMessage then
                    _G.debugLogMessage("[DEBUG] Body wearable detected: " .. wearableId .. " (" .. wearableName .. ")")
                end
            end
            
            local wearablePath = FileResolver.resolveWearablePath(assetsPath, wearableId, wearableName, viewIndex)
            if wearablePath then
                local slotDisplay = slotDisplayMap[slot] or slot
                local layerName = slotDisplay .. " - " .. wearableName .. " (#" .. wearableId .. ")"
                local ok, err = loadAndCopySprite(wearablePath, sprite, layerName)
                if not ok then
                    table.insert(errors, "Wearable " .. wearableId .. " (" .. wearableName .. "): " .. (err or "Failed"))
                end
            else
                table.insert(errors, "Wearable " .. wearableId .. " (" .. wearableName .. "): File not found")
            end
        end
    end
    
    if _G.debugLogMessage then
        if bodyWearableData then
            _G.debugLogMessage("[DEBUG] Body wearable will be checked for sleeves")
        else
            _G.debugLogMessage("[DEBUG] No body wearable equipped - skipping sleeves")
        end
    end
    
    -- 8. Sleeves (if body wearable is equipped)
    if bodyWearableData then
        if _G.debugLogMessage then
            _G.debugLogMessage("[DEBUG] Checking for sleeves - Body wearable: " .. bodyWearableData.id .. " (" .. bodyWearableData.name .. "), Hand pose: " .. handPose)
        end
        local sleevesPath = FileResolver.resolveSleevesPath(assetsPath, bodyWearableData.id, bodyWearableData.name, viewIndex, handPose)
        if sleevesPath then
            if _G.debugLogMessage then
                _G.debugLogMessage("[DEBUG] Sleeves found, loading...")
            end
            -- sleevesPath might be a single file (string) or two files (table with left and right)
            if type(sleevesPath) == "table" and #sleevesPath == 2 then
                -- Two files: left and right sleeves
                -- Load left sleeve first (will be on a lower layer)
                local ok, err = loadAndCopySprite(sleevesPath[1], sprite, "Sleeves Left (" .. (handPose == "up" and "Up" or "Down") .. ")")
                if not ok then
                    table.insert(errors, "Sleeves Left: " .. (err or "Failed"))
                end
                -- Then right sleeve (higher layer)
                local ok2, err2 = loadAndCopySprite(sleevesPath[2], sprite, "Sleeves Right (" .. (handPose == "up" and "Up" or "Down") .. ")")
                if not ok2 then
                    table.insert(errors, "Sleeves Right: " .. (err2 or "Failed"))
                end
            elseif type(sleevesPath) == "string" then
                -- Single file with sleeves
                local sleeveType = (handPose == "up" and "Up" or "Down")
                local ok, err = loadAndCopySprite(sleevesPath, sprite, "Sleeves (" .. sleeveType .. ")")
                if not ok then
                    table.insert(errors, "Sleeves: " .. (err or "Failed"))
                end
            end
        end
        -- If sleeves file doesn't exist, that's OK - not all body wearables have separate sleeve files
    end
    
    -- Refresh display
    app.refresh()
    
    -- Return results
    return {
        success = #errors == 0,
        errors = errors,
        sprite = sprite
    }
end

return Composer

