-- File Resolver for Aavegotchi .aseprite files
-- Resolves file paths based on selections (collateral, view, expressions, etc.)

local FileResolver = {}

-- View name mapping
local viewNames = {"front", "left", "right", "back"}

-- Helper: Check if file exists
local function fileExists(path)
    return app.fs.isFile(path)
end

-- Resolve body file path
function FileResolver.resolveBodyPath(assetsPath, collateral, viewIndex)
    local viewName = viewNames[viewIndex + 1] or "front"
    
    -- Try pattern: body_{view}_{collateral}.aseprite
    local path1 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/body/body_" .. viewName .. "_" .. collateral .. ".aseprite"
    if fileExists(path1) then
        return path1
    end
    
    -- Try pattern: body_00_{collateral}.aseprite (for front view)
    if viewIndex == 0 then
        local path2 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/body/body_00_" .. collateral .. ".aseprite"
        if fileExists(path2) then
            return path2
        end
    end
    
    return nil
end

-- Resolve hands file path
function FileResolver.resolveHandsPath(assetsPath, collateral, pose, viewIndex)
    local viewName = viewNames[viewIndex + 1] or "front"
    
    -- Try pattern: hands_{pose}_{collateral}.aseprite
    local path1 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/hands/hands_" .. pose .. "_" .. collateral .. ".aseprite"
    if fileExists(path1) then
        return path1
    end
    
    -- For side views, try hands_{view}_{collateral}.aseprite
    if viewIndex == 1 or viewIndex == 2 then
        local path2 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/hands/hands_" .. viewName .. "_" .. collateral .. ".aseprite"
        if fileExists(path2) then
            return path2
        end
    end
    
    return nil
end

-- Resolve mouth file path
function FileResolver.resolveMouthPath(assetsPath, collateral, expression)
    -- Pattern: mouth_{expression}_00_{collateral}.aseprite
    local path1 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/mouth/mouth_" .. expression .. "_00_" .. collateral .. ".aseprite"
    if fileExists(path1) then
        return path1
    end
    
    -- Try without _00 pattern
    local path2 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/mouth/mouth_" .. expression .. "_" .. collateral .. ".aseprite"
    if fileExists(path2) then
        return path2
    end
    
    return nil
end

-- Resolve shadow file path
function FileResolver.resolveShadowPath(assetsPath, collateral, viewIndex)
    -- Try pattern: shadow_00_{collateral}.aseprite or shadow_01_{collateral}.aseprite
    local path1 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/shadow/shadow_00_" .. collateral .. ".aseprite"
    if fileExists(path1) then
        return path1
    end
    
    local path2 = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/shadow/shadow_01_" .. collateral .. ".aseprite"
    if fileExists(path2) then
        return path2
    end
    
    return nil
end

-- Resolve eyes file path (now uses eyeRange and rarity parameters)
function FileResolver.resolveEyesPath(assetsPath, collateral, eyeRange, rarity, viewIndex)
    return FileResolver.resolveEyeShapePath(assetsPath, collateral, eyeRange, rarity, viewIndex)
end

-- Normalize wearable name to match directory structure (remove spaces)
local function normalizeWearableName(name)
    return name:gsub("%s+", "")
end

-- Resolve wearable file path
-- Handles both naming conventions: flat files and subdirectory structure
function FileResolver.resolveWearablePath(assetsPath, wearableId, wearableName, viewIndex)
    local viewName = viewNames[viewIndex + 1] or "front"
    
    -- Normalize name (remove spaces) to match directory structure
    local normalizedName = normalizeWearableName(wearableName)
    local wearableDir = assetsPath .. "/Aseprites/Wearables/" .. wearableId .. "_" .. normalizedName .. "/"
    
    -- If normalized directory doesn't exist, try original name
    if not app.fs.isDirectory(wearableDir) then
        wearableDir = assetsPath .. "/Aseprites/Wearables/" .. wearableId .. "_" .. wearableName .. "/"
        if not app.fs.isDirectory(wearableDir) then
            return nil
        end
    end
    
    -- Try subdirectory pattern first: {View}/{id}_{normalizedName}_{View}.aseprite
    local viewMap = {
        front = "Front",
        left = "Left", 
        right = "Right",
        back = "Back"
    }
    local viewCap = viewMap[viewName] or viewName:gsub("^%l", string.upper)
    
    -- Try with normalized name first (most common)
    local path1 = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewCap .. ".aseprite"
    if fileExists(path1) then
        return path1
    end
    
    -- Try flat file pattern: {id}_{normalizedName}_{view}.aseprite
    local path2 = wearableDir .. wearableId .. "_" .. normalizedName .. "_" .. viewName .. ".aseprite"
    if fileExists(path2) then
        return path2
    end
    
    -- Try alternative subdirectory pattern: Front/{id}_{normalizedName}_front.aseprite
    local path3 = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewName .. ".aseprite"
    if fileExists(path3) then
        return path3
    end
    
    -- For side views, try SideLeft/SideRight
    if viewIndex == 1 then
        local path4 = wearableDir .. "Left/" .. wearableId .. "_" .. normalizedName .. "_SideLeft.aseprite"
        if fileExists(path4) then
            return path4
        end
    elseif viewIndex == 2 then
        local path5 = wearableDir .. "Right/" .. wearableId .. "_" .. normalizedName .. "_SideRight.aseprite"
        if fileExists(path5) then
            return path5
        end
    end
    
    -- Last resort: try with original name
    local path6 = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. wearableName .. "_" .. viewCap .. ".aseprite"
    if fileExists(path6) then
        return path6
    end
    
    return nil
end

-- Scan for available collaterals in assets directory
function FileResolver.scanForCollaterals(assetsPath)
    local collaterals = {}
    local collateralsDir = assetsPath .. "/Aseprites/Collaterals/"
    
    -- Known collateral names (we'll check which ones exist)
    local knownCollaterals = {
        "amUSDC", "amUSDT", "amWETH", "amWBTC", "amAAVE", "amWMATIC", "amDAI",
        "maUSDC", "maUSDT", "maWETH", "maDAI", "maAAVE", "maUNI", "maLINK", "maTUSD", "maYFI"
    }
    
    for _, collateral in ipairs(knownCollaterals) do
        local bodyPath = collateralsDir .. collateral .. "/body/"
        -- Check if directory exists by trying to resolve a body file
        local bodyFile = FileResolver.resolveBodyPath(assetsPath, collateral, 0) -- Check front view
        if bodyFile then
            table.insert(collaterals, collateral)
        end
    end
    
    return collaterals
end

-- Scan for eye shape ranges for a collateral
-- Returns list of range directory names (e.g., "haunt1_id00_range0-1")
function FileResolver.scanEyeShapeRanges(assetsPath, collateral)
    local ranges = {}
    local eyeShapeDir = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/eye shape/"
    
    -- Known range patterns based on the directory structure
    -- We check if a directory exists by testing for a common file pattern
    local rangePatterns = {}
    
    -- Generate all possible range patterns
    for haunt = 1, 2 do
        for id = 0, 16 do
            local idPadded = string.format("%02d", id)
            local patterns = {
                string.format("haunt%d_id%s_range0-1", haunt, idPadded),
                string.format("haunt%d_id%s_range1-2", haunt, idPadded),
                string.format("haunt%d_id%s_range2-5", haunt, idPadded),
                string.format("haunt%d_id%s_range5-7", haunt, idPadded),
                string.format("haunt%d_id%s_range7-10", haunt, idPadded),
                string.format("haunt%d_id%s_range10-15", haunt, idPadded),
                string.format("haunt%d_id%s_range15-20", haunt, idPadded),
                string.format("haunt%d_id%s_range20-25", haunt, idPadded),
                string.format("haunt%d_id%s_range25-42", haunt, idPadded),
                string.format("haunt%d_id%s_range42-58", haunt, idPadded),
                string.format("haunt%d_id%s_range58-75", haunt, idPadded),
                string.format("haunt%d_id%s_range75-80", haunt, idPadded),
                string.format("haunt%d_id%s_range80-85", haunt, idPadded),
                string.format("haunt%d_id%s_range85-90", haunt, idPadded),
                string.format("haunt%d_id%s_range90-93", haunt, idPadded),
                string.format("haunt%d_id%s_range93-95", haunt, idPadded),
                string.format("haunt%d_id%s_range95-98", haunt, idPadded)
            }
            
            for _, pattern in ipairs(patterns) do
                -- Test if directory exists by checking for a common eye file
                local testFile = eyeShapeDir .. pattern .. "/haunt" .. haunt .. "_id" .. idPadded .. "_front_common.aseprite"
                if app.fs.isFile(testFile) then
                    table.insert(ranges, pattern)
                    break -- Found this ID, move to next ID
                end
            end
        end
    end
    
    return ranges
end

-- Get eye color/rarity options for a specific eye shape range
function FileResolver.getEyeRarityOptions(assetsPath, collateral, eyeRange, viewIndex)
    local viewName = viewNames[viewIndex + 1] or "front"
    local eyeShapeDir = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/eye shape/" .. eyeRange .. "/"
    
    local rarities = {}
    local rarityNames = {
        "common", "uncommon_low", "uncommon_high", "rare_low", "rare_high", 
        "mythical_low", "mythical_high"
    }
    
    -- Extract haunt and id from range name (e.g., "haunt1_id00_range0-1")
    local haunt, id = eyeRange:match("haunt(%d)_id(%d+)_range")
    if not haunt or not id then
        return rarities
    end
    
    local idPadded = string.format("%02d", tonumber(id))
    local fileNamePrefix = "haunt" .. haunt .. "_id" .. idPadded .. "_" .. viewName .. "_"
    
    for _, rarity in ipairs(rarityNames) do
        local filePath = eyeShapeDir .. fileNamePrefix .. rarity .. ".aseprite"
        if app.fs.isFile(filePath) then
            table.insert(rarities, rarity)
        end
    end
    
    return rarities
end

-- Resolve eye shape file path
function FileResolver.resolveEyeShapePath(assetsPath, collateral, eyeRange, rarity, viewIndex)
    local viewName = viewNames[viewIndex + 1] or "front"
    local eyeShapeDir = assetsPath .. "/Aseprites/Collaterals/" .. collateral .. "/eye shape/" .. eyeRange .. "/"
    
    -- Extract haunt and id from range name
    local haunt, id = eyeRange:match("haunt(%d)_id(%d+)_range")
    if not haunt or not id then
        return nil
    end
    
    local idPadded = string.format("%02d", tonumber(id))
    local fileName = "haunt" .. haunt .. "_id" .. idPadded .. "_" .. viewName .. "_" .. rarity .. ".aseprite"
    local filePath = eyeShapeDir .. fileName
    
    if app.fs.isFile(filePath) then
        return filePath
    end
    
    return nil
end

-- Helper to normalize wearable name (duplicate from wearable-scanner for this module)
local function normalizeWearableNameForResolver(name)
    return name:gsub("%s+", "")
end

-- Resolve sleeves file path for a body wearable
-- Sleeves are typically named: {id}_{name}_Front_LeftUp.aseprite or _RightUp.aseprite for up
-- or _LeftDown.aseprite / _RightDown.aseprite for down
function FileResolver.resolveSleevesPath(assetsPath, wearableId, wearableName, viewIndex, handPose)
    local viewNames = {"front", "left", "right", "back"}
    local viewName = viewNames[viewIndex + 1] or "front"
    
    -- Normalize name
    local normalizedName = normalizeWearableNameForResolver(wearableName)
    local wearableDir = assetsPath .. "/Aseprites/Wearables/" .. wearableId .. "_" .. normalizedName .. "/"
    
    if not app.fs.isDirectory(wearableDir) then
        wearableDir = assetsPath .. "/Aseprites/Wearables/" .. wearableId .. "_" .. wearableName .. "/"
        if not app.fs.isDirectory(wearableDir) then
            return nil
        end
        normalizedName = wearableName
    end
    
    local viewMap = {
        front = "Front",
        left = "Left",
        right = "Right",
        back = "Back"
    }
    local viewCap = viewMap[viewName] or "Front"
    
    -- Determine sleeve type based on hand pose
    -- "up" = sleeves up: pattern is {id}_{name}_Front_LeftUp.aseprite / _RightUp.aseprite
    -- "down_open" or "down_closed" = sleeves down: pattern is {id}_{name}_FrontLeft.aseprite / _FrontRight.aseprite (no Up/Down suffix)
    local leftSleevePath, rightSleevePath
    if handPose == "up" then
        -- Up sleeves: {id}_{name}_Front_LeftUp.aseprite
        leftSleevePath = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewCap .. "_LeftUp.aseprite"
        rightSleevePath = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewCap .. "_RightUp.aseprite"
    else
        -- Down sleeves: {id}_{name}_FrontLeft.aseprite (no Up/Down suffix)
        leftSleevePath = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewCap .. "Left.aseprite"
        rightSleevePath = wearableDir .. viewCap .. "/" .. wearableId .. "_" .. normalizedName .. "_" .. viewCap .. "Right.aseprite"
    end
    
    -- Debug logging
    if _G.debugLogMessage then
        _G.debugLogMessage("[DEBUG] Resolving sleeves for wearable " .. wearableId .. " (" .. wearableName .. ")")
        _G.debugLogMessage("[DEBUG]   Hand pose: " .. handPose .. " -> Checking for " .. (handPose == "up" and "Up" or "Down") .. " sleeves")
        _G.debugLogMessage("[DEBUG]   Left sleeve path: " .. leftSleevePath)
        _G.debugLogMessage("[DEBUG]   Right sleeve path: " .. rightSleevePath)
    end
    
    local leftExists = fileExists(leftSleevePath)
    local rightExists = fileExists(rightSleevePath)
    
    if _G.debugLogMessage then
        _G.debugLogMessage("[DEBUG]   Left exists: " .. tostring(leftExists) .. ", Right exists: " .. tostring(rightExists))
    end
    
    if leftExists and rightExists then
        -- Return both as a table
        if _G.debugLogMessage then
            _G.debugLogMessage("[DEBUG]   Returning both sleeve files")
        end
        return {leftSleevePath, rightSleevePath}
    elseif leftExists then
        -- Just left sleeve
        if _G.debugLogMessage then
            _G.debugLogMessage("[DEBUG]   Returning left sleeve only")
        end
        return leftSleevePath
    elseif rightExists then
        -- Just right sleeve
        if _G.debugLogMessage then
            _G.debugLogMessage("[DEBUG]   Returning right sleeve only")
        end
        return rightSleevePath
    end
    
    -- No sleeves found
    if _G.debugLogMessage then
        _G.debugLogMessage("[DEBUG]   No sleeve files found")
    end
    return nil
end

return FileResolver

