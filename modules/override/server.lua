if ESX.RegisterPlayerMethodOverrides then return end

---@type table<string, string>
local invokedResources = {}

---@type table<string, function>
local originalMethods = lib.require("server.classes.playerMethods")

---@type table<string, function>
Core.PlayerMethodOverrides = {}

---Overrides player methods if they exist. If those method don't exist, it will add the new received methods to the all of the player objects(basically extends xPlayer objects methods)
---@param newMethods table<string, function>
function ESX.RegisterPlayerMethodOverrides(newMethods)
    local newMethodsType = type(newMethods)
    if newMethodsType ~= "table" then
        return print(("[^1ERROR^7] Expected a parameter with type of ^3table^7 in ^4ESX.RegisterPlayerMethodOverrides^7 function. Received (^3%s^7)"):format(newMethodsType))
    end

    local invokingResource = GetInvokingResource() or cache.resource

    for fnName, fn in pairs(newMethods) do
        if Core.PlayerMethodOverrides[fnName] then
            print(("[^3WARNING^7] xPlayer method ^2'%s'^7 is already overrided by ^4'%s'^7. Re-overriding it from ^4'%s'^7..."):format(fnName, invokedResources[fnName], invokingResource))
        end

        Core.PlayerMethodOverrides[fnName] = fn
        invokedResources[fnName] = invokingResource

        for playerId, xPlayer in pairs(ESX.Players) do
            ESX.Players[playerId][fnName] = fn(xPlayer) -- overriding online players methods to the new one(s)...
        end
    end
end

local function onResourceStop(resource)
    for fnName, invokedResource in pairs(invokedResources) do
        if invokedResource == resource then
            print(("[^5INFO^7] Removing overrided xPlayer method ^2'%s'^7 from ^4'%s'^7..."):format(fnName, invokedResources[fnName]))
            Core.PlayerMethodOverrides[fnName] = nil
            invokedResources[fnName] = nil

            for playerId, xPlayer in pairs(ESX.Players) do
                ESX.Players[playerId][fnName] = originalMethods[fnName] and originalMethods[fnName](xPlayer) or nil -- overriding online players methods to the original one(s) if exist...
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)
