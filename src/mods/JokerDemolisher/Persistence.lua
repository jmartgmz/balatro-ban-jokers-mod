-- Return cached instance if it exists (singleton pattern)
if JokerDemolisher_Persistence then
    return JokerDemolisher_Persistence
end

local mod_path = SMODS.current_mod and SMODS.current_mod.path or JokerDemolisher_ModPath
local Utils = assert(loadfile(mod_path .. "Utils.lua"))()

local Persistence = {}
local GloballyDisabledFilename = "GloballyDisabled.txt"

local function serialize(val, depth)
    local temp = string.rep(" ", depth)

    if type(val) == "table" then
        temp = temp .. "{\n"
        local entries = {}
        for k, v in pairs(val) do
            local entry = string.rep(" ", depth + 1)
            if type(k) == "string" then
                entry = entry .. "[" .. string.format("%q", k) .. "] = "
            end
            entry = entry .. serialize(v, depth + 2)
            table.insert(entries, entry)
        end
        temp = temp .. table.concat(entries, ",\n")
        temp = temp .. "\n" .. string.rep(" ", depth) .. "}"
    else
        if type(val) == "string" then
            temp = temp .. string.format("%q", val)
        else
            temp = temp .. tostring(val)
        end
    end
    return temp
end

function Persistence.saveGloballyDisabled()
    local directory = "Mods/JokerDemolisher"
    local filePath = directory .. "/" .. GloballyDisabledFilename
    local data = {
        jokers = Utils.globallyDisabledJokers
    }
    local serialized = serialize(data, 0)
    love.filesystem.write(filePath, serialized)
    Utils.log("Globally disabled jokers saved")
end

function Persistence.loadGloballyDisabled()
    local directory = "Mods/JokerDemolisher"
    local filePath = directory .. "/" .. GloballyDisabledFilename
    local fileContent = love.filesystem.read(filePath)

    if fileContent then
        local func, err = loadstring("return " .. fileContent)
        if func then
            local data = func()
            Utils.globallyDisabledJokers = data.jokers or {}
            Utils.log("Globally disabled jokers loaded")
        else
            Utils.log("Could not deserialize globally disabled data: " .. (err or "unknown error"))
        end
    else
        Utils.log("No globally disabled jokers file found, starting fresh")
        Utils.globallyDisabledJokers = {}
    end
end

function Persistence.isGloballyDisabled(key, itemType)
    if itemType ~= 'Joker' then
        return false
    end
    
    for _, v in ipairs(Utils.globallyDisabledJokers) do
        if v == key then return true end
    end
    return false
end

function Persistence.toggleGloballyDisabled(key, itemType)
    if itemType ~= 'Joker' then
        return false
    end

    -- Check if already in list
    for i, v in ipairs(Utils.globallyDisabledJokers) do
        if v == key then
            table.remove(Utils.globallyDisabledJokers, i)
            Persistence.saveGloballyDisabled()
            Utils.log("Re-enabled globally: " .. key)
            return false -- Was disabled, now enabled
        end
    end

    -- Not in list, add it
    table.insert(Utils.globallyDisabledJokers, key)
    Persistence.saveGloballyDisabled()
    Utils.log("Disabled globally: " .. key)
    return true -- Was enabled, now disabled
end

-- Cache the instance globally
JokerDemolisher_Persistence = Persistence

return Persistence
