ESX = {}
ESX.Players = {} --[[@type table<number, xPlayer> ]]
ESX.Items = {}
Core = {}
Core.UsableItemsCallbacks = {}
Core.Pickups = {}
Core.PickupId = 0
Core.DatabaseConnected = false
Core.PlayersByCid = {} --[[@type table<string, xPlayer> ]]
Core.PlayersByIdentifier = {} --[[@type table<string, xPlayer> ]]
Core.Vehicles = {} --[[@type table<number, xVehicle> ]]
Core.VehicleEntitiesByVin = {} --[[@type table<string, number> ]]
Core.ResourceExport = exports[cache.resource]

AddEventHandler("esx:getSharedObject", function(cb)
    return cb and cb(ESX)
end)

exports("getSharedObject", function()
    return ESX
end)

exports("getReference", function(index)
    return ESX[index]
end)

local function startDBSync()
    CreateThread(function()
        while true do
            Wait(10 * 60 * 1000)

            Core.SavePlayers()
        end
    end)
end

MySQL.ready(function()
    MySQL.transaction.await(lib.require("esx-sql-triggers"))

    if not Config.OxInventory then
        local items = MySQL.query.await("SELECT * FROM items")
        for _, v in ipairs(items) do
            ESX.Items[v.name] = { label = v.label, weight = v.weight, rare = v.rare, canRemove = v.can_remove }
        end
    else
        TriggerEvent("__cfx_export_ox_inventory_Items", function(ref)
            if ref then
                ESX.Items = ref()
            end
        end)

        AddEventHandler("ox_inventory:itemList", function(items)
            ESX.Items = items
        end)

        while not next(ESX.Items) do
            Wait(0)
        end
    end

    while not ESX.RefreshJobs or not ESX.RefreshGroups do Wait(0) end

    ESX.RefreshJobs()

    ESX.Trace(("ESX ^5Overextended %s^0 Initialized!"):format(GetResourceMetadata(cache.resource, "version", 0)), "info", true)

    startDBSync()

    Core.DatabaseConnected = true
end)

function ESX.GetConfig() ---@diagnostic disable-line: duplicate-set-field
    return Config
end

lib.require("modules.hooks.server")
lib.require("modules.override.server")
lib.require("modules.safeEvent.server")
