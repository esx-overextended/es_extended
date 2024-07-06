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
