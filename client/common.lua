AddEventHandler("esx:getSharedObject", function(cb)
    return cb and cb(ESX)
end)

exports('getSharedObject', function()
    return ESX
end)

if GetResourceState('ox_inventory') ~= 'missing' then
    Config.OxInventory = true
end
