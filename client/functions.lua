function ESX.IsPlayerLoaded()
    return ESX.PlayerLoaded
end

function ESX.GetPlayerData()
    return ESX.PlayerData
end

function ESX.SearchInventory(items, count)
    if type(items) == "string" then items = { items } end

    local returnData = {}
    local itemCount = #items

    for i = 1, itemCount do
        local itemName = items[i]
        returnData[itemName] = count and 0

        for _, item in pairs(ESX.PlayerData.inventory) do
            if item.name == itemName then
                if count then
                    returnData[itemName] = returnData[itemName] + item.count
                else
                    returnData[itemName] = item
                end
            end
        end
    end

    if next(returnData) then
        return itemCount == 1 and returnData[items[1]] or returnData
    end
end

function ESX.SetPlayerData(key, val)
    local current = ESX.PlayerData[key]
    ESX.PlayerData[key] = val

    if key ~= "inventory" and key ~= "loadout" then
        if type(val) == "table" or val ~= current then
            TriggerEvent("esx:setPlayerData", key, val, current)
        end
    end
end

function ESX.UI.ShowInventoryItemNotification(add, item, count)
    SendNUIMessage({
        action = "inventoryNotification",
        add = add,
        item = item,
        count = count
    })
end

function ESX.ShowInventory()
    if not Config.EnableDefaultInventory then return end

    local playerPed = ESX.PlayerData.ped
    local elements = {
        { unselectable = true, icon = "fas fa-box", title = "Player Inventory" }
    }
    local currentWeight = 0

    for i = 1, #(ESX.PlayerData.accounts) do
        if ESX.PlayerData.accounts[i].money > 0 then
            local formattedMoney = _U("locale_currency", ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money))
            local canDrop = ESX.PlayerData.accounts[i].name ~= "bank"

            elements[#elements + 1] = {
                icon = "fas fa-money-bill-wave",
                title = ("%s: %s"):format(ESX.PlayerData.accounts[i].label, formattedMoney),
                count = ESX.PlayerData.accounts[i].money,
                type = "item_account",
                value = ESX.PlayerData.accounts[i].name,
                usable = false,
                rare = false,
                canRemove = canDrop
            }
        end
    end

    for _, v in ipairs(ESX.PlayerData.inventory) do
        if v.count > 0 then
            currentWeight = currentWeight + (v.weight * v.count)

            elements[#elements + 1] = {
                icon = "fas fa-box",
                title = ("%s x%s"):format(v.label, v.count),
                count = v.count,
                type = "item_standard",
                value = v.name,
                usable = v.usable,
                rare = v.rare,
                canRemove = v.canRemove
            }
        end
    end

    for _, v in ipairs(Config.Weapons) do
        local weaponHash = joaat(v.name)

        if HasPedGotWeapon(playerPed, weaponHash, false) then
            local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
            local label = v.ammo and ("%s - %s %s"):format(v.label, ammo, v.ammo.label) or v.label

            elements[#elements + 1] = {
                icon = "fas fa-gun",
                title = label,
                count = 1,
                type = "item_weapon",
                value = v.name,
                usable = false,
                rare = false,
                ammo = ammo,
                canGiveAmmo = (v.ammo ~= nil),
                canRemove = true
            }
        end
    end

    elements[#elements + 1] = {
        unselectable = true,
        icon = "fas fa-weight",
        title = "Current Weight: " .. currentWeight
    }

    ESX.CloseContext()

    ESX.OpenContext("right", elements, function(_, element)
        local player, distance = ESX.Game.GetClosestPlayer()

        local elements2 = {}

        if element.usable then
            elements2[#elements2 + 1] = {
                icon = "fas fa-utensils",
                title = _U("use"),
                action = "use",
                type = element.type,
                value = element.value
            }
        end

        if element.canRemove then
            if player ~= -1 and distance <= 3.0 then
                elements2[#elements2 + 1] = {
                    icon = "fas fa-hands",
                    title = _U("give"),
                    action = "give",
                    type = element.type,
                    value = element.value
                }
            end

            elements2[#elements2 + 1] = {
                icon = "fas fa-trash",
                title = _U("remove"),
                action = "remove",
                type = element.type,
                value = element.value
            }
        end

        if element.type == "item_weapon" and element.canGiveAmmo and element.ammo > 0 and player ~= -1 and distance <= 3.0 then
            elements2[#elements2 + 1] = {
                icon = "fas fa-gun",
                title = _U("giveammo"),
                action = "give_ammo",
                type = element.type,
                value = element.value
            }
        end

        elements2[#elements2 + 1] = {
            icon = "fas fa-arrow-left",
            title = _U("return"),
            action = "return"
        }

        ESX.OpenContext("right", elements2, function(_, element2)
            local item, type = element2.value, element2.type

            if element2.action == "give" then
                local playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)

                if #playersNearby > 0 then
                    local players = {}
                    local elements3 = {
                        { unselectable = true, icon = "fas fa-users", title = "Nearby Players" }
                    }

                    for _, playerNearby in ipairs(playersNearby) do
                        players[GetPlayerServerId(playerNearby)] = true
                    end

                    ESX.TriggerServerCallback("esx:getPlayerNames", function(returnedPlayers)
                        for playerId, playerName in pairs(returnedPlayers) do
                            elements3[#elements3 + 1] = {
                                icon = "fas fa-user",
                                title = playerName,
                                playerId = playerId
                            }
                        end

                        ESX.OpenContext("right", elements3, function(_, element3)
                            local selectedPlayer, selectedPlayerId = GetPlayerFromServerId(element3.playerId), element3.playerId
                            playersNearby = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
                            playersNearby = ESX.Table.Set(playersNearby)

                            if playersNearby[selectedPlayer] then
                                local selectedPlayerPed = GetPlayerPed(selectedPlayer)

                                if IsPedOnFoot(selectedPlayerPed) and not IsPedFalling(selectedPlayerPed) then
                                    if type == "item_weapon" then
                                        TriggerServerEvent("esx:giveInventoryItem", selectedPlayerId, type, item, nil)
                                        ESX.CloseContext()
                                    else
                                        local elementsG = {
                                            { unselectable = true,          icon = "fas fa-trash", title = element.title },
                                            { icon = "fas fa-hashtag",      title = "Amount",      input = true,         inputType = "number", inputPlaceholder = "Amount to give...", inputMin = 1, inputMax = 1000 },
                                            { icon = "fas fa-check-double", title = "Confirm",     val = "confirm" }
                                        }

                                        ESX.OpenContext("right", elementsG, function(menuG, _)
                                            local quantity = tonumber(menuG.eles[2].inputValue)

                                            if quantity and quantity > 0 and element.count >= quantity then
                                                TriggerServerEvent("esx:giveInventoryItem", selectedPlayerId, type, item, quantity)
                                                ESX.CloseContext()
                                            else
                                                ESX.ShowNotification(_U("amount_invalid"))
                                            end
                                        end)
                                    end
                                else
                                    ESX.ShowNotification(_U("in_vehicle"))
                                end
                            else
                                ESX.ShowNotification(_U("players_nearby"))
                                ESX.CloseContext()
                            end
                        end)
                    end, players)
                end
            elseif element2.action == "remove" then
                if IsPedOnFoot(playerPed) and not IsPedFalling(playerPed) then
                    local dict, anim = "weapons@first_person@aim_rng@generic@projectile@sticky_bomb@", "plant_floor"
                    ESX.Streaming.RequestAnimDict(dict)

                    if type == "item_weapon" then
                        ESX.CloseContext()
                        TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                        RemoveAnimDict(dict)
                        Wait(1000)
                        TriggerServerEvent("esx:removeInventoryItem", type, item)
                    else
                        local elementsR = {
                            { unselectable = true,          icon = "fas fa-trash", title = element.title },
                            { icon = "fas fa-hashtag",      title = "Amount",      input = true,         inputType = "number", inputPlaceholder = "Amount to remove...", inputMin = 1, inputMax = 1000 },
                            { icon = "fas fa-check-double", title = "Confirm",     val = "confirm" }
                        }

                        ESX.OpenContext("right", elementsR, function(menuR, _)
                            local quantity = tonumber(menuR.eles[2].inputValue)

                            if quantity and quantity > 0 and element.count >= quantity then
                                ESX.CloseContext()
                                TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                                RemoveAnimDict(dict)
                                Wait(1000)
                                TriggerServerEvent("esx:removeInventoryItem", type, item, quantity)
                            else
                                ESX.ShowNotification(_U("amount_invalid"))
                            end
                        end)
                    end
                end
            elseif element2.action == "use" then
                ESX.CloseContext()
                TriggerServerEvent("esx:useItem", item)
            elseif element2.action == "return" then
                ESX.CloseContext()
                ESX.ShowInventory()
            elseif element2.action == "give_ammo" then
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                local closestPed = GetPlayerPed(closestPlayer)
                local pedAmmo = GetAmmoInPedWeapon(playerPed, joaat(item))

                if IsPedOnFoot(closestPed) and not IsPedFalling(closestPed) then
                    if closestPlayer ~= -1 and closestDistance < 3.0 then
                        if pedAmmo > 0 then
                            local elementsGA = {
                                { unselectable = true,          icon = "fas fa-trash", title = element.title },
                                { icon = "fas fa-hashtag",      title = "Amount",      input = true,         inputType = "number", inputPlaceholder = "Amount to give...", inputMin = 1, inputMax = 1000 },
                                { icon = "fas fa-check-double", title = "Confirm",     val = "confirm" }
                            }

                            ESX.OpenContext("right", elementsGA, function(menuGA, _)
                                local quantity = tonumber(menuGA.eles[2].inputValue)

                                if quantity and quantity > 0 then
                                    if pedAmmo >= quantity then
                                        TriggerServerEvent("esx:giveInventoryItem", GetPlayerServerId(closestPlayer), "item_ammo", item, quantity)
                                        ESX.CloseContext()
                                    else
                                        ESX.ShowNotification(_U("noammo"))
                                    end
                                else
                                    ESX.ShowNotification(_U("amount_invalid"))
                                end
                            end)
                        else
                            ESX.ShowNotification(_U("noammo"))
                        end
                    else
                        ESX.ShowNotification(_U("players_nearby"))
                    end
                else
                    ESX.ShowNotification(_U("in_vehicle"))
                end
            end
        end)
    end)
end
