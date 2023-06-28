ESX.OneSync = {}

---@param source number | vector3 playerId or vector3 coordinates
---@param closest boolean
---@param distance? integer | number defaults to 100 if omitted
---@param ignore? table playerIds to ignore, where the key is playerId and value is true
---@return table, integer | number
local function getNearbyPlayers(source, closest, distance, ignore)
    local nearbyPlayersId, count = {}, 0

    source = type(source) == "number" and GetEntityCoords(GetPlayerPed(source)) or vector3(source.x, source.y, source.z) --[[@as vector3]]
    distance = type(distance) == "number" and distance or 100

    for _, xPlayer in pairs(ESX.Players) do
        if not ignore or not ignore[xPlayer.source] then
            local playerPed = GetPlayerPed(xPlayer.source)
            local playerCoords = GetEntityCoords(playerPed)
            local dist = #(source - playerCoords)

            if closest then
                if dist <= (nearbyPlayersId.dist or distance) then
                    count = 1
                    nearbyPlayersId = { id = xPlayer.source, entity = playerPed, ped = NetworkGetNetworkIdFromEntity(playerPed), coords = playerCoords, dist = dist }
                end
            else
                if dist <= distance then
                    count += 1
                    nearbyPlayersId[count] = { id = xPlayer.source, entity = playerPed, ped = NetworkGetNetworkIdFromEntity(playerPed), coords = playerCoords, dist = dist }
                end
            end
        end
    end

    return nearbyPlayersId, count
end

---@param source vector3 | number playerId or vector3 coordinates
---@param maxDistance? number defaults to 100 if omitted
---@param ignore? table playerIds to ignore, where the key is playerId and value is true
---@return table, integer | number
function ESX.OneSync.GetPlayersInArea(source, maxDistance, ignore)
    return getNearbyPlayers(source, false, maxDistance, ignore)
end

---@param source vector3 | number playerId or vector3 coordinates
---@param maxDistance? number defaults to 100 if omitted
---@param ignore? table playerIds to ignore, where the key is playerId and value is true
---@return table, integer | number
function ESX.OneSync.GetClosestPlayer(source, maxDistance, ignore)
    return getNearbyPlayers(source, true, maxDistance, ignore)
end

---@param model number | string
---@param coords vector3 | table
---@param heading? number
---@param properties? table
---@param cb? function
function ESX.OneSync.SpawnVehicle(model, coords, heading, properties, cb)
    local typeModel = type(model)

    if typeModel ~= "string" and typeModel ~= "number" then
        print(("[^1ERROR^7] Invalid type of model (^1%s^7) in ^5ESX.OneSync.SpawnVehicle^7!"):format(typeModel)) return
    end

    if typeModel == "number" or type(tonumber(model)) == "number" then
        typeModel = "number"
        model = tonumber(model) --[[@as number]]

        for vModel, vData in pairs(ESX.GetVehicleData()) do
            if vData.hash == model then
                model = vModel
                break
            end
        end
    end

    model = typeModel == "string" and model:lower() or model --[[@as string]]
    local modelData = ESX.GetVehicleData(model) --[[@as VehicleData]]

    if not modelData then
        print(("[^1ERROR^7] Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(model)) return
    end

    local entity = Core.SpawnVehicle(model, modelData.type, coords, heading or coords.w or coords.heading or 0.0)

    if not entity then return end

    Entity(entity).state:set("initVehicle", true, true)
    Entity(entity).state:set("vehicleProperties", properties, true)

    return cb and cb(NetworkGetNetworkIdFromEntity(entity))
end

---@param model number | string
---@param coords vector3 | table
---@param heading number
---@param cb? function
function ESX.OneSync.SpawnObject(model, coords, heading, cb)
    model = type(model) == "string" and joaat(model) or model --[[@as number]]
    coords = type(coords) == "vector3" and coords or vector3(coords.x, coords.y, coords.z)

    local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    local doesEntityExist, timeout = false, 0

    while not doesEntityExist and timeout < 1000 do
        doesEntityExist = DoesEntityExist(entity)
        timeout += 1
        Wait(0)
    end

    if not doesEntityExist then return print(("[^3WARNING^7] Spawning (^3%s^7) timed out after waiting %s ticks for object creation!"):format(entity, timeout)) end

    SetEntityHeading(entity, heading or 0.0)

    return cb and cb(NetworkGetNetworkIdFromEntity(entity))
end

---@param model number | string
---@param coords vector3 | table
---@param heading number
---@param cb? function
function ESX.OneSync.SpawnPed(model, coords, heading, cb)
    model = type(model) == "string" and joaat(model) or model --[[@as number]]
    coords = type(coords) == "vector3" and coords or vector3(coords.x, coords.y, coords.z)

    local entity = CreatePed(0, model, coords.x, coords.y, coords.z, heading or 0.0, true, true)
    local doesEntityExist, timeout = false, 0

    while not doesEntityExist and timeout < 1000 do
        doesEntityExist = DoesEntityExist(entity)
        timeout += 1
        Wait(0)
    end

    if not doesEntityExist then return print(("[^3WARNING^7] Spawning (^3%s^7) timed out after waiting %s ticks for ped creation!"):format(entity, timeout)) end

    return cb and cb(NetworkGetNetworkIdFromEntity(entity))
end

---@param model number | string
---@param vehicle number entityId
---@param seat number
---@param cb? function
function ESX.OneSync.SpawnPedInVehicle(model, vehicle, seat, cb)
    model = type(model) == "string" and joaat(model) or model --[[@as number]]

    local entity = CreatePedInsideVehicle(vehicle, 1, model, seat, true, true)
    local doesEntityExist, timeout = false, 0

    while not doesEntityExist and timeout < 1000 do
        doesEntityExist = DoesEntityExist(entity)
        timeout += 1
        Wait(0)
    end

    if not doesEntityExist then return print(("[^3WARNING^7] Spawning ped in vehicle (^3%s^7) timed out after waiting %s ticks for ped creation!"):format(entity, timeout)) end

    return cb and cb(NetworkGetNetworkIdFromEntity(entity))
end

---@param entities table<number, number>
---@param coords playerId | vector3
---@param modelFilter? string | table<number, true>
---@param maxDistance? integer | number
---@param isPed? boolean
---@return table<number, number>, table<number, number>, integer | number
local function getNearbyEntities(entities, coords, modelFilter, maxDistance, isPed)
    local nearbyEntities, nearbyNetIds, count = {}, {}, 0

    coords = type(coords) == "number" and GetEntityCoords(GetPlayerPed(coords)) or vector3(coords.x, coords.y, coords.z)

    for i = 1, #entities do
        local entity = entities[i]

        if not isPed or (isPed and not IsPedAPlayer(entity)) then
            if not modelFilter or modelFilter == GetEntityModel(entity) or modelFilter?[GetEntityModel(entity)] then
                local entityCoords = GetEntityCoords(entity)
                local distance = #(coords - entityCoords)

                if not maxDistance or distance <= maxDistance then
                    count += 1
                    nearbyEntities[count] = entity
                    nearbyNetIds[count] = NetworkGetNetworkIdFromEntity(entity)
                end
            end
        end
    end

    return nearbyNetIds, nearbyEntities, count
end

---@param coords playerId | vector3
---@param modelFilter? string | table<number, true> models to check for. if table provided, the key is the model hash and the value is true
---@param maxDistance? integer | number
---@return table<number, number>, table<number, number>, integer | number
function ESX.OneSync.GetPedsInArea(coords, maxDistance, modelFilter)
    return getNearbyEntities(GetAllPeds(), coords, modelFilter, maxDistance, true)
end

---@param coords playerId | vector3
---@param modelFilter? string | table<number, true> models to check for. if table provided, the key is the model hash and the value is true
---@param maxDistance? integer | number
---@return table<number, number>, table<number, number>, integer | number
function ESX.OneSync.GetObjectsInArea(coords, maxDistance, modelFilter)
    return getNearbyEntities(GetAllObjects(), coords, modelFilter, maxDistance)
end

---@param coords playerId | vector3
---@param modelFilter? string | table<number, true> models to check for. if table provided, the key is the model hash and the value is true
---@param maxDistance? integer | number
---@return table<number, number>, table<number, number>, integer | number
function ESX.OneSync.GetVehiclesInArea(coords, maxDistance, modelFilter)
    return getNearbyEntities(GetAllVehicles(), coords, modelFilter, maxDistance) ---@diagnostic disable-line: param-type-mismatch
end

local function getClosestEntity(entities, coords, modelFilter, isPed)
    local distance, closestEntity, closestCoords = 100, nil, nil
    coords = type(coords) == "number" and GetEntityCoords(GetPlayerPed(coords)) or vector3(coords.x, coords.y, coords.z)

    for _, entity in pairs(entities) do
        if not isPed or (isPed and not IsPedAPlayer(entity)) then
            if not modelFilter or modelFilter[GetEntityModel(entity)] then
                local entityCoords = GetEntityCoords(entity)
                local dist = #(coords - entityCoords)

                if dist < distance then
                    closestEntity, distance, closestCoords = entity, dist, entityCoords
                end
            end
        end
    end

    return NetworkGetNetworkIdFromEntity(closestEntity), distance, closestCoords
end

---@param coords vector3
---@param modelFilter table models to ignore, where the key is the model hash and the value is true
---@return number entityId, number distance, vector3 coords
function ESX.OneSync.GetClosestPed(coords, modelFilter)
    return getClosestEntity(GetAllPeds(), coords, modelFilter, true)
end

---@param coords vector3
---@param modelFilter table models to ignore, where the key is the model hash and the value is true
---@return number entityId, number distance, vector3 coords
function ESX.OneSync.GetClosestObject(coords, modelFilter)
    return getClosestEntity(GetAllObjects(), coords, modelFilter)
end

---@param coords vector3
---@param modelFilter table models to ignore, where the key is the model hash and the value is true
---@return number entityId, number distance, vector3 coords
function ESX.OneSync.GetClosestVehicle(coords, modelFilter)
    return getClosestEntity(GetAllVehicles(), coords, modelFilter)
end

ESX.RegisterServerCallback("esx:Onesync:SpawnObject", function(_, cb, model, coords, heading)
    ESX.OneSync.SpawnObject(model, coords, heading, cb)
end)
