ESX.Table = {}

-- nil proof alternative to #table
function ESX.Table.SizeOf(t)
    local count = 0

    for _, _ in pairs(t) do count += 1 end

    return count
end

function ESX.Table.Set(t)
    local set = {}

    for _, v in ipairs(t) do set[v] = true end

    return set
end

function ESX.Table.IndexOf(t, value)
    for i = 1, #t, 1 do
        if t[i] == value then return i end
    end

    return -1
end

function ESX.Table.LastIndexOf(t, value)
    for i = #t, 1, -1 do
        if t[i] == value then return i end
    end

    return -1
end

function ESX.Table.Find(t, cb)
    for i = 1, #t, 1 do
        if cb(t[i]) then return t[i] end
    end

    return nil
end

function ESX.Table.FindIndex(t, cb)
    for i = 1, #t, 1 do
        if cb(t[i]) then return i end
    end

    return -1
end

function ESX.Table.Filter(t, cb)
    local newTable, newTableCount = {}, 0

    for i = 1, #t, 1 do
        if cb(t[i]) then
            newTableCount += 1
            newTable[newTableCount] = t[i]
        end
    end

    return newTable
end

function ESX.Table.Map(t, cb)
    local newTable = {}

    for i = 1, #t, 1 do
        newTable[i] = cb(t[i], i)
    end

    return newTable
end

function ESX.Table.Reverse(t)
    local newTable, newTableCount = {}, 0

    for i = #t, 1, -1 do
        newTableCount += 1
        newTable[newTableCount] = t[i]
    end

    return newTable
end

function ESX.Table.Clone(t)
    if type(t) ~= "table" then return t end

    local meta = getmetatable(t)
    local newTable = {}

    for k, v in pairs(t) do
        if type(v) == "table" then
            newTable[k] = ESX.Table.Clone(v)
        else
            newTable[k] = v
        end
    end

    setmetatable(newTable, meta)

    return newTable
end

function ESX.Table.Concat(t1, t2)
    local t3 = ESX.Table.Clone(t1)
    local t3Count = #t3

    for i = 1, #t2, 1 do
        t3Count += 1
        t3[t3Count] = t2[i]
    end

    return t3
end

function ESX.Table.Join(t, sep)
    sep = sep or ","
    local str = ""

    for i = 1, #t, 1 do
        if i > 1 then
            str = str .. sep
        end

        str = str .. t[i]
    end

    return str
end

-- Credits: https://github.com/JonasDev99/qb-garages/blob/b0335d67cb72a6b9ac60f62a87fb3946f5c2f33d/server/main.lua#L5
function ESX.Table.TableContains(tab, val)
    if type(val) == "table" then
        for _, value in pairs(tab) do
            if ESX.Table.TableContains(val, value) then return true end
        end

        return false
    else
        for _, value in pairs(tab) do
            if value == val then return true end
        end
    end

    return false
end

-- Credit: https://stackoverflow.com/a/15706820
-- Description: sort function for pairs
function ESX.Table.Sort(t, order)
    -- collect the keys
    local keys, keysCount = {}, 0

    for k, _ in pairs(t) do
        keysCount += 1
        keys[keysCount] = k
    end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a, b)
            return order(t, a, b)
        end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0

    return function()
        i += 1

        if keys[i] then return keys[i], t[keys[i]] end
    end
end

function ESX.DumpTable(table, nb)
    if nb == nil then nb = 0 end

    if type(table) == "table" then
        local s = ""

        for _ = 1, nb + 1, 1 do
            s = s .. "    "
        end

        s = "{\n"
        for k, v in pairs(table) do
            if type(k) ~= "number" then k = "'" .. k .. "'" end

            for _ = 1, nb, 1 do
                s = s .. "    "
            end

            s = s .. "[" .. k .. "] = " .. ESX.DumpTable(v, nb + 1) .. ",\n"
        end

        for _ = 1, nb, 1 do
            s = s .. "    "
        end

        return s .. "}"
    else
        return tostring(table)
    end
end
