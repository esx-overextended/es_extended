ESX = {}
ESX.Players = {} --[[@type table<number, xPlayer> ]]
ESX.Items = {}
Core = {}
Core.UsableItemsCallbacks = {}
Core.RegisteredCommands = {}
Core.Pickups = {}
Core.PickupId = 0
Core.DatabaseConnected = false
Core.PlayersByIdentifier = {} --[[@type table<string, xPlayer> ]]
Core.Vehicles = {} --[[@type table<number, xVehicle> ]]
Core.ResourceExport = exports[cache.resource]

AddEventHandler("esx:getSharedObject", function(cb)
    return cb and cb(ESX)
end)

exports("getSharedObject", function()
    return ESX
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

    print(("[^2INFO^7] ESX ^5Overextended %s^0 Initialized!"):format(GetResourceMetadata(GetCurrentResourceName(), "version", 0)))

    startDBSync()

    if Config.EnablePaycheck then
        StartPayCheck()
    end

    Core.DatabaseConnected = true
end)

RegisterServerEvent("esx:clientLog", function(msg)
    if Config.EnableDebug then
        print(("[^2TRACE^7] %s^7"):format(msg))
    end
end)

lib.require("modules.hooks.server")
lib.require("modules.override.server")
lib.require("modules.safeEvent.server")
