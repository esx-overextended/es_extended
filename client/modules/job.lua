---Gets the specified job object data
---@param jobName string
---@return xJob?
function ESX.GetJob(jobName) ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["ESX.Jobs"]?[jobName]
end

---Gets all of the job objects
---@return table<string, xJob>
function ESX.GetJobs() ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["ESX.Jobs"]
end

AddEventHandler("esx:setJob", function(job)
    ESX.SetPlayerData("job", job)
end)

AddEventHandler("esx:setDuty", function(duty)
    ESX.SetPlayerData("duty", duty)
end)
