function ESX.GetRandomNumber(length)
    if type(length) ~= "number" or length <= 0 then return end

    local minRange = 10 ^ (length - 1)
    local maxRange = (10 ^ length) - 1

    return math.random(minRange, maxRange)
end
