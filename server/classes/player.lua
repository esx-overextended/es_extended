---Creates an xPlayer object
---@param playerId integer | number
---@param playerIdentifier string
---@param playerGroup string
---@param playerAccounts table
---@param playerInventory table
---@param playerInventoryWeight integer | number
---@param playerJob table
---@param playerLoadout table
---@param playerName string
---@param playerMetadata table
---@return xPlayer
function CreateExtendedPlayer(playerId, playerIdentifier, playerGroup, playerAccounts, playerInventory, playerInventoryWeight, playerJob, playerLoadout, playerName, playerMetadata)
    local targetOverrides = Config.PlayerFunctionOverride and Core.PlayerFunctionOverrides[Config.PlayerFunctionOverride] or {}

    ---@type xPlayer
    local self = {}

    self.accounts = playerAccounts
    self.groups = {[playerGroup] = 0}
    self.group = playerGroup
    self.identifier = playerIdentifier
    self.license = string.format("license:%s", Config.Multichar and playerIdentifier:sub(playerIdentifier:find(":") + 1, playerIdentifier:len()) or playerIdentifier)
    self.inventory = playerInventory
    self.job = playerJob
    self.loadout = playerLoadout
    self.name = playerName
    self.playerId = playerId
    self.source = playerId
    self.variables = {}
    self.weight = playerInventoryWeight
    self.maxWeight = Config.MaxWeight
    self.metadata = playerMetadata

    for groupName, groupGrade in pairs(self.groups) do
        lib.addPrincipal(("identifier.%s"):format(self.license), ("%s:%s"):format(ESX.Groups[groupName].principal, groupGrade))
    end

    local stateBag = Player(self.source).state
    stateBag:set("identifier", self.identifier, true)
    stateBag:set("license", self.license, true)
    stateBag:set("job", self.job, true)
    stateBag:set("duty", self.job.duty, true)
    stateBag:set("groups", self.groups, true)
    stateBag:set("group", self.group, true)
    stateBag:set("name", self.name, true)
    stateBag:set("metadata", self.metadata, true)

    ---Triggers a client event for the current player
    ---@param eventName string name of the client event
    ---@param ... any
    function self.triggerEvent(eventName, ...)
        TriggerClientEvent(eventName, self.source, ...)
    end

    ---Triggers a safe event for the current player
    ---@param eventName string -- name of the safe event
    ---@param eventData? table -- data to send through the safe event
    ---@param eventOptions? CEventOptions data to define whether server, client, or both should be triggered (defaults to {server = false, client = true})
    function self.triggerSafeEvent(eventName, eventData, eventOptions)
        ESX.TriggerSafeEvent(eventName, self.source, eventData, eventOptions or {server = false, client = true})
    end

    ---Sets the current player coords
    ---@param coords table | vector3 | vector4
    function self.setCoords(coords)
        local ped = GetPlayerPed(self.source)
        local vector = vector4(coords?.x, coords?.y, coords?.z, coords?.w or coords?.heading or 0.0)

        if not vector then return end

        SetEntityCoords(ped, vector.x, vector.y, vector.z, false, false, false, false)
        SetEntityHeading(ped, vector.w)
    end

    ---Gets the current player coordinates
    ---@param vector? boolean whether to return the the player coords as vector4 or as table
    ---@return vector4 | table
    function self.getCoords(vector)
        local playerPed = GetPlayerPed(self.source)
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        return vector and vector4(coords.x, coords.y, coords.z, heading) or {x = coords.x, y = coords.y, z = coords.z, heading = heading}
    end

    ---Kicks the current player out with the specified reason
    ---@param reason? string
    function self.kick(reason)
        DropPlayer(tostring(self.source), reason --[[@as string]])
    end

    ---Sets the current player money to the specified value
    ---@param money integer | number
    ---@return boolean
    function self.setMoney(money)
        money = ESX.Math.Round(money)
        return self.setAccountMoney("money", money)
    end

    ---Gets the current player money value
    ---@return integer | number
    function self.getMoney()
        return self.getAccount("money")?.money
    end

    ---Adds the specified value to the current player money
    ---@param money integer | number
    ---@param reason? string
    ---@return boolean
    function self.addMoney(money, reason)
        money = ESX.Math.Round(money)
        return self.addAccountMoney("money", money, reason)
    end

    ---Removes the specified value from the current player money
    ---@param money integer | number
    ---@param reason? string
    ---@return boolean
    function self.removeMoney(money, reason)
        money = ESX.Math.Round(money)
        return self.removeAccountMoney("money", money, reason)
    end

    ---Gets the current player identifier
    ---@return string
    function self.getIdentifier()
        return self.identifier
    end

    ---Gets the current player's Rockstar license
    ---@return string
    function self.getLicense()
        return self.license
    end

    ---Checks if the current player has the specified group
    ---@param groupName string
    ---@param groupGrade? integer | number
    ---@return boolean, integer | number | nil
    function self.hasGroup(groupName, groupGrade)
        if not groupName then return false end

        if groupGrade ~= nil then return self.groups[groupName] == groupGrade end

        return self.groups[groupName] ~= nil, self.groups[groupName]
    end

    ---Adds the specified group to the current player
    ---@param groupName string
    ---@param groupGrade integer | number
    ---@return boolean
    function self.addGroup(groupName, groupGrade)
        if type(groupName) ~= "string" or type(groupGrade) ~= "number" or self.hasGroup(groupName, groupGrade) then return false end

        if not ESX.DoesGroupExist(groupName, groupGrade) then print(("[^3WARNING^7] Ignoring invalid ^5.addGroup(%s, %s)^7 usage for Player ^5%s^7"):format(groupName, groupGrade, self.source)) return false end

        local triggerRemoveGroup, previousGroup = false, self.group
        local lastGroups = json.decode(json.encode(self.groups))

        if Config.AdminGroupsByName[groupName] or groupName == Core.DefaultGroup then
            self.groups[self.group], self.group = nil, groupName
            triggerRemoveGroup = true

            lib.removePrincipal(("identifier.%s"):format(self.license), ("%s:%s"):format(ESX.Groups[previousGroup].principal, lastGroups[previousGroup]))
        end

        self.groups[groupName] = groupGrade

        lib.addPrincipal(("identifier.%s"):format(self.license), ("%s:%s"):format(ESX.Groups[groupName].principal, groupGrade))

        self.triggerSafeEvent("esx:setGroups", {currentGroups = self.groups, lastGroups = lastGroups}, {server = true, client = true})
        self.triggerSafeEvent("esx:addGroup", {groupName = groupName, groupGrade = groupGrade}, {server = true, client = true})

        if triggerRemoveGroup then
            self.triggerSafeEvent("esx:removeGroup", {groupName = previousGroup, groupGrade = lastGroups[previousGroup]}, {server = true, client = true})
        end

        Player(self.source).state:set("groups", self.groups, true)
        Player(self.source).state:set("group", self.group, true)

        return true
    end

    ---Removes the specified group from the current player
    ---@param groupName string
    ---@return boolean
    function self.removeGroup(groupName)
        if type(groupName) ~= "string" or groupName == Core.DefaultGroup or not self.hasGroup(groupName) then return false end

        local triggerAddGroup, defaultGroup = false, Core.DefaultGroup
        local lastGroups = json.decode(json.encode(self.groups))

        lib.removePrincipal(("identifier.%s"):format(self.license), ("%s:%s"):format(ESX.Groups[groupName].principal, lastGroups[groupName]))

        self.groups[groupName] = nil

        if Config.AdminGroupsByName[groupName] then
            self.groups[defaultGroup], self.group = 0, defaultGroup
            triggerAddGroup = true

            lib.addPrincipal(("identifier.%s"):format(self.license), ("%s:%s"):format(ESX.Groups[defaultGroup].principal, self.groups[defaultGroup]))
        end

        self.triggerSafeEvent("esx:setGroups", {currentGroups = self.groups, lastGroups = lastGroups}, {server = true, client = true})
        self.triggerSafeEvent("esx:removeGroup", {groupName = groupName, groupGrade = lastGroups[groupName]}, {server = true, client = true})

        if triggerAddGroup then
            self.triggerSafeEvent("esx:addGroup", {groupName = defaultGroup, groupGrade = self.groups[defaultGroup]}, {server = true, client = true})
        end

        Player(self.source).state:set("groups", self.groups, true)
        Player(self.source).state:set("group", self.group, true)

        return true
    end

    ---Gets all of the current player's groups
    ---@return table<string, integer | number>
    function self.getGroups()
        return self.groups
    end

    ---Sets the current player's permission/user/admin group
    ---@param newGroup string
    ---@return boolean
    function self.setGroup(newGroup)
        return self.addGroup(newGroup, 0)
    end

    ---Gets the current player's permission/user/admin group
    ---@return string
    function self.getGroup()
        return self.group
    end

    ---Sets the specified value to the key variable for the current player
    ---@param key string
    ---@param value any
    function self.setVariable(key, value) -- TODO: sync with client using safe event
        self.variables[key] = value
        Player(self.source).state:set(key, value, true)
    end
    self.set = self.setVariable

    ---Gets the value of the specified key variable from the current player
    ---@param key any
    ---@return any
    function self.getVariable(key)
        return self.variables[key]
    end
    self.get = self.getVariable

    ---Gets all of the current player accounts
    ---@param minimal? boolean
    ---@return table
    function self.getAccounts(minimal)
        if not minimal then return self.accounts end

        local minimalAccounts = {}

        for i = 1, #self.accounts do
            minimalAccounts[self.accounts[i].name] = self.accounts[i].money
        end

        return minimalAccounts
    end

    ---Gets the specified account's data from the current player
    ---@param accountName string
    ---@return table?
    function self.getAccount(accountName)
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

    ---Gets all of the current player inventory data
    ---@param minimal? boolean
    ---@return table
    function self.getInventory(minimal)
        if not minimal then return self.inventory end

        local minimalInventory = {}

        for _, v in ipairs(self.inventory) do
            if v.count > 0 then
                minimalInventory[v.name] = v.count
            end
        end

        return minimalInventory
    end

    ---Gets all of the current player loadout data
    ---@param minimal? boolean
    ---@return table
    function self.getLoadout(minimal)
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

    ---Gets the current player name
    ---@return string
    function self.getName()
        return self.name
    end

    ---Sets the current player name
    ---@param newName string
    function self.setName(newName)
        self.name = newName
        Player(self.source).state:set("name", self.name, true)
    end

    ---Sets money for the specified account of the current player
    ---@param accountName string
    ---@param money integer | number
    ---@param reason? string
    ---@return boolean
    function self.setAccountMoney(accountName, money, reason)
        money = tonumber(money) --[[@as number]]
        reason = reason or "Unknown"

        if not money or money < 0 then
            print(("[^1ERROR^7] Tried to set account ^5%s^0 for Player ^5%s^0 to with invalid value -> ^5%s^7"):format(accountName, self.playerId, money))
            return false
        end

        local account = self.getAccount(accountName)

        if not account then
            print(("[^1ERROR^7] Tried to set money to an invalid account ^5%s^0 for Player ^5%s^0"):format(accountName, self.playerId))
            return false
        end

        money = account.round and ESX.Math.Round(money) or money
        self.accounts[account.index].money = money

        self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = money, reason = reason}, {server = true, client = true})

        return true
    end

    ---Adds money to the specified account of the current player
    ---@param accountName string
    ---@param money integer | number
    ---@param reason? string
    ---@return boolean
    function self.addAccountMoney(accountName, money, reason)
        money = tonumber(money) --[[@as number]]
        reason = reason or "Unknown"

        if not money or money <= 0 then
            print(("[^1ERROR^7] Tried to add account ^5%s^0 for Player ^5%s^0 with an invalid value -> ^5%s^7"):format(accountName, self.playerId, money))
            return false
        end

        local account = self.getAccount(accountName)

        if not account then
            print(("[^1ERROR^7] Tried to add money to an invalid account ^5%s^0 for Player ^5%s^0"):format(accountName, self.playerId))
            return false
        end

        money = account.round and ESX.Math.Round(money) or money
        self.accounts[account.index].money += money

        TriggerEvent("esx:addAccountMoney", self.source, accountName, money, reason)
        self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason})

        return true
    end

    ---Removes money from the specified account of the current player
    ---@param accountName string
    ---@param money integer | number
    ---@param reason? string
    ---@return boolean
    function self.removeAccountMoney(accountName, money, reason)
        money = tonumber(money) --[[@as number]]
        reason = reason or "Unknown"

        if not money or money <= 0 then
            print(("[^1ERROR^7] Tried to remove account ^5%s^0 for Player ^5%s^0 with an invalid value -> ^5%s^7"):format(accountName, self.playerId, money))
            return false
        end

        local account = self.getAccount(accountName)

        if not account then
            print(("[^1ERROR^7] Tried to remove money from an invalid account ^5%s^0 for Player ^5%s^0"):format(accountName, self.playerId))
            return false
        end

        money = account.round and ESX.Math.Round(money) or money
        self.accounts[account.index].money = self.accounts[account.index].money - money

        TriggerEvent("esx:removeAccountMoney", self.source, accountName, money, reason)
        self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason})

        return true
    end

    ---Gets the specified item data from the current player
    ---@param itemName string
    ---@return table?
    function self.getInventoryItem(itemName)
        local itemData

        for _, item in ipairs(self.inventory) do
            if item.name == itemName then
                itemData = item
                break
            end
        end

        return itemData
    end

    ---Adds the specified item to the current player
    ---@param itemName string
    ---@param itemCount? integer | number defaults to 1 if not provided
    ---@return boolean
    function self.addInventoryItem(itemName, itemCount)
        local item = self.getInventoryItem(itemName)

        if not item then return false end

        itemCount = type(itemCount) == "number" and ESX.Math.Round(itemCount) or 1
        item.count += itemCount
        self.weight += (item.weight * itemCount)

        TriggerEvent("esx:onAddInventoryItem", self.source, item.name, item.count)
        self.triggerSafeEvent("esx:addInventoryItem", {itemName = item.name, itemCount = item.count})

        return true
    end

    ---Removes the specified item from the current player
    ---@param itemName string
    ---@param itemCount? integer | number defaults to 1 if not provided
    ---@return boolean
    function self.removeInventoryItem(itemName, itemCount)
        local item = self.getInventoryItem(itemName)

        if not item then return false end

        itemCount = type(itemCount) == "number" and ESX.Math.Round(itemCount) or 1

        local newCount = item.count - itemCount

        if newCount < 0 then print(("[^1ERROR^7] Tried to remove non-existance count(%s) of %s item for Player ^5%s^0"):format(itemCount, itemName, self.playerId)) return false end

        item.count = newCount
        self.weight = self.weight - (item.weight * itemCount)

        TriggerEvent("esx:onRemoveInventoryItem", self.source, item.name, item.count)
        self.triggerSafeEvent("esx:removeInventoryItem", {itemName = item.name, itemCount = item.count})

        return true
    end

    ---Set the specified item count for the current player
    ---@param itemName string
    ---@param itemCount integer | number
    ---@return boolean
    function self.setInventoryItem(itemName, itemCount)
        local item = self.getInventoryItem(itemName)
        itemCount = type(itemCount) == "number" and ESX.Math.Round(itemCount) --[[@as number]]

        if not item or not itemCount or itemCount <= 0 then return false end

        return itemCount > item.count and self.addInventoryItem(item.name, itemCount - item.count) or self.removeInventoryItem(item.name, item.count - itemCount)
    end

    ---Gets the current player inventory weight
    ---@return integer | number
    function self.getWeight()
        return self.weight
    end

    ---Gets the current player max inventory weight
    ---@return integer | number
    function self.getMaxWeight()
        return self.maxWeight
    end

    ---Sets the current player max inventory weight
    ---@param newWeight integer | number
    function self.setMaxWeight(newWeight)
        self.maxWeight = newWeight
        self.triggerSafeEvent("esx:setMaxWeight", {maxWeight = newWeight}, {server = true, client = true})
    end

    ---Checks if the current player does have enough space in inventory to carry the specified item count(s)
    ---@param itemName string
    ---@param itemCount integer | number
    ---@return boolean
    function self.canCarryItem(itemName, itemCount)
        if not ESX.Items[itemName] then print(("[^3WARNING^7] Item ^5'%s'^7 was used but does not exist!"):format(itemName)) return false end

        local currentWeight, itemWeight = self.weight, ESX.Items[itemName].weight
        local newWeight = currentWeight + (itemWeight * itemCount)

        return newWeight <= self.maxWeight
    end

    ---Checks if 2 items with the specified counts can be swapped in the current player inventory based on max inventory weight
    ---@param firstItem string
    ---@param firstItemCount integer | number
    ---@param testItem string
    ---@param testItemCount integer | number
    ---@return boolean
    function self.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
        local firstItemObject = self.getInventoryItem(firstItem)
        local testItemObject = self.getInventoryItem(testItem)

        if not firstItemObject or not testItemObject or firstItemObject.count < firstItemCount then return false end

        local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
        local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

        return weightWithTestItem <= self.maxWeight
    end

    ---Gets the current player job object
    ---@return table
    function self.getJob()
        return self.job
    end

    ---Sets job for the current player
    ---@param job string
    ---@param grade integer | number | string
    ---@param duty? boolean if not provided, it will use the job's default duty value
    ---@return boolean
    function self.setJob(job, grade, duty)
        if not ESX.DoesJobExist(job, grade) then print(("[^3WARNING^7] Ignoring invalid ^5.setJob()^7 usage for Player ^5%s^7, Job: ^5%s^7"):format(self.source, job)) return false end

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

    ---Gets the current player's job duty state
    ---@return boolean
    function self.getDuty()
        return self.job.duty
    end

    ---Sets the current player's job duty state
    ---@param duty boolean
    ---@return boolean
    function self.setDuty(duty)
        if type(duty) ~= "boolean" then return false end

        return self.setJob(self.job.name, self.job.grade, duty)
    end

    ---Adds a weapon with the specified ammo to the current player
    ---@param weaponName string
    ---@param ammo integer | number
    ---@return boolean
    function self.addWeapon(weaponName, ammo)
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

    ---Removes the specified weapon from current player
    ---@param weaponName string
    ---@return boolean
    function self.removeWeapon(weaponName)
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

    ---Adds a specific component to the current player's weapon
    ---@param weaponName string
    ---@param weaponComponent string
    ---@return boolean
    function self.addWeaponComponent(weaponName, weaponComponent)
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

    ---Removes the specified weapon component from current player
    ---@param weaponName string
    ---@param weaponComponent string
    ---@return boolean
    function self.removeWeaponComponent(weaponName, weaponComponent)
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

    ---Sets ammo to the current player's specified weapon
    ---@param weaponName string
    ---@param ammoCount integer | number
    ---@return boolean
    function self.updateWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if not weapon then return false end

        weapon.ammo = ammoCount
        SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)

        return true
    end

    ---Adds ammo to the current player's specified weapon
    ---@param weaponName string
    ---@param ammoCount integer | number
    ---@return boolean
    function self.addWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if not weapon then return false end

        weapon.ammo += ammoCount
        SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)

        return true
    end

    ---Removes ammo from the current player's specified weapon
    ---@param weaponName string
    ---@param ammoCount integer | number
    ---@return boolean
    function self.removeWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if not weapon then return false end

        weapon.ammo = weapon.ammo - ammoCount
        self.updateWeaponAmmo(weaponName, weapon.ammo)

        return true
    end

    ---Sets tint to the current player's specified weapon
    ---@param weaponName string
    ---@param weaponTintIndex integer | number
    ---@return boolean
    function self.setWeaponTint(weaponName, weaponTintIndex)
        local loadoutNum, weapon = self.getWeapon(weaponName)

        if not weapon then return false end

        local _, weaponObject = ESX.GetWeapon(weaponName)

        if not weaponObject?.tints or weaponObject?.tints?[weaponTintIndex] then return false end

        self.loadout[loadoutNum].tintIndex = weaponTintIndex

        self.triggerSafeEvent("esx:setWeaponTint", {weaponName = weaponName, weaponTintIndex = weaponTintIndex})
        self.triggerSafeEvent("esx:addInventoryItem", {itemName = weaponObject.tints[weaponTintIndex], itemCount = false, showNotification = true})

        return true
    end

    ---Gets the tint index of the current player's specified weapon
    ---@param weaponName any
    ---@return integer | number
    function self.getWeaponTint(weaponName)
        local _, weapon = self.getWeapon(weaponName)

        return weapon?.tintIndex or 0
    end

    ---Checks if the current player has the specified component for the weapon
    ---@param weaponName any
    ---@param weaponComponent any
    ---@return boolean
    function self.hasWeaponComponent(weaponName, weaponComponent)
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

    ---Checks if the current player has the specified weapon
    ---@param weaponName string
    ---@return boolean
    function self.hasWeapon(weaponName)
        for _, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return true
            end
        end

        return false
    end

    ---Checks if the current player has the specified item
    ---@param itemName string
    ---@return false | table, integer | number | nil
    function self.hasItem(itemName)
        for _, v in ipairs(self.inventory) do
            if (v.name == itemName) and (v.count >= 1) then
                return v, v.count
            end
        end

        return false
    end

    ---Checks if the current player has the specified weapon
    ---@param weaponName string
    ---@return false | integer | number, table?
    function self.getWeapon(weaponName)
        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return k, v
            end
        end

        return false
    end

    ---Sends notification to the current player
    ---@param message string | table
    ---@param type? string
    ---@param duration? integer | number
    ---@param extra? table
    function self.showNotification(message, type, duration, extra)
        self.triggerSafeEvent("esx:showNotification", {
            message = message,
            type = type,
            duration = duration,
            extra = extra
        })
    end

    ---Sends help notification to the current player
    ---@param message string
    ---@param thisFrame boolean
    ---@param beep boolean
    ---@param duration integer | number
    function self.showHelpNotification(message, thisFrame, beep, duration)
        self.triggerSafeEvent("esx:showHelpNotification", {
            message = message,
            thisFrame = thisFrame,
            beep = beep,
            duration = duration
        })
    end

    ---Gets the current player specified metadata
    ---@param index? string
    ---@param subIndex? string | table
    ---@return nil | string | table
    function self.getMetadata(index, subIndex) -- TODO: Get back to this as it looks like it won't work with all different cases...
        if not index then return self.metadata end

        if type(index) ~= "string" then  print("[^1ERROR^7] xPlayer.getMetadata ^5index^7 should be ^5string^7!") end

        if self.metadata[index] then
            if subIndex and type(self.metadata[index]) == "table" then
                local _type = type(subIndex)

                if _type == "string" then return self.metadata[index][subIndex] end

                if _type == "table" then
                    local returnValues = {}
                    for i = 1, #subIndex do
                        if self.metadata[index][subIndex[i]] then
                            returnValues[subIndex[i]] = self.metadata[index][subIndex[i]]
                        else
                            print(("[^1ERROR^7] xPlayer.getMetadata ^5%s^7 not exist on ^5%s^7!"):format(subIndex[i], index))
                        end
                    end

                    return returnValues
                end
            end

            return self.metadata[index]
        else
            print(("[^1ERROR^7] xPlayer.getMetadata ^5%s^7 not exist!"):format(index))
            return nil
        end
    end
    self.getMeta = self.getMetadata -- backward compatibility with esx-legacy

    ---Sets the specified metadata to the current player
    ---@param index string
    ---@param value? string | number | table
    ---@param subValue? any
    ---@return boolean
    function self.setMetadata(index, value, subValue) -- TODO: Get back to this as it looks like it won't work with all different cases...
        if not index then print("[^1ERROR^7] xPlayer.setMetadata ^5index^7 is Missing!") return false end

        if type(index) ~= "string" then print("[^1ERROR^7] xPlayer.setMetadata ^5index^7 should be ^5string^7!") return false end

        if not value then print(("[^1ERROR^7] xPlayer.setMetadata ^5%s^7 is Missing!"):format(value)) return false end

        local _type = type(value)
        local lastMetadata = json.decode(json.encode(self.metadata)) -- avoid holding reference to the self.metadata table

        if not subValue then
            if _type ~= "number" and _type ~= "string" and _type ~= "table" then
                print(("[^1ERROR^7] xPlayer.setMetadata ^5%s^7 should be ^5number^7 or ^5string^7 or ^5table^7!"):format(value))
                return false
            end

            self.metadata[index] = value
        else
            if _type ~= "string" then
                print(("[^1ERROR^7] xPlayer.setMetadata ^5value^7 should be ^5string^7 as a subIndex!"):format(value))
                return false
            end

            self.metadata[index][value] = subValue
        end

        self.triggerSafeEvent("esx:setMetadata", {currentMetadata = self.metadata, lastMetadata = lastMetadata}, {server = true, client = true})
        Player(self.source).state:set("metadata", self.metadata, true)

        return true
    end
    self.setMeta = self.setMetadata -- backward compatibility with esx-legacy

    ---Clears the specifid metadata for the current player
    ---@param index string | string[]
    ---@return boolean
    function self.clearMetadata(index) -- TODO: Get back to this as it looks like the return value won't work properly with all different cases...
        if not index then print(("[^1ERROR^7] xPlayer.clearMetadata ^5%s^7 is missing!"):format(index)) return false end

        if type(index) == "table" then
            for _, val in pairs(index) do
                self.clearMetadata(val)
            end

            return true
        end

        if not self.metadata[index] then print(("[^1ERROR^7] xPlayer.clearMetadata ^5%s^7 not exist!"):format(index)) return false end

        local lastMetadata = json.decode(json.encode(self.metadata)) -- avoid holding reference to the self.metadata table
        self.metadata[index] = nil

        self.triggerSafeEvent("esx:setMetadata", {currentMetadata = self.metadata, lastMetadata = lastMetadata}, {server = true, client = true})
        Player(self.source).state:set("metadata", self.metadata, true)

        return true
    end
    self.clearMeta = self.clearMetadata -- backward compatibility with esx-legacy

    ---Gets the table of all players that are in-scope/in-range with the current player
    ---@param includeSelf? boolean include the current player within the return data (defaults to false)
    ---@return xScope | nil
    function self.getInScopePlayers(includeSelf)
        return ESX.GetPlayersInScope(self.source, includeSelf)
    end

    ---Checks if the current player is inside the scope/range of the target player id
    ---@param targetId integer | number
    ---@return boolean
    function self.isInPlayerScope(targetId)
        return ESX.IsPlayerInScope(self.source, targetId)
    end

    ---Checks if the target player id is inside the scope/range of the current player
    ---@param targetId integer | number
    ---@return boolean
    function self.isPlayerInScope(targetId)
        return ESX.IsPlayerInScope(targetId, self.source)
    end

    ---Triggers a client event for all players that are in-scope/in-range with the current player
    ---@param eventName string name of the client event
    ---@param includeSelf? boolean trigger the event for the current player (defaults to false)
    ---@param ... any
    function self.triggerScopedEvent(eventName, includeSelf, ...)
        ESX.TriggerScopedEvent(eventName, self.source, includeSelf, ...)
    end

    ---Triggers a safe event for all players that are in-scope/in-range with the current player
    ---@param eventName string name of the safe event
    ---@param includeSelf? boolean trigger the event for the current player (defaults to false)
    ---@param eventData? table -- data to send through the safe event
    ---@param eventOptions? CEventOptions data to define whether server, client, or both should be triggered (defaults to {server = false, client = true})
    function self.triggerSafeScopedEvent(eventName, includeSelf, eventData, eventOptions)
        ESX.TriggerSafeScopedEvent(eventName, self.source, includeSelf, eventData, eventOptions)
    end

    ---Gets the routing bucket id that the current player is inside
    ---@return routingBucket | nil
    function self.getRoutingBucket()
        return ESX.GetPlayerRoutingBucket(self.source)
    end

    ---Adds the current player to the routing bucket id
    ---@param bucketId routingBucket
    ---@return boolean
    function self.setRoutingBucket(bucketId)
        return ESX.SetPlayerRoutingBucket(self.source, bucketId)
    end

    for fnName, fn in pairs(targetOverrides) do
        self[fnName] = fn(self)
    end

    return self
end