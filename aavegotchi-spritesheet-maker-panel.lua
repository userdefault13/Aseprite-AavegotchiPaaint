-- Aavegotchi Sprite Sheet Maker Panel
-- Combined panel for generating gotchis and creating sprite sheets

-- Hardcoded assets path
local hardcodedAssetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"

-- Helper function to resolve script paths (works in both GUI and CLI)
local function resolveScriptPath(scriptName)
    -- Try relative path first (for GUI mode when script is in extension folder)
    local relativePath = scriptName
    if app.fs.isFile(relativePath) then
        return relativePath
    end
    
    -- Try absolute path (for CLI mode or when relative fails)
    local absolutePath = hardcodedAssetsPath .. "/" .. scriptName
    if app.fs.isFile(absolutePath) then
        return absolutePath
    end
    
    -- Return original if neither works (will fail with clear error)
    return scriptName
end

-- Load modules with path resolution
local Composer = dofile(resolveScriptPath("aavegotchi-composer.lua"))
local FileResolver = dofile(resolveScriptPath("file-resolver.lua"))
local JsonLoader = dofile(resolveScriptPath("json-loader.lua"))
local WearableScanner = dofile(resolveScriptPath("wearable-scanner.lua"))
local SpriteSheetGenerator = dofile(resolveScriptPath("aavegotchi-spritesheet-generator.lua"))

-- Global state
local panelDlg = nil
local wearablesDb = nil

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
local refreshCollaterals

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
    
    local rarities = FileResolver.getEyeRarityOptions(assetsPath, collateral, eyeRange, 0)
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
refreshCollaterals = function(dlg, assetsPath)
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
        refreshEyeShapeRanges(dlg, assetsPath, options[1])
    end
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

-- Build wearable options list
local function buildWearableOptions(wearablesDb, slotIndex, assetsPath, viewIndex)
    local options = {""}
    
    if not wearablesDb or not wearablesDb.wearables then
        return options
    end
    
    viewIndex = viewIndex or 0
    
    for _, wearable in ipairs(wearablesDb.wearables) do
        if wearable.slotPositions and wearable.slotPositions[slotIndex + 1] then
            local exists, filePath = WearableScanner.verifyWearableExists(assetsPath, wearable.id, wearable.name, viewIndex)
            if exists then
                table.insert(options, wearable.id .. " - " .. wearable.name)
            end
        end
    end
    
    return options
end

-- Show the panel
local function showPanel()
    panelDlg = Dialog("Aavegotchi Sprite Sheet Maker")
    
    -- Assets path (read-only)
    panelDlg:entry{
        id = "assets_path",
        label = "Assets Directory:",
        text = hardcodedAssetsPath,
        readonly = true
    }
    
    panelDlg:separator{text = "Generate Aavegotchi"}
    
    -- View selector
    panelDlg:combobox{
        id = "view",
        label = "View:",
        option = "front",
        options = {"front", "left", "right", "back"}
    }
    
    -- Collateral selector
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
    
    -- Eye Rarity selector
    panelDlg:combobox{
        id = "eyeRarity",
        label = "Eye Rarity:",
        option = "",
        options = {}
    }
    
    -- Hand pose selector
    panelDlg:combobox{
        id = "handPose",
        label = "Hand Pose:",
        option = "down_open",
        options = {"down_open", "down_closed", "up_open", "up_closed"}
    }
    
    -- Mouth expression selector
    panelDlg:combobox{
        id = "mouthExpression",
        label = "Mouth Expression:",
        option = "neutral",
        options = {"neutral", "happy", "sad", "surprised"}
    }
    
    -- Canvas size
    panelDlg:number{
        id = "canvasSize",
        label = "Canvas Size:",
        text = "64",
        decimals = 0
    }
    
    -- Build Aavegotchi button
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
            
            local viewName = panelDlg.data.view or "front"
            local viewIndex = 0
            if viewName == "left" then viewIndex = 1
            elseif viewName == "right" then viewIndex = 2
            elseif viewName == "back" then viewIndex = 3
            end
            
            -- Collect wearables
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
    
    panelDlg:separator{text = "Create Sprite Sheet"}
    
    -- Sprite sheet collateral selector
    panelDlg:combobox{
        id = "spriteSheetCollateral",
        label = "Collateral:",
        option = "",
        options = {},
        onchange = function()
            -- Sync with main collateral if needed
        end
    }
    
    -- Create Sprite Sheet button
    panelDlg:button{
        id = "createSpriteSheet",
        text = "Create Sprite Sheet",
        onclick = function()
            local assetsPath = panelDlg.data.assets_path
            if not assetsPath or assetsPath == "" then
                app.alert("Please specify an assets directory path")
                return
            end
            
            local collateral = panelDlg.data.spriteSheetCollateral
            if not collateral or collateral == "" then
                app.alert("Please select a collateral for the sprite sheet")
                return
            end
            
            app.alert("Generating body sprite sheet...\n\nThis may take a moment.\nCheck the console for progress.")
            
            -- Construct JSON path: JSONs/Body/collateral-base-{collateral}.json
            local jsonPath = assetsPath .. "/JSONs/Body/collateral-base-" .. collateral:lower() .. ".json"
            
            -- Check if JSON file exists
            if not app.fs.isFile(jsonPath) then
                app.alert("JSON file not found:\n" .. jsonPath)
                return
            end
            
            local sheetSprite, err = SpriteSheetGenerator.generateBodySpriteSheet(collateral, jsonPath, assetsPath)
            
            if not sheetSprite then
                app.alert("Error creating sprite sheet: " .. (err or "Unknown error"))
                return
            end
            
            -- Save the sprite sheet
            local outputPath = assetsPath .. "/Output/aavegotchi-body-sprites-" .. collateral:lower() .. ".aseprite"
            
            ok, saveErr = pcall(function()
                app.activeSprite = sheetSprite
                sheetSprite:saveAs(outputPath)
            end)
            
            if not ok then
                app.alert("Error saving sprite sheet: " .. (saveErr or "Unknown error"))
                return
            end
            
            print("SUCCESS: Sprite sheet created!")
            print("Dimensions: " .. sheetSprite.width .. "x" .. sheetSprite.height)
            print("Frames: " .. #sheetSprite.frames)
            print("Layers: " .. #sheetSprite.layers)
            
            app.alert("Sprite sheet created successfully!\n\nSaved to:\n" .. outputPath)
        end
    }
    
    panelDlg:button{
        id = "close",
        text = "Close"
    }
    
    -- Load wearables database
    local wearablesDbPath = hardcodedAssetsPath .. "/JSONs/aavegotchi_db_wearables.json"
    if app.fs.isFile(wearablesDbPath) then
        wearablesDb, err = JsonLoader.loadWearablesDatabase(wearablesDbPath)
        if err then
            print("Warning: Could not load wearables database: " .. err)
            wearablesDb = nil
        end
    end
    
    -- Auto-refresh collaterals
    if app.fs.isDirectory(hardcodedAssetsPath) then
        refreshCollaterals(panelDlg, hardcodedAssetsPath)
        
        -- Also populate sprite sheet collateral dropdown
        local collaterals = FileResolver.scanForCollaterals(hardcodedAssetsPath)
        table.sort(collaterals)
        if #collaterals > 0 then
            panelDlg:modify{
                id = "spriteSheetCollateral",
                options = collaterals,
                option = collaterals[1]
            }
        end
    end
    
    -- Show as persistent panel
    panelDlg:show{wait=false, autoscrollbars=true}
end

-- Initialize and show panel
showPanel()


