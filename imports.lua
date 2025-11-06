local es_extended = "es_extended"
local esxMT = {
    __index = function(self, index)
        local reference = exports[es_extended]:getReference(index)

        rawset(self, index, reference)

        return reference
    end
}

ESX = setmetatable({}, esxMT)

if not _VERSION:find("5.4") then
    return ESX.Trace("^1Lua 5.4 must be enabled in the resource manifest!^7", "error", true)
end

local getInvokingResource = GetInvokingResource

---@param eventName string
---@param cb function
local function eventHandler(eventName, cb)
    AddEventHandler(eventName, function(...)
        local invokingResource = getInvokingResource()

        if invokingResource == es_extended then
            return cb(...)
        end

        ESX.Trace(("Event (%s) was triggered, but not from the framework! Invoked from (%s)"):format(eventName, invokingResource), "error", true)
    end)
end

if not IsDuplicityVersion() then -- Client
    eventHandler("esx:setPlayerData", function(key, val, last)
        ESX.PlayerData[key] = val

        local onPlayerData = _G.OnPlayerData --[[@as function?]]

        if onPlayerData then
            onPlayerData(key, val, last)
        end
    end)

    eventHandler("esx:playerLoaded", function(xPlayer)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true
    end)

    eventHandler("esx:onPlayerLogout", function()
        ESX.PlayerLoaded = false
        ESX.PlayerData = {}
    end)

    eventHandler("esx:sharedObjectUpdated", function()
        ESX = setmetatable({}, esxMT)

        collectgarbage("collect")
    end)
else -- Server
    local jobsMT = {
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
    }
    local groupsMT = {
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
    }

    local function setupESX()
        local _GetPlayerFromId = ESX.GetPlayerFromId

        ESX.Jobs = setmetatable({}, jobsMT)
        ESX.Groups = setmetatable({}, groupsMT)

        function ESX.GetPlayerFromId(playerId) ---@diagnostic disable-line: duplicate-set-field
            local xPlayer = _GetPlayerFromId(playerId)

            return xPlayer and setmetatable(xPlayer, {
                __index = function(self, index)
                    if index == "coords" then return self.getCoords() end

                    return rawget(self, index)
                end
            })
        end

        --backward-compatibility with esx legacy
        ---@param src number|string
        ---@return xPlayer?
        function ESX.Player(src)
            ---@diagnostic disable-next-line: param-type-mismatch
            return ESX.GetPlayerFromId(src) or ESX.GetPlayerFromIdentifier(src) or ESX.GetPlayerFromCid(src)
        end

        --backward-compatibility with esx legacy
        ---@param key? string
        ---@param val? string|string[]
        ---@return xPlayer[], number
        function ESX.ExtendedPlayers(key, val)
            return ESX.GetExtendedPlayers(key, val)
        end
    end

    do setupESX() end

    eventHandler("esx:jobsObjectRefreshed", function()
        if ESX and ESX.Jobs and next(ESX.Jobs) then -- check to see if ESX.Jobs is being used in this external resource or not
            ESX.Jobs = setmetatable(ESX.GetJobs(), jobsMT)
        end
    end)

    eventHandler("esx:groupsObjectRefreshed", function()
        if ESX and ESX.Groups and next(ESX.Groups) then -- check to see if ESX.Groups is being used in this external resource or not
            ESX.Groups = setmetatable(ESX.GetJobs(), groupsMT)
        end
    end)

    eventHandler("esx:sharedObjectUpdated", function()
        ESX = setmetatable({}, esxMT)

        do setupESX() end

        collectgarbage("collect")
    end)
end

return ESX
