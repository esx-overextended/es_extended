-- Copyright (c) 2022-2023 Overextended (https://github.com/overextended/ox_core/tree/main/server/vehicle)
-- Modified to fit ESX system in 2023 by ESX-Overextended

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

local xVehicleMethods = {
    ---Sets the vehicle's coordinates and heading.
    ---@param self xVehicle
    setCoords = function(self)
        ---@param coords table | vector3 | vector4
        return function(coords)
            local vector = vector4(coords?.x, coords?.y, coords?.z, coords?.w or coords?.heading or 0.0)

            if not vector then return end

            SetEntityCoords(self.entity, vector.x, vector.y, vector.z, false, false, false, false)
            SetEntityHeading(self.entity, vector.w)
        end
    end,

    ---Gets the vehicle's coordinates and heading.
    ---@param self xVehicle
    getCoords = function(self)
        ---@param vector? boolean whether to return the vehicle coords as vector4 or as table
        ---@return vector4 | table
        return function(vector)
            local coords = GetEntityCoords(self.entity)
            local heading = GetEntityHeading(self.entity)

            return vector and vector4(coords.x, coords.y, coords.z, heading) or { x = coords.x, y = coords.y, z = coords.z, heading = heading }
        end
    end,

    ---Sets the vehicle's non-persistant data for the specified key to the given value which will be removed on vehicle deletion. Similar to statebag data.
    ---@param self xVehicle
    set = function(self)
        ---@param key string
        ---@param value any
        return function(key, value)
            self.variables[key] = value
            Entity(self.entity).state:set(key, value, true)
        end
    end,

    ---Gets the value of the specified key from the vehicles's non-persistant data, or omit the argument to get all data.
    ---@param self xVehicle
    get = function(self)
        ---@param key? string
        ---@return any
        return function(key)
            return key and self.variables[key] or self.variables
        end
    end,

    ---Sets the vehicle's persistant data for the specified key to the given value which will be saved on vehicle deletion. Unlike statebag data.
    ---@param self xVehicle
    setMetadata = function(self)
        ---@param index string
        ---@param value? string | number | table
        ---@param subValue? any
        ---@return boolean
        return function(index, value, subValue) -- TODO: Get back to this as it looks like it won't work with all different cases (it's a copy of xPlayer.setMetadata)...
            if not index then print("[^1ERROR^7] xVehicle.setMetadata ^5index^7 is Missing!") return false end

            if type(index) ~= "string" then print("[^1ERROR^7] xVehicle.setMetadata ^5index^7 should be ^5string^7!") return false end

            local _type = type(value)

            if not subValue then
                if _type ~= "nil" and _type ~= "number" and _type ~= "string" and _type ~= "table" then
                    print(("[^1ERROR^7] xVehicle.setMetadata ^5%s^7 should be ^5number^7 or ^5string^7 or ^5table^7!"):format(value))
                    return false
                end

                self.metadata[index] = value
            else
                if _type ~= "string" then
                    print(("[^1ERROR^7] xVehicle.setMetadata ^5value^7 should be ^5string^7 as a subIndex!"):format(value))
                    return false
                end

                self.metadata[index][value] = subValue
            end

            Entity(self.entity).state:set("metadata", self.metadata, true)

            return true
        end
    end,

    ---Gets the value of the specified key from the vehicles's persistant data, or omit the argument to get all data.
    ---@param self xVehicle
    getMetadata = function(self)
        ---@param index? string
        ---@param subIndex? string | table
        ---@return nil | string | table
        return function(index, subIndex) -- TODO: Get back to this as it looks like it won't work with all different cases (it's a copy of xPlayer.getMetadata)...
            if not index then return self.metadata end

            if type(index) ~= "string" then  print("[^1ERROR^7] xVehicle.getMetadata ^5index^7 should be ^5string^7!") end

            if self.metadata[index] then
                if subIndex and type(self.metadata[index]) == "table" then
                    local _type = type(subIndex)

                    if _type == "string" then return self.metadata[index][subIndex] end

                    if _type == "table" then
                        local returnValues = {}

                        for i = 1, #subIndex do
                            if self.metadata[index][subIndex[i]] then
                                returnValues[subIndex[i]] = self.metadata[index][subIndex[i]]
                            end
                        end

                        return returnValues
                    end

                    return nil
                end

                return self.metadata[index]
            end

            return nil
        end
    end,

    ---Removes/despawns the vehicle from the game world, optionally removes its entry from database.
    ---@param self xVehicle
    delete = function(self)
        ---@param removeFromDb? boolean delete the entry from database as well or no (defaults to false if not provided and nil)
        return function(removeFromDb)
            local id = self.id
            local entity = self.entity
            local netId = self.netId
            local vin = self.vin
            local plate = self.plate

            if self.owner or self.group then
                if removeFromDb then
                    MySQL.prepare("DELETE FROM `owned_vehicles` WHERE `id` = ?", { self.id })
                else
                    MySQL.prepare("UPDATE `owned_vehicles` SET `stored` = ?, `metadata` = ? WHERE `id` = ?", { self.stored, json.encode(self.metadata), self.id })
                end
            end

            Core.Vehicles[entity] = nil -- maybe I should use entityRemoved event instead(but that might create race condition, no?)
            Core.VehiclesPropertiesQueue[entity] = nil -- maybe I should use entityRemoved event instead(but that might create race condition, no?)

            if DoesEntityExist(entity) then DeleteEntity(entity) end

            TriggerEvent("esx:vehicleDeleted", id, entity, netId, vin, plate)
        end
    end,

    ---Updates the vehicle's stored property on database and optionally despawns it.
    ---@param self xVehicle
    setStored = function(self)
        ---@param value? boolean
        ---@param despawn? boolean remove the vehicle entity from the game world as well or not (defaults to false if not provided and nil)
        return function(value, despawn)
            self.stored = value

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `stored` = ? WHERE `id` = ?", { self.stored, self.id })

            if despawn then
                self.delete()
            end
        end
    end,

    ---Updates the vehicle's owner, matching a xPlayer's identifier or nil to set it as unowned.
    ---@param self xVehicle
    setOwner = function(self)
        ---@param newOwner? string
        return function(newOwner)
            self.owner = newOwner

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `owner` = ? WHERE `id` = ?", { self.owner or nil --[[to make sure "false" is not being sent]], self.id })

            Entity(self.entity).state:set("owner", self.owner, true)
        end
    end,

    ---Updates the vehicle's group, which can be used for garage restrictions, unowned group vehicles, etc.
    ---@param self xVehicle
    setGroup = function(self)
        ---Updates the current vehicle group
        ---@param newGroup? string
        return function(newGroup)
            self.group = newGroup

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `job` = ? WHERE `id` = ?", { self.group or nil --[[to make sure "false" is not being sent]], self.id })

            Entity(self.entity).state:set("group", self.group, true)
        end
    end,

    ---Sets the vehicle's plate, used in the database to ensure uniqueness. Does not necessarily match the vehicle's plate property (i.e. fake plates).
    ---@param self xVehicle
    setPlate = function(self)
        ---@param newPlate string
        return function(newPlate)
            self.plate = ("%-8s"):format(newPlate)

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `plate` = ? WHERE `id` = ?", { self.plate, self.id })

            Entity(self.entity).state:set("plate", self.plate, true)
        end
    end,

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
}

return xVehicleMethods
