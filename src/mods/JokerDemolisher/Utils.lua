-- Return cached instance if it exists (singleton pattern)
if JokerDemolisher_Utils then
    return JokerDemolisher_Utils
end

local Utils = {}

Utils.mode = "PROD"

-- Global disabled jokers (disabled across ALL runs via click in collection)
Utils.globallyDisabledJokers = {}

function Utils.log(message)
    if sendDebugMessage ~= nil then
        sendDebugMessage(message, "JokerDemolisher")
    end
end

-- Cache the instance globally
JokerDemolisher_Utils = Utils

return Utils
