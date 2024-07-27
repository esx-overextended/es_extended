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
local function setPedIntoVehicle(vehicleEntity)
    while IsVehicleSeatFree(vehicleEntity, -1) do
        Wait(0)
        SetPedIntoVehicle(cache.ped, vehicleEntity, -1)
    end
end

ESX.RegisterClientCallback("esx:generateVehicleData", function(cb, params)
    if not ESX.TriggerServerCallback("esx:isUserAdmin") then return end

    local models = GetAllVehicleModels()
    local numModels = #models
    local numParsed = 0
    local coords = GetEntityCoords(cache.ped)
    local radarState = not IsRadarHidden()
    local vehicleData, vehicleTopStats = {}, {}
    local message = ("Generating data from vehicle models (%s models loaded)"):format(numModels)
    local specifiedModel = params.model and params.model:lower()

    ESX.Trace(message, "info", true)
    ESX.ShowNotification({ "ESX-Overextended", message }, "info", 5000)

    DisplayRadar(false)
    SetEntityVisible(cache.ped, false, false)
    SetPlayerControl(cache.playerId, false, 1 << 8)

    freezeEntity(true, cache.ped, Config.VehicleParser.Position)

    local estimatedRemaining
    local startTime = GetGameTimer()
    message = "Generated vehicle data for %d" .. ("/%d models  \n"):format(numModels)

    local cam = CreateCamWithParams(Config.VehicleParser.Cam.Name, Config.VehicleParser.Cam.Coords.x, Config.VehicleParser.Cam.Coords.y, Config.VehicleParser.Cam.Coords.z, Config.VehicleParser.Cam.Rotation.x,
        Config.VehicleParser.Cam.Rotation.y, Config.VehicleParser.Cam.Rotation.z, Config.VehicleParser.Cam.FOV, Config.VehicleParser.Cam.Active, Config.VehicleParser.Cam.RotationOrder)

    PointCamAtCoord(cam, Config.VehicleParser.Position.x, Config.VehicleParser.Position.y, Config.VehicleParser.Position.z + 0.65)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1, true, true)
    CreateMobilePhone(1)
    CellCamActivate(true, true)
    Wait(2000)

    for i = 1, numModels do
        local model = models[i]:lower()
        local isThisModelSpecified = specifiedModel == model

        if isThisModelSpecified or params?.processAll or (not specifiedModel and not params?.processAll and not ESX.GetVehicleData(model)) then
            local hash = loadModel(model)

            if hash then
                local vehicle = spawnPreviewVehicle(hash, Config.VehicleParser.Position)

                freezeEntity(true, vehicle, Config.VehicleParser.Position)

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

                local image = ESX.TriggerServerCallback("esx:takeScreenshotFromVehicle", model) or ""

                local data = {
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

                local stats = {
                    braking = ESX.Math.Round(GetVehicleModelMaxBraking(hash), 4),
                    acceleration = ESX.Math.Round(GetVehicleModelAcceleration(hash), 4),
                    speed = ESX.Math.Round(GetVehicleModelEstimatedMaxSpeed(hash), 4),
                    handling = ESX.Math.Round(GetVehicleModelEstimatedAgility(hash), 4),
                }

                if vType ~= "trailer" and vType ~= "train" then
                    local vGroup = (vType == "heli" or vType == "plane" or vType == "blimp") and "air" or (vType == "boat" or vType == "submarine") and "sea" or "land"
                    local topTypeStats = vehicleTopStats[vGroup]

                    if not topTypeStats then
                        vehicleTopStats[vGroup] = {}
                        topTypeStats = vehicleTopStats[vGroup]
                    end

                    for k, v in pairs(stats) do
                        if not topTypeStats[k] or v > topTypeStats[k] then
                            topTypeStats[k] = v
                        end

                        data[k] = v
                    end
                end

                vehicleData[model] = data
                numParsed += 1

                deleteEntity(vehicle)

                if isThisModelSpecified and not params.processAll then -- Server requests to generate data of only 1 specified model
                    break
                end

                estimatedRemaining = (((GetGameTimer() - startTime) / 1000) / numParsed) * (numModels - numParsed)
                estimatedRemaining = ("%s:%s"):format(string.format("%02d", math.floor(estimatedRemaining / 60)), string.format("%02d", math.floor(estimatedRemaining % 60)))

                ESX.TextUI(("%sEstimated time remaining: %s"):format(message:format(numParsed), estimatedRemaining), "info")
            end
        end
    end

    DestroyMobilePhone()
    CellCamActivate(false, false)
    RenderScriptCams(false, false, 1, false, false)
    DestroyAllCams(true)
    ClearFocus()
    SetCamActive(cam, false)

    ESX.HideUI()
    ESX.Trace(message:format(numParsed), "info", true)
    ESX.ShowNotification({ "ESX-Overextended", message:format(numParsed, estimatedRemaining) }, "info", 5000)

    DisplayRadar(radarState)
    SetEntityVisible(cache.ped, true, false)
    SetPlayerControl(cache.playerId, true, 0)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z, false, false, false, false)

    freezeEntity(false, cache.ped)

    return cb(vehicleData, vehicleTopStats)
end)
