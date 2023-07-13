if GetResourceState("ox_inventory"):find("miss") then return end

Config.OxInventory = true

---@override
ESX.ShowInventory = nil

---@override
ESX.UI.ShowInventoryItemNotification = nil
