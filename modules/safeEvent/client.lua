if ESX.RegisterSafeEvent then return end

local currentResourceName = GetCurrentResourceName()
local registeredEvents = {}

---@param eventName string
---@param cb function
function ESX.RegisterSafeEvent(eventName, cb) ---@diagnostic disable-line: duplicate-set-field
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
        RemoveStateBagChangeHandler(registeredEvents[eventName].selfCookie)
        RemoveStateBagChangeHandler(registeredEvents[eventName].globalCookie)
        print(("[^5INFO^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is being re-registered from ^2%s^7 to ^2%s^7!"):format(eventName, registeredEvents[eventName].resource, invokingResource))
    end

    local function stateBagChangeHandler(_, _, value, _, _)
        if type(value) ~= "table" or not value?.__esx_triggerClient then return end

        cb(value)
    end

    registeredEvents[eventName] = {
        selfCookie = AddStateBagChangeHandler(("player:%s->%s"):format(cache.serverId, eventName), "global", stateBagChangeHandler),
        globalCookie = AddStateBagChangeHandler(("player:%s->%s"):format("-1", eventName), "global", stateBagChangeHandler),
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
                RemoveStateBagChangeHandler(registeredEvents[eventName].selfCookie)
                RemoveStateBagChangeHandler(registeredEvents[eventName].globalCookie)
                registeredEvents[eventName] = nil
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onClientResourceStop", onResourceStop)
