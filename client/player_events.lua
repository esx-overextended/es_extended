local completeBackwardCompatibleEvents = false

if completeBackwardCompatibleEvents then
    RegisterNetEvent("esx:setAccountMoney")
    RegisterNetEvent("esx:addInventoryItem")
    RegisterNetEvent("esx:removeInventoryItem")
    RegisterNetEvent("esx:setMaxWeight")
    RegisterNetEvent("esx:setJob")
end

AddStateBagChangeHandler(("player:%s->esx:setAccountMoney"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:setAccountMoney", value.account)
end)

AddStateBagChangeHandler(("player:%s->esx:addInventoryItem"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:addInventoryItem", value.itemName, value.itemCount)
end)

AddStateBagChangeHandler(("player:%s->esx:removeInventoryItem"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:removeInventoryItem", value.itemName, value.itemCount)
end)

AddStateBagChangeHandler(("player:%s->esx:setMaxWeight"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:setMaxWeight", value.maxWeight)
end)

AddStateBagChangeHandler(("player:%s->esx:setJob"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:setJob", value.currentJob, value.lastJob)
end)
