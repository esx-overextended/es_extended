---Gets the specified group object data
---@param groupName string
---@return xGroup?
function ESX.GetGroup(groupName) ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["ESX.Groups"]?[groupName]
end

---Gets all of the group objects
---@return table<string, xGroup>
function ESX.GetGroups() ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["ESX.Groups"]
end

AddEventHandler("esx:setGroups", function(groups)
    ESX.SetPlayerData("groups", groups)
end)
