---@diagnostic disable: need-check-nil

---@alias xScope table<integer, true>

---@type table<integer, xScope>
local scopes = {}

---action to do when a player joins in
---@param source integer
local function onPlayerJoining(source)
    source = tonumber(source) --[[@as number]]

    scopes[source] = setmetatable({}, {
        __index = function() return false end
    })
end

AddEventHandler("playerJoining", function()
    onPlayerJoining(source)
end)

---action to do when a player drops/logs out
---@param source integer
local function onPlayerDropped(source)
    source = tonumber(source) --[[@as number]]

    if not source then return end

    scopes[source] = nil

    for _, scopeData in pairs(scopes) do
        if scopeData[source] then
            scopeData[source] = nil
        end
    end
end

AddEventHandler("playerDropped", function()
    onPlayerDropped(source)
end)

AddEventHandler("playerEnteredScope", function(data)
    local playerEntering, player = tonumber(data["player"]), tonumber(data["for"]) --[[@as number]]

    if not scopes[player] then
        onPlayerJoining(player)
        print(("[^4INFO^7] Player Id ^3%s^7 did not have its scope configured beforehand. However that is handled but it should not have happened!"):format(player))
    end

    scopes[player][playerEntering] = true
end)

AddEventHandler("playerLeftScope", function(data)
    local playerLeaving, player = tonumber(data["player"]), tonumber(data["for"]) --[[@as number]]

    if not scopes[player] then return end

    scopes[player][playerLeaving] = nil
end)

local function onResourceStart(resource)
    if resource ~= GetCurrentResourceName() then return end

    for _, playerId in ipairs(GetPlayers()) do
        onPlayerJoining(playerId --[[@as number]])
    end
end

AddEventHandler("onResourceStart", onResourceStart)
AddEventHandler("onServerResourceStart", onResourceStart)

---Gets the table of all players that are inside the scope of a player id
---@param scopeOwner integer server id of the player/scope owner
---@param includeScopeOwner? boolean include the scope owner within the return data (defaults to false)
---@return xScope | nil
function ESX.GetPlayersInScope(scopeOwner, includeScopeOwner)
    scopeOwner = tonumber(scopeOwner) --[[@as number]]

    if not includeScopeOwner then
        return scopes[scopeOwner]
    end

    if not scopes[scopeOwner] then return end

    local xScope = lib.table.deepclone(scopes[scopeOwner]) --[[@as xScope]]
    xScope[scopeOwner] = true

    return xScope
end

---Checks whether the playerId can be found inside the scopeId
---@param playerId integer target player id to check
---@param scopeId integer scope id/scope of a player id to check
---@return boolean
function ESX.IsPlayerInScope(playerId, scopeId)
    playerId = tonumber(playerId) --[[@as number]]
    scopeId = tonumber(scopeId) --[[@as number]]

    return scopes[scopeId] and (playerId == scopeId or scopes[scopeId][playerId] == true) or false
end

---Triggers a client event for all players that are inside a scope id/scope of a player id
---@param eventName string name of the client event
---@param scopeOwner integer scope id/scope of a player id
---@param includeScopeOwner? boolean trigger the event for the scopeOwner (defaults to false)
---@param ... any
function ESX.TriggerScopedEvent(eventName, scopeOwner, includeScopeOwner, ...)
    local targets = ESX.GetPlayersInScope(scopeOwner, includeScopeOwner)

    if not targets then return print(("[^3WARNING^7] No such scope (^5%s^7) is available!"):format(scopeOwner)) end

    for targetId in pairs(targets) do
        TriggerClientEvent(eventName, targetId, ...)
    end
end

---Triggers a safe client event for all players that are inside a scope id/scope of a player id
---@param eventName string name of the safe event
---@param scopeOwner integer scope id/scope of a player id
---@param includeScopeOwner? boolean trigger the event for the scopeOwner (defaults to false)
---@param eventData? table -- data to send through the safe event
---@param eventOptions? CEventOptions data to define whether server, client, or both should be triggered (defaults to {server = false, client = true})
function ESX.TriggerSafeScopedEvent(eventName, scopeOwner, includeScopeOwner, eventData, eventOptions)
    local targets = ESX.GetPlayersInScope(scopeOwner, includeScopeOwner)

    if not targets then return print(("[^3WARNING^7] No such scope (^5%s^7) is available!"):format(scopeOwner)) end

    for targetId in pairs(targets) do
        ESX.TriggerSafeEvent(eventName, targetId, eventData, eventOptions or { server = false, client = true })
    end
end

do
    ESX.RegisterPlayerMethodOverrides({
        ---Gets a table including all instances of players ids that are in-scope/in-range with the current player.
        ---@param self xPlayer
        getInScopePlayers = function(self)
            ---@param includeSelf? boolean include the current player within the return data (defaults to false)
            ---@return xScope | nil
            return function(includeSelf)
                return ESX.GetPlayersInScope(self.source, includeSelf)
            end
        end,

        ---Checks if the player is inside the scope/range of the target player id.
        ---@param self xPlayer
        isInPlayerScope = function(self)
            ---@param targetId number
            ---@return boolean
            return function(targetId)
                return ESX.IsPlayerInScope(self.source, targetId)
            end
        end,

        ---Checks if the target player id is inside the scope/range of the current player.
        ---@param self xPlayer
        isPlayerInScope = function(self)
            ---@param targetId number
            ---@return boolean
            return function(targetId)
                return ESX.IsPlayerInScope(targetId, self.source)
            end
        end,

        ---Triggers a client event for all players that are in-scope/in-range with the current player.
        ---@param self xPlayer
        triggerScopedEvent = function(self)
            ---@param eventName string name of the client event
            ---@param includeSelf? boolean trigger the event for the current player (defaults to false)
            ---@param ... any
            return function(eventName, includeSelf, ...)
                ESX.TriggerScopedEvent(eventName, self.source, includeSelf, ...)
            end
        end,

        ---Triggers a safe event for all players that are in-scope/in-range with the current player.
        ---@param self xPlayer
        triggerSafeScopedEvent = function(self)
            ---@param eventName string name of the safe event
            ---@param includeSelf? boolean trigger the event for the current player (defaults to false)
            ---@param eventData? table -- data to send through the safe event
            ---@param eventOptions? CEventOptions data to define whether server, client, or both should be triggered (defaults to {server = false, client = true})
            return function(eventName, includeSelf, eventData, eventOptions)
                ESX.TriggerSafeScopedEvent(eventName, self.source, includeSelf, eventData, eventOptions)
            end
        end
    })
end
