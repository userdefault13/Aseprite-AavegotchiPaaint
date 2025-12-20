-- Batch import SVGs from collateral JSON file
-- Usage: aseprite -b --script batch-import-body-svgs.lua --script-param jsonFile:path/to/file.json

-- Load SVG importer modules
-- Try multiple possible paths
local svgParserPath = nil
local svgRendererPath = nil

-- Get the script's directory
local scriptPath = app.params["script"] or "batch-import-body-svgs.lua"
local scriptDir = app.fs.filePath(scriptPath)
if scriptDir == "" then
    scriptDir = app.fs.currentPath
end

local possiblePaths = {
    app.fs.joinPath(scriptDir, "../aesprite-svgimporter/extracted/svg-parser.lua"),
    app.fs.joinPath(scriptDir, "aesprite-svgimporter/extracted/svg-parser.lua"),
    "../aesprite-svgimporter/extracted/svg-parser.lua",
    "aesprite-svgimporter/extracted/svg-parser.lua",
    "../../aesprite-svgimporter/extracted/svg-parser.lua",
    "/Users/juliuswong/Dev/aesprite-svgimporter/extracted/svg-parser.lua"
}

print("DEBUG: Looking for SVG parser module...")
print("DEBUG: Script directory: " .. scriptDir)
print("DEBUG: Current path: " .. app.fs.currentPath)

for _, path in ipairs(possiblePaths) do
    print("DEBUG: Checking: " .. path)
    if app.fs.isFile(path) then
        svgParserPath = path
        svgRendererPath = path:gsub("svg-parser", "svg-renderer-professional")
        print("DEBUG: Found parser at: " .. svgParserPath)
        print("DEBUG: Renderer path: " .. svgRendererPath)
        break
    end
end

if not svgParserPath then
    print("ERROR: Could not find SVG parser module")
    print("Searched paths:")
    for _, path in ipairs(possiblePaths) do
        print("  - " .. path .. " (exists: " .. tostring(app.fs.isFile(path)) .. ")")
    end
    return
end

-- Fix renderer path
svgRendererPath = svgParserPath:gsub("svg%-parser%.lua", "svg-renderer-professional.lua")
print("DEBUG: Loading parser from: " .. svgParserPath)
print("DEBUG: Loading renderer from: " .. svgRendererPath)

local SVGParser = dofile(svgParserPath)
local SVGRenderer = dofile(svgRendererPath)

if not SVGParser then
    print("ERROR: Failed to load SVG parser")
    return
end

if not SVGRenderer then
    print("ERROR: Failed to load SVG renderer")
    return
end

print("DEBUG: Modules loaded successfully")

-- Simple JSON parser for our specific structure
local function parseJSON(jsonContent)
    local data = {}
    
    -- Extract body array
    local bodyStart = jsonContent:find('"body"%s*:%s*%[')
    if bodyStart then
        data.body = {}
        -- Find array content
        local arrayStart = jsonContent:find('%[', bodyStart)
        local bracketCount = 0
        local inString = false
        local escapeNext = false
        local currentString = ""
        local stringStart = nil
        
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
                -- Don't add the backslash itself, wait for next char
            elseif char == '"' then
                if inString then
                    -- End of string
                    table.insert(data.body, currentString)
                    currentString = ""
                    inString = false
                else
                    -- Start of string
                    inString = true
                    stringStart = i
                end
            elseif inString then
                currentString = currentString .. char
            elseif char == ']' and not inString then
                break
            end
        end
    end
    
    -- Extract other arrays similarly
    local function extractArray(key)
        local keyStart = jsonContent:find('"' .. key .. '"%s*:%s*%[')
        if keyStart then
            data[key] = {}
            local arrayStart = jsonContent:find('%[', keyStart)
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
                    -- Don't add the backslash itself
                elseif char == '"' then
                    if inString then
                        table.insert(data[key], currentString)
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
    
    extractArray("hands")
    extractArray("mouth_neutral")
    extractArray("mouth_happy")
    extractArray("eyes_mad")
    extractArray("eyes_happy")
    extractArray("eyes_sleepy")
    extractArray("shadow")
    
    return data
end

-- Import SVG and save as Aseprite file
local function importSVG(svgCode, outputPath, canvasWidth, canvasHeight)
    -- Parse SVG
    local svgData = SVGParser.parse(svgCode)
    
    if not svgData or not svgData.viewBox then
        print("ERROR: Failed to parse SVG")
        return false
    end
    
    -- Use SVG's native dimensions if not specified
    if not canvasWidth or not canvasHeight then
        canvasWidth = math.floor(svgData.viewBox.width)
        canvasHeight = math.floor(svgData.viewBox.height)
    end
    
    -- Render to pixels
    local renderResult = SVGRenderer.render(svgData, canvasWidth, canvasHeight)
    
    if not renderResult or #renderResult.pixels == 0 then
        print("ERROR: No pixels rendered")
        return false
    end
    
    -- Create new sprite
    local sprite = Sprite(canvasWidth, canvasHeight, ColorMode.RGB)
    local layer = sprite.layers[1]
    local cel = sprite:newCel(layer, 1)
    local image = cel.image
    
    -- Draw pixels
    app.transaction(
        function()
            for _, pixel in ipairs(renderResult.pixels) do
                if pixel.x >= 0 and pixel.x < canvasWidth and pixel.y >= 0 and pixel.y < canvasHeight then
                    local color = Color{r = pixel.color.r, g = pixel.color.g, b = pixel.color.b}
                    image:drawPixel(pixel.x, pixel.y, color)
                end
            end
        end
    )
    
    -- Save sprite
    sprite:saveAs(outputPath)
    sprite:close()
    
    return true
end

-- Main batch processing function
local function processJSONFile(jsonFilePath, outputDir)
    -- Read JSON file
    local file = io.open(jsonFilePath, "r")
    if not file then
        print("ERROR: Could not open JSON file: " .. jsonFilePath)
        return
    end
    
    local jsonContent = file:read("*all")
    file:close()
    
    if not jsonContent or jsonContent == "" then
        print("ERROR: JSON file is empty")
        return
    end
    
    -- Parse JSON
    local data = parseJSON(jsonContent)
    
    if not data then
        print("ERROR: Failed to parse JSON")
        return
    end
    
    -- Create output directory if it doesn't exist
    if outputDir and not app.fs.isDirectory(outputDir) then
        app.fs.makeDirectory(outputDir)
    end
    
    -- Extract base name from JSON file
    local baseName = jsonFilePath:match("([^/]+)%.json$") or "output"
    baseName = baseName:gsub("collateral%-base%-", "")
    
    -- Process body SVGs
    if data.body then
        local bodyNames = {"front", "left", "right", "back"}
        for i, svgCode in ipairs(data.body) do
            local name = bodyNames[i] or ("body_" .. i)
            local outputPath = outputDir .. "/body_" .. name .. "_" .. baseName .. ".aseprite"
            print("Processing body " .. name .. "...")
            if importSVG(svgCode, outputPath, 64, 64) then
                print("  ✓ Saved: " .. outputPath)
            else
                print("  ✗ Failed: " .. outputPath)
            end
        end
    end
    
    -- Process hands SVGs
    if data.hands then
        local handNames = {"closed", "open", "up", "left_wearable", "right_wearable"}
        for i, svgCode in ipairs(data.hands) do
            local name = handNames[i] or ("hand_" .. i)
            local outputPath = outputDir .. "/hand_" .. name .. "_" .. baseName .. ".aseprite"
            print("Processing hand " .. name .. "...")
            if importSVG(svgCode, outputPath, 64, 64) then
                print("  ✓ Saved: " .. outputPath)
            else
                print("  ✗ Failed: " .. outputPath)
            end
        end
    end
    
    -- Process other parts
    local parts = {
        "mouth_neutral", "mouth_happy",
        "eyes_mad", "eyes_happy", "eyes_sleepy",
        "shadow"
    }
    
    for _, partName in ipairs(parts) do
        if data[partName] then
            for i, svgCode in ipairs(data[partName]) do
                local outputPath = outputDir .. "/" .. partName .. "_" .. i .. "_" .. baseName .. ".aseprite"
                print("Processing " .. partName .. " " .. i .. "...")
                if importSVG(svgCode, outputPath, 64, 64) then
                    print("  ✓ Saved: " .. outputPath)
                else
                    print("  ✗ Failed: " .. outputPath)
                end
            end
        end
    end
    
    print("\nBatch processing complete!")
end

-- Get parameters from command line
local jsonFile = app.params["jsonFile"] or app.params.jsonFile
local outputDir = app.params["outputDir"] or app.params.outputDir or "Output/bodies"

if not jsonFile then
    -- Default to mayfi if no parameter
    jsonFile = "JSONs/Body/collateral-base-mayfi.json"
end

if app.fs.isFile(jsonFile) then
    print("Processing JSON file: " .. jsonFile)
    print("Output directory: " .. outputDir)
    print("")
    processJSONFile(jsonFile, outputDir)
else
    print("ERROR: JSON file not found: " .. jsonFile)
    print("Usage: aseprite -b --script batch-import-body-svgs.lua --script-param jsonFile:path/to/file.json")
end

