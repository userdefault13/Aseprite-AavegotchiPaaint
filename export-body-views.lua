-- Export Body Views Script
-- This script exports all 4 body views with colors from JSON
-- Run this as a standalone Aseprite script

local BodyExporter = dofile("body-exporter.lua")

-- Configuration
local assetsPath = "/Users/juliuswong/Dev/Aseprite-AavegotchiPaaint"
local collateral = "amAAVE"
local outputDir = assetsPath .. "/Output"

-- Ensure output directory exists (create if needed)
if not app.fs.isDirectory(outputDir) then
    app.alert("Output directory does not exist. Please create: " .. outputDir)
    return
end

-- Export all 4 views
app.alert("Starting export of " .. collateral .. " body views...")
local results = BodyExporter.exportAllViews(assetsPath, collateral, outputDir)

-- Report results
local successCount = 0
local errorCount = 0
local messages = {}

for view, result in pairs(results) do
    if result.success then
        successCount = successCount + 1
        table.insert(messages, "✓ " .. view .. ": " .. result.path)
    else
        errorCount = errorCount + 1
        table.insert(messages, "✗ " .. view .. ": " .. (result.error or "Failed"))
    end
end

local summary = "Export complete!\n\n"
summary = summary .. "Success: " .. successCount .. "\n"
summary = summary .. "Errors: " .. errorCount .. "\n\n"
summary = summary .. table.concat(messages, "\n")

app.alert(summary)

