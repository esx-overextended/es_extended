if GetResourceState("ox_inventory"):find("miss") then return end

Config.OxInventory = true

SetConvarReplicated("inventory:framework", "esx-ox")
SetConvarReplicated("inventory:weight", Config.MaxWeight * 1000) ---@diagnostic disable-line: param-type-mismatch

ESX.CreatePickup = nil

local Inventory

AddEventHandler("ox_inventory:loadInventory", function(module)
    Inventory = module
end)

ESX.RegisterPlayerMethodOverrides({
    getInventory = function(self)
        return function(minimal)
            if minimal then
                local minimalInventory = {}

                for k, v in pairs(self.inventory) do
                    if v.count and v.count > 0 then
                        local metadata = v.metadata

                        if v.metadata and next(v.metadata) == nil then
                            metadata = nil
                        end

                        minimalInventory[#minimalInventory + 1] = {
                            name = v.name,
                            count = v.count,
                            slot = k,
                            metadata = metadata
                        }
                    end
                end

                return minimalInventory
            end

            return self.inventory
        end
    end,

    getLoadout = function(_)
        return function()
            return {}
        end
    end,

    ---Sets money for the specified account of the player.
    ---@param self xPlayer
    setAccountMoney = function(self)
        ---@param accountName string
        ---@param money number
        ---@param reason? string
        ---@return boolean
        return function(accountName, money, reason)
            money = tonumber(money) --[[@as number]]
            reason = reason or "Unknown"

            if not money or money < 0 then
                ESX.Trace(("Tried to set account ^5%s^0 for Player ^5%s^0 to with invalid value -> ^5%s^7"):format(accountName, self.playerId, money), "error", true)
                return false
            end

            local account = self.getAccount(accountName)

            if not account then
                ESX.Trace(("Tried to set money to an invalid account ^5%s^0 for Player ^5%s^0"):format(accountName, self.playerId), "error", true)
                return false
            end

            money = account.round and ESX.Math.Round(money) or money
            self.accounts[account.index].money = money

            self.triggerSafeEvent("esx:setAccountMoney", { account = account, accountName = accountName, money = money, reason = reason }, { server = true, client = true })

            if Inventory.accounts[accountName] then
                return Inventory.SetItem(self.source, accountName, money)
            end

            return true
        end
    end,

    ---Adds money to the specified account of the player.
    ---@param self xPlayer
    addAccountMoney = function(self)
        ---@param accountName string
        ---@param money number
        ---@param reason? string
        ---@return boolean
        return function(accountName, money, reason)
            money = tonumber(money) --[[@as number]]
            reason = reason or "Unknown"

            if not money or money <= 0 then
                ESX.Trace(("Tried to add account ^5%s^0 for Player ^5%s^0 with an invalid value -> ^5%s^7"):format(accountName, self.playerId, money), "error", true)
                return false
            end

            local account = self.getAccount(accountName)

            if not account then
                ESX.Trace(("Tried to add money to an invalid account ^5%s^0 for Player ^5%s^0"):format(accountName, self.playerId), "error", true)
                return false
            end

            money = account.round and ESX.Math.Round(money) or money
            self.accounts[account.index].money += money

            TriggerEvent("esx:addAccountMoney", self.source, accountName, money, reason)
            self.triggerSafeEvent("esx:setAccountMoney", { account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason })

            if Inventory.accounts[accountName] then
                return Inventory.AddItem(self.source, accountName, money)
            end

            return true
        end
    end,

    ---Removes money from the specified account of the player.
    ---@param self xPlayer
    removeAccountMoney = function(self)
        ---@param accountName string
        ---@param money number
        ---@param reason? string
        ---@return boolean
        return function(accountName, money, reason)
            money = tonumber(money) --[[@as number]]
            reason = reason or "Unknown"

            if not money or money <= 0 then
                ESX.Trace(("Tried to remove account ^5%s^0 for Player ^5%s^0 with an invalid value -> ^5%s^7"):format(accountName, self.playerId, money), "error", true)
                return false
            end

            local account = self.getAccount(accountName)

            if not account then
                ESX.Trace(("Tried to remove money from an invalid account ^5%s^0 for Player ^5%s^0"):format(accountName, self.playerId), "error", true)
                return false
            end

            money = account.round and ESX.Math.Round(money) or money
            self.accounts[account.index].money = self.accounts[account.index].money - money

            TriggerEvent("esx:removeAccountMoney", self.source, accountName, money, reason)
            self.triggerSafeEvent("esx:setAccountMoney", { account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason })

            if Inventory.accounts[accountName] then
                return Inventory.RemoveItem(self.source, accountName, money)
            end

            return true
        end
    end,

    getInventoryItem = function(self)
        return function(name, metadata)
            return Inventory.GetItem(self.source, name, metadata)
        end
    end,

    addInventoryItem = function(self)
        return function(name, count, metadata, slot)
            return Inventory.AddItem(self.source, name, count or 1, metadata, slot)
        end
    end,

    removeInventoryItem = function(self)
        return function(name, count, metadata, slot)
            return Inventory.RemoveItem(self.source, name, count or 1, metadata, slot)
        end
    end,

    setInventoryItem = function(self)
        return function(name, count, metadata)
            return Inventory.SetItem(self.source, name, count, metadata)
        end
    end,

    canCarryItem = function(self)
        return function(name, count, metadata)
            return Inventory.CanCarryItem(self.source, name, count, metadata)
        end
    end,

    canSwapItem = function(self)
        return function(firstItem, firstItemCount, testItem, testItemCount)
            return Inventory.CanSwapItem(self.source, firstItem, firstItemCount, testItem, testItemCount)
        end
    end,

    setMaxWeight = function(self)
        return function(newWeight)
            self.maxWeight = newWeight
            self.triggerSafeEvent("esx:setMaxWeight", { maxWeight = newWeight }, { server = true, client = true })
            return Inventory.Set(self.source, "maxWeight", newWeight)
        end
    end,

    addWeapon = function(_)
        return function() end
    end,

    addWeaponComponent = function(_)
        return function() end
    end,

    addWeaponAmmo = function(_)
        return function() end
    end,

    updateWeaponAmmo = function(_)
        return function() end
    end,

    setWeaponTint = function(_)
        return function() end
    end,

    getWeaponTint = function(_)
        return function() end
    end,

    removeWeapon = function(_)
        return function() end
    end,

    removeWeaponComponent = function(_)
        return function() end
    end,

    removeWeaponAmmo = function(_)
        return function() end
    end,

    hasWeaponComponent = function(_)
        return function()
            return false
        end
    end,

    hasWeapon = function(_)
        return function()
            return false
        end
    end,

    hasItem = function(self)
        return function(name, metadata)
            return Inventory.GetItem(self.source, name, metadata)
        end
    end,

    getWeapon = function(_)
        return function() end
    end,

    syncInventory = function(self)
        return function(weight, maxWeight, items, money)
            self.weight, self.maxWeight = weight, maxWeight
            self.inventory = items

            if money then
                for accountName, amount in pairs(money) do
                    local account = self.getAccount(accountName)

                    if account and ESX.Math.Round(account.money) ~= amount then
                        account.money = amount

                        self.triggerSafeEvent("esx:setAccountMoney", { account = account, accountName = accountName, money = amount, reason = "Sync account with item" }, { server = true, client = true })
                    end
                end
            end
        end
    end
})

AddEventHandler("esx:playerLoaded", function(source, xPlayer, isNew)
    if not isNew or not Config.StartingAccountMoney.money then return end

    Wait(1000) -- wait until the client initializes

    if not ESX.Players[source] then return end

    xPlayer.setMoney(Config.StartingAccountMoney.money)
end)