---@param eventName string
---@param cb? function
---@param ... any
---@return any?
ESX.TriggerServerCallback = function(eventName, cb, ...)
    return (cb and lib.callback(eventName, false, cb, ...)) or (not cb and lib.callback.await(eventName, false, ...))
end

---@param eventName string
---@param cb function
ESX.RegisterClientCallback = function(eventName, cb)
    return lib.callback.register(eventName, cb)
end
