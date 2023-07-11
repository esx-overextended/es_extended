-- Copyright (c) 2022-2023 Overextended (https://github.com/overextended/ox_core/blob/main/shared/vehicles.lua)
-- Modified to fit ESX system in 2023 by ESX-Overextended

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

local function loadJson(file)
    local t = json.decode(LoadResourceFile(cache.resource, file) or "{}")

    if not t then
        error(("An unknown error occured while loading @%s/%s"):format(cache.resource, file), 2)
    end

    return t
end

---@type TopVehicleStats
local topStats = loadJson("files/topVehicleStats.json")

---@type table<string, VehicleData>
local vehicleList = loadJson("files/vehicles.json")

local function filterData(model, data, filter)
    if filter.model and not model:find(filter.model) then return end
    if filter.bodytype and filter.bodytype ~= data.bodytype then return end
    if filter.class and filter.class ~= data.class then return end
    if filter.doors and filter.doors == data.doors then return end
    if filter.make and filter.make ~= data.make then return end
    if filter.seats and filter.seats ~= data.seats then return end
    if filter.type and filter.type ~= data.type then return end
    if filter.hash and filter.hash ~= data.hash then return end

    return true
end

---@param filter "land" | "air" | "sea" | nil
---@return TopVehicleStats?
function ESX.GetTopVehicleStats(filter)
    if filter then
        return topStats[filter]
    end

    return topStats
end

---@param filter string | string[] | table<string, string | number> | nil
function ESX.GetVehicleData(filter)
    if filter then
        if type(filter) == "table" then
            local rv = {}

            if table.type(filter) == "array" then
                for i = 1, #filter do
                    local model = filter[i]
                    rv[model] = vehicleList[model]
                end
            else
                for model, data in pairs(vehicleList) do
                    if filterData(model, data, filter) then
                        rv[model] = data
                    end
                end
            end

            return rv
        end

        return vehicleList[filter]
    end

    return vehicleList
end

if not Config.EnableDebug or lib.context == "server" then return end

lib.callback.register("esx:generateVehicleData", function(processAll)
    local models = GetAllVehicleModels()
    local numModels = #models
    local numParsed = 0
    local coords = GetEntityCoords(cache.ped)
    local vehicleData = {}
    local vehicleTopStats = {}

    print(("Generating vehicle data from models (%s models loaded)."):format(numModels))

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

    print(("Generated vehicle data from %s models."):format(numParsed))

    return vehicleData, vehicleTopStats
end)
