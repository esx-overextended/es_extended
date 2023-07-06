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
---@return xVehicle
local function createExtendedVehicle(vehicleId, vehicleOwner, vehicleGroup, vehicleNetId, vehicleEntity, vehicleModel, vehiclePlate, vehicleVin, vehicleScript, vehicleMetadata)
    ---@type xVehicle
    local self = {}

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

    local stateBag = Entity(self.entity).state

    stateBag:set("id", self.id, true)
    stateBag:set("owner", self.owner, true)
    stateBag:set("group", self.group, true)
    stateBag:set("model", self.model, true)
    stateBag:set("plate", self.plate, true)
    stateBag:set("vin", self.vin, true)
    stateBag:set("metadata", self.metadata, true)

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

    local xVehicle = createExtendedVehicle(id, owner, group, NetworkGetNetworkIdFromEntity(entity), entity, model, plate, vin, script, metadata)

    Core.Vehicles[xVehicle.entity] = xVehicle

    Core.TriggerEventHooks("onVehicleCreate", { xVehicle = xVehicle })

    Entity(entity).state:set("initVehicle", true, true)

    ESX.SetVehicleProperties(entity, properties)

    if owner or group then xVehicle.setStored(false) end

    TriggerEvent("esx:vehicleCreated", xVehicle.entity, xVehicle.netId, xVehicle)

    return xVehicle
end

---Gets a vehicle model type based on esx-legacy (used in DB column to keep backward-compatibility)
---@param modelName string
---@param modelType? string
local function getVehicleTypeFromModel(modelName, modelType)
    modelType = modelType or ESX.GetVehicleData(modelName)?.type --[[@as string]]

    if modelType == "automobile" then return "car"
    elseif modelType == "bike" then return "bike"
    elseif modelType == "quadbike" then return "bike"
    elseif modelType == "heli" then return "heli"
    elseif modelType == "plane" then return "plane"
    elseif modelType == "trailer" then return "trailer"
    elseif modelType == "boat" then return "boat"
    else return modelType end
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

    if not DoesEntityExist(entity) then return print(("[^1ERROR^7] Failed to spawn vehicle (^4%s^7)"):format(modelName)) end

    TriggerEvent("entityCreated", entity)

    return entity
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

    if typeData ~= "number" and typeData ~= "table" then print(("[^1ERROR^7] Invalid type of data (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeData)) return end

    if typeData == "number" then
        local typeCoords = type(coords)

        if typeCoords == "table" then
            if not coords[1] or not coords[2] or not coords[3] then
                print(("[^1ERROR^7] Invalid type of coords (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeCoords)) return
            end

            coords = vector3(coords[1], coords[2], coords[3])
            heading = heading or coords[4]
        elseif typeCoords == "vector4" then
            coords = vector3(coords.x, coords.y, coords.z)
            heading = heading or coords.w
        elseif typeCoords ~= "vector3" then
            print(("[^1ERROR^7] Invalid type of coords (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeCoords)) return
        end

        heading = heading or 0.0

        local vehicle = MySQL.prepare.await(("SELECT `owner`, `job`, `plate`, `vin`, `model`, `class`, `vehicle`, `metadata` FROM `owned_vehicles` WHERE `id` = ? %s"):format(not forceSpawn and "AND `stored` = 1" or ""), { data })

        if not vehicle then
            print(("[^1ERROR^7] Failed to spawn vehicle with id %s (invalid id%s)"):format(data, not forceSpawn and " or already spawned" or "")) return
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

            if not vehicleData then print(("[^1ERROR^7] Vehicle model hash (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(vehicle.vehicle?.model)) return end

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `vin` = ?, `model` = ?, `class` = ?, `metadata` = ? WHERE `id` = ?", {
                vehicle.vin or Core.GenerateVin(vehicleData.model),
                vehicle.model or vehicleData.model,
                vehicle.class or vehicleData.data?.class,
                vehicle.metadata and json.encode(vehicle.metadata) or "{}",
                data
            })

            return ESX.CreateVehicle(data, coords, heading, forceSpawn)
        end

        local modelData = ESX.GetVehicleData(vehicle.model) --[[@as VehicleData]]

        if not modelData then
            print(("[^1ERROR^7] Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(vehicle.model)) return
        end

        return spawnVehicle(data, vehicle.owner, vehicle.job, vehicle.plate, vehicle.vin, vehicle.model, script, vehicle.metadata, coords, heading, modelData.type, vehicle.vehicle)
    end

    local typeModel = type(data.model)

    if typeModel ~= "string" and typeModel ~= "number" then
        print(("[^1ERROR^7] Invalid type of data.model (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeModel)) return
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
        print(("[^1ERROR^7] Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(model)) return
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
        owner or nil, plate, vin, json.encode(vehicleProperties), getVehicleTypeFromModel(model, modelData.type), group or nil, model, modelData.class, json.encode(metadata), stored
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

local math_random = math.random

local function getNumber()
    return math_random(0, 9)
end

local function getLetter()
    return string.char(math_random(65, 90))
end

local function getAlphanumeric()
    return math_random(0, 1) == 1 and getLetter() or getNumber()
end

local plateFormat = string.upper(Config.PlatePattern)
local formatLen = #plateFormat

---Creates a unique vehicle plate.
---@return string
function Core.GeneratePlate()
    local plate = table.create(8, 0)

    while true do
        local tableLen = 1

        for i = 1, formatLen do
            local char = plateFormat:sub(i, i)

            if char == "1" then
                plate[tableLen] = getNumber()
            elseif char == "A" then
                plate[tableLen] = getLetter()
            elseif char == "." then
                plate[tableLen] = getAlphanumeric()
            elseif char == "^" then
                i += 1
                plate[tableLen] = plateFormat:sub(i, i)
            else
                plate[tableLen] = char
            end

            tableLen += 1

            if tableLen == 9 then
                break
            end
        end

        if tableLen < 9 then
            for i = tableLen, 8 do
                plate[i] = " "
            end
        end

        local str = table.concat(plate)

        if not MySQL.scalar.await("SELECT 1 FROM `owned_vehicles` WHERE `plate` = ?", { str }) then return str end
    end
end

---Creates a unique vehicle vin number.
---@param model string
---@return string
function Core.GenerateVin(model)
    local vehicle = ESX.GetVehicleData(model:lower())
    local arr = {
        math_random(1, 9),
        vehicle.make == "" and "ESX" or vehicle.make:sub(1, 2):upper(), ---@diagnostic disable-line: param-type-mismatch
        model:sub(1, 2):upper(),
        getAlphanumeric(),
        string.char(math_random(65, 90)),
    }

    while true do
        ---@diagnostic disable-next-line: param-type-mismatch
        arr[6] = os.time(os.date("!*t"))
        local vin = table.concat(arr)

        if not MySQL.scalar.await("SELECT 1 FROM `owned_vehicles` WHERE `vin` = ?", { vin }) then return vin end
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
        print(("[^3WARNING^7] Tried to delete a vehicle entity (^1%s^7) that is invalid!"):format(vehicleEntity))
        return
    end

    local vehicle = Core.Vehicles[vehicleEntity]

    if vehicle then
        vehicle.delete()
    else
        DeleteEntity(vehicleEntity)
        Core.VehiclesPropertiesQueue[vehicleEntity] = nil
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
        print(("[^3WARNING^7] Tried to set properties to a vehicle entity (^1%s^7) that is invalid!"):format(vehicleEntity))
        return
    end

    if not Core.VehiclesPropertiesQueue[vehicleEntity] then
        Core.VehiclesPropertiesQueue[vehicleEntity] = { properties }

        Entity(vehicleEntity).state:set("vehicleProperties", properties, true)
    elseif Core.VehiclesPropertiesQueue[vehicleEntity] then
        table.insert(Core.VehiclesPropertiesQueue[vehicleEntity], properties) -- adding the properties to the queue
    end
end

AddStateBagChangeHandler("initVehicle", "", function(bagName, _, value, _, _)
    if value ~= nil then return end

    local entity = GetEntityFromStateBagName(bagName)

    if not entity or entity == 0 then return end

    -- workaround for server-vehicles that exist in traffic randomly creating peds
    -- https://forum.cfx.re/t/sometimes-an-npc-spawns-inside-an-vehicle-spawned-with-createvehicleserversetter-or-create-automobile/4947251
    for i = -1, 0 do
        if DoesEntityExist(entity) then
            local ped = GetPedInVehicleSeat(entity, i)

            if not IsPedAPlayer(ped) then
                DeleteEntity(ped)
            end
        end
    end
end)

AddStateBagChangeHandler("vehicleProperties", "", function(bagName, key, value, _, _)
    if value ~= nil then return end

    local entity = GetEntityFromStateBagName(bagName)

    if not entity or entity == 0 or not Core.VehiclesPropertiesQueue[entity] then return end

    table.remove(Core.VehiclesPropertiesQueue[entity], 1) -- removing the properties that just applied from the queue

    if next(Core.VehiclesPropertiesQueue[entity]) then
        Wait(10) -- needed. if we don't have a wait here, the server's change handler will not be triggerred all the time, therefore the queue will not empty, causing the future ESX.SetVehicleProperties calls not to take in place
        return Core.VehiclesPropertiesQueue[entity]?[1] and Entity(entity).state:set(key, Core.VehiclesPropertiesQueue[entity][1], true) -- applying the next properties from the queue
        --[[
        local bagName = ("entity:%d"):format(NetworkGetNetworkIdFromEntity(entity))
        local payload = msgpack_pack(Core.VehiclesPropertiesQueue[entity][1])

        return SetStateBagValue(bagName, key, payload, payload:len(), true)
        ]]
    end

    Core.VehiclesPropertiesQueue[entity] = nil
end)