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
    self.metadata = vehicleData or {}

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

        ESX.Vehicles[entity] = nil -- maybe I should use entityRemoved event instead(but that might create race condition, no?)
        DeleteEntity(entity)

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

        self.set("owner", newOwner)
    end

    ---Updates the current vehicle group
    ---@param newGroup? string
    function self.setGroup(newGroup)
        self.group = newGroup

        MySQL.prepare.await("UPDATE `owned_vehicles` SET `job` = ? WHERE `id` = ?", { self.group or nil --[[to make sure "false" is not being sent]], self.id })

        self.set("group", newGroup)
    end

    ---May mismatch with properties due to "fake plates". Used to prevent duplicate "persistent plates".
    ---@param newPlate string
    function self.setPlate(newPlate)
        self.plate = ("%-8s"):format(newPlate)

        MySQL.prepare("UPDATE `owned_vehicles` SET `plate` = ? WHERE `id` = ?", { self.plate, self.id })

        self.set("plate", newPlate)
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

    if not DoesEntityExist(entity) then print(("^1Failed to spawn vehicle '%s'^0"):format(model)) end

    local vehicle = createExtendedVehicle(id, owner, group, NetworkGetNetworkIdFromEntity(entity), entity, model, plate, vin, script, metadata)

    ESX.Vehicles[vehicle.entity] = vehicle

    local stateBag = Entity(entity).state

    stateBag:set("initVehicle", true, true)
    vehicle.set("owner", owner)
    stateBag:set("vehicleProperties", properties, true)

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

            MySQL.prepare.await("UPDATE `owned_vehicles` SET `vin` = ?, `model` = ?, `class` = ?, `metadata` = ? FROM `owned_vehicles` WHERE `id` = ? %s", {
                vehicle.vin or ESX.GenerateVin(vehicleData.model),
                vehicle.model or vehicleData.model,
                vehicle.class or vehicleData.class,
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

    if typeModel ~= "string" then
        print(("[^1ERROR^7] Invalid type of data.model (^1%s^7) in ^5ESX.CreateVehicle^7!"):format(typeModel)) return
    end

    local model = data.model:lower()
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

---Returns an instance of xVehicle for the given entityId.
---@param entityId number | integer
---@return xVehicle?
function ESX.GetVehicle(entityId)
    return ESX.Vehicles[entityId]
end

---Return all vehicle data.
---@return xVehicle[]
function ESX.GetVehicles()
    local size = 0
    local vehicles = {}

    for _, v in pairs(ESX.Vehicles) do
        size += 1
        vehicles[size] = v
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

