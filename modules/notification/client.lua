---Shows a notification
---@param notifyText string | table<number, string> if the type of passed value is table, the first element reflects the title and the second one reflects the message
---@param notifyType? "success" | "error" | "inform" | "info"
---@param notifyDuration? number | integer
---@param notifyExtra? table ox_lib's notify related properties such as position, style, icon, and iconColor and title
function ESX.ShowNotification(notifyText, notifyType, notifyDuration, notifyExtra)
    if GetResourceState("esx_notify"):find("start") then
        return exports["esx_notify"]:Notify(notifyType == "inform" and "info", notifyDuration, type(notifyText) == "table" and notifyText[2] or notifyText)
    end

    lib.notify({
        title = type(notifyText) == "table" and notifyText[1] or notifyExtra?.title,
        description = type(notifyText) == "table" and notifyText[2] or notifyText,
        duration = notifyDuration or 3000,
        position = notifyExtra?.position or Config.DefaultNotificationPosition,
        type = notifyType == "info" and "inform" or notifyType,
        style = notifyExtra?.style,
        icon = notifyExtra?.icon,
        iconColor = notifyExtra?.iconColor
    })
end

---Shows an advanced GTA-based type notification
---@param sender string
---@param subject string
---@param msg string
---@param textureDict string
---@param iconType number
---@param flash? boolean
---@param saveToBrief? boolean
---@param hudColorIndex? number
function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if saveToBrief == nil then saveToBrief = true end

    AddTextEntry("esxAdvancedNotification", msg)
    BeginTextCommandThefeedPost("esxAdvancedNotification")

    if hudColorIndex then ThefeedSetNextPostBackgroundColor(hudColorIndex) end

    EndTextCommandThefeedPostMessagetext(textureDict, textureDict, false, iconType, sender, subject)
    EndTextCommandThefeedPostTicker(flash or false, saveToBrief)
end

---Shows a GTA-based type help notification
---@param msg string
---@param thisFrame? boolean
---@param beep? boolean
---@param duration? number
function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    AddTextEntry("esxHelpNotification", msg)

    if thisFrame then
        DisplayHelpTextThisFrame("esxHelpNotification", false)
    else
        if beep == nil then beep = true end

        BeginTextCommandDisplayHelp("esxHelpNotification")
        EndTextCommandDisplayHelp(0, false, beep, duration or -1)
    end
end

---Shows a GTA-based type floating help notification
---@param msg string
---@param coords vector3
function ESX.ShowFloatingHelpNotification(msg, coords)
    AddTextEntry("esxFloatingHelpNotification", msg)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp("esxFloatingHelpNotification")
    EndTextCommandDisplayHelp(2, false, false, -1)
end

AddEventHandler("esx:showNotification", ESX.ShowNotification)
AddEventHandler("esx:showHelpNotification", ESX.ShowHelpNotification)
AddEventHandler("esx:showAdvancedNotification", ESX.ShowAdvancedNotification)