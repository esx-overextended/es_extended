Core.Inputs = {}

function ESX.HashString(str)
    local hash = joaat(str)
    local input_map = string.format("~INPUT_%s~", string.upper(string.format("%x", hash)))
    input_map = string.gsub(input_map, "FFFFFFFF", "")

    return input_map
end

function ESX.RegisterInput(command_name, label, input_group, key, on_press, on_release)
    -- Check if the command is already registered
    if Core.Inputs[command_name] then
        print(("Command '%s' is already registered. Skipping registration."):format(command_name))
        return
    end

    -- Convert the command name for press and release
    local is_release = on_release ~= nil
    local command_key = is_release and "+" .. command_name or command_name

    -- Check if the key mapping is already registered
    for cmd, _ in pairs(Core.Inputs) do
        if Core.Inputs[cmd] == ESX.HashString(command_key) then
            print(("Key mapping for '%s' is already registered. Skipping registration."):format(command_name))
            return
        end
    end

    -- Register the command for key press
    RegisterCommand(command_key, on_press, false)
    Core.Inputs[command_name] = ESX.HashString(command_key)

    -- If on_release is provided, register the command for key release
    if is_release then
        RegisterCommand("-" .. command_name, on_release, false)
    end

    -- Map the key to the command
    RegisterKeyMapping(command_key, label, input_group, key)
end
