-- Generate All Sprite Sheets Command
-- This command generates all 16 body sprite sheets and all 18 eye range sprite sheets

local SpriteSheetGenerator = dofile("sprite-sheet-generator.lua")

-- Set paths (same as hardcoded in aavegotchi-paint-panel.lua)
local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local outputDir = assetsPath .. "/Output"

-- Function to show the generation dialog
local function showGenerateDialog()
    -- Show confirmation dialog
    local dlg = Dialog("Generate All Sprite Sheets")
    dlg:label{
        text = "This will generate:",
        focus = false
    }
    dlg:newrow()
    dlg:label{
        text = "• 16 body sprite sheets (no eyes)",
        focus = false
    }
    dlg:newrow()
    dlg:label{
        text = "• 18 eye range sprite sheets (all 6 rarities each)",
        focus = false
    }
    dlg:newrow()
    dlg:label{
        text = "",
        focus = false
    }
    dlg:newrow()
    dlg:label{
        text = "Output: " .. outputDir,
        focus = false
    }
    dlg:newrow()
    dlg:button{
        text = "Generate",
        onclick = function()
            dlg:close()
            
            -- Generate body sprite sheets
            app.alert("Starting generation...\n\nThis may take a while.\nCheck the console for progress.")
            
            print("=== Sprite Sheet Generator ===")
            print("Assets Path: " .. assetsPath)
            print("Output Directory: " .. outputDir)
            print("")
            
            local bodiesDir = outputDir .. "/bodies"
            local eyesDir = outputDir .. "/eyes"
            
            print("Generating body sprite sheets...")
            print("")
            
            local bodyConfig = {
                mouthExpression = "neutral",
                handPose = "down_open",
                wearables = {}
            }
            
            local bodyResults, bodyErr = SpriteSheetGenerator.generateAllCollateralBodySpriteSheets(
                assetsPath,
                bodiesDir,
                bodyConfig
            )
            
            if bodyErr then
                print("Error: " .. bodyErr)
                app.alert("Error generating body sheets: " .. bodyErr)
            else
                local successCount = 0
                local failCount = 0
                for collateral, result in pairs(bodyResults) do
                    if result.success then
                        print("✓ " .. collateral .. ": " .. result.outputPath)
                        successCount = successCount + 1
                    else
                        print("✗ " .. collateral .. ": " .. (result.error or "Unknown error"))
                        failCount = failCount + 1
                    end
                end
                print("")
                print("Body sheets: " .. successCount .. " succeeded, " .. failCount .. " failed")
            end
            
            print("")
            print("Generating eye sprite sheets...")
            print("")
            
            local eyeResults, eyeErr = SpriteSheetGenerator.generateAllEyeRangeSpriteSheets(
                assetsPath,
                eyesDir
            )
            
            if eyeErr then
                print("Error: " .. eyeErr)
                app.alert("Error generating eye sheets: " .. eyeErr)
            else
                local successCount = 0
                local failCount = 0
                for eyeRange, result in pairs(eyeResults) do
                    if result.success then
                        print("✓ " .. eyeRange .. ": " .. result.outputPath)
                        successCount = successCount + 1
                    else
                        print("✗ " .. eyeRange .. ": " .. (result.error or "Unknown error"))
                        failCount = failCount + 1
                    end
                end
                print("")
                print("Eye sheets: " .. successCount .. " succeeded, " .. failCount .. " failed")
            end
            
            print("")
            print("=== Generation Complete ===")
            
            app.alert("Generation complete!\n\nCheck the console for details.\n\nOutput saved to:\n" .. outputDir)
        end
    }
    dlg:button{
        text = "Cancel",
        onclick = function()
            dlg:close()
        end
    }
    dlg:show()
end

-- Register the plugin command
function init(plugin)
    plugin:newCommand{
        id = "generate_all_sprite_sheets",
        title = "Generate All Sprite Sheets",
        group = "tools",
        onenabled = function() return true end,
        onclick = showGenerateDialog
    }
end

return plugin

