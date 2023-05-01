local completeBackwardCompatibleEvents = false

if completeBackwardCompatibleEvents then
    RegisterNetEvent("esx:setAccountMoney")
end

AddStateBagChangeHandler(("player:%s->esx:setAccountMoney"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:setAccountMoney", value.account)
end)
