local requestId = 0
local clientRequests = {}
local serverCallbacks = {}

---@param playerId number
---@param eventName string
---@param cb? any
---@param ... any
---@return ...
function ESX.TriggerClientCallback(playerId, eventName, cb, ...)
    requestId += 1
    local _requestId = requestId
    local typeCb = type(cb)
    local isCbFunction = typeCb == "function" or (typeCb == "table" and cb?.__cfx_functionReference and true)
    local _promise = not (isCbFunction) and promise.new()
    local args = { ... }

    if _promise then
        table.insert(args, 1, cb)
    end

    TriggerClientEvent("esx:triggerClientCallback", playerId, eventName, _requestId, GetInvokingResource() or cache.resource, table.unpack(args))

    clientRequests[_requestId] = function(...)
        clientRequests[_requestId] = nil

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

RegisterServerEvent("esx:clientCallback", function(receivedRequestId, invoker, ...)
    local callback = clientRequests[receivedRequestId] --[[@as function]]

    if not callback then
        return ESX.Trace(("Client callback with receivedRequestId ^5%s^7 was called by ^5%s^7 but does not exist."):format(receivedRequestId, invoker), "error", true)
    end

    callback(...)
end)

---@param eventName string
---@param callback function
function ESX.RegisterServerCallback(eventName, callback)
    serverCallbacks[eventName] = callback
end

RegisterServerEvent("esx:triggerServerCallback", function(eventName, receivedRequestId, invoker, ...)
    if not serverCallbacks[eventName] then
        return ESX.Trace(("Server callback not registered, name: ^5%s^7, invoker resource: ^5%s^7"):format(eventName, invoker), "error", true)
    end

    local _source = source

    serverCallbacks[eventName](_source, function(...)
        TriggerClientEvent("esx:serverCallback", _source, receivedRequestId, invoker, ...)
    end, ...)
end)
