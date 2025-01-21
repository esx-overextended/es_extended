if ESX.RegisterSafeEvent then return end

local MAX_HASH_ID, currentHashId = 65535, 0
local currentResourceName = GetCurrentResourceName()
local registeredEvents = {}

local function generateHash()
    currentHashId = currentHashId < MAX_HASH_ID and currentHashId + 1 or 0
    return currentHashId
end

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(nil, "global", function(_, key, value, _, _)
    if type(value) ~= "table" or not value?.__esx_triggerServer then return end

    local bagName = string.match(key, "(.-)%s*->") -- pattern to find the first occurence of a "->"
    local playerId = bagName and tonumber(bagName:gsub("player:", ""), 10)

    if not playerId then return end

    local notEvent = bagName .. "->"
    local notEventLength = #notEvent

    if string.sub(key, 1, notEventLength) ~= notEvent then
        return ESX.Trace(("Mulfunctioned GlobalState bag ^4name^7 (^2%s^7) received for triggering safe event!"):format(key), "error", true)
    end

    local eventName = string.sub(key, notEventLength + 1)

    if not registeredEvents[eventName] then
        return ESX.Trace(("The event (^3%s^7) passed in ^4ESX.TriggerSafeEvent^7 is not registered on server!"):format(eventName), "error", true)
    end

    registeredEvents[eventName].callback(value)
end)

---@param eventName string
---@param cb function
function ESX.RegisterSafeEvent(eventName, cb) ---@diagnostic disable-line: duplicate-set-field
    if type(eventName) ~= "string" then
        return ESX.Trace(("The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is not a valid string!"):format(eventName), "error", true)
    end

    local invokingResource = GetInvokingResource() or GetCurrentResourceName()
    local cbType = type(cb)
    local isCbValid = (cbType == "function" or (cbType == "table" and cb?.__cfx_functionReference and true)) or false

    if not cb then
        return ESX.Trace(("No callback function has passed in ^4ESX.RegisterEvent^7 for (^3%s^7) within ^3%s^7"):format(eventName, invokingResource), "error", true)
    end

    if not isCbValid then
        return ESX.Trace(("The callback function passed in ^4ESX.RegisterEvent^7 for (^3%s^7) within ^3%s^7 is not a valid function!"):format(eventName, invokingResource), "error", true)
    end

    local originalCb = invokingResource == currentResourceName and cb

    if registeredEvents[eventName] then
        originalCb = registeredEvents[eventName].originalCallback
        ESX.Trace(("The event (^3%s^7) passed in ^4ESX.RegisterEvent^7 is being re-registered from ^2%s^7 to ^2%s^7!"):format(eventName, registeredEvents[eventName].resource, invokingResource), "info", true)
    end

    registeredEvents[eventName] = {
        originalCallback = originalCb,
        callback = cb,
        resource = invokingResource
    }
end

---@class CEventOptions
---@field client? boolean whether should call the client event (defaults to false)
---@field server? boolean whether should call the server event (defaults to false)

---@param eventName string
---@param source integer
---@param eventData? table<string, any>
---@param eventOptions? CEventOptions
function ESX.TriggerSafeEvent(eventName, source, eventData, eventOptions)
    if not eventName or not source then return end

    if type(eventName) ~= "string" then
        return ESX.Trace(("The event (^3%s^7) passed in ^4ESX.TriggerSafeEvent^7 is not a valid string!"):format(eventName), "error", true)
    end

    source = tonumber(source) --[[@as number]]
    source = source and math.floor(source)

    if not source or (source <= 0 and source ~= -1) then return ESX.Trace("The source passed in ^4ESX.TriggerSafeEvent^7 must be a valid player id or -1!", "error", true) end

    if eventData and type(eventData) ~= "table" then
        return ESX.Trace(("The data (^3%s^7) passed in ^4ESX.TriggerSafeEvent^7 is not a table type!"):format(eventName), "error", true)
    end

    eventData                     = eventData or {}
    eventData.source              = source
    eventData.__esx_triggerServer = eventOptions?.server == nil and false or eventOptions?.server
    eventData.__esx_triggerClient = eventOptions?.client == nil and false or eventOptions?.client
    eventData.__esx_hash          = generateHash() -- to make sure the eventData is unique & different everytime calling GlobalState, because if it isn't, the change handlers won't be triggered

    local bagName                 = ("player:%s->%s"):format(source, eventName)

    GlobalState:set(bagName, eventData, true)
    GlobalState:set(bagName, nil, true)
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

do
    ESX.RegisterPlayerMethodOverrides({
        ---Triggers a safe event for the player.
        ---@param self xPlayer
        triggerSafeEvent = function(self)
            ---@param eventName string -- name of the safe event
            ---@param eventData? table -- data to send through the safe event
            ---@param eventOptions? CEventOptions data to define whether server, client, or both should be triggered (defaults to {server = false, client = true})
            return function(eventName, eventData, eventOptions)
                ESX.TriggerSafeEvent(eventName, self.source, eventData, eventOptions or { server = false, client = true })
            end
        end
    })
end

---@class xPlayer
---@field triggerSafeEvent fun(eventName: string, eventData: table, eventOptions?: CEventOptions)
