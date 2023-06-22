-- The idea of this file comes from cfx-server-data's spawnmanager
-- This has be implemented inside es_extended to reduce the dependency resources...

local isSpawning = false

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

---Spawns/Revives the player with the specified data such as coords, health, model and ...
---@param spawnData table
---@param cb function
---@return function | boolean (returns boolean indicating whether the action was successful or not if cb is omitted)
local function spawnPlayer(spawnData, cb)
    if isSpawning then return false end

    isSpawning = true

    if not spawnData or type(spawnData) ~= "table" then
        isSpawning = false

        print("[^1ERROR^7] The first paramater of spawnPlayer function is invalid!")

        return false
    end

    spawnData.x = (spawnData.x and spawnData.x + 0.0) or -1
    spawnData.y = (spawnData.x and spawnData.x + 0.0) or -1
    spawnData.z = (spawnData.x and spawnData.x + 0.0) or -1
    spawnData.heading = (spawnData.heading and spawnData.heading + 0.0) or 0.0

    for key, value in pairs(spawnData) do
        if type(value) == "number" and value == -1 then
            print(("[^1ERROR^7] The key '%s' from first parameter of spawnPlayer function is invalid!"):format(key))

            return false
        end
    end

    if not spawnData.skipFade then
        DoScreenFadeOut(500)

        while not IsScreenFadedOut() do
            Wait(0)
        end
    end

    freeze(true)

    if spawnData.model then
        lib.requestModel(spawnData.model)

        SetPlayerModel(cache.playerId, spawnData.model)
        SetModelAsNoLongerNeeded(spawnData.model)
    end

    RequestCollisionAtCoord(spawnData.x, spawnData.y, spawnData.z)

    local ped = PlayerPedId()

    SetEntityCoordsNoOffset(ped, spawnData.x, spawnData.y, spawnData.z, false, false, false)
    NetworkResurrectLocalPlayer(spawnData.x, spawnData.y, spawnData.z, spawnData.heading, true, true)

    spawnData.health = spawnData.health or 200

    ClearPedTasksImmediately(ped)
    SetPedMaxHealth(ped, spawnData.health)
    SetEntityHealth(ped, spawnData.health)
    RemoveAllPedWeapons(ped, true)
    ClearPlayerWantedLevel(cache.playerId)

    local time = GetGameTimer()

    while not HasCollisionLoadedAroundEntity(ped) and (GetGameTimer() - time) < 5000 do
        Wait(0)
    end

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

    return cb and cb(spawnData) or true
end

exports("spawnPlayer", spawnPlayer)
