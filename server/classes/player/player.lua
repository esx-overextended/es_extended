local xPlayerMethods = lib.require("server.classes.player.playerMethods")

---Creates an xPlayer object
---@param cid string
---@param playerId number
---@param playerIdentifier string
---@param playerGroups table<string, number>
---@param playerGroup string
---@param playerAccounts table
---@param playerInventory table
---@param playerInventoryWeight number
---@param playerJob table
---@param playerLoadout table
---@param playerName string
---@param playerMetadata table
---@return xPlayer
function CreateExtendedPlayer(cid, playerId, playerIdentifier, playerGroups, playerGroup, playerAccounts, playerInventory, playerInventoryWeight, playerJob, playerLoadout, playerName, playerMetadata)
    ---@type xPlayer
    local self = {} ---@diagnostic disable-line: missing-fields

    self.cid = cid
    self.accounts = playerAccounts
    self.groups = playerGroups
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
        lib.addPrincipal(("identifier.%s"):format(self.license), ("group.%s:%s"):format(groupName, groupGrade))
    end

    local stateBag = Player(self.source).state

    stateBag:set("cid", self.cid, true)
    stateBag:set("identifier", self.identifier, true)
    stateBag:set("license", self.license, true)
    stateBag:set("job", self.job, true)
    stateBag:set("duty", self.job.duty, true)
    stateBag:set("groups", self.groups, true)
    stateBag:set("group", self.group, true)
    stateBag:set("name", self.name, true)
    stateBag:set("metadata", self.metadata, true)

    for fnName, fn in pairs(xPlayerMethods) do
        self[fnName] = fn(self)
    end

    for fnName, fn in pairs(Core.ExtendedPlayerMethods) do
        self[fnName] = fn(self)
    end

    return self
end

---Returns instance of xPlayers
---@param key? string
---@param value? any
---@return xPlayer[], integer | number
function ESX.GetExtendedPlayers(key, value)
    local xPlayers, count = {}, 0

    for _, xPlayer in pairs(ESX.Players) do
        if key then
            if (key == "job" and xPlayer.job.name == value) or (key == "group" and xPlayer.groups[value]) or xPlayer[key] == value then
                count += 1
                xPlayers[count] = xPlayer
            end
        else
            count += 1
            xPlayers[count] = xPlayer
        end
    end

    return xPlayers, count
end

---Returns an instance of xPlayer for the passed server id
---@param source number | string
---@return xPlayer?
function ESX.GetPlayerFromId(source) ---@diagnostic disable-line: duplicate-set-field
    return ESX.Players[tonumber(source)]
end

---Returns an instance of xPlayer for the passed player identifier
---@param identifier string
---@return xPlayer?
function ESX.GetPlayerFromIdentifier(identifier)
    return Core.PlayersByIdentifier[identifier]
end

---Saves the player data into database
---@param xPlayer xPlayer
---@param cb? function
function Core.SavePlayer(xPlayer, cb)
    local queries = {
        {
            query = "UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `job_duty` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ?, `metadata` = ? WHERE `identifier` = ?",
            values = {
                json.encode(xPlayer.getAccounts(true)),
                xPlayer.job.name,
                xPlayer.job.grade,
                xPlayer.job.duty,
                xPlayer.group,
                json.encode(xPlayer.getCoords()),
                json.encode(xPlayer.getInventory(true)),
                json.encode(xPlayer.getLoadout(true)),
                json.encode(xPlayer.getMetadata()),
                xPlayer.identifier
            }
        },
        {
            query = "DELETE FROM `user_groups` WHERE `identifier` = ? AND `name` <> ?",
            values = { xPlayer.identifier, xPlayer.group }
        }
    }

    for groupName, groupGrade in pairs(xPlayer.groups) do
        if groupName ~= xPlayer.group then
            queries[#queries + 1] = {
                query = "INSERT INTO `user_groups` (identifier, name, grade) VALUES (?, ?, ?)",
                values = { xPlayer.identifier, groupName, groupGrade }
            }
        end
    end

    MySQL.transaction(queries, function(success)
        ESX.Trace((success and "Saved player ^5'%s'^7" or "Error in saving player ^5'%s'^7"):format(xPlayer.name), success and "info" or "error", true)

        if success then TriggerEvent("esx:playerSaved", xPlayer.source, xPlayer) end

        return type(cb) == "function" and cb(success)
    end)
end

---Saves all players data into database
---@param cb? function
function Core.SavePlayers(cb)
    local xPlayers <const> = ESX.Players

    if not next(xPlayers) then return end

    local startTime <const> = os.time()

    local queries, count = {}, 0
    local playerCounts = 0

    for _, xPlayer in pairs(xPlayers) do
        count += 1
        queries[count] = {
            query = "UPDATE `users` SET `accounts` = ?, `job` = ?, `job_grade` = ?, `job_duty` = ?, `group` = ?, `position` = ?, `inventory` = ?, `loadout` = ?, `metadata` = ? WHERE `identifier` = ?",
            values = {
                json.encode(xPlayer.getAccounts(true)),
                xPlayer.job.name,
                xPlayer.job.grade,
                xPlayer.job.duty,
                xPlayer.group,
                json.encode(xPlayer.getCoords()),
                json.encode(xPlayer.getInventory(true)),
                json.encode(xPlayer.getLoadout(true)),
                json.encode(xPlayer.getMetadata()),
                xPlayer.identifier
            }
        }

        count += 1
        queries[count] = {
            query = "DELETE FROM `user_groups` WHERE `identifier` = ? AND `name` <> ?",
            values = { xPlayer.identifier, xPlayer.group }
        }

        for groupName, groupGrade in pairs(xPlayer.groups) do
            if groupName ~= xPlayer.group then
                count += 1
                queries[count] = {
                    query = "INSERT INTO `user_groups` (identifier, name, grade) VALUES (?, ?, ?)",
                    values = { xPlayer.identifier, groupName, groupGrade }
                }
            end
        end

        playerCounts += 1
    end

    MySQL.transaction(queries, function(success)
        ESX.Trace((success and "Saved ^5%s^7 %s over ^5%s^7 ms" or "Failed to save ^5%s^7 %s over ^5%s^7 ms"):format(playerCounts, playerCounts > 1 and "players" or "player", ESX.Math.Round((os.time() - startTime) / 1000000, 2)),
            success and "info" or "error", true)

        return type(cb) == "function" and cb(success)
    end)
end

---@param playerId integer | number | string
---@return boolean
function Core.IsPlayerAdmin(playerId)
    if (IsPlayerAceAllowed(tostring(playerId), "command") or GetConvar("sv_lan", "") == "true") and true or false then
        return true
    end

    playerId = tonumber(playerId) --[[@as number]]

    return Config.AdminGroupsByName[ESX.Players[playerId]?.group] ~= nil
end

---@param playerId integer | number | string
---@return string
function Core.GetPlayerAdminGroup(playerId)
    playerId = tostring(playerId)
    local group = Core.DefaultGroup

    for i = 1, #Config.AdminGroups do -- start from the highest perm admin group
        local groupName = Config.AdminGroups[i]

        if IsPlayerAceAllowed(playerId, Core.Groups[groupName].principal) then
            group = groupName
            break
        end
    end

    return group
end
