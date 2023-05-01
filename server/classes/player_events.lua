local pattern = "([^%-]*)%-" -- pattern to find the first occurence of a hyphen

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler(nil, "global", function(_, key, value, _, _)
    if not value then return end

    local bagName = string.match(key, pattern)
    local playerId = bagName and tonumber(bagName:gsub("player:", ""), 10)

    if not playerId then return end

    local notEvent = bagName .. "->"
    local notEventLength = #notEvent
    -- local eventName = key:gsub(notEvent:gsub("([%-%%])", "%%%1"), "")

    if string.sub(key, 1, notEventLength) ~= notEvent then
        return print(("[^1ERROR^7] Mulfunctioned state bag ^5name^7 received for triggering player-related events (^2%s^7)"):format(key))
    end

    if value.triggerServer ~= false then
        local eventName = string.sub(key, notEventLength + 1)

        if eventName == "esx:setAccountMoney" then
            TriggerEvent(eventName, playerId, value.accountName, value.money, value.reason)
        elseif eventName == "esx:setMaxWeight" then
            TriggerEvent(eventName, playerId, value.maxWeight)
        else
            print(("[^3WARNING^7] The event ^5name^7 received using global state bag has not been setup for ^5server-side^7 yet(^2%s^7)"):format(eventName))
        end
    end

    GlobalState:set(key, nil, true)
end)