-- Aavegotchi Paint Panel
-- Main extension entry point with persistent panel UI

local Composer = dofile("aavegotchi-composer.lua")
local FileResolver = dofile("file-resolver.lua")
local JsonLoader = dofile("json-loader.lua")
local WearableScanner = dofile("wearable-scanner.lua")

-- Global state for the panel
local panelDlg = nil
local wearablesDb = nil

-- Debug log collector
local debugLog = {}

-- Debug logging function that both logs and prints
local function debugLogMessage(...)
    local args = {...}
    local message = table.concat(args, "\t")
    table.insert(debugLog, message)
    -- Use raw print to avoid recursion
    io.write(message .. "\n")
    io.flush()
end

-- Make debugLogMessage available globally for other modules
_G.debugLogMessage = debugLogMessage

-- Slot names mapping
local slotNames = {
    "body", "face", "eyes", "head", "right_hand", "left_hand",
    "pet", "background", "aura", "hands", "weapon_right", "weapon_left"
}

-- Slot display names
local slotDisplayNames = {
    "Body", "Face", "Eyes", "Head", "Right Hand", "Left Hand",
    "Pet", "Background", "Aura", "Hands", "Weapon Right", "Weapon Left"
}

-- Forward declarations
local refreshEyeRarities
local refreshEyeShapeRanges

-- Refresh eye rarity options dropdown
refreshEyeRarities = function(dlg, assetsPath, collateral, eyeRange)
    if not eyeRange or eyeRange == "" then
        dlg:modify{
            id = "eyeRarity",
            options = {""},
            option = ""
        }
        return
    end
    
    local rarities = FileResolver.getEyeRarityOptions(assetsPath, collateral, eyeRange, 0) -- front view only
    table.sort(rarities)
    
    local options = {}
    for _, rarity in ipairs(rarities) do
        table.insert(options, rarity)
    end
    
    if #options > 0 then
        dlg:modify{
            id = "eyeRarity",
            options = options,
            option = options[1]
        }
    else
        dlg:modify{
            id = "eyeRarity",
            options = {""},
            option = ""
        }
    end
end

-- Refresh eye shape ranges dropdown
refreshEyeShapeRanges = function(dlg, assetsPath, collateral)
    local ranges = FileResolver.scanEyeShapeRanges(assetsPath, collateral)
    table.sort(ranges)
    
    local options = {}
    for _, range in ipairs(ranges) do
        table.insert(options, range)
    end
    
    if #options > 0 then
        dlg:modify{
            id = "eyeShapeRange",
            options = options,
            option = options[1]
        }
        -- Also refresh rarity options for first range
        refreshEyeRarities(dlg, assetsPath, collateral, options[1])
    else
        dlg:modify{
            id = "eyeShapeRange",
            options = {""},
            option = ""
        }
    end
end

-- Refresh collaterals dropdown
local function refreshCollaterals(dlg, assetsPath)
    local collaterals = FileResolver.scanForCollaterals(assetsPath)
    table.sort(collaterals)
    
    local options = {}
    for _, collateral in ipairs(collaterals) do
        table.insert(options, collateral)
    end
    
    if #options > 0 then
        dlg:modify{
            id = "collateral",
            options = options,
            option = options[1]
        }
        -- Also refresh eye shape ranges for first collateral
        refreshEyeShapeRanges(dlg, assetsPath, options[1])
    end
end

-- Build wearable options list, filtering to only show wearables that exist in the directory
local function buildWearableOptions(wearablesDb, slotIndex, assetsPath)
    local options = {""}  -- Empty option means no wearable
    
    if not wearablesDb or not wearablesDb.wearables then
        debugLogMessage("[DEBUG] buildWearableOptions: No wearables database or wearables array")
        return options
    end
    
    debugLogMessage("[DEBUG] buildWearableOptions: Processing slot " .. slotIndex .. ", total wearables in DB: " .. #wearablesDb.wearables)
    
    -- Get view index (default to front/0)
    local viewIndex = 0
    local checkedCount = 0
    local matchedCount = 0
    local existsCount = 0
    
    for _, wearable in ipairs(wearablesDb.wearables) do
        if wearable.slotPositions and wearable.slotPositions[slotIndex + 1] then
            checkedCount = checkedCount + 1
            matchedCount = matchedCount + 1
            
            -- Verify the wearable actually exists in the directory
            local exists, filePath = WearableScanner.verifyWearableExists(assetsPath, wearable.id, wearable.name, viewIndex)
            if exists then
                existsCount = existsCount + 1
                table.insert(options, wearable.id .. " - " .. wearable.name)
                if existsCount <= 3 then  -- Log first 3 for debugging
                    debugLogMessage("[DEBUG] Found wearable: " .. wearable.id .. " - " .. wearable.name .. " at " .. (filePath or "unknown"))
                end
            else
                if matchedCount <= 3 then  -- Log first 3 missing for debugging
                    debugLogMessage("[DEBUG] Wearable " .. wearable.id .. " - " .. wearable.name .. " matches slot but file not found")
                end
            end
        end
    end
    
    debugLogMessage("[DEBUG] Slot " .. slotIndex .. " results: " .. checkedCount .. " checked, " .. matchedCount .. " matched slot, " .. existsCount .. " exist, " .. #options - 1 .. " in dropdown")
    
    return options
end

-- Get wearable ID from option string
local function getWearableIdFromOption(option)
    if not option or option == "" then
        return nil
    end
    local id = option:match("^(%d+)")
    return id and tonumber(id) or nil
end

-- Get wearable name by ID
local function getWearableNameById(wearablesDb, id)
    if not wearablesDb or not wearablesDb.wearables then
        return "Wearable" .. id
    end
    
    for _, wearable in ipairs(wearablesDb.wearables) do
        if wearable.id == id then
            return wearable.name
        end
    end
    
    return "Wearable" .. id
end

-- Show the panel
local function showPanel()
    -- Create dialog
    panelDlg = Dialog("Aavegotchi Paint")
    
    -- Hardcoded assets path
    local hardcodedAssetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
    
    panelDlg:entry{
        id = "assets_path",
        label = "Assets Directory:",
        text = hardcodedAssetsPath,
        readonly = true,  -- Make it read-only since it's hardcoded
        onchange = function()
            local assetsPath = panelDlg.data.assets_path
            if assetsPath and assetsPath ~= "" and app.fs.isDirectory(assetsPath) then
                refreshCollaterals(panelDlg, assetsPath)
                -- Also refresh eye shape ranges when collateral changes
                local collateral = panelDlg.data.collateral
                if collateral and collateral ~= "" then
                    refreshEyeShapeRanges(panelDlg, assetsPath, collateral)
                end
            end
        end
    }
    
    -- View selector (default to front for now)
    panelDlg:combobox{
        id = "view",
        label = "View:",
        option = "front",
        options = {"front"}
    }
    
    -- Collateral selector (will be populated when assets path is set)
    panelDlg:combobox{
        id = "collateral",
        label = "Collateral:",
        option = "",
        options = {},
        onchange = function()
            local assetsPath = panelDlg.data.assets_path
            local collateral = panelDlg.data.collateral
            if assetsPath and assetsPath ~= "" and collateral and collateral ~= "" then
                refreshEyeShapeRanges(panelDlg, assetsPath, collateral)
            end
        end
    }
    
    -- Eye Shape Range selector
    panelDlg:combobox{
        id = "eyeShapeRange",
        label = "Eye Shape Range:",
        option = "",
        options = {},
        onchange = function()
            local assetsPath = panelDlg.data.assets_path
            local collateral = panelDlg.data.collateral
            local eyeRange = panelDlg.data.eyeShapeRange
            if assetsPath and assetsPath ~= "" and collateral and collateral ~= "" and eyeRange and eyeRange ~= "" then
                refreshEyeRarities(panelDlg, assetsPath, collateral, eyeRange)
            end
        end
    }
    
    -- Eye Rarity/Color selector
    panelDlg:combobox{
        id = "eyeRarity",
        label = "Eye Color (Rarity):",
        option = "",
        options = {}
    }
    
    -- Hand pose
    panelDlg:combobox{
        id = "handPose",
        label = "Hand Pose:",
        option = "down_open",
        options = {"down_open", "down_closed", "up"}
    }
    
    -- Mouth expression
    panelDlg:combobox{
        id = "mouthExpression",
        label = "Mouth Expression:",
        option = "neutral",
        options = {"neutral", "happy"}
    }
    
    -- Canvas size
    panelDlg:number{
        id = "canvasSize",
        label = "Canvas Size:",
        text = "64",
        decimals = 0
    }
    
    -- Load wearables database - try multiple paths
    local wearablesPath = "aavegotchi_db_wearables.json"
    if not app.fs.isFile(wearablesPath) then
        wearablesPath = app.fs.joinPath(app.fs.userConfigPath, "extensions", "aavegotchi-paint", "aavegotchi_db_wearables.json")
    end
    if not app.fs.isFile(wearablesPath) then
        -- Try extension directory
        local scriptPath = app.fs.filePath(app.script.path)
        if scriptPath then
            wearablesPath = app.fs.joinPath(scriptPath, "aavegotchi_db_wearables.json")
        end
    end
    
    debugLogMessage("[DEBUG] Loading wearables database from: " .. wearablesPath)
    wearablesDb, err = JsonLoader.loadWearablesDatabase(wearablesPath)
    if not wearablesDb then
        local errorMsg = err or "Unknown error"
        debugLogMessage("[DEBUG] ERROR loading wearables database: " .. errorMsg)
        app.alert("Warning: Could not load wearables database: " .. errorMsg .. "\nWearables will not be available.")
    else
        local wearableCount = wearablesDb.wearables and #wearablesDb.wearables or 0
        debugLogMessage("[DEBUG] Successfully loaded " .. wearableCount .. " wearables from database")
        
        -- Debug: Show first few wearables
        if wearablesDb.wearables and #wearablesDb.wearables > 0 then
            debugLogMessage("[DEBUG] First wearable: ID=" .. wearablesDb.wearables[1].id .. ", Name=" .. (wearablesDb.wearables[1].name or "nil"))
            if wearablesDb.wearables[1].slotPositions then
                debugLogMessage("[DEBUG] First wearable slotPositions length: " .. #wearablesDb.wearables[1].slotPositions)
            end
        end
    end
    
    -- Separator for wearables section
    panelDlg:separator{text = "Wearables (Optional)"}
    
    -- Get assets path for filtering wearables
    local assetsPath = hardcodedAssetsPath
    
    -- Group wearables into sections for better organization
    -- Core wearables
    panelDlg:separator{text = "Core"}
    local coreSlots = {1, 2, 3, 4}  -- body, face, eyes, head
    for _, i in ipairs(coreSlots) do
        local slotName = slotNames[i]
        local options = buildWearableOptions(wearablesDb, i - 1, assetsPath)
        panelDlg:combobox{
            id = "wearable_" .. slotName,
            label = slotDisplayNames[i] .. ":",
            option = "",
            options = options
        }
    end
    
    -- Hands and weapons
    panelDlg:separator{text = "Hands & Weapons"}
    local handsSlots = {5, 6, 10, 11, 12}  -- right_hand, left_hand, hands, weapon_right, weapon_left
    for _, i in ipairs(handsSlots) do
        local slotName = slotNames[i]
        local options = buildWearableOptions(wearablesDb, i - 1, assetsPath)
        panelDlg:combobox{
            id = "wearable_" .. slotName,
            label = slotDisplayNames[i] .. ":",
            option = "",
            options = options
        }
    end
    
    -- Accessories
    panelDlg:separator{text = "Accessories"}
    local accessorySlots = {7, 8, 9}  -- pet, background, aura
    for _, i in ipairs(accessorySlots) do
        local slotName = slotNames[i]
        local options = buildWearableOptions(wearablesDb, i - 1, assetsPath)
        panelDlg:combobox{
            id = "wearable_" .. slotName,
            label = slotDisplayNames[i] .. ":",
            option = "",
            options = options
        }
    end
    
    -- Export debug log button
    panelDlg:button{
        id = "exportLog",
        text = "Export Debug Log",
        onclick = function()
            -- Create log content
            local logContent = table.concat(debugLog, "\n")
            
            -- Save to Debug folder in project directory
            local debugFolder = hardcodedAssetsPath .. "/Debug"
            
            -- Create Debug folder if it doesn't exist
            if not app.fs.isDirectory(debugFolder) then
                -- Try to create it (Aseprite Lua might not support mkdir, so we'll try anyway)
                -- If it fails, we'll still try to write the file
            end
            
            -- Generate filename with timestamp
            local timestamp = os.date("%Y%m%d_%H%M%S")
            local logPath = debugFolder .. "/aavegotchi-paint-debug-" .. timestamp .. ".log"
            
            local file = io.open(logPath, "w")
            if file then
                file:write("Aavegotchi Paint Debug Log\n")
                file:write("Generated: " .. os.date() .. "\n")
                file:write("=" .. string.rep("=", 60) .. "\n\n")
                file:write(logContent)
                file:close()
                app.alert("Debug log exported to:\n" .. logPath)
            else
                -- Try alternative path if Debug folder doesn't exist
                local altLogPath = hardcodedAssetsPath .. "/aavegotchi-paint-debug-" .. timestamp .. ".log"
                local altFile = io.open(altLogPath, "w")
                if altFile then
                    altFile:write("Aavegotchi Paint Debug Log\n")
                    altFile:write("Generated: " .. os.date() .. "\n")
                    altFile:write("=" .. string.rep("=", 60) .. "\n\n")
                    altFile:write(logContent)
                    altFile:close()
                    app.alert("Debug log exported to:\n" .. altLogPath .. "\n(Note: Debug folder not found, saved to project root)")
                else
                    app.alert("Error: Could not write debug log to file\nTried:\n" .. logPath .. "\n" .. altLogPath)
                end
            end
        end
    }
    
    -- Build button
    panelDlg:button{
        id = "build",
        text = "Build Aavegotchi",
        onclick = function()
            local assetsPath = panelDlg.data.assets_path
            if not assetsPath or assetsPath == "" then
                app.alert("Please specify an assets directory path")
                return
            end
            
            if not app.fs.isDirectory(assetsPath) then
                app.alert("Assets directory does not exist: " .. assetsPath)
                return
            end
            
            local collateral = panelDlg.data.collateral
            if not collateral or collateral == "" then
                app.alert("Please select a collateral")
                return
            end
            
            -- Convert view name to index
            local viewName = panelDlg.data.view or "front"
            local viewIndex = 0
            if viewName == "left" then viewIndex = 1
            elseif viewName == "right" then viewIndex = 2
            elseif viewName == "back" then viewIndex = 3
            end
            
            -- Collect wearables with names
            local selectedWearables = {}
            for i, slotName in ipairs(slotNames) do
                local option = panelDlg.data["wearable_" .. slotName]
                local wearableId = getWearableIdFromOption(option)
                if wearableId then
                    local wearableName = getWearableNameById(wearablesDb, wearableId)
                    selectedWearables[slotName] = {
                        id = wearableId,
                        name = wearableName
                    }
                end
            end
            
            -- Get eye shape selection
            local eyeRange = panelDlg.data.eyeShapeRange
            local eyeRarity = panelDlg.data.eyeRarity
            if not eyeRange or eyeRange == "" then
                app.alert("Please select an eye shape range")
                return
            end
            if not eyeRarity or eyeRarity == "" then
                app.alert("Please select an eye color/rarity")
                return
            end
            
            -- Build configuration
            local config = {
                collateral = collateral,
                view = viewIndex,
                handPose = panelDlg.data.handPose or "down_open",
                eyeRange = eyeRange,
                eyeRarity = eyeRarity,
                mouthExpression = panelDlg.data.mouthExpression or "neutral",
                wearables = selectedWearables,
                canvasSize = tonumber(panelDlg.data.canvasSize) or 64
            }
            
            -- Compose the Aavegotchi
            local result = Composer.composeAavegotchi(config, assetsPath, selectedWearables)
            
            if result.success then
                app.alert("Aavegotchi built successfully!")
            else
                local errorMsg = "Build completed with errors:\n"
                for _, err in ipairs(result.errors) do
                    errorMsg = errorMsg .. "- " .. err .. "\n"
                end
                app.alert(errorMsg)
            end
        end
    }
    
    panelDlg:button{
        id = "close",
        text = "Close"
    }
    
    -- Auto-refresh collaterals with hardcoded path
    if app.fs.isDirectory(hardcodedAssetsPath) then
        refreshCollaterals(panelDlg, hardcodedAssetsPath)
    end
    
    -- Show as persistent panel with auto scrollbars enabled
    panelDlg:show{wait=false, autoscrollbars=true}
end

-- Initialize and show panel
showPanel()

