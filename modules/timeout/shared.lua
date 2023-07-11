local activeTimeouts, cancelledTimeouts = {}, {}
local timeoutsCount = 0

---@param msec number
---@param cb? function
---@return number
ESX.SetTimeout = function(msec, cb)
    timeoutsCount += 1
    local timeoutId = timeoutsCount
    activeTimeouts[timeoutId] = true

    SetTimeout(msec, function()
        activeTimeouts[timeoutId] = nil

        if not cancelledTimeouts[timeoutId] then return cb and cb() end

        cancelledTimeouts[timeoutId] = nil
    end)

    return timeoutId
end

---@param timeoutId number
---@return boolean
ESX.ClearTimeout = function(timeoutId)
    if not activeTimeouts[timeoutId] then return false end

    cancelledTimeouts[timeoutId] = true

    return true
end
