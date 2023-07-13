local serverCallbacks = {}

local clientRequests = {}
local RequestId = 0

---@param eventName string
---@param callback function
ESX.RegisterServerCallback = function(eventName, callback)
    serverCallbacks[eventName] = callback
end

RegisterServerEvent("esx:triggerServerCallback", function(eventName, requestId, invoker, ...)
    if not serverCallbacks[eventName] then
        return ESX.Trace(("Server callback not registered, name: ^5%s^7, invoker resource: ^5%s^7"):format(eventName, invoker), "error", true)
    end

    local source = source

    serverCallbacks[eventName](source, function(...)
        TriggerClientEvent("esx:serverCallback", source, requestId, invoker, ...)
    end, ...)
end)

---@param player number playerId
---@param eventName string
---@param callback function
---@param ... any
ESX.TriggerClientCallback = function(player, eventName, callback, ...)
    clientRequests[RequestId] = callback

    TriggerClientEvent("esx:triggerClientCallback", player, eventName, RequestId, GetInvokingResource() or "unknown", ...)

    RequestId = RequestId + 1
end

RegisterServerEvent("esx:clientCallback", function(requestId, invoker, ...)
    if not clientRequests[requestId] then
        return ESX.Trace(("Client callback with requestId ^5%s^7 was called by ^5%s^7 but does not exist."):format(requestId, invoker), "error", true)
    end

    clientRequests[requestId](...)
    clientRequests[requestId] = nil
end)
