local pickups = {}

CreateThread(function()
    while not Config.Multichar do
        Wait(100)

        if NetworkIsPlayerActive(PlayerId()) then
            DoScreenFadeOut(0)
            Wait(500)
            TriggerServerEvent("esx:onPlayerJoined")
            break
        end
    end
end)

AddEventHandler("esx:playerLoaded", function(xPlayer, isNew, skin)
    ESX.PlayerData = xPlayer
    ESX.PlayerLoaded = true

    if not Config.Multichar then
        Core.ResourceExport:spawnPlayer({
            x = ESX.PlayerData.coords.x,
            y = ESX.PlayerData.coords.y,
            z = ESX.PlayerData.coords.z + 0.25,
            heading = ESX.PlayerData.coords.heading,
            model = `mp_m_freemode_01`
        })

        TriggerServerEvent("esx:onPlayerSpawn")

        TriggerEvent("esx:onPlayerSpawn")
        TriggerEvent("esx:restoreLoadout")

        if isNew then
            TriggerEvent("skinchanger:loadDefaultModel", skin.sex == 0)
        elseif skin then
            TriggerEvent("skinchanger:loadSkin", skin)
        end

        TriggerEvent("esx:loadingScreenOff")

        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
    end

    SetDefaultVehicleNumberPlateTextPattern(-1, Config.CustomAIPlates)

    Core.StartServerSyncLoop()
    Core.StartDroppedItemsLoop()
end)

AddEventHandler("esx:onPlayerLogout", function()
    ESX.PlayerLoaded = false
end)

AddEventHandler("esx:setMaxWeight", function(newMaxWeight)
    ESX.SetPlayerData("maxWeight", newMaxWeight)
end)

local function onPlayerSpawn()
    ESX.SetPlayerData("ped", PlayerPedId())
    ESX.SetPlayerData("dead", false)
end

AddEventHandler("playerSpawned", onPlayerSpawn)
AddEventHandler("esx:onPlayerSpawn", onPlayerSpawn)

AddEventHandler("esx:onPlayerDeath", function()
    ESX.SetPlayerData("ped", PlayerPedId())
    ESX.SetPlayerData("dead", true)
end)

AddEventHandler("skinchanger:modelLoaded", function()
    while not ESX.PlayerLoaded do Wait(100) end

    TriggerEvent("esx:restoreLoadout")
end)

AddEventHandler("esx:restoreLoadout", function()
    if Config.OxInventory or not ESX.PlayerData.loadout then return end

    local ammoTypes = {}
    RemoveAllPedWeapons(ESX.PlayerData.ped, true)

    for _, v in ipairs(ESX.PlayerData.loadout) do
        local weaponName = v.name
        local weaponHash = joaat(weaponName)

        GiveWeaponToPed(ESX.PlayerData.ped, weaponHash, 0, false, false)
        SetPedWeaponTintIndex(ESX.PlayerData.ped, weaponHash, v.tintIndex)

        local ammoType = GetPedAmmoTypeFromWeapon(ESX.PlayerData.ped, weaponHash)

        for _, v2 in ipairs(v.components) do
            local componentHash = ESX.GetWeaponComponent(weaponName, v2).hash
            GiveWeaponComponentToPed(ESX.PlayerData.ped, weaponHash, componentHash)
        end

        if not ammoTypes[ammoType] then
            AddAmmoToPed(ESX.PlayerData.ped, weaponHash, v.ammo)
            ammoTypes[ammoType] = true
        end
    end
end)

AddEventHandler("esx:setAccountMoney", function(account)
    local accounts = {} -- creating a new table to remove references to ESX.PlayerData.accounts is required for ESX.SetPlayerData to send the old value through its event properly

    for i = 1, #(ESX.PlayerData.accounts) do
        if ESX.PlayerData.accounts[i].name == account.name then
            accounts[i] = account
        else
            accounts[i] = table.clone(ESX.PlayerData.accounts[i])
        end
    end

    ESX.SetPlayerData("accounts", accounts)
end)

AddEventHandler("esx:setMetadata", function(metadata)
    ESX.SetPlayerData("metadata", metadata)
end)

AddEventHandler("onClientResourceStart", function(resource)
    if resource ~= cache.resource or Config.OxInventory then return end

    local function setObjectProperties(entity, pickupId, coords, label)
        SetEntityAsMissionEntity(entity, true, false)
        PlaceObjectOnGroundProperly(entity)
        FreezeEntityPosition(entity, true)
        SetEntityCollision(entity, false, true)

        pickups[pickupId] = {
            obj = entity,
            label = label,
            inRange = false,
            coords = vector3(coords.x, coords.y, coords.z)
        }
    end

    AddEventHandler("esx:createPickup", function(pickupId, label, coords, type, name, components, tintIndex)
        if type == "item_weapon" then
            local weaponHash = joaat(name)
            ESX.Streaming.RequestWeaponAsset(weaponHash)
            local pickupObject = CreateWeaponObject(weaponHash, 50, coords.x, coords.y, coords.z, true, 1.0, 0)
            SetWeaponObjectTintIndex(pickupObject, tintIndex)

            for _, v in ipairs(components) do
                local component = ESX.GetWeaponComponent(name, v)
                GiveWeaponComponentToWeaponObject(pickupObject, component.hash)
            end

            setObjectProperties(pickupObject, pickupId, coords, label)
        else
            ESX.Game.SpawnLocalObject("prop_money_bag_01", coords, function(entity)
                setObjectProperties(entity, pickupId, coords, label)
            end)
        end
    end)

    AddEventHandler("esx:removePickup", function(pickupId)
        if pickups[pickupId] and pickups[pickupId].obj then
            ESX.Game.DeleteObject(pickups[pickupId].obj)
            pickups[pickupId] = nil
        end
    end)

    AddEventHandler("esx:createMissingPickups", function(missingPickups)
        for pickupId, pickup in pairs(missingPickups) do
            TriggerEvent("esx:createPickup", pickupId, pickup.label, pickup.coords, pickup.type, pickup.name, pickup.components, pickup.tintIndex)
        end
    end)

    AddEventHandler("esx:addInventoryItem", function(item, count, showNotification)
        for k, v in ipairs(ESX.PlayerData.inventory) do
            if v.name == item then
                ESX.UI.ShowInventoryItemNotification(true, v.label, count - v.count)
                ESX.PlayerData.inventory[k].count = count
                break
            end
        end

        if showNotification then
            ESX.UI.ShowInventoryItemNotification(true, item, count)
        end
    end)

    AddEventHandler("esx:removeInventoryItem", function(item, count, showNotification)
        for k, v in ipairs(ESX.PlayerData.inventory) do
            if v.name == item then
                ESX.UI.ShowInventoryItemNotification(false, v.label, v.count - count)
                ESX.PlayerData.inventory[k].count = count
                break
            end
        end

        if showNotification then
            ESX.UI.ShowInventoryItemNotification(false, item, count)
        end
    end)

    RegisterNetEvent("esx:addWeapon", function()
        ESX.Trace("Event ^5'esx:addWeapon'^7 Has Been Removed. Please use ^5xPlayer.addWeapon^7 Instead!", "error", true)
    end)

    RegisterNetEvent("esx:removeWeapon", function()
        ESX.Trace("Event ^5'esx:removeWeapon'^7 Has Been Removed. Please use ^5xPlayer.removeWeapon^7 Instead!", "error", true)
    end)

    RegisterNetEvent("esx:setWeaponAmmo", function()
        ESX.Trace("Event ^5'esx:setWeaponAmmo'^7 Has Been Removed. Please use ^5xPlayer.updateWeaponAmmo^7 Instead!", "error", true)
    end)

    RegisterNetEvent("esx:addWeaponComponent", function()
        ESX.Trace("Event ^5'esx:addWeaponComponent'^7 Has Been Removed. Please use ^5xPlayer.addWeaponComponent^7 Instead!", "error", true)
    end)

    RegisterNetEvent("esx:removeWeaponComponent", function()
        ESX.Trace("Event ^5'esx:removeWeaponComponent'^7 Has Been Removed. Please use ^5xPlayer.removeWeaponComponent^7 Instead!", "error", true)
    end)

    AddEventHandler("esx:setWeaponTint", function(weapon, weaponTintIndex)
        SetPedWeaponTintIndex(ESX.PlayerData.ped, joaat(weapon), weaponTintIndex)
    end)

    if Config.EnableDefaultInventory then
        RegisterCommand("showinv", function()
            if ESX.PlayerData.dead then return end

            ESX.ShowInventory()
        end, false)

        RegisterKeyMapping("showinv", _U("keymap_showinventory"), "keyboard", "F2")
    end
end)

function Core.StartServerSyncLoop() ---@diagnostic disable-line: duplicate-set-field
    CreateThread(function()
        local currentWeapon = { Ammo = 0 }
        local sleep

        while ESX.PlayerLoaded do
            sleep = 1500

            if GetSelectedPedWeapon(ESX.PlayerData.ped) ~= -1569615261 then
                sleep = 1000
                local _, weaponHash = GetCurrentPedWeapon(ESX.PlayerData.ped, true)
                local weapon = ESX.GetWeaponFromHash(weaponHash)

                if weapon then
                    local ammoCount = GetAmmoInPedWeapon(ESX.PlayerData.ped, weaponHash)

                    if weapon.name ~= currentWeapon.name then
                        currentWeapon.Ammo = ammoCount
                        currentWeapon.name = weapon.name
                    else
                        if ammoCount ~= currentWeapon.Ammo then
                            currentWeapon.Ammo = ammoCount

                            TriggerServerEvent("esx:updateWeaponAmmo", weapon.name, ammoCount)
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

function Core.StartDroppedItemsLoop() ---@diagnostic disable-line: duplicate-set-field
    CreateThread(function()
        local sleep

        while ESX.PlayerLoaded do
            sleep = 1500
            local _, closestDistance = ESX.Game.GetClosestPlayer(cache.coords)

            for pickupId, pickup in pairs(pickups) do
                local distance = #(cache.coords - pickup.coords)

                PlaceObjectOnGroundProperly(pickup.obj)

                if distance < 5 then
                    sleep = 0
                    local label = pickup.label

                    if distance < 1 then
                        if IsControlJustReleased(0, 38) then
                            if IsPedOnFoot(ESX.PlayerData.ped) and (closestDistance == -1 or closestDistance > 3) and not pickup.inRange then
                                pickup.inRange = true

                                local dict, anim = "weapons@first_person@aim_rng@generic@projectile@sticky_bomb@", "plant_floor"
                                ESX.Streaming.RequestAnimDict(dict)
                                TaskPlayAnim(ESX.PlayerData.ped, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                                RemoveAnimDict(dict)
                                Wait(1000)

                                TriggerServerEvent("esx:onPickup", pickupId)
                                PlaySoundFrontend(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                            end
                        end

                        label = ("%s~n~%s"):format(label, _U("threw_pickup_prompt"))
                    end

                    ESX.Game.Utils.DrawText3D({
                        x = pickup.coords.x,
                        y = pickup.coords.y,
                        z = pickup.coords.z + 0.25
                    }, label, 1.2, 1)
                elseif pickup.inRange then
                    pickup.inRange = false
                end
            end
            Wait(sleep)
        end
    end)
end

----- Admin commnads from esx_adminplus
RegisterNetEvent("esx:tpm")
AddEventHandler("esx:tpm", function()
    local GetEntityCoords = GetEntityCoords
    local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
    local GetFirstBlipInfoId = GetFirstBlipInfoId
    local DoesBlipExist = DoesBlipExist
    local DoScreenFadeOut = DoScreenFadeOut
    local GetBlipInfoIdCoord = GetBlipInfoIdCoord
    local GetVehiclePedIsIn = GetVehiclePedIsIn

    ESX.TriggerServerCallback("esx:isUserAdmin", function(admin)
        if not admin then
            return
        end
        local blipMarker = GetFirstBlipInfoId(8)
        if not DoesBlipExist(blipMarker) then
            ESX.ShowNotification(_U("tpm_nowaypoint"), "error")
            return "marker"
        end

        -- Fade screen to hide how clients get teleported.
        DoScreenFadeOut(650)
        while not IsScreenFadedOut() do
            Wait(0)
        end

        local ped, coords = ESX.PlayerData.ped, GetBlipInfoIdCoord(blipMarker)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local oldCoords = GetEntityCoords(ped)

        -- Unpack coords instead of having to unpack them while iterating.
        -- 825.0 seems to be the max a player can reach while 0.0 being the lowest.
        local x, y, groundZ, Z_START = coords["x"], coords["y"], 850.0, 950.0
        local found = false
        FreezeEntityPosition(vehicle > 0 and vehicle or ped, true)

        for i = Z_START, 0, -25.0 do
            local z = i
            if (i % 2) ~= 0 then
                z = Z_START - i
            end

            NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
            local curTime = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(0)
            end
            NewLoadSceneStop()
            SetPedCoordsKeepVehicle(ped, x, y, z)

            while not HasCollisionLoadedAroundEntity(ped) do
                RequestCollisionAtCoord(x, y, z)
                if GetGameTimer() - curTime > 1000 then
                    break
                end
                Wait(0)
            end

            -- Get ground coord. As mentioned in the natives, this only works if the client is in render distance.
            found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
            if found then
                Wait(0)
                SetPedCoordsKeepVehicle(ped, x, y, groundZ)
                break
            end
            Wait(0)
        end

        -- Remove black screen once the loop has ended.
        DoScreenFadeIn(650)
        FreezeEntityPosition(vehicle > 0 and vehicle or ped, false)

        if not found then
            -- If we can't find the coords, set the coords to the old ones.
            -- We don't unpack them before since they aren't in a loop and only called once.
            SetPedCoordsKeepVehicle(ped, oldCoords["x"], oldCoords["y"], oldCoords["z"] - 1.0)
            ESX.ShowNotification(_U("tpm_success"), "success")
        end

        -- If Z coord was found, set coords in found coords.
        SetPedCoordsKeepVehicle(ped, x, y, groundZ)
        ESX.ShowNotification(_U("tpm_success"), "success")
    end)
end)

local noclip = false
local noclip_pos = vector3(0, 0, 70)
local heading = 0

local function noclipThread()
    while noclip do
        SetEntityCoordsNoOffset(ESX.PlayerData.ped, noclip_pos.x, noclip_pos.y, noclip_pos.z, false, false, false)

        if IsControlPressed(1, 34) then
            heading = heading + 1.5
            if heading > 360 then
                heading = 0
            end

            SetEntityHeading(ESX.PlayerData.ped, heading)
        end

        if IsControlPressed(1, 9) then
            heading = heading - 1.5
            if heading < 0 then
                heading = 360
            end

            SetEntityHeading(ESX.PlayerData.ped, heading)
        end

        if IsControlPressed(1, 8) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, 1.0, 0.0)
        end

        if IsControlPressed(1, 32) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, -1.0, 0.0)
        end

        if IsControlPressed(1, 27) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, 0.0, 1.0)
        end

        if IsControlPressed(1, 173) then
            noclip_pos = GetOffsetFromEntityInWorldCoords(ESX.PlayerData.ped, 0.0, 0.0, -1.0)
        end
        Wait(0)
    end
end

RegisterNetEvent("esx:noclip")
AddEventHandler("esx:noclip", function()
    ESX.TriggerServerCallback("esx:isUserAdmin", function(admin)
        if not admin then
            return
        end

        if not noclip then
            noclip_pos = GetEntityCoords(ESX.PlayerData.ped, false)
            heading = GetEntityHeading(ESX.PlayerData.ped)
        end

        noclip = not noclip
        if noclip then
            CreateThread(noclipThread)
        end

        ESX.ShowNotification(_U("noclip_message", noclip and "enabled" or "disabled"))
    end)
end)

AddEventHandler("esx:killPlayer", function()
    SetEntityHealth(ESX.PlayerData.ped, 0)
end)

AddEventHandler("esx:freezePlayer", function(input)
    if input == "freeze" then
        SetEntityCollision(ESX.PlayerData.ped, false, true)
        FreezeEntityPosition(ESX.PlayerData.ped, true)
        SetPlayerInvincible(cache.playerId, true)
    elseif input == "unfreeze" then
        SetEntityCollision(ESX.PlayerData.ped, true, true)
        FreezeEntityPosition(ESX.PlayerData.ped, false)
        SetPlayerInvincible(cache.playerId, false)
    end
end)

ESX.RegisterClientCallback("esx:GetVehicleType", function(cb, model)
    cb(ESX.GetVehicleType(model))
end)

lib.onCache("ped", function(value)
    ESX.SetPlayerData("ped", value)
    TriggerEvent("esx:restoreLoadout")
end)

local vehicleDbId, vehicleEntity, vehicleNetId
local isMonitorVehiclePropertiesThreadActive = false

local function syncVehicleProperties()
    if not vehicleDbId then return end -- not a persistent vehicle spawned by the framework

    TriggerServerEvent(("esx:updateVehicleNetId%sProperties"):format(vehicleNetId), vehicleDbId, ESX.Game.GetVehicleProperties(vehicleEntity))
end

local function monitorVehiclePropertiesThread()
    if isMonitorVehiclePropertiesThreadActive then return end

    isMonitorVehiclePropertiesThreadActive = true

    CreateThread(function()
        while cache.seat == -1 do
            syncVehicleProperties()
            Wait(10000)
        end

        isMonitorVehiclePropertiesThreadActive = false
    end)
end

lib.onCache("seat", function(newSeat)
    if newSeat == -1 then
        vehicleEntity = cache.vehicle
        vehicleDbId   = Entity(vehicleEntity).state.id
        vehicleNetId  = NetworkGetNetworkIdFromEntity(vehicleEntity)

        monitorVehiclePropertiesThread()
    elseif cache.seat == -1 then
        syncVehicleProperties()
        vehicleDbId, vehicleEntity, vehicleNetId = nil, nil, nil
    end
end)
