---Shows notification
---@param notifyText string | table<number, string> if the type of passed value is table, the first element reflects the title and the second one reflects the message
---@param notifyType? "success" | "error" | "inform" | "info"
---@param notifyDuration? number | integer
---@param notifyExtra? table ox_lib's related properties such as position, style, icon, and iconColor and title
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