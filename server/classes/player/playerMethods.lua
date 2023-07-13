local xPlayerMethods = {
    ---Triggers a client event for the player
    ---@param self xPlayer
    triggerEvent = function(self)
        ---@param eventName string name of the client event
        ---@param ... any
        return function(eventName, ...)
            TriggerClientEvent(eventName, self.source, ...)
        end
    end,

    ---Sets the player's coordinates.
    ---@param self xPlayer
    setCoords = function(self)
        ---@param coords table | vector3 | vector4
        return function(coords)
            local ped = GetPlayerPed(self.source)
            local vector = vector4(coords?.x, coords?.y, coords?.z, coords?.w or coords?.heading or 0.0)

            if not vector then return end

            SetEntityCoords(ped, vector.x, vector.y, vector.z, false, false, false, false)
            SetEntityHeading(ped, vector.w)
        end
    end,

    ---Gets the player's coordinates.
    ---@param self xPlayer
    getCoords = function(self)
        ---@param vector? boolean whether to return the player coords as vector4 or as table
        ---@return vector4 | table
        return function(vector)
            local playerPed = GetPlayerPed(self.source)
            local coords = GetEntityCoords(playerPed)
            local heading = GetEntityHeading(playerPed)

            return vector and vector4(coords.x, coords.y, coords.z, heading) or {x = coords.x, y = coords.y, z = coords.z, heading = heading}
        end
    end,

    ---Kicks the player out with an optional reason.
    ---@param self xPlayer
    kick = function(self)
        ---@param reason? string
        return function(reason)
            DropPlayer(tostring(self.source), reason --[[@as string]])
        end
    end,

    ---Sets the player's money to the specified value.
    ---@param self xPlayer
    setMoney = function(self)
        ---@param money number
        ---@return boolean
        return function(money)
            money = ESX.Math.Round(money)
            return self.setAccountMoney("money", money)
        end
    end,

    ---Gets the player's money value.
    ---@param self xPlayer
    getMoney = function(self)
        ---@return number
        return function()
            return self.getAccount("money")?.money
        end
    end,

    ---Adds the specified value to the player's money.
    ---@param self xPlayer
    addMoney = function(self)
        ---@param money number
        ---@param reason? string
        ---@return boolean
        return function(money, reason)
            money = ESX.Math.Round(money)
            return self.addAccountMoney("money", money, reason)
        end
    end,

    ---Removes the specified value from the player's money.
    ---@param self xPlayer
    removeMoney = function(self)
        ---@param money number
        ---@param reason? string
        ---@return boolean
        return function(money, reason)
            money = ESX.Math.Round(money)
            return self.removeAccountMoney("money", money, reason)
        end
    end,

    ---Gets the player's identifier.
    ---@param self xPlayer
    getIdentifier = function(self)
        ---@return string
        return function()
            return self.identifier
        end
    end,

    ---Gets the player's Rockstar license.
    ---@param self xPlayer
    getLicense = function(self)
        ---@return string
        return function()
            return self.license
        end
    end,

    ---Checks if the player has the specified group.
    ---@param self xPlayer
    hasGroup = function(self)
        ---@param groupName string
        ---@param groupGrade? number
        ---@return boolean, number | nil
        return function(groupName, groupGrade)
            if not groupName then return false end

            if groupGrade ~= nil then return self.groups[groupName] == groupGrade end

            return self.groups[groupName] ~= nil, self.groups[groupName]
        end
    end,

    ---Adds the specified group to the player's groups.
    ---@param self xPlayer
    addGroup = function(self)
        ---@param groupName string
        ---@param groupGrade number
        ---@return boolean
        return function(groupName, groupGrade)
            if type(groupName) ~= "string" or type(groupGrade) ~= "number" or self.hasGroup(groupName, groupGrade) then return false end

            if not ESX.DoesGroupExist(groupName, groupGrade) then
                ESX.Trace(("Ignoring invalid ^5.addGroup(%s, %s)^7 usage for Player ^5%s^7"):format(groupName, groupGrade, self.source), "warning", true)
                return false
            end

            local triggerRemoveGroup, previousGroup, groupToRemove = false, self.group, nil
            local lastGroups = json.decode(json.encode(self.groups))

            if Config.AdminGroupsByName[groupName] or groupName == Core.DefaultGroup then
                triggerRemoveGroup = true
                groupToRemove = previousGroup
                self.groups[self.group], self.group = nil, groupName
            elseif self.hasGroup(groupName) then
                triggerRemoveGroup = true
                groupToRemove = groupName
            end

            self.groups[groupName] = groupGrade

            lib.addPrincipal(("identifier.%s"):format(self.license), ("group.%s:%s"):format(groupName, groupGrade))

            self.triggerSafeEvent("esx:setGroups", {currentGroups = self.groups, lastGroups = lastGroups}, {server = true, client = true})
            self.triggerSafeEvent("esx:addGroup", {groupName = groupName, groupGrade = groupGrade}, {server = true, client = true})

            if triggerRemoveGroup then
                lib.removePrincipal(("identifier.%s"):format(self.license), ("group.%s:%s"):format(groupToRemove, lastGroups[groupToRemove]))

                self.triggerSafeEvent("esx:removeGroup", {groupName = groupToRemove, groupGrade = lastGroups[groupToRemove]}, {server = true, client = true})
            end

            Player(self.source).state:set("groups", self.groups, true)
            Player(self.source).state:set("group", self.group, true)

            return true
        end
    end,

    ---Removes the specified group from the player's groups.
    ---@param self xPlayer
    removeGroup = function(self)
        ---@param groupName string
        ---@return boolean
        return function(groupName)
            if type(groupName) ~= "string" or groupName == Core.DefaultGroup or not self.hasGroup(groupName) then return false end

            local triggerAddGroup, defaultGroup = false, Core.DefaultGroup
            local lastGroups = json.decode(json.encode(self.groups))

            lib.removePrincipal(("identifier.%s"):format(self.license), ("group.%s:%s"):format(groupName, lastGroups[groupName]))

            self.groups[groupName] = nil

            if Config.AdminGroupsByName[groupName] then
                triggerAddGroup = true
                self.groups[defaultGroup], self.group = 0, defaultGroup
            end

            self.triggerSafeEvent("esx:setGroups", {currentGroups = self.groups, lastGroups = lastGroups}, {server = true, client = true})
            self.triggerSafeEvent("esx:removeGroup", {groupName = groupName, groupGrade = lastGroups[groupName]}, {server = true, client = true})

            if triggerAddGroup then
                lib.addPrincipal(("identifier.%s"):format(self.license), ("group.%s:%s"):format(defaultGroup, self.groups[defaultGroup]))

                self.triggerSafeEvent("esx:addGroup", {groupName = defaultGroup, groupGrade = self.groups[defaultGroup]}, {server = true, client = true})
            end

            Player(self.source).state:set("groups", self.groups, true)
            Player(self.source).state:set("group", self.group, true)

            return true
        end
    end,

    ---Gets all of the player's groups.
    ---@param self xPlayer
    getGroups = function(self)
        ---@return table<string, number>
        return function()
            return self.groups
        end
    end,

    ---Sets the player's permission/user/admin group.
    ---@param self xPlayer
    setGroup = function(self)
        ---@param newGroup string
        ---@return boolean
        return function(newGroup)
            if not Config.AdminGroupsByName[newGroup] and Core.DefaultGroup ~= newGroup then
                ESX.Trace(("Ignoring invalid ^5.setGroup(%s)^7 usage for Player ^5%s^7"):format(newGroup, self.source), "warning", true)
                return false
            end

            return self.addGroup(newGroup, 0)
        end
    end,

    ---Gets the player's permission/user/admin group.
    ---@param self xPlayer
    getGroup = function(self)
        ---@return string
        return function()
            return self.group
        end
    end,

    ---Sets the specified value to the key variable for the player.
    ---@param self xPlayer
    set = function(self)
        ---@param key string
        ---@param value any
        return function(key, value) -- TODO: sync with client using safe event
            self.variables[key] = value
            Player(self.source).state:set(key, value, true)
        end
    end,

    ---Gets the value of the specified key variable from the player, returning the entire table if key is omitted.
    ---@param self xPlayer
    get = function(self)
        ---@param key? string
        ---@return any
        return function(key)
            return key and self.variables[key] or self.variables
        end
    end,

    ---Gets all of the player's accounts.
    ---@param self xPlayer
    getAccounts = function(self)
        ---@param minimal? boolean
        ---@return table
        return function(minimal)
            if not minimal then return self.accounts end

            local minimalAccounts = {}

            for i = 1, #self.accounts do
                minimalAccounts[self.accounts[i].name] = self.accounts[i].money
            end

            return minimalAccounts
        end
    end,

    ---Gets the specified account's data of the player.
    ---@param self xPlayer
    getAccount = function(self)
        ---@param accountName string
        ---@return table?
        return function(accountName)
            accountName = type(accountName) == "string" and accountName:lower() --[[@as string]]
            local accountData

            if accountName then
                for i = 1, #self.accounts do
                    if self.accounts[i].name:lower() == accountName then
                        accountData = self.accounts[i]
                        break
                    end
                end
            end

            return accountData
        end
    end,

    ---Gets all of the player's inventory data.
    ---@param self xPlayer
    getInventory = function(self)
        ---@param minimal? boolean
        ---@return table
        return function(minimal)
            if not minimal then return self.inventory end

            local minimalInventory = {}

            for _, v in ipairs(self.inventory) do
                if v.count > 0 then
                    minimalInventory[v.name] = v.count
                end
            end

            return minimalInventory
        end
    end,

    ---Gets all of the player's loadout data.
    ---@param self xPlayer
    getLoadout = function(self)
        ---@param minimal? boolean
        ---@return table
        return function(minimal)
            if not minimal then return self.loadout end

            local minimalLoadout = {}

            for _, v in ipairs(self.loadout) do
                minimalLoadout[v.name] = {ammo = v.ammo}
                if v.tintIndex > 0 then minimalLoadout[v.name].tintIndex = v.tintIndex end

                if #v.components > 0 then
                    local components = {}

                    for _, component in ipairs(v.components) do
                        if component ~= "clip_default" then
                            components[#components + 1] = component
                        end
                    end

                    if #components > 0 then
                        minimalLoadout[v.name].components = components
                    end
                end
            end

            return minimalLoadout
        end
    end,

    ---Gets the player's name.
    ---@param self xPlayer
    getName = function(self)
        ---@return string
        return function()
            return self.name
        end
    end,

    ---Sets the player's name.
    ---@param self xPlayer
    setName = function(self)
        ---@param newName string
        return function(newName)
            self.name = newName
            Player(self.source).state:set("name", self.name, true)
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

            self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = money, reason = reason}, {server = true, client = true})

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
            self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason})

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
            self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason})

            return true
        end
    end,

    ---Gets the specified item data from the player's inventory.
    ---@param self xPlayer
    getInventoryItem = function(self)
        ---@param itemName string
        ---@return table?
        return function(itemName)
            local itemData

            for _, item in ipairs(self.inventory) do
                if item.name == itemName then
                    itemData = item
                    break
                end
            end

            return itemData
        end
    end,

    ---Adds the specified item to the player's inventory.
    ---@param self xPlayer
    addInventoryItem = function(self)
        ---@param itemName string
        ---@param itemCount? number defaults to 1 if not provided
        ---@return boolean
        return function(itemName, itemCount)
            local item = self.getInventoryItem(itemName)

            if not item then return false end

            itemCount = type(itemCount) == "number" and ESX.Math.Round(itemCount) or 1
            item.count += itemCount
            self.weight += (item.weight * itemCount)

            TriggerEvent("esx:onAddInventoryItem", self.source, item.name, item.count)
            self.triggerSafeEvent("esx:addInventoryItem", {itemName = item.name, itemCount = item.count})

            return true
        end
    end,

    ---Removes the specified item from the player's inventory.
    ---@param self xPlayer
    removeInventoryItem = function(self)
        ---@param itemName string
        ---@param itemCount? number defaults to 1 if not provided
        ---@return boolean
        return function(itemName, itemCount)
            local item = self.getInventoryItem(itemName)

            if not item then return false end

            itemCount = type(itemCount) == "number" and ESX.Math.Round(itemCount) or 1

            local newCount = item.count - itemCount

            if newCount < 0 then ESX.Trace(("Tried to remove non-existance count(%s) of %s item for Player ^5%s^0"):format(itemCount, itemName, self.playerId), "error", true) return false end

            item.count = newCount
            self.weight = self.weight - (item.weight * itemCount)

            TriggerEvent("esx:onRemoveInventoryItem", self.source, item.name, item.count)
            self.triggerSafeEvent("esx:removeInventoryItem", {itemName = item.name, itemCount = item.count})

            return true
        end
    end,

    ---Set the specified item count in the player's inventory.
    ---@param self xPlayer
    setInventoryItem = function(self)
        ---@param itemName string
        ---@param itemCount number
        ---@return boolean
        return function(itemName, itemCount)
            local item = self.getInventoryItem(itemName)
            itemCount = type(itemCount) == "number" and ESX.Math.Round(itemCount) --[[@as number]]

            if not item or not itemCount or itemCount <= 0 then return false end

            return itemCount > item.count and self.addInventoryItem(item.name, itemCount - item.count) or self.removeInventoryItem(item.name, item.count - itemCount)
        end
    end,

    ---Gets the player's inventory weight.
    ---@param self xPlayer
    getWeight = function(self)
        ---@return number
        return function()
            return self.weight
        end
    end,

    ---Gets the player's maximum inventory weight.
    ---@param self xPlayer
    getMaxWeight = function(self)
        ---@return number
        return function()
            return self.maxWeight
        end
    end,

    ---Sets the player's maximum inventory weight.
    ---@param self xPlayer
    setMaxWeight = function(self)
        ---@param newWeight number
        return function(newWeight)
            self.maxWeight = newWeight
            self.triggerSafeEvent("esx:setMaxWeight", {maxWeight = newWeight}, {server = true, client = true})
        end
    end,

    ---Checks if the player does have enough space in inventory to carry the specified item count(s).
    ---@param self xPlayer
    canCarryItem = function(self)
        ---@param itemName string
        ---@param itemCount number
        ---@return boolean
        return function(itemName, itemCount)
            if not ESX.Items[itemName] then ESX.Trace(("Item ^5'%s'^7 was used but does not exist!"):format(itemName), "warning", true) return false end

            local currentWeight, itemWeight = self.weight, ESX.Items[itemName].weight
            local newWeight = currentWeight + (itemWeight * itemCount)

            return newWeight <= self.maxWeight
        end
    end,

    ---Checks if 2 items with the specified counts can be swapped in the player's inventory based on max inventory weight.
    ---@param self xPlayer
    canSwapItem = function(self)
        ---@param firstItem string
        ---@param firstItemCount number
        ---@param testItem string
        ---@param testItemCount number
        ---@return boolean
        return function(firstItem, firstItemCount, testItem, testItemCount)
            local firstItemObject = self.getInventoryItem(firstItem)
            local testItemObject = self.getInventoryItem(testItem)

            if not firstItemObject or not testItemObject or firstItemObject.count < firstItemCount then return false end

            local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
            local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

            return weightWithTestItem <= self.maxWeight
        end
    end,

    ---Gets the player's job object.
    ---@param self xPlayer
    getJob = function(self)
        ---@return table
        return function()
            return self.job
        end
    end,

    ---Sets job for the player.
    ---@param self xPlayer
    setJob = function(self)
        ---@param job string
        ---@param grade number | string
        ---@param duty? boolean if not provided, it will use the job's default duty value
        ---@return boolean
        return function(job, grade, duty)
            if not ESX.DoesJobExist(job, grade) then ESX.Trace(("Ignoring invalid ^5.setJob()^7 usage for Player ^5%s^7, Job: ^5%s^7"):format(self.source, job), "warning", true) return false end

            grade = tostring(grade)
            local lastJob = json.decode(json.encode(self.job))
            local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

            self.job.id                   = jobObject.id
            self.job.name                 = jobObject.name
            self.job.label                = jobObject.label
            self.job.type                 = jobObject.type
            self.job.duty                 = type(duty) == "boolean" and duty or jobObject.default_duty --[[@as boolean]]
            self.job.grade                = tonumber(grade)
            self.job.grade_name           = gradeObject.name
            self.job.grade_label          = gradeObject.label
            self.job.grade_salary         = gradeObject.salary
            self.job.grade_offduty_salary = gradeObject.offduty_salary
            self.job.skin_male            = gradeObject.skin_male and json.decode(gradeObject.skin_male) or {}     --[[@diagnostic disable-line: param-type-mismatch]]
            self.job.skin_female          = gradeObject.skin_female and json.decode(gradeObject.skin_female) or {} --[[@diagnostic disable-line: param-type-mismatch]]

            self.triggerSafeEvent("esx:setJob", {currentJob = self.job, lastJob = lastJob}, {server = true, client = true})
            Player(self.source).state:set("job", self.job, true)

            self.triggerSafeEvent("esx:setDuty", {duty = self.job.duty}, {server = true, client = true})
            Player(self.source).state:set("duty", self.job.duty, true)

            return true
        end
    end,

    ---Gets the player's job duty state.
    ---@param self xPlayer
    getDuty = function(self)
        ---@return boolean
        return function()
            return self.job.duty
        end
    end,

    ---Sets the player's job duty state.
    ---@param self xPlayer
    setDuty = function(self)
        ---@param duty boolean
        ---@return boolean
        return function(duty)
            if type(duty) ~= "boolean" then return false end

            return self.setJob(self.job.name, self.job.grade, duty)
        end
    end,

    ---Adds a weapon with the specified ammo to the player's loadout.
    ---@param self xPlayer
    addWeapon = function(self)
        ---@param weaponName string
        ---@param ammo number
        ---@return boolean
        return function(weaponName, ammo)
            if self.hasWeapon(weaponName) then return false end

            local weaponLabel = ESX.GetWeaponLabel(weaponName)
            self.loadout[#self.loadout+1] = {
                name = weaponName,
                ammo = ammo,
                label = weaponLabel,
                components = {},
                tintIndex = 0
            }

            GiveWeaponToPed(GetPlayerPed(self.source), joaat(weaponName), ammo, false, false)
            self.triggerSafeEvent("esx:addInventoryItem", {itemName = weaponLabel, itemCount = false, showNotification = true})

            return true
        end
    end,

    ---Removes the specified weapon from the player's loadout.
    ---@param self xPlayer
    removeWeapon = function(self)
        ---@param weaponName string
        ---@return boolean
        return function(weaponName)
            for k, v in ipairs(self.loadout) do
                if v.name == weaponName then
                    for _, v2 in ipairs(v.components) do
                        self.removeWeaponComponent(weaponName, v2)
                    end

                    table.remove(self.loadout, k)

                    local ped, weaponHash = GetPlayerPed(self.source), joaat(weaponName)

                    RemoveWeaponFromPed(ped, weaponHash)
                    SetPedAmmo(ped, weaponHash, 0)
                    self.triggerSafeEvent("esx:removeInventoryItem", {itemName = v.label, itemCount = false, showNotification = true})

                    return true
                end
            end

            return false
        end
    end,

    ---Adds a specific component to the player's weapon.
    ---@param self xPlayer
    addWeaponComponent = function(self)
        ---@param weaponName string
        ---@param weaponComponent string
        ---@return boolean
        return function(weaponName, weaponComponent)
            local loadoutNum, weapon = self.getWeapon(weaponName)

            if not weapon then return false end

            local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if not component or self.hasWeaponComponent(weaponName, weaponComponent) then return false end

            self.loadout[loadoutNum].components[#self.loadout[loadoutNum].components + 1] = weaponComponent
            local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

            GiveWeaponComponentToPed(GetPlayerPed(self.source), joaat(weaponName), componentHash)
            self.triggerSafeEvent("esx:addInventoryItem", {itemName = component.label, itemCount = false, showNotification = true})

            return true
        end
    end,

    ---Removes the specified weapon component from the player's loadout.
    ---@param self xPlayer
    removeWeaponComponent = function(self)
        ---@param weaponName string
        ---@param weaponComponent string
        ---@return boolean
        return function(weaponName, weaponComponent)
            local loadoutNum, weapon = self.getWeapon(weaponName)

            if not weapon then return false end

            local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if not component or not self.hasWeaponComponent(weaponName, weaponComponent) then return false end

            for k, v in ipairs(self.loadout[loadoutNum].components) do
                if v == weaponComponent then
                    table.remove(self.loadout[loadoutNum].components, k)
                    break
                end
            end

            RemoveWeaponComponentFromPed(GetPlayerPed(self.source), joaat(weaponName), component.hash)
            self.triggerSafeEvent("esx:removeInventoryItem", {itemName = component.label, itemCount = false, showNotification = true})

            return true
        end
    end,

    ---Sets ammo of the player's specified weapon.
    ---@param self xPlayer
    updateWeaponAmmo = function(self)
        ---@param weaponName string
        ---@param ammoCount number
        ---@return boolean
        return function(weaponName, ammoCount)
            local _, weapon = self.getWeapon(weaponName)

            if not weapon then return false end

            weapon.ammo = ammoCount
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)

            return true
        end
    end,

    ---Adds ammo to the player's specified weapon.
    ---@param self xPlayer
    addWeaponAmmo = function(self)
        ---@param weaponName string
        ---@param ammoCount number
        ---@return boolean
        return function(weaponName, ammoCount)
            local _, weapon = self.getWeapon(weaponName)

            if not weapon then return false end

            weapon.ammo += ammoCount
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)

            return true
        end
    end,

    ---Removes ammo from the player's specified weapon.
    ---@param self xPlayer
    removeWeaponAmmo = function(self)
        ---@param weaponName string
        ---@param ammoCount number
        ---@return boolean
        return function(weaponName, ammoCount)
            local _, weapon = self.getWeapon(weaponName)

            if not weapon then return false end

            weapon.ammo = weapon.ammo - ammoCount
            self.updateWeaponAmmo(weaponName, weapon.ammo)

            return true
        end
    end,

    ---Sets tint of the player's specified weapon.
    ---@param self xPlayer
    setWeaponTint = function(self)
        ---@param weaponName string
        ---@param weaponTintIndex number
        ---@return boolean
        return function(weaponName, weaponTintIndex)
            local loadoutNum, weapon = self.getWeapon(weaponName)

            if not weapon then return false end

            local _, weaponObject = ESX.GetWeapon(weaponName)

            if not weaponObject?.tints or weaponObject?.tints?[weaponTintIndex] then return false end

            self.loadout[loadoutNum].tintIndex = weaponTintIndex

            self.triggerSafeEvent("esx:setWeaponTint", {weaponName = weaponName, weaponTintIndex = weaponTintIndex})
            self.triggerSafeEvent("esx:addInventoryItem", {itemName = weaponObject.tints[weaponTintIndex], itemCount = false, showNotification = true})

            return true
        end
    end,

    ---Gets the tint index of the player's specified weapon.
    ---@param self xPlayer
    getWeaponTint = function(self)
        ---@param weaponName string
        ---@return number
        return function(weaponName)
            local _, weapon = self.getWeapon(weaponName)

            return weapon?.tintIndex or 0
        end
    end,

    ---Checks if player has the specified component for the weapon.
    ---@param self xPlayer
    hasWeaponComponent = function(self)
        ---@param weaponName any
        ---@param weaponComponent any
        ---@return boolean
        return function(weaponName, weaponComponent)
            local _, weapon = self.getWeapon(weaponName)

            if weapon then
                for _, v in ipairs(weapon.components) do
                    if v == weaponComponent then
                        return true
                    end
                end
            end

            return false
        end
    end,

    ---Checks if the specified weapon can be found in the player's loadout.
    ---@param self xPlayer
    hasWeapon = function(self)
        ---@param weaponName string
        ---@return boolean
        return function(weaponName)
            for _, v in ipairs(self.loadout) do
                if v.name == weaponName then
                    return true
                end
            end

            return false
        end
    end,

    ---Checks if the specified item can be found in the player's inventory.
    ---@param self xPlayer
    hasItem = function(self)
        ---@param itemName string
        ---@return false | table, number | nil
        return function(itemName)
            for _, v in ipairs(self.inventory) do
                if (v.name == itemName) and (v.count >= 1) then
                    return v, v.count
                end
            end

            return false
        end
    end,

    ---Gets the specified weapon data from player's loadout if it exists.
    ---@param self xPlayer
    getWeapon = function(self)
        ---@param weaponName string
        ---@return false | number, table?
        return function(weaponName)
            for k, v in ipairs(self.loadout) do
                if v.name == weaponName then
                    return k, v
                end
            end

            return false
        end
    end,

    ---Gets the player's specified metadata. Returns all metadatas if the key/index is omitted.
    ---@param self xPlayer
    getMetadata = function(self)
        ---@param index? string
        ---@param subIndex? string | table
        ---@return nil | string | table
        return function(index, subIndex) -- TODO: Get back to this as it looks like it won't work with all different cases...
            if not index then return self.metadata end

            if type(index) ~= "string" then  ESX.Trace("xPlayer.getMetadata ^5index^7 should be ^5string^7!", "error", true) end

            if self.metadata[index] then
                if subIndex and type(self.metadata[index]) == "table" then
                    local _type = type(subIndex)

                    if _type == "string" then return self.metadata[index][subIndex] end

                    if _type == "table" then
                        local returnValues = {}

                        for i = 1, #subIndex do
                            if self.metadata[index][subIndex[i]] then
                                returnValues[subIndex[i]] = self.metadata[index][subIndex[i]]
                            end
                        end

                        return returnValues
                    end

                    return nil
                end

                return self.metadata[index]
            end

            return nil
        end
    end,

    ---Sets value of the specified metadata key/index of the player's.
    ---@param self xPlayer
    setMetadata = function(self)
        ---@param index string
        ---@param value? string | number | table
        ---@param subValue? any
        ---@return boolean
        return function(index, value, subValue) -- TODO: Get back to this as it looks like it won't work with all different cases...
            if not index then ESX.Trace("xPlayer.setMetadata ^5index^7 is Missing!", "error", true) return false end

            if type(index) ~= "string" then ESX.Trace("xPlayer.setMetadata ^5index^7 should be ^5string^7!", "error", true) return false end

            local _type = type(value)
            local lastMetadata = json.decode(json.encode(self.metadata)) -- avoid holding reference to the self.metadata table

            if not subValue then
                if _type ~= "nil" and _type ~= "number" and _type ~= "string" and _type ~= "table" then
                    ESX.Trace(("xPlayer.setMetadata ^5%s^7 should be ^5number^7 or ^5string^7 or ^5table^7!"):format(value), "error", true)
                    return false
                end

                self.metadata[index] = value
            else
                if _type ~= "string" then
                    ESX.Trace(("xPlayer.setMetadata ^5value^7 should be ^5string^7 as a subIndex!"):format(value), "error", true)
                    return false
                end

                self.metadata[index][value] = subValue
            end

            self.triggerSafeEvent("esx:setMetadata", {currentMetadata = self.metadata, lastMetadata = lastMetadata}, {server = true, client = true})
            Player(self.source).state:set("metadata", self.metadata, true)

            return true
        end
    end,

    ---Clears value of the specified metadata key/index of the player's.
    ---@param self xPlayer
    clearMetadata = function(self)
        ---@param index string | string[]
        ---@return boolean
        return function(index) -- TODO: Get back to this as it looks like the return value won't work properly with all different cases...
            if not index then ESX.Trace(("xPlayer.clearMetadata ^5%s^7 is missing!"):format(index), "error", true) return false end

            if type(index) == "table" then
                for _, val in pairs(index) do
                    self.clearMetadata(val)
                end

                return true
            end

            if not self.metadata[index] then ESX.Trace(("xPlayer.clearMetadata ^5%s^7 not exist!"):format(index), "error", true) return false end

            local lastMetadata = json.decode(json.encode(self.metadata)) -- avoid holding reference to the self.metadata table
            self.metadata[index] = nil

            self.triggerSafeEvent("esx:setMetadata", {currentMetadata = self.metadata, lastMetadata = lastMetadata}, {server = true, client = true})
            Player(self.source).state:set("metadata", self.metadata, true)

            return true
        end
    end
}

xPlayerMethods.getMeta   = xPlayerMethods.getMetadata   -- backward compatibility with esx-legacy
xPlayerMethods.setMeta   = xPlayerMethods.setMetadata   -- backward compatibility with esx-legacy
xPlayerMethods.clearMeta = xPlayerMethods.clearMetadata -- backward compatibility with esx-legacy

return xPlayerMethods