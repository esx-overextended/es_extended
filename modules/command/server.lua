---@class CRegisteredCommand
---@field group string | string[]
---@field cb function
---@field allowConsole boolean
---@field suggestion table

---@type table<string, CRegisteredCommand>
Core.RegisteredCommands = {}

---Triggers a registered command based on the passed parameters
---@param commandName string
---@param playerId? number
---@param args table
local function triggerCommand(commandName, playerId, args)
    local command = Core.RegisteredCommands[commandName]

    if not command then return ESX.Trace(("Tried to trigger command (^1%s^7) but it is not registered!"):format(commandName), "error", true) end

    local hasPlayerId = playerId and playerId ~= 0 or playerId ~= ""

    if not command.allowConsole and not hasPlayerId then return ESX.Trace(("^5%s"):format(_U("commanderror_console")), "warning", true) end

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
        if not hasPlayerId then
            ESX.Trace(("%s^7"):format(error), "warning", true)
        else
            xPlayer.showNotification(error)
        end
    else
        command.cb(xPlayer or false, args, function(msg)
            if not hasPlayerId then
                ESX.Trace(("%s^7"):format(msg), "warning", true)
            else
                xPlayer.showNotification(msg)
            end
        end)
    end
end

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
        triggerCommand(name, playerId, args)
    end, true)

    if type(group) == "table" then
        for _, v in ipairs(group) do
            lib.addAce(("group.%s"):format(v), ("command.%s"):format(name), true)
        end
    else
        lib.addAce(("group.%s"):format(group), ("command.%s"):format(name), true)
    end
end

AddEventHandler("esx:triggerCommand", triggerCommand)

do
    Core.ResourceExport:registerHook("onPlayerLoad", function(payload)
        local xPlayer = payload?.xPlayer and ESX.Players[payload.xPlayer?.source]

        if not xPlayer then return ESX.Trace("Unexpected behavior from onPlayerLoad hook in modules/command/server.lua", "error", true) end

        xPlayer.triggerSafeEvent("esx:registerSuggestions", { registeredCommands = Core.RegisteredCommands })
    end)
end
