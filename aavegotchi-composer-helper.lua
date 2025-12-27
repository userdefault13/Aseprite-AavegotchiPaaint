-- Aavegotchi Composer Helper Functions
-- Provides trait mapping and path resolution utilities

local ComposerHelper = {}

-- Map eye shape trait value (0-99) to folder path
function ComposerHelper.getEyeShapeFolder(eyeShapeValue)
    if eyeShapeValue == 0 then
        return "MythicalLow/Mythical-Low_1_Range_0-0"
    elseif eyeShapeValue == 1 then
        return "MythicalLow/Mythical-Low_2_Range_1-1"
    elseif eyeShapeValue >= 2 and eyeShapeValue <= 4 then
        return "RareLow/Rare-Low_1_Range_2-4"
    elseif eyeShapeValue >= 5 and eyeShapeValue <= 6 then
        return "RareLow/Rare-Low_2_Range_5-6"
    elseif eyeShapeValue >= 7 and eyeShapeValue <= 9 then
        return "RareLow/Rare-Low_3_Range_7-9"
    elseif eyeShapeValue >= 10 and eyeShapeValue <= 14 then
        return "UncommonLow/Uncommon-Low_1_Range_10-14"
    elseif eyeShapeValue >= 15 and eyeShapeValue <= 19 then
        return "UncommonLow/Uncommon-Low_2_Range_15-19"
    elseif eyeShapeValue >= 20 and eyeShapeValue <= 24 then
        return "UncommonLow/Uncommon-Low_3_Range_20-24"
    elseif eyeShapeValue >= 25 and eyeShapeValue <= 41 then
        return "Common/Common_1_Range_25-41"
    elseif eyeShapeValue >= 42 and eyeShapeValue <= 57 then
        return "Common/Common_2_Range_42-57"
    elseif eyeShapeValue >= 58 and eyeShapeValue <= 74 then
        return "Common/Common_3_Range_58-74"
    elseif eyeShapeValue >= 75 and eyeShapeValue <= 79 then
        return "UncommonHigh/Uncommon-High_1_Range_75-79"
    elseif eyeShapeValue >= 80 and eyeShapeValue <= 84 then
        return "UncommonHigh/Uncommon-High_2_Range_80-84"
    elseif eyeShapeValue >= 85 and eyeShapeValue <= 89 then
        return "UncommonHigh/Uncommon-High_3_Range_85-89"
    elseif eyeShapeValue >= 90 and eyeShapeValue <= 92 then
        return "RareHigh/Rare-High_1_Range_90-92"
    elseif eyeShapeValue >= 93 and eyeShapeValue <= 94 then
        return "RareHigh/Rare-High_2_Range_93-94"
    elseif eyeShapeValue >= 95 and eyeShapeValue <= 97 then
        return "RareHigh/Rare-High_3_Range_95-97"
    elseif eyeShapeValue >= 98 and eyeShapeValue <= 99 then
        return "Collateral"  -- Will be combined with collateral name later
    end
    return nil
end

-- Map eye color trait value (0-99) to rarity string
-- Based on aavegotchi_db_rarity.json
function ComposerHelper.getEyeColorRarity(eyeColorValue)
    if eyeColorValue >= 0 and eyeColorValue <= 1 then
        return "mythicallow"  -- Mythical Low
    elseif eyeColorValue >= 2 and eyeColorValue <= 9 then
        return "rarelow"  -- Rare Low
    elseif eyeColorValue >= 10 and eyeColorValue <= 24 then
        return "uncommonlow"  -- Uncommon Low
    elseif eyeColorValue >= 25 and eyeColorValue <= 74 then
        return "common"  -- Common
    elseif eyeColorValue >= 75 and eyeColorValue <= 90 then
        return "uncommonhigh"  -- Uncommon High
    elseif eyeColorValue >= 91 and eyeColorValue <= 97 then
        return "rarehigh"  -- Rare High
    elseif eyeColorValue >= 98 and eyeColorValue <= 99 then
        return "mythicalhigh"  -- Mythical High
    end
    return "common"  -- Default fallback
end

-- Resolve Aseprite spritesheet paths
function ComposerHelper.resolveAsepritePaths(assetsPath, collateral, eyeShapeValue, eyeColorRarity)
    local collateralLower = collateral:lower()
    local eyeShapeFolder = ComposerHelper.getEyeShapeFolder(eyeShapeValue)
    
    -- Handle collateral eye shape folder
    if eyeShapeFolder == "Collateral" then
        -- Find the collateral folder (e.g., amAAVECollateral_Range_98-99)
        local eyesBasePath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/Collateral"
        if app.fs.isDirectory(eyesBasePath) then
            local files = app.fs.listFiles(eyesBasePath)
            if files and #files > 0 then
                -- Find first directory (subfolder)
                for _, file in ipairs(files) do
                    local fullPath = eyesBasePath .. "/" .. file
                    if app.fs.isDirectory(fullPath) then
                        eyeShapeFolder = "Collateral/" .. file
                        break
                    end
                end
                if eyeShapeFolder == "Collateral" then
                    eyeShapeFolder = "Collateral/" .. collateral:upper() .. "Collateral_Range_98-99"
                end
            else
                eyeShapeFolder = "Collateral/" .. collateral:upper() .. "Collateral_Range_98-99"
            end
        else
            eyeShapeFolder = "Collateral/" .. collateral:upper() .. "Collateral_Range_98-99"
        end
    end
    
    local paths = {
        body = assetsPath .. "/Output/test-body-spritesheet-" .. collateralLower .. ".aseprite",
        hands = assetsPath .. "/Output/test-hands-spritesheet-" .. collateralLower .. ".aseprite",
        mouth = assetsPath .. "/Output/test-mouth-spritesheet-" .. collateralLower .. ".aseprite",
        collateral = assetsPath .. "/Output/test-collateral-spritesheet-" .. collateralLower .. ".aseprite",
        eyes = assetsPath .. "/Output/Eyes/" .. collateralLower .. "/" .. eyeShapeFolder .. "/eyes-" .. eyeColorRarity .. ".aseprite"
    }
    
    return paths
end

-- Resolve JSON source paths
function ComposerHelper.resolveJsonPaths(assetsPath, collateral, eyeShapeValue, eyeColorRarity)
    local collateralLower = collateral:lower()
    local eyeShapeFolder = ComposerHelper.getEyeShapeFolder(eyeShapeValue)
    
    -- Handle collateral eye shape folder
    local eyesJsonFolder = eyeShapeFolder
    if eyeShapeFolder == "Collateral" then
        -- Find the collateral folder
        local eyesBasePath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/Collateral"
        if app.fs.isDirectory(eyesBasePath) then
            local files = app.fs.listFiles(eyesBasePath)
            if files and #files > 0 then
                -- Find first directory (subfolder)
                for _, file in ipairs(files) do
                    local fullPath = eyesBasePath .. "/" .. file
                    if app.fs.isDirectory(fullPath) then
                        eyesJsonFolder = "Collateral/" .. file
                        break
                    end
                end
                if eyesJsonFolder == "Collateral" then
                    eyesJsonFolder = "Collateral/" .. collateral:upper() .. "Collateral_Range_98-99"
                end
            else
                eyesJsonFolder = "Collateral/" .. collateral:upper() .. "Collateral_Range_98-99"
            end
        else
            eyesJsonFolder = "Collateral/" .. collateral:upper() .. "Collateral_Range_98-99"
        end
    end
    
    -- Find eyes JSON file (it has a timestamp in the filename)
    local eyesJsonPath = nil
    local eyesFolderPath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/" .. eyesJsonFolder
    if app.fs.isDirectory(eyesFolderPath) then
        local files = app.fs.listFiles(eyesFolderPath)
        for _, file in ipairs(files) do
            if file:match("eyes%-" .. eyeColorRarity) then
                eyesJsonPath = eyesFolderPath .. "/" .. file
                break
            end
        end
    end
    
    -- Find collateral JSON file (has timestamp)
    local collateralJsonPath = nil
    local collateralBasePath = assetsPath .. "/JSONs/Collaterals"
    if app.fs.isDirectory(collateralBasePath) then
        local files = app.fs.listFiles(collateralBasePath)
        for _, file in ipairs(files) do
            if file:match("collateral%-" .. collateralLower) then
                collateralJsonPath = collateralBasePath .. "/" .. file
                break
            end
        end
    end
    
    local paths = {
        body = assetsPath .. "/JSONs/Body/collateral-base-" .. collateralLower .. ".json",
        hands = assetsPath .. "/JSONs/Body/collateral-base-" .. collateralLower .. ".json",  -- Same file
        mouth = assetsPath .. "/JSONs/Body/collateral-base-" .. collateralLower .. ".json",  -- Same file
        collateral = collateralJsonPath,
        eyes = eyesJsonPath
    }
    
    return paths
end

return ComposerHelper

