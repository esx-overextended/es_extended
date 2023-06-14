---Gets the specified job object data
---@param jobName string
---@return xJob?
function ESX.GetJob(jobName) ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["Jobs"]?[jobName]
end

---Gets all of the job objects
---@return table<string, xJob>
function ESX.GetJobs() ---@diagnostic disable-line: duplicate-set-field
    return GlobalState["Jobs"]
end

ESX.RegisterSafeEvent("esx:setJob", function(value)
    TriggerEvent("esx:setJob", value.currentJob, value.lastJob)
end)

ESX.RegisterSafeEvent("esx:setDuty", function(value)
    TriggerEvent("esx:setDuty", value.duty)
end)

AddEventHandler("esx:setJob", function(job)
    ESX.SetPlayerData("job", job)
end)
