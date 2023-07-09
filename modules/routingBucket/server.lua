---@class routingBucketData
---@field players routingBucketPlayersData
---@field entities routingBucketEntitiesData


---@type table<routingBucket, routingBucketData>
local routingBuckets = {}
---@type table<playerId, routingBucket>
local routingBucketPlayers = {}
---@type table<entityId, routingBucket>
local routingBucketEntities = {}

---Setup routing bucket table (for internal use)
---@param bucketId routingBucket
local function configureBucket(bucketId)
    if routingBuckets[bucketId] then return end

    routingBuckets[bucketId] = {
        players = setmetatable({}, {
            __index = function() return false end,
            __newindex = function(self, index, value)
                rawset(self, index, value)

                routingBucketPlayers[index] = value and bucketId

                if value then
                    SetPlayerRoutingBucket(index, bucketId)

                    if ESX.Players[index] then ESX.Players[index].routingBucket = bucketId end

                    Player(index).state:set("routingBucket", bucketId, true)
                    ESX.TriggerSafeEvent("esx:setPlayerRoutingBucket", index, { routingBucket = bucketId }, { server = true, client = true })
                end

                if routingBuckets[bucketId].players and next(routingBuckets[bucketId].players) or routingBuckets[bucketId].entities and next(routingBuckets[bucketId].entities) then return end

                routingBuckets[bucketId] = nil
            end
        }),
        entities = setmetatable({}, {
            __index = function() return false end,
            __newindex = function(self, index, value)
                rawset(self, index, value)

                routingBucketEntities[index] = value and bucketId

                if value then
                    SetEntityRoutingBucket(index, bucketId)

                    if Core.Vehicles[index] then Core.Vehicles[index].routingBucket = bucketId end

                    Entity(index).state:set("routingBucket", bucketId, true)
                    TriggerEvent("esx:setEntityRoutingBucket", index, bucketId)
                end

                if routingBuckets[bucketId].entities and next(routingBuckets[bucketId].entities) or routingBuckets[bucketId].players and next(routingBuckets[bucketId].players) then return end

                routingBuckets[bucketId] = nil
            end
        })
    }
end

---action to do when a player joins in
---@param source playerId
local function onPlayerJoining(source)
    source = tonumber(source) --[[@as number]]

    local bucketId = GetPlayerRoutingBucket(source--[[@as string]])

    ESX.SetPlayerRoutingBucket(source, bucketId)
end

AddEventHandler("playerJoining", function()
    onPlayerJoining(source)
end)

---action to do when a player drops/logs out
---@param source playerId
local function onPlayerDropped(source)
    source = tonumber(source) --[[@as number]]

    if not source then return end

    local bucketId = routingBucketPlayers[source] --[[@as routingBucket]]

    if not bucketId then return print(("[^3WARNING^7] Player Id (^5%s^7) surprisingly did not have routing bucket id assigned!"):format(source)) end

    getmetatable(routingBuckets[bucketId].players).__newindex(routingBuckets[bucketId].players, source, nil)
end

AddEventHandler("playerDropped", function()
    onPlayerDropped(source)
end)

local function onResourceStart(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, playerId in ipairs(GetPlayers()) do
        onPlayerJoining(playerId --[[@as number]])
    end
end

AddEventHandler("onResourceStart", onResourceStart)
AddEventHandler("onServerResourceStart", onResourceStart)

--[[ -- we can but we don't need to cache all entities as it makes the cache tables so much populated
AddEventHandler("entityCreated", function(entityId)
    if not DoesEntityExist(entityId) then return end

    ESX.SetEntityRoutingBucket(entityId, GetEntityRoutingBucket(entityId))
end)
]]

AddEventHandler("entityRemoved", function(entityId)
    if not routingBucketEntities[entityId] then return end

    getmetatable(routingBuckets[routingBucketEntities[entityId]].entities).__newindex(routingBuckets[routingBucketEntities[entityId]].entities, entityId, nil)
end)

---Adds the player id to the routing bucket id
---@param playerId playerId
---@param bucketId routingBucket
---@return boolean
function ESX.SetPlayerRoutingBucket(playerId, bucketId)
    playerId = tonumber(playerId) --[[@as number]]
    bucketId = tonumber(bucketId) --[[@as number]]

    if not playerId or not bucketId or GetPlayerPing(playerId --[[@as string]]) == 0 then return false end

    local currentBucketId = routingBucketPlayers[playerId]

    if currentBucketId then
        getmetatable(routingBuckets[currentBucketId].players).__newindex(routingBuckets[currentBucketId].players, playerId, nil)
    end

    configureBucket(bucketId)

    routingBuckets[bucketId].players[playerId] = true

    return true
end

---Adds the entity id to the routing bucket id
---@param entityId entityId
---@param bucketId routingBucket
---@return boolean
function ESX.SetEntityRoutingBucket(entityId, bucketId)
    entityId = tonumber(entityId) --[[@as number]]
    bucketId = tonumber(bucketId) --[[@as number]]

    if not entityId or not bucketId or not DoesEntityExist(entityId) then return false end

    local currentBucketId = routingBucketEntities[entityId]

    if currentBucketId then
        getmetatable(routingBuckets[currentBucketId].entities).__newindex(routingBuckets[currentBucketId].entities, entityId, nil)
    end

    configureBucket(bucketId)

    routingBuckets[bucketId].entities[entityId] = true

    return true
end

---Gets the routing bucket id that the player id is inside
---@param playerId playerId
---@return routingBucket | nil
function ESX.GetPlayerRoutingBucket(playerId)
    playerId = tonumber(playerId) --[[@as number]]

    return routingBucketPlayers[playerId]
end

---Gets the routing bucket id that the entity id is inside
---@param entityId entityId
---@return routingBucket | nil
function ESX.GetEntityRoutingBucket(entityId)
    entityId = tonumber(entityId) --[[@as number]]

    return routingBucketEntities[entityId]
end

---Gets all of the players inside the routing bucket id
---@param bucketId routingBucket
---@return routingBucketPlayersData | nil
function ESX.GetRoutingBucketPlayers(bucketId)
    bucketId = tonumber(bucketId) --[[@as number]]

    return routingBuckets[bucketId]?.players
end

---Gets all of the entities inside the routing bucket id
---@param bucketId routingBucket
---@return routingBucketEntitiesData | nil
function ESX.GetRoutingBucketEntities(bucketId)
    bucketId = tonumber(bucketId) --[[@as number]]

    return routingBuckets[bucketId]?.entities
end

---Gets all of the routing bucket id data (players & entities)
---@param bucketId routingBucket
---@return routingBucketData | nil
function ESX.GetRoutingBucketData(bucketId)
    bucketId = tonumber(bucketId) --[[@as number]]

    return routingBuckets[bucketId]
end

ESX.RegisterSafeEvent("esx:setPlayerRoutingBucket", function(value)
    TriggerEvent("esx:setPlayerRoutingBucket", value.source, value.routingBucket)
end)

do
    Core.ResourceExport:registerHook("onPlayerLoad", function(payload)
        local xPlayer = payload?.xPlayer and ESX.Players[payload.xPlayer?.source]

        if not xPlayer then return print("[^1ERROR^7] Unexpected behavior from onPlayerLoad hook in modules/routingBucket/server.lua") end

        xPlayer.routingBucket = ESX.GetPlayerRoutingBucket(xPlayer.source)
    end)

    ESX.RegisterPlayerMethodOverrides({
        ---Gets the routing bucket id that the player is inside.
        ---@param self xPlayer
        getRoutingBucket = function(self)
            ---@return number
            return function()
                return self.routingBucket
            end
        end,

        ---Adds the player to the specified routing bucket id.
        ---@param self xPlayer
        setRoutingBucket = function(self)
            ---@param bucketId routingBucket
            ---@return boolean
            return function(bucketId)
                local success = ESX.SetPlayerRoutingBucket(self.source, bucketId)

                if success then self.routingBucket = tonumber(bucketId) end

                return success
            end
        end
    })

    Core.ResourceExport:registerHook("onVehicleCreate", function(payload)
        local xVehicle = payload?.xVehicle and Core.Vehicles[payload.xVehicle?.entity]

        if not xVehicle then return print("[^1ERROR^7] Unexpected behavior from onVehicleCreate hook in modules/routingBucket/server.lua") end

        xVehicle.routingBucket = ESX.GetEntityRoutingBucket(xVehicle.entity)
    end)

    ESX.RegisterPlayerMethodOverrides({
        ---Gets the routing bucket id that the vehicle is inside.
        ---@param self xVehicle
        getRoutingBucket = function(self)
            ---@return number
            return function()
                return self.routingBucket
            end
        end,

        ---Adds the vehicle to the specified routing bucket id.
        ---@param self xVehicle
        setRoutingBucket = function(self)
            ---@param bucketId routingBucket
            ---@return boolean
            return function(bucketId)
                local success = ESX.SetEntityRoutingBucket(self.entity, bucketId)

                if success then self.routingBucket = tonumber(bucketId) end

                return success
            end
        end
    })
end