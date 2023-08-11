ESX.RegisterCommand("setcoords", "admin", function(xPlayer, args, _)
    xPlayer.setCoords({ x = args.x, y = args.y, z = args.z })
end, false, {
    help = _U("command_setcoords"),
    validate = true,
    arguments = {
        { name = "x", help = _U("command_setcoords_x"), type = "number" },
        { name = "y", help = _U("command_setcoords_y"), type = "number" },
        { name = "z", help = _U("command_setcoords_z"), type = "number" }
    }
})

ESX.RegisterCommand("setjob", "admin", function(xPlayer, args, showError)
    if ESX.DoesJobExist(args.job, args.grade) then
        args.playerId.setJob(args.job, args.grade)
    else
        showError(_U("command_setjob_invalid"))
    end
    ESX.DiscordLogFields("UserActions", "/setjob Triggered", "pink", {
        { name = "Player", value = xPlayer.name, inline = true },
        { name = "Job",    value = args.job,     inline = true },
        { name = "Grade",  value = args.grade,   inline = true }
    })
end, true, {
    help = _U("command_setjob"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" },
        { name = "job",      help = _U("command_setjob_job"),      type = "string" },
        { name = "grade",    help = _U("command_setjob_grade"),    type = "number" }
    }
})

ESX.RegisterCommand("setduty", "admin", function(_, args, showError)
    local toBoolean = { ["true"] = true, ["false"] = false }
    local duty = args.duty ~= nil and toBoolean[args.duty:lower()]

    if duty == nil then return showError(_U("command_setduty_invalid")) end

    args.playerId.setDuty(duty)
end, true, {
    help = _U("command_setduty"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" },
        { name = "duty",     help = _U("command_setjob_duty"),     type = "string" }
    }
})

local upgrades = Config.SpawnVehMaxUpgrades and {
    plate = "ADMINCAR",
    modEngine = 3,
    modBrakes = 2,
    modTransmission = 2,
    modSuspension = 3,
    modArmor = true,
    windowTint = 1
} or {}

local arrayOfVehiclesName, count = {}, 0
for modelName in pairs(ESX.GetVehicleData()) do
    count += 1
    arrayOfVehiclesName[count] = modelName
end

local function getRandomVehicleName() -- TODO: generating random must be achieved way better. Maybe should be implemented manually inside the esx's math module
    Wait(10)
    math.randomseed(os.time())
    math.random(count)
    math.random(count)                    -- To get better pseudo-random number just pop some random number before using them for really (http://lua-users.org/wiki/MathLibraryTutorial)
    local model = arrayOfVehiclesName[math.random(count)]
    local modelType = ESX.GetVehicleData(model)?.type
    return (modelType == "automobile" or modelType == "bike") and model or getRandomVehicleName()
end

ESX.RegisterCommand("car", "admin", function(xPlayer, args, _)
    local playerPed = GetPlayerPed(xPlayer?.source)
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    args.model = type(args.model) == "string" and args.model or getRandomVehicleName()
    args.owner = args.owner?.identifier

    local vehicle = ESX.CreateVehicle({
        owner = args.owner,
        model = args.model
    }, playerCoords, playerHeading)

    if not vehicle then return end

    if playerVehicle and playerVehicle > 0 then ESX.DeleteVehicle(playerVehicle) end

    if next(upgrades) and not args.owner then ESX.SetVehicleProperties(vehicle.entity, upgrades) end

    for _ = 1, 50 do
        Wait(0)
        SetPedIntoVehicle(playerPed, vehicle.entity, -1)

        if GetVehiclePedIsIn(playerPed, false) == vehicle.entity then
            break
        end
    end

    ESX.DiscordLogFields("UserActions", "/car Triggered", "pink", {
        { name = "Player",  value = xPlayer.name,   inline = true },
        { name = "ID",      value = xPlayer.source, inline = true },
        { name = "Vehicle", value = args.model,     inline = true },
        { name = "Owner",   value = args.owner,     inline = true }
    })
end, false, {
    help = _U("command_car"),
    validate = false,
    arguments = {
        { name = "model", help = _U("command_car_model"), type = "string" },
        { name = "owner", help = _U("command_car_owner"), type = "player" }
    }
})

ESX.RegisterCommand({ "cardel", "dv" }, "admin", function(xPlayer, args, _)
    local toBoolean = { ["true"] = true, ["false"] = false }
    local playerPed = GetPlayerPed(xPlayer?.source)
    local playerCoords = GetEntityCoords(playerPed)
    local playerVehicle = GetVehiclePedIsIn(playerPed, false)

    args.radius = tonumber(args.radius) or 5.0
    args.owned = type(args.owned) == "string" and toBoolean[args.owned:lower()]

    if playerVehicle and playerVehicle > 0 then
        return ESX.DeleteVehicle(playerVehicle)
    end

    local _, vehicleEntities, vehiclesCount = ESX.OneSync.GetVehiclesInArea(playerCoords, args.radius)

    for i = 1, vehiclesCount do
        local vehicleEntity = vehicleEntities[i]
        local vehicle = ESX.GetVehicle(vehicleEntity)

        if not vehicle then
            DeleteEntity(vehicleEntity)
        elseif args.owned or (not args.owned and not vehicle?.owner and not vehicle?.group) then
            vehicle.delete()
        end
    end
end, false, {
    help = _U("command_cardel"),
    validate = false,
    arguments = {
        { name = "radius", help = _U("command_cardel_radius"), type = "number" },
        { name = "owned",  help = _U("command_cardel_owned"),  type = "string" }
    }
})

ESX.RegisterCommand("setaccountmoney", "admin", function(_, args, showError)
    if args.playerId.getAccount(args.account) then
        args.playerId.setAccountMoney(args.account, args.amount, "Government Grant")
    else
        showError(_U("command_giveaccountmoney_invalid"))
    end
end, true, {
    help = _U("command_setaccountmoney"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"),          type = "player" },
        { name = "account",  help = _U("command_giveaccountmoney_account"), type = "string" },
        { name = "amount",   help = _U("command_setaccountmoney_amount"),   type = "number" }
    }
})

ESX.RegisterCommand("giveaccountmoney", "admin", function(_, args, showError)
    if args.playerId.getAccount(args.account) then
        args.playerId.addAccountMoney(args.account, args.amount, "Government Grant")
    else
        showError(_U("command_giveaccountmoney_invalid"))
    end
end, true, {
    help = _U("command_giveaccountmoney"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"),          type = "player" },
        { name = "account",  help = _U("command_giveaccountmoney_account"), type = "string" },
        { name = "amount",   help = _U("command_giveaccountmoney_amount"),  type = "number" }
    }
})

if not Config.OxInventory then
    ESX.RegisterCommand("giveitem", "admin", function(_, args, _)
        args.playerId.addInventoryItem(args.item, args.count)
    end, true, {
        help = _U("command_giveitem"),
        validate = true,
        arguments = {
            { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" },
            { name = "item",     help = _U("command_giveitem_item"),   type = "item" },
            { name = "count",    help = _U("command_giveitem_count"),  type = "number" }
        }
    })

    ESX.RegisterCommand("giveweapon", "admin", function(_, args, showError)
        if args.playerId.hasWeapon(args.weapon) then
            showError(_U("command_giveweapon_hasalready"))
        else
            args.playerId.addWeapon(args.weapon, args.ammo)
        end
    end, true, {
        help = _U("command_giveweapon"),
        validate = true,
        arguments = {
            { name = "playerId", help = _U("commandgeneric_playerid"),   type = "player" },
            { name = "weapon",   help = _U("command_giveweapon_weapon"), type = "weapon" },
            { name = "ammo",     help = _U("command_giveweapon_ammo"),   type = "number" }
        }
    })

    ESX.RegisterCommand("giveammo", "admin", function(_, args, showError)
        if args.playerId.hasWeapon(args.weapon) then
            args.playerId.addWeaponAmmo(args.weapon, args.ammo)
        else
            showError(_U("command_giveammo_noweapon_found"))
        end
    end, true, {
        help = _U("command_giveweapon"),
        validate = false,
        arguments = {
            { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" },
            { name = "weapon",   help = _U("command_giveammo_weapon"), type = "weapon" },
            { name = "ammo",     help = _U("command_giveammo_ammo"),   type = "number" }
        }
    })

    ESX.RegisterCommand("giveweaponcomponent", "admin", function(_, args, showError)
        if args.playerId.hasWeapon(args.weaponName) then
            local component = ESX.GetWeaponComponent(args.weaponName, args.componentName)

            if component then
                if args.playerId.hasWeaponComponent(args.weaponName, args.componentName) then
                    showError(_U("command_giveweaponcomponent_hasalready"))
                else
                    args.playerId.addWeaponComponent(args.weaponName, args.componentName)
                end
            else
                showError(_U("command_giveweaponcomponent_invalid"))
            end
        else
            showError(_U("command_giveweaponcomponent_missingweapon"))
        end
    end, true, {
        help = _U("command_giveweaponcomponent"),
        validate = true,
        arguments = {
            { name = "playerId",      help = _U("commandgeneric_playerid"),               type = "player" },
            { name = "weaponName",    help = _U("command_giveweapon_weapon"),             type = "weapon" },
            { name = "componentName", help = _U("command_giveweaponcomponent_component"), type = "string" }
        }
    })
end

ESX.RegisterCommand({ "clear", "cls" }, "user", function(xPlayer, _, _)
    xPlayer.triggerEvent("chat:clear")
end, false, { help = _U("command_clear") })

ESX.RegisterCommand({ "clearall", "clsall" }, "admin", function(_, _, _)
    TriggerClientEvent("chat:clear", -1)
end, true, { help = _U("command_clearall") })

ESX.RegisterCommand("refreshjobs", "admin", function(_, _, _)
    ESX.RefreshJobs()
end, true, { help = _U("command_refreshjobs") })

ESX.RegisterCommand("refreshgroups", "admin", function(_, _, _)
    ESX.RefreshGroups()
end, true, { help = _U("command_refreshgroups") })

if not Config.OxInventory then
    ESX.RegisterCommand("clearinventory", "admin", function(_, args, _)
        for _, v in ipairs(args.playerId.inventory) do
            if v.count > 0 then
                args.playerId.setInventoryItem(v.name, 0)
            end
        end
        TriggerEvent("esx:playerInventoryCleared", args.playerId)
    end, true, {
        help = _U("command_clearinventory"),
        validate = true,
        arguments = {
            { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
        }
    })

    ESX.RegisterCommand("clearloadout", "admin", function(_, args, _)
        for i = #args.playerId.loadout, 1, -1 do
            args.playerId.removeWeapon(args.playerId.loadout[i].name)
        end
        TriggerEvent("esx:playerLoadoutCleared", args.playerId)
    end, true, {
        help = _U("command_clearloadout"),
        validate = true,
        arguments = {
            { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
        }
    })
end

ESX.RegisterCommand("setgroup", "admin", function(xPlayer, args, _)
    if not args.playerId then args.playerId = xPlayer.source end

    args.playerId.setGroup(args.group)
end, true, {
    help = _U("command_setgroup"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" },
        { name = "group",    help = _U("command_setgroup_group"),  type = "string" },
    }
})

ESX.RegisterCommand("addgroup", "admin", function(xPlayer, args, _)
    if not args.playerId then args.playerId = xPlayer.source --[[@type xPlayer]] end

    args.playerId.addGroup(args.group, args.grade)
end, true, {
    help = _U("command_addgroup"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" },
        { name = "group",    help = _U("command_addgroup_group"),  type = "string" },
        { name = "grade",    help = _U("command_addgroup_grade"),  type = "number" },
    }
})

ESX.RegisterCommand("removegroup", "admin", function(xPlayer, args, _)
    if not args.playerId then args.playerId = xPlayer.source --[[@type xPlayer]] end

    args.playerId.removeGroup(args.group)
end, true, {
    help = _U("command_removegroup"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"),   type = "player" },
        { name = "group",    help = _U("command_removegroup_group"), type = "string" }
    }
})

ESX.RegisterCommand("save", "admin", function(_, args, _)
    Core.SavePlayer(args.playerId)
    ESX.Trace(("Saved Player (^5%s^0)"):format(), "info", true)
end, true, {
    help = _U("command_save"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
    }
})

ESX.RegisterCommand("saveall", "admin", function(_, _, _)
    Core.SavePlayers()
end, true, { help = _U("command_saveall") })

ESX.RegisterCommand("group", { "user", "admin" }, function(xPlayer, _, _)
    ESX.Trace(("%s, You are currently: ^5%s^0"):format(xPlayer.getName(), xPlayer.getGroup()), "info", true)
end, true)

ESX.RegisterCommand("job", { "user", "admin" }, function(xPlayer, _, _)
    ESX.Trace(("%s, You are currently: ^5%s^0 - ^5%s^0 (^5%s-Duty^0)"):format(xPlayer.getName(), xPlayer.getJob().name, xPlayer.getJob().grade_label, xPlayer.getDuty() and "On" or "Off"), "info", true)
end, true)

ESX.RegisterCommand("info", { "user", "admin" }, function(xPlayer, _, _)
    ESX.Trace(("^2ID: ^5%s^0 | ^2CID: ^5%s^0 | ^2Name: ^5%s^0 | ^2Group: ^5%s^0 | ^2Job: ^5%s^0"):format(xPlayer.source, xPlayer.cid, xPlayer.getName(), xPlayer.getGroup(), xPlayer.getJob().name), "info", true)
end, true)

ESX.RegisterCommand("coords", "admin", function(xPlayer, _, _)
    local coords = xPlayer.getCoords()

    ESX.Trace(("Coords - Vector3: ^5%s^0"):format(vector3(coords.x, coords.y, coords.z)), "info", true)
    ESX.Trace(("Coords - Vector4: ^5%s^0"):format(vector4(coords.x, coords.y, coords.z, coords.heading)), "info", true)
end, true)

ESX.RegisterCommand("tpm", "admin", function(xPlayer, _, _)
    xPlayer.triggerEvent("esx:tpm")
end, true)

ESX.RegisterCommand("goto", "admin", function(xPlayer, args, _)
    local targetCoords = args.playerId.getCoords()
    xPlayer.setCoords(targetCoords)
end, true, {
    help = _U("command_goto"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
    }
})

ESX.RegisterCommand("bring", "admin", function(xPlayer, args, _)
    local playerCoords = xPlayer.getCoords()
    args.playerId.setCoords(playerCoords)
end, true, {
    help = _U("command_bring"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
    }
})

ESX.RegisterCommand("kill", "admin", function(_, args, _)
    args.playerId.triggerSafeEvent("esx:killPlayer")
end, true, {
    help = _U("command_kill"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
    }
})

ESX.RegisterCommand("freeze", "admin", function(_, args, _)
    args.playerId.triggerSafeEvent("esx:freezePlayer", { state = "freeze" })
end, true, {
    help = _U("command_freeze"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
    }
})

ESX.RegisterCommand("unfreeze", "admin", function(_, args, _)
    args.playerId.triggerSafeEvent("esx:freezePlayer", { state = "unfreeze" })
end, true, {
    help = _U("command_unfreeze"),
    validate = true,
    arguments = {
        { name = "playerId", help = _U("commandgeneric_playerid"), type = "player" }
    }
})

ESX.RegisterCommand("noclip", "admin", function(xPlayer, _, _)
    xPlayer.triggerEvent("esx:noclip")
end, false)

ESX.RegisterCommand("players", "admin", function(_, _, _)
    local xPlayers = ESX.GetExtendedPlayers()
    local xPlayersCount = #xPlayers

    ESX.Trace(("^5%s^2 Online Player(s)^0"):format(xPlayersCount), "info", true)

    for i = 1, xPlayersCount do
        local xPlayer = xPlayers[i]

        ESX.Trace(("\n[^2ID: ^5%s^0 | ^2Name: ^5%s^0 | ^2Group: ^5%s^0 | ^2Job: ^5%s^0]"):format(xPlayer.source, xPlayer.getName(), xPlayer.getGroup(), xPlayer.getJob().name), "info", true)
    end
end, true)

if Config.EnableDebug then
    ESX.RegisterCommand("parsevehicles", "superadmin", function(xPlayer, args, _)
        local toBoolean = { ["false"] = false, ["true"] = true }
        args.processAll = args.processAll ~= nil and toBoolean[args.processAll:lower()]

        ---@type table<string, VehicleData>, TopVehicleStats
        local vehicleData, topStats = lib.callback.await("esx:generateVehicleData", xPlayer.source, args.processAll)

        if vehicleData and next(vehicleData) then
            if not args.processAll then
                for k, v in pairs(ESX.GetVehicleData()) do
                    vehicleData[k] = v
                end
            end

            local topVehicleStats = ESX.GetTopVehicleStats() or {}

            if topVehicleStats then
                for vtype, data in pairs(topVehicleStats) do
                    if not topStats[vtype] then topStats[vtype] = {} end

                    for stat, value in pairs(data) do
                        local newValue = topStats[vtype][stat]

                        if newValue and newValue > value then
                            topVehicleStats[vtype][stat] = newValue
                        end
                    end
                end
            end

            SaveResourceFile(cache.resource, "files/topVehicleStats.json", json.encode(topVehicleStats, {
                indent = true, sort_keys = true, indent_count = 4
            }), -1)

            SaveResourceFile(cache.resource, "files/vehicles.json", json.encode(vehicleData, {
                indent = true, sort_keys = true, indent_count = 4
            }), -1)
        end
    end, false, {
        help = "Generate and save vehicle data for available models on the client",
        validate = false,
        arguments = {
            { name = "processAll", help = "Include vehicles with existing data (in the event of updated vehicle stats)", type = "string" }
        }
    })
end
