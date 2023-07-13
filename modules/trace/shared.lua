---@enum traceTypes
local traceTypes = {
    ["info"]    = "[^5INFO^7]",
    ["warning"] = "[^3WARNING^7]",
    ["error"]   = "[^1ERROR^7]",
    ["trace"]   = "[^2TRACE^7]"
}

---@param message string
---@param traceType? traceTypes
---@param forcePrint? boolean
function ESX.Trace(message, traceType, forcePrint)
    if not Config.EnableDebug and not forcePrint then return end

    if type(traceType) ~= "string" or not traceTypes[traceType:lower()] then
        traceType = traceTypes.trace
    end

    print(("%s %s^7"):format(traceType, message))
end
