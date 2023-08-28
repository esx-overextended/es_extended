ESX.OneSync = {}

---@param bagName string
---@return number?, number?
function ESX.OneSync.GetEntityFromStateBag(bagName)
    local netId = tonumber(bagName:gsub("entity:", ""), 10)
    local doesNetIdExist, timeout = false, 0

    while not doesNetIdExist and timeout < 1000 do
        Wait(10)
        timeout += 1
        doesNetIdExist = NetworkDoesEntityExistWithNetworkId(netId)
    end

    if not doesNetIdExist then
        return ESX.Trace(("Statebag (^3%s^7) timed out after waiting %s ticks for its entity creation!"):format(bagName, timeout), "warning", true)
    end

    Wait(500)

    local entity = NetworkDoesEntityExistWithNetworkId(netId) and NetworkGetEntityFromNetworkId(netId)

    if not entity or entity == 0 then return end

    return entity, netId
end
