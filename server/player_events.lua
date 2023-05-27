ESX.RegisterSafeEvent("esx:playerLoaded", function(value)
    TriggerEvent("esx:playerLoaded", value.playerId, value.xPlayerServer, value.isNew)
end)

ESX.RegisterSafeEvent("esx:setAccountMoney", function(value)
    TriggerEvent("esx:setAccountMoney", value.source, value.accountName, value.money, value.reason)
end)

ESX.RegisterSafeEvent("esx:setMaxWeight", function(value)
    TriggerEvent("esx:setMaxWeight", value.source, value.maxWeight)
end)

ESX.RegisterSafeEvent("esx:setGroups", function(value)
    TriggerEvent("esx:setGroups", value.source, value.currentGroups, value.lastGroups)
end)

ESX.RegisterSafeEvent("esx:addGroup", function(value)
    TriggerEvent("esx:addGroup", value.source, value.groupName, value.groupGrade)
end)

ESX.RegisterSafeEvent("esx:removeGroup", function(value)
    TriggerEvent("esx:removeGroup", value.source, value.groupName, value.groupGrade)
end)

ESX.RegisterSafeEvent("esx:setJob", function(value)
    TriggerEvent("esx:setJob", value.source, value.currentJob, value.lastJob)
end)

ESX.RegisterSafeEvent("esx:setDuty", function(value)
    TriggerEvent("esx:setDuty", value.source, value.duty)
end)

ESX.RegisterSafeEvent("esx:setMetadata", function(value)
    TriggerEvent("esx:setMetadata", value.source, value.currentMetadata, value.lastMetadata)
end)

ESX.RegisterSafeEvent("esx:setPlayerRoutingBucket", function(value)
    TriggerEvent("esx:setPlayerRoutingBucket", value.source, value.routingBucket)
end)
