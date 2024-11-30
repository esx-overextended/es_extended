---@class xGroupGrade
---@field label string grade label
---@field is_boss boolean grade access to boss actions

---@class xGroup
---@field name string job name
---@field label string job label
---@field principal string
---@field grades table<gradeKey, xGroupGrade>

Core.Groups = {} --[[@type table<string, xGroup>]]
Config.AdminGroupsByName = {} --[[@type table<string, integer | number>]]
Core.DefaultGroup = "user"

for i = 1, #Config.AdminGroups do
    Config.AdminGroupsByName[Config.AdminGroups[i]] = i
end

---Refreshes/loads the group table from database
function ESX.RefreshGroups()
    local Groups = {}
    local groups = MySQL.query.await("SELECT * FROM groups")

    for _, v in ipairs(groups) do
        Groups[v.name] = v
        Groups[v.name].grades = {}
    end

    local groupGrades = MySQL.query.await("SELECT * FROM group_grades")

    for _, data in ipairs(groupGrades) do
        if Groups[data.group_name] then
            Groups[data.group_name].grades[tostring(data.grade)] = data
        else
            ESX.Trace(("Ignoring group grades for ^5'%s'^0 due to missing group"):format(data.group_name), "warning", true)
        end
    end

    for key, data in pairs(Groups) do
        if ESX.Table.SizeOf(data.grades) == 0 then
            Groups[key] = nil
            ESX.Trace(("[^3WARNING^7] Ignoring group ^5'%s'^0 due to no group grades found"):format(key), "warning", true)
        end
    end

    for _, xGroup in pairs(Core.Groups) do -- removes the old groups ace permissions...
        -- TODO: might need to check for group.admin and user
        local grades = {}
        local parent = xGroup.principal

        lib.removeAce(parent, parent)

        for i in pairs(xGroup.grades) do
            grades[#grades + 1] = tonumber(i)
        end

        table.sort(grades, function(a, b)
            return a < b
        end)

        for i = 1, #grades do
            local child = ("%s:%s"):format(xGroup.principal, grades[i])

            lib.removeAce(child, child)
            lib.removePrincipal(child, parent)

            parent = child
        end
    end

    Core.Groups = lib.table.merge(Groups, ESX.Jobs)

    for i = 1, #Config.AdminGroups do
        local group = Config.AdminGroups[i]
        Core.Groups[group] = { ---@diagnostic disable-line: missing-fields
            name = group,
            label = group:gsub("^%l", string.upper),
            grades = { ["0"] = { group_name = group, grade = 0, label = group:gsub("^%l", string.upper) } } ---@diagnostic disable-line: missing-fields
        }
    end

    Core.Groups[Core.DefaultGroup] = { ---@diagnostic disable-line: missing-fields
        name = Core.DefaultGroup,
        label = Core.DefaultGroup:gsub("^%l", string.upper),
        grades = { ["0"] = { group_name = Core.DefaultGroup, grade = 0, label = Core.DefaultGroup:gsub("^%l", string.upper) } } ---@diagnostic disable-line: missing-fields
    }

    for key, xGroup in pairs(Core.Groups) do
        -- TODO: might need to check for group.admin and user
        local grades = {}
        local principal = ("group.%s"):format(xGroup.name)
        local parent = principal

        if not IsPrincipalAceAllowed(principal, principal) then
            lib.addAce(principal, principal)
        end

        for i in pairs(xGroup.grades) do
            grades[#grades + 1] = tonumber(i)
        end

        table.sort(grades, function(a, b)
            return a < b
        end)

        for i = 1, #grades do
            local child = ("%s:%s"):format(principal, grades[i])

            if not IsPrincipalAceAllowed(child, child) then
                lib.addAce(child, child)
                lib.addPrincipal(child, parent)
            end

            parent = child
        end

        Core.Groups[key].principal = principal
    end

    local adminGroupsCount = #Config.AdminGroups

    for i = 1, #Config.AdminGroups do
        local child = Config.AdminGroups[i]
        local parent = Config.AdminGroups[i + 1] or Core.DefaultGroup

        lib.removePrincipal(Core.Groups[child].principal, Core.Groups[parent].principal) -- prevents duplication
        lib.addPrincipal(Core.Groups[child].principal, Core.Groups[parent].principal)
    end

    if adminGroupsCount > 0 then
        lib.removeAce(Core.Groups[Config.AdminGroups[adminGroupsCount]].principal, "command") -- prevents duplication
        lib.addAce(Core.Groups[Config.AdminGroups[adminGroupsCount]].principal, "command")
        lib.addAce(Core.Groups[Config.AdminGroups[adminGroupsCount]].principal, "command.quit", false)
    end

    GlobalState:set("Groups", Core.Groups, true)

    Core.RefreshPlayersGroups()

    TriggerEvent("esx:groupsObjectRefreshed")
end

AddEventHandler("esx:jobsObjectRefreshed", function()
    ESX.RefreshGroups()
end)

---Gets the specified group object data
---@param groupName string
---@return xGroup?
function ESX.GetGroup(groupName) ---@diagnostic disable-line: duplicate-set-field
    return Core.Groups[groupName]
end

---Gets all of the group objects
---@return table<string, xGroup>
function ESX.GetGroups() ---@diagnostic disable-line: duplicate-set-field
    return Core.Groups
end

---Checks if a group with the specified name and grade exist
---@param groupName string
---@param groupGrade integer | string
---@return boolean
function ESX.DoesGroupExist(groupName, groupGrade)
    groupGrade = tostring(groupGrade)

    if groupName and groupGrade then
        if Core.Groups[groupName] and Core.Groups[groupName].grades[groupGrade] then
            return true
        end
    end

    return false
end

function Core.RefreshPlayersGroups()
    for _, xPlayer in pairs(ESX.Players) do
        for groupName, groupGrade in pairs(xPlayer.groups) do
            local doesGroupExist = ESX.DoesGroupExist(groupName, groupGrade)
            xPlayer[doesGroupExist and "addGroup" or "removeGroup"](groupName, groupGrade)
        end
    end
end

---Gets all players with the specified group
---@param groupName string group name
---@param groupGrade? number | integer if it's provided and not nil, it will only return players with the specified group grade
---@return xPlayer[], integer
function ESX.GetPlayersByGroup(groupName, groupGrade)
    local xPlayers = {}
    local count = 0

    if type(groupName) == "string" and (type(groupGrade) == "nil" or type(groupGrade) == "number") then
        for _, xPlayer in pairs(ESX.Players) do
            if xPlayer.groups[groupName] and (groupGrade == nil or xPlayer.groups[groupName] == groupGrade) then
                count += 1
                xPlayers[count] = xPlayer
            end
        end
    end

    return xPlayers, count
end

do
    ESX.RegisterPlayerMethodOverrides({
        ---Checks if the player has the specified job(s) and is onDuty or has the specified group(s)
        ---@param self xPlayer
        canInteractWithGroup = function(self)
            ---@param groupToCheck string | string[] | table<string, number>
            ---@return boolean
            return function(groupToCheck)
                if not groupToCheck then return false end

                local groupToCheckType = type(groupToCheck)

                if groupToCheckType == "string" then
                    groupToCheck = { groupToCheck }
                    groupToCheckType = "table"
                end

                local playerGroups = self.groups
                local currJobName  = self.job.name
                local currJobDuty  = self.job.duty
                local currJobGrade = self.job.grade

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
        end,
    })
end

---@class xPlayer
---@field canInteractWithGroup fun(groupToCheck: string | string[] | table<string, number>):boolean

ESX.RegisterSafeEvent("esx:setGroups", function(value)
    TriggerEvent("esx:setGroups", value.source, value.currentGroups, value.lastGroups)
end)

ESX.RegisterSafeEvent("esx:addGroup", function(value)
    TriggerEvent("esx:addGroup", value.source, value.groupName, value.groupGrade)
end)

ESX.RegisterSafeEvent("esx:removeGroup", function(value)
    TriggerEvent("esx:removeGroup", value.source, value.groupName, value.groupGrade)
end)
