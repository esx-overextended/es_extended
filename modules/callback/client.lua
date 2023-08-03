local requestId = 0
local serverRequests = {}

local clientCallbacks = {}

---@param eventName string
---@param callback function
---@param ... any
function ESX.TriggerServerCallback(eventName, callback, ...)
    serverRequests[requestId] = callback

    TriggerServerEvent("esx:triggerServerCallback", eventName, requestId, GetInvokingResource() or "unknown", ...)

    requestId = requestId + 1
end

---@param eventName string
---@param ... any
function ESX.AwaitTriggerServerCallback(eventName, ...)
    local _promise = promise.new()

    ESX.TriggerServerCallback(eventName, function(...)
        _promise:resolve(...)
    end, ...)

    return Citizen.Await(_promise)
end

RegisterNetEvent("esx:serverCallback", function(receivedRequestId, invoker, ...)
    local callback = serverRequests[receivedRequestId] --[[@as function]]

    if not callback then
        return ESX.Trace(("Server callback with requestId of ^5%s^7 was called by ^5%s^7 but does not exist."):format(receivedRequestId, invoker), "error", true)
    end

    serverRequests[receivedRequestId] = nil
    callback(...)
end)

---@param eventName string
---@param callback function
ESX.RegisterClientCallback = function(eventName, callback)
    clientCallbacks[eventName] = callback
end

RegisterNetEvent("esx:triggerClientCallback", function(eventName, requestId, invoker, ...)
    if not clientCallbacks[eventName] then
        return ESX.Trace(("Client callback not registered, name: ^5%s^7, invoker resource: ^5%s^7"):format(eventName, invoker), "error", true)
    end

    clientCallbacks[eventName](function(...)
        TriggerServerEvent("esx:clientCallback", requestId, invoker, ...)
    end, ...)
end)
