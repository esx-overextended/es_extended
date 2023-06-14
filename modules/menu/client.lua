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
                if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
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
            if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
                ESX.UI.Menu.Opened[i].close()
                ESX.UI.Menu.Opened[i] = nil
            end
        end
    end
end

function ESX.UI.Menu.CloseAll()
    for i = #ESX.UI.Menu.Opened, 1, -1 do
        if ESX.UI.Menu.Opened[i] then
            ESX.UI.Menu.Opened[i].close()
            ESX.UI.Menu.Opened[i] = nil
        end
    end
end

function ESX.UI.Menu.GetOpened(type, namespace, name)
    for i = 1, #ESX.UI.Menu.Opened, 1 do
        if ESX.UI.Menu.Opened[i] then
            if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
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
            options[i].close = false
            if options[i].type == "slider" then
                options[i].values = {}

                if options[i].min <= 0 then
                    local rangeToOne = 1 - options[i].min
                    options[i].min += rangeToOne
                    options[i].max += rangeToOne
                    options[i].value = options[i].value and options[i].value + rangeToOne
                    options[i]._modifiedRange = rangeToOne
                elseif options[i].min > 1 then
                    local rangeToOne = options[i].min - 1
                    options[i].min = options[i].min - rangeToOne
                    options[i].max = options[i].max - rangeToOne
                    options[i].value = options[i].value and options[i].value - rangeToOne
                    options[i]._modifiedRange = rangeToOne
                end

                local value

                for k = 1, (optionData.options and #optionData.options) or (options[i].max + 1 - (options[i].min or 1)) do
                    if k == 1 and optionData.min then
                        value = optionData.min
                    end

                    options[i].values[k] = value or optionData.options?[k] or k

                    if value then value += 1 end
                end

                options[i].defaultIndex = options[i].value
            end
        end

        if not next(options) then options[1] = {label = "NO DATA", icon = "fas fa-circle-exclamation", close = false} end -- fix error for menus with no passed element options

        return options
    end

    local function closeMenu(type, namespace, name)
        if type == "default" then
            local currentMenuId = lib.getOpenMenu()

            if not currentMenuId then return end

            local foundInOpenedMenu = currentMenuId == menuData?.id

            if not foundInOpenedMenu and (namespace and name) then
                for i = #ESX.UI.Menu.Opened, 1, -1 do
                    local menu = ESX.UI.Menu.Opened[i]
                    if menu?.type == type and menu?.namespace == namespace and menu?.name == name then
                        foundInOpenedMenu = true
                        break
                    end
                end
            end

            lib.hideMenu(not foundInOpenedMenu)
        elseif type == "dialog" then
            lib.closeInputDialog()
        end

        Wait(10)
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
                if not next(data.elements) then return end -- fix error for menus with no passed element options

                local menu = ESX.UI.Menu.GetOpened("default", namespace, name)

                if not menu then return end

                data.elements[selected].value = options[selected].values?[scrollIndex] or data.elements[selected].value

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

                data.elements[selected].value = options[selected].values?[scrollIndex] or data.elements[selected].value

                menu.setElement(selected, "value", data.elements[selected].value)

                if menu.change ~= nil then
                    local changeData = { _namespace = namespace, _name = name, elements = data.elements, current = data.elements[selected] }
                    menu.change(changeData, menu)
                end
            end,
        }

        lib.registerMenu(menuData, function(selected, _, _)
            if not next(data.elements) then return end -- fix error for menus with no passed element options

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

    ESX.UI.Menu.RegisterType("dialog", function(namespace, name, data) -- open
        closeMenu("dialog") closeMenu("default")
        data.type = data.type or "default"

        local input = lib.inputDialog(data.title or "Dialog", {
            {type = data.type == "big" and "textarea" or "input", label = data.label, description = data.description, placeholder = data.placeholder, icon = data.icon, default = data.value}
        })
        local menu = ESX.UI.Menu.GetOpened("dialog", namespace, name)

        if not menu then return end

        if not input then
            if menu.cancel then
                local cancelData = { _namespace = namespace, _name = name }
                menu.cancel(cancelData, menu)
            end
        else
            local cancel = false

            -- is the submitted data a number?
            if tonumber(input[1]) then
                input[1] = ESX.Math.Round(tonumber(input[1]))

                -- check for negative value
                if tonumber(input[1]) <= 0 then
                    cancel = true
                end
            end

            data.value = ESX.Math.Trim(input[1])

            -- don't submit if the value is negative or if it's 0
            if cancel then
                ESX.ShowNotification("That input is not allowed!")
                return menu.refresh()
            else
                if menu.change then menu.change(data, menu) end
                if menu.submit then menu.submit(data, menu) end
            end
        end

        menu.close()
    end, function(namespace, name)  -- close
        closeMenu("dialog", namespace, name)
    end, true)
end