function StartPayCheck()
    CreateThread(function()
        while true do
            Wait(Config.PaycheckInterval)

            for _, xPlayer in pairs(ESX.Players) do
                local job = xPlayer.job.grade_name
                local salary = xPlayer.job.grade_salary

                if salary > 0 then
                    if not Config.EnableSocietyPayouts then
                        xPlayer.addAccountMoney("bank", salary, job == "unemployed" and "Welfare Check" or "Paycheck")
                        xPlayer.triggerSafeEvent("esx:showAdvancedNotification", {
                            sender = _U("bank"),
                            subject = _U("received_paycheck"),
                            message = job == "unemployed" and _U("received_help", salary) or _U("received_salary", salary),
                            textureDict = "CHAR_BANK_MAZE",
                            iconType = 9,
                        })
                    else                                            -- possibly a society
                        TriggerEvent('esx_society:getSociety', xPlayer.job.name, function(society)
                            if society ~= nil then                  -- verified society
                                TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
                                    if account.money >= salary then -- does the society have money to pay its employees?
                                        xPlayer.addAccountMoney("bank", salary, "Paycheck")
                                        account.removeMoney(salary)

                                        xPlayer.triggerSafeEvent("esx:showAdvancedNotification", {
                                            sender = _U("bank"),
                                            subject = _U("received_paycheck"),
                                            message = _U("received_salary", salary),
                                            textureDict = "CHAR_BANK_MAZE",
                                            iconType = 9,
                                        })
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
                            else -- not a society
                                xPlayer.addAccountMoney("bank", salary, job == "unemployed" and "Welfare Check" or "Paycheck")
                                xPlayer.triggerSafeEvent("esx:showAdvancedNotification", {
                                    sender = _U("bank"),
                                    subject = _U("received_paycheck"),
                                    message = job == "unemployed" and _U("received_help", salary) or _U("received_salary", salary),
                                    textureDict = "CHAR_BANK_MAZE",
                                    iconType = 9,
                                })
                            end
                        end)
                    end
                end
            end
        end
    end)
end
