ESX.Paycheck = Config.EnablePaycheck

---Modifies the paycheck status dynamically on runtime. Whether paychecks should be processed or not
---@param state boolean
local function paycheckState(state)
    if ESX.Paycheck ~= state then
        ESX.SetField("Paycheck", state)
    end
end

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
function StartPayCheck()
    if isThreadActive then
        return ESX.Trace("Paycheck thread has already started, but it was called again. Nothing to worry, but it shouldn't have happenned!", "warning", true)
    end

    isThreadActive = true

    CreateThread(function()
        local minute = 60000

        while true do
            if not ESX.Paycheck then
                Wait(minute)
                goto skipLoop
            end

            Wait(Config.PaycheckInterval or minute)

            for _, xPlayer in pairs(ESX.Players) do
                local job = xPlayer.job
                local salary = job.duty and job.grade_salary or job.grade_offduty_salary

                if salary > 0 then
                    local isUnemployed = job.name == "unemployed"
                    local message      = isUnemployed and _U("received_help", salary) or _U("received_salary", salary)

                    if Config.EnableSocietyPayouts and not isUnemployed then
                        processSocietyPaycheck(xPlayer, job.name, salary)
                    else
                        processPaycheck(xPlayer, salary, message)
                    end
                end
            end

            ::skipLoop::
        end
    end)
end

exports("enablePaycheck", function()
    paycheckState(true)
end)

exports("disablePaycheck", function()
    paycheckState(false)
end)