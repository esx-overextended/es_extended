if GetResourceState("ox_inventory"):find("miss") then return end

Config.OxInventory = true

---@override
ESX.ShowInventory = nil

---@override
ESX.UI.ShowInventoryItemNotification = nil

function Core.StartServerSyncLoop() end ---@diagnostic disable-line: duplicate-set-field

function Core.StartDroppedItemsLoop() end ---@diagnostic disable-line: duplicate-set-field
