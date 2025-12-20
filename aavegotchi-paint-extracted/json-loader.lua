-- JSON Loader for Aavegotchi databases
-- Simple JSON parser for wearables database

local JsonLoader = {}

-- Extract wearable entries from JSON using pattern matching
-- This is a simplified parser that works for our specific JSON structure
local function extractWearables(jsonContent)
    local wearables = {}
    local currentIndex = 1
    
    -- Find the start of the wearables array
    local startPos = jsonContent:find('"wearables"%s*:%s*%[')
    if not startPos then
        return wearables
    end
    
    -- Find individual wearable objects
    local pos = startPos
    while true do
        -- Find next wearable object start
        local objStart = jsonContent:find('{%s*"id"', pos)
        if not objStart then break end
        
        -- Find the end of this wearable object
        local braceCount = 0
        local inString = false
        local escapeNext = false
        local objEnd = objStart
        
        for i = objStart, #jsonContent do
            local char = jsonContent:sub(i, i)
            
            if escapeNext then
                escapeNext = false
            elseif char == '\\' then
                escapeNext = true
            elseif char == '"' and not escapeNext then
                inString = not inString
            elseif not inString then
                if char == '{' then
                    braceCount = braceCount + 1
                elseif char == '}' then
                    braceCount = braceCount - 1
                    if braceCount == 0 then
                        objEnd = i
                        break
                    end
                end
            end
        end
        
        if objEnd > objStart then
            local wearableStr = jsonContent:sub(objStart, objEnd)
            
            -- Extract ID
            local idMatch = wearableStr:match('"id"%s*:%s*(%d+)')
            if idMatch then
                local wearable = {
                    id = tonumber(idMatch)
                }
                
                -- Extract name
                local nameMatch = wearableStr:match('"name"%s*:%s*"([^"]+)"')
                if nameMatch then
                    wearable.name = nameMatch
                end
                
                -- Extract slotPositions array
                -- Find the position of "slotPositions"
                local slotsPos = wearableStr:find('"slotPositions"%s*:%s*%[')
                if slotsPos then
                    -- Find the matching closing bracket by counting brackets
                    local bracketCount = 0
                    local inString = false
                    local escapeNext = false
                    local arrayStart = slotsPos
                    local arrayEnd = nil
                    
                    -- Find the opening bracket
                    for i = slotsPos, #wearableStr do
                        local char = wearableStr:sub(i, i)
                        if char == '[' then
                            arrayStart = i
                            bracketCount = 1
                            i = i + 1
                            -- Now find matching closing bracket
                            for j = i, #wearableStr do
                                local char2 = wearableStr:sub(j, j)
                                
                                if escapeNext then
                                    escapeNext = false
                                elseif char2 == '\\' then
                                    escapeNext = true
                                elseif char2 == '"' and not escapeNext then
                                    inString = not inString
                                elseif not inString then
                                    if char2 == '[' then
                                        bracketCount = bracketCount + 1
                                    elseif char2 == ']' then
                                        bracketCount = bracketCount - 1
                                        if bracketCount == 0 then
                                            arrayEnd = j
                                            break
                                        end
                                    end
                                end
                            end
                            break
                        end
                    end
                    
                    if arrayEnd and arrayEnd > arrayStart then
                        local slotsStr = wearableStr:sub(arrayStart + 1, arrayEnd - 1)
                        wearable.slotPositions = {}
                        -- Match true/false values (case sensitive)
                        for value in slotsStr:gmatch('[%s,]*([tf][ar][ul][se]e?)[%s,]*') do
                            if value == "true" then
                                table.insert(wearable.slotPositions, true)
                            elseif value == "false" then
                                table.insert(wearable.slotPositions, false)
                            end
                        end
                    end
                end
                
                table.insert(wearables, wearable)
            end
        end
        
        pos = objEnd + 1
        if pos >= #jsonContent then break end
    end
    
    return wearables
end

-- Load wearables database from JSON file
function JsonLoader.loadWearablesDatabase(filePath)
    if not filePath then
        filePath = "aavegotchi_db_wearables.json"
    end
    
    if not app.fs.isFile(filePath) then
        return nil, "Wearables database file does not exist: " .. filePath
    end
    
    local file = io.open(filePath, "r")
    if not file then
        return nil, "Could not open wearables database file: " .. filePath
    end
    
    local content = file:read("*all")
    file:close()
    
    if not content or content == "" then
        return nil, "Wearables database file is empty"
    end
    
    local wearables = extractWearables(content)
    
    -- Use debug logging function if available
    if _G.debugLogMessage then
        _G.debugLogMessage("[DEBUG] JsonLoader: Extracted " .. #wearables .. " wearables from JSON")
        if #wearables > 0 then
            _G.debugLogMessage("[DEBUG] JsonLoader: First wearable - ID: " .. wearables[1].id .. ", Name: " .. (wearables[1].name or "nil"))
            if wearables[1].slotPositions then
                _G.debugLogMessage("[DEBUG] JsonLoader: First wearable has " .. #wearables[1].slotPositions .. " slot positions")
            end
        end
    end
    
    return {
        wearables = wearables
    }, nil
end

-- Get wearables for a specific slot
function JsonLoader.getWearablesForSlot(wearablesDb, slotIndex)
    if not wearablesDb or not wearablesDb.wearables then
        return {}
    end
    
    local slotWearables = {}
    for _, wearable in ipairs(wearablesDb.wearables) do
        if wearable.slotPositions and wearable.slotPositions[slotIndex + 1] then
            table.insert(slotWearables, wearable)
        end
    end
    
    return slotWearables
end

return JsonLoader

