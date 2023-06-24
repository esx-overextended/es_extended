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

local eventHooks, hookId = {}, 0
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
    mt.__index = nil
    mt.__newindex = nil
    cb.resource = GetInvokingResource() or cache.resource
    hookId += 1
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

            if hook.print then
                print(("Triggering event hook '%s:%s:%s'"):format(hook.resource, event, i))
            end

            local start = microtime()
            local _, response = pcall(hooks[i], payload)
            local executionTime = microtime() - start

            if executionTime >= 100000 then
                warn(("[^3WARNING^7] Execution of event hook '%s:%s:%s' took %.2fms"):format(hook.resource, event, i, executionTime / 1e3))
            end

            if response == false then
                return false
            end
        end
    end

    return true
end

