-- This file is a slightly modified version of FiveM's official spawnmanager (https://github.com/citizenfx/cfx-server-data/blob/master/resources/%5Bmanagers%5D/spawnmanager/spawnmanager.lua)
-- This has be re-done inside es_extended to reduce the dependency resources...

local spawnLock = false

local function freezePlayer(playerId, freeze)
    SetPlayerControl(playerId, not freeze, false) ---@diagnostic disable-line: param-type-mismatch

    local playerPed = GetPlayerPed(playerId)

    SetEntityVisible(playerPed, not freeze, false)
    SetEntityCollision(playerPed, not freeze, true)
    FreezeEntityPosition(playerPed, freeze)
    SetPlayerInvincible(playerId, freeze)

    ClearPedTasksImmediately(playerPed)
end

local function spawnPlayer(spawnIdx, cb)
    if spawnLock then return end

    spawnLock = true

    CreateThread(function()
        if not spawnIdx or type(spawnIdx) ~= "table" then
            spawnLock = false

            Citizen.Trace("first paramater of spawnPlayer function is invalid\n")

            return false
        end

        local spawn = spawnIdx

        spawn.x = spawn.x + 0.0
        spawn.y = spawn.y + 0.0
        spawn.z = spawn.z + 0.0

        spawn.heading = spawn.heading and (spawn.heading + 0.0) or 0.0

        if not spawn.skipFade then
            DoScreenFadeOut(500)

            while not IsScreenFadedOut() do
                Wait(0)
            end
        end

        freezePlayer(cache.playerId, true)

        if spawn.model then
            lib.requestModel(spawn.model)

            SetPlayerModel(cache.playerId, spawn.model)
            SetModelAsNoLongerNeeded(spawn.model)
        end

        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)

        local ped = PlayerPedId()

        SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false)

        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.heading, true, true)

        ClearPedTasksImmediately(ped)
        SetEntityHealth(ped, spawn.health or 300)
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

        freezePlayer(cache.playerId, false)

        TriggerEvent("esx:onPlayerSpawn", spawn)

        if cb then
            cb(spawn)
        end

        spawnLock = false

        return true
    end)
end

exports("spawnPlayer", spawnPlayer)
