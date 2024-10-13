-- leave for backward-compatibility
---@param model string | number
---@param _? number playerId (not used anymore)
---@param cb? function
---@return string?
function ESX.GetVehicleType(model, _, cb) ---@diagnostic disable-line: duplicate-set-field
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

ESX.RegisterServerCallback("esx:takeScreenshotFromVehicle", function(source, cb, fileName)
    if not Core.IsPlayerAdmin(source) then
        return ESX.Trace("Player (%s) requested to take a screenshot from vehicle, but is not authorized!", "error", true)
    end

    local imageAddress = ("es_extended/files/vehicle-images/%s.jpg"):format(fileName)

    exports["screenshot-basic"]:requestClientScreenshot(source, {
        quality = 0.3,
        encoding = "jpg",
        fileName = ("resources/[core]/%s"):format(imageAddress)
    }, function(err, _)
        if err then
            cb(false)
            ESX.Trace(("Could not generate an image for the vehicle (%s)!"):format(fileName), "error", true)
            return ESX.Trace(("%s"):format(err), "error", true)
        end

        cb(("https://cfx-nui-%s"):format(imageAddress))
    end)
end)

local function requestDataGenerationFromPlayer(playerId, args)
    if not GetResourceState("screenshot-basic"):find("start") then
        ESX.Trace("The resource 'screenshot-basic' MUST be started so vehicles image can be generated in vehicles data!", "error", true)
        return ESX.Trace("You can download the 'screenshot-basic' from <<https://github.com/citizenfx/screenshot-basic>>", "info", true)
    end

    ---@type table<string, VehicleData>, TopVehicleStats
    local vehicleData, topStats = ESX.TriggerClientCallback(playerId, "esx:generateVehicleData", { processAll = args.processAll, model = args.model })

    if vehicleData and next(vehicleData) then
        if not args.processAll then
            for k, v in pairs(ESX.GetVehicleData()) do
                if not vehicleData[k] or args.model ~= k then
                    vehicleData[k] = v
                end
            end
        end

        local topVehicleStats = ESX.GetTopVehicleStats() or {}

        if topVehicleStats then
            for vtype, data in pairs(topVehicleStats) do
                if not topStats[vtype] then topStats[vtype] = {} end

                for stat, value in pairs(data) do
                    local newValue = topStats[vtype][stat]

                    if newValue and newValue > value then
                        topVehicleStats[vtype][stat] = newValue
                    end
                end
            end
        end

        SaveResourceFile(cache.resource, "files/vehicles.json", json.encode(vehicleData, {
            indent = true, sort_keys = true, indent_count = 4
        }), -1)

        SaveResourceFile(cache.resource, "files/topVehicleStats.json", json.encode(topVehicleStats, {
            indent = true, sort_keys = true, indent_count = 4
        }), -1)

        Core.RefreshVehicleData()

        ESX.Trace(("Vehicle parsing process requested by the Player ID (%s) is complete!"):format(playerId), "info", true)
        ESX.Trace("The changes are dynamically applied onto the server, except for vehicle images which will be updated once the server is restarted!", "info", true)
    end
end

ESX.RegisterCommand("parsevehicles", "superadmin", function(xPlayer, args)
    -- Convert "true/false" string to boolean
    local toBoolean = { ["false"] = false, ["true"] = true }

    -- Check if the user input is a valid "true" or "false"
    if toBoolean[args.processAll:lower()] ~= nil then
        -- Convert processAll argument to boolean
        args.processAll = toBoolean[args.processAll:lower()]

        -- Call requestDataGenerationFromPlayer function with converted argument
        requestDataGenerationFromPlayer(xPlayer.source, args)
    else
        -- Notify the player if the input is invalid
        xPlayer.showNotification("Invalid value for processAll. Please use true or false.")
    end
end, false, {
    help = "Generate and save vehicle data for available models on the client",
    validate = true,
    arguments = {
        { name = "processAll", help = "true/false >> Whether the parsing process should include vehicles with existing data (in the event of updated vehicle stats)", type = "string" }
    }
})


ESX.RegisterCommand("parsevehicle", "superadmin", function(xPlayer, args)
    requestDataGenerationFromPlayer(xPlayer.source, args)
end, false, {
    help = "Generate and save vehicle data for a specifid model on the client",
    validate = true,
    arguments = {
        { name = "model", help = "The specified model to generate its data", type = "string" }
    }
})
