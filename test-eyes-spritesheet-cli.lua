-- Test Eyes Spritesheet Generator via CLI (Batch Process All Rarities)
-- Usage: aseprite -b --script test-eyes-spritesheet-cli.lua

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local collateral = "amaave"
local eyesBasePath = assetsPath .. "/JSONs/Eyes/" .. collateral

print("=== Testing Eyes Spritesheet Generator (Batch) ===")
print("Assets Path: " .. assetsPath)
print("Collateral: " .. collateral)
print("Eyes Base Path: " .. eyesBasePath)
print("")

-- Load modules
local SpriteSheetGenerator = dofile(assetsPath .. "/aavegotchi-spritesheet-generator.lua")

if not SpriteSheetGenerator then
    print("ERROR: Failed to load SpriteSheetGenerator module")
    return
end

print("Module loaded successfully")
print("")

-- Check if eyes base path exists
if not app.fs.isDirectory(eyesBasePath) then
    print("ERROR: Eyes base directory not found: " .. eyesBasePath)
    return
end

-- Define the 7 rarity folders and their subfolders
local rarityFolders = {
    {name = "Collateral", subfolders = {"amAAVECollateral_Range_98-99"}},
    {name = "Common", subfolders = {"Common_1_Range_25-41", "Common_2_Range_42-57", "Common_3_Range_58-74"}},
    {name = "MythicalLow", subfolders = {"Mythical-Low_1_Range_0-0", "Mythical-Low_2_Range_1-1"}},
    {name = "RareHigh", subfolders = {"Rare-High_1_Range_90-92", "Rare-High_2_Range_93-94", "Rare-High_3_Range_95-97"}},
    {name = "RareLow", subfolders = {"Rare-Low_1_Range_2-4", "Rare-Low_2_Range_5-6", "Rare-Low_3_Range_7-9"}},
    {name = "UncommonHigh", subfolders = {"Uncommon-High_1_Range_75-79", "Uncommon-High_2_Range_80-84", "Uncommon-High_3_Range_85-89"}},
    {name = "UncommonLow", subfolders = {"Uncommon-Low_1_Range_10-14", "Uncommon-Low_2_Range_15-19", "Uncommon-Low_3_Range_20-24"}}
}

-- Define the 7 rarities
local rarities = {
    "common",
    "mythicalhigh",
    "mythicallow",
    "rarehigh",
    "rarelow",
    "uncommonhigh",
    "uncommonlow"
}

local totalGenerated = 0
local totalErrors = 0

-- Loop through each rarity folder
for _, rarityFolder in ipairs(rarityFolders) do
    local rarityBasePath = eyesBasePath .. "/" .. rarityFolder.name
    
    if not app.fs.isDirectory(rarityBasePath) then
        print("WARNING: Rarity folder not found: " .. rarityBasePath)
        goto continue_rarity
    end
    
    -- Loop through each subfolder
    for _, subfolder in ipairs(rarityFolder.subfolders) do
        local subfolderPath = rarityBasePath .. "/" .. subfolder
        
        if not app.fs.isDirectory(subfolderPath) then
            print("WARNING: Subfolder not found: " .. subfolderPath)
            goto continue_subfolder
        end
        
        -- Loop through each rarity JSON file
        for _, rarity in ipairs(rarities) do
            -- Find matching JSON file
            local jsonFiles = app.fs.listFiles(subfolderPath)
            local jsonPath = nil
            
            for _, file in ipairs(jsonFiles) do
                if file:match("eyes%-" .. rarity) then
                    jsonPath = subfolderPath .. "/" .. file
                    break
                end
            end
            
            if not jsonPath or not app.fs.isFile(jsonPath) then
                print("WARNING: JSON file not found for rarity " .. rarity .. " in " .. subfolderPath)
                totalErrors = totalErrors + 1
                goto continue_rarity_file
            end
            
            -- Generate spritesheet
            print("=== Processing: " .. rarityFolder.name .. "/" .. subfolder .. "/" .. rarity .. " ===")
            
            local sprite, err
            local ok, result1, result2 = pcall(function()
                return SpriteSheetGenerator.generateEyesSpriteSheet(rarity, jsonPath, assetsPath)
            end)
            
            if not ok then
                print("ERROR (pcall failed): " .. tostring(result1))
                totalErrors = totalErrors + 1
                goto continue_rarity_file
            end
            
            sprite = result1
            err = result2
            
            if not sprite then
                print("ERROR: Function returned nil")
                print("Error message: " .. (err or "No error message provided"))
                totalErrors = totalErrors + 1
                goto continue_rarity_file
            end
            
            -- Create output path
            local outputSubfolder = rarityFolder.name .. "/" .. subfolder
            local outputDir = assetsPath .. "/Output/Eyes/" .. collateral .. "/" .. outputSubfolder
            -- Create directory if it doesn't exist
            app.fs.makeDirectory(outputDir)
            
            local outputPath = outputDir .. "/eyes-" .. rarity .. ".aseprite"
            app.activeSprite = sprite
            sprite:saveAs(outputPath)
            
            print("SUCCESS: Saved to " .. outputPath)
            print("")
            
            totalGenerated = totalGenerated + 1
            
            ::continue_rarity_file::
        end
        
        ::continue_subfolder::
    end
    
    ::continue_rarity::
end

print("")
print("=== Batch Processing Complete ===")
print("Total spritesheets generated: " .. totalGenerated)
print("Total errors: " .. totalErrors)
print("Done!")

