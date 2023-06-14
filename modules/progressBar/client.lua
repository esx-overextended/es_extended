---Shows a progress bar
---@param progressText string
---@param progressDuration number | integer
---@param progressOptions table properties such as onFinish(), onCancel(), and ox_lib's progress bar properties such as position, canCancel, anim, prop, and etc...
function ESX.Progressbar(progressText, progressDuration, progressOptions)
    if GetResourceState("esx_progressbar"):find("start") then
        return exports["esx_progressbar"]:Progressbar(progressText, progressDuration, progressOptions)
    end

    local progressType = progressOptions?.type or Config.DefaultProgressBarType
    local animation = progressOptions?.anim or progressOptions?.animation

    if lib[progressType == "bar" and "progressBar" or progressType == "circle" and "progressCircle"]({
        label = progressText,
        duration = progressDuration,
        position = progressOptions?.position or Config.DefaultProgressBarPosition,
        useWhileDead = progressOptions?.useWhileDead or false,
        allowRagdoll = progressOptions?.allowRagdoll or false,
        allowCuffed = progressOptions?.allowCuffed or false,
        allowFalling = progressOptions?.allowFalling or false,
        canCancel = progressOptions?.canCancel or (progressOptions?.onCancel ~= nil and true),
        anim = {
            dict = animation?.dict,
            clip = animation?.clip or animation?.lib,
            flag = animation?.flag,
            blendIn = animation?.blendIn,
            blendOut = animation?.blendOut,
            duration = animation?.duration,
            playbackRate = animation?.playbackRate,
            lockX = animation?.lockX,
            lockY = animation?.lockY,
            lockZ = animation?.lockZ,
            scenario = animation?.scenario or animation?.Scenario,
            playEnter = animation?.playEnter,
        },
        prop = progressOptions?.prop,
        disable = progressOptions?.disable or {
            move = progressOptions?.FreezePlayer,
            car = progressOptions?.FreezePlayer,
            combat = progressOptions?.FreezePlayer,
            mouse = false
        }
    }) then
        return progressOptions?.onFinish and progressOptions.onFinish() or true
    else
        return progressOptions?.onCancel and progressOptions.onCancel() or false
    end
end