-- Wearable Scanner
-- Scans the Aseprites/Wearables directory to index available wearables

local WearableScanner = {}

-- Scan wearables directory and return a map of wearable ID -> {id, name, path}
function WearableScanner.scanWearablesDirectory(assetsPath)
    local wearablesMap = {}
    local wearablesDir = assetsPath .. "/Aseprites/Wearables"
    
    if not app.fs.isDirectory(wearablesDir) then
        return wearablesMap
    end
    
    -- Try to read directory entries
    -- Note: Aseprite's file system API may be limited, so we'll try to match patterns
    -- For now, we'll use a simpler approach: try to check for common wearable IDs
    
    -- Actually, since we can't easily list directories in Aseprite Lua,
    -- we'll rely on the JSON database and just verify files exist when needed
    -- This function is a placeholder for future directory scanning if needed
    
    return wearablesMap
end

-- Normalize wearable name to match directory structure
-- Removes spaces and converts to match directory naming
local function normalizeWearableName(name)
    -- Remove all spaces
    return name:gsub("%s+", "")
end

-- Verify if a wearable file exists for a given view
function WearableScanner.verifyWearableExists(assetsPath, wearableId, wearableName, viewIndex)
    local viewNames = {"front", "left", "right", "back"}
    local viewName = viewNames[viewIndex + 1] or "front"
    
    -- Try normalized name first (removes spaces - most common)
    local normalizedName = normalizeWearableName(wearableName)
    local wearableDir = assetsPath .. "/Aseprites/Wearables/" .. wearableId .. "_" .. normalizedName
    
    -- If normalized directory doesn't exist, try original name
    if not app.fs.isDirectory(wearableDir) then
        wearableDir = assetsPath .. "/Aseprites/Wearables/" .. wearableId .. "_" .. wearableName
        if not app.fs.isDirectory(wearableDir) then
            return false, nil
        end
    end
    
    -- Check for view subdirectory (capitalized)
    local viewMap = {
        front = "Front",
        left = "Left",
        right = "Right",
        back = "Back"
    }
    local viewCap = viewMap[viewName] or "Front"
    
    -- Use normalized name in file paths (matches directory structure)
    -- Try subdirectory pattern FIRST (most common): Front/{id}_{normalizedName}_Front.aseprite
    local filePath = wearableDir .. "/" .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewCap .. ".aseprite"
    if app.fs.isFile(filePath) then
        return true, filePath
    end
    
    -- Try flat file pattern: {id}_{normalizedName}_{view}.aseprite (directly in wearable folder)
    -- This matches structure like: 1_CamoHat_front.aseprite
    filePath = wearableDir .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewName .. ".aseprite"
    if app.fs.isFile(filePath) then
        return true, filePath
    end
    
    -- Try alternative subdirectory pattern: Front/{id}_{normalizedName}_front.aseprite (lowercase)
    filePath = wearableDir .. "/" .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewName .. ".aseprite"
    if app.fs.isFile(filePath) then
        return true, filePath
    end
    
    -- For side views, try SideLeft/SideRight
    if viewIndex == 1 then
        filePath = wearableDir .. "/Left/" .. wearableId .. "_" .. normalizedName .. "_SideLeft.aseprite"
        if app.fs.isFile(filePath) then
            return true, filePath
        end
    elseif viewIndex == 2 then
        filePath = wearableDir .. "/Right/" .. wearableId .. "_" .. normalizedName .. "_SideRight.aseprite"
        if app.fs.isFile(filePath) then
            return true, filePath
        end
    end
    
    -- Last resort: try with original name (in case some wearables use spaces in filenames)
    filePath = wearableDir .. "/" .. viewCap .. "/" .. wearableId .. "_" .. wearableName .. "_" .. viewCap .. ".aseprite"
    if app.fs.isFile(filePath) then
        return true, filePath
    end
    
    return false, nil
end

return WearableScanner

