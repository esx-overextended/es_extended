local requestId = 0
local serverRequests = {}

local clientCallbacks = {}

---@param eventName string
---@param cb? function
---@param ... any
---@return ...
local function triggerServerCallback(eventName, cb, ...)
    local _requestId = requestId
    requestId += 1

    TriggerServerEvent("esx:triggerServerCallback", eventName, _requestId, GetInvokingResource() or "unknown", ...)

    ---@type promise?
    local _promise = not cb and promise.new() or nil

    serverRequests[_requestId] = function(...)
        serverRequests[_requestId] = nil

        if cb then
            cb(...)
        elseif _promise then
            _promise:resolve({ ... })
        end
    end

    if _promise then
        return table.unpack(Citizen.Await(_promise))
    end
end

ESX.TriggerServerCallback = triggerServerCallback

---@param eventName string
---@param ... any
function ESX.AwaitTriggerServerCallback(eventName, ...)
    return triggerServerCallback(eventName, nil, ...)
end

RegisterNetEvent("esx:serverCallback", function(receivedRequestId, invoker, ...)
    local callback = serverRequests[receivedRequestId] --[[@as function]]

    if not callback then
        return ESX.Trace(("Server callback with requestId of ^5%s^7 was called by ^5%s^7 but does not exist."):format(receivedRequestId, invoker), "error", true)
    end

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
