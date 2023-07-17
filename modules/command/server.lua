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
