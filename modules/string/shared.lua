local charset, charsetCount = {}, 0

for _, range in ipairs({ { 48, 57 }, { 65, 90 }, { 97, 122 } }) do
    for i = range[1], range[2] do
        charsetCount += 1
        charset[charsetCount] = string.char(i)
    end
end

function ESX.GetRandomString(length, stringPattern)
    if type(length) ~= "number" or length <= 0 then return "" end

    if type(stringPattern) == "string" then
        stringPattern = string.upper(stringPattern)
        local tableOfChars = table.create(length, 0)

        for i = 1, length do
            local character
            local shouldSkipLoop = false
            local validCharactersCount = 0

            for characterIndex = 1, #stringPattern do
                if shouldSkipLoop then
                    shouldSkipLoop = false
                    goto skipLoop
                end

                local _character
                local patternCharacter = stringPattern:sub(characterIndex, characterIndex)

                if patternCharacter == "1" then
                    _character = ESX.GetRandomNumber(1)
                elseif patternCharacter == "A" then
                    _character = ESX.GetRandomString(1)
                elseif patternCharacter == "." then
                    _character = math.random(0, 1) == 1 and ESX.GetRandomString(1) or ESX.GetRandomNumber(1)
                elseif patternCharacter == "^" then
                    characterIndex += 1
                    _character = stringPattern:sub(characterIndex, characterIndex)
                    shouldSkipLoop = true
                else
                    _character = patternCharacter
                end

                validCharactersCount += 1

                if validCharactersCount == i then
                    character = _character
                    break
                end

                ::skipLoop::
            end

            if not character or character == "" then
                character = ESX.GetRandomString(1)
            end

            tableOfChars[i] = character
        end

        return table.concat(tableOfChars)
    end

    return ESX.GetRandomString(length - 1) .. charset[math.random(1, charsetCount)]
end
