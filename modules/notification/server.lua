do
    ESX.RegisterPlayerMethodOverrides({
        ---Shows a notification to the player.
        ---@param self xPlayer
        showNotification = function(self)
            ---@param message string | table
            ---@param type? string
            ---@param duration? number
            ---@param extra? table
            return function(message, type, duration, extra)
                self.triggerSafeEvent("esx:showNotification", {
                    message = message,
                    type = type,
                    duration = duration,
                    extra = extra
                })
            end
        end,

        ---Shows a help-type notification to the player.
        ---@param self xPlayer
        showHelpNotification = function(self)
            ---@param message string
            ---@param thisFrame boolean
            ---@param beep boolean
            ---@param duration number
            return function(message, thisFrame, beep, duration)
                self.triggerSafeEvent("esx:showHelpNotification", {
                    message = message,
                    thisFrame = thisFrame,
                    beep = beep,
                    duration = duration
                })
            end
        end,
    })
end

---@class xPlayer
---@field showNotification fun(message: string | table, type?: string, duration?: integer | number, extra)
---@field showHelpNotification fun(message: string, thisFrame: boolean, beep: boolean, duration: integer | number)
