if ESX.RegisterPlayerMethodOverrides then return end

---@type table<string, string>
local invokedResources = {}

---@type table<string, function>
Core.PlayerMethodOverrides = {}

function ESX.RegisterPlayerMethodOverrides(overrides)
    local overridesType = type(overrides)
    if overridesType ~= "table" then
        return print(("[^1ERROR^7] Expected a parameter with type of ^3table^7 in ^4ESX.RegisterPlayerMethodOverrides^7 function. Received (^3%s^7)"):format(overridesType))
    end

    local invokingResource = GetInvokingResource() or cache.resource

    for fnName, fn in pairs(overrides) do
        if Core.PlayerMethodOverrides[fnName] then
            print(("[^3WARNING^7] xPlayer method ^2'%s'^7 is already overrided by ^4'%s'^7. Re-overriding it from ^4'%s'^7..."):format(fnName, invokedResources[fnName], invokingResource))
        end

        Core.PlayerMethodOverrides[fnName] = fn
        invokedResources[fnName] = invokingResource
    end

    --TODO: override online players methods
end

local function onResourceStop(resource)
    for fnName, invokedResource in pairs(invokedResources) do
        if invokedResource == resource then
            print(("[^5INFO^7] Removing overrided xPlayer method ^2'%s'^7 from ^4'%s'^7..."):format(fnName, invokedResources[fnName]))
            Core.PlayerMethodOverrides[fnName] = nil
            invokedResources[fnName] = nil

            --TODO: remove overrided online players methods
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)
