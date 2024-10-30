ESX.Paycheck = Config.EnablePaycheck

---Sends notification to the specified player
---@param xPlayer xPlayer
---@param subject? string
---@param message string
---@param iconType number
local function notifyPlayer(xPlayer, subject, message, iconType)
    xPlayer.triggerSafeEvent("esx:showAdvancedNotification", {
        sender = _U("bank"),
        subject = subject or "",
        message = message,
        textureDict = "CHAR_BANK_MAZE",
        iconType = iconType,
    })
end

---Adds paycheck to the specified player
---@param xPlayer xPlayer
---@param salary number
---@param message string
local function processPaycheck(xPlayer, salary, message)
    if xPlayer.addAccountMoney("bank", salary, message) then
        notifyPlayer(xPlayer, _U("received_paycheck"), message, 9)
    else
        ESX.Trace(("Could not add paycheck for Player ^5%s^0!"):format(xPlayer.playerId), "error", true)
    end
end

---Adds paycheck to the specified player from its organization's account balance
---@param xPlayer xPlayer
---@param jobName string
---@param salary number
local function processSocietyPaycheck(xPlayer, jobName, salary)
    TriggerEvent("esx_society:getSociety", jobName, function(society)
        if not society then
            return processPaycheck(xPlayer, salary, _U("received_salary", salary))
        end

        TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
            if account and account.money >= salary then
                account.removeMoney(salary)
                processPaycheck(xPlayer, salary, _U("received_salary", salary))
            else
                notifyPlayer(xPlayer, nil, _U("company_nomoney"), 1)
            end
        end)
    end)
end

local isThreadActive = false

---Starts the paycheck processing thread
local function startPaycheck()
    if isThreadActive then return end

    isThreadActive = true

    CreateThread(function()
        while ESX.Paycheck do
            Wait(Config.PaycheckInterval or 60000)

            if not ESX.Paycheck then break end -- safety check in case the system was toggled off while the loop is waiting for its interval

            for _, xPlayer in pairs(ESX.Players) do
                local job = xPlayer.job
                local salary = job.duty and job.grade_salary or job.grade_offduty_salary

                if salary > 0 then
                    local isUnemployed = job.name == "unemployed"

                    if Config.EnableSocietyPayouts and not isUnemployed then
                        processSocietyPaycheck(xPlayer, job.name, salary)
                    else
                        processPaycheck(xPlayer, salary, isUnemployed and _U("received_help", salary) or _U("received_salary", salary))
                    end
                end
            end
        end

        isThreadActive = false
    end)
end

---Modifies the paycheck status dynamically on runtime. Whether paychecks should be processed or not
---@param state boolean
---@return boolean (indicates whether the action was successful or not)
local function togglePaycheck(state)
    local isSuccessful = false

    if ESX.Paycheck ~= state then
        isSuccessful = ESX.SetField("Paycheck", state)

        if state and isSuccessful then startPaycheck() end
    end

    return isSuccessful
end

---Enables/Disables the built-in paycheck system
---Returns true/false whether the toggle was successful or not
exports("togglePaycheck", function(state)
    return type(state) == "boolean" and togglePaycheck(state)
end)

---Returns true/false whether the built-in paycheck system is running or not
exports("isPaycheckToggled", function() return ESX.Paycheck end)

---Starts the built-in paycheck system on resource start if Config.EnablePaycheck is set to true
do if ESX.Paycheck then startPaycheck() end end
