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
            print(("[^3WARNING^7] Ignoring group grades for ^5'%s'^0 due to missing group"):format(data.group_name))
        end
    end

    for key, data in pairs(Groups) do
        if ESX.Table.SizeOf(data.grades) == 0 then
            Groups[key] = nil
            print(("[^3WARNING^7] Ignoring group ^5'%s'^0 due to no group grades found"):format(key))
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
        Core.Groups[group] = {
            name = group,
            label = group:gsub("^%l", string.upper),
            grades = { ["0"] = { group_name = group, grade = 0, label = group:gsub("^%l", string.upper) } }
        }
    end

    Core.Groups[Core.DefaultGroup] = {
        name = Core.DefaultGroup,
        label = Core.DefaultGroup:gsub("^%l", string.upper),
        grades = { ["0"] = { group_name = Core.DefaultGroup, grade = 0, label = Core.DefaultGroup:gsub("^%l", string.upper) } }
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

    TriggerEvent("esx:onGroupsRefreshed")
end

AddEventHandler("esx:onJobsRefreshed", function()
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