---@class xGroupGrade
---@field label string grade label
---@field is_boss boolean grade access to boss actions

---@class xGroup
---@field name string job name
---@field label string job label
---@field grades table<gradeKey, xGroupGrade>

ESX.Groups = {}

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

    ESX.Groups = Groups

    for key, value in pairs(Config.AdminGroups) do
        if value then
            ESX.Groups[key] = {
                name = key,
                label = key:gsub("^%l", string.upper),
                grades = { ["0"] = { group_name = key, grade = 0, label = key:gsub("^%l", string.upper) } }
            }
        end
    end

    ESX.Groups["user"] = {
        name = "user",
        label = ("user"):gsub("^%l", string.upper),
        grades = { ["0"] = { group_name = "user", grade = 0, label = ("user"):gsub("^%l", string.upper) } }
    }

    Core.RefreshPlayersGroups()
end

---Gets the specified group object data
---@param groupName string
---@return xGroup?
function ESX.GetGroup(groupName)
    return ESX.Groups[groupName]
end

---Gets all of the group objects
---@return xGroup[]
function ESX.GetGroups()
    return ESX.Groups
end

---Checks if a group with the specified name and grade exist
---@param groupName string
---@param groupGrade integer | string
---@return boolean
function ESX.DoesGroupExist(groupName, groupGrade)
    groupGrade = tostring(groupGrade)

    if groupName and groupGrade then
        if ESX.Groups[groupName] and ESX.Groups[groupName].grades[groupGrade] then
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

RegisterCommand("groups", function()
    print(ESX.DumpTable(ESX.Groups))
end, false)
