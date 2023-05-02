---@diagnostic disable: duplicate-set-field
local registeredEvents = {}

---@param eventName string
---@param cb function
function ESX.RegisterSafeEvent(eventName, cb)
    if type(eventName) ~= "string" then
        return print(("[^1ERROR^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is not a valid string!"):format(eventName))
    end

    if type(cb) ~= "function" then
        return print(("[^1ERROR^7] The cb passed in ^4ESX.RegisterEvent^7 for (^3%s^7) is not a valid function!"):format(eventName))
    end

    local invokingResource = GetInvokingResource()

    if registeredEvents[eventName] then
        RemoveStateBagChangeHandler(registeredEvents[eventName].cookie)
        print(("[^5INFO^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is being re-registered from ^2%s^7 to ^2%s^7!"):format(eventName, registeredEvents[eventName].resource, invokingResource))
    end

    registeredEvents[eventName] = {
        cookie = AddStateBagChangeHandler(("player:%s->%s"):format(cache.serverId, eventName), "global", function(_, _, value, _, _)
            if not value then return end

            if value.client ~= false then
                cb(value)
            end
        end),
        resource = invokingResource
    }
end

local function onResourceStop(resource)
    for eventName, data in pairs(registeredEvents) do
        if data.resource == resource then
            RemoveStateBagChangeHandler(registeredEvents[eventName].cookie)
            registeredEvents[eventName] = nil
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)
