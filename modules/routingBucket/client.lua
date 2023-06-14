ESX.RegisterSafeEvent("esx:setPlayerRoutingBucket", function(value)
    TriggerEvent("esx:setPlayerRoutingBucket", value.routingBucket)
end)
