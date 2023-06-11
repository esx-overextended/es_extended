function ESX.Trace(msg)
    if Config.EnableDebug then
        print(('[^2TRACE^7] %s^7'):format(msg))
    end
end

function ESX.RegisterCommand(name, group, cb, allowConsole, suggestion)
    if type(name) == 'table' then
        for _, v in ipairs(name) do
            ESX.RegisterCommand(v, group, cb, allowConsole, suggestion)
        end

        return
    end

    if Core.RegisteredCommands[name] then
        print(('[^3WARNING^7] Command ^5"%s" ^7already registered, overriding command'):format(name))

        if Core.RegisteredCommands[name].suggestion then
            TriggerClientEvent('chat:removeSuggestion', -1, ('/%s'):format(name))
        end
    end

    if suggestion then
        if not suggestion.arguments then
            suggestion.arguments = {}
        end
        if not suggestion.help then
            suggestion.help = ''
        end

        TriggerClientEvent('chat:addSuggestion', -1, ('/%s'):format(name), suggestion.help, suggestion.arguments)
    end

    Core.RegisteredCommands[name] = { group = group, cb = cb, allowConsole = allowConsole, suggestion = suggestion }

    RegisterCommand(name, function(playerId, args, _)
        local command = Core.RegisteredCommands[name]

        if not command.allowConsole and playerId == 0 then
            print(('[^3WARNING^7] ^5%s'):format(_U('commanderror_console')))
        else
            local xPlayer, error = ESX.Players[playerId], nil

            if command.suggestion then
                if command.suggestion.validate then
                    if #args ~= #command.suggestion.arguments then
                        error = _U('commanderror_argumentmismatch', #args, #command.suggestion.arguments)
                    end
                end

                if not error and command.suggestion.arguments then
                    local newArgs = {}

                    for k, v in ipairs(command.suggestion.arguments) do
                        if v.type then
                            if v.type == 'number' then
                                local newArg = tonumber(args[k])

                                if newArg then
                                    newArgs[v.name] = newArg
                                else
                                    error = _U('commanderror_argumentmismatch_number', k)
                                end
                            elseif v.type == 'player' or v.type == 'playerId' then
                                local targetPlayer = tonumber(args[k])

                                if args[k] == 'me' then
                                    targetPlayer = playerId
                                end

                                if targetPlayer then
                                    local xTargetPlayer = ESX.GetPlayerFromId(targetPlayer)

                                    if xTargetPlayer then
                                        if v.type == 'player' then
                                            newArgs[v.name] = xTargetPlayer
                                        else
                                            newArgs[v.name] = targetPlayer
                                        end
                                    else
                                        error = _U('commanderror_invalidplayerid')
                                    end
                                else
                                    error = _U('commanderror_argumentmismatch_number', k)
                                end
                            elseif v.type == 'string' then
                                newArgs[v.name] = args[k]
                            elseif v.type == 'item' then
                                if ESX.Items[args[k]] then
                                    newArgs[v.name] = args[k]
                                else
                                    error = _U('commanderror_invaliditem')
                                end
                            elseif v.type == 'weapon' then
                                if ESX.GetWeapon(args[k]) then
                                    newArgs[v.name] = string.upper(args[k])
                                else
                                    error = _U('commanderror_invalidweapon')
                                end
                            elseif v.type == 'any' then
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
                    print(('[^3WARNING^7] %s^7'):format(error))
                else
                    xPlayer.showNotification(error)
                end
            else
                cb(xPlayer or false, args, function(msg)
                    if playerId == 0 then
                        print(('[^3WARNING^7] %s^7'):format(msg))
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

function Core.SavePlayer(xPlayer, cb)
    local queries = {
        {
            query = "UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `job_duty` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ?, `metadata` = ? WHERE `identifier` = ?",
            values = {
                json.encode(xPlayer.getAccounts(true)),
                xPlayer.job.name,
                xPlayer.job.grade,
                xPlayer.job.duty,
                xPlayer.group,
                json.encode(xPlayer.getCoords()),
                json.encode(xPlayer.getInventory(true)),
                json.encode(xPlayer.getLoadout(true)),
                json.encode(xPlayer.getMetadata()),
                xPlayer.identifier
            }
        },
        {
            query = "DELETE FROM `user_groups` WHERE `identifier` = ? AND `name` <> ?",
            values = {xPlayer.identifier, xPlayer.group}
        }
    }

    for groupName, groupGrade in pairs(xPlayer.groups) do
        if groupName ~= xPlayer.group then
            queries[#queries+1] = {
                query = "INSERT INTO `user_groups` (identifier, name, grade) VALUES (?, ?, ?)",
                values = {xPlayer.identifier, groupName, groupGrade}
            }
        end
    end

    MySQL.transaction(queries, function(success)
        print((success and "[^2INFO^7] Saved player ^5'%s'^7" or "[^1ERROR^7] Error in saving player ^5'%s'^7"):format(xPlayer.name))

        if success then TriggerEvent("esx:playerSaved", xPlayer.source, xPlayer) end

        return type(cb) == "function" and cb(success)
    end)
end

function Core.SavePlayers(cb)
    local xPlayers <const> = ESX.Players

    if not next(xPlayers) then return end

    local startTime <const> = os.time()

    local queries, count = {}, 0
    local playerCounts = 0

    for _, xPlayer in pairs(xPlayers) do
        count += 1
        queries[count] = {
            query = "UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `job_duty` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ?, `metadata` = ? WHERE `identifier` = ?",
            values = {
                json.encode(xPlayer.getAccounts(true)),
                xPlayer.job.name,
                xPlayer.job.grade,
                xPlayer.job.duty,
                xPlayer.group,
                json.encode(xPlayer.getCoords()),
                json.encode(xPlayer.getInventory(true)),
                json.encode(xPlayer.getLoadout(true)),
                json.encode(xPlayer.getMetadata()),
                xPlayer.identifier
            }
        }

        count += 1
        queries[count] = {
            query = "DELETE FROM `user_groups` WHERE `identifier` = ? AND `name` <> ?",
            values = {xPlayer.identifier, xPlayer.group}
        }

        for groupName, groupGrade in pairs(xPlayer.groups) do
            if groupName ~= xPlayer.group then
                count += 1
                queries[count] = {
                    query = "INSERT INTO `user_groups` (identifier, name, grade) VALUES (?, ?, ?)",
                    values = {xPlayer.identifier, groupName, groupGrade}
                }
            end
        end

        playerCounts += 1
    end

    MySQL.transaction(queries, function(success)
        print((success and "[^2INFO^7] Saved ^5%s^7 %s over ^5%s^7 ms" or "[^1ERROR^7] Failed to save ^5%s^7 %s over ^5%s^7 ms"):format(playerCounts, playerCounts > 1 and "players" or "player", ESX.Math.Round((os.time() - startTime) / 1000000, 2)))

        return type(cb) == "function" and cb(success)
    end)
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
            if (xVehicle.owner or xVehicle.group) ~= false then -- TODO: might need to remove this check as I think it's handled through xVehicle.delete()
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

---Returns instance of xPlayers
---@param key? string
---@param value? any
---@return xPlayer[], integer | number
function ESX.GetExtendedPlayers(key, value)
    local xPlayers = {}
    local count = 0

    for _, xPlayer in pairs(ESX.Players) do
        if key then
            if (key == "job" and xPlayer.job.name == value) or (key == "group" and xPlayer.groups[value]) or xPlayer[key] == value then
                count += 1
                xPlayers[count] = xPlayer
            end
        else
            count += 1
            xPlayers[count] = xPlayer
        end
    end

    return xPlayers, count
end

---@diagnostic disable-next-line: duplicate-set-field
function ESX.GetPlayerFromId(source)
    return ESX.Players[tonumber(source)]
end

function ESX.GetPlayerFromIdentifier(identifier)
    return Core.PlayersByIdentifier[identifier]
end

---Gets a player id rockstar's license identifier without 'license:' prefix
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

---@param model string | number
---@param _? number playerId (not used anymore)
---@param cb? function
---@return string?
function ESX.GetVehicleType(model, _, cb) ---@diagnostic disable-line: duplicate-set-field
    local typeModel = type(model)

    if typeModel ~= "string" and typeModel ~= "number" then
        print(("[^1ERROR^7] Invalid type of model (^1%s^7) in ^5ESX.GetVehicleType^7!"):format(typeModel)) return
    end

    if typeModel == "number" or type(tonumber(model)) == "number" then
        typeModel = "number"
        model = tonumber(model) --[[@as number]]

        for vModel, vData in pairs(ESX.GetVehicleData()) do
            if vData.hash == model then
                model = vModel
                break
            end
        end
    end

    model = typeModel == "string" and model:lower() or model --[[@as string]]
    local modelData = ESX.GetVehicleData(model) --[[@as VehicleData]]

    if not modelData then
        print(("[^1ERROR^7] Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(model))
    end

    return cb and cb(modelData?.type) or modelData?.type
end

function ESX.DiscordLog(name, title, color, message)
    local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
    local embedData = { {
        ['title'] = title,
        ['color'] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
        ['footer'] = {
            ['text'] = "| ESX Logs | " .. os.date(),
            ['icon_url'] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
        },
        ['description'] = message,
        ['author'] = {
            ['name'] = "ESX Framework",
            ['icon_url'] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
        }
    } }
    ---@diagnostic disable-next-line: param-type-mismatch
    PerformHttpRequest(webHook, nil, 'POST', json.encode({
        username = 'Logs',
        embeds = embedData
    }), {
        ['Content-Type'] = 'application/json'
    })
end

function ESX.DiscordLogFields(name, title, color, fields)
    local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
    local embedData = { {
        ['title'] = title,
        ['color'] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
        ['footer'] = {
            ['text'] = "| ESX Logs | " .. os.date(),
            ['icon_url'] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
        },
        ['fields'] = fields,
        ['description'] = "",
        ['author'] = {
            ['name'] = "ESX Framework",
            ['icon_url'] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
        }
    } }
    ---@diagnostic disable-next-line: param-type-mismatch
    PerformHttpRequest(webHook, nil, 'POST', json.encode({
        username = 'Logs',
        embeds = embedData
    }), {
        ['Content-Type'] = 'application/json'
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
                return result and print(result) or
                    print(('[^3WARNING^7] An error occured when using item ^5"%s"^7! This was not caused by ESX.'):format(item))
            end
        end
    else
        print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(item))
    end
end

function ESX.RegisterPlayerFunctionOverrides(index, overrides)
    Core.PlayerFunctionOverrides[index] = overrides
end

function ESX.SetPlayerFunctionOverride(index)
    if not index or not Core.PlayerFunctionOverrides[index] then
        return print('[^3WARNING^7] No valid index provided.')
    end

    Config.PlayerFunctionOverride = index
end

function ESX.GetItemLabel(item)
    if Config.OxInventory then
        item = exports.ox_inventory:Items(item)
        if item then
            return item.label
        end
    end

    if ESX.Items[item] then
        return ESX.Items[item].label
    else
        print('[^3WARNING^7] Attemting to get invalid Item -> ^5' .. item .. "^7")
    end
end

function ESX.GetUsableItems()
    local Usables = {}
    for k in pairs(Core.UsableItemsCallbacks) do
        Usables[k] = true
    end
    return Usables
end

if not Config.OxInventory then
    function ESX.CreatePickup(type, name, count, label, playerId, components, tintIndex)
        local pickupId = (Core.PickupId == 65635 and 0 or Core.PickupId + 1)
        local xPlayer = ESX.Players[playerId]
        local coords = xPlayer.getCoords()

        Core.Pickups[pickupId] = { type = type, name = name, count = count, label = label, coords = coords }

        if type == 'item_weapon' then
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

        if IsPlayerAceAllowed(playerId, ESX.Groups[groupName].principal) then
            group = groupName
            break
        end
    end

    return group
end
