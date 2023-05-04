-- It is NOT suggessted to set this to true as it opens opportunity for vulnerabilities and abuses.
-- Also for these events below try converting your scripts to use AddEventHandler instead of RegisterNetEvent, as if you don't, it acts the same as setting this variable to true!
local completeBackwardCompatibleEvents = false

if completeBackwardCompatibleEvents then
    RegisterNetEvent("esx:playerLoaded")
    RegisterNetEvent("esx:onPlayerLogout")
    RegisterNetEvent("esx:setAccountMoney")
    RegisterNetEvent("esx:addInventoryItem")
    RegisterNetEvent("esx:removeInventoryItem")
    RegisterNetEvent("esx:setMaxWeight")
    RegisterNetEvent("esx:setJob")
    RegisterNetEvent("esx:setWeaponTint")
    RegisterNetEvent("esx:updatePlayerData") -- hate this
    RegisterNetEvent("esx:setMetadata", function(currentMetadata)
        TriggerEvent("esx:updatePlayerData", "metadata", currentMetadata)
    end)
    RegisterNetEvent("esx:createPickup")
    RegisterNetEvent("esx:createMissingPickups")
end

ESX.RegisterSafeEvent("esx:playerLoaded", function(value)
    TriggerEvent("esx:playerLoaded", value.xPlayerClient, value.isNew, value.skin)
end)

ESX.RegisterSafeEvent("esx:setAccountMoney", function(value)
    TriggerEvent("esx:setAccountMoney", value.account)
end)

ESX.RegisterSafeEvent("esx:addInventoryItem", function(value)
    TriggerEvent("esx:addInventoryItem", value.itemName, value.itemCount, value.showNotification)
end)

ESX.RegisterSafeEvent("esx:removeInventoryItem", function(value)
    TriggerEvent("esx:removeInventoryItem", value.itemName, value.itemCount)
end)

ESX.RegisterSafeEvent("esx:setMaxWeight", function(value)
    TriggerEvent("esx:setMaxWeight", value.maxWeight)
end)

ESX.RegisterSafeEvent("esx:setJob", function(value)
    TriggerEvent("esx:setJob", value.currentJob, value.lastJob)
end)

ESX.RegisterSafeEvent("esx:setWeaponTint", function(value)
    TriggerEvent("esx:setWeaponTint", value.weaponName, value.weaponTintIndex)
end)

ESX.RegisterSafeEvent("esx:setMetadata", function(value)
    TriggerEvent("esx:setMetadata", value.currentMetadata, value.lastMetadata)
end)

ESX.RegisterSafeEvent("esx:createPickup", function(value)
    TriggerEvent("esx:createPickup", value.pickupId, value.label, value.coords, value.type, value.name, value.components, value.tintIndex)
end)

ESX.RegisterSafeEvent("esx:createMissingPickups", function(value)
    TriggerEvent("esx:createMissingPickups", value.pickups)
end)
