Core.Inputs = {}

function ESX.HashString(str)
    local hash = joaat(str)
    local input_map = string.format("~INPUT_%s~", string.upper(string.format("%x", hash)))
    input_map = string.gsub(input_map, "FFFFFFFF", "")

    return input_map
end

function ESX.RegisterInput(command_name, label, input_group, key, on_press, on_release)
    RegisterCommand(on_release ~= nil and "+" .. command_name or command_name, on_press, false)

    Core.Inputs[command_name] = on_release ~= nil and ESX.HashString("+" .. command_name) or ESX.HashString(command_name) -- TODO: check why is this happening (also consider swapping it to ox_lib's')

    if on_release then RegisterCommand("-" .. command_name, on_release, false) end

    RegisterKeyMapping(on_release ~= nil and "+" .. command_name or command_name, label, input_group, key)
end
