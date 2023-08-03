local requestId = 0
local serverRequests = {}
local clientCallbacks = {}

---@param eventName string
---@param cb? any
---@param ... any
---@return ...
function ESX.TriggerServerCallback(eventName, cb, ...)
    requestId += 1
    local _requestId = requestId
    local typeCb = type(cb)
    local isCbFunction = typeCb == "function" or (typeCb == "table" and cb?.__cfx_functionReference and true)
    local _promise = not (isCbFunction) and promise.new()
    local args = { ... }

    if _promise then
        table.insert(args, 1, cb)
    end

    TriggerServerEvent("esx:triggerServerCallback", eventName, _requestId, GetInvokingResource() or cache.resource, table.unpack(args))

    serverRequests[_requestId] = function(...)
        serverRequests[_requestId] = nil

        if isCbFunction then
            cb(...)
        elseif _promise then
            _promise:resolve({ ... })
        end
    end

    if _promise then
        return table.unpack(Citizen.Await(_promise))
    end
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

RegisterNetEvent("esx:triggerClientCallback", function(eventName, receivedRequestId, invoker, ...)
    if not clientCallbacks[eventName] then
        return ESX.Trace(("Client callback not registered, name: ^5%s^7, invoker resource: ^5%s^7"):format(eventName, invoker), "error", true)
    end

    clientCallbacks[eventName](function(...)
        TriggerServerEvent("esx:clientCallback", receivedRequestId, invoker, ...)
    end, ...)
end)
