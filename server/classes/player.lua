function CreateExtendedPlayer(playerId, playerIdentifier, playerGroup, playerAccounts, playerInventory, playerInventoryWeight, playerJob, playerLoadout, playerName, playerMetadata)
    local targetOverrides = Config.PlayerFunctionOverride and Core.PlayerFunctionOverrides[Config.PlayerFunctionOverride] or {}

    local self = {}

    self.accounts = playerAccounts
    self.group = playerGroup
    self.identifier = playerIdentifier
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

    if Config.Multichar then self.license = 'license'.. playerIdentifier:sub(playerIdentifier:find(':'), playerIdentifier:len()) else self.license = 'license:'..playerIdentifier end

    ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.license, self.group))

    local stateBag = Player(self.source).state
    stateBag:set("identifier", self.identifier, true)
    stateBag:set("license", self.license, true)
    stateBag:set("job", self.job, true)
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

    function self.setCoords(coords)
        local ped = GetPlayerPed(self.source)
        local vector = vector4(coords?.x, coords?.y, coords?.z, coords?.w or coords?.heading or 0.0)

        if not vector then return end

        SetEntityCoords(ped, vector.x, vector.y, vector.z, false, false, false, false)
        SetEntityHeading(ped, vector.w)
    end

    function self.getCoords(vector)
        local playerPed = GetPlayerPed(self.source)
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        return vector and vector4(coords.x, coords.y, coords.z, heading) or {x = coords.x, y = coords.y, z = coords.z, heading = heading}
    end

    function self.kick(reason)
        DropPlayer(self.source, reason)
    end

    function self.setMoney(money)
        money = ESX.Math.Round(money)
        self.setAccountMoney('money', money)
    end

    function self.getMoney()
        return self.getAccount('money').money
    end

    function self.addMoney(money, reason)
        money = ESX.Math.Round(money)
        self.addAccountMoney('money', money, reason)
    end

    function self.removeMoney(money, reason)
        money = ESX.Math.Round(money)
        self.removeAccountMoney('money', money, reason)
    end

    function self.getIdentifier()
        return self.identifier
    end

    function self.setGroup(newGroup)
        ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.license, self.group))
        self.group = newGroup
        Player(self.source).state:set("group", self.group, true)
        ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.license, self.group))
    end

    function self.getGroup()
        return self.group
    end

    function self.set(k, v)
        self.variables[k] = v
        Player(self.source).state:set(k, v, true)
    end

    function self.get(k)
        return self.variables[k]
    end

    function self.getAccounts(minimal)
        if not minimal then
            return self.accounts
        end

        local minimalAccounts = {}

        for i = 1, #self.accounts do
            minimalAccounts[self.accounts[i].name] = self.accounts[i].money
        end

        return minimalAccounts
    end

    function self.getAccount(account)
        for i = 1, #self.accounts do
            if self.accounts[i].name == account then
                return self.accounts[i]
            end
        end
    end

    function self.getInventory(minimal)
        if minimal then
            local minimalInventory = {}

            for _, v in ipairs(self.inventory) do
                if v.count > 0 then
                    minimalInventory[v.name] = v.count
                end
            end

            return minimalInventory
        end

        return self.inventory
    end

    function self.getJob()
        return self.job
    end

    function self.getLoadout(minimal)
        if not minimal then return self.loadout end

        local minimalLoadout = {}

        for _, v in ipairs(self.loadout) do
            minimalLoadout[v.name] = {ammo = v.ammo}
            if v.tintIndex > 0 then minimalLoadout[v.name].tintIndex = v.tintIndex end

            if #v.components > 0 then
                local components = {}

                for _, component in ipairs(v.components) do
                    if component ~= 'clip_default' then
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

    function self.getName()
        return self.name
    end

    function self.setName(newName)
        self.name = newName
        Player(self.source).state:set("name", self.name, true)
    end

    function self.setAccountMoney(accountName, money, reason)
        reason = reason or 'unknown'
        if not tonumber(money) then
            print(('[^1ERROR^7] Tried To Set Account ^5%s^0 For Player ^5%s^0 To An Invalid Number -> ^5%s^7'):format(accountName, self.playerId, money))
            return
        end
        if money >= 0 then
            local account = self.getAccount(accountName)

            if account then
                money = account.round and ESX.Math.Round(money) or money
                self.accounts[account.index].money = money

                self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = money, reason = reason}, {server = true, client = true})
            else
                print(('[^1ERROR^7] Tried To Set Invalid Account ^5%s^0 For Player ^5%s^0!'):format(accountName, self.playerId))
            end
        else
            print(('[^1ERROR^7] Tried To Set Account ^5%s^0 For Player ^5%s^0 To An Invalid Number -> ^5%s^7'):format(accountName, self.playerId, money))
        end
    end

    function self.addAccountMoney(accountName, money, reason)
        reason = reason or 'Unknown'
        if not tonumber(money) then
            print(('[^1ERROR^7] Tried To Set Account ^5%s^0 For Player ^5%s^0 To An Invalid Number -> ^5%s^7'):format(accountName, self.playerId, money))
            return
        end
        if money > 0 then
            local account = self.getAccount(accountName)
            if account then
                money = account.round and ESX.Math.Round(money) or money
                self.accounts[account.index].money += money

                TriggerEvent('esx:addAccountMoney', self.source, accountName, money, reason)
                self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason})
            else
                print(('[^1ERROR^7] Tried To Set Add To Invalid Account ^5%s^0 For Player ^5%s^0!'):format(accountName, self.playerId))
            end
        else
            print(('[^1ERROR^7] Tried To Set Account ^5%s^0 For Player ^5%s^0 To An Invalid Number -> ^5%s^7'):format(accountName, self.playerId, money))
        end
    end

    function self.removeAccountMoney(accountName, money, reason)
        reason = reason or 'Unknown'
        if not tonumber(money) then
            print(('[^1ERROR^7] Tried To Set Account ^5%s^0 For Player ^5%s^0 To An Invalid Number -> ^5%s^7'):format(accountName, self.playerId, money))
            return
        end
        if money > 0 then
            local account = self.getAccount(accountName)

            if account then
                money = account.round and ESX.Math.Round(money) or money
                self.accounts[account.index].money = self.accounts[account.index].money - money

                TriggerEvent('esx:removeAccountMoney', self.source, accountName, money, reason)
                self.triggerSafeEvent("esx:setAccountMoney", {account = account, accountName = accountName, money = self.accounts[account.index].money, reason = reason})
            else
                print(('[^1ERROR^7] Tried To Set Add To Invalid Account ^5%s^0 For Player ^5%s^0!'):format(accountName, self.playerId))
            end
        else
            print(('[^1ERROR^7] Tried To Set Account ^5%s^0 For Player ^5%s^0 To An Invalid Number -> ^5%s^7'):format(accountName, self.playerId, money))
        end
    end

    function self.getInventoryItem(name)
        for _, v in ipairs(self.inventory) do
            if v.name == name then
                return v
            end
        end
    end

    function self.addInventoryItem(name, count)
        local item = self.getInventoryItem(name)

        if item then
            count = ESX.Math.Round(count)
            item.count = item.count + count
            self.weight = self.weight + (item.weight * count)

            TriggerEvent('esx:onAddInventoryItem', self.source, item.name, item.count)
            self.triggerSafeEvent("esx:addInventoryItem", {itemName = item.name, itemCount = item.count})
        end
    end

    function self.removeInventoryItem(name, count)
        local item = self.getInventoryItem(name)

        if item then
            count = ESX.Math.Round(count)
            if count > 0 then
                local newCount = item.count - count

                if newCount >= 0 then
                    item.count = newCount
                    self.weight = self.weight - (item.weight * count)

                    TriggerEvent('esx:onRemoveInventoryItem', self.source, item.name, item.count)
                    self.triggerSafeEvent("esx:removeInventoryItem", {itemName = item.name, itemCount = item.count})
                end
            else
                print(('[^1ERROR^7] Player ID:^5%s Tried to remove a Invalid count -> %s of %s'):format(self.playerId, count,name))
            end
        end
    end

    function self.setInventoryItem(name, count)
        local item = self.getInventoryItem(name)

        if item and count >= 0 then
            count = ESX.Math.Round(count)

            if count > item.count then
                self.addInventoryItem(item.name, count - item.count)
            else
                self.removeInventoryItem(item.name, item.count - count)
            end
        end
    end

    function self.getWeight()
        return self.weight
    end

    function self.getMaxWeight()
        return self.maxWeight
    end

    function self.canCarryItem(name, count)
        if ESX.Items[name] then
            local currentWeight, itemWeight = self.weight, ESX.Items[name].weight
            local newWeight = currentWeight + (itemWeight * count)

            return newWeight <= self.maxWeight
        else
            print(('[^3WARNING^7] Item ^5"%s"^7 was used but does not exist!'):format(name))
        end
    end

    function self.canSwapItem(firstItem, firstItemCount, testItem, testItemCount)
        local firstItemObject = self.getInventoryItem(firstItem)
        local testItemObject = self.getInventoryItem(testItem)

        if firstItemObject.count >= firstItemCount then
            local weightWithoutFirstItem = ESX.Math.Round(self.weight - (firstItemObject.weight * firstItemCount))
            local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (testItemObject.weight * testItemCount))

            return weightWithTestItem <= self.maxWeight
        end

        return false
    end

    function self.setMaxWeight(newWeight)
        self.maxWeight = newWeight
        self.triggerSafeEvent("esx:setMaxWeight", {maxWeight = newWeight}, {server = true, client = true})
    end

    function self.setJob(job, grade, duty)
        grade = tostring(grade)
        local lastJob = json.decode(json.encode(self.job))

        if ESX.DoesJobExist(job, grade) then
            local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

            self.job.id    = jobObject.id
            self.job.name  = jobObject.name
            self.job.label = jobObject.label
            self.job.type  = jobObject.type
            self.job.duty  = type(duty) == "boolean" and duty or jobObject.default_duty

            self.job.grade        = tonumber(grade)
            self.job.grade_name   = gradeObject.name
            self.job.grade_label  = gradeObject.label
            self.job.grade_salary = gradeObject.salary

            if gradeObject.skin_male then
                self.job.skin_male = json.decode(gradeObject.skin_male)
            else
                self.job.skin_male = {}
            end

            if gradeObject.skin_female then
                self.job.skin_female = json.decode(gradeObject.skin_female)
            else
                self.job.skin_female = {}
            end

            self.triggerSafeEvent("esx:setJob", {currentJob = self.job, lastJob = lastJob}, {server = true, client = true})
            Player(self.source).state:set("job", self.job, true)

            self.setDuty(self.job.duty)
        else
            print(('[es_extended] [^3WARNING^7] Ignoring invalid ^5.setJob()^7 usage for ID: ^5%s^7, Job: ^5%s^7'):format(self.source, job))
        end
    end

    ---Gets the current player's job duty state
    ---@return boolean
    function self.getDuty()
        return self.job.duty
    end

    ---Sets the current player's job duty state
    ---@param duty boolean
    function self.setDuty(duty)
        if type(duty) ~= "boolean" then return end

        self.job.duty = duty

        self.triggerSafeEvent("esx:setDuty", {duty = self.job.duty}, {server = true, client = true})
        Player(self.source).state:set("duty", self.job.duty, true)
    end

    ---Gets the current player's job type
    ---@return string | nil
    function self.getJobType()
        return self.job.type
    end

    function self.addWeapon(weaponName, ammo)
        if not self.hasWeapon(weaponName) then
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
        end
    end

    function self.addWeaponComponent(weaponName, weaponComponent)
        local loadoutNum, weapon = self.getWeapon(weaponName)

        if weapon then
            local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if component then
                if not self.hasWeaponComponent(weaponName, weaponComponent) then
                    self.loadout[loadoutNum].components[#self.loadout[loadoutNum].components + 1] = weaponComponent
                    local componentHash = ESX.GetWeaponComponent(weaponName, weaponComponent).hash

                    GiveWeaponComponentToPed(GetPlayerPed(self.source), joaat(weaponName), componentHash)
                    self.triggerSafeEvent("esx:addInventoryItem", {itemName = component.label, itemCount = false, showNotification = true})
                end
            end
        end
    end

    function self.addWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = weapon.ammo + ammoCount
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
        end
    end

    function self.updateWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = ammoCount
            SetPedAmmo(GetPlayerPed(self.source), joaat(weaponName), weapon.ammo)
        end
    end

    function self.setWeaponTint(weaponName, weaponTintIndex)
        local loadoutNum, weapon = self.getWeapon(weaponName)

        if weapon then
            local _, weaponObject = ESX.GetWeapon(weaponName)

            if weaponObject.tints and weaponObject.tints[weaponTintIndex] then
                self.loadout[loadoutNum].tintIndex = weaponTintIndex

                self.triggerSafeEvent("esx:setWeaponTint", {weaponName = weaponName, weaponTintIndex = weaponTintIndex})
                self.triggerSafeEvent("esx:addInventoryItem", {itemName = weaponObject.tints[weaponTintIndex], itemCount = false, showNotification = true})
            end
        end
    end

    function self.getWeaponTint(weaponName)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            return weapon.tintIndex
        end

        return 0
    end

    function self.removeWeapon(weaponName)
        local weaponLabel

        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                weaponLabel = v.label

                for _, v2 in ipairs(v.components) do
                    self.removeWeaponComponent(weaponName, v2)
                end

                table.remove(self.loadout, k)
                break
            end
        end

        if weaponLabel then
            local ped, weaponHash = GetPlayerPed(self.source), joaat(weaponName)

            RemoveWeaponFromPed(ped, weaponHash)
            SetPedAmmo(ped, weaponHash, 0)
            self.triggerSafeEvent("esx:removeInventoryItem", {itemName = weaponLabel, itemCount = false, showNotification = true})
        end
    end

    function self.removeWeaponComponent(weaponName, weaponComponent)
        local loadoutNum, weapon = self.getWeapon(weaponName)

        if weapon then
            local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

            if component then
                if self.hasWeaponComponent(weaponName, weaponComponent) then
                    for k, v in ipairs(self.loadout[loadoutNum].components) do
                        if v == weaponComponent then
                            table.remove(self.loadout[loadoutNum].components, k)
                            break
                        end
                    end

                    RemoveWeaponComponentFromPed(GetPlayerPed(self.source), joaat(weaponName), component.hash)
                    self.triggerSafeEvent("esx:removeInventoryItem", {itemName = component.label, itemCount = false, showNotification = true})
                end
            end
        end
    end

    function self.removeWeaponAmmo(weaponName, ammoCount)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            weapon.ammo = weapon.ammo - ammoCount
            self.updateWeaponAmmo(weaponName, weapon.ammo)
        end
    end

    function self.hasWeaponComponent(weaponName, weaponComponent)
        local _, weapon = self.getWeapon(weaponName)

        if weapon then
            for _, v in ipairs(weapon.components) do
                if v == weaponComponent then
                    return true
                end
            end

            return false
        else
            return false
        end
    end

    function self.hasWeapon(weaponName)
        for _, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return true
            end
        end

        return false
    end

    function self.hasItem(item)
        for _, v in ipairs(self.inventory) do
            if (v.name == item) and (v.count >= 1) then
                return v, v.count
            end
        end

        return false
    end

    function self.getWeapon(weaponName)
        for k, v in ipairs(self.loadout) do
            if v.name == weaponName then
                return k, v
            end
        end
    end

    function self.showNotification(message, type, duration, extra)
        self.triggerSafeEvent("esx:showNotification", {
            message = message,
            type = type,
            duration = duration,
            extra = extra
        })
    end

    function self.showHelpNotification(message, thisFrame, beep, duration)
        self.triggerSafeEvent("esx:showHelpNotification", {
            message = message,
            thisFrame = thisFrame,
            beep = beep,
            duration = duration
        })
    end

    function self.getMetadata(index, subIndex)
        if not index then return self.metadata end

        if type(index) ~= "string" then
            return print("[^1ERROR^7] xPlayer.getMetadata ^5index^7 should be ^5string^7!")
        end

        if self.metadata[index] then
            if subIndex and type(self.metadata[index]) == "table" then
                local _type = type(subIndex)

                if _type == "string" then
                    if self.metadata[index][subIndex] then
                        return self.metadata[index][subIndex]
                    end
                    return
                end

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
            return print(("[^1ERROR^7] xPlayer.getMetadata ^5%s^7 not exist!"):format(index))
        end
    end
    self.getMeta = self.getMetadata -- backward compatibility with esx-legacy

    function self.setMetadata(index, value, subValue)
        if not index then
            return print("[^1ERROR^7] xPlayer.setMetadata ^5index^7 is Missing!")
        end

        if type(index) ~= "string" then
            return print("[^1ERROR^7] xPlayer.setMetadata ^5index^7 should be ^5string^7!")
        end

        if not value then
            return print(("[^1ERROR^7] xPlayer.setMetadata ^5%s^7 is Missing!"):format(value))
        end

        local _type = type(value)
        local lastMetadata = json.decode(json.encode(self.metadata)) -- avoid holding reference to the self.metadata table

        if not subValue then

            if _type ~= "number" and _type ~= "string" and _type ~= "table" then
                return print(("[^1ERROR^7] xPlayer.setMetadata ^5%s^7 should be ^5number^7 or ^5string^7 or ^5table^7!"):format(value))
            end

            self.metadata[index] = value
        else

            if _type ~= "string" then
                return print(("[^1ERROR^7] xPlayer.setMetadata ^5value^7 should be ^5string^7 as a subIndex!"):format(value))
            end

            self.metadata[index][value] = subValue
        end

        self.triggerSafeEvent("esx:setMetadata", {currentMetadata = self.metadata, lastMetadata = lastMetadata}, {server = true, client = true})
        Player(self.source).state:set('metadata', self.metadata, true)
    end
    self.setMeta = self.setMetadata -- backward compatibility with esx-legacy

    function self.clearMetadata(index)
        if not index then
            return print(("[^1ERROR^7] xPlayer.clearMetadata ^5%s^7 is Missing!"):format(index))
        end

        if type(index) == 'table' then
            for _, val in pairs(index) do
                self.clearMetadata(val)
            end

            return
        end

        if not self.metadata[index] then
            return print(("[^1ERROR^7] xPlayer.clearMetadata ^5%s^7 not exist!"):format(index))
        end

        local lastMetadata = json.decode(json.encode(self.metadata)) -- avoid holding reference to the self.metadata table
        self.metadata[index] = nil

        self.triggerSafeEvent("esx:setMetadata", {currentMetadata = self.metadata, lastMetadata = lastMetadata}, {server = true, client = true})
        Player(self.source).state:set('metadata', self.metadata, true)
    end
    self.clearMeta = self.clearMetadata -- backward compatibility with esx-legacy

    ---Gets the table of all players that are in-scope/in-range with the current player
    ---@param includeSelf? boolean include the current player within the return data (defaults to false)
    ---@return xScope | nil
    function self.getInScopePlayers(includeSelf)
        return ESX.GetPlayersInScope(self.source, includeSelf)
    end

    ---Checks if the current player is inside the scope/range of the target player id
    ---@param targetId integer
    ---@return boolean
    function self.isInPlayerScope(targetId)
        return ESX.IsPlayerInScope(self.source, targetId)
    end

    ---Checks if the target player id is inside the scope/range of the current player
    ---@param targetId integer
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