function ESX.RegisterCommand(name, group, cb, allowConsole, suggestion)
    if type(name) == "table" then
        for _, v in ipairs(name) do
            ESX.RegisterCommand(v, group, cb, allowConsole, suggestion)
        end

        return
    end

    if Core.RegisteredCommands[name] then
        ESX.Trace(("Command ^5'%s'^7 already registered, overriding command"):format(name), "info", true)

        if Core.RegisteredCommands[name].suggestion then
            TriggerClientEvent("chat:removeSuggestion", -1, ("/%s"):format(name))
        end
    end

    if suggestion then
        if not suggestion.arguments then
            suggestion.arguments = {}
        end

        if not suggestion.help then
            suggestion.help = ""
        end

        TriggerClientEvent("chat:addSuggestion", -1, ("/%s"):format(name), suggestion.help, suggestion.arguments)
    end

    Core.RegisteredCommands[name] = { group = group, cb = cb, allowConsole = allowConsole, suggestion = suggestion }

    RegisterCommand(name, function(playerId, args, _)
        local command = Core.RegisteredCommands[name]

        if not command.allowConsole and playerId == 0 then
            ESX.Trace(("^5%s"):format(_U("commanderror_console")), "warning", true)
        else
            local xPlayer, error = ESX.Players[playerId], nil

            if command.suggestion then
                if command.suggestion.validate then
                    if #args ~= #command.suggestion.arguments then
                        error = _U("commanderror_argumentmismatch", #args, #command.suggestion.arguments)
                    end
                end

                if not error and command.suggestion.arguments then
                    local newArgs = {}

                    for k, v in ipairs(command.suggestion.arguments) do
                        if v.type then
                            if v.type == "number" then
                                local newArg = tonumber(args[k])

                                if newArg then
                                    newArgs[v.name] = newArg
                                else
                                    error = _U("commanderror_argumentmismatch_number", k)
                                end
                            elseif v.type == "player" or v.type == "playerId" then
                                local targetPlayer = tonumber(args[k])

                                if args[k] == "me" then
                                    targetPlayer = playerId
                                end

                                if targetPlayer then
                                    ---@cast targetPlayer number
                                    local xTargetPlayer = ESX.Players[targetPlayer]

                                    if xTargetPlayer then
                                        newArgs[v.name] = v.type == "player" and xTargetPlayer or targetPlayer
                                    else
                                        error = _U("commanderror_invalidplayerid")
                                    end
                                else
                                    error = _U("commanderror_argumentmismatch_number", k)
                                end
                            elseif v.type == "string" then
                                newArgs[v.name] = args[k]
                            elseif v.type == "item" then
                                if ESX.Items[args[k]] then
                                    newArgs[v.name] = args[k]
                                else
                                    error = _U("commanderror_invaliditem")
                                end
                            elseif v.type == "weapon" then
                                if ESX.GetWeapon(args[k]) then
                                    newArgs[v.name] = string.upper(args[k])
                                else
                                    error = _U("commanderror_invalidweapon")
                                end
                            elseif v.type == "any" then
                                newArgs[v.name] = args[k]
                            end
                        end

                        if not v.validate then
                            error = nil
                        end

                        if error then
                            break
                        end
                    end

                    args = newArgs
                end
            end

            if error then
                if playerId == 0 then
                    ESX.Trace(("%s^7"):format(error), "warning", true)
                else
                    xPlayer.showNotification(error)
                end
            else
                cb(xPlayer or false, args, function(msg)
                    if playerId == 0 then
                        ESX.Trace(("%s^7"):format(msg), "warning", true)
                    else
                        xPlayer.showNotification(msg)
                    end
                end)
            end
        end
    end, true)

    if type(group) == "table" then
        for _, v in ipairs(group) do
            lib.addAce(("group.%s"):format(v), ("command.%s"):format(name), true)
        end
    else
        lib.addAce(("group.%s"):format(group), ("command.%s"):format(name), true)
    end
end

---Saves all vehicles for the resource and despawns them
---@param resource string?
function Core.SaveVehicles(resource)
    local parameters, pSize = {}, 0
    local vehicles, vSize = {}, 0

    if not next(Core.Vehicles) then return end

    if resource == cache.resource then resource = nil end

    for _, xVehicle in pairs(Core.Vehicles) do
        if not resource or resource == xVehicle.script then
            if (xVehicle.owner or xVehicle.group) ~= false then -- TODO: might need to remove this check as I think it"s handled through xVehicle.delete()
                pSize += 1
                parameters[pSize] = { xVehicle.stored, json.encode(xVehicle.metadata), xVehicle.id }
            end

            vSize += 1
            vehicles[vSize] = xVehicle.entity
        end
    end

    if vSize > 0 then
        ESX.DeleteVehicle(vehicles)
    end

    if pSize > 0 then
        MySQL.prepare("UPDATE `owned_vehicles` SET `stored` = ?, `metadata` = ? WHERE `id` = ?", parameters)
    end
end

ESX.GetPlayers = GetPlayers

---Gets a player id rockstar"s license identifier without "license:" prefix
---@param playerId integer
---@return string | nil
function ESX.GetIdentifier(playerId)
    if Config.EnableDebug or GetConvarInt("sv_fxdkMode", 0) == 1 then
        return ("ESX-DEBUG-LICENSE%s"):format(playerId and ("-ID(%s)"):format(playerId) or "")
    end

    local identifier = nil

    for _, v in ipairs(GetPlayerIdentifiers(playerId)) do
        if string.match(v, "license:") then
            identifier = string.gsub(v, "license:", "")
            break
        end
    end

    return identifier
end

function ESX.DiscordLog(name, title, color, message)
    local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
    local embedData = { {
        ["title"] = title,
        ["color"] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
        ["footer"] = {
            ["text"] = "| ESX Logs | " .. os.date(),
            ["icon_url"] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
        },
        ["description"] = message,
        ["author"] = {
            ["name"] = "ESX Framework",
            ["icon_url"] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
        }
    } }
    ---@diagnostic disable-next-line: param-type-mismatch
    PerformHttpRequest(webHook, nil, "POST", json.encode({
        username = "Logs",
        embeds = embedData
    }), {
        ["Content-Type"] = "application/json"
    })
end

function ESX.DiscordLogFields(name, title, color, fields)
    local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
    local embedData = { {
        ["title"] = title,
        ["color"] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
        ["footer"] = {
            ["text"] = "| ESX Logs | " .. os.date(),
            ["icon_url"] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
        },
        ["fields"] = fields,
        ["description"] = "",
        ["author"] = {
            ["name"] = "ESX Framework",
            ["icon_url"] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
        }
    } }
    ---@diagnostic disable-next-line: param-type-mismatch
    PerformHttpRequest(webHook, nil, "POST", json.encode({
        username = "Logs",
        embeds = embedData
    }), {
        ["Content-Type"] = "application/json"
    })
end

function ESX.RegisterUsableItem(item, cb)
    Core.UsableItemsCallbacks[item] = cb
end

function ESX.UseItem(source, item, ...)
    if ESX.Items[item] then
        local itemCallback = Core.UsableItemsCallbacks[item]

        if itemCallback then
            local success, result = pcall(itemCallback, source, item, ...)

            if not success then
                return ESX.Trace(result and result or ("An error occured when using item ^5'%s'^7! This was not caused by ESX."):format(item), result and "error" or "warning", true)
            end
        end
    else
        ESX.Trace(("Item ^5'%s'^7 was used but does not exist!"):format(item), "warning", true)
    end
end

function ESX.GetItemLabel(item)
    if Config.OxInventory then
        item = exports.ox_inventory:Items(item)
        if item then
            return item.label
        end
    end

    if not ESX.Items[item] then
        return ESX.Trace(("Attemting to get invalid Item -> ^5%s^7"):format(item), "warning", true)
    end

    return ESX.Items[item].label
end

function ESX.GetUsableItems()
    local usables = {}

    for k in pairs(Core.UsableItemsCallbacks) do
        usables[k] = true
    end

    return usables
end

if not Config.OxInventory then
    function ESX.CreatePickup(type, name, count, label, playerId, components, tintIndex)
        local pickupId = (Core.PickupId == 65635 and 0 or Core.PickupId + 1)
        local xPlayer = ESX.Players[playerId]
        local coords = xPlayer.getCoords()

        Core.Pickups[pickupId] = { type = type, name = name, count = count, label = label, coords = coords }

        if type == "item_weapon" then
            Core.Pickups[pickupId].components = components
            Core.Pickups[pickupId].tintIndex = tintIndex
        end

        ESX.TriggerSafeEvent("esx:createPickup", -1, {
            pickupId = pickupId,
            label = label,
            coords = coords,
            type = type,
            name = name,
            components = components,
            tintIndex = tintIndex
        }, { server = false, client = true })

        Core.PickupId = pickupId
    end
end

---@param playerId integer | number | string
---@return boolean
function Core.IsPlayerAdmin(playerId)
    if (IsPlayerAceAllowed(tostring(playerId), "command") or GetConvar("sv_lan", "") == "true") and true or false then
        return true
    end

    playerId = tonumber(playerId) --[[@as number]]

    return Config.AdminGroupsByName[ESX.Players[playerId]?.group] ~= nil
end

---@param playerId integer | number | string
---@return string
function Core.GetPlayerAdminGroup(playerId)
    playerId = tostring(playerId)
    local group = Core.DefaultGroup

    for i = 1, #Config.AdminGroups do -- start from the highest perm admin group
        local groupName = Config.AdminGroups[i]

        if IsPlayerAceAllowed(playerId, Core.Groups[groupName].principal) then
            group = groupName
            break
        end
    end

    return group
end
