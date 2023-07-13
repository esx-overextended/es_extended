local charset, charsetCount = {}, 0

for _, range in ipairs({ { 48, 57 }, { 65, 90 }, { 97, 122 } }) do
    for i = range[1], range[2] do
        charsetCount += 1
        charset[charsetCount] = string.char(i)
    end
end

function ESX.GetRandomString(length)
    math.randomseed(GetGameTimer())

    return length > 0 and ESX.GetRandomString(length - 1) .. charset[math.random(1, charsetCount)] or ""
end
