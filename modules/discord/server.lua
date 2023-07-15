---@param name? string
---@param title string
---@param color? string
---@param message any
function ESX.DiscordLog(name, title, color, message)
    local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
    local embedData = { {
        ["title"] = title,
        ["color"] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
        ["footer"] = {
            ["text"] = "| ESX Logs | " .. os.date(),
            ["icon_url"] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
        },
        ["description"] = message,
        ["author"] = {
            ["name"] = "ESX Overextended",
            ["icon_url"] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
        }
    } }

    PerformHttpRequest(webHook, nil, "POST", json.encode({ ---@diagnostic disable-line: param-type-mismatch
        username = "Logs",
        embeds = embedData
    }), {
        ["Content-Type"] = "application/json"
    })
end

---@param name? string
---@param title string
---@param color? string
---@param fields any
function ESX.DiscordLogFields(name, title, color, fields)
    local webHook = Config.DiscordLogs.Webhooks[name] or Config.DiscordLogs.Webhooks.default
    local embedData = { {
        ["title"] = title,
        ["color"] = Config.DiscordLogs.Colors[color] or Config.DiscordLogs.Colors.default,
        ["footer"] = {
            ["text"] = "| ESX Logs | " .. os.date(),
            ["icon_url"] = "https://cdn.discordapp.com/attachments/944789399852417096/1020099828266586193/blanc-800x800.png"
        },
        ["fields"] = fields,
        ["description"] = "",
        ["author"] = {
            ["name"] = "ESX Overextended",
            ["icon_url"] = "https://cdn.discordapp.com/emojis/939245183621558362.webp?size=128&quality=lossless"
        }
    } }

    PerformHttpRequest(webHook, nil, "POST", json.encode({ ---@diagnostic disable-line: param-type-mismatch
        username = "Logs",
        embeds = embedData
    }), {
        ["Content-Type"] = "application/json"
    })
end
