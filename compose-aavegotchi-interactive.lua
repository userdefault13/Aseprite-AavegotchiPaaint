-- Aavegotchi Paaint - Interactive Composer CLI
-- Author: UnDead Pixel
-- Usage: aseprite -b --script compose-aavegotchi-interactive.lua

local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"

-- Display header
print("")
print("╔═══════════════════════════════════════════════════════════╗")
print("║                                                           ║")
print("║              Aavegotchi Paaint                            ║")
print("║                                                           ║")
print("║              by UnDead Pixel                              ║")
print("║                                                           ║")
print("╚═══════════════════════════════════════════════════════════╝")
print("")
print("Description:")
print("  Composes complete Aavegotchi sprites or generates individual")
print("  spritesheets for body, hands, eyes, mouth, and collateral parts.")
print("  Generates sprites based on collateral choice and trait values.")
print("")

-- Load helper modules
local ComposerHelper = dofile(assetsPath .. "/aavegotchi-composer-helper.lua")
local SpriteSheetGenerator = dofile(assetsPath .. "/aavegotchi-spritesheet-generator.lua")
local ComposerCLI = dofile(assetsPath .. "/aavegotchi-composer-cli.lua")

if not ComposerHelper or not SpriteSheetGenerator or not ComposerCLI then
    print("ERROR: Failed to load required modules")
    return
end

-- Define all 16 collaterals
local collaterals = {
    {name = "amAAVE", displayName = "amAAVE"},
    {name = "amDAI", displayName = "amDAI"},
    {name = "amUSDC", displayName = "amUSDC"},
    {name = "amUSDT", displayName = "amUSDT"},
    {name = "amWBTC", displayName = "amWBTC"},
    {name = "amWETH", displayName = "amWETH"},
    {name = "amWMATIC", displayName = "amWMATIC"},
    {name = "maAAVE", displayName = "maAAVE"},
    {name = "maDAI", displayName = "maDAI"},
    {name = "maLINK", displayName = "maLINK"},
    {name = "maTUSD", displayName = "maTUSD"},
    {name = "maUNI", displayName = "maUNI"},
    {name = "maUSDC", displayName = "maUSDC"},
    {name = "maUSDT", displayName = "maUSDT"},
    {name = "maWETH", displayName = "maWETH"},
    {name = "maYFI", displayName = "maYFI"}
}

-- Display collaterals
print("Available Collaterals:")
for i, collateral in ipairs(collaterals) do
    print(string.format("  %2d. %s", i, collateral.displayName))
end
print("")

-- Configuration: Edit these values directly to use your own values
-- Set to nil to use interactive prompts (may not work in all Aseprite CLI environments)
-- 
-- QUICK START: Edit the values below to use your own selections:
local collateralChoice = nil  -- Set to 1-16 (1=amAAVE, 2=amDAI, ..., 16=maYFI), or leave nil to prompt
local eyeShapeValue = nil     -- Set to 0-99, or leave nil to prompt
local eyeColorValue = nil     -- Set to 0-99, or leave nil to prompt
local modeChoice = nil        -- Set to 1 (Aseprite Library) or 2 (JSON Source), or leave nil to prompt

-- Try to get values from environment variables (alternative method)
if not collateralChoice then
    local envCollateral = os.getenv("AVEGOTCHI_COLLATERAL")
    if envCollateral then collateralChoice = tonumber(envCollateral) end
end
if not eyeShapeValue then
    local envEyeShape = os.getenv("AVEGOTCHI_EYE_SHAPE")
    if envEyeShape then eyeShapeValue = tonumber(envEyeShape) end
end
if not eyeColorValue then
    local envEyeColor = os.getenv("AVEGOTCHI_EYE_COLOR")
    if envEyeColor then eyeColorValue = tonumber(envEyeColor) end
end
if not modeChoice then
    local envMode = os.getenv("AVEGOTCHI_MODE")
    if envMode then modeChoice = tonumber(envMode) end
end

-- Interactive prompts if values not set
if not collateralChoice then
    print("NOTE: To use non-interactive mode, edit the script and set values at the top,")
    print("      or use environment variables: AVEGOTCHI_COLLATERAL, AVEGOTCHI_EYE_SHAPE, etc.")
    print("")
    
    io.write("Select a collateral (1-16): ")
    io.flush()
    local input = io.read()
    collateralChoice = input and tonumber(input) or nil
end

if not collateralChoice or collateralChoice < 1 or collateralChoice > 16 then
    print("ERROR: Invalid collateral selection (must be 1-16)")
    print("Please edit the script and set collateralChoice, eyeShapeValue, eyeColorValue, and modeChoice")
    return
end

if not eyeShapeValue then
    io.write("Enter Eye Shape trait value (0-99): ")
    io.flush()
    local input = io.read()
    eyeShapeValue = input and tonumber(input) or nil
end

if not eyeShapeValue or eyeShapeValue < 0 or eyeShapeValue > 99 then
    print("ERROR: Eye shape value must be between 0 and 99")
    return
end

if not eyeColorValue then
    io.write("Enter Eye Color trait value (0-99): ")
    io.flush()
    local input = io.read()
    eyeColorValue = input and tonumber(input) or nil
end

if not eyeColorValue or eyeColorValue < 0 or eyeColorValue > 99 then
    print("ERROR: Eye color value must be between 0 and 99")
    return
end

if not modeChoice then
    print("Select operation:")
    print("  1. Compose Full Aavegotchi (combine all parts into final sprite)")
    print("  2. Generate Individual Spritesheets (create body, hands, collateral, mouth, or eyes)")
    print("")
    io.write("Select operation (1 or 2): ")
    io.flush()
    local input = io.read()
    modeChoice = input and tonumber(input) or nil
end

if not modeChoice or (modeChoice ~= 1 and modeChoice ~= 2) then
    print("ERROR: Operation must be 1 or 2")
    return
end

-- Get selected collateral first (needed for both modes)
local selectedCollateral = collaterals[collateralChoice]
local collateralName = selectedCollateral.name
local collateralDisplay = selectedCollateral.displayName

-- If generating individual spritesheets, handle that separately
if modeChoice == 2 then
    print("")
    print("Generate Individual Spritesheet:")
    print("  1. Body (depends on collateral)")
    print("  2. Hands (depends on collateral)")
    print("  3. Collateral (depends on collateral)")
    print("  4. Mouth (depends on collateral)")
    print("  5. Eyes (depends on eye shape and eye color)")
    print("  6. Compose All (generate all parts and compose final sprite)")
    print("")
    io.write("Select part to generate (1-6): ")
    io.flush()
    local input = io.read()
    local partChoice = input and tonumber(input) or nil
    
    if not partChoice or partChoice < 1 or partChoice > 6 then
        print("ERROR: Part selection must be 1-6")
        return
    end
    
    -- Load modules
    local SpriteSheetGenerator = dofile(assetsPath .. "/aavegotchi-spritesheet-generator.lua")
    if not SpriteSheetGenerator then
        print("ERROR: Failed to load SpriteSheetGenerator module")
        return
    end
    
    local collateralLower = collateralName:lower()
    
    -- Handle Compose All option (partChoice == 6)
    if partChoice == 6 then
        print("")
        print("Selected Collateral: " .. collateralDisplay)
        print("Eye Shape Trait Value: " .. eyeShapeValue)
        print("Eye Color Trait Value: " .. eyeColorValue)
        print("")
        print("=== Generating All Spritesheets ===")
        print("")
        
        -- Generate all parts and then compose
        -- Initialize all variables before any control flow
        local bodySprite, handsSprite, mouthSprite, eyesSprite, collateralSprite = nil, nil, nil, nil, nil
        local spritesToClose = {}
        local err = nil
        local bodyJsonPath = assetsPath .. "/JSONs/Body/collateral-base-" .. collateralLower .. ".json"
        local collateralBasePath = assetsPath .. "/JSONs/Collaterals"
        local collateralJsonPath = nil
        local eyeShapeFolder = ComposerHelper.getEyeShapeFolder(eyeShapeValue)
        local eyeColorRarity = ComposerHelper.getEyeColorRarity(eyeColorValue)
        local eyesJsonFolder = nil
        local eyesFolderPath = nil
        local eyesJsonPath = nil
        local outputFilename = "aavegotchi-" .. collateralLower .. "-eyeShape" .. eyeShapeValue .. "-eyeColor" .. eyeColorValue .. ".aseprite"
        local outputPath = assetsPath .. "/Output/" .. outputFilename
        local composedSprite = nil
        
        -- Determine eye shape folder and eye color rarity
        if not eyeShapeFolder then
            print("ERROR: Could not determine eye shape folder for value: " .. eyeShapeValue)
            return
        end
        
        -- Generate Body
        print("1. Generating body spritesheet...")
        bodySprite, err = SpriteSheetGenerator.generateBodySpriteSheet(collateralName, bodyJsonPath, assetsPath)
        if not bodySprite then
            print("ERROR: Failed to generate body: " .. (err or "Unknown error"))
            return
        end
        table.insert(spritesToClose, bodySprite)
        print("   ✓ Body generated")
        
        -- Generate Hands
        print("2. Generating hands spritesheet...")
        handsSprite, err = SpriteSheetGenerator.generateHandsSpriteSheet(collateralName, bodyJsonPath, assetsPath)
        if not handsSprite then
            print("ERROR: Failed to generate hands: " .. (err or "Unknown error"))
            -- Cleanup and return
            for _, sprite in ipairs(spritesToClose) do
                pcall(function()
                    app.activeSprite = sprite
                    app.command.CloseFile()
                end)
            end
            return
        end
        table.insert(spritesToClose, handsSprite)
        print("   ✓ Hands generated")
        
        -- Generate Collateral
        print("3. Generating collateral spritesheet...")
        if app.fs.isDirectory(collateralBasePath) then
            local files = app.fs.listFiles(collateralBasePath)
            for _, file in ipairs(files) do
                if file:match("collateral%-" .. collateralLower) then
                    collateralJsonPath = collateralBasePath .. "/" .. file
                    break
                end
            end
        end
        if collateralJsonPath and app.fs.isFile(collateralJsonPath) then
            collateralSprite, err = SpriteSheetGenerator.generateCollateralSpriteSheet(collateralName, collateralJsonPath, assetsPath)
            if collateralSprite then
                table.insert(spritesToClose, collateralSprite)
                print("   ✓ Collateral generated")
            else
                print("   ⚠ Collateral generation failed (optional): " .. (err or "Unknown error"))
            end
        else
            print("   ⚠ Collateral JSON not found (optional)")
        end
        
        -- Generate Mouth
        print("4. Generating mouth spritesheet...")
        mouthSprite, err = SpriteSheetGenerator.generateMouthSpriteSheet(collateralName, bodyJsonPath, assetsPath)
        if mouthSprite then
            table.insert(spritesToClose, mouthSprite)
            print("   ✓ Mouth generated")
        else
            print("   ⚠ Mouth generation failed (optional): " .. (err or "Unknown error"))
        end
        
        -- Generate Eyes
        print("5. Generating eyes spritesheet...")
        eyesJsonFolder = eyeShapeFolder
        if eyeShapeFolder == "Collateral" then
            local eyesBasePath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/Collateral"
            if app.fs.isDirectory(eyesBasePath) then
                local files = app.fs.listFiles(eyesBasePath)
                for _, file in ipairs(files) do
                    local fullPath = eyesBasePath .. "/" .. file
                    if app.fs.isDirectory(fullPath) then
                        eyesJsonFolder = "Collateral/" .. file
                        break
                    end
                end
                if eyesJsonFolder == "Collateral" then
                    eyesJsonFolder = "Collateral/" .. collateralName:upper() .. "Collateral_Range_98-99"
                end
            else
                eyesJsonFolder = "Collateral/" .. collateralName:upper() .. "Collateral_Range_98-99"
            end
        end
        
        eyesFolderPath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/" .. eyesJsonFolder
        if app.fs.isDirectory(eyesFolderPath) then
            local files = app.fs.listFiles(eyesFolderPath)
            for _, file in ipairs(files) do
                if file:match("eyes%-" .. eyeColorRarity) then
                    eyesJsonPath = eyesFolderPath .. "/" .. file
                    break
                end
            end
        end
        
        if eyesJsonPath and app.fs.isFile(eyesJsonPath) then
            eyesSprite, err = SpriteSheetGenerator.generateEyesSpriteSheet(eyeColorRarity, eyesJsonPath, assetsPath)
            if eyesSprite then
                table.insert(spritesToClose, eyesSprite)
                print("   ✓ Eyes generated")
            else
                print("   ⚠ Eyes generation failed (optional): " .. (err or "Unknown error"))
            end
        else
            print("   ⚠ Eyes JSON not found (optional)")
        end
        
        print("")
        print("=== Composing Final Sprite ===")
        print("")
        
        -- Load composer module
        local ComposerCLI = dofile(assetsPath .. "/aavegotchi-composer-cli.lua")
        if not ComposerCLI then
            print("ERROR: Failed to load ComposerCLI module")
            -- Cleanup and return
            for _, sprite in ipairs(spritesToClose) do
                pcall(function()
                    app.activeSprite = sprite
                    app.command.CloseFile()
                end)
            end
            return
        end
        
        -- Compose all sprites
        composedSprite, err = ComposerCLI.composeFromSpritesheets(
            bodySprite, 
            handsSprite, 
            mouthSprite, 
            eyesSprite, 
            collateralSprite,
            assetsPath,
            outputPath
        )
        
        -- Close all sprites
        for _, sprite in ipairs(spritesToClose) do
            pcall(function()
                app.activeSprite = sprite
                app.command.CloseFile()
            end)
        end
        
        if not composedSprite then
            print("ERROR: Composition failed: " .. (err or "Unknown error"))
            print("Failed to compose sprite")
            return
        end
        
        print("")
        print("=== Composition Complete ===")
        if outputPath then
            print("Output file: " .. outputPath)
        end
        print("")
        print("Done!")
        return
    end
    
    -- Individual part generation (partChoice 1-5)
    local partNames = {"body", "hands", "collateral", "mouth", "eyes"}
    local partName = partNames[partChoice]
    
    print("")
    print("Selected Collateral: " .. collateralDisplay)
    if partChoice == 5 then
        print("Eye Shape Trait Value: " .. eyeShapeValue)
        print("Eye Color Trait Value: " .. eyeColorValue)
    end
    print("")
    
    local outputPath = nil
    local sprite = nil
    local err = nil
    
    print("")
    print("Generating " .. partName .. " spritesheet...")
    
    if partChoice <= 4 then
        -- Body, Hands, Collateral, Mouth depend on collateral
        local jsonPath = assetsPath .. "/JSONs/Body/collateral-base-" .. collateralLower .. ".json"
        
        if partChoice == 1 then
            -- Body
            sprite, err = SpriteSheetGenerator.generateBodySpriteSheet(collateralName, jsonPath, assetsPath)
            outputPath = assetsPath .. "/Output/test-body-spritesheet-" .. collateralLower .. ".aseprite"
        elseif partChoice == 2 then
            -- Hands
            sprite, err = SpriteSheetGenerator.generateHandsSpriteSheet(collateralName, jsonPath, assetsPath)
            outputPath = assetsPath .. "/Output/test-hands-spritesheet-" .. collateralLower .. ".aseprite"
        elseif partChoice == 3 then
            -- Collateral
            -- Find collateral JSON file
            local collateralBasePath = assetsPath .. "/JSONs/Collaterals"
            local collateralJsonPath = nil
            if app.fs.isDirectory(collateralBasePath) then
                local files = app.fs.listFiles(collateralBasePath)
                for _, file in ipairs(files) do
                    if file:match("collateral%-" .. collateralLower) then
                        collateralJsonPath = collateralBasePath .. "/" .. file
                        break
                    end
                end
            end
            if not collateralJsonPath or not app.fs.isFile(collateralJsonPath) then
                print("ERROR: Collateral JSON not found for " .. collateralName)
                return
            end
            sprite, err = SpriteSheetGenerator.generateCollateralSpriteSheet(collateralName, collateralJsonPath, assetsPath)
            outputPath = assetsPath .. "/Output/test-collateral-spritesheet-" .. collateralLower .. ".aseprite"
        elseif partChoice == 4 then
            -- Mouth
            sprite, err = SpriteSheetGenerator.generateMouthSpriteSheet(collateralName, jsonPath, assetsPath)
            outputPath = assetsPath .. "/Output/test-mouth-spritesheet-" .. collateralLower .. ".aseprite"
        end
    else
        -- Eyes - ask if user wants to generate all eyes or just one
        print("")
        print("Eyes Generation Mode:")
        print("  1. Single Eye (specify eye shape and eye color)")
        print("  2. All Eyes for " .. collateralDisplay .. " (batch generate all eyes in all subfolders)")
        print("")
        io.write("Select mode (1 or 2): ")
        io.flush()
        local input = io.read()
        local eyesModeChoice = input and tonumber(input) or nil
        
        if not eyesModeChoice or (eyesModeChoice ~= 1 and eyesModeChoice ~= 2) then
            print("ERROR: Eyes mode must be 1 or 2")
            return
        end
        
        if eyesModeChoice == 2 then
            -- Batch generate all eyes for this collateral
            print("")
            print("=== Batch Generating All Eyes for " .. collateralDisplay .. " ===")
            print("")
            
            local eyesBasePath = assetsPath .. "/JSONs/Eyes/" .. collateralLower
            
            if not app.fs.isDirectory(eyesBasePath) then
                print("ERROR: Eyes directory not found: " .. eyesBasePath)
                return
            end
            
            -- Define the 7 rarity folders and their subfolders (structure from batch script)
            local rarityFolders = {
                {name = "Collateral", subfolders = {collateralName:upper() .. "Collateral_Range_98-99"}},
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
                        print("Processing: " .. rarityFolder.name .. "/" .. subfolder .. "/" .. rarity .. "...")
                        
                        local batchSprite, batchErr
                        local ok, result1, result2 = pcall(function()
                            return SpriteSheetGenerator.generateEyesSpriteSheet(rarity, jsonPath, assetsPath)
                        end)
                        
                        if not ok then
                            print("  ERROR (pcall failed): " .. tostring(result1))
                            totalErrors = totalErrors + 1
                            goto continue_rarity_file
                        end
                        
                        batchSprite = result1
                        batchErr = result2
                        
                        if not batchSprite then
                            print("  ERROR: " .. (batchErr or "Unknown error"))
                            totalErrors = totalErrors + 1
                            goto continue_rarity_file
                        end
                        
                        -- Create output path
                        local outputSubfolder = rarityFolder.name .. "/" .. subfolder
                        local outputDir = assetsPath .. "/Output/Eyes/" .. collateralLower .. "/" .. outputSubfolder
                        app.fs.makeDirectory(outputDir)
                        
                        local batchOutputPath = outputDir .. "/eyes-" .. rarity .. ".aseprite"
                        app.activeSprite = batchSprite
                        batchSprite:saveAs(batchOutputPath)
                        
                        print("  ✓ Saved to " .. batchOutputPath)
                        
                        -- Close sprite
                        pcall(function()
                            app.activeSprite = batchSprite
                            app.command.CloseFile()
                        end)
                        
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
            return
        else
            -- Single eye generation (original logic)
            local eyeShapeFolder = ComposerHelper.getEyeShapeFolder(eyeShapeValue)
            local eyeColorRarity = ComposerHelper.getEyeColorRarity(eyeColorValue)
            
            if not eyeShapeFolder then
                print("ERROR: Could not determine eye shape folder for value: " .. eyeShapeValue)
                return
            end
            
            -- Handle collateral eye shape folder
            local eyesJsonFolder = eyeShapeFolder
            if eyeShapeFolder == "Collateral" then
                local eyesBasePath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/Collateral"
                if app.fs.isDirectory(eyesBasePath) then
                    local files = app.fs.listFiles(eyesBasePath)
                    for _, file in ipairs(files) do
                        local fullPath = eyesBasePath .. "/" .. file
                        if app.fs.isDirectory(fullPath) then
                            eyesJsonFolder = "Collateral/" .. file
                            break
                        end
                    end
                    if eyesJsonFolder == "Collateral" then
                        eyesJsonFolder = "Collateral/" .. collateralName:upper() .. "Collateral_Range_98-99"
                    end
                else
                    eyesJsonFolder = "Collateral/" .. collateralName:upper() .. "Collateral_Range_98-99"
                end
            end
            
            -- Find eyes JSON file
            local eyesFolderPath = assetsPath .. "/JSONs/Eyes/" .. collateralLower .. "/" .. eyesJsonFolder
            local eyesJsonPath = nil
            if app.fs.isDirectory(eyesFolderPath) then
                local files = app.fs.listFiles(eyesFolderPath)
                for _, file in ipairs(files) do
                    if file:match("eyes%-" .. eyeColorRarity) then
                        eyesJsonPath = eyesFolderPath .. "/" .. file
                        break
                    end
                end
            end
            
            if not eyesJsonPath or not app.fs.isFile(eyesJsonPath) then
                print("ERROR: Eyes JSON not found:")
                print("  Expected path: " .. eyesFolderPath)
                print("  Looking for rarity: " .. eyeColorRarity)
                return
            end
            
            print("Eye Shape Folder: " .. eyeShapeFolder)
            print("Eye Color Rarity: " .. eyeColorRarity)
            print("Eyes JSON Path: " .. eyesJsonPath)
            
            sprite, err = SpriteSheetGenerator.generateEyesSpriteSheet(eyeColorRarity, eyesJsonPath, assetsPath)
            
            -- Create output directory structure
            local outputDir = assetsPath .. "/Output/Eyes/" .. collateralLower .. "/" .. eyesJsonFolder
            app.fs.makeDirectory(outputDir)
            outputPath = outputDir .. "/eyes-" .. eyeColorRarity .. ".aseprite"
        end
        end
        
        if not sprite then
            print("ERROR: Failed to generate " .. partName .. " sprite: " .. (err or "Unknown error"))
            return
        end
        
        -- Save sprite
        if outputPath then
            app.activeSprite = sprite
            sprite:saveAs(outputPath)
            print("")
            print("SUCCESS: Generated " .. partName .. " spritesheet")
            print("Saved to: " .. outputPath)
            print("")
            
            -- Close sprite
            pcall(function()
                app.activeSprite = sprite
                app.command.CloseFile()
            end)
        else
            print("ERROR: No output path specified")
        end
        
        print("Done!")
        return
end

-- Continue with composition mode (modeChoice == 1)
local selectedCollateral = collaterals[collateralChoice]
local collateralName = selectedCollateral.name
local collateralDisplay = selectedCollateral.displayName

print("")
print("Selected Collateral: " .. collateralDisplay)
print("Eye Shape Trait Value: " .. eyeShapeValue)
print("Eye Color Trait Value: " .. eyeColorValue)
print("")

-- Determine eye shape folder and eye color rarity
local eyeShapeFolder = ComposerHelper.getEyeShapeFolder(eyeShapeValue)
local eyeColorRarity = ComposerHelper.getEyeColorRarity(eyeColorValue)

if not eyeShapeFolder then
    print("ERROR: Could not determine eye shape folder for value: " .. eyeShapeValue)
    return
end

print("Determined Eye Shape Folder: " .. eyeShapeFolder)
print("Determined Eye Color Rarity: " .. eyeColorRarity)
print("")

-- Ask for composition source mode
print("Select composition source:")
print("  1. Aseprite Library (use pre-generated .aseprite files)")
print("  2. JSON Source (generate spritesheets from JSON on-the-fly)")
print("")
io.write("Select source (1 or 2): ")
io.flush()
local input = io.read()
local sourceChoice = input and tonumber(input) or nil

if not sourceChoice or (sourceChoice ~= 1 and sourceChoice ~= 2) then
    print("ERROR: Source must be 1 or 2")
    return
end

local useAsepriteMode = (sourceChoice == 1)
local modeName = useAsepriteMode and "Aseprite Library" or "JSON Source"
print("Selected Source: " .. modeName)
print("")

-- Initialize variables that might be used in cleanup
local collateralLower = collateralName:lower()
local paths = nil
local bodySprite, handsSprite, mouthSprite, eyesSprite, collateralSprite = nil, nil, nil, nil, nil
local spritesToClose = {}
local composedSprite = nil
local outputFilename = nil
local outputPath = nil

-- Resolve paths
if useAsepriteMode then
    paths = ComposerHelper.resolveAsepritePaths(assetsPath, collateralName, eyeShapeValue, eyeColorRarity)
else
    paths = ComposerHelper.resolveJsonPaths(assetsPath, collateralName, eyeShapeValue, eyeColorRarity)
end

-- Display paths
print("Spritesheet Paths:")
print("  Body: " .. paths.body)
print("  Hands: " .. paths.hands)
print("  Mouth: " .. paths.mouth)
print("  Collateral: " .. (paths.collateral or "N/A"))
print("  Eyes: " .. (paths.eyes or "N/A"))
print("")

-- Load or generate sprites

-- Body
print("Loading/Generating body spritesheet...")
if useAsepriteMode then
    bodySprite, err = ComposerCLI.loadSprite(paths.body)
    if not bodySprite then
        print("ERROR: " .. (err or "Failed to load body sprite"))
        return
    end
    table.insert(spritesToClose, bodySprite)
    print("Body sprite loaded: " .. bodySprite.width .. "x" .. bodySprite.height .. ", " .. #bodySprite.frames .. " frames")
else
    bodySprite, err = SpriteSheetGenerator.generateBodySpriteSheet(collateralName, paths.body, assetsPath)
    if not bodySprite then
        print("ERROR: Failed to generate body sprite: " .. (err or "Unknown error"))
        return
    end
    table.insert(spritesToClose, bodySprite)
end

-- Hands
print("Loading/Generating hands spritesheet...")
if useAsepriteMode then
    handsSprite, err = ComposerCLI.loadSprite(paths.hands)
    if not handsSprite then
        print("ERROR: " .. (err or "Failed to load hands sprite"))
        -- Cleanup and return
        for _, sprite in ipairs(spritesToClose) do
            ComposerCLI.closeSprite(sprite)
        end
        return
    end
    table.insert(spritesToClose, handsSprite)
    print("Hands sprite loaded: " .. handsSprite.width .. "x" .. handsSprite.height .. ", " .. #handsSprite.frames .. " frames")
else
    handsSprite, err = SpriteSheetGenerator.generateHandsSpriteSheet(collateralName, paths.hands, assetsPath)
    if not handsSprite then
        print("ERROR: Failed to generate hands sprite: " .. (err or "Unknown error"))
        -- Cleanup and return
        for _, sprite in ipairs(spritesToClose) do
            ComposerCLI.closeSprite(sprite)
        end
        return
    end
    table.insert(spritesToClose, handsSprite)
end

-- Mouth
print("Loading/Generating mouth spritesheet...")
if useAsepriteMode then
    mouthSprite, err = ComposerCLI.loadSprite(paths.mouth)
    if mouthSprite then
        table.insert(spritesToClose, mouthSprite)
        print("Mouth sprite loaded: " .. mouthSprite.width .. "x" .. mouthSprite.height .. ", " .. #mouthSprite.frames .. " frames")
    else
        print("WARNING: Mouth sprite not found (optional)")
    end
else
    mouthSprite, err = SpriteSheetGenerator.generateMouthSpriteSheet(collateralName, paths.mouth, assetsPath)
    if mouthSprite then
        table.insert(spritesToClose, mouthSprite)
    else
        print("WARNING: Failed to generate mouth sprite (optional): " .. (err or "Unknown error"))
    end
end

-- Collateral (optional)
if paths.collateral then
    print("Loading/Generating collateral spritesheet...")
    if useAsepriteMode then
        collateralSprite, err = ComposerCLI.loadSprite(paths.collateral)
        if collateralSprite then
            table.insert(spritesToClose, collateralSprite)
            print("Collateral sprite loaded: " .. collateralSprite.width .. "x" .. collateralSprite.height .. ", " .. #collateralSprite.frames .. " frames")
        else
            print("WARNING: Collateral sprite not found (optional)")
        end
    else
        -- Find the actual JSON file (has timestamp)
        local collateralJsonPath = nil
        if app.fs.isFile(paths.collateral) then
            collateralJsonPath = paths.collateral
        else
            -- Try to find it
            local collateralBasePath = assetsPath .. "/JSONs/Collaterals"
            if app.fs.isDirectory(collateralBasePath) then
                local files = app.fs.listFiles(collateralBasePath)
                for _, file in ipairs(files) do
                    if file:match("collateral%-" .. collateralName:lower()) then
                        collateralJsonPath = collateralBasePath .. "/" .. file
                        break
                    end
                end
            end
        end
        
        if collateralJsonPath and app.fs.isFile(collateralJsonPath) then
            collateralSprite, err = SpriteSheetGenerator.generateCollateralSpriteSheet(collateralName, collateralJsonPath, assetsPath)
            if collateralSprite then
                table.insert(spritesToClose, collateralSprite)
            else
                print("WARNING: Failed to generate collateral sprite (optional): " .. (err or "Unknown error"))
            end
        else
            print("WARNING: Collateral JSON not found (optional)")
        end
    end
end

-- Eyes
if paths.eyes then
    print("Loading/Generating eyes spritesheet...")
    if useAsepriteMode then
        eyesSprite, err = ComposerCLI.loadSprite(paths.eyes)
        if eyesSprite then
            table.insert(spritesToClose, eyesSprite)
            print("Eyes sprite loaded: " .. eyesSprite.width .. "x" .. eyesSprite.height .. ", " .. #eyesSprite.frames .. " frames")
        else
            print("WARNING: Eyes sprite not found (optional)")
        end
    else
        -- Find the actual JSON file (has timestamp)
        if paths.eyes and app.fs.isFile(paths.eyes) then
            eyesSprite, err = SpriteSheetGenerator.generateEyesSpriteSheet(eyeColorRarity, paths.eyes, assetsPath)
            if eyesSprite then
                table.insert(spritesToClose, eyesSprite)
            else
                print("WARNING: Failed to generate eyes sprite (optional): " .. (err or "Unknown error"))
            end
        else
            print("WARNING: Eyes JSON not found (optional)")
        end
    end
end

print("")

-- Generate output filename
outputFilename = "aavegotchi-" .. collateralLower .. "-eyeShape" .. eyeShapeValue .. "-eyeColor" .. eyeColorValue .. ".aseprite"
outputPath = assetsPath .. "/Output/" .. outputFilename

-- Compose sprites
print("Composing Aavegotchi sprite...")
print("")
composedSprite, err = ComposerCLI.composeFromSpritesheets(
    bodySprite, 
    handsSprite, 
    mouthSprite, 
    eyesSprite, 
    collateralSprite,
    assetsPath,
    outputPath
)

-- Close all loaded sprites
for _, sprite in ipairs(spritesToClose) do
    ComposerCLI.closeSprite(sprite)
end

if not composedSprite then
    print("ERROR: Composition failed: " .. (err or "Unknown error"))
    print("Failed to compose sprite")
    return
end

print("")
print("=== Composition Complete ===")
if outputPath then
    print("Output file: " .. outputPath)
end
print("")
print("Done!")

