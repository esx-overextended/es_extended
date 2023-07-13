local traceTypes = {
    ["info"]    = "[^5INFO^7]",
    ["warning"] = "[^3WARNING^7]",
    ["error"]   = "[^1ERROR^7]",
    ["trace"]   = "[^2TRACE^7]"
}

---@param message string
---@param traceType? "info" | "warning" | "error" | "trace"
---@param forcePrint? boolean
function ESX.Trace(message, traceType, forcePrint)
    if not Config.EnableDebug and not forcePrint then return end

    if type(traceType) ~= "string" or not traceTypes[traceType:lower()] then
        traceType = traceTypes.trace ---@diagnostic disable-line: cast-local-type
    end

    print(("%s %s^7"):format(traceType, message))
end

do
    local conflictResources = {
        "essentialmode",
        "es_admin2",
        "basic-gamemode",
        "mapmanager",
        "fivem-map-skater",
        "fivem-map-hipster",
        "qb-core",
        "default_spawnpoint",
    }

    for i = 1, #conflictResources do
        if GetResourceState(conflictResources[i]):find("start") then
            ESX.Trace(("YOU ARE USING A RESOURCE THAT WILL CAUSE CONFLICT AND POSSIBLY BREAK ^1ESX^7, PLEASE REMOVE ^5%s^7"):format(conflictResources[i]), "error", true)
        end
    end
end
