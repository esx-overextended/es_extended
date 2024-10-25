function StartPayCheck()
    local function ProcessPayCheck(xPlayer, salary, message)
        xPlayer.addAccountMoney("bank", salary, message)
        xPlayer.triggerSafeEvent("esx:showAdvancedNotification", {
            sender = _U("bank"),
            subject = _U("received_paycheck"),
            message = message,
            textureDict = "CHAR_BANK_MAZE",
            iconType = 9,
        })
    end

    CreateThread(function()
        while true do
            local interval = Config.PaycheckInterval or 60000
            Wait(interval)

            for _, xPlayer in pairs(ESX.Players) do
                local job = xPlayer.job.name
                local salary = xPlayer.job.grade_salary
                local offduty_salary = xPlayer.job.grade_offduty_salary
                local duty = xPlayer.job.duty

                if duty and salary > 0 then
                    if not Config.EnableSocietyPayouts then
                        ProcessPayCheck(xPlayer, salary, job == "unemployed" and _U("received_help", salary) or _U("received_salary", salary))
                    else
                        TriggerEvent("esx_society:getSociety", job, function(society)
                            if society then
                                TriggerEvent("esx_addonaccount:getSharedAccount", society.account, function(account)
                                    if account.money >= salary then
                                        ProcessPayCheck(xPlayer, salary, _U("received_salary", salary))
                                        account.removeMoney(salary)
                                    else
                                        xPlayer.triggerSafeEvent("esx:showAdvancedNotification", {
                                            sender = _U("bank"),
                                            subject = "",
                                            message = _U("company_nomoney"),
                                            textureDict = "CHAR_BANK_MAZE",
                                            iconType = 1,
                                        })
                                    end
                                end)
                            else
                                ProcessPayCheck(xPlayer, salary, job == "unemployed" and _U("received_help", salary) or _U("received_salary", salary))
                            end
                        end)
                    end
                elseif not duty and offduty_salary > 0 then
                    ProcessPayCheck(xPlayer, offduty_salary, job == "unemployed" and _U("received_help", offduty_salary) or _U("received_salary", offduty_salary))
                end
            end
        end
    end)
end