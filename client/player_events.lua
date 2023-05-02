-- It is NOT suggessted to set this to true as it opens opportunity for vulnerabilities and abuses.
-- Also for these events below try converting your scripts to use AddEventHandler instead of RegisterNetEvent, as if you don't, it acts the same as setting this variable to true!
local completeBackwardCompatibleEvents = false

if completeBackwardCompatibleEvents then
    RegisterNetEvent("esx:setAccountMoney")
    RegisterNetEvent("esx:addInventoryItem")
    RegisterNetEvent("esx:removeInventoryItem")
    RegisterNetEvent("esx:setMaxWeight")
    RegisterNetEvent("esx:setJob")
    RegisterNetEvent("esx:setWeaponTint")
end

AddStateBagChangeHandler(("player:%s->esx:setAccountMoney"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:setAccountMoney", value.account)
end)

AddStateBagChangeHandler(("player:%s->esx:addInventoryItem"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:addInventoryItem", value.itemName, value.itemCount, value.showNotification)
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

AddStateBagChangeHandler(("player:%s->esx:setWeaponTint"):format(cache.serverId), "global", function(_, _, value, _, _)
    if not value then return end

    TriggerEvent("esx:setWeaponTint", value.weaponName, value.weaponTintIndex)
end)
