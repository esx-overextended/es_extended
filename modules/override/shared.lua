---@type table<string, function>
local originalFunctions = {}

---@type table<string, string>
local invokedResources = {}

---@param fieldName string
---@param value number | string | boolean | table
---@return boolean (whether the action was successful or not)
function ESX.SetField(fieldName, value)
    local fieldNameType = type(fieldName)
    local valueType = type(value)
    local isValueValid = (valueType == "number" or valueType == "string" or valueType == "boolean" or (valueType == "table" and not value?.__cfx_functionReference)) and true or false

    if fieldNameType ~= "string" then
        ESX.Trace(("The field name (^3%s^7) passed in ^5ESX.SetField^7 in ^3%s^7 is not a valid string!"):format(fieldName, lib.context), "error", true)
        return false
    elseif not isValueValid then
        ESX.Trace(("The value passed in ^5ESX.SetField^7 in ^3%s^7 does not have a valid type!"):format(lib.context), "error", true)
        return false
    end

    if fieldName == "SetField" then
        ESX.Trace(("Field ^2%s^7 of ESX ^1cannot^7 be overrided!"):format(fieldName), "error", true)
        return false
    end

    ESX[fieldName] = value

    ESX.Trace(("Setting field (^2%s^7) for ^2ESX^7 through ^5ESX.SetField^7 in ^3%s^7."):format(fieldName, lib.context), "info", true)

    return true
end

---@param fnName string
---@param fn function
---@return boolean (whether the action was successful or not)
function ESX.SetFunction(fnName, fn)
    local fnNameType = type(fnName)
    local fnType = type(fn)
    local isFnValid = (fnType == "function" or (fnType == "table" and fn?.__cfx_functionReference and true)) or false

    if fnNameType ~= "string" then
        ESX.Trace(("The function name (^3%s^7) passed in ^5ESX.SetFunction^7 in ^3%s^7 is not a valid string!"):format(fnName, lib.context), "error", true)
        return false
    elseif not isFnValid then
        ESX.Trace(("The function passed in ^5ESX.SetFunction^7 in ^3%s^7 is not a valid function!"):format(lib.context), "error", true)
        return false
    end

    if fnName == "SetFunction" then
        ESX.Trace(("Function ^2%s^7 of ESX ^1cannot^7 be overrided!"):format(fnName), "error", true)
        return false
    end

    if type(ESX[fnName]) == "function" then
        originalFunctions[fnName] = ESX[fnName]
    end

    invokedResources[fnName] = GetInvokingResource() or cache.resource

    ESX[fnName] = fn(ESX)

    ESX.Trace(("Setting function (^2%s^7) for ^2ESX^7 through ^5ESX.SetFunction^7 in ^3%s^7."):format(fnName, lib.context), "info", true)

    TriggerEvent("esx:sharedObjectUpdated")

    return true
end

---@param resource string
local function onResourceStop(resource)
    for fnName, invokedResource in pairs(invokedResources) do
        if invokedResource == resource and not GetResourceState(resource):find("start") --[[hacky way to bypass event tick delay on a resource restart]] then
            invokedResources[fnName] = nil

            if originalFunctions[fnName] then
                ESX.SetFunction(fnName, function()
                    return originalFunctions[fnName]
                end)
            else
                ESX[fnName] = nil
                TriggerEvent("esx:sharedObjectUpdated")
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler(("on%sResourceStop"):format(lib.context:gsub("^%l", string.upper)), onResourceStop)
