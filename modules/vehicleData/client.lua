-- leave for backward-compatibility
---@param model string | number
---@param cb? function
---@return string?
function ESX.GetVehicleType(model, cb) ---@diagnostic disable-line: duplicate-set-field
    local typeModel = type(model)

    if typeModel ~= "string" and typeModel ~= "number" then
        ESX.Trace(("Invalid type of model (^1%s^7) in ^5ESX.GetVehicleType^7!"):format(typeModel), "error", true)
        return
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
        ESX.Trace(("Vehicle model (^1%s^7) is invalid \nEnsure vehicle exists in ^2'@es_extended/files/vehicles.json'^7"):format(model), "error", true)
    end

    return cb and cb(modelData?.type) or modelData?.type
end

if not Config.EnableDebug then return end

lib.callback.register("esx:generateVehicleData", function(processAll)
    local models = GetAllVehicleModels()
    local numModels = #models
    local numParsed = 0
    local coords = GetEntityCoords(cache.ped)
    local vehicleData = {}
    local vehicleTopStats = {}

    ESX.Trace(("Generating vehicle data from models (%s models loaded)."):format(numModels), "info", true)

    for i = 1, numModels do
        local model = models[i]:lower()

        if processAll or not ESX.GetVehicleData(model) then
            local hash = joaat(model)

            lib.requestModel(hash)

            if hash then
                local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z + 10, 0.0, false, false)
                local make = GetMakeNameFromVehicleModel(hash)

                if make == "" then
                    local make2 = GetMakeNameFromVehicleModel(model:gsub("%A", ""))

                    if make2 ~= "CARNOTFOUND" then
                        make = make2
                    end
                end

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

                local data = {
                    name = GetLabelText(GetDisplayNameFromVehicleModel(hash)),
                    make = make == "" and make or GetLabelText(make),
                    class = class,
                    seats = GetVehicleModelNumberOfSeats(hash),
                    weapons = DoesVehicleHaveWeapons(vehicle) or nil,
                    doors = GetNumberOfVehicleDoors(vehicle),
                    type = vType,
                    hash = hash
                }

                local stats = {
                    braking = GetVehicleModelMaxBraking(hash),
                    acceleration = GetVehicleModelAcceleration(hash),
                    speed = GetVehicleModelEstimatedMaxSpeed(hash),
                    handling = GetVehicleModelEstimatedAgility(hash),
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

                SetVehicleAsNoLongerNeeded(vehicle)
                DeleteEntity(vehicle)
                SetModelAsNoLongerNeeded(hash)
            end
        end
    end

    ESX.Trace(("Generated vehicle data from %s models."):format(numParsed), "info", true)

    return vehicleData, vehicleTopStats
end)
