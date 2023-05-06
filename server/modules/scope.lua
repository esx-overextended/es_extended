---@diagnostic disable: need-check-nil

---@alias xScope table<integer, true>

---@type table<integer, xScope>
local scopes = {}
local syncedScopes = {}

AddEventHandler("playerEnteredScope", function(data)
    local playerEntering, player = tonumber(data["player"]), tonumber(data["for"])

    if not scopes[player] then
        scopes[player] = setmetatable({}, {
            __index = function() return false end,
            __newindex = function(self, index, value)
                local invokingResource, currentResource = GetInvokingResource(), GetCurrentResourceName()
                if invokingResource and invokingResource ~= currentResource then -- not being triggered from the framework
                    return print(("[^3WARNING^7] Resource ^1%s^7 is modifying players' scope data. This should ^5not^7 be happening!"):format(invokingResource))
                end

                rawset(self, index, value)
            end
        })
    end

    if not syncedScopes[player] then
        local xPlayer = ESX.GetPlayerFromId(player)

        if xPlayer then
            xPlayer.inScopePlayers = scopes[player] --- point the xPlayer.inScopePlayers table to the same memory as scopes[player]
            syncedScopes[player] = true
        end
    end

    scopes[player][playerEntering] = true
end)

AddEventHandler("playerLeftScope", function(data)
    local playerLeaving, player = tonumber(data["player"]), tonumber(data["for"])

    if not scopes[player] then return end

    scopes[player][playerLeaving] = nil
end)

---action to do when a player drops/logs out
---@param source integer
local function onPlayerDropped(source)
    source = tonumber(source) --[[@as number]]

    if not source then return end

    scopes[source], syncedScopes[source] = nil, nil

    for _, scopeData in ipairs(scopes) do
        if scopeData[source] then
            scopeData[source] = nil
        end
    end
end

AddEventHandler("playerDropped", function()
    onPlayerDropped(source)
end)

AddEventHandler("esx:playerDropped", function(source)
    onPlayerDropped(source)
end)

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

---Triggers a client event for all players that are inside a scope id/scope of a player id
---@param eventName string name of the client event
---@param scopeOwner integer name of the client event
---@param includeScopeOwner? boolean include the scope owner within the return data (defaults to false)
---@param ... any
function ESX.TriggerScopedEvent(eventName, scopeOwner, includeScopeOwner, ...)
    local targets = ESX.GetPlayersInScope(scopeOwner, includeScopeOwner)

    if not targets then return print(("[^3WARNING^7] No such scope (^5%s^7) is available!"):format(scopeOwner)) end

    for targetId in ipairs(targets) do
        TriggerClientEvent(eventName, targetId, ...)
    end
end
