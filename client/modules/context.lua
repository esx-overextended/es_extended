local useEsxContext = false

if useEsxContext then
    ---@param position? string left | center | right
    ---@param elements table
    ---@param onSelect? function
    ---@param onClose? function
    ---@param canClose? boolean defaults to true
    function ESX.OpenContext(position, elements, onSelect, onClose, canClose)
        if not GetResourceState("esx_context"):find("start") then
            return print("[^1ERROR^7] Tried to ^5open^7 context menu, but ^5esx_context^7 is not started!")
        end

        exports["esx_context"]:Open(position, elements, onSelect, onClose, canClose)
    end

    ---@param position string left | center | right
    ---@param elements table
    ---@param onSelect? function
    ---@param onClose? function
    ---@param canClose? boolean defaults to true
    function ESX.PreviewContext(position, elements, onSelect, onClose, canClose)
        if not GetResourceState("esx_context"):find("start") then
            return print("[^1ERROR^7] Tried to ^5preview^7 context menu, but ^5esx_context^7 is not started!")
        end

        exports["esx_context"]:Preview(position, elements, onSelect, onClose, canClose)
    end

    function ESX.CloseContext(_)
        if not GetResourceState("esx_context"):find("start") then
            return print("[^1ERROR^7] Tried to ^5close^7 context menu, but ^5esx_context^7 is not started!")
        end

        exports["esx_context"]:Close()
    end

    ---@param position? string left | center | right
    ---@param elements? table
    function ESX.RefreshContext(elements, position)
        if not GetResourceState("esx_context"):find("start") then
            return print("[^1ERROR^7] Tried to ^5Refresh^7 context menu, but ^5esx_context^7 is not started!")
        end

        exports["esx_context"]:Refresh(elements, position)
    end

    return
end

local contextData

---converts esx_context elements to ox_lib options type
---@param elements table
---@param onSelect? function
local function generateOptions(elements, onSelect)
    local options = {}

    local isFirstElementUnselectable = elements[1]?.unselectable == true

    for index = isFirstElementUnselectable and 2 or 1, #elements do
        local optionData = elements[index]
        local i = isFirstElementUnselectable and index-1 or index
        options[i] = lib.table.deepclone(optionData)
        options[i].title = optionData.title
        options[i].description = optionData.name and (("%s%s"):format(optionData.name, (optionData.inputValue and ": " .. optionData.inputValue) or "")) or (optionData.inputValue and tostring(optionData.inputValue)--[[sometime it works with number and sometimes doesnt!]])
        options[i].metadata = optionData.description and {
            {label = "description", value = optionData.description}
        }
        options[i].icon = optionData.icon
        options[i].disabled = optionData.disabled or optionData.unselectable
        options[i].onSelect = function()
            if not optionData.input then
                ESX.OpenContext(nil, elements, contextData.onSelect, contextData.onClose, contextData.canClose)
                return onSelect ~= nil and onSelect(contextData, optionData)
            end

            local inputDialogData = {}
            if optionData.inputType == "number" then
                inputDialogData[1] = {
                    type = "number",
                    label = optionData.name or optionData.title,
                    description = ("%s %s"):format(optionData.description or "", (optionData.inputMin and optionData.inputMax) and ("\nMin: %s - Max: %s"):format(optionData.inputMin, optionData.inputMax) or ""), -- no markdown support for description =[
                    placeholder = optionData.inputPlaceholder,
                    icon = optionData.icon,
                    required = true,
                    default = tonumber(optionData.inputValue),
                    min = tonumber(optionData.inputMin),
                    max = tonumber(optionData.inputMax),
                }
            elseif optionData.inputType == "text" then
                inputDialogData[1] = {
                    type = "textarea",
                    label = optionData.name or optionData.title,
                    description = optionData.description,
                    placeholder = optionData.inputPlaceholder,
                    icon = optionData.icon,
                    required = true,
                    default = optionData.inputValue,
                    autosize = true
                }
            elseif optionData.inputType == "radio" then
                local radioOptions, defaultValue = {}, nil
                for _i = 1, #optionData.inputValues do
                    local radioOptionData = optionData.inputValues[_i]
                    defaultValue = defaultValue or (radioOptionData.value == optionData.inputValue or radioOptionData.value == optionData.inputPlaceholder or radioOptionData.value == -1) and radioOptionData.value
                    radioOptions[_i] = {label = radioOptionData.text, value = radioOptionData.value}
                end

                inputDialogData[1] = {
                    type = "select",
                    label = optionData.name or optionData.title,
                    options = radioOptions,
                    description = optionData.description,
                    placeholder = optionData.inputPlaceholder,
                    icon = optionData.icon,
                    required = true,
                    default = defaultValue,
                    clearable = true
                }
            end

            local input = lib.inputDialog(optionData.title, inputDialogData, {allowCancel = true})

            elements[index].inputValue = input?[1] or elements[index].inputValue

            ESX.OpenContext(nil, elements, contextData.onSelect, contextData.onClose, contextData.canClose)
        end
    end

    return options
end

---@param elements table
---@param onSelect? function
---@param onClose? function
---@param canClose? boolean defaults to true
function ESX.OpenContext(_, elements, onSelect, onClose, canClose)
    local options = generateOptions(elements, onSelect)
    contextData = {
        id = "esx:contextMenu",
        title = elements[1]?.unselectable and elements[1]?.title or "Menu",
        options = options,
        eles = elements,          -- populate the table for backward-compatibility with esx_context
        onSelect = onSelect,      -- populate the table for backward-compatibility with esx_context
        onClose = onClose,        -- populate the table for backward-compatibility with esx_context
        close = ESX.CloseContext, -- populate the table for backward-compatibility with esx_context
        canClose = canClose == nil and true or canClose,
        onExit = function()
            contextData = nil
            return onClose ~= nil and onClose()
        end,
    }

    lib.registerContext(contextData)
    lib.showContext(contextData.id)
end

function ESX.PreviewContext(_, _, _, _, _)
    print("[^1ERROR^7] Tried to ^5preview^7 context menu, but ^5ox_lib does not offer such functionality^7 at the moment!")
end

---@param onExit? boolean defaults to true
function ESX.CloseContext(onExit)
    lib.hideContext(onExit == nil and true or onExit)
end

---@param elements? table
function ESX.RefreshContext(elements, _)
    local currentContextId = lib.getOpenContextMenu()

    if not currentContextId then return end
    if currentContextId ~= contextData?.id then -- strict check whether the current context is opened through ESX.OpenContext or not
        return print("[^1ERROR^7] Tried to ^5refresh^7 a context menu that hasn't been opened through ^2ESX.OpenContext^7.")
    end

    local _contextData = contextData -- save the current context menu data since it will be nil once ESX.CloseContext is called

    ESX.CloseContext() Wait(10)
    ESX.OpenContext(nil, elements or _contextData.eles, _contextData.onSelect, _contextData.onClose, _contextData.canClose)
end