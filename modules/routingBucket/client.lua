ESX.RegisterSafeEvent("esx:setPlayerRoutingBucket", function(value)
    TriggerEvent("esx:setPlayerRoutingBucket", value.routingBucket)
end)

AddEventHandler("esx:setPlayerRoutingBucket", function(routingBucket)
    if not ESX.PlayerLoaded then return end

    ESX.SetPlayerData("routingBucket", routingBucket)
end)
