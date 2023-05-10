ESX.UI.HUD = {}
ESX.UI.HUD.RegisteredElements = {}

function ESX.UI.HUD.SetDisplay(opacity)
    SendNUIMessage({
        action = 'setHUDDisplay',
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
        action = 'insertHUDElement',
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
        action = 'deleteHUDElement',
        name = name
    })
end

function ESX.UI.HUD.Reset()
    SendNUIMessage({
        action = 'resetHUDElements'
    })
    ESX.UI.HUD.RegisteredElements = {}
end

function ESX.UI.HUD.UpdateElement(name, data)
    SendNUIMessage({
        action = 'updateHUDElement',
        name = name,
        data = data
    })
end
