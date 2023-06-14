---Gets the specified group object data
---@param groupName string
---@return xGroup?
function ESX.GetGroup(groupName) ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["Groups"]?[groupName]
end

---Gets all of the group objects
---@return table<string, xGroup>
function ESX.GetGroups() ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["Groups"]
end

ESX.RegisterSafeEvent("esx:setGroups", function(value)
    TriggerEvent("esx:setGroups", value.currentGroups, value.lastGroups)
end)

ESX.RegisterSafeEvent("esx:addGroup", function(value)
    TriggerEvent("esx:addGroup", value.groupName, value.groupGrade)
end)

ESX.RegisterSafeEvent("esx:removeGroup", function(value)
    TriggerEvent("esx:removeGroup", value.groupName, value.groupGrade)
end)

AddEventHandler("esx:setGroups", function(groups)
    ESX.SetPlayerData("groups", groups)
end)
