-- Copyright (c) 2022-2023 Overextended (https://github.com/overextended/ox_inventory/blob/main/modules/hooks/server.lua)
-- Modified to fit ESX system in 2023 by ESX-Overextended

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.

-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

if Core.TriggerEventHooks then return end

local eventHooks, hookId, clock = {}, 0, os.clock -- instead of microtime which is used by ox, we gotta use clock since os.microtime is not recognized in our lua lint workflow
local api = setmetatable({}, {
    __newindex = function(self, index, value)
        exports(index, value)
        rawset(self, index, value)
    end
})

---@param event string
---@param cb function
---@param options? table
function api.registerHook(event, cb, options)
    if not eventHooks[event] then eventHooks[event] = {} end

    local mt = getmetatable(cb)
    mt.__index, mt.__newindex = nil, nil
    cb.resource = GetInvokingResource() or cache.resource
    hookId = hookId + 1 -- very strange but if we use compound operator of += here, the lint crashes although we are using this operator in other part of the code!
    cb.hookId = hookId

    if type(options) == "table" then
        for k, v in pairs(options) do
            cb[k] = v
        end
    end

    eventHooks[event][#eventHooks[event] + 1] = cb

    return hookId
end

---@param resource string
---@param id? number
local function removeResourceHooks(resource, id)
    for _, hooks in pairs(eventHooks) do
        for i = #hooks, 1, -1 do
            local hook = hooks[i]

            if hook.resource == resource and (not id or hook.hookId == id) then
                table.remove(hooks, i)
            end
        end
    end
end

AddEventHandler("onResourceStop", removeResourceHooks)
AddEventHandler("onServerResourceStop", removeResourceHooks)

---@param id? number
function api.removeHooks(id)
    removeResourceHooks(GetInvokingResource() or cache.resource, id)
end

---Triggers all registered hooks for the specified event
---@param event string
---@param payload? table
function Core.TriggerEventHooks(event, payload)
    local hooks = eventHooks[event]

    if hooks then
        for i = 1, #hooks do
            local hook = hooks[i]

            ESX.Trace(("Triggering event hook '%s:%s:%s'"):format(hook.resource, event, i), "trace", hook.print)

            local start = clock()
            local _, response = xpcall(hooks[i], function() ESX.Trace(("There was an error in trigerring event hook '%s:%s:%s'"):format(hook.resource, event, i), "error", true) end, payload)
            local executionTime = (clock() - start) * 1000 -- convert execution time to milliseconds

            if executionTime >= 100 then
                ESX.Trace(("Execution of event hook '%s:%s:%s' took %.2fms"):format(hook.resource, event, i, executionTime), "warning", true)
            end

            if response == false then
                return false
            end
        end
    end

    return true
end
