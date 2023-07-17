ESX = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false
ESX.UI = {}
Core = {}
Core.ResourceExport = exports[cache.resource]

AddEventHandler("esx:getSharedObject", function(cb)
    return cb and cb(ESX)
end)

exports("getSharedObject", function()
    return ESX
end)

function ESX.GetConfig() ---@diagnostic disable-line: duplicate-set-field
    return Config
end

lib.require("modules.safeEvent.client")
