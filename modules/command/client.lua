ESX.RegisterSafeEvent("esx:registerSuggestions", function(value)
    TriggerEvent("esx:registerSuggestions", value.registeredCommands)
end)

AddEventHandler("esx:registerSuggestions", function(registeredCommands)
    for name, command in pairs(registeredCommands) do
        if command.suggestion then
            TriggerEvent("chat:addSuggestion", ("/%s"):format(name), command.suggestion.help, command.suggestion.arguments)
        end
    end
end)
