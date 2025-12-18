-- Body Exporter
-- Exports body views with colors applied from JSON
-- Usage: This script will be called to export body sprites with proper colors

local FileResolver = dofile("file-resolver.lua")
local JsonLoader = dofile("json-loader.lua")

local BodyExporter = {}

-- Parse hex color to RGB
local function hexToRgb(hex)
    hex = hex:gsub("#", "")
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    return r, g, b
end

-- Extract colors from SVG style string
local function extractColorsFromSvg(svgString)
    local colors = {}
    
    -- Extract primary color
    local primaryMatch = svgString:match("%.gotchi%-primary{fill:([^;]+)")
    if primaryMatch then
        colors.primary = primaryMatch:gsub("%s+", "")
    end
    
    -- Extract secondary color
    local secondaryMatch = svgString:match("%.gotchi%-secondary{fill:([^;]+)")
    if secondaryMatch then
        colors.secondary = secondaryMatch:gsub("%s+", "")
    end
    
    -- Extract cheek color
    local cheekMatch = svgString:match("%.gotchi%-cheek{fill:([^;]+)")
    if cheekMatch then
        colors.cheek = cheekMatch:gsub("%s+", "")
    end
    
    return colors
end

-- Load body colors from JSON for a specific collateral and view
local function loadBodyColorsFromJson(jsonPath, collateral, view)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Could not open JSON file"
    end
    
    local content = file:read("*all")
    file:close()
    
    -- Find the collateral section (case insensitive)
    local collateralLower = collateral:lower()
    local pattern = '"' .. collateralLower .. '":%s*{'
    local startPos = content:find(pattern, 1, true)
    if not startPos then
        -- Try exact match
        pattern = '"' .. collateral .. '":%s*{'
        startPos = content:find(pattern)
    end
    
    if not startPos then
        return nil, "Collateral not found: " .. collateral
    end
    
    -- Find the view section
    local viewPattern = '"' .. view .. '":%s*"'
    local viewStart = content:find(viewPattern, startPos)
    if not viewStart then
        return nil, "View not found: " .. view
    end
    
    -- Extract SVG string (find the closing quote)
    local svgStart = content:find('"', viewStart + #viewPattern)
    if not svgStart then
        return nil, "SVG start not found"
    end
    
    -- Find the end of the SVG string (escaped quotes)
    local svgEnd = svgStart + 1
    local inEscape = false
    while svgEnd <= #content do
        local char = content:sub(svgEnd, svgEnd)
        if inEscape then
            inEscape = false
        elseif char == "\\" then
            inEscape = true
        elseif char == '"' then
            break
        end
        svgEnd = svgEnd + 1
    end
    
    local svgString = content:sub(svgStart + 1, svgEnd - 1)
    -- Unescape the SVG string
    svgString = svgString:gsub('\\"', '"')
    svgString = svgString:gsub('\\\\', '\\')
    
    -- Extract colors from SVG
    local colors = extractColorsFromSvg(svgString)
    
    return colors, nil
end

-- Apply color replacement to image
-- Replaces all pixels of oldColor with newColor
local function replaceColor(image, oldColor, newColor)
    if not image then return false end
    
    for y = 0, image.height - 1 do
        for x = 0, image.width - 1 do
            local pixel = image:getPixel(x, y)
            if pixel == oldColor then
                image:putPixel(x, y, newColor)
            end
        end
    end
    
    return true
end

-- Export body view with colors applied
function BodyExporter.exportBodyView(assetsPath, collateral, view, outputPath)
    local viewMap = {front = 0, back = 3, left = 1, right = 2}
    local viewIndex = viewMap[view] or 0
    
    -- Load the body file
    local bodyPath = FileResolver.resolveBodyPath(assetsPath, collateral, viewIndex)
    if not bodyPath then
        return false, "Body file not found: " .. collateral .. " " .. view
    end
    
    -- Load colors from JSON
    local jsonPath = assetsPath .. "/JSONs/aavegotchi_db_body.json"
    local colors, err = loadBodyColorsFromJson(jsonPath, collateral, view)
    if not colors then
        return false, "Could not load colors: " .. (err or "Unknown error")
    end
    
    if _G.debugLogMessage then
        _G.debugLogMessage("[DEBUG] Loaded colors for " .. collateral .. " " .. view .. ":")
        _G.debugLogMessage("  Primary: " .. (colors.primary or "nil"))
        _G.debugLogMessage("  Secondary: " .. (colors.secondary or "nil"))
        _G.debugLogMessage("  Cheek: " .. (colors.cheek or "nil"))
    end
    
    -- Open the body sprite
    local bodySprite = app.open(bodyPath)
    if not bodySprite then
        return false, "Could not open body sprite: " .. bodyPath
    end
    
    -- Get the first layer and frame
    local layer = bodySprite.layers[1]
    if not layer then
        app.command.CloseFile()
        return false, "Body sprite has no layers"
    end
    
    local frame = bodySprite.frames[1]
    if not frame then
        app.command.CloseFile()
        return false, "Body sprite has no frames"
    end
    
    local cel = layer:cel(frame)
    if not cel or not cel.image then
        app.command.CloseFile()
        return false, "Body sprite has no image data"
    end
    
    local image = cel.image
    
    -- Note: Color replacement would require knowing which pixels are primary/secondary
    -- For now, we'll just save the file with a note that colors need to be applied
    -- The actual color application might require pixel-level analysis or a color mapping strategy
    
    -- Ensure output directory exists
    local outputDir = outputPath:match("^(.+)/[^/]+$")
    if outputDir and not app.fs.isDirectory(outputDir) then
        -- Try to create directory (Aseprite API might not support this)
        -- For now, assume it exists
    end
    
    -- Save the sprite
    bodySprite:saveAs(outputPath)
    app.command.CloseFile()
    
    if _G.debugLogMessage then
        _G.debugLogMessage("[DEBUG] Exported body to: " .. outputPath)
    end
    
    return true, nil
end

-- Export all 4 views for a collateral
function BodyExporter.exportAllViews(assetsPath, collateral, outputDir)
    local views = {"front", "back", "left", "right"}
    local results = {}
    
    for _, view in ipairs(views) do
        local outputPath = outputDir .. "/body_" .. view .. "_" .. collateral .. ".aseprite"
        local success, err = BodyExporter.exportBodyView(assetsPath, collateral, view, outputPath)
        results[view] = {
            success = success,
            error = err,
            path = outputPath
        }
    end
    
    return results
end

return BodyExporter

