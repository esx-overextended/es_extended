ESX.UI.HUD = {}
ESX.UI.HUD.RegisteredElements = {}

function ESX.UI.HUD.SetDisplay(opacity)
    SendNUIMessage({
        action = "setHUDDisplay",
        opacity = opacity
    })
end

function ESX.UI.HUD.RegisterElement(name, index, priority, html, data)
    local found = false

    for i = 1, #ESX.UI.HUD.RegisteredElements, 1 do
        if ESX.UI.HUD.RegisteredElements[i] == name then
            found = true
            break
        end
    end

    if found then
        return
    end

    ESX.UI.HUD.RegisteredElements[#ESX.UI.HUD.RegisteredElements + 1] = name

    SendNUIMessage({
        action = "insertHUDElement",
        name = name,
        index = index,
        priority = priority,
        html = html,
        data = data
    })

    ESX.UI.HUD.UpdateElement(name, data)
end

function ESX.UI.HUD.RemoveElement(name)
    for i = 1, #ESX.UI.HUD.RegisteredElements, 1 do
        if ESX.UI.HUD.RegisteredElements[i] == name then
            table.remove(ESX.UI.HUD.RegisteredElements, i)
            break
        end
    end

    SendNUIMessage({
        action = "deleteHUDElement",
        name = name
    })
end

function ESX.UI.HUD.Reset()
    SendNUIMessage({
        action = "resetHUDElements"
    })
    ESX.UI.HUD.RegisteredElements = {}
end

function ESX.UI.HUD.UpdateElement(name, data)
    SendNUIMessage({
        action = "updateHUDElement",
        name = name,
        data = data
    })
end

AddEventHandler("esx:playerLoaded", function()
    if not Config.EnableHud then return end

    while not ESX.IsPlayerLoaded() do Wait(1000) end

    for i = 1, #(ESX.PlayerData.accounts) do
        local accountTpl = "<div><img src='img/accounts/" .. ESX.PlayerData.accounts[i].name .. ".png'/>&nbsp;{{money}}</div>"
        ESX.UI.HUD.RegisterElement("account_" .. ESX.PlayerData.accounts[i].name, i, 0, accountTpl, { money = ESX.Math.GroupDigits(ESX.PlayerData.accounts[i].money) })
    end

    local jobTpl = "<div>{{job_label}}{{grade_label}}</div>"

    local gradeLabel = ESX.PlayerData.job.grade_label ~= ESX.PlayerData.job.label and ESX.PlayerData.job.grade_label or ""
    if gradeLabel ~= "" then gradeLabel = " - " .. gradeLabel end

    ESX.UI.HUD.RegisterElement("job", #ESX.PlayerData.accounts, 0, jobTpl, {
        job_label = ESX.PlayerData.job.label,
        grade_label = gradeLabel
    })
end)

AddEventHandler("esx:onPlayerLogout", function()
    if not Config.EnableHud then return end

    ESX.UI.HUD.Reset()
end)

AddEventHandler("esx:setAccountMoney", function(account)
    if not Config.EnableHud then return end

    ESX.UI.HUD.UpdateElement("account_" .. account.name, {
        money = ESX.Math.GroupDigits(account.money)
    })
end)

AddEventHandler("esx:setJob", function(job)
    if not Config.EnableHud then return end

    local gradeLabel = job.grade_label ~= job.label and job.grade_label or ""
    if gradeLabel ~= "" then gradeLabel = " - " .. gradeLabel end
    ESX.UI.HUD.UpdateElement("job", {
        job_label = job.label,
        grade_label = gradeLabel
    })
end)

if Config.EnableHud then
    CreateThread(function()
        local isPauseMenuActive = false

        while true do
            if IsPauseMenuActive() and not isPauseMenuActive then
                isPauseMenuActive = true
                ESX.UI.HUD.SetDisplay(0.0)
            elseif not IsPauseMenuActive() and isPauseMenuActive then
                isPauseMenuActive = false
                ESX.UI.HUD.SetDisplay(1.0)
            end

            Wait(500)
        end
    end)

    AddEventHandler("esx:loadingScreenOff", function()
        ESX.UI.HUD.SetDisplay(1.0)
    end)
end
