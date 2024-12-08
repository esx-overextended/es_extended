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

local xVehicleMethods = lib.require("server.classes.vehicle.vehicleMethods")

---@type table<entityId, table<number, table>>
Core.VehiclesPropertiesQueue = {}

---@type table<number, { key: number, name: string }>
Core.RegisteredVehiclePropertiesEvent = {}

---Creates an xVehicle object
---@param vehicleId? integer | number
---@param vehicleOwner? string | boolean
---@param vehicleGroup? string | boolean
---@param vehicleNetId integer | number
---@param vehicleEntity integer | number
---@param vehicleModel string
---@param vehiclePlate string
---@param vehicleVin string
---@param vehicleScript string
---@param vehicleMetadata table
---@param vehicleProperties table
---@return xVehicle
local function createExtendedVehicle(vehicleId, vehicleOwner, vehicleGroup, vehicleNetId, vehicleEntity, vehicleModel, vehiclePlate, vehicleVin, vehicleScript, vehicleMetadata, vehicleProperties)
    ---@type xVehicle
    local self = {} ---@diagnostic disable-line: missing-fields

    self.id = vehicleId
    self.owner = vehicleOwner
    self.group = vehicleGroup
    self.netId = vehicleNetId
    self.entity = vehicleEntity
    self.model = vehicleModel
    self.plate = vehiclePlate
    self.vin = vehicleVin
    self.script = vehicleScript
    self.stored = nil
    self.variables = {}
    self.metadata = vehicleMetadata or {}
    self.properties = vehicleProperties

    local stateBag = Entity(self.entity).state

    stateBag:set("id", self.id, true)
    stateBag:set("owner", self.owner, true)
    stateBag:set("group", self.group, true)
    stateBag:set("model", self.model, true)
    stateBag:set("plate", self.plate, true)
    stateBag:set("vin", self.vin, true)
    stateBag:set("metadata", self.metadata, true)
    stateBag:set("properties", self.properties, true)

    for fnName, fn in pairs(xVehicleMethods) do
        self[fnName] = fn(self)
    end

    for fnName, fn in pairs(Core.ExtendedVehicleMethods) do
        self[fnName] = fn(self)
    end

    return self
end

---@param id? number
---@param owner? string | boolean
---@param group? string | boolean
---@param plate string
---@param model string
---@param script string
---@param metadata table
---@param coords vector3
---@param heading number
---@param vType string
---@param properties table
---@return xVehicle?
local function spawnVehicle(id, owner, group, plate, vin, model, script, metadata, coords, heading, vType, properties)
    local entity = Core.SpawnVehicle(model, vType, coords, heading)

    if not entity then return end

    local xVehicle = createExtendedVehicle(id, owner, group, NetworkGetNetworkIdFromEntity(entity), entity, model, plate, vin, script, metadata, properties)

    Core.Vehicles[xVehicle.entity] = xVehicle
    Core.RegisterVehiclePropertiesEvent(xVehicle.entity)

    Core.TriggerEventHooks("onVehicleCreate", { xVehicle = xVehicle })

    Entity(entity).state:set("initVehicle", true, true)

    ESX.SetVehicleProperties(entity, properties)

    if owner or group then xVehicle.setStored(false) end

    TriggerEvent("esx:vehicleCreated", xVehicle.entity, xVehicle.netId, xVehicle)

    return xVehicle
end

---@param modelName string
---@param modelType string
---@param coordinates vector3
---@param heading number
function Core.SpawnVehicle(modelName, modelType, coordinates, heading)
    -- New native seems to be missing some types, for now we will convert to known types
    -- https://github.com/citizenfx/fivem/commit/1e266a2ca5c04eb96c090de67508a3475d35d6da
    if modelType == "bicycle" or modelType == "quadbike" or modelType == "amphibious_quadbike" then
        modelType = "bike"
    elseif modelType == "amphibious_automobile" or modelType == "submarinecar" then
        modelType = "automobile"
    elseif modelType == "blimp" then
        modelType = "heli"
    end

    local entity = CreateVehicleServerSetter(joaat(modelName), modelType, coordinates.x, coordinates.y, coordinates.z, heading)

    if not DoesEntityExist(entity) then return ESX.Trace(("Failed to spawn vehicle (^4%s^7)"):format(modelName), "error", true) end

    TriggerEvent("entityCreated", entity)

    return entity
end

---@param vehicleEntity number
function Core.RegisterVehiclePropertiesEvent(vehicleEntity)
    if Core.RegisteredVehiclePropertiesEvent[vehicleEntity] then
        return ESX.Trace(("Tried to register properties listener for vehicle entity Id of %s, but it's been already registered!"):format(vehicleEntity), "warning", true)
    end

    local xVehicle = Core.Vehicles[vehicleEntity]
    local vehicleModelHash = joaat(xVehicle.model)

    Core.RegisteredVehiclePropertiesEvent[vehicleEntity] = RegisterNetEvent(("esx:updateVehicleNetId%sProperties"):format(xVehicle.netId), function(receivedVehicleId, receivedProperties)
        if xVehicle.id ~= receivedVehicleId then
            return ESX.Trace(("Player Id %s requested to update vehicle properties. Expected '%s', Received '%s'"):format(source, xVehicle.id, receivedVehicleId), "error", true)
        end

        if NetworkGetEntityOwner(vehicleEntity) ~= source then return end

        local typeProperties = type(receivedProperties)

        if typeProperties ~= "table" or table.type(receivedProperties) ~= "hash" then
            return ESX.Trace(("Invalid vehicle properties to update received. Expected 'table-hash', Received '%s'"):format(source, typeProperties == "table" and ("table-%s"):format(table.type(receivedProperties)) or typeProperties), "error", true)
        end

        if receivedProperties.model then
            if vehicleModelHash ~= receivedProperties.model then
                return ESX.Trace(("Player Id %s sent an unexpected vehicle model. Expected '%s', Received '%s'"):format(source, vehicleModelHash, receivedProperties.model), "error", true)
            end
        end

        xVehicle.setProperties(receivedProperties, false)

        ESX.Trace(("Updated Vehicle Properties (vehicleId: %s - entityId: %s - networkId: %s)"):format(xVehicle.id, xVehicle.entity, xVehicle.netId), "trace", true)
    end)
end

---@param vehicleEntity number
function Core.UnregisterVehiclePropertiesEvent(vehicleEntity)
    if not Core.RegisteredVehiclePropertiesEvent[vehicleEntity] then
        return ESX.Trace(("Tried to unregister properties listener for vehicle entity Id of %s, but it does not even exist!"):format(vehicleEntity), "warning", true)
    end

    RemoveEventHandler(Core.RegisteredVehiclePropertiesEvent[vehicleEntity])
    Core.RegisteredVehiclePropertiesEvent[vehicleEntity] = nil
end

---Loads a vehicle from the database by id, or creates a new vehicle using provided data.
---@param data table | number
---@param coords vector3 | vector4
---@param heading? number
---@param forceSpawn? boolean if true, it will spawn the vehicle no matter if the vehicle already is spawned in the game world. If false or nil, it checks if the vehicle has not been already spawned
---@return table | number | nil
function ESX.CreateVehicle(data, coords, heading, forceSpawn)
    local typeData = type(data)
    local script = GetInvokingResource()

    if typeData ~= "number" and typeData ~= "table" then
        ESX.Trace(("Invalid type of data (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeData), "error", true)
        return
    end

    if typeData == "number" then
        local typeCoords = type(coords)

        if typeCoords == "table" then
            if not coords[1] or not coords[2] or not coords[3] then
                ESX.Trace(("Invalid type of coords (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeCoords), "error", true)
                return
            end

            coords = vector3(coords[1], coords[2], coords[3])
            heading = heading or coords[4]
        elseif typeCoords == "vector4" then
            coords = vector3(coords.x, coords.y, coords.z)
            heading = heading or coords.w
        elseif typeCoords ~= "vector3" then
            ESX.Trace(("Invalid type of coords (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeCoords), "error", true)
            return
        end

        heading = heading or 0.0

        local vehicle = MySQL.prepare.await(("SELECT `owner`, `job`, `plate`, `vin`, `model`, `class`, `vehicle`, `metadata` FROM `owned_vehicles` WHERE `id` = ? %s"):format(not forceSpawn and "AND `stored` = 1" or ""), { data })

        if not vehicle then
            ESX.Trace(("Failed to spawn vehicle with id %s (invalid id%s)"):format(data, not forceSpawn and " or already spawned" or ""), "error", true)
            return
        end

        vehicle.vehicle = json.decode(vehicle.vehicle --[[@as string]])
        vehicle.metadata = json.decode(vehicle.metadata --[[@as string]])

        if not vehicle.vin or not vehicle.metadata or not vehicle.model or not vehicle.class then -- probably first time spawning the vehicle after migrating from esx-legacy
            local vehicleData = nil

            if vehicle.model then
                local vData = ESX.GetVehicleData(vehicle.model)

                if vData then
                    vehicleData = { model = vehicle.model, data = vData }
                end
            end

            if not vehicleData then
                for vModel, vData in pairs(ESX.GetVehicleData()) do
                    if vData.hash == vehicle.vehicle?.model then
                        vehicleData = { model = vModel, data = vData }
                        break
                    end
                end
            end

            if not vehicleData then
                ESX.Trace(("Vehicle model hash (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(vehicle.vehicle?.model), "error", true)
                return
            end

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `vin` = ?, `type` = ?, `model` = ?, `class` = ?, `metadata` = ? WHERE `id` = ?", {
                vehicle.vin or Core.GenerateVin(vehicleData.model),
                vehicleData.data?.type,
                vehicle.model or vehicleData.model,
                vehicle.class or vehicleData.data?.class,
                vehicle.metadata and json.encode(vehicle.metadata) or "{}",
                data
            })

            return ESX.CreateVehicle(data, coords, heading, forceSpawn)
        end

        local modelData = ESX.GetVehicleData(vehicle.model) --[[@as VehicleData]]

        if not modelData then
            ESX.Trace(("Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(vehicle.model), "error", true)
            return
        end

        return spawnVehicle(data, vehicle.owner, vehicle.job, vehicle.plate, vehicle.vin, vehicle.model, script, vehicle.metadata, coords, heading, modelData.type, vehicle.vehicle)
    end

    local typeModel = type(data.model)

    if typeModel ~= "string" and typeModel ~= "number" then
        ESX.Trace(("Invalid type of data.model (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeModel), "error", true)
        return
    end

    if typeModel == "number" or type(tonumber(data.model)) == "number" then
        typeModel = "number"
        data.model = tonumber(data.model) --[[@as number]]

        for vModel, vData in pairs(ESX.GetVehicleData()) do
            if vData.hash == data.model then
                data.model = vModel
                break
            end
        end
    end

    local model = typeModel == "string" and data.model:lower() or data.model --[[@as string]]
    local modelData = ESX.GetVehicleData(model) --[[@as VehicleData]]

    if not modelData then
        ESX.Trace(("Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(model), "error", true)
        return
    end

    local owner = type(data.owner) == "string" and data.owner or false
    local group = type(data.group) == "string" and data.group or false
    local stored = data.stored
    local plate = Core.GeneratePlate()
    local vin = Core.GenerateVin(model)
    local metadata = {}
    local vehicleProperties = data.properties or {}

    vehicleProperties.plate = plate
    vehicleProperties.model = modelData.hash -- backward compatibility with esx-legacy

    local vehicleId = (owner or group) and MySQL.prepare.await("INSERT INTO `owned_vehicles` (`owner`, `plate`, `vin`, `vehicle`, `type`, `job`, `model`, `class`, `metadata`, `stored`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        owner or nil, plate, vin, json.encode(vehicleProperties), modelData.type, group or nil, model, modelData.class, json.encode(metadata), stored
    }) or nil

    if stored then
        return vehicleId
    end

    return spawnVehicle(vehicleId, owner, group, plate, vin, model, script, metadata, coords, heading or 90.0, modelData.type, vehicleProperties)
end

---Returns an instance of xVehicle for the given entity id.
---@param vehicleEntity number | integer
---@return xVehicle?
function ESX.GetVehicle(vehicleEntity)
    return Core.Vehicles[vehicleEntity]
end

---Return all vehicle data.
---@return xVehicle[]
function ESX.GetVehicles()
    local vehicles, size = {}, 0

    for _, xVehicle in pairs(Core.Vehicles) do
        size += 1
        vehicles[size] = xVehicle
    end

    return vehicles
end

---Creates a unique vehicle plate.
---@return string
function Core.GeneratePlate()
    local generatedPlate = string.upper(ESX.GetRandomString(8, string.upper(Config.PlatePattern)))
    return not MySQL.scalar.await("SELECT 1 FROM `owned_vehicles` WHERE `plate` = ?", { generatedPlate }) and generatedPlate or Core.GeneratePlate()
end

---Creates a unique vehicle vin number.
---@param model string
---@return string
function Core.GenerateVin(model)
    local vehicleData = ESX.GetVehicleData(model:lower())

    ---@diagnostic disable-next-line: param-type-mismatch
    local pattern = ("1%s%s.A%s"):format(vehicleData.make == "" and "ESX" or vehicleData.make:sub(1, 3), model:sub(1, 3), ESX.GetRandomNumber(10))
    local generatedVin = string.upper(ESX.GetRandomString(17, pattern))

    return not MySQL.scalar.await("SELECT 1 FROM `owned_vehicles` WHERE `vin` = ?", { generatedVin }) and generatedVin or Core.GenerateVin(model)
end

---Saves all vehicles for the resource and despawns them
---@param resource string?
function Core.SaveVehicles(resource)
    local parameters, pSize = {}, 0
    local vehicles, vSize = {}, 0

    if not next(Core.Vehicles) then return end

    if resource == cache.resource then resource = nil end

    for _, xVehicle in pairs(Core.Vehicles) do
        if not resource or resource == xVehicle.script then
            if (xVehicle.owner or xVehicle.group) ~= false then -- TODO: might need to remove this check as I think it's handled through xVehicle.delete()
                pSize += 1
                parameters[pSize] = { xVehicle.stored, json.encode(xVehicle.metadata), xVehicle.id }
            end

            vSize += 1
            vehicles[vSize] = xVehicle.entity
        end
    end

    if vSize > 0 then
        ESX.DeleteVehicle(vehicles)
    end

    if pSize > 0 then
        MySQL.prepare("UPDATE `owned_vehicles` SET `stored` = ?, `metadata` = ? WHERE `id` = ?", parameters)
    end
end

---Deletes the passed vehicle entity/entities
---@param vehicleEntity integer | number | table<number, number>
function ESX.DeleteVehicle(vehicleEntity)
    local _type = type(vehicleEntity)

    if _type == "table" then
        for i = 1, #vehicleEntity do
            ESX.DeleteVehicle(vehicleEntity[i])
        end

        return
    end

    if _type ~= "number" or vehicleEntity <= 0 or not DoesEntityExist(vehicleEntity) or GetEntityType(vehicleEntity) ~= 2 then
        ESX.Trace(("Tried to delete a vehicle entity (^1%s^7) that is invalid!"):format(vehicleEntity), "warning", true)
        return
    end

    local vehicle = Core.Vehicles[vehicleEntity]

    if vehicle then
        vehicle.delete()
    else
        DeleteEntity(vehicleEntity)
        Core.VehiclesPropertiesQueue[vehicleEntity] = nil
        Core.UnregisterVehiclePropertiesEvent(vehicleEntity)
    end
end

---Sets properties to the the passed vehicle entity/entities
---@param vehicleEntity integer | number | table<number, number>
---@param properties table<string, any>
function ESX.SetVehicleProperties(vehicleEntity, properties)
    if type(properties) ~= "table" or not next(properties) then return end

    local _type = type(vehicleEntity)

    if _type == "table" then
        for i = 1, #vehicleEntity do
            ESX.SetVehicleProperties(vehicleEntity[i], properties)
        end

        return
    end

    if _type ~= "number" or vehicleEntity <= 0 or not DoesEntityExist(vehicleEntity) or GetEntityType(vehicleEntity) ~= 2 then
        ESX.Trace(("Tried to set properties to a vehicle entity (^1%s^7) that is invalid!"):format(vehicleEntity), "warning", true)
        return
    end

    if not Core.VehiclesPropertiesQueue[vehicleEntity] then
        Core.VehiclesPropertiesQueue[vehicleEntity] = { properties }

        Entity(vehicleEntity).state:set("vehicleProperties", properties, true)
    elseif Core.VehiclesPropertiesQueue[vehicleEntity] then
        table.insert(Core.VehiclesPropertiesQueue[vehicleEntity], properties) -- adding the properties to the queue
    end
end

AddStateBagChangeHandler("vehicleProperties", "", function(bagName, key, value, _, _)
    if value ~= nil then return end

    local entity = GetEntityFromStateBagName(bagName)

    if not entity or entity == 0 or not Core.VehiclesPropertiesQueue[entity] then return end

    table.remove(Core.VehiclesPropertiesQueue[entity], 1) -- removing the properties that just applied from the queue

    if next(Core.VehiclesPropertiesQueue[entity]) then
        Wait(10)                                                                                                                         -- needed. if we don't have a wait here, the server's change handler will not be triggerred all the time, therefore the queue will not empty, causing the future ESX.SetVehicleProperties calls not to take in place
        return Core.VehiclesPropertiesQueue[entity]?[1] and Entity(entity).state:set(key, Core.VehiclesPropertiesQueue[entity][1], true) -- applying the next properties from the queue
        --[[
        local bagName = ("entity:%d"):format(NetworkGetNetworkIdFromEntity(entity))
        local payload = msgpack_pack(Core.VehiclesPropertiesQueue[entity][1])

        return SetStateBagValue(bagName, key, payload, payload:len(), true)
        ]]
    end

    Core.VehiclesPropertiesQueue[entity] = nil
end)

-- leave for providing backward-compatibility with legacy esx_vehicleshop
ESX.RegisterServerCallback("esx:generatePlate", function(_, cb)
    cb(Core.GeneratePlate())
end)
