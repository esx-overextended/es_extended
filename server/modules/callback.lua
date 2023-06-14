local serverCallbacks = {}
local cbEvent = ("__ox_cb_%s")

---@param eventName string
---@param cb function
ESX.RegisterServerCallback = function(eventName, cb)
    serverCallbacks[eventName] = cb

    RegisterNetEvent(cbEvent:format(eventName), function(resource, key, ...)
        if not serverCallbacks[eventName] then
            return print(("[^1ERROR^7] Server Callback not registered, name: ^5%s^7, invoker resource: ^5%s^7"):format(eventName, resource))
        end

        local source = source

        serverCallbacks[eventName](source, function(...)
            TriggerClientEvent(cbEvent:format(resource), source, key, ...)
        end, ...)
    end)
end

---@param source playerId
---@param eventName string
---@param cb function
---@param ... any
ESX.TriggerClientCallback = function(source, eventName, cb, ...)
    return lib.callback(eventName, source, cb, ...)
end
