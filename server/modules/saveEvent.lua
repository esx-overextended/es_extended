---@diagnostic disable: duplicate-set-field
local pattern = "([^%-]*)%-" -- pattern to find the first occurence of a hyphen
local MAX_HASH_ID, currentHashId = 65535, 0
local currentResourceName = GetCurrentResourceName()
local registeredEvents = {}

local function generateHash()
    currentHashId = currentHashId < MAX_HASH_ID and currentHashId + 1 or 0
    return currentHashId
end

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(nil, "global", function(_, key, value, _, _)
    if not value then return end

    local bagName = string.match(key, pattern)
    local playerId = bagName and tonumber(bagName:gsub("player:", ""), 10)

    if not playerId then return end

    local notEvent = bagName .. "->"
    local notEventLength = #notEvent
    -- local eventName = key:gsub(notEvent:gsub("([%-%%])", "%%%1"), "")

    if string.sub(key, 1, notEventLength) == notEvent then
        if value._server ~= false then
            local eventName = string.sub(key, notEventLength + 1)

            if registeredEvents[eventName] then
                if registeredEvents[eventName].callback then registeredEvents[eventName].callback(value) end
            else
                print(("[^1ERROR^7] The event (^3%s^7) passed in ^4ESX.TriggerSafeEventForPlayer^7 is not registered!"):format(eventName))
            end
        end
    else
        print(("[^1ERROR^7] Mulfunctioned GlobalState bag ^4name^7 (^2%s^7) received for triggering safe event!"):format(key))
    end

    GlobalState:set(key, nil, true)
end)

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
        print(("[^5INFO^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is being re-registered from ^2%s^7 to ^2%s^7!"):format(eventName, registeredEvents[eventName].resource, invokingResource))
    end

    registeredEvents[eventName] = {
        originalCallback = originalCb,
        callback = cb,
        resource = invokingResource
    }
end

---@class CEventOptions
---@field client? boolean whether should call the client event (defaults to true)
---@field server? boolean whether should call the server event (defaults to true)

---@param source integer
---@param eventName string
---@param eventData table
---@param eventOptions? CEventOptions
function ESX.TriggerSafeEventForPlayer(source, eventName, eventData, eventOptions)
    if not source or not eventName or not eventData then return end

    source = tonumber(source) --[[@as number]]
    source = source and math.floor(source)

    if not source or source <= 0 then return print("[^1ERROR^7] The source passed in ^4ESX.TriggerSafeEventForPlayer^7 must be a valid player id!") end

    if type(eventName) ~= "string" then
        return print(("[^1ERROR^7] The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is not a valid string!"):format(eventName))
    end

    -- if not registeredEvents[eventName] then return print(("[^1ERROR^7] The event (^3%s^7) passed in ^4ESX.TriggerSafeEventForPlayer^7 is not registered!"):format(eventName)) end

    eventData.source  = source
    eventData._server = eventOptions?.server == nil and true or eventOptions?.server
    eventData._client = eventOptions?.client == nil and true or eventOptions?.client
    eventData._hash   = generateHash() -- to make sure the eventData is unique & different everytime calling GlobalState, because if it isn't, the change handlers won't be triggered

    GlobalState:set(("player:%s->%s"):format(source, eventName), eventData, true)
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
AddEventHandler("onServerResourceStop", onResourceStop)