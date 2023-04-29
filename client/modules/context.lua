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
