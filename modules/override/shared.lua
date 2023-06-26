---@type table<string, function>
local originalFunctions = {}

---@type table<string, string>
local invokedResources = {}

---@param fnName string
---@param fn function
---@return boolean
function ESX.SetFunction(fnName, fn)
    local fnNameType = type(fnName)
    local fnType = type(fn)
    local isFnValid = (fnType == "function" or (fnType == "table" and fn?.__cfx_functionReference and true)) or false

    if fnNameType ~= "string" then print(("[^1ERROR^7] The function name (^3%s^7) passed in ^5ESX.SetFunction^7 in ^3%s^7 is not a valid string!"):format(fnName, cache.context, self.source)) return false
    elseif not isFnValid then print(("[^1ERROR^7] The function passed in ^5ESX.SetFunction^7 in ^3%s^7 is not a valid function!"):format(self.source, cache.context)) return false end

    if fnName == "SetFunction" then print(("[^1ERROR^7] Function ^2%s^7 of ESX ^1cannot^7 be overrided!"):format(fnName)) return false end

    if type(ESX[fnName]) == "function" then
        originalFunctions[fnName] = ESX[fnName]
    end

    invokedResources[fnName] = GetInvokingResource() or cache.resource

    ESX[fnName] = fn

    if Config.EnableDebug then
        print(("[^5INFO^7] Setting function (^2%s^7) for ^2ESX^7 through ^5ESX.SetFunction^7 in ^3%s^7."):format(fnName, self.source))
    end

    TriggerEvent("esx:sharedObjectUpdated")

    return true
end

---@param resource string
local function onResourceStop(resource)
    for fnName, invokedResource in pairs(invokedResources) do
        if invokedResource == resource then
            invokedResources[fnName] = nil

            if originalFunctions[fnName] then
                ESX.SetFunction(fnName, originalFunctions[fnName])
            else
                TriggerEvent("esx:sharedObjectUpdated")
            end
        end
    end
end

AddEventHandler("onResourceStop", onResourceStop)
AddEventHandler(("on%sResourceStop"):format(cache.context:gsub("^%l", string.upper)), onResourceStop)