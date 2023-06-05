---@type table<entityId, table<number, number>>
local vehiclesPropertiesQueue = {}

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

    ---Sets the specified value to the key variable for the current vehicle
    ---@param key string
    ---@param value any
    function self.set(key, value)
        self.variables[key] = value
        Entity(self.entity).state:set(key, value, true)
    end

     ---Gets the value of the specified key variable from the current vehicle, returning the entire table if key is omitted.
    ---@param key? string
    ---@return any
    function self.get(key)
        return key and self.variables[key] or self.variables
    end

    ---Removes the current vehicle entity
    ---@param removeFromDb? boolean delete the entry from database as well or no (defaults to false if not provided and nil)
    function self.delete(removeFromDb)
        local id = self.id
        local entity = self.entity
        local netId = self.netId
        local vin = self.vin
        local plate = self.plate

        if self.owner or self.group then -- TODO: why do we need this check?
            if removeFromDb then
                MySQL.prepare("DELETE FROM `owned_vehicles` WHERE `id` = ?", { self.id })
            else
                MySQL.prepare("UPDATE `owned_vehicles` SET `stored` = ?, `metadata` = ? WHERE `id` = ?", { self.stored, json.encode(self.metadata), self.id })
            end
        end

        Core.Vehicles[entity] = nil -- maybe I should use entityRemoved event instead(but that might create race condition, no?)
        vehiclesPropertiesQueue[entity] = nil -- maybe I should use entityRemoved event instead(but that might create race condition, no?)

        if DoesEntityExist(entity) then DeleteEntity(entity) end

        TriggerEvent("esx:vehicleDeleted", id, entity, netId, vin, plate)
    end

    ---Sets the stored property for the current vehicle in database
    ---@param value? boolean
    ---@param despawn? boolean remove the vehicle entity from the game world as well or not (defaults to false if not provided and nil)
    function self.setStored(value, despawn)
        self.stored = value

        MySQL.prepare.await("UPDATE `owned_vehicles` SET `stored` = ? WHERE `id` = ?", { self.stored, self.id })

        if despawn then
            self.delete()
        end
    end

    ---Updates the current vehicle owner
    ---@param newOwner? string
    function self.setOwner(newOwner)
        self.owner = newOwner

        MySQL.prepare.await("UPDATE `owned_vehicles` SET `owner` = ? WHERE `id` = ?", { self.owner or nil --[[to make sure "false" is not being sent]], self.id })

        Entity(self.entity).state:set("owner", self.owner, true)
    end

    ---Updates the current vehicle group
    ---@param newGroup? string
    function self.setGroup(newGroup)
        self.group = newGroup

        MySQL.prepare.await("UPDATE `owned_vehicles` SET `job` = ? WHERE `id` = ?", { self.group or nil --[[to make sure "false" is not being sent]], self.id })

        Entity(self.entity).state:set("group", self.group, true)
    end

    ---May mismatch with properties due to "fake plates". Used to prevent duplicate "persistent plates".
    ---@param newPlate string
    function self.setPlate(newPlate)
        self.plate = ("%-8s"):format(newPlate)

        MySQL.prepare("UPDATE `owned_vehicles` SET `plate` = ? WHERE `id` = ?", { self.plate, self.id })

        Entity(self.entity).state:set("plate", self.plate, true)
    end

    ---Gets the current vehicle specified metadata
    ---@param index? string
    ---@param subIndex? string | table
    ---@return nil | string | table
    function self.getMetadata(index, subIndex) -- TODO: Get back to this as it looks like it won't work with all different cases (it's a copy of xPlayer.getMetadata)...
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

    ---Sets the specified metadata to the current player
    ---@param index string
    ---@param value? string | number | table
    ---@param subValue? any
    ---@return boolean
    function self.setMetadata(index, value, subValue) -- TODO: Get back to this as it looks like it won't work with all different cases (it's a copy of xPlayer.setMetadata)...
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
    -- New native seems to be missing some types, for now we will convert to known types
    -- https://github.com/citizenfx/fivem/commit/1e266a2ca5c04eb96c090de67508a3475d35d6da
    if vType == "bicycle" or vType == "quadbike" or vType == "amphibious_quadbike" then
        vType = "bike"
    elseif vType == "amphibious_automobile" or vType == "submarinecar" then
        vType = "automobile"
    elseif vType == "blimp" then
        vType = "heli"
    end

    local entity = CreateVehicleServerSetter(joaat(model), vType, coords.x, coords.y, coords.z, heading)

    if not DoesEntityExist(entity) then print(("[^1ERROR^7] Failed to spawn vehicle (^4%s^7)"):format(model)) end

    TriggerEvent("entityCreated", entity)

    local vehicle = createExtendedVehicle(id, owner, group, NetworkGetNetworkIdFromEntity(entity), entity, model, plate, vin, script, metadata)

    Core.Vehicles[vehicle.entity] = vehicle

    Entity(entity).state:set("initVehicle", true, true)

    ESX.SetVehicleProperties(entity, properties)

    if owner or group then vehicle.setStored(false) end

    TriggerEvent("esx:vehicleCreated", vehicle.id, vehicle, vehicle.entity, vehicle.netId)

    return vehicle
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

        local vehicle = MySQL.prepare.await(("SELECT `owner`, `job`, `plate`, `vin`, `model`, `vehicle`, `metadata` FROM `owned_vehicles` WHERE `id` = ? %s"):format(not forceSpawn and "AND `stored` = 1" or ""), { data })

        if not vehicle then
            print(("[^1ERROR^7] Failed to spawn vehicle with id  (invalid id %s)"):format(not forceSpawn and "or already spawned" or "", data)) return
        end

        vehicle.vehicle = json.decode(vehicle.vehicle --[[@as string]])
        vehicle.metadata = json.decode(vehicle.metadata --[[@as string]])

        if not vehicle.vin or not vehicle.metadata or not vehicle.model then -- probably first time spawning the vehicle after migrating from esx-legacy
            local vehicleData = nil

            for vModel, vData in pairs(ESX.GetVehicleData()) do

                if vData.hash == vehicle.vehicle?.model then
                    vehicleData = {model = vModel, data = vData}
                    break
                end
            end

            if not vehicleData then print(("[^1ERROR^7] Vehicle model hash (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(vehicle.vehicle?.model)) return end

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `vin` = ?, `model` = ?, `class` = ?, `metadata` = ? WHERE `id` = ?", {
                vehicle.vin or ESX.GenerateVin(vehicleData.model),
                vehicle.model or vehicleData.model,
                vehicleData.data?.class,
                vehicle.metadata and json.encode(vehicle.metadata) or "{}",
                data
            })

            return ESX.CreateVehicle(data, coords, heading, forceSpawn)
        end

        local modelData = ESX.GetVehicleData(vehicle.model) --[[@as VehicleData]]

        if not modelData then
            print(("[^1ERROR^7] Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(vehicle.model)) return
        end

        return spawnVehicle(data, vehicle.owner, vehicle.group, vehicle.plate, vehicle.vin, vehicle.model, script, vehicle.metadata, coords, heading, modelData.type, vehicle.vehicle)
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
    local plate = ESX.GeneratePlate()
    local vin = ESX.GenerateVin(model)
    local metadata = {}
    local vehicleProperties = data.properties or {}

    vehicleProperties.plate = plate
    vehicleProperties.model = modelData.hash -- backward compatibility with esx-legacy

    local vehicleId = (owner or group) and MySQL.prepare.await("INSERT INTO `owned_vehicles` (`plate`, `vin`, `vehicle`, `owner`, `job`, `model`, `class`, `metadata`, `stored`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", {
        plate, vin, json.encode(vehicleProperties), owner or nil, group or nil, model, modelData.class, json.encode(metadata), stored
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
function ESX.GeneratePlate()
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
function ESX.GenerateVin(model)
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
        vehiclesPropertiesQueue[vehicleEntity] = nil
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

    if not vehiclesPropertiesQueue[vehicleEntity] then
        vehiclesPropertiesQueue[vehicleEntity] = {}

        table.insert(vehiclesPropertiesQueue[vehicleEntity], properties)

        Entity(vehicleEntity).state:set("vehicleProperties", vehiclesPropertiesQueue[vehicleEntity][1], true)
    elseif vehiclesPropertiesQueue[vehicleEntity] then
        table.insert(vehiclesPropertiesQueue[vehicleEntity], properties) -- adding the properties to the queue
    end
end

AddStateBagChangeHandler("initVehicle", "", function(bagName, key, value, _, _)
    if not value then return end -- TODO: check if peds are still appearing in vehicles and are not being deleted, changing this to "value ~= nil" might fix it...

    local entity = GetEntityFromStateBagName(bagName)

    if not entity or entity == 0 then return end

    local doesEntityExist, timeout = false, 0

    while not doesEntityExist and timeout < 1000 do
        doesEntityExist = DoesEntityExist(entity)
        timeout += 1
        Wait(0)
    end

    if not doesEntityExist then print(("[^3WARNING^7] Statebag (%s) timed out after waiting %s ticks for entity creation on %s!"):format(bagName, timeout, key)) return end

    -- workaround for server-vehicles that exist in traffic randomly creating peds
    -- https://forum.cfx.re/t/sometimes-an-npc-spawns-inside-an-vehicle-spawned-with-createvehicleserversetter-or-create-automobile/4947251
    for i = -1, 0 do
        local ped = GetPedInVehicleSeat(entity, i)

        if not IsPedAPlayer(ped) then
            DeleteEntity(ped)
        end
    end
end)

AddStateBagChangeHandler("vehicleProperties", "", function(bagName, key, value, _, _)
    if value ~= nil then return end

    local entity = GetEntityFromStateBagName(bagName)

    if not entity or entity == 0 or not vehiclesPropertiesQueue[entity] then return end

    table.remove(vehiclesPropertiesQueue[entity], 1) -- removing the properties that just applied from the queue 

    if next(vehiclesPropertiesQueue[entity]) then
        return Entity(entity).state:set(key, vehiclesPropertiesQueue[entity][1]) -- applying the next properties from the queue
        --[[
        local bagName = ("entity:%d"):format(NetworkGetNetworkIdFromEntity(entity))
        local payload = msgpack_pack(vehiclesPropertiesQueue[entity][1])

        return SetStateBagValue(bagName, key, payload, payload:len(), true)
        ]]
    end

    vehiclesPropertiesQueue[entity] = nil
end)