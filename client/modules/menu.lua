ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

function ESX.UI.Menu.RegisterType(type, open, close, ox_lib)
    ESX.UI.Menu.RegisteredTypes[type] = {
        open = open,
        close = close,
        ox_lib = ox_lib
    }
end

function ESX.UI.Menu.Open(type, namespace, name, data, submit, cancel, change, close)
    local menu = {}

    menu.type = type
    menu.namespace = namespace
    menu.name = name
    menu.data = data
    menu.submit = submit
    menu.cancel = cancel
    menu.change = change
    menu.lastIndex = 1

    menu.close = function()
        ESX.UI.Menu.RegisteredTypes[type].close(namespace, name)

        for i = 1, #ESX.UI.Menu.Opened, 1 do
            if ESX.UI.Menu.Opened[i] then
                if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and
                    ESX.UI.Menu.Opened[i].name == name then
                    ESX.UI.Menu.Opened[i] = nil
                end
            end
        end

        if close then
            close()
        end

        if ESX.UI.Menu.RegisteredTypes[type].ox_lib then
            local lastMenuIndex = #ESX.UI.Menu.Opened
            local lastMenu = ESX.UI.Menu.Opened[lastMenuIndex]

            if lastMenu then
                lastMenu.refresh()
            end
        end
    end

    menu.update = function(query, newData)
        for i = 1, #menu.data.elements, 1 do
            local match = true

            for k, v in pairs(query) do
                if menu.data.elements[i][k] ~= v then
                    match = false
                end
            end

            if match then
                for k, v in pairs(newData) do
                    menu.data.elements[i][k] = v
                end
            end
        end
    end

    menu.refresh = function()
        ESX.UI.Menu.RegisteredTypes[type].open(namespace, name, menu.data, menu.lastIndex)
    end

    menu.setElement = function(i, key, val)
        menu.data.elements[i][key] = val
    end

    menu.setElements = function(newElements)
        menu.data.elements = newElements
    end

    menu.setTitle = function(val)
        menu.data.title = val
    end

    menu.removeElement = function(query)
        for i = 1, #menu.data.elements, 1 do
            for k, v in pairs(query) do
                if menu.data.elements[i] then
                    if menu.data.elements[i][k] == v then
                        table.remove(menu.data.elements, i)
                        break
                    end
                end
            end
        end
    end

    menu.setIndex = function(index)
        menu.lastIndex = index
    end

    ESX.UI.Menu.Opened[#ESX.UI.Menu.Opened + 1] = menu
    ESX.UI.Menu.RegisteredTypes[type].open(namespace, name, data, menu.lastIndex)

    return menu
end

function ESX.UI.Menu.Close(type, namespace, name)
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and
                ESX.UI.Menu.Opened[i].name == name then
                ESX.UI.Menu.Opened[i].close()
                ESX.UI.Menu.Opened[i] = nil
            end
        end
    end
end

function ESX.UI.Menu.CloseAll()
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            ESX.UI.Menu.Opened[i].close()
            ESX.UI.Menu.Opened[i] = nil
        end
    end
end

function ESX.UI.Menu.GetOpened(type, namespace, name)
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and
                ESX.UI.Menu.Opened[i].name == name then
                return ESX.UI.Menu.Opened[i]
            end
        end
    end
end

function ESX.UI.Menu.GetOpenedMenus()
    return ESX.UI.Menu.Opened
end

function ESX.UI.Menu.IsOpen(type, namespace, name)
    return ESX.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

do -- use ox_lib for default menu
    local menuData

    local function generateDefaultMenuOptions(namespace, name, elements)
        local options = {}

        for i = 1, #elements do
            local optionData = elements[i]
            options[i] = lib.table.deepclone(optionData)
            options[i]._namespace = namespace
            options[i]._name = name
            options[i].label = optionData.title or optionData.label
            options[i].type = options[i].type or "default"
            options[i].selected = optionData.selected or false
            options[i].close = optionData.close or false
            if options[i].type == "slider" then
                options[i].values = {}
                for k = optionData.min or 1, optionData.options and #optionData.options or options[i].max do
                    options[i].values[k] = optionData.options?[k] or k
                end
                options[i].defaultIndex = options[i].value
            end
        end

        return options
    end

    local function closeMenu(type, namespace, name)
        local currentMenuId = lib.getOpenMenu()

        if not currentMenuId then return end

        local foundInOpenedMenu = currentMenuId == menuData?.id

        if not foundInOpenedMenu and (namespace and name) then
            local openedMenusCount = #ESX.UI.Menu.Opened
            for i = openedMenusCount, openedMenusCount, -1 do
                local menu = ESX.UI.Menu.Opened[i]
                if menu.type == type and menu.namespace == namespace and menu.name == name then
                    foundInOpenedMenu = true
                    break
                end
            end
        end

        lib.hideMenu(not foundInOpenedMenu) Wait(10)
    end

    ESX.UI.Menu.RegisterType("default", function(namespace, name, data, indexToOpen) -- open
        closeMenu("default")

        local options = generateDefaultMenuOptions(namespace, name, data.elements)
        menuData = {
            id = "esx:defaultMenu",
            title = data.title,
            options = options,
            position = data.align,
            disableInput = data.disableInput,
            canClose = data.canClose,
            onClose = function(_)
                local menu = ESX.UI.Menu.GetOpened("default", namespace, name)

                if not menu then return end

                if menu.cancel ~= nil then
                    local cancelData = { _namespace = namespace, _name = name }
                    return menu.cancel(cancelData, menu)
                end

                menu.close()
            end,
            onSelected = function(selected, scrollIndex, _)
                local menu = ESX.UI.Menu.GetOpened("default", namespace, name)

                if not menu then return end

                data.elements[selected].value = (not data.elements[selected].min and scrollIndex and scrollIndex - 1) or scrollIndex or data.elements[selected].value

                for i = 1, #data.elements, 1 do
                    menu.setElement(i, "value", data.elements[i].value)
                    menu.setElement(i, "selected", i == selected)
                end

                menu.setIndex(selected)

                if menu.change ~= nil then
                    local changeData = { _namespace = namespace, _name = name, elements = data.elements, current = data.elements[selected] }
                    menu.change(changeData, menu)
                end
            end,
            onSideScroll = function(selected, scrollIndex, _)
                local menu = ESX.UI.Menu.GetOpened("default", namespace, name)

                if not menu then return end

                data.elements[selected].value = (not data.elements[selected].min and scrollIndex and scrollIndex - 1) or scrollIndex or data.elements[selected].value

                menu.setElement(selected, "value", data.elements[selected].value)

                if menu.change ~= nil then
                    local changeData = { _namespace = namespace, _name = name, elements = data.elements, current = data.elements[selected] }
                    menu.change(changeData, menu)
                end
            end,
        }

        lib.registerMenu(menuData, function(selected, _, _)
            local menu = ESX.UI.Menu.GetOpened("default", namespace, name)

            if menu.submit ~= nil then
                local submitData = { _namespace = namespace, _name = name, elements = data.elements, current = data.elements[selected] }
                menu.submit(submitData, menu)
            end
        end)

        lib.showMenu(menuData.id, indexToOpen)
    end, function(namespace, name)  -- close
        closeMenu("default", namespace, name)
    end, true)
end