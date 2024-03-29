-- The idea of this file comes from cfx-server-data's spawnmanager
-- This has be implemented inside es_extended to reduce the dependency resources...

local isSpawning = false
local api = setmetatable({}, {
    __newindex = function(self, index, value)
        exports(index, value)
        rawset(self, index, value)
    end
})

---Freeze/Unfreezes the player
---@param state boolean
local function freeze(state)
    SetPlayerControl(cache.playerId, not state, false) ---@diagnostic disable-line: param-type-mismatch

    local playerPed = GetPlayerPed(cache.playerId)

    SetEntityVisible(playerPed, not state, false)
    SetEntityCollision(playerPed, not state, true)
    FreezeEntityPosition(playerPed, state)
    SetPlayerInvincible(cache.playerId, state)

    ClearPedTasksImmediately(playerPed)
end

---Spawns the player with the specified data such as coords, health, model and ...
---@param spawnData table
---@param cb function
---@return boolean (whether the action was successful or not)
function api.spawnPlayer(spawnData, cb)
    if isSpawning then return false end

    isSpawning = true

    if type(spawnData) ~= "table" then
        isSpawning = false

        ESX.Trace("The first paramater of spawnPlayer function is invalid!", "error", true)

        return false
    end

    spawnData.x = (type(spawnData.y) == "number" and spawnData.x + 0.0) or -1
    spawnData.y = (type(spawnData.y) == "number" and spawnData.y + 0.0) or -1
    spawnData.z = (type(spawnData.z) == "number" and spawnData.z + 0.0) or -1
    spawnData.heading = (spawnData.heading and spawnData.heading + 0.0) or 0.0

    for key, value in pairs(spawnData) do
        if type(value) == "number" and value == -1 then
            ESX.Trace(("The key '%s' from first parameter of spawnPlayer function is invalid!"):format(key), "error", true)

            return false
        end
    end

    freeze(true)

    if spawnData.model then
        spawnData.model = type(spawnData.model) == "string" and joaat(spawnData.model) or spawnData.model

        lib.requestModel(spawnData.model, 100000)

        SetPlayerModel(cache.playerId, spawnData.model)
        SetModelAsNoLongerNeeded(spawnData.model)
    end

    RequestCollisionAtCoord(spawnData.x, spawnData.y, spawnData.z)

    local ped = PlayerPedId()

    SetEntityCoordsNoOffset(ped, spawnData.x, spawnData.y, spawnData.z, false, false, false)
    NetworkResurrectLocalPlayer(spawnData.x, spawnData.y, spawnData.z, spawnData.heading, true, true)

    ped = PlayerPedId()
    local time = GetGameTimer()

    while not HasCollisionLoadedAroundEntity(ped) and (GetGameTimer() - time) < 5000 do
        Wait(0)
    end

    spawnData.health = spawnData.health or 200

    ClearPedTasksImmediately(ped)
    SetPedMaxHealth(ped, spawnData.health)
    SetEntityHealth(ped, spawnData.health)
    RemoveAllPedWeapons(ped, true)
    ClearPlayerWantedLevel(cache.playerId)
    ShutdownLoadingScreen()

    if IsScreenFadedOut() then
        DoScreenFadeIn(500)

        while not IsScreenFadedIn() do
            Wait(0)
        end
    end

    freeze(false)

    TriggerEvent("esx:onPlayerSpawn", spawnData)

    isSpawning = false

    if cb then CreateThread(function() cb(spawnData) end) end

    return true
end

---Checks if another spawn is not already in the progress
---@return boolean
function api.canSpawnPlayer()
    return isSpawning == false
end
