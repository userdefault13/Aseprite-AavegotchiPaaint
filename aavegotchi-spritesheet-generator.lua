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

-- Helper function to resolve script paths (works in both GUI and CLI)
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

-- Helper function to fix CSS class issues by replacing classes with inline fill colors
-- This is needed because the SVG renderer doesn't always handle multiple CSS classes correctly
local function fixSvgClassColors(svgString)
    -- Extract CSS color definitions from <style> tag
    local primaryColor = nil
    local secondaryColor = nil
    local styleContent = svgString:match("<style>(.-)</style>")
    if styleContent then
        -- Extract .gotchi-primary{fill:#color;} - handle newlines and whitespace
        primaryColor = styleContent:match("%.gotchi%-primary[^}]*fill%s*:%s*#([%w]+)")
        secondaryColor = styleContent:match("%.gotchi%-secondary[^}]*fill%s*:%s*#([%w]+)")
    end
    
    if not primaryColor and not secondaryColor then
        return svgString -- No colors to apply
    end
    
    print("DEBUG fixSvgClassColors: primaryColor=" .. (primaryColor or "nil") .. ", secondaryColor=" .. (secondaryColor or "nil"))
    
    -- Fix paths with gotchi-primary class - add inline fill attribute
    local fixed = svgString
    local modified = false
    
    if primaryColor then
        -- Match self-closing paths: <path ... class="...gotchi-primary..." />
        local beforeSelfClose = fixed
        fixed = fixed:gsub('(<path)([^>]*class="[^"]*gotchi%-primary[^"]*")([^>]*)/>', function(open, classPart, rest)
            if not (classPart .. rest):match('fill%s*=') then
                modified = true
                return open .. classPart .. rest .. ' fill="#' .. primaryColor .. '"/>'
            end
            return open .. classPart .. rest .. '/>'
        end)
        
        -- Match regular paths: <path ... class="...gotchi-primary..." >
        fixed = fixed:gsub('(<path)([^>]*class="[^"]*gotchi%-primary[^"]*")([^>]*)>', function(open, classPart, rest)
            if not (classPart .. rest):match('fill%s*=') then
                modified = true
                return open .. classPart .. rest .. ' fill="#' .. primaryColor .. '">'
            end
            return open .. classPart .. rest .. '>'
        end)
    end
    
    if secondaryColor then
        -- Match self-closing paths with gotchi-secondary
        fixed = fixed:gsub('(<path)([^>]*class="[^"]*gotchi%-secondary[^"]*")([^>]*)/>', function(open, classPart, rest)
            if not (classPart .. rest):match('fill%s*=') then
                modified = true
                return open .. classPart .. rest .. ' fill="#' .. secondaryColor .. '"/>'
            end
            return open .. classPart .. rest .. '/>'
        end)
        
        -- Match regular paths with gotchi-secondary
        fixed = fixed:gsub('(<path)([^>]*class="[^"]*gotchi%-secondary[^"]*")([^>]*)>', function(open, classPart, rest)
            if not (classPart .. rest):match('fill%s*=') then
                modified = true
                return open .. classPart .. rest .. ' fill="#' .. secondaryColor .. '">'
            end
            return open .. classPart .. rest .. '>'
        end)
    end
    
    if modified then
        print("DEBUG: SVG was modified to add inline fill colors")
    else
        print("DEBUG: SVG was NOT modified (no matching paths found or fills already exist)")
    end
    
    return fixed
end

-- Helper function to convert SVG string to Image
-- Uses SVG importer modules if available, otherwise returns error
local function svgStringToImage(svgString, width, height)
    -- Fix CSS class color issues before rendering
    svgString = fixSvgClassColors(svgString)
    -- Try to load SVG importer modules
    local svgParserPath = nil
    local svgRendererPath = nil
    
    -- Check multiple possible paths for SVG modules
    local possiblePaths = {
        "/Users/juliuswong/Dev/aesprite-svgimporter/extracted/svg-parser.lua",
        "../aesprite-svgimporter/extracted/svg-parser.lua",
        "aesprite-svgimporter/extracted/svg-parser.lua",
        app.fs.joinPath(app.fs.userConfigPath, "extensions/aesprite-svgimporter/extracted/svg-parser.lua")
    }
    
    for _, path in ipairs(possiblePaths) do
        if app.fs.isFile(path) then
            svgParserPath = path
            svgRendererPath = path:gsub("svg%-parser%.lua", "svg-renderer-professional.lua")
            break
        end
    end
    
    if not svgParserPath or not app.fs.isFile(svgParserPath) then
        return nil, "SVG parser module not found. Please ensure aesprite-svgimporter extension is installed."
    end
    
    if not svgRendererPath or not app.fs.isFile(svgRendererPath) then
        return nil, "SVG renderer module not found. Please ensure aesprite-svgimporter extension is installed."
    end
    
    -- Load SVG modules
    local SVGParser = dofile(svgParserPath)
    local SVGRenderer = dofile(svgRendererPath)
    
    if not SVGParser or not SVGRenderer then
        return nil, "Failed to load SVG parser or renderer modules"
    end
    
    -- Parse SVG
    local svgData = SVGParser.parse(svgString)
    if not svgData or not svgData.viewBox then
        return nil, "Failed to parse SVG"
    end
    
    -- Render to pixels
    local renderResult = SVGRenderer.render(svgData, width, height)
    if not renderResult or not renderResult.pixels or #renderResult.pixels == 0 then
        return nil, "No pixels rendered from SVG"
    end
    
    -- Create image and draw pixels
    local image = Image(width, height, ColorMode.RGB)
    
    -- Wrap pixel drawing in transaction for better performance and proper color handling
    app.transaction(
        function()
            for _, pixel in ipairs(renderResult.pixels) do
                if pixel.x >= 0 and pixel.x < width and pixel.y >= 0 and pixel.y < height then
                    -- Check if pixel has valid color data and alpha > 0
                    if pixel.color and (not pixel.color.a or pixel.color.a > 0) then
                        local color = Color{
                            r = pixel.color.r or 0,
                            g = pixel.color.g or 0,
                            b = pixel.color.b or 0,
                            a = pixel.color.a or 255
                        }
                        image:drawPixel(pixel.x, pixel.y, color)
                    end
                end
            end
        end
    )
    
    return image, nil
end

-- Helper function to apply Y offset to an image
local function applyYOffsetToImage(image, yOffset)
    if not image or yOffset == 0 then
        return image
    end
    
    local newImage = Image(image.width, image.height, ColorMode.RGB)
    newImage:drawImage(image, Point(0, yOffset))
    return newImage
end

-- Flip image horizontally
local function flipImageHorizontally(image)
    if not image then
        return image
    end
    
    local newImage = Image(image.width, image.height, ColorMode.RGB)
    -- Copy pixels from right to left
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            local sourceX = image.width - 1 - x
            local pixel = image:getPixel(sourceX, y)
            newImage:putPixel(x, y, pixel)
        end
    end
    return newImage
end

-- Parse JSON file to extract body array
local function parseBodyJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    -- Simple parser to extract body array
    local bodyArray = {}
    local bodyStart = jsonContent:find('"body"%s*:%s*%[')
    if not bodyStart then
        return nil, "Could not find 'body' array in JSON"
    end
    
    local arrayStart = jsonContent:find('%[', bodyStart)
    local inString = false
    local escapeNext = false
    local currentString = ""
    
    for i = arrayStart + 1, #jsonContent do
        local char = jsonContent:sub(i, i)
        
        if escapeNext then
            if inString then
                -- Handle escape sequences
                if char == '"' then
                    currentString = currentString .. '"'
                elseif char == '\\' then
                    currentString = currentString .. '\\'
                elseif char == 'n' then
                    currentString = currentString .. '\n'
                elseif char == 't' then
                    currentString = currentString .. '\t'
                else
                    currentString = currentString .. char
                end
            end
            escapeNext = false
        elseif char == '\\' then
            escapeNext = true
        elseif char == '"' then
            if inString then
                -- End of string
                table.insert(bodyArray, currentString)
                currentString = ""
                inString = false
            else
                -- Start of string
                inString = true
            end
        elseif inString then
            currentString = currentString .. char
        elseif char == ']' and not inString then
            break
        end
    end
    
    if #bodyArray < 6 then
        return nil, "Expected at least 6 body views, found " .. #bodyArray
    end
    
    -- Return first 6 entries
    local firstSix = {}
    for i = 1, 6 do
        table.insert(firstSix, bodyArray[i])
    end
    
    return firstSix, nil
end

-- Parse JSON file to extract hands array
local function parseHandsJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    -- Simple parser to extract hands array
    local handsArray = {}
    local handsStart = jsonContent:find('"hands"%s*:%s*%[')
    if not handsStart then
        return nil, "Could not find 'hands' array in JSON"
    end
    
    local arrayStart = jsonContent:find('%[', handsStart)
    local inString = false
    local escapeNext = false
    local currentString = ""
    
    for i = arrayStart + 1, #jsonContent do
        local char = jsonContent:sub(i, i)
        
        if escapeNext then
            if inString then
                -- Handle escape sequences
                if char == '"' then
                    currentString = currentString .. '"'
                elseif char == '\\' then
                    currentString = currentString .. '\\'
                elseif char == 'n' then
                    currentString = currentString .. '\n'
                elseif char == 't' then
                    currentString = currentString .. '\t'
                else
                    currentString = currentString .. char
                end
            end
            escapeNext = false
        elseif char == '\\' then
            escapeNext = true
        elseif char == '"' then
            if inString then
                -- End of string
                table.insert(handsArray, currentString)
                currentString = ""
                inString = false
            else
                -- Start of string
                inString = true
            end
        elseif inString then
            currentString = currentString .. char
        elseif char == ']' and not inString then
            break
        end
    end
    
    if #handsArray < 5 then
        return nil, "Expected at least 5 hands views, found " .. #handsArray
    end
    
    -- Return first 5 entries (we'll reuse index 1 for back view)
    local firstFive = {}
    for i = 1, 5 do
        table.insert(firstFive, handsArray[i])
    end
    
    return firstFive, nil
end

-- Parse JSON file to extract useItem/weapon array
local function parseWeaponJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    -- Simple parser to extract useItem/weapon array
    local weaponArray = {}
    local weaponStart = jsonContent:find('"useItem/weapon"%s*:%s*%[')
    if not weaponStart then
        return nil, "Could not find 'useItem/weapon' array in JSON"
    end
    
    local arrayStart = jsonContent:find('%[', weaponStart)
    local inString = false
    local escapeNext = false
    local currentString = ""
    
    for i = arrayStart + 1, #jsonContent do
        local char = jsonContent:sub(i, i)
        
        if escapeNext then
            if inString then
                -- Handle escape sequences
                if char == '"' then
                    currentString = currentString .. '"'
                elseif char == '\\' then
                    currentString = currentString .. '\\'
                elseif char == 'n' then
                    currentString = currentString .. '\n'
                elseif char == 't' then
                    currentString = currentString .. '\t'
                else
                    currentString = currentString .. char
                end
            end
            escapeNext = false
        elseif char == '\\' then
            escapeNext = true
        elseif char == '"' then
            if inString then
                -- End of string
                table.insert(weaponArray, currentString)
                currentString = ""
                inString = false
            else
                -- Start of string
                inString = true
            end
        elseif inString then
            currentString = currentString .. char
        elseif char == ']' and not inString then
            break
        end
    end
    
    if #weaponArray < 10 then
        return nil, "Expected at least 10 weapon views, found " .. #weaponArray
    end
    
    return weaponArray, nil
end

-- Parse JSON file to extract takeDamage arrays
local function parseTakeDamageJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    local takeDamageData = {
        front = {},
        left = {},
        right = {},
        back = {}
    }
    
    -- Parse each takeDamage array
    local views = {"front", "left", "right", "back"}
    for _, view in ipairs(views) do
        local arrayName = '"takeDamage/' .. view .. '"'
        local arrayStart = jsonContent:find(arrayName .. '%s*:%s*%[')
        if arrayStart then
            local bracketStart = jsonContent:find('%[', arrayStart)
            local inString = false
            local escapeNext = false
            local currentString = ""
            
            for i = bracketStart + 1, #jsonContent do
                local char = jsonContent:sub(i, i)
                
                if escapeNext then
                    if inString then
                        if char == '"' then
                            currentString = currentString .. '"'
                        elseif char == '\\' then
                            currentString = currentString .. '\\'
                        elseif char == 'n' then
                            currentString = currentString .. '\n'
                        elseif char == 't' then
                            currentString = currentString .. '\t'
                        else
                            currentString = currentString .. char
                        end
                    end
                    escapeNext = false
                elseif char == '\\' then
                    escapeNext = true
                elseif char == '"' then
                    if inString then
                        table.insert(takeDamageData[view], currentString)
                        currentString = ""
                        inString = false
                    else
                        inString = true
                    end
                elseif inString then
                    currentString = currentString .. char
                elseif char == ']' and not inString then
                    break
                end
            end
        end
    end
    
    return takeDamageData, nil
end

-- Parse JSON file to extract death array
local function parseDeathJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    local deathArray = {}
    local deathStart = jsonContent:find('"death"%s*:%s*%[')
    if not deathStart then
        return nil, "Could not find 'death' array in JSON"
    end
    
    local arrayStart = jsonContent:find('%[', deathStart)
    local inString = false
    local escapeNext = false
    local currentString = ""
    
    for i = arrayStart + 1, #jsonContent do
        local char = jsonContent:sub(i, i)
        
        if escapeNext then
            if inString then
                if char == '"' then
                    currentString = currentString .. '"'
                elseif char == '\\' then
                    currentString = currentString .. '\\'
                elseif char == 'n' then
                    currentString = currentString .. '\n'
                elseif char == 't' then
                    currentString = currentString .. '\t'
                else
                    currentString = currentString .. char
                end
            end
            escapeNext = false
        elseif char == '\\' then
            escapeNext = true
        elseif char == '"' then
            if inString then
                table.insert(deathArray, currentString)
                currentString = ""
                inString = false
            else
                inString = true
            end
        elseif inString then
            currentString = currentString .. char
        elseif char == ']' and not inString then
            break
        end
    end
    
    return deathArray, nil
end

-- Parse JSON file to extract takeDamage/hands object
local function parseHandTakeDamageJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    local handTakeDamageData = {
        frontDown = {},
        frontUp = {},
        left = {},
        right = {}
    }
    
    -- Parse each takeDamage/hands array
    local views = {"frontDown", "frontUp", "left", "right"}
    for _, view in ipairs(views) do
        -- Find the takeDamage/hands object first
        local handsStart = jsonContent:find('"takeDamage/hands"%s*:%s*%{')
        if handsStart then
            -- Find the specific view array within the hands object
            local viewPattern = '"' .. view .. '"%s*:%s*%['
            local viewStart = jsonContent:find(viewPattern, handsStart)
            if viewStart then
                local bracketStart = jsonContent:find('%[', viewStart)
                local inString = false
                local escapeNext = false
                local currentString = ""
                
                for i = bracketStart + 1, #jsonContent do
                    local char = jsonContent:sub(i, i)
                    
                    if escapeNext then
                        if inString then
                            if char == '"' then
                                currentString = currentString .. '"'
                            elseif char == '\\' then
                                currentString = currentString .. '\\'
                            elseif char == 'n' then
                                currentString = currentString .. '\n'
                            elseif char == 't' then
                                currentString = currentString .. '\t'
                            else
                                currentString = currentString .. char
                            end
                        end
                        escapeNext = false
                    elseif char == '\\' then
                        escapeNext = true
                    elseif char == '"' then
                        if inString then
                            table.insert(handTakeDamageData[view], currentString)
                            currentString = ""
                            inString = false
                        else
                            inString = true
                        end
                    elseif inString then
                        currentString = currentString .. char
                    elseif char == ']' and not inString then
                        break
                    end
                end
            end
        end
    end
    
    return handTakeDamageData, nil
end

-- Parse JSON file to extract collateral array
local function parseCollateralJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    -- Simple parser to extract collateral array
    local collateralArray = {}
    local collateralStart = jsonContent:find('"collateral"%s*:%s*%[')
    if not collateralStart then
        return nil, "Could not find 'collateral' array in JSON"
    end
    
    local arrayStart = jsonContent:find('%[', collateralStart)
    local inString = false
    local escapeNext = false
    local currentString = ""
    
    for i = arrayStart + 1, #jsonContent do
        local char = jsonContent:sub(i, i)
        
        if escapeNext then
            if inString then
                -- Handle escape sequences
                if char == '"' then
                    currentString = currentString .. '"'
                elseif char == '\\' then
                    currentString = currentString .. '\\'
                elseif char == 'n' then
                    currentString = currentString .. '\n'
                elseif char == 't' then
                    currentString = currentString .. '\t'
                else
                    currentString = currentString .. char
                end
            end
            escapeNext = false
        elseif char == '\\' then
            escapeNext = true
        elseif char == '"' then
            if inString then
                -- End of string
                table.insert(collateralArray, currentString)
                currentString = ""
                inString = false
            else
                -- Start of string
                inString = true
            end
        elseif inString then
            currentString = currentString .. char
        elseif char == ']' and not inString then
            break
        end
    end
    
    if #collateralArray < 3 then
        return nil, "Expected at least 3 collateral views (front, left, right), found " .. #collateralArray
    end
    
    return collateralArray, nil
end

-- Get hex color for eye color rarity from aavegotchi_db_rarity.json
local function getRarityHexColor(rarityString, assetsPath)
    local rarityJsonPath = assetsPath .. "/JSONs/aavegotchi_db_rarity.json"
    if not app.fs.isFile(rarityJsonPath) then
        return nil, "Rarity JSON file not found: " .. rarityJsonPath
    end
    
    local file = io.open(rarityJsonPath, "r")
    if not file then
        return nil, "Failed to open rarity JSON file"
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "Rarity JSON file is empty"
    end
    
    -- Map rarity string to range key
    local rangeKey = nil
    if rarityString == "mythicallow" then
        rangeKey = "0-1"
    elseif rarityString == "rarelow" then
        rangeKey = "2-9"
    elseif rarityString == "uncommonlow" then
        rangeKey = "10-24"
    elseif rarityString == "common" then
        -- Common uses collateral color, return nil to indicate no replacement needed
        return nil, nil
    elseif rarityString == "uncommonhigh" then
        rangeKey = "75-90"
    elseif rarityString == "rarehigh" then
        rangeKey = "91-97"
    elseif rarityString == "mythicalhigh" then
        rangeKey = "98-99"
    end
    
    if not rangeKey then
        return nil, "Unknown rarity: " .. rarityString
    end
    
    -- Parse JSON to extract hex value for this range
    -- Look for "rangeKey": { ... "hex": "value" or "hex": null }
    -- Escape special characters in rangeKey for pattern matching
    local escapedRangeKey = rangeKey:gsub('%-', '%%-')  -- Escape dash for pattern
    local pattern = '"' .. escapedRangeKey .. '"%s*:%s*%{[^}]*"hex"%s*:%s*"([^"]+)"'
    local hexMatch = jsonContent:match(pattern)
    
    if not hexMatch then
        -- Try a more flexible pattern that handles newlines and whitespace
        pattern = '"' .. escapedRangeKey .. '"' .. '[^}]*"hex"%s*:%s*"([^"]+)"'
        hexMatch = jsonContent:match(pattern)
    end
    
    if not hexMatch then
        -- Try to find if it's null
        local nullPattern = '"' .. escapedRangeKey .. '"' .. '[^}]*"hex"%s*:%s*(null)'
        local nullMatch = jsonContent:match(nullPattern)
        if nullMatch == "null" then
            return nil, nil  -- Common rarity, use collateral color
        end
        return nil, "Could not find hex for rarity: " .. rarityString .. " (range: " .. rangeKey .. ")"
    end
    
    -- hexMatch should now be the hex value (e.g., "#ff00ff")
    hexMatch = hexMatch:gsub('%s+', '')
    
    return hexMatch, nil
end

-- Apply eye color to SVG string by replacing gotchi-eyeColor fill
local function applyEyeColorToSvg(svgString, hexColor)
    if not hexColor then
        return svgString  -- No color to apply (common rarity uses collateral color)
    end
    
    -- Replace .gotchi-eyeColor{fill:#...} with the new color
    -- Pattern matches: .gotchi-eyeColor{fill:#hexcolor;} or .gotchi-eyeColor{fill:#hexcolor}
    -- Match any hex color after fill: and before ; or }
    local pattern = '(%.gotchi%-eyeColor%s*{[^}]*fill%s*:)[^;}]+([;}])'
    
    local modifiedSvg = svgString:gsub(pattern, '%1' .. hexColor .. '%2')
    
    return modifiedSvg
end

-- Parse JSON file to extract eyes array
local function parseEyesJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    -- Simple parser to extract eyes array
    local eyesArray = {}
    local eyesStart = jsonContent:find('"eyes"%s*:%s*%[')
    if not eyesStart then
        return nil, "Could not find 'eyes' array in JSON"
    end
    
    local arrayStart = jsonContent:find('%[', eyesStart)
    local inString = false
    local escapeNext = false
    local currentString = ""
    
    for i = arrayStart + 1, #jsonContent do
        local char = jsonContent:sub(i, i)
        
        if escapeNext then
            if inString then
                -- Handle escape sequences
                if char == '"' then
                    currentString = currentString .. '"'
                elseif char == '\\' then
                    currentString = currentString .. '\\'
                elseif char == 'n' then
                    currentString = currentString .. '\n'
                elseif char == 't' then
                    currentString = currentString .. '\t'
                else
                    currentString = currentString .. '\\' .. char
                end
                escapeNext = false
            end
        elseif char == '\\' and inString then
            escapeNext = true
        elseif char == '"' then
            if inString then
                -- End of string
                table.insert(eyesArray, currentString)
                currentString = ""
                inString = false
            else
                -- Start of string
                inString = true
                currentString = ""
            end
        elseif inString then
            currentString = currentString .. char
        elseif char == ']' and not inString then
            break
        end
    end
    
    if #eyesArray < 3 then
        return nil, "Expected at least 3 eye views (front, left, right), found " .. #eyesArray
    end
    
    return eyesArray, nil
end

-- Parse JSON file to extract mouth arrays
local function parseMouthJson(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Failed to open JSON file: " .. jsonPath
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        return nil, "JSON file is empty"
    end
    
    local mouths = {
        happy = nil,
        surprised = nil,
        sad = nil
    }
    
    -- Extract mouth_happy
    local happyStart = jsonContent:find('"mouth_happy"%s*:%s*%[')
    if happyStart then
        local arrayStart = jsonContent:find('%[', happyStart)
        local svgStart = jsonContent:find('"', arrayStart)
        if svgStart then
            local svgEnd = jsonContent:find('"', svgStart + 1)
            while jsonContent:sub(svgEnd - 1, svgEnd - 1) == '\\' do
                svgEnd = jsonContent:find('"', svgEnd + 1)
            end
            if svgEnd then
                local svgContent = jsonContent:sub(svgStart + 1, svgEnd - 1)
                svgContent = svgContent:gsub('\\"', '"')
                svgContent = svgContent:gsub('\\\\', '\\')
                svgContent = svgContent:gsub('\\n', '\n')
                mouths.happy = svgContent
            end
        end
    end
    
    -- Extract mouth_surprised
    local surprisedStart = jsonContent:find('"mouth_surprised"%s*:%s*%[')
    if surprisedStart then
        local arrayStart = jsonContent:find('%[', surprisedStart)
        local svgStart = jsonContent:find('"', arrayStart)
        if svgStart then
            local svgEnd = jsonContent:find('"', svgStart + 1)
            while jsonContent:sub(svgEnd - 1, svgEnd - 1) == '\\' do
                svgEnd = jsonContent:find('"', svgEnd + 1)
            end
            if svgEnd then
                local svgContent = jsonContent:sub(svgStart + 1, svgEnd - 1)
                svgContent = svgContent:gsub('\\"', '"')
                svgContent = svgContent:gsub('\\\\', '\\')
                svgContent = svgContent:gsub('\\n', '\n')
                mouths.surprised = svgContent
            end
        end
    end
    
    -- Extract mouth_sad
    local sadStart = jsonContent:find('"mouth_sad"%s*:%s*%[')
    if sadStart then
        local arrayStart = jsonContent:find('%[', sadStart)
        local svgStart = jsonContent:find('"', arrayStart)
        if svgStart then
            local svgEnd = jsonContent:find('"', svgStart + 1)
            while jsonContent:sub(svgEnd - 1, svgEnd - 1) == '\\' do
                svgEnd = jsonContent:find('"', svgEnd + 1)
            end
            if svgEnd then
                local svgContent = jsonContent:sub(svgStart + 1, svgEnd - 1)
                svgContent = svgContent:gsub('\\"', '"')
                svgContent = svgContent:gsub('\\\\', '\\')
                svgContent = svgContent:gsub('\\n', '\n')
                mouths.sad = svgContent
            end
        end
    end
    
    if not mouths.happy or not mouths.surprised or not mouths.sad then
        return nil, "Could not find all required mouth SVGs (happy, surprised, sad)"
    end
    
    return mouths, nil
end

-- Generate body spritesheet from JSON file
function SpriteSheetGenerator.generateBodySpriteSheet(collateral, jsonPath, assetsPath)
    print("=== Body Sprite Sheet Generator ===")
    print("Collateral: " .. collateral)
    print("JSON Path: " .. jsonPath)
    print("")
    
    -- Save original active sprite
    local originalActiveSprite = app.activeSprite
    
    -- Validate JSON path exists
    if not app.fs.isFile(jsonPath) then
        local errMsg = "JSON file not found: " .. jsonPath
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    -- Parse JSON file
    local bodyArray, err = parseBodyJson(jsonPath)
    if not bodyArray then
        local errMsg = err or "Failed to parse JSON"
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    print("Loaded " .. #bodyArray .. " body views from JSON")
    
    -- Parse takeDamage and death arrays
    local takeDamageData, err = parseTakeDamageJson(jsonPath)
    if not takeDamageData then
        print("WARNING: Could not parse takeDamage arrays: " .. (err or "Unknown error"))
        takeDamageData = {front = {}, left = {}, right = {}, back = {}}
    else
        print("Loaded takeDamage arrays: front=" .. #takeDamageData.front .. ", left=" .. #takeDamageData.left .. 
              ", right=" .. #takeDamageData.right .. ", back=" .. #takeDamageData.back)
    end
    
    local deathArray, err = parseDeathJson(jsonPath)
    if not deathArray then
        print("WARNING: Could not parse death array: " .. (err or "Unknown error"))
        deathArray = {}
    else
        print("Loaded " .. #deathArray .. " death frames from JSON")
    end
    
    -- Create sprite: 1088x384 (17 columns × 6 rows of 64x64 cells)
    -- Original 5 columns (0-256) + 12 new columns (320-1024) = 1088px
    local sheetWidth = 1088
    local sheetHeight = 384
    local frameWidth = 64
    local frameHeight = 64
    
    print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
    local sheetSprite = nil
    local ok, err = pcall(function()
        sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
        app.activeSprite = sheetSprite
    end)
    
    if not ok or not sheetSprite then
        return nil, "Failed to create sprite: " .. (err or "Unknown error")
    end
    
    -- Remove default layer
    ok, err = pcall(function()
        app.activeSprite = sheetSprite
        if #sheetSprite.layers > 0 then
            local defaultLayer = sheetSprite.layers[1]
            sheetSprite:deleteLayer(defaultLayer)
        end
    end)
    
    -- Get frame 1 and create frames 2-12 (total 12 frames)
    -- Frames 1-2: Base frames (existing)
    -- Frames 3-5: Take damage animation (3 frames)
    -- Frames 6-12: Death animation (7 frames)
    local frames = {sheetSprite.frames[1]}
    
    for i = 2, 12 do
        local newFrame = sheetSprite:newFrame(i)
        table.insert(frames, newFrame)
    end
    
    if not frames[1] or #frames < 12 then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "Failed to create frames"
    end
    
    -- Body array indices: 1=Front, 2=Front-Up, 3=Front-Down Closed, 4=Left, 5=Right, 6=Back
    -- Convert all body views to images first
    local bodyImages = {}
    local bodyNames = {"Front", "Front - Up", "Front - Down Closed", "Left", "Right", "Back"}
    for i = 1, math.min(#bodyArray, 6) do
        local svgString = bodyArray[i]
        local bodyImage, err = svgStringToImage(svgString, frameWidth, frameHeight)
        if bodyImage then
            bodyImages[i] = bodyImage
            print("Loaded " .. bodyNames[i] .. " body view")
        else
            print("  WARNING: Failed to convert " .. bodyNames[i] .. " body SVG: " .. (err or "Unknown error"))
        end
    end
    
    -- Create a single layer for all body views
    local bodyLayer = sheetSprite:newLayer("Body")
    
    -- Create canvas images for all 12 frames
    local bodyFrameImages = {}
    for i = 1, 12 do
        bodyFrameImages[i] = Image(sheetWidth, sheetHeight, ColorMode.RGB)
    end
    
    -- Layout specification:
    -- Row 0 (y=0): x=0,64,128,192,256 - all use front view body
    -- Row 1 (y=64): x=0,64,128,192,256 - all use front view body
    -- Row 2 (y=128): x=0,64 - use front view body (only 2 columns)
    -- Row 3 (y=192): x=0,64,128,192,256 - all use left view body
    -- Row 4 (y=256): x=0,64,128,192,256 - all use right view body
    -- Row 5 (y=320): x=0,64,128,192,256 - all use back view body
    
    local frontBody = bodyImages[1]  -- Front view
    local leftBody = bodyImages[4]   -- Left view
    local rightBody = bodyImages[5]  -- Right view
    local backBody = bodyImages[6]   -- Back view
    
    if not frontBody or not leftBody or not rightBody or not backBody then
        return nil, "Missing required body views (Front, Left, Right, Back)"
    end
    
    -- Create offset versions of body images (up by 1 = y offset -1)
    local frontBodyOffset = applyYOffsetToImage(frontBody, -1)
    local leftBodyOffset = applyYOffsetToImage(leftBody, -1)
    local rightBodyOffset = applyYOffsetToImage(rightBody, -1)
    local backBodyOffset = applyYOffsetToImage(backBody, -1)
    
    -- Helper function to get the appropriate body image based on row
    local function getBodyImageForRow(rowY, isOffset)
        local bodyImage = nil
        if rowY == 0 or rowY == 64 or rowY == 128 then
            bodyImage = isOffset and frontBodyOffset or frontBody
        elseif rowY == 192 then
            bodyImage = isOffset and leftBodyOffset or leftBody
        elseif rowY == 256 then
            bodyImage = isOffset and rightBodyOffset or rightBody
        elseif rowY == 320 then
            bodyImage = isOffset and backBodyOffset or backBody
        end
        return bodyImage
    end
    
    -- Define all row y positions
    local rowYs = {0, 64, 128, 192, 256, 320}
    
    -- Frame 1: Build the frame
    for _, rowY in ipairs(rowYs) do
        local baseBody = getBodyImageForRow(rowY, false)
        local offsetBody = getBodyImageForRow(rowY, true)
        
        if baseBody and offsetBody then
            -- Determine which columns to draw based on row
            local columns = {}
            if rowY == 128 then
                -- Row 2: Only x=0,64
                columns = {0, 64}
            else
                -- All other rows: x=0,64,128,192,256
                columns = {0, 64, 128, 192, 256}
            end
            
            -- Draw images for all frames (base body stays same across all frames)
            -- Note: Skip x=0 for frame 2, as it will be handled separately with offset
            for frameIdx = 1, 12 do
                for _, x in ipairs(columns) do
                    if x == 64 then
                        -- Column x=64: offset image (all frames)
                        bodyFrameImages[frameIdx]:drawImage(offsetBody, Point(x, rowY))
                    elseif x == 0 and frameIdx == 2 then
                        -- Column x=0 for frame 2: skip here, will be handled in next section
                        -- Do nothing
                    else
                        -- All other columns: base image (same in all frames)
                        bodyFrameImages[frameIdx]:drawImage(baseBody, Point(x, rowY))
                    end
                end
            end
        end
    end
    
    -- Frame 2: x=0 duplicates x=64, all other columns same as Frame 1
    for _, rowY in ipairs(rowYs) do
        local baseBody = getBodyImageForRow(rowY, false)
        local offsetBody = getBodyImageForRow(rowY, true)
        
        if baseBody and offsetBody then
            -- Determine which columns to draw based on row
            local columns = {}
            if rowY == 128 then
                -- Row 2: Only x=0,64
                columns = {0, 64}
            else
                -- All other rows: x=0,64,128,192,256
                columns = {0, 64, 128, 192, 256}
            end
            
            -- Draw images for Frame 2 specifically
            -- Only need to draw x=0 with offset (x=64 and others already drawn correctly in first loop)
            for _, x in ipairs(columns) do
                if x == 0 then
                    -- Column x=0: duplicate x=64 (offset) - this is the only change for frame 2
                    bodyFrameImages[2]:drawImage(offsetBody, Point(x, rowY))
                end
                -- x=64 and other columns already drawn correctly in first loop, no need to redraw
            end
            
            -- Frames 3-12: Already drawn correctly in first loop (same as frame 1 pattern)
            -- x=0 = base, x=64 = offset, others = base
        end
    end
    
    print("  Frame 1: Base images at x=0,128,192,256 | Offset images at x=64")
    print("  Frame 2: Offset images at x=0,64 (x=0 duplicates x=64) | Base images at x=128,192,256")
    print("  Frames 3-12: Same as Frame 1 pattern (reverted)")
    
    -- Create cels for body layer (all 12 frames)
    for frameIdx = 1, 12 do
        sheetSprite:newCel(bodyLayer, frames[frameIdx], bodyFrameImages[frameIdx])
    end
    
    -- Add take damage sequences to columns 5-7 (x=320, 384, 448)
    if #takeDamageData.front >= 3 and #takeDamageData.left >= 3 and 
       #takeDamageData.right >= 3 and #takeDamageData.back >= 3 then
        
        print("Adding take damage sequences...")
        
        -- Create take damage layer
        local takeDamageLayer = sheetSprite:newLayer("Take Damage")
        
        -- Prepare images for all take damage views
        local takeDamageImages = {
            front = {},
            left = {},
            right = {},
            back = {}
        }
        
        for i = 1, 3 do
            -- Front view
            local img, err = svgStringToImage(takeDamageData.front[i], frameWidth, frameHeight)
            if img then table.insert(takeDamageImages.front, img) end
            
            -- Left view
            img, err = svgStringToImage(takeDamageData.left[i], frameWidth, frameHeight)
            if img then table.insert(takeDamageImages.left, img) end
            
            -- Right view
            img, err = svgStringToImage(takeDamageData.right[i], frameWidth, frameHeight)
            if img then table.insert(takeDamageImages.right, img) end
            
            -- Back view
            img, err = svgStringToImage(takeDamageData.back[i], frameWidth, frameHeight)
            if img then table.insert(takeDamageImages.back, img) end
        end
        
        -- Create canvas images for frames 1-12
        local takeDamageFrameImages = {}
        for frameIdx = 1, 12 do
            takeDamageFrameImages[frameIdx] = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        end
        
        -- Columns 5-7: x=320, 384, 448
        -- Row 2 (y=64): front view take damage frames 1, 2, 3
        if #takeDamageImages.front >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64  -- 320, 384, 448
                local y = 64  -- Row 2
                -- Add to all frames (static display)
                for frameIdx = 1, 12 do
                    takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.front[col], Point(x, y))
                end
            end
        end
        
        -- Row 3 (y=128): front view take damage frames 1, 2, 3 (duplicate of row 2)
        if #takeDamageImages.front >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64  -- 320, 384, 448
                local y = 128  -- Row 3
                -- Add to all frames (static display)
                for frameIdx = 1, 12 do
                    takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.front[col], Point(x, y))
                end
            end
        end
        
        -- Row 4 (y=192): left view take damage frames 1, 2, 3
        if #takeDamageImages.left >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64
                local y = 192
                for frameIdx = 1, 12 do
                    takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.left[col], Point(x, y))
                end
            end
        end
        
        -- Row 5 (y=256): right view take damage frames 1, 2, 3
        if #takeDamageImages.right >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64
                local y = 256
                for frameIdx = 1, 12 do
                    takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.right[col], Point(x, y))
                end
            end
        end
        
        -- Row 6 (y=320): back view take damage frames 1, 2, 3
        if #takeDamageImages.back >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64
                local y = 320
                for frameIdx = 1, 12 do
                    takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.back[col], Point(x, y))
                end
            end
        end
        
        -- Column 8 (x=512): Take damage animation
        local x = 512
        
        -- Row 2 (y=64): Front view take damage animation (frames 3-5 show front view frames 1-3)
        if #takeDamageImages.front >= 3 then
            local y = 64  -- Row 2
            -- Frame 3 shows take damage frame 1
            takeDamageFrameImages[3]:drawImage(takeDamageImages.front[1], Point(x, y))
            -- Frame 4 shows take damage frame 2
            takeDamageFrameImages[4]:drawImage(takeDamageImages.front[2], Point(x, y))
            -- Frame 5 shows take damage frame 3
            takeDamageFrameImages[5]:drawImage(takeDamageImages.front[3], Point(x, y))
            -- Other frames can show frame 3 or remain empty
            for frameIdx = 6, 12 do
                takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.front[3], Point(x, y))
            end
        end
        
        -- Row 3 (y=128): Front view take damage animation (duplicate of row 2)
        if #takeDamageImages.front >= 3 then
            local y = 128  -- Row 3
            -- Frame 3 shows take damage frame 1
            takeDamageFrameImages[3]:drawImage(takeDamageImages.front[1], Point(x, y))
            -- Frame 4 shows take damage frame 2
            takeDamageFrameImages[4]:drawImage(takeDamageImages.front[2], Point(x, y))
            -- Frame 5 shows take damage frame 3
            takeDamageFrameImages[5]:drawImage(takeDamageImages.front[3], Point(x, y))
            -- Other frames can show frame 3 or remain empty
            for frameIdx = 6, 12 do
                takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.front[3], Point(x, y))
            end
        end
        
        -- Row 4 (y=192): Left view take damage animation (frames 3-5 show left view frames 1-3)
        if #takeDamageImages.left >= 3 then
            local y = 192
            -- Frame 3 shows take damage frame 1
            takeDamageFrameImages[3]:drawImage(takeDamageImages.left[1], Point(x, y))
            -- Frame 4 shows take damage frame 2
            takeDamageFrameImages[4]:drawImage(takeDamageImages.left[2], Point(x, y))
            -- Frame 5 shows take damage frame 3
            takeDamageFrameImages[5]:drawImage(takeDamageImages.left[3], Point(x, y))
            -- Other frames can show frame 3 or remain empty
            for frameIdx = 6, 12 do
                takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.left[3], Point(x, y))
            end
        end
        
        -- Row 5 (y=256): Right view take damage animation (frames 3-5 show right view frames 1-3)
        if #takeDamageImages.right >= 3 then
            local y = 256
            -- Frame 3 shows take damage frame 1
            takeDamageFrameImages[3]:drawImage(takeDamageImages.right[1], Point(x, y))
            -- Frame 4 shows take damage frame 2
            takeDamageFrameImages[4]:drawImage(takeDamageImages.right[2], Point(x, y))
            -- Frame 5 shows take damage frame 3
            takeDamageFrameImages[5]:drawImage(takeDamageImages.right[3], Point(x, y))
            -- Other frames can show frame 3 or remain empty
            for frameIdx = 6, 12 do
                takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.right[3], Point(x, y))
            end
        end
        
        -- Row 6 (y=320): Back view take damage animation (frames 3-5 show back view frames 1-3)
        if #takeDamageImages.back >= 3 then
            local y = 320
            -- Frame 3 shows take damage frame 1
            takeDamageFrameImages[3]:drawImage(takeDamageImages.back[1], Point(x, y))
            -- Frame 4 shows take damage frame 2
            takeDamageFrameImages[4]:drawImage(takeDamageImages.back[2], Point(x, y))
            -- Frame 5 shows take damage frame 3
            takeDamageFrameImages[5]:drawImage(takeDamageImages.back[3], Point(x, y))
            -- Other frames can show frame 3 or remain empty
            for frameIdx = 6, 12 do
                takeDamageFrameImages[frameIdx]:drawImage(takeDamageImages.back[3], Point(x, y))
            end
        end
        
        -- Create cels for all frames
        for frameIdx = 1, 12 do
            sheetSprite:newCel(takeDamageLayer, frames[frameIdx], takeDamageFrameImages[frameIdx])
        end
        
        print("  Created take damage layer")
    end
    
    -- Add death sequence to columns 9-15 (x=576, 640, 704, 768, 832, 896, 960)
    if #deathArray >= 7 then
        print("Adding death sequence...")
        
        -- Create death layer
        local deathLayer = sheetSprite:newLayer("Death")
        
        -- Convert death SVGs to images
        local deathImages = {}
        for i = 1, 7 do
            local img, err = svgStringToImage(deathArray[i], frameWidth, frameHeight)
            if img then
                table.insert(deathImages, img)
            else
                print("  WARNING: Failed to convert death SVG " .. i .. ": " .. (err or "Unknown error"))
            end
        end
        
        -- Create canvas images for frames 1-12
        local deathFrameImages = {}
        for frameIdx = 1, 12 do
            deathFrameImages[frameIdx] = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        end
        
        -- Columns 9-15: x=576, 640, 704, 768, 832, 896, 960
        -- Row 1 (y=0): all 7 death SVGs (static display in all frames)
        if #deathImages >= 7 then
            for col = 1, 7 do
                local x = 576 + (col - 1) * 64  -- 576, 640, 704, 768, 832, 896, 960
                local y = 0
                -- Add to all frames (static display)
                for frameIdx = 1, 12 do
                    deathFrameImages[frameIdx]:drawImage(deathImages[col], Point(x, y))
                end
            end
        end
        
        -- Column 16 (x=1024): Death animation (frames 6-12 show death frames 1-7)
        if #deathImages >= 7 then
            local x = 1024
            local y = 0
            -- Frame 6 shows death frame 1
            deathFrameImages[6]:drawImage(deathImages[1], Point(x, y))
            -- Frame 7 shows death frame 2
            deathFrameImages[7]:drawImage(deathImages[2], Point(x, y))
            -- Frame 8 shows death frame 3
            deathFrameImages[8]:drawImage(deathImages[3], Point(x, y))
            -- Frame 9 shows death frame 4
            deathFrameImages[9]:drawImage(deathImages[4], Point(x, y))
            -- Frame 10 shows death frame 5
            deathFrameImages[10]:drawImage(deathImages[5], Point(x, y))
            -- Frame 11 shows death frame 6
            deathFrameImages[11]:drawImage(deathImages[6], Point(x, y))
            -- Frame 12 shows death frame 7
            deathFrameImages[12]:drawImage(deathImages[7], Point(x, y))
        end
        
        -- Create cels for all frames
        for frameIdx = 1, 12 do
            sheetSprite:newCel(deathLayer, frames[frameIdx], deathFrameImages[frameIdx])
        end
        
        print("  Created death layer with " .. #deathImages .. " death frames")
    end
    
    print("SUCCESS: Body sprite sheet created!")
    print("Dimensions: " .. sheetWidth .. "x" .. sheetHeight)
    print("Frames: 12")
    
    -- Return the sprite
    app.activeSprite = sheetSprite
    return sheetSprite, nil
end

-- Generate hands spritesheet from JSON file
function SpriteSheetGenerator.generateHandsSpriteSheet(collateral, jsonPath, assetsPath)
    print("=== Hands Sprite Sheet Generator ===")
    print("Collateral: " .. collateral)
    print("JSON Path: " .. jsonPath)
    print("")
    
    -- Save original active sprite
    local originalActiveSprite = app.activeSprite
    
    -- Validate JSON path exists
    if not app.fs.isFile(jsonPath) then
        local errMsg = "JSON file not found: " .. jsonPath
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    -- Parse JSON file
    local handsArray, err = parseHandsJson(jsonPath)
    if not handsArray then
        local errMsg = err or "Failed to parse JSON"
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    print("Loaded " .. #handsArray .. " hands views from JSON")
    
    -- Parse weapon array
    local weaponArray, err = parseWeaponJson(jsonPath)
    if not weaponArray then
        print("WARNING: Could not parse weapon array: " .. (err or "Unknown error"))
        weaponArray = {}
    else
        print("Loaded " .. #weaponArray .. " weapon views from JSON")
    end
    
    -- Parse hand takeDamage arrays
    local handTakeDamageData, err = parseHandTakeDamageJson(jsonPath)
    if not handTakeDamageData then
        print("WARNING: Could not parse hand takeDamage arrays: " .. (err or "Unknown error"))
        handTakeDamageData = {frontDown = {}, frontUp = {}, left = {}, right = {}}
    else
        print("Loaded hand takeDamage arrays: frontDown=" .. #handTakeDamageData.frontDown .. ", frontUp=" .. #handTakeDamageData.frontUp .. 
              ", left=" .. #handTakeDamageData.left .. ", right=" .. #handTakeDamageData.right)
    end
    
    -- Create sprite: 576x384 (9 columns × 6 rows of 64x64 cells)
    -- Original 5 columns (0-256) + 4 new columns (320-512) = 576px
    local sheetWidth = 576
    local sheetHeight = 384
    local frameWidth = 64
    local frameHeight = 64
    
    print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
    local sheetSprite = nil
    local ok, err = pcall(function()
        sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
        app.activeSprite = sheetSprite
    end)
    
    if not ok or not sheetSprite then
        return nil, "Failed to create sprite: " .. (err or "Unknown error")
    end
    
    -- Remove default layer
    ok, err = pcall(function()
        app.activeSprite = sheetSprite
        if #sheetSprite.layers > 0 then
            local defaultLayer = sheetSprite.layers[1]
            sheetSprite:deleteLayer(defaultLayer)
        end
    end)
    
    -- Get frame 1 and create frames 2 and 3
    local frame1 = sheetSprite.frames[1]
    local frame2 = sheetSprite:newFrame(2)
    local frame3 = sheetSprite:newFrame(3)
    
    if not frame1 or not frame2 or not frame3 then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "Failed to create frames"
    end
    
    -- Process each view: hands array mapping:
    -- Index 0: handsDownClosed → Front
    -- Index 1: handsDownOpen → Front - Down Open (and also used for Back)
    -- Index 2: handsUp → Front - Up
    -- Index 3: Left
    -- Index 4: Right
    -- Index 5: Back (reuses index 1 - handsDownOpen)
    local viewNames = {"Front", "Front - Down Open", "Front - Up", "Left", "Right", "Back"}
    for viewIndex = 0, 5 do
        local arrayIndex = viewIndex + 1  -- Lua is 1-indexed
        -- For back view (index 5), reuse Front - Down Open (array index 2, which is handsArray[2])
        if viewIndex == 5 then
            arrayIndex = 2  -- Use handsDownOpen for back
        end
        local svgString = handsArray[arrayIndex]
        local viewName = viewNames[viewIndex + 1]
        
        print("Processing " .. viewName .. " view...")
        
        -- Convert SVG string to Image
        local baseImage, err = svgStringToImage(svgString, frameWidth, frameHeight)
        if not baseImage then
            print("  ERROR: Failed to convert SVG: " .. (err or "Unknown error"))
            if originalActiveSprite then
                app.activeSprite = originalActiveSprite
            end
            return nil, "Failed to convert SVG for " .. viewName .. " view: " .. (err or "Unknown error")
        end
        
        -- Create layer for this view with descriptive label
        local layerName = viewName .. " - Hands"
        local viewLayer = sheetSprite:newLayer(layerName)
        
        -- Create canvas images for all 3 frames
        local frame1Image = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local frame2Image = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local frame3Image = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        
        -- Calculate positions (columns 0 and 1 for hands)
        local yPos = viewIndex * frameHeight
        local leftColX = 0
        local rightColX = 64
        
        -- Create offset version once (used in multiple frames)
        local offsetImage = applyYOffsetToImage(baseImage, -1)
        
        -- Frame 1: Left column = base views, Right column = offset views
        frame1Image:drawImage(baseImage, Point(leftColX, yPos))
        frame1Image:drawImage(offsetImage, Point(rightColX, yPos))
        
        -- Frame 2: Left column = offset views, Right column = offset views (same as right of frame 1)
        frame2Image:drawImage(offsetImage, Point(leftColX, yPos))
        frame2Image:drawImage(offsetImage, Point(rightColX, yPos))
        
        -- Frame 3: Same as frame 1 for existing hands layers
        frame3Image:drawImage(baseImage, Point(leftColX, yPos))
        frame3Image:drawImage(offsetImage, Point(rightColX, yPos))
        
        -- Create cels for this view layer
        sheetSprite:newCel(viewLayer, frame1, frame1Image)
        sheetSprite:newCel(viewLayer, frame2, frame2Image)
        sheetSprite:newCel(viewLayer, frame3, frame3Image)
        
        print("  Created layer: " .. layerName)
        print("  Frame 1: base at (" .. leftColX .. ", " .. yPos .. "), offset at (" .. rightColX .. ", " .. yPos .. ")")
        print("  Frame 2: offset at (" .. leftColX .. ", " .. yPos .. "), offset at (" .. rightColX .. ", " .. yPos .. ")")
    end
    
    -- Process weapon views if available
    -- Specific positions for each weapon SVG index:
    -- Index 0: x=128, y=0
    -- Index 1: x=192, y=0
    -- Index 2: x=128, y=64
    -- Index 3: x=192, y=64
    -- Index 4: x=128, y=192
    -- Index 5: x=192, y=192
    -- Index 6: x=128, y=256
    -- Index 7: x=192, y=256
    -- Index 8: x=128, y=320
    -- Index 9: x=192, y=320
    -- Index 10: (not specified, will skip)
    if #weaponArray >= 10 then
        print("Processing weapon views...")
        
        -- Create a single layer for all weapon views
        local weaponLayer = sheetSprite:newLayer("Weapon - useItem/weapon")
        
        -- Create canvas images for all 3 frames
        local frame1Image = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local frame2Image = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local frame3Image = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        
        -- Define positions for each weapon index (0-indexed array, but Lua uses 1-indexed)
        local weaponPositions = {
            {x = 128, y = 0},    -- Index 0
            {x = 192, y = 0},    -- Index 1
            {x = 128, y = 64},   -- Index 2
            {x = 192, y = 64},   -- Index 3
            {x = 128, y = 192},  -- Index 4
            {x = 192, y = 192},  -- Index 5
            {x = 128, y = 256},  -- Index 6
            {x = 192, y = 256},  -- Index 7
            {x = 128, y = 320},  -- Index 8
            {x = 192, y = 320},  -- Index 9
        }
        
        -- First pass: draw weapons at their original positions
        for i = 1, math.min(#weaponArray, #weaponPositions) do
            local pos = weaponPositions[i]
            local svgString = weaponArray[i]
            
            local weaponImage, err = svgStringToImage(svgString, frameWidth, frameHeight)
            if weaponImage then
                -- For x=128 and x=192: all frames use base image (no offset)
                if pos.x == 128 or pos.x == 192 then
                    -- Frame 1: base view
                    frame1Image:drawImage(weaponImage, Point(pos.x, pos.y))
                    -- Frame 2: same base view (no offset)
                    frame2Image:drawImage(weaponImage, Point(pos.x, pos.y))
                    -- Frame 3: same base view (no offset)
                    frame3Image:drawImage(weaponImage, Point(pos.x, pos.y))
                    
                    print("  Added weapon index " .. (i - 1) .. " at (" .. pos.x .. ", " .. pos.y .. ") (no offset, same in all frames)")
                else
                    print("  WARNING: Unexpected x position " .. pos.x .. " for weapon index " .. (i - 1))
                end
            else
                print("  WARNING: Failed to convert weapon SVG index " .. (i - 1) .. ": " .. (err or "Unknown error"))
            end
        end
        
        -- Second pass: duplicate to x=256 column
        for i = 1, math.min(#weaponArray, #weaponPositions) do
            local pos = weaponPositions[i]
            local svgString = weaponArray[i]
            
            local weaponImage, err = svgStringToImage(svgString, frameWidth, frameHeight)
            if weaponImage then
                -- Duplicate x=128 positions to x=256 in Frame 1 (mirror x=128 column)
                if pos.x == 128 and (pos.y == 0 or pos.y == 64 or pos.y == 192 or pos.y == 256 or pos.y == 320) then
                    -- Frame 1: duplicate base view from x=128 to x=256
                    frame1Image:drawImage(weaponImage, Point(256, pos.y))
                    print("  Duplicated weapon index " .. (i - 1) .. " from (128, " .. pos.y .. ") to (256, " .. pos.y .. ") in Frame 1")
                end
                
                -- Duplicate x=192 positions to x=256 in Frame 2 (mirror x=192 column)
                if pos.x == 192 and (pos.y == 0 or pos.y == 64 or pos.y == 128 or pos.y == 192 or pos.y == 256 or pos.y == 320) then
                    -- Frame 2: duplicate base view from x=192 to x=256
                    frame2Image:drawImage(weaponImage, Point(256, pos.y))
                    print("  Duplicated weapon index " .. (i - 1) .. " from (192, " .. pos.y .. ") to (256, " .. pos.y .. ") in Frame 2")
                end
            end
        end
        
        -- Frame 3: same as Frame 1 (duplicate x=128 to x=256)
        for i = 1, math.min(#weaponArray, #weaponPositions) do
            local pos = weaponPositions[i]
            local svgString = weaponArray[i]
            
            local weaponImage, err = svgStringToImage(svgString, frameWidth, frameHeight)
            if weaponImage then
                -- Duplicate x=128 positions to x=256 in Frame 3 (same as Frame 1)
                if pos.x == 128 and (pos.y == 0 or pos.y == 64 or pos.y == 192 or pos.y == 256 or pos.y == 320) then
                    -- Frame 3: duplicate base view from x=128 to x=256 (same as Frame 1)
                    frame3Image:drawImage(weaponImage, Point(256, pos.y))
                end
                -- Also copy base positions
                if pos.x == 128 or pos.x == 192 then
                    frame3Image:drawImage(weaponImage, Point(pos.x, pos.y))
                end
            end
        end
        
        -- Create cels for weapon layer
        sheetSprite:newCel(weaponLayer, frame1, frame1Image)
        sheetSprite:newCel(weaponLayer, frame2, frame2Image)
        sheetSprite:newCel(weaponLayer, frame3, frame3Image)
        
        print("  Created weapon layer with " .. math.min(#weaponArray, #weaponPositions) .. " weapons")
    end
    
    -- Add hand take damage sequences to columns 6-8 (x=320, 384, 448)
    if #handTakeDamageData.frontDown >= 3 and #handTakeDamageData.frontUp >= 3 and 
       #handTakeDamageData.left >= 3 and #handTakeDamageData.right >= 3 then
        
        print("Adding hand take damage sequences...")
        
        -- Create hand take damage layer
        local handTakeDamageLayer = sheetSprite:newLayer("Hands - Take Damage")
        
        -- Prepare images for all hand take damage views
        local handTakeDamageImages = {
            frontDown = {},
            frontUp = {},
            left = {},
            right = {}
        }
        
        for i = 1, 3 do
            -- Front Down view
            local img, err = svgStringToImage(handTakeDamageData.frontDown[i], frameWidth, frameHeight)
            if img then table.insert(handTakeDamageImages.frontDown, img) end
            
            -- Front Up view
            img, err = svgStringToImage(handTakeDamageData.frontUp[i], frameWidth, frameHeight)
            if img then table.insert(handTakeDamageImages.frontUp, img) end
            
            -- Left view
            img, err = svgStringToImage(handTakeDamageData.left[i], frameWidth, frameHeight)
            if img then table.insert(handTakeDamageImages.left, img) end
            
            -- Right view
            img, err = svgStringToImage(handTakeDamageData.right[i], frameWidth, frameHeight)
            if img then table.insert(handTakeDamageImages.right, img) end
        end
        
        -- Create canvas images for all 3 frames
        local handTakeDamageFrameImages = {}
        for frameIdx = 1, 3 do
            handTakeDamageFrameImages[frameIdx] = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        end
        
        -- Columns 6-8: x=320, 384, 448 (static display - same in all frames)
        -- Row 2 (y=64): Front Down view take damage frames 1, 2, 3
        if #handTakeDamageImages.frontDown >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64  -- 320, 384, 448
                local y = 64  -- Row 2
                for frameIdx = 1, 3 do
                    handTakeDamageFrameImages[frameIdx]:drawImage(handTakeDamageImages.frontDown[col], Point(x, y))
                end
            end
        end
        
        -- Row 3 (y=128): Front Up view take damage frames 1, 2, 3
        if #handTakeDamageImages.frontUp >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64
                local y = 128  -- Row 3
                for frameIdx = 1, 3 do
                    handTakeDamageFrameImages[frameIdx]:drawImage(handTakeDamageImages.frontUp[col], Point(x, y))
                end
            end
        end
        
        -- Row 4 (y=192): Left view take damage frames 1, 2, 3
        if #handTakeDamageImages.left >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64
                local y = 192  -- Row 4
                for frameIdx = 1, 3 do
                    handTakeDamageFrameImages[frameIdx]:drawImage(handTakeDamageImages.left[col], Point(x, y))
                end
            end
        end
        
        -- Row 5 (y=256): Right view take damage frames 1, 2, 3
        if #handTakeDamageImages.right >= 3 then
            for col = 1, 3 do
                local x = 320 + (col - 1) * 64
                local y = 256  -- Row 5
                for frameIdx = 1, 3 do
                    handTakeDamageFrameImages[frameIdx]:drawImage(handTakeDamageImages.right[col], Point(x, y))
                end
            end
        end
        
        -- Column 9 (x=512): Animation column
        -- Row 2 (y=64): Front Down animation (frames 1-3 show frontDown frames 1-3)
        if #handTakeDamageImages.frontDown >= 3 then
            local x = 512
            local y = 64
            handTakeDamageFrameImages[1]:drawImage(handTakeDamageImages.frontDown[1], Point(x, y))
            handTakeDamageFrameImages[2]:drawImage(handTakeDamageImages.frontDown[2], Point(x, y))
            handTakeDamageFrameImages[3]:drawImage(handTakeDamageImages.frontDown[3], Point(x, y))
        end
        
        -- Row 3 (y=128): Front Up animation (frames 1-3 show frontUp frames 1-3)
        if #handTakeDamageImages.frontUp >= 3 then
            local x = 512
            local y = 128
            handTakeDamageFrameImages[1]:drawImage(handTakeDamageImages.frontUp[1], Point(x, y))
            handTakeDamageFrameImages[2]:drawImage(handTakeDamageImages.frontUp[2], Point(x, y))
            handTakeDamageFrameImages[3]:drawImage(handTakeDamageImages.frontUp[3], Point(x, y))
        end
        
        -- Row 4 (y=192): Left animation (frames 1-3 show left frames 1-3)
        if #handTakeDamageImages.left >= 3 then
            local x = 512
            local y = 192
            handTakeDamageFrameImages[1]:drawImage(handTakeDamageImages.left[1], Point(x, y))
            handTakeDamageFrameImages[2]:drawImage(handTakeDamageImages.left[2], Point(x, y))
            handTakeDamageFrameImages[3]:drawImage(handTakeDamageImages.left[3], Point(x, y))
        end
        
        -- Row 5 (y=256): Right animation (frames 1-3 show right frames 1-3)
        if #handTakeDamageImages.right >= 3 then
            local x = 512
            local y = 256
            handTakeDamageFrameImages[1]:drawImage(handTakeDamageImages.right[1], Point(x, y))
            handTakeDamageFrameImages[2]:drawImage(handTakeDamageImages.right[2], Point(x, y))
            handTakeDamageFrameImages[3]:drawImage(handTakeDamageImages.right[3], Point(x, y))
        end
        
        -- Row 6 (y=320): Duplicate row 2 (frontDown animation) for back view
        if #handTakeDamageImages.frontDown >= 3 then
            local x = 512
            local y = 320
            handTakeDamageFrameImages[1]:drawImage(handTakeDamageImages.frontDown[1], Point(x, y))
            handTakeDamageFrameImages[2]:drawImage(handTakeDamageImages.frontDown[2], Point(x, y))
            handTakeDamageFrameImages[3]:drawImage(handTakeDamageImages.frontDown[3], Point(x, y))
        end
        
        -- Create cels for all 3 frames
        sheetSprite:newCel(handTakeDamageLayer, frame1, handTakeDamageFrameImages[1])
        sheetSprite:newCel(handTakeDamageLayer, frame2, handTakeDamageFrameImages[2])
        sheetSprite:newCel(handTakeDamageLayer, frame3, handTakeDamageFrameImages[3])
        
        print("  Created hand take damage layer")
    end
    
    print("SUCCESS: Hands sprite sheet created!")
    print("Dimensions: " .. sheetWidth .. "x" .. sheetHeight)
    print("Frames: 3")
    
    -- Return the sprite
    app.activeSprite = sheetSprite
    return sheetSprite, nil
end

-- Generate collateral spritesheet from JSON file
function SpriteSheetGenerator.generateCollateralSpriteSheet(collateral, jsonPath, assetsPath)
    print("=== Collateral Sprite Sheet Generator ===")
    print("Collateral: " .. collateral)
    print("JSON Path: " .. jsonPath)
    print("")
    
    -- Save original active sprite
    local originalActiveSprite = app.activeSprite
    
    -- Validate JSON path exists
    if not app.fs.isFile(jsonPath) then
        local errMsg = "JSON file not found: " .. jsonPath
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    -- Parse JSON file
    local collateralArray, err = parseCollateralJson(jsonPath)
    if not collateralArray then
        local errMsg = err or "Failed to parse JSON"
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    print("Loaded " .. #collateralArray .. " collateral views from JSON")
    print("  Index 0: Front")
    print("  Index 1: Left")
    print("  Index 2: Right")
    print("  Row 6 (back view) will be left blank")
    print("")
    
    -- Create sprite: 576x384 (9 columns × 6 rows of 64x64 cells)
    local sheetWidth = 576
    local sheetHeight = 384
    local frameWidth = 64
    local frameHeight = 64
    
    print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
    local sheetSprite = nil
    local ok, err = pcall(function()
        sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
        app.activeSprite = sheetSprite
    end)
    
    if not ok or not sheetSprite then
        return nil, "Failed to create sprite: " .. (err or "Unknown error")
    end
    
    -- Remove default layer
    ok, err = pcall(function()
        app.activeSprite = sheetSprite
        if #sheetSprite.layers > 0 then
            local defaultLayer = sheetSprite.layers[1]
            sheetSprite:deleteLayer(defaultLayer)
        end
    end)
    
    -- Get frame 1 and create frame 2
    local frame1 = sheetSprite.frames[1]
    if not frame1 then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "Failed to create frame"
    end
    
    local frame2 = sheetSprite:newFrame()
    if not frame2 then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "Failed to create frame 2"
    end
    
    -- Convert SVG strings to images
    local frontImage, err = svgStringToImage(collateralArray[1], frameWidth, frameHeight)
    if not frontImage then
        return nil, "Failed to convert front collateral SVG: " .. (err or "Unknown error")
    end
    
    local leftImage, err = svgStringToImage(collateralArray[2], frameWidth, frameHeight)
    if not leftImage then
        return nil, "Failed to convert left collateral SVG: " .. (err or "Unknown error")
    end
    
    local rightImage, err = svgStringToImage(collateralArray[3], frameWidth, frameHeight)
    if not rightImage then
        return nil, "Failed to convert right collateral SVG: " .. (err or "Unknown error")
    end
    
    -- Use front image for back view
    local backImage = frontImage
    
    local layerCount = 0
    
    -- Row 1 (y=0): columns 1-5 (x=0, 64, 128, 192, 256) - front view
    for col = 1, 5 do
        local x = (col - 1) * 64  -- 0, 64, 128, 192, 256
        local y = 0
        local layerName = "Row 1 Col " .. col .. " - Front"
        local layer = sheetSprite:newLayer(layerName)
        
        -- Frame 1
        local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        -- Apply offset for column 2 (x=64)
        local imageToDraw1 = (col == 2) and applyYOffsetToImage(frontImage, -1) or frontImage
        layerImage1:drawImage(imageToDraw1, Point(x, y))
        sheetSprite:newCel(layer, frame1, layerImage1)
        
        -- Frame 2: Column 1 duplicates column 2 (offset), column 2 stays offset, others stay base
        local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local imageToDraw2
        if col == 1 then
            -- Column 1 in frame 2: duplicate column 2 (offset)
            imageToDraw2 = applyYOffsetToImage(frontImage, -1)
        elseif col == 2 then
            -- Column 2 in frame 2: same as frame 1 (offset)
            imageToDraw2 = applyYOffsetToImage(frontImage, -1)
        else
            -- Other columns: same as frame 1 (base)
            imageToDraw2 = frontImage
        end
        layerImage2:drawImage(imageToDraw2, Point(x, y))
        sheetSprite:newCel(layer, frame2, layerImage2)
        
        layerCount = layerCount + 1
    end
    
    -- Row 2 (y=64): columns 1-9 (x=0, 64, 128, 192, 256, 320, 384, 448, 512) - front view
    for col = 1, 9 do
        local x = (col - 1) * 64  -- 0, 64, 128, 192, 256, 320, 384, 448, 512
        local y = 64
        local layerName = "Row 2 Col " .. col .. " - Front"
        local layer = sheetSprite:newLayer(layerName)
        
        -- Frame 1
        local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        -- Apply offset for column 2 (x=64)
        local imageToDraw1 = (col == 2) and applyYOffsetToImage(frontImage, -1) or frontImage
        layerImage1:drawImage(imageToDraw1, Point(x, y))
        sheetSprite:newCel(layer, frame1, layerImage1)
        
        -- Frame 2: Column 1 duplicates column 2 (offset), column 2 stays offset, others stay base
        local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local imageToDraw2
        if col == 1 then
            -- Column 1 in frame 2: duplicate column 2 (offset)
            imageToDraw2 = applyYOffsetToImage(frontImage, -1)
        elseif col == 2 then
            -- Column 2 in frame 2: same as frame 1 (offset)
            imageToDraw2 = applyYOffsetToImage(frontImage, -1)
        else
            -- Other columns: same as frame 1 (base)
            imageToDraw2 = frontImage
        end
        layerImage2:drawImage(imageToDraw2, Point(x, y))
        sheetSprite:newCel(layer, frame2, layerImage2)
        
        layerCount = layerCount + 1
    end
    
    -- Row 3 (y=128): columns 1-2 (x=0, 64) and 6-9 (x=320, 384, 448, 512) - front view
    for col = 1, 2 do
        local x = (col - 1) * 64  -- 0, 64
        local y = 128
        local layerName = "Row 3 Col " .. col .. " - Front"
        local layer = sheetSprite:newLayer(layerName)
        
        -- Frame 1
        local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        -- Apply offset for column 2 (x=64)
        local imageToDraw1 = (col == 2) and applyYOffsetToImage(frontImage, -1) or frontImage
        layerImage1:drawImage(imageToDraw1, Point(x, y))
        sheetSprite:newCel(layer, frame1, layerImage1)
        
        -- Frame 2: Column 1 duplicates column 2 (offset), column 2 stays offset
        local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local imageToDraw2
        if col == 1 then
            -- Column 1 in frame 2: duplicate column 2 (offset)
            imageToDraw2 = applyYOffsetToImage(frontImage, -1)
        elseif col == 2 then
            -- Column 2 in frame 2: same as frame 1 (offset)
            imageToDraw2 = applyYOffsetToImage(frontImage, -1)
        else
            -- Other columns: same as frame 1 (base)
            imageToDraw2 = frontImage
        end
        layerImage2:drawImage(imageToDraw2, Point(x, y))
        sheetSprite:newCel(layer, frame2, layerImage2)
        
        layerCount = layerCount + 1
    end
    for col = 6, 9 do
        local x = (col - 1) * 64  -- 320, 384, 448, 512
        local y = 128
        local layerName = "Row 3 Col " .. col .. " - Front"
        local layer = sheetSprite:newLayer(layerName)
        
        -- Frame 1
        local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        layerImage1:drawImage(frontImage, Point(x, y))
        sheetSprite:newCel(layer, frame1, layerImage1)
        
        -- Frame 2: same as frame 1
        local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        layerImage2:drawImage(frontImage, Point(x, y))
        sheetSprite:newCel(layer, frame2, layerImage2)
        
        layerCount = layerCount + 1
    end
    
    -- Row 4 (y=192): columns 1-9 (x=0, 64, 128, 192, 256, 320, 384, 448, 512) - left view
    for col = 1, 9 do
        local x = (col - 1) * 64
        local y = 192
        local layerName = "Row 4 Col " .. col .. " - Left"
        local layer = sheetSprite:newLayer(layerName)
        
        -- Frame 1
        local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        -- Apply offset for column 2 (x=64)
        local imageToDraw1 = (col == 2) and applyYOffsetToImage(leftImage, -1) or leftImage
        layerImage1:drawImage(imageToDraw1, Point(x, y))
        sheetSprite:newCel(layer, frame1, layerImage1)
        
        -- Frame 2: Column 1 duplicates column 2 (offset), column 2 stays offset, others stay base
        local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local imageToDraw2
        if col == 1 then
            -- Column 1 in frame 2: duplicate column 2 (offset)
            imageToDraw2 = applyYOffsetToImage(leftImage, -1)
        elseif col == 2 then
            -- Column 2 in frame 2: same as frame 1 (offset)
            imageToDraw2 = applyYOffsetToImage(leftImage, -1)
        else
            -- Other columns: same as frame 1 (base)
            imageToDraw2 = leftImage
        end
        layerImage2:drawImage(imageToDraw2, Point(x, y))
        sheetSprite:newCel(layer, frame2, layerImage2)
        
        layerCount = layerCount + 1
    end
    
    -- Row 5 (y=256): columns 1-9 (x=0, 64, 128, 192, 256, 320, 384, 448, 512) - right view
    for col = 1, 9 do
        local x = (col - 1) * 64
        local y = 256
        local layerName = "Row 5 Col " .. col .. " - Right"
        local layer = sheetSprite:newLayer(layerName)
        
        -- Frame 1
        local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        -- Apply offset for column 2 (x=64)
        local imageToDraw1 = (col == 2) and applyYOffsetToImage(rightImage, -1) or rightImage
        layerImage1:drawImage(imageToDraw1, Point(x, y))
        sheetSprite:newCel(layer, frame1, layerImage1)
        
        -- Frame 2: Column 1 duplicates column 2 (offset), column 2 stays offset, others stay base
        local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
        local imageToDraw2
        if col == 1 then
            -- Column 1 in frame 2: duplicate column 2 (offset)
            imageToDraw2 = applyYOffsetToImage(rightImage, -1)
        elseif col == 2 then
            -- Column 2 in frame 2: same as frame 1 (offset)
            imageToDraw2 = applyYOffsetToImage(rightImage, -1)
        else
            -- Other columns: same as frame 1 (base)
            imageToDraw2 = rightImage
        end
        layerImage2:drawImage(imageToDraw2, Point(x, y))
        sheetSprite:newCel(layer, frame2, layerImage2)
        
        layerCount = layerCount + 1
    end
    
    -- Row 6 (y=320): Left blank (back view does not show collateral)
    
    print("  Created " .. layerCount .. " collateral layers")
    
    print("SUCCESS: Collateral sprite sheet created!")
    print("Dimensions: " .. sheetWidth .. "x" .. sheetHeight)
    print("Frames: 2")
    
    -- Return the sprite
    app.activeSprite = sheetSprite
    return sheetSprite, nil
end

-- Generate mouth spritesheet from JSON file
function SpriteSheetGenerator.generateMouthSpriteSheet(collateral, jsonPath, assetsPath)
    print("=== Mouth Sprite Sheet Generator ===")
    print("Collateral: " .. collateral)
    print("JSON Path: " .. jsonPath)
    print("")
    
    -- Save original active sprite
    local originalActiveSprite = app.activeSprite
    
    -- Validate JSON path exists
    if not app.fs.isFile(jsonPath) then
        local errMsg = "JSON file not found: " .. jsonPath
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    -- Parse JSON file
    local mouths, err = parseMouthJson(jsonPath)
    if not mouths then
        local errMsg = err or "Failed to parse JSON"
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    print("Loaded mouth SVGs from JSON")
    print("  Happy: " .. (mouths.happy and "✓" or "✗"))
    print("  Surprised: " .. (mouths.surprised and "✓" or "✗"))
    print("  Sad: " .. (mouths.sad and "✓" or "✗"))
    print("")
    
    -- Create sprite: 576x192 (9 columns × 3 rows of 64x64 cells)
    local sheetWidth = 576
    local sheetHeight = 192
    local frameWidth = 64
    local frameHeight = 64
    
    print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
    local sheetSprite = nil
    local ok, err = pcall(function()
        sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
        app.activeSprite = sheetSprite
    end)
    
    if not ok or not sheetSprite then
        return nil, "Failed to create sprite: " .. (err or "Unknown error")
    end
    
    -- Create 3 frames
    local frame1 = sheetSprite.frames[1]
    local frame2 = sheetSprite:newFrame()
    local frame3 = sheetSprite:newFrame()
    
    -- Remove default layer
    ok, err = pcall(function()
        app.activeSprite = sheetSprite
        if #sheetSprite.layers > 0 then
            local defaultLayer = sheetSprite.layers[1]
            sheetSprite:deleteLayer(defaultLayer)
        end
    end)
    
    -- Convert SVG strings to images
    local happyImage, err = svgStringToImage(mouths.happy, frameWidth, frameHeight)
    if not happyImage then
        return nil, "Failed to convert happy mouth SVG: " .. (err or "Unknown error")
    end
    
    local surprisedImage, err = svgStringToImage(mouths.surprised, frameWidth, frameHeight)
    if not surprisedImage then
        return nil, "Failed to convert surprised mouth SVG: " .. (err or "Unknown error")
    end
    
    local sadImage, err = svgStringToImage(mouths.sad, frameWidth, frameHeight)
    if not sadImage then
        return nil, "Failed to convert sad mouth SVG: " .. (err or "Unknown error")
    end
    
    -- Create offset version of happy mouth
    local happyOffset = applyYOffsetToImage(happyImage, -1)
    
    -- Create frame images for all 3 frames
    local frameImages = {}
    for i = 1, 3 do
        frameImages[i] = Image(sheetWidth, sheetHeight, ColorMode.RGB)
    end
    
    -- Row 1 (y=0)
    -- Columns 1, 3-5: happy mouth
    -- Column 2: happy mouth with offset
    -- Column 1, Frame 2: happy mouth with offset
    local row1Y = 0
    
    -- Column 1
    frameImages[1]:drawImage(happyImage, Point(0, row1Y))  -- Frame 1: base
    frameImages[2]:drawImage(happyOffset, Point(0, row1Y))  -- Frame 2: offset
    frameImages[3]:drawImage(happyImage, Point(0, row1Y))  -- Frame 3: base
    
    -- Column 2
    frameImages[1]:drawImage(happyOffset, Point(64, row1Y))  -- Frame 1: offset
    frameImages[2]:drawImage(happyOffset, Point(64, row1Y))  -- Frame 2: offset
    frameImages[3]:drawImage(happyOffset, Point(64, row1Y))  -- Frame 3: offset
    
    -- Columns 3-5
    for col = 3, 5 do
        local x = (col - 1) * 64  -- 128, 192, 256
        frameImages[1]:drawImage(happyImage, Point(x, row1Y))
        frameImages[2]:drawImage(happyImage, Point(x, row1Y))
        frameImages[3]:drawImage(happyImage, Point(x, row1Y))
    end
    
    -- Row 2 (y=64)
    -- Columns 1-5: happy mouth
    -- Column 1, Frame 2: happy mouth with offset
    -- Column 6: surprised mouth
    -- Column 7: sad mouth
    -- Column 8: surprised mouth
    -- Column 9: Animation (Frame 1: column 6, Frame 2: column 7, Frame 3: column 8)
    local row2Y = 64
    
    -- Column 1: happy mouth (offset in frame 2)
    frameImages[1]:drawImage(happyImage, Point(0, row2Y))  -- Frame 1: base
    frameImages[2]:drawImage(happyOffset, Point(0, row2Y))  -- Frame 2: offset
    frameImages[3]:drawImage(happyImage, Point(0, row2Y))  -- Frame 3: base
    
    -- Columns 2-5: happy mouth
    for col = 2, 5 do
        local x = (col - 1) * 64  -- 64, 128, 192, 256
        frameImages[1]:drawImage(happyImage, Point(x, row2Y))
        frameImages[2]:drawImage(happyImage, Point(x, row2Y))
        frameImages[3]:drawImage(happyImage, Point(x, row2Y))
    end
    
    -- Column 6: surprised mouth (static in all frames)
    frameImages[1]:drawImage(surprisedImage, Point(320, row2Y))
    frameImages[2]:drawImage(surprisedImage, Point(320, row2Y))
    frameImages[3]:drawImage(surprisedImage, Point(320, row2Y))
    
    -- Column 7: sad mouth (static in all frames)
    frameImages[1]:drawImage(sadImage, Point(384, row2Y))
    frameImages[2]:drawImage(sadImage, Point(384, row2Y))
    frameImages[3]:drawImage(sadImage, Point(384, row2Y))
    
    -- Column 8: surprised mouth (static in all frames)
    frameImages[1]:drawImage(surprisedImage, Point(448, row2Y))
    frameImages[2]:drawImage(surprisedImage, Point(448, row2Y))
    frameImages[3]:drawImage(surprisedImage, Point(448, row2Y))
    
    -- Column 9: Animation
    frameImages[1]:drawImage(surprisedImage, Point(512, row2Y))  -- Frame 1: surprised (same as col 6)
    frameImages[2]:drawImage(sadImage, Point(512, row2Y))        -- Frame 2: sad (same as col 7)
    frameImages[3]:drawImage(surprisedImage, Point(512, row2Y))  -- Frame 3: surprised (same as col 8)
    
    -- Row 3 (y=128)
    -- Columns 1-2: happy mouth
    -- Column 1, Frame 2: happy mouth with offset
    -- Column 6: surprised mouth
    -- Column 7: sad mouth
    -- Column 8: surprised mouth
    -- Column 9: Animation (Frame 1: column 6, Frame 2: column 7, Frame 3: column 8)
    local row3Y = 128
    
    -- Column 1: happy mouth (offset in frame 2)
    frameImages[1]:drawImage(happyImage, Point(0, row3Y))  -- Frame 1: base
    frameImages[2]:drawImage(happyOffset, Point(0, row3Y))  -- Frame 2: offset
    frameImages[3]:drawImage(happyImage, Point(0, row3Y))  -- Frame 3: base
    
    -- Column 2: happy mouth
    frameImages[1]:drawImage(happyImage, Point(64, row3Y))
    frameImages[2]:drawImage(happyImage, Point(64, row3Y))
    frameImages[3]:drawImage(happyImage, Point(64, row3Y))
    
    -- Column 6: surprised mouth (static in all frames)
    frameImages[1]:drawImage(surprisedImage, Point(320, row3Y))
    frameImages[2]:drawImage(surprisedImage, Point(320, row3Y))
    frameImages[3]:drawImage(surprisedImage, Point(320, row3Y))
    
    -- Column 7: sad mouth (static in all frames)
    frameImages[1]:drawImage(sadImage, Point(384, row3Y))
    frameImages[2]:drawImage(sadImage, Point(384, row3Y))
    frameImages[3]:drawImage(sadImage, Point(384, row3Y))
    
    -- Column 8: surprised mouth (static in all frames)
    frameImages[1]:drawImage(surprisedImage, Point(448, row3Y))
    frameImages[2]:drawImage(surprisedImage, Point(448, row3Y))
    frameImages[3]:drawImage(surprisedImage, Point(448, row3Y))
    
    -- Column 9: Animation
    frameImages[1]:drawImage(surprisedImage, Point(512, row3Y))  -- Frame 1: surprised (same as col 6)
    frameImages[2]:drawImage(sadImage, Point(512, row3Y))        -- Frame 2: sad (same as col 7)
    frameImages[3]:drawImage(surprisedImage, Point(512, row3Y))  -- Frame 3: surprised (same as col 8)
    
    -- Create single layer and add cels for all frames
    local mouthLayer = sheetSprite:newLayer("Mouth")
    sheetSprite:newCel(mouthLayer, frame1, frameImages[1])
    sheetSprite:newCel(mouthLayer, frame2, frameImages[2])
    sheetSprite:newCel(mouthLayer, frame3, frameImages[3])
    
    print("  Created mouth layer with 3 frames")
    print("SUCCESS: Mouth sprite sheet created!")
    print("Dimensions: " .. sheetWidth .. "x" .. sheetHeight)
    print("Frames: 3")
    
    -- Return the sprite
    app.activeSprite = sheetSprite
    return sheetSprite, nil
end

-- Generate eyes spritesheet from JSON file
function SpriteSheetGenerator.generateEyesSpriteSheet(rarity, jsonPath, assetsPath)
    print("=== Eyes Sprite Sheet Generator ===")
    print("Rarity: " .. rarity)
    print("JSON Path: " .. jsonPath)
    print("")
    
    -- Save original active sprite
    local originalActiveSprite = app.activeSprite
    
    -- Validate JSON path exists
    if not app.fs.isFile(jsonPath) then
        local errMsg = "JSON file not found: " .. jsonPath
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    -- Parse JSON file
    local eyesArray, err = parseEyesJson(jsonPath)
    if not eyesArray then
        local errMsg = err or "Failed to parse JSON"
        print("ERROR: " .. errMsg)
        return nil, errMsg
    end
    
    print("Loaded " .. #eyesArray .. " eye views from JSON")
    print("  Index 0: Front")
    print("  Index 1: Left")
    print("  Index 2: Right")
    print("")
    
    -- Get rarity hex color and apply to SVGs
    print("Getting rarity hex color for: " .. rarity)
    local rarityHex, err = getRarityHexColor(rarity, assetsPath)
    if err then
        print("WARNING: Could not get rarity color: " .. err)
        print("  Using colors from JSON file (collateral color for common rarity)")
    else
        if rarityHex then
            print("Applying rarity color to eyes: " .. rarityHex)
            -- Apply color to all eye SVGs
            for i = 1, #eyesArray do
                eyesArray[i] = applyEyeColorToSvg(eyesArray[i], rarityHex)
            end
        else
            print("Using collateral color (common rarity or no hex specified)")
        end
    end
    print("")
    
    -- Create sprite: 576x384 (9 columns × 6 rows of 64x64 cells)
    local sheetWidth = 576
    local sheetHeight = 384
    local frameWidth = 64
    local frameHeight = 64
    
    print("Creating sprite: " .. sheetWidth .. "x" .. sheetHeight)
    local sheetSprite = nil
    local ok, err = pcall(function()
        sheetSprite = Sprite(sheetWidth, sheetHeight, ColorMode.RGB)
        app.activeSprite = sheetSprite
    end)
    
    if not ok or not sheetSprite then
        return nil, "Failed to create sprite: " .. (err or "Unknown error")
    end
    
    -- Remove default layer
    ok, err = pcall(function()
        app.activeSprite = sheetSprite
        if #sheetSprite.layers > 0 then
            local defaultLayer = sheetSprite.layers[1]
            sheetSprite:deleteLayer(defaultLayer)
        end
    end)
    
    -- Get frame 1 and create frame 2
    local frame1 = sheetSprite.frames[1]
    if not frame1 then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "Failed to create frame"
    end
    
    local frame2 = sheetSprite:newFrame()
    if not frame2 then
        if originalActiveSprite then
            app.activeSprite = originalActiveSprite
        end
        return nil, "Failed to create frame 2"
    end
    
    -- Convert SVG strings to images
    local frontImage, err = svgStringToImage(eyesArray[1], frameWidth, frameHeight)
    if not frontImage then
        return nil, "Failed to convert front eye SVG: " .. (err or "Unknown error")
    end
    
    local leftImage, err = svgStringToImage(eyesArray[2], frameWidth, frameHeight)
    if not leftImage then
        return nil, "Failed to convert left eye SVG: " .. (err or "Unknown error")
    end
    
    local rightImage, err = svgStringToImage(eyesArray[3], frameWidth, frameHeight)
    if not rightImage then
        return nil, "Failed to convert right eye SVG: " .. (err or "Unknown error")
    end
    
    -- Create offset versions
    local frontOffset = applyYOffsetToImage(frontImage, -1)
    local leftOffset = applyYOffsetToImage(leftImage, -1)
    local rightOffset = applyYOffsetToImage(rightImage, -1)
    
    local layerCount = 0
    
    -- Row 1 (y=0): columns 1, 3-5 use front view; column 2 apply offset
    -- Row 1, column 1, frame 2: add offset
    for col = 1, 5 do
        if col == 1 or col == 2 or (col >= 3 and col <= 5) then
            local x = (col - 1) * 64  -- 0, 64, 128, 192, 256
            local y = 0
            local layerName = "Row 1 Col " .. col .. " - Front"
            local layer = sheetSprite:newLayer(layerName)
            
            -- Frame 1
            local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            local imageToDraw1
            if col == 2 then
                imageToDraw1 = frontOffset  -- Column 2: offset
            else
                imageToDraw1 = frontImage   -- Columns 1, 3-5: base
            end
            layerImage1:drawImage(imageToDraw1, Point(x, y))
            sheetSprite:newCel(layer, frame1, layerImage1)
            
            -- Frame 2
            local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            local imageToDraw2
            if col == 1 then
                imageToDraw2 = frontOffset  -- Column 1, frame 2: offset
            elseif col == 2 then
                imageToDraw2 = frontOffset  -- Column 2, frame 2: offset (same as frame 1)
            else
                imageToDraw2 = frontImage   -- Columns 3-5, frame 2: base (same as frame 1)
            end
            layerImage2:drawImage(imageToDraw2, Point(x, y))
            sheetSprite:newCel(layer, frame2, layerImage2)
            
            layerCount = layerCount + 1
        end
    end
    
    -- Row 2 (y=64): columns 1, 3-5 use front view; column 2 apply offset
    -- Row 2, column 1, frame 2: add offset
    for col = 1, 5 do
        if col == 1 or col == 2 or (col >= 3 and col <= 5) then
            local x = (col - 1) * 64  -- 0, 64, 128, 192, 256
            local y = 64
            local layerName = "Row 2 Col " .. col .. " - Front"
            local layer = sheetSprite:newLayer(layerName)
            
            -- Frame 1
            local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            local imageToDraw1
            if col == 2 then
                imageToDraw1 = frontOffset  -- Column 2: offset
            else
                imageToDraw1 = frontImage   -- Columns 1, 3-5: base
            end
            layerImage1:drawImage(imageToDraw1, Point(x, y))
            sheetSprite:newCel(layer, frame1, layerImage1)
            
            -- Frame 2
            local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            local imageToDraw2
            if col == 1 then
                imageToDraw2 = frontOffset  -- Column 1, frame 2: offset
            elseif col == 2 then
                imageToDraw2 = frontOffset  -- Column 2, frame 2: offset (same as frame 1)
            else
                imageToDraw2 = frontImage   -- Columns 3-5, frame 2: base (same as frame 1)
            end
            layerImage2:drawImage(imageToDraw2, Point(x, y))
            sheetSprite:newCel(layer, frame2, layerImage2)
            
            layerCount = layerCount + 1
        end
    end
    
    -- Row 3 (y=128): Left blank
    
    -- Row 4 (y=192): columns 1 and 3-5 use left view
    -- Row 4, column 1, frame 2: add offset
    for col = 1, 5 do
        if col == 1 or (col >= 3 and col <= 5) then
            local x = (col - 1) * 64  -- 0, 128, 192, 256
            local y = 192
            local layerName = "Row 4 Col " .. col .. " - Left"
            local layer = sheetSprite:newLayer(layerName)
            
            -- Frame 1
            local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            layerImage1:drawImage(leftImage, Point(x, y))  -- All columns: base
            sheetSprite:newCel(layer, frame1, layerImage1)
            
            -- Frame 2
            local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            local imageToDraw2
            if col == 1 then
                imageToDraw2 = leftOffset   -- Column 1, frame 2: offset
            else
                imageToDraw2 = leftImage    -- Columns 3-5, frame 2: base
            end
            layerImage2:drawImage(imageToDraw2, Point(x, y))
            sheetSprite:newCel(layer, frame2, layerImage2)
            
            layerCount = layerCount + 1
        end
    end
    
    -- Row 5 (y=256): columns 1 and 3-5 use right view
    -- Row 5, column 1, frame 2: add offset
    for col = 1, 5 do
        if col == 1 or (col >= 3 and col <= 5) then
            local x = (col - 1) * 64  -- 0, 128, 192, 256
            local y = 256
            local layerName = "Row 5 Col " .. col .. " - Right"
            local layer = sheetSprite:newLayer(layerName)
            
            -- Frame 1
            local layerImage1 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            layerImage1:drawImage(rightImage, Point(x, y))  -- All columns: base
            sheetSprite:newCel(layer, frame1, layerImage1)
            
            -- Frame 2
            local layerImage2 = Image(sheetWidth, sheetHeight, ColorMode.RGB)
            local imageToDraw2
            if col == 1 then
                imageToDraw2 = rightOffset  -- Column 1, frame 2: offset
            else
                imageToDraw2 = rightImage   -- Columns 3-5, frame 2: base
            end
            layerImage2:drawImage(imageToDraw2, Point(x, y))
            sheetSprite:newCel(layer, frame2, layerImage2)
            
            layerCount = layerCount + 1
        end
    end
    
    -- Row 6 (y=320): Left blank
    
    print("  Created " .. layerCount .. " eye layers")
    
    print("SUCCESS: Eyes sprite sheet created!")
    print("Dimensions: " .. sheetWidth .. "x" .. sheetHeight)
    print("Frames: 2")
    
    -- Return the sprite
    app.activeSprite = sheetSprite
    return sheetSprite, nil
end

return SpriteSheetGenerator

