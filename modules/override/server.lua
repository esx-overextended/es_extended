if ESX.RegisterPlayerMethodOverrides then return end

---@type table<string, string>
local extendedPlayerMethodsResources = {}

---@type table<string, function>
local originalPlayerMethods = lib.require("server.classes.player.playerMethods")

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

        extendedPlayerMethodsResources[fnName] = invokingResource

        registeredHooks[fnName] = Core.ResourceExport:registerHook("onPlayerLoad", function(payload)
            local xPlayer = payload?.xPlayer --[[@as xPlayer]]

            if not ESX.Players[xPlayer?.source] then return print("[^1ERROR^7] Unexpected behavior from onPlayerLoad hook in modules/override/server.lua") end

            xPlayer.setMethod(fnName, fn) -- registering the new method(s) to apply to the future players right after their xPlayer creation
        end)

        for _, xPlayer in pairs(ESX.Players) do
            xPlayer.setMethod(fnName, fn) -- registering the new method(s) for the online players
        end

        ::skipLoop::
    end

    return registeredHooks
end

---@type table<string, string>
local extendedVehicleMethodsResources = {}

---@type table<string, function>
local originalVehicleMethods = lib.require("server.classes.vehicle.vehicleMethods")

---@type table<string, function>
Core.ExtendedVehicleMethods = {}

---Overrides vehicle methods if they exist. If those method don't exist, it will add the new received methods to the all of the vehicle objects(basically extends xVehicle objects methods)
---@param newMethods table<string, function>
---@return table<string, number>?
function ESX.RegisterVehicleMethodOverrides(newMethods)
    local newMethodsType = type(newMethods)

    if newMethodsType ~= "table" then
        return print(("[^1ERROR^7] Expected a parameter with type of ^3table^7 in ^4ESX.RegisterVehicleMethodOverrides^7 function. Received (^3%s^7)"):format(newMethodsType))
    end

    ---@type table<string, number>
    local registeredHooks = {}
    local invokingResource = GetInvokingResource()

    for fnName, fn in pairs(newMethods) do
        -- This check means the method registration is coming from es_extended itself onResourceStart
        -- Why do we do this exclusively and not through hook and xVehicle.setMethod? Because that way they add function reference to xVehicle objects
        -- Which is almost 3 times more expensive to call than a normal function which will be applied through Core.ExtendedVehicleMethods!
        -- Conclusion: throw your extended/custom vehicle methods as a module inside the framework to load up, which will be more performant than registering them from external resources...
        if not invokingResource then
            Core.ExtendedVehicleMethods[fnName] = fn

            goto skipLoop
        end

        extendedVehicleMethodsResources[fnName] = invokingResource

        registeredHooks[fnName] = Core.ResourceExport:registerHook("onVehicleCreate", function(payload)
            local xVehicle = payload?.xVehicle --[[@as xVehicle]]

            if not Core.Vehicles[xVehicle?.entity] then return print("[^1ERROR^7] Unexpected behavior from onVehicleCreate hook in modules/override/server.lua") end

            xVehicle.setMethod(fnName, fn) -- registering the new method(s) to apply to the future vehicles right after their xVehicle creation
        end)

        for _, xVehicle in pairs(Core.Vehicles) do
            xVehicle.setMethod(fnName, fn) -- registering the new method(s) for the spawned vehicles
        end

        ::skipLoop::
    end

    return registeredHooks
end

local function onResourceStop(resource)
    for fnName, invokedResource in pairs(extendedPlayerMethodsResources) do
        if invokedResource == resource then
            extendedPlayerMethodsResources[fnName] = nil

            for _, xPlayer in pairs(ESX.Players) do
                if originalPlayerMethods[fnName] then
                    xPlayer.setMethod(fnName, originalPlayerMethods[fnName]) -- overriding online players methods to the original one(s) if any exist...
                else
                    xPlayer[fnName] = nil
                end
            end
        end
    end

    for fnName, invokedResource in pairs(extendedVehicleMethodsResources) do
        if invokedResource == resource then
            extendedVehicleMethodsResources[fnName] = nil

            for _, xVehicle in pairs(Core.Vehicles) do
                if originalVehicleMethods[fnName] then
                    xVehicle.setMethod(fnName, originalVehicleMethods[fnName]) -- overriding spawned vehicles methods to the original one(s) if any exist...
                else
                    xVehicle[fnName] = nil
                end
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler("onServerResourceStop", onResourceStop)

do
    ESX.RegisterPlayerMethodOverrides({
        ---Sets the value of the specified field for the xPlayer object. If a field with the same name already exist, its value will be overrided.
        ---@param self xPlayer
        setField = function(self)
            ---@param fieldName string
            ---@param value number | string | boolean | table
            ---@return boolean (whether the registration action was successful or not)
            return function(fieldName, value)
                local fieldNameType = type(fieldName)
                local valueType = type(value)
                local isValueValid = (valueType == "number" or valueType == "string" or valueType == "boolean" or (valueType == "table" and not value?.__cfx_functionReference)) and true or false

                if fieldNameType ~= "string" then print(("[^1ERROR^7] The field name (^3%s^7) passed in ^5player(%s)'s setField()^7 is not a valid string!"):format(fieldName, self.source)) return false
                elseif not isValueValid then print(("[^1ERROR^7] The value passed in ^5player(%s)'s setField()^7 does not have a valid type!"):format(self.source)) return false end

                if fieldName == "setField" or fieldName == "setMethod" then print(("[^1ERROR^7] Field ^2%s^7 of xPlayer ^1cannot^7 be overrided!"):format(fieldName)) return false end

                self[fieldName] = value

                if Config.EnableDebug then
                    print(("[^5INFO^7] Setting field (^2%s^7) for player(%s) through ^5xPlayer.setField()^7."):format(fieldName, self.source))
                end

                return true
            end
        end,

        ---Adds a new method/function to the current xPlayer object. If a method with the same name already exist, it will be overrided.
        ---@param self xPlayer
        setMethod = function(self)
            ---@param fnName string
            ---@param fn function
            ---@return boolean (whether the registration action was successful or not)
            return function(fnName, fn)
                local fnNameType = type(fnName)
                local fnType = type(fn)
                local isFnValid = (fnType == "function" or (fnType == "table" and fn?.__cfx_functionReference and true)) or false

                if fnNameType ~= "string" then print(("[^1ERROR^7] The method name (^3%s^7) passed in ^5player(%s)'s setMethod()^7 is not a valid string!"):format(fnName, self.source)) return false
                elseif not isFnValid then print(("[^1ERROR^7] The function passed in ^5player(%s)'s setMethod()^7 is not a valid function!"):format(self.source)) return false end

                if fnName == "setMethod" or fnName == "setField" then print(("[^1ERROR^7] Method ^2%s^7 of xPlayer ^1cannot^7 be overrided!"):format(fnName)) return false end

                self[fnName] = fn(self)

                if Config.EnableDebug then
                    print(("[^5INFO^7] Setting method (^2%s^7) for player(%s) through ^5xPlayer.setMethod()^7."):format(fnName, self.source))
                end

                return true
            end
        end
    })

    ESX.RegisterVehicleMethodOverrides({
        ---Sets the value of the specified field for the xVehicle object. If a field with the same name already exist, its value will be overrided.
        ---@param self xVehicle
        setField = function(self)
            ---@param fieldName string
            ---@param value number | string | boolean | table
            ---@return boolean (whether the registration action was successful or not)
            return function(fieldName, value)
                local fieldNameType = type(fieldName)
                local valueType = type(value)
                local isValueValid = (valueType == "number" or valueType == "string" or valueType == "boolean" or (valueType == "table" and not value?.__cfx_functionReference)) and true or false

                if fieldNameType ~= "string" then print(("[^1ERROR^7] The field name (^3%s^7) passed in ^5vehicle(%s)'s setField()^7 is not a valid string!"):format(fieldName, self.entity)) return false
                elseif not isValueValid then print(("[^1ERROR^7] The value passed in ^5vehicle(%s)'s setField()^7 does not have a valid type!"):format(self.entity)) return false end

                if fieldName == "setField" or fieldName == "setMethod" then print(("[^1ERROR^7] Field ^2%s^7 of xVehicle ^1cannot^7 be overrided!"):format(fieldName)) return false end

                self[fieldName] = value

                if Config.EnableDebug then
                    print(("[^5INFO^7] Setting field (^2%s^7) for vehicle(%s) through ^5xVehicle.setField()^7."):format(fieldName, self.entity))
                end

                return true
            end
        end,

        ---Adds a new method/function to the current xVehicle object. If a method with the same name already exist, it will be overrided.
        ---@param self xVehicle
        setMethod = function(self)
            ---@param fnName string
            ---@param fn function
            ---@return boolean (whether the registration action was successful or not)
            return function(fnName, fn)
                local fnNameType = type(fnName)
                local fnType = type(fn)
                local isFnValid = (fnType == "function" or (fnType == "table" and fn?.__cfx_functionReference and true)) or false

                if fnNameType ~= "string" then print(("[^1ERROR^7] The method name (^3%s^7) passed in ^5vehicle(%s)'s setMethod()^7 is not a valid string!"):format(fnName, self.entity)) return false
                elseif not isFnValid then print(("[^1ERROR^7] The function passed in ^5vehicle(%s)'s setMethod()^7 is not a valid function!"):format(self.entity)) return false end

                if fnName == "setMethod" or fnName == "setField" then print(("[^1ERROR^7] Method ^2%s^7 of xVehicle ^1cannot^7 be overrided!"):format(fnName)) return false end

                self[fnName] = fn(self)

                if Config.EnableDebug then
                    print(("[^5INFO^7] Setting method (^2%s^7) for vehicle(%s) through ^5xVehicle.setMethod()^7."):format(fnName, self.entity))
                end

                return true
            end
        end
    })
end

---@class xPlayer
---@field setField fun(fieldName: string, value: number | string | boolean | table): boolean
---@field setMethod fun(fnName: string, fn: function): boolean

---@class xVehicle
---@field setField fun(fieldName: string, value: number | string | boolean | table): boolean
---@field setMethod fun(fnName: string, fn: function): boolean