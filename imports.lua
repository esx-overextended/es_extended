ESX = exports["es_extended"]:getSharedObject()

if not _VERSION:find("5.4") then
    return ESX.Trace("^1Lua 5.4 must be enabled in the resource manifest!^7", "error", true)
end

if not IsDuplicityVersion() then -- Only register these for the client
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

    AddEventHandler("esx:sharedObjectUpdated", function()
        ESX = exports["es_extended"]:getSharedObject()

        collectgarbage("collect")
    end)
else -- Only register these for the server
    local function setupESX()
        local _GetPlayerFromId = ESX.GetPlayerFromId

        ESX.Jobs = setmetatable({}, {
            __index = function(self, index)
                if not next(self) then self() end

                return rawget(self, index)
            end,
            __call = function(self)
                for key, data in pairs(ESX.GetJobs()) do
                    rawset(self, key, data)
                end

                return self
            end,
            __pairs = function(self)
                if not next(self) then self() end

                return next, self, nil ---@diagnostic disable-line: redundant-return-value
            end
        })

        ESX.Groups = setmetatable({}, {
            __index = function(self, index)
                if not next(self) then self() end

                return rawget(self, index)
            end,
            __call = function(self)
                for key, data in pairs(ESX.GetGroups()) do
                    rawset(self, key, data)
                end

                return self
            end,
            __pairs = function(self)
                if not next(self) then self() end

                return next, self, nil ---@diagnostic disable-line: redundant-return-value
            end
        })

        function ESX.GetPlayerFromId(playerId) ---@diagnostic disable-line: duplicate-set-field
            local xPlayer = _GetPlayerFromId(playerId)

            return xPlayer and setmetatable(xPlayer, {
                __index = function(self, index)
                    if index == "coords" then return self.getCoords() end

                    return rawget(self, index)
                end
            })
        end
    end

    do setupESX() end

    AddEventHandler("esx:jobsObjectRefreshed", function()
        if ESX and ESX.Jobs then
            ESX.Jobs = ESX.GetJobs()
        end
    end)

    AddEventHandler("esx:groupsObjectRefreshed", function()
        if ESX and ESX.Groups then
            ESX.Groups = ESX.GetGroups()
        end
    end)

    AddEventHandler("esx:sharedObjectUpdated", function()
        ESX = exports["es_extended"]:getSharedObject()

        do setupESX() end

        collectgarbage("collect")
    end)
end
