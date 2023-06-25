if ESX.RegisterPlayerMethodOverrides then return end

---@type table<string, string>
local invokedResources = {}

---@type table<string, function>
local originalMethods = lib.require("server.classes.playerMethods")

---@type table<string, function>
Core.ExtendedPlayerMethods = {}

---Overrides player methods if they exist. If those method don't exist, it will add the new received methods to the all of the player objects(basically extends xPlayer objects methods)
---@param newMethods table<string, function>
---@return table<string, number>?
function ESX.RegisterPlayerMethodOverrides(newMethods)
    local newMethodsType = type(newMethods)

    if newMethodsType ~= "table" then
        return print(("[^1ERROR^7] Expected a parameter with type of ^3table^7 in ^4ESX.RegisterPlayerMethodOverrides^7 function. Received (^3%s^7)"):format(newMethodsType))
    end

    ---@type table<string, number>
    local registeredHooks = {}
    local invokingResource = GetInvokingResource()

    for fnName, fn in pairs(newMethods) do
        -- This check means the method registration is coming from es_extended itself onResourceStart (such as from modules/ox_inventory)
        -- Why do we do this exclusively and not through hook and xPlayer.setMethod? Because that way they add function reference to xPlayer objects
        -- Which is almost 3 times more expensive to call than a normal function which will be applied through Core.ExtendedPlayerMethods!
        -- Conclusion: throw your extended/custom player methods as a module inside the framework to load up, which will be more performant than registering them from external resources...
        if not invokingResource then
            Core.ExtendedPlayerMethods[fnName] = fn

            goto skipLoop
        end

        invokedResources[fnName] = invokingResource

        registeredHooks[fnName] = Core.ResourceExport:registerHook("onPlayerLoad", function(payload)
            local xPlayer = payload?.xPlayer --[[@as xPlayer]]

            if not xPlayer then return print("[^1ERROR^7] Unexpected behavior from onPlayerLoad hook in modules/override/server.lua") end

            xPlayer.setMethod(fnName, fn) -- registering the new method(s) to apply to the future players right after their xPlayer creation
        end)

        for _, xPlayer in pairs(ESX.Players) do
            xPlayer.setMethod(fnName, fn) -- registering the new method(s) for the online players
        end

        ::skipLoop::
    end

    return registeredHooks
end

local function onResourceStop(resource)
    for fnName, invokedResource in pairs(invokedResources) do
        if invokedResource == resource then
            invokedResources[fnName] = nil

            for _, xPlayer in pairs(ESX.Players) do
                if originalMethods[fnName] then
                    xPlayer.setMethod(fnName, originalMethods[fnName]) -- overriding online players methods to the original one(s) if any exist...
                else
                    xPlayer[fnName] = nil
                end
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)