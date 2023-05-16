---@alias gradeKey string starts from 0 (must be string)

---@class xGrade
---@field name string grade name
---@field label string grade label
---@field salary number grade salary
---@field skin_male table grade male skin
---@field skin_female table grade female skin

---@class xJob
---@field name string job name
---@field label string job label
---@field whitelisted boolean | 1 | 0 job whitelisted state
---@field grades table<gradeKey, xGrade>

---Adds a job object or a table of job objects on runtime
---@param jobObject xJob | xJob[]
---@return boolean
---@return string
function ESX.AddJob(jobObject)
    if type(jobObject) ~= "table" then return false, "invalid_job_object_type" end

    local jobsTable, queries = {}, {}
    local currentJobs = ESX.GetJobs()

    if jobObject.name then
        jobsTable[1] = {
            name = ((jobObject.name and type(jobObject.name) == "string") and jobObject.name) or -1,
            label = ((jobObject.label and type(jobObject.label) == "string") and jobObject.label) or -1,
            whitelisted = ((jobObject.whitelisted ~= nil and (type(jobObject.whitelisted) == "number" or type(jobObject.whitelisted) == "boolean")) and jobObject.whitelisted) or jobObject.whitelisted == nil and -1,
            grades = ((jobObject.grades and type(jobObject.grades) == "table") and jobObject.grades) or -1,
        }
    else
        for index, jobObj in pairs(jobObject) do
            jobsTable[index] = {
                name = ((jobObj.name and type(jobObj.name) == "string") and jobObj.name) or -1,
                label = ((jobObj.label and type(jobObj.label) == "string") and jobObj.label) or -1,
                whitelisted = ((jobObj.whitelisted ~= nil and (type(jobObj.whitelisted) == "number" or type(jobObj.whitelisted) == "boolean")) and jobObj.whitelisted) or jobObj.whitelisted == nil and -1,
                grades = ((jobObj.grades and type(jobObj.grades) == "table") and jobObj.grades) or -1,
            }
        end
    end

    if not #jobsTable or #jobsTable < 1 then return false, "no_job_object_received" end

    for index, jobObj in pairs(jobsTable) do
        for key, value in pairs(jobObj) do
            if value == -1 then return false, ("invalid_job_%s_parameter"):format(key) end

            if key == "name" and currentJobs[value] then
                return false, "job_already_exists"
            elseif key == "grades" then
                if type(value) ~= "table" or not next(value) then return false, "invalid_job_grades_object" end

                for gradeKey, gradeObject in pairs(value) do
                    local gradeKeyToNumber = tonumber(gradeKey)

                    if type(gradeKey) ~= "string" and (gradeKeyToNumber and type(gradeKeyToNumber) ~= "number") then return false, "invalid_job_grade_key" end

                    if type(gradeObject) ~= "table" then return false, "invalid_job_grade_object" end

                    local gradeObj = {
                        grade = gradeKeyToNumber or -1,
                        name = ((gradeObject.name and type(gradeObject.name) == "string") and gradeObject.name) or -1,
                        label = ((gradeObject.label and type(gradeObject.label) == "string") and gradeObject.label) or -1,
                        salary = ((gradeObject.salary and type(gradeObject.salary) == "number") and gradeObject.salary) or -1,
                        skin_male = ((gradeObject.skin_male and type(gradeObject.skin_male) == "table") and (next(gradeObject.skin_male) and json.encode(gradeObject.skin_male) or "{}")) or -1,
                        skin_female = ((gradeObject.skin_female and type(gradeObject.skin_female) == "table") and (next(gradeObject.skin_female) and json.encode(gradeObject.skin_female) or "{}")) or -1,
                    }

                    for key2, value2 in pairs(gradeObj) do
                        if value2 == -1 then
                            return false, ("invalid_grade_%s_%s_parameter"):format(gradeKey, key2)
                        end
                    end

                    queries[#queries + 1] = {
                        query = "INSERT INTO `job_grades` SET `job_name` = ?, `grade` = ?, `name` = ?, `label` = ?, `salary` = ?, `skin_male` = ?, `skin_female` = ?",
                        values = { jobsTable[index].name, gradeObj.grade, gradeObj.name, gradeObj.label, gradeObj.salary, gradeObj.skin_male, gradeObj.skin_female }
                    }

                    gradeKeyToNumber, gradeObj = nil, nil
                end
            end
        end

        queries[#queries + 1] = {
            query = "INSERT INTO `jobs` SET `name` = ?, `label` = ?, `whitelisted` = ?",
            values = { jobsTable[index].name, jobsTable[index].label, jobsTable[index].whitelisted }
        }
    end

    if not MySQL.transaction.await(queries) then return false, "error_in_executing_queries" end

    for index in pairs(jobsTable) do
        print(('[^2INFO^7] Job ^5"%s"^7 (%s) has been added'):format(jobsTable[index].label, jobsTable[index].name))
    end

    ---@diagnostic disable-next-line: cast-local-type
    jobObject, jobsTable, queries, currentJobs = nil, nil, nil, nil

    ESX.RefreshJobs()

    return true, "job_added_successfully"
end
