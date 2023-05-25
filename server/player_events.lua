ESX.RegisterSafeEvent("esx:playerLoaded", function(value)
    TriggerEvent("esx:playerLoaded", value.playerId, value.xPlayerServer, value.isNew)
end)

ESX.RegisterSafeEvent("esx:setAccountMoney", function(value)
    TriggerEvent("esx:setAccountMoney", value.source, value.accountName, value.money, value.reason)
end)

ESX.RegisterSafeEvent("esx:setMaxWeight", function(value)
    TriggerEvent("esx:setMaxWeight", value.source, value.maxWeight)
end)

ESX.RegisterSafeEvent("esx:setJob", function(value)
    TriggerEvent("esx:setJob", value.source, value.currentJob, value.lastJob)
end)

ESX.RegisterSafeEvent("esx:setMetadata", function(value)
    TriggerEvent("esx:setMetadata", value.source, value.currentMetadata, value.lastMetadata)
end)

ESX.RegisterSafeEvent("esx:setPlayerRoutingBucket", function(value)
    TriggerEvent("esx:setPlayerRoutingBucket", value.source, value.routingBucket)
end)
