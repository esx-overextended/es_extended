ESX = exports["es_extended"]:getSharedObject()

if not IsDuplicityVersion() then -- Only register this event for the client
    AddEventHandler("esx:setPlayerData", function(key, val, last)
        if GetInvokingResource() == "es_extended" then
            ESX.PlayerData[key] = val
            if _G.OnPlayerData then
                _G.OnPlayerData(key, val, last)
            end
        end
    end)

    AddEventHandler("esx:playerLoaded", function(xPlayer)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true
    end)

    AddEventHandler("esx:onPlayerLogout", function()
        ESX.PlayerLoaded = false
        ESX.PlayerData = {}
    end)
else -- Only register this event for the server
    local _GetPlayerFromId = ESX.GetPlayerFromId
    ---@diagnostic disable-next-line: duplicate-set-field
    function ESX.GetPlayerFromId(playerId)
        local xPlayer = _GetPlayerFromId(playerId)

        return xPlayer and setmetatable(xPlayer, {
            __index = function(self, index)
                if index == "coords" then return self.getCoords() end

                return rawget(self, index)
            end
        })
    end
end
