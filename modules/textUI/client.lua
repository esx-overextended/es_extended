---Shows a text ui
---@param text string
---@param textType? "success" | "error" | "info"
---@param textExtra? table ox_lib's text ui related properties such as position, style, icon, and iconColor
function ESX.TextUI(text, textType, textExtra)
    if GetResourceState("esx_textui"):find("start") then
        return exports["esx_textui"]:TextUI(text, textType)
    end

    lib.showTextUI(text, {
        position = textExtra?.position or Config.DefaultTextUIPosition,
        icon = textExtra?.icon or textType == "success" and "fa-circle-check" or textType == "error" and "fa-circle-exclamation" or "fa-circle-info",
        iconColor = textExtra?.iconColor or textType == "success" and "#2ecc71" or textType == "error" and "#c0392b" or "#2980b9",
        style = textExtra?.style
    })
end

---Hides the text ui
function ESX.HideUI()
    if GetResourceState("esx_textui"):find("start") then
        return exports["esx_textui"]:HideUI()
    end

    lib.hideTextUI()
end