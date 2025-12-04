-- leave for backward-compatibility
---@param model string | number
---@param cb? function
---@return string?
function ESX.GetVehicleType(model, cb) ---@diagnostic disable-line: duplicate-set-field
    local typeModel = type(model)

    if typeModel ~= "string" and typeModel ~= "number" then
        return ESX.Trace(("Invalid type of model (^1%s^7) in ^5ESX.GetVehicleType^7!"):format(typeModel), "error", true)
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
        return ESX.Trace(("Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(model), "error", true)
    end

    return cb and cb(modelData?.type) or modelData?.type
end

---@param entity? number
---@return boolean
local function hasCollisionLoadedAroundEntity(entity)
    if not entity then entity = cache.ped end

    return HasCollisionLoadedAroundEntity(entity) and not IsEntityWaitingForWorldCollision(entity)
end

---@param state boolean
---@param entity? number
---@param atCoords? vector3 | vector4 | table
local function freezeEntity(state, entity, atCoords)
    if not entity then entity = cache.ped end
    if IsEntityAPed(entity) and IsPedAPlayer(entity) then ClearPedTasksImmediately(entity) end

    SetEntityCollision(entity, not state, true)
    FreezeEntityPosition(entity, state)
    SetEntityInvincible(entity, state)

    if atCoords then
        SetEntityCoords(entity, atCoords.x, atCoords.y, atCoords.z, false, false, false, false)

        if atCoords.w or atCoords.heading then
            SetEntityHeading(entity, atCoords.w or atCoords.heading)
        end

        while not hasCollisionLoadedAroundEntity(entity) do
            RequestCollisionAtCoord(atCoords.x, atCoords.y, atCoords.z)
            Wait(0)
        end
    end
end

---@param state boolean
---@param text? string
local function spinner(state, text)
    if not state then return BusyspinnerOff() end
    if not text then text = "Loading..." end

    AddTextEntry(text, text)
    BeginTextCommandBusyspinnerOn(text)
    EndTextCommandBusyspinnerOn(4)
end

---@param entity number
---@return boolean
local function deleteEntity(entity)
    if not entity then return false end

    local model = GetEntityModel(entity)

    SetVehicleAsNoLongerNeeded(entity)

    while DoesEntityExist(entity) do
        DeleteEntity(entity)
        Wait(0)
    end

    SetModelAsNoLongerNeeded(model)

    return true
end

local MAX_TRY_COUNT = 1000

---@param vehicleModel string
---@return number | false
local function loadModel(vehicleModel)
    local hash = joaat(vehicleModel)
    local tryCount, hasModelLoaded = 0, false

    ESX.Trace("Trying to load vehicle model " .. vehicleModel, nil) ---@diagnostic disable-line: param-type-mismatch

    while tryCount < MAX_TRY_COUNT and not hasModelLoaded do
        spinner(true, ("Loading %s"):format(vehicleModel))
        RequestModel(hash)
        Wait(0)
        tryCount, hasModelLoaded = tryCount + 1, HasModelLoaded(hash)
    end

    spinner(false)

    if not hasModelLoaded then
        return false, ESX.Trace(("^1Waited %s-frames for vehicle model ^5%s ^1to load, but it did not!^7"):format(MAX_TRY_COUNT, vehicleModel), "warning", true)
    end

    return hash
end

---@param vehicleModel number
---@param atCoords any
---@return number
local function spawnPreviewVehicle(vehicleModel, atCoords)
    local vehicleEntity = CreateVehicle(vehicleModel, atCoords.x, atCoords.y, atCoords.z, atCoords.w, false, false)

    while not DoesEntityExist(vehicleEntity) do Wait(0) end

    SetVehRadioStation(vehicleEntity, "OFF")
    SetVehicleNeedsToBeHotwired(vehicleEntity, false)
    freezeEntity(true, vehicleEntity, atCoords)

    return vehicleEntity
end

---@param vehicleEntity number
local function setPedIntoVehicle(vehicleEntity, seat)
    seat = seat or -1

    while DoesEntityExist(vehicleEntity) and IsVehicleSeatFree(vehicleEntity, seat) do
        Wait(0)
        SetPedIntoVehicle(cache.ped, vehicleEntity, seat)
    end
end

local activeCam = nil
local initialCoords, initialRadarState = nil, nil

local function setupPreviewCam()
    if activeCam and DoesCamExist(activeCam) then return activeCam end

    activeCam = CreateCamWithParams(
        Config.VehicleParser.Cam.Name,
        Config.VehicleParser.Cam.Coords.x,
        Config.VehicleParser.Cam.Coords.y,
        Config.VehicleParser.Cam.Coords.z,
        Config.VehicleParser.Cam.Rotation.x,
        Config.VehicleParser.Cam.Rotation.y,
        Config.VehicleParser.Cam.Rotation.z,
        Config.VehicleParser.Cam.FOV,
        Config.VehicleParser.Cam.Active,
        Config.VehicleParser.Cam.RotationOrder
    )

    PointCamAtCoord(activeCam, Config.VehicleParser.Position.x, Config.VehicleParser.Position.y, Config.VehicleParser.Position.z + 0.65)
    SetCamActive(activeCam, true)
    RenderScriptCams(true, true, 1, true, true)
    CreateMobilePhone(1)
    CellCamActivate(true, true)

    return activeCam
end

local function cleanupPreviewCam()
    if not activeCam then return end

    DestroyMobilePhone()
    CellCamActivate(false, false)
    RenderScriptCams(false, false, 1, false, false)
    DestroyAllCams(true)
    ClearFocus()
    SetCamActive(activeCam, false)

    activeCam = nil
end

local function setupEnironment()
    SetEntityVisible(cache.ped, false, false)
    SetPlayerControl(cache.playerId, false, 1 << 8)

    initialCoords = GetEntityCoords(cache.ped)
    initialRadarState = not IsRadarHidden()

    freezeEntity(true, cache.ped, Config.VehicleParser.Position)

    setupPreviewCam()

    Citizen.CreateThreadNow(function()
        while activeCam do
            DisplayRadar(false)
            Wait(0)
        end
    end)
end

local function exitEnvironment()
    cleanupPreviewCam()

    DisplayRadar(initialRadarState) ---@diagnostic disable-line: param-type-mismatch
    SetEntityVisible(cache.ped, true, false)
    SetPlayerControl(cache.playerId, true, 0)
    SetEntityCoords(cache.ped, initialCoords.x, initialCoords.y, initialCoords.z, false, false, false, false) ---@diagnostic disable-line: need-check-nil

    freezeEntity(false, cache.ped)
end

local function generateVehicleData(model, params)
    local vehicleData, vehicleStats
    local hash = loadModel(model)

    if hash then
        local vehicle = spawnPreviewVehicle(hash, Config.VehicleParser.Position)

        freezeEntity(true, vehicle, Config.VehicleParser.Position)

        if params?.properties then
            ESX.Game.SetVehicleProperties(vehicle, params.properties)
        end

        -- Keep camera Z-height, only move BACK in XY ====
        local vehPos = Config.VehicleParser.Position
        local min, max = GetModelDimensions(hash)
        local size = vector3(max.x - min.x, max.y - min.y, max.z - min.z)
        local radius = (#size / 2.0) * 1.18 -- bounding sphere + margin

        -- ORIGINAL camera position (keep Z unchanged)
        local camX = Config.VehicleParser.Cam.Coords.x
        local camY = Config.VehicleParser.Cam.Coords.y
        local camZ = Config.VehicleParser.Cam.Coords.z -- KEEP ORIGINAL Z!

        -- Look at vehicle center (floor + half height)
        local lookX = vehPos.x
        local lookY = vehPos.y
        local lookZ = vehPos.z + (size.z * 0.4)

        -- XY distance only (ignore Z for positioning)
        local dirX = lookX - camX
        local dirY = lookY - camY
        local xyDist = math.sqrt(dirX * dirX + dirY * dirY)

        -- FOV-based required XY distance
        local halfFovRad = math.rad(Config.VehicleParser.Cam.FOV * 0.65) -- wider effective FOV for height
        local neededXYDist = radius / math.tan(halfFovRad)

        if neededXYDist > xyDist then
            -- Move back ONLY in XY plane, keep original Z
            local scale = neededXYDist / xyDist
            camX = lookX - dirX * scale
            camY = lookY - dirY * scale
            -- camZ stays exactly Config.VehicleParser.Cam.Coords.z
        end

        SetCamCoord(activeCam, camX, camY, camZ) ---@diagnostic disable-line: param-type-mismatch
        PointCamAtCoord(activeCam, lookX, lookY, lookZ) ---@diagnostic disable-line: param-type-mismatch
        -- ==================================================

        local make = GetMakeNameFromVehicleModel(hash)

        if make == "" then
            local make2 = GetMakeNameFromVehicleModel(model:gsub("%A", ""))

            if make2 ~= "CARNOTFOUND" then
                make = make2
            end
        end

        setPedIntoVehicle(vehicle)

        local class = GetVehicleClass(vehicle)
        local vType

        if IsThisModelACar(hash) then
            vType = "automobile"
        elseif IsThisModelABicycle(hash) then
            vType = "bicycle"
        elseif IsThisModelABike(hash) then
            vType = "bike"
        elseif IsThisModelABoat(hash) then
            vType = "boat"
        elseif IsThisModelAHeli(hash) then
            vType = "heli"
        elseif IsThisModelAPlane(hash) then
            vType = "plane"
        elseif IsThisModelAQuadbike(hash) then
            vType = "quadbike"
        elseif IsThisModelAnAmphibiousCar(hash) then
            vType = "amphibious_automobile"
        elseif IsThisModelAnAmphibiousQuadbike(hash) then
            vType = "amphibious_quadbike"
        elseif IsThisModelATrain(hash) then
            vType = "train"
        else
            vType = (class == 5 and "submarinecar") or (class == 14 and "submarine") or (class == 16 and "blimp") or "trailer"
        end

        local image
        if params?.export then
            local p = promise.new()

            exports["screenshot-basic"]:requestScreenshot({
                quality = 0.3,
                encoding = "jpg"
            }, function(data)
                TriggerEvent('chat:addMessage', { template = '<img src="{0}" style="max-width: 300px;" />', args = { data } })
                p:resolve(data)
            end)

            image = Citizen.Await(p)
        else
            image = ESX.TriggerServerCallback("esx:takeScreenshotFromVehicle", model) or ""
        end

        vehicleData = {
            name = GetLabelText(GetDisplayNameFromVehicleModel(hash)),
            make = make == "" and make or GetLabelText(make),
            class = class,
            seats = GetVehicleModelNumberOfSeats(hash),
            weapons = DoesVehicleHaveWeapons(vehicle) or nil,
            doors = GetNumberOfVehicleDoors(vehicle),
            type = vType,
            hash = hash,
            image = image
        }

        vehicleStats = {
            braking = ESX.Math.Round(GetVehicleModelMaxBraking(hash), 4),
            acceleration = ESX.Math.Round(GetVehicleModelAcceleration(hash), 4),
            speed = ESX.Math.Round(GetVehicleModelEstimatedMaxSpeed(hash), 4),
            handling = ESX.Math.Round(GetVehicleModelEstimatedAgility(hash), 4),
        }

        if vType ~= "trailer" and vType ~= "train" then
            for k, v in pairs(vehicleStats) do
                vehicleData[k] = v
            end
        end

        deleteEntity(vehicle)
    end

    return vehicleData, vehicleStats
end

exports("generateVehicleImage", function(entityId, params)
    local image

    if DoesEntityExist(entityId) then
        params = params or {}
        params.fade = params.fade ~= false
        local entityModel = GetEntityModel(entityId)
        local currentVehicle, currentSeat = cache.vehicle and NetworkGetNetworkIdFromEntity(cache.vehicle), cache.seat

        if params.fade then
            SendNUIMessage({ action = "showBlackout" })
        end

        local properties = ESX.Game.GetVehicleProperties(entityId)

        setupEnironment()
        Wait(2000)

        image = generateVehicleData(entityModel, { export = true, properties = properties })?.image

        exitEnvironment()
        Wait(2000)

        if currentVehicle and NetworkDoesEntityExistWithNetworkId(currentVehicle) then
            setPedIntoVehicle(NetworkGetEntityFromNetworkId(currentVehicle), currentSeat)
        end

        if params.fade then
            SendNUIMessage({ action = "hideBlackout" })
        end
    end

    return image
end)

ESX.RegisterClientCallback("esx:generateVehicleData", function(cb, params)
    if not ESX.TriggerServerCallback("esx:isUserAdmin") then return end

    local models = GetAllVehicleModels()
    local numModels = #models
    local numParsed = 0
    local vehicleData, vehicleTopStats = {}, {}
    local message = ("Generating data from vehicle models (%s models loaded)"):format(numModels)
    local specifiedModel = params.model and params.model:lower()

    ESX.Trace(message, "info", true)
    ESX.ShowNotification({ "ESX-Overextended", message }, "info", 5000)

    local estimatedRemaining
    local startTime = GetGameTimer()
    message = "Generated vehicle data for %d" .. ("/%d models  \n"):format(numModels)

    setupEnironment()

    Wait(2000)

    for i = 1, numModels do
        local model = models[i]:lower()
        local isThisModelSpecified = specifiedModel == model

        if isThisModelSpecified or params?.processAll or (not specifiedModel and not params?.processAll and not ESX.GetVehicleData(model)) then
            local _vehicleData, _vehicleStats = generateVehicleData(model)

            if _vehicleData?.type ~= "trailer" and _vehicleData?.type ~= "train" then
                local vGroup = (_vehicleData?.type == "heli" or _vehicleData?.type == "plane" or _vehicleData?.type == "blimp") and "air" or (_vehicleData?.type == "boat" or _vehicleData?.type == "submarine") and "sea" or "land"
                local topTypeStats = vehicleTopStats[vGroup]

                if not topTypeStats then
                    vehicleTopStats[vGroup] = {}
                    topTypeStats = vehicleTopStats[vGroup]
                end

                for k, v in pairs(_vehicleStats) do
                    if not topTypeStats[k] or v > topTypeStats[k] then
                        topTypeStats[k] = v
                    end
                end
            end

            vehicleData[model] = _vehicleData
            numParsed += 1

            if isThisModelSpecified and not params.processAll then -- Server requests to generate data of only 1 specified model
                break
            end

            estimatedRemaining = (((GetGameTimer() - startTime) / 1000) / numParsed) * (numModels - numParsed)
            estimatedRemaining = ("%s:%s"):format(string.format("%02d", math.floor(estimatedRemaining / 60)), string.format("%02d", math.floor(estimatedRemaining % 60)))

            ESX.TextUI(("%sEstimated time remaining: %s"):format(message:format(numParsed), estimatedRemaining), "info")
        end
    end

    ESX.HideUI()
    ESX.Trace(message:format(numParsed), "info", true)
    ESX.ShowNotification({ "ESX-Overextended", message:format(numParsed, estimatedRemaining) }, "info", 5000)

    exitEnvironment()

    return cb(vehicleData, vehicleTopStats)
end)
