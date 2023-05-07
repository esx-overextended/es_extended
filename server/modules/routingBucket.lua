---@alias playerId integer
---@alias routingBucket integer
---@alias routingBucketData table<integer, true>


---@type table<routingBucket, routingBucketData>
local routingBuckets = {}
---@type table<playerId, routingBucket>
local routingBucketPlayers = {}

---Setup routing bucket table (for internal use)
---@param bucketId integer
local function configureBucket(bucketId)
    if routingBuckets[bucketId] then return end

    routingBuckets[bucketId] = setmetatable({}, {
        __index = function() return false end,
        __newindex = function(self, index, value)
            rawset(self, index, value)

            routingBucketPlayers[index] = bucketId

            if value then
                SetPlayerRoutingBucket(index, bucketId)
                ESX.TriggerSafeEvent("esx:setPlayerRoutingBucket", index, { routingBucket = bucketId }, { server = true, client = true })
            end

            if not next(routingBuckets[bucketId]) then routingBuckets[bucketId] = nil end
        end
    })
end

---action to do when a player joins in
---@param source integer
local function onPlayerJoining(source)
    source = tonumber(source) --[[@as number]]

    local bucketId = GetPlayerRoutingBucket(source) --[[@as routingBucket]]

    ESX.SetPlayerRoutingBucket(source, bucketId)
end

AddEventHandler("playerJoining", function()
    onPlayerJoining(source)
end)

---action to do when a player drops/logs out
---@param source integer
local function onPlayerDropped(source)
    source = tonumber(source) --[[@as number]]

    if not source then return end

    local bucketId = routingBucketPlayers[source] --[[@as routingBucket]]

    if not bucketId then return print(("[^3WARNING^7] Player Id (^5%s^7) surprisingly did not have routing bucket id assigned!"):format(source)) end

    getmetatable(routingBuckets[bucketId]).__newindex(routingBuckets[bucketId], source, nil)
end

AddEventHandler("playerDropped", function()
    onPlayerDropped(source)
end)

---Adds the player id to the routing bucket id
---@param playerId integer
---@param bucketId integer
---@return boolean
function ESX.SetPlayerRoutingBucket(playerId, bucketId)
    playerId = tonumber(playerId) --[[@as number]]
    bucketId = tonumber(bucketId) --[[@as number]]

    if not playerId or not bucketId then return false end

    local currentBucketId = routingBucketPlayers[source]

    if currentBucketId then
        routingBuckets[currentBucketId][playerId] = nil
    end

    configureBucket(bucketId)

    routingBuckets[bucketId][playerId] = true

    return true
end

---Gets the routing bucket id that the player id is inside
---@param playerId integer
---@return routingBucket | nil
function ESX.GetPlayerRoutingBucket(playerId)
    playerId = tonumber(playerId) --[[@as number]]

    return routingBucketPlayers[playerId]
end

---Gets the routing bucket id that the player id is inside
---@param bucketId integer
---@return routingBucketData | nil
function ESX.GetRoutingBucketPlayers(bucketId)
    bucketId = tonumber(bucketId) --[[@as number]]

    return routingBuckets[bucketId]
end