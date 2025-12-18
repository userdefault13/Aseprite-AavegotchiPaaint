-- Import Body SVGs Script
-- This script imports the 4 body SVG views from JSON into Aseprite
-- Usage: Run this script and it will import all 4 views for a specified collateral

-- Configuration
-- Use absolute path to the JSON file
local jsonPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint/JSONs/aavegotchi_db_body.json"

local collateral = "amAAVE"  -- Change this to the desired collateral
-- Available collaterals: amaave, amdai, amusdc, amusdt, amwbtc, amweth, amwmatic, maaave, madai, malink, matusd, mauni, mausdc, mausdt, maweth, mayfi

-- Get temporary directory (cross-platform)
local tempDir = os.getenv("TMPDIR") or os.getenv("TMP") or os.getenv("TEMP") or "/tmp"

-- Get list of available collaterals from JSON
local function getAvailableCollaterals(jsonPath)
    local file = io.open(jsonPath, "r")
    if not file then
        return {}
    end
    
    local content = file:read("*all")
    file:close()
    
    local collaterals = {}
    -- Find all collateral keys in the "bodies" object
    for collateral in content:gmatch('"([^"]+)":%s*{%s*"back"') do
        table.insert(collaterals, collateral)
    end
    
    return collaterals
end

-- Extract SVG string from JSON for a specific collateral and view
local function extractSvgFromJson(jsonPath, collateral, view)
    local file = io.open(jsonPath, "r")
    if not file then
        return nil, "Could not open JSON file: " .. jsonPath
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
    local svgStart = viewStart + #viewPattern
    local svgEnd = svgStart
    local inEscape = false
    
    while svgEnd <= #content do
        local char = content:sub(svgEnd, svgEnd)
        if inEscape then
            inEscape = false
        elseif char == "\\" then
            inEscape = true
        elseif char == '"' and not inEscape then
            break
        end
        svgEnd = svgEnd + 1
    end
    
    local svgString = content:sub(svgStart, svgEnd - 1)
    -- Unescape the SVG string
    svgString = svgString:gsub('\\"', '"')
    svgString = svgString:gsub('\\\\', '\\')
    svgString = svgString:gsub('\\n', '\n')
    svgString = svgString:gsub('\\r', '\r')
    svgString = svgString:gsub('\\t', '\t')
    
    return svgString, nil
end

-- Write SVG string to a temporary file
local function writeSvgToFile(svgString, filePath)
    local file = io.open(filePath, "w")
    if not file then
        return false, "Could not create SVG file: " .. filePath
    end
    
    file:write(svgString)
    file:close()
    
    return true, nil
end

-- Import SVG file into Aseprite
local function importSvgFile(svgPath, viewName)
    if not app.fs.isFile(svgPath) then
        return false, "SVG file does not exist: " .. svgPath
    end
    
    -- Open the SVG file in Aseprite
    -- Aseprite will automatically convert SVG to a sprite
    local sprite = app.open(svgPath)
    if not sprite then
        return false, "Could not import SVG file: " .. svgPath
    end
    
    -- Note: We can't directly set filename, but the sprite is now open in Aseprite
    -- The user can save it with the desired name
    
    return true, sprite
end

-- Main function to import all 4 views
local function importAllBodyViews(jsonPath, collateral, tempDir)
    local views = {"front", "back", "left", "right"}
    local results = {}
    local tempFiles = {}  -- Track temp files for cleanup
    
    app.alert("Starting import of " .. collateral .. " body views from JSON...")
    
    -- Check if JSON file exists
    if not app.fs.isFile(jsonPath) then
        app.alert("Error: JSON file not found at: " .. jsonPath)
        return results
    end
    
    for _, view in ipairs(views) do
        -- Extract SVG from JSON
        local svgString, err = extractSvgFromJson(jsonPath, collateral, view)
        if not svgString then
            results[view] = {
                success = false,
                error = err or "Failed to extract SVG"
            }
            goto continue
        end
        
        -- Write SVG to temporary file
        local tempSvgPath = app.fs.joinPath(tempDir, "body_" .. view .. "_" .. collateral .. ".svg")
        local writeSuccess, writeErr = writeSvgToFile(svgString, tempSvgPath)
        if not writeSuccess then
            results[view] = {
                success = false,
                error = writeErr or "Failed to write SVG file"
            }
            goto continue
        end
        
        table.insert(tempFiles, tempSvgPath)
        
        -- Import SVG into Aseprite
        local importSuccess, sprite = importSvgFile(tempSvgPath, "body_" .. view .. "_" .. collateral)
        if not importSuccess then
            results[view] = {
                success = false,
                error = sprite or "Failed to import SVG"
            }
            goto continue
        end
        
        results[view] = {
            success = true,
            sprite = sprite,
            path = tempSvgPath
        }
        
        ::continue::
    end
    
    -- Clean up temporary files (optional - comment out if you want to keep them for debugging)
    -- for _, tempFile in ipairs(tempFiles) do
    --     os.remove(tempFile)
    -- end
    
    -- Report results
    local successCount = 0
    local errorCount = 0
    local messages = {}
    
    for view, result in pairs(results) do
        if result.success then
            successCount = successCount + 1
            table.insert(messages, "✓ " .. view .. ": Imported successfully")
        else
            errorCount = errorCount + 1
            table.insert(messages, "✗ " .. view .. ": " .. (result.error or "Failed"))
        end
    end
    
    local summary = "Import complete!\n\n"
    summary = summary .. "Success: " .. successCount .. "\n"
    summary = summary .. "Errors: " .. errorCount .. "\n\n"
    summary = summary .. table.concat(messages, "\n")
    
    app.alert(summary)
    
    return results
end

-- Validate collateral exists
local availableCollaterals = getAvailableCollaterals(jsonPath)
local collateralLower = collateral:lower()
local found = false
for _, avail in ipairs(availableCollaterals) do
    if avail:lower() == collateralLower then
        found = true
        break
    end
end

if not found then
    local message = "Collateral '" .. collateral .. "' not found in JSON.\n\n"
    message = message .. "Available collaterals:\n"
    for _, avail in ipairs(availableCollaterals) do
        message = message .. "  - " .. avail .. "\n"
    end
    app.alert(message)
    return
end

-- Run the import
importAllBodyViews(jsonPath, collateral, tempDir)

