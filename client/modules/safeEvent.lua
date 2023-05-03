---@diagnostic disable: duplicate-set-field
local currentResourceName = GetCurrentResourceName()
local registeredEvents = {}

---@param eventName string
---@param cb function
function ESX.RegisterSafeEvent(eventName, cb)
    if type(eventName) ~= "string" then
        return print(("[^1ERROR^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is not a valid string!"):format(eventName))
    end

    local invokingResource = GetInvokingResource() or GetCurrentResourceName()
    local cbType = type(cb)
    local isCbValid = (cbType == "function" or (cbType == "table" and cb?.__cfx_functionReference and true)) or false

    if not cb then
        return print(("[^1ERROR^7] No callback function has passed in ^4ESX.RegisterEvent^7 for (^3%s^7) within ^3%s^7"):format(eventName, invokingResource))
    end

    if not isCbValid then
        return print(("[^1ERROR^7] The callback function passed in ^4ESX.RegisterEvent^7 for (^3%s^7) within ^3%s^7 is not a valid function!"):format(eventName, invokingResource))
    end

    local originalCb = invokingResource == currentResourceName and cb

    if registeredEvents[eventName] then
        originalCb = registeredEvents[eventName].originalCallback
        RemoveStateBagChangeHandler(registeredEvents[eventName].cookie)
        print(("[^5INFO^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is being re-registered from ^2%s^7 to ^2%s^7!"):format(eventName, registeredEvents[eventName].resource, invokingResource))
    end

    registeredEvents[eventName] = {
        cookie = AddStateBagChangeHandler(("player:%s->%s"):format(cache.serverId, eventName), "global", function(_, _, value, _, _)
            if not value then return end

            if value._client ~= false then
                cb(value)
            end
        end),
        originalCallback = originalCb,
        resource = invokingResource
    }
end

local function onResourceStop(resource)
    if resource == currentResourceName then return end

    for eventName, data in pairs(registeredEvents) do
        if data.resource == resource then
            if data.originalCallback then
                ESX.RegisterSafeEvent(eventName, data.originalCallback)
            else
                registeredEvents[eventName] = nil
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)
