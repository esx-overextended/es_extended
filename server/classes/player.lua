local xPlayerMethods = lib.require("server.classes.playerMethods")

---Creates an xPlayer object
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
function CreateExtendedPlayer(playerId, playerIdentifier, playerGroups, playerGroup, playerAccounts, playerInventory, playerInventoryWeight, playerJob, playerLoadout, playerName, playerMetadata)
    ---@type xPlayer
    local self = {}

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

    for fnName, fn in pairs(Core.PlayerMethodOverrides) do
        self[fnName] = fn(self)
    end

    return self
end
