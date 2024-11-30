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

---@param groupToCheck string | string[] | table<string, number>
---@return boolean
function ESX.CanInteractWithGroup(groupToCheck)
    if not groupToCheck then return false end

    local groupToCheckType = type(groupToCheck)

    if groupToCheckType == "string" then
        groupToCheck = { groupToCheck }
        groupToCheckType = "table"
    end

    local playerGroups = ESX.PlayerData.groups
    local currJobName  = ESX.PlayerData.job.name
    local currJobDuty  = ESX.PlayerData.job.duty
    local currJobGrade = ESX.PlayerData.job.grade

    if groupToCheckType == "table" then
        if table.type(groupToCheck) == "array" then
            for i = 1, #groupToCheck do
                local groupName = groupToCheck[i]

                if currJobName == groupName and currJobDuty --[[making sure the duty is on if the job matches]] then return true end

                if playerGroups[groupName] and not ESX.GetJob(groupName) --[[making sure the group is not a job]] then return true end
            end
        else
            for groupName, groupGrade in pairs(groupToCheck --[[@as table<string, number>]]) do
                if currJobName == groupName and currJobGrade >= groupGrade and currJobDuty --[[making sure the duty is on if the job matches]] then return true end

                if playerGroups[groupName] and playerGroups[groupName] >= groupGrade and not ESX.GetJob(groupName) --[[making sure the group is not a job]] then return true end
            end
        end
    end

    return false
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
