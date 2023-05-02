ESX.RegisterSafeEvent("esx:setAccountMoney", function(value)
    TriggerEvent("esx:setAccountMoney", value.source, value.accountName, value.money, value.reason)
end)

ESX.RegisterSafeEvent("esx:addInventoryItem")

ESX.RegisterSafeEvent("esx:removeInventoryItem")

ESX.RegisterSafeEvent("esx:setMaxWeight", function(value)
    TriggerEvent("esx:setMaxWeight", value.source, value.maxWeight)
end)

ESX.RegisterSafeEvent("esx:setJob", function(value)
    TriggerEvent("esx:setJob", value.source, value.currentJob, value.lastJob)
end)

ESX.RegisterSafeEvent("esx:setWeaponTint")

ESX.RegisterSafeEvent("esx:setMetadata", function(value)
    TriggerEvent("esx:setMetadata", value.source, value.currentMetadata, value.lastMetadata)
end)