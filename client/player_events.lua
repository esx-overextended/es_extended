-- It is NOT suggessted to set these events to true to be registered as networked events as they open opportunity for vulnerabilities and abuses.
-- Also for these events below try converting your scripts to use AddEventHandler instead of RegisterNetEvent, as if you don't, it acts the same as setting them to true(networked)!
-- However, if you cannot convert all of these below events in your scripts to use AddEventHandler instead of RegisterNetEvent(escrowed scripts), you could set them to true to be networked.

local events = {
    ["esx:playerLoaded"] = false,
    ["esx:onPlayerLogout"] = false,
    ["esx:setAccountMoney"] = false,
    ["esx:addInventoryItem"] = false,
    ["esx:removeInventoryItem"] = false,
    ["esx:setMaxWeight"] = false,
    ["esx:setJob"] = false,
    ["esx:setWeaponTint"] = false,
    ["esx:updatePlayerData"] = false,
    ["esx:setMetadata"] = false,
    ["esx:createPickup"] = false,
    ["esx:createMissingPickups"] = false,
    ["esx:removePickup"] = false,
    ["esx:registerSuggestions"] = false,
    ["esx:showNotification"] = false,
    ["esx:showAdvancedNotification"] = false,

}

do
    for eventName, networked in pairs(events) do
        if networked then RegisterNetEvent(eventName) end
    end

    if events["esx:updatePlayerData"] then
        AddEventHandler("esx:setMetadata", function(currentMetadata)
            TriggerEvent("esx:updatePlayerData", "metadata", currentMetadata)
        end)
    end
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

ESX.RegisterSafeEvent("esx:removePickup", function(value)
    TriggerEvent("esx:removePickup", value.pickupId)
end)

ESX.RegisterSafeEvent("esx:registerSuggestions", function(value)
    TriggerEvent("esx:registerSuggestions", value.registeredCommands)
end)

ESX.RegisterSafeEvent("esx:showNotification", function(value)
    TriggerEvent("esx:showNotification", value.notifyText, value.notifyType, value.notifyDuration, value.notifyExtra)
end)


ESX.RegisterSafeEvent("esx:showAdvancedNotification", function(value)
    TriggerEvent("esx:showAdvancedNotification", value.sender, value.subject, value.message, value.textureDict, value.iconType, value.flash, value.saveToBrief, value.hudColorIndex)
end)
