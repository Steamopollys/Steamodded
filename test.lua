-- Hint: run "watch lua Mods/Steamodded/test.lua" using DebugPlus dev branch
-- Make sure to copy over your changes to core/utils
V_MT.__call = function(_, str)
    str = str or '0.0.0'
    local _, _, major, minorFull, minor, patchFull, patch, rev = string.find(str, '^(%d+)(%.?(%d*))(%.?(%d*))(.*)$')
    if (minorFull ~= "" and minor == "") or (patchFull ~= "" and patch == "") then
        error('Trailing dot found in version "' .. str .. '".')
    end
    local t = {
        major = tonumber(major),
        minor = tonumber(minor) or 0,
        patch = tonumber(patch) or 0,
        rev = rev or '',
        beta = rev and rev:sub(1, 1) == '~' and -1 or 0
    }
    return setmetatable(t, V_MT)
end

local function doTheStuff(v)
    local _, r = pcall(V, v)
    print(v, require('debugplus-util').stringifyTable(r)) -- Technically unstable api
end

doTheStuff("1.0.1~")
doTheStuff("1.0.~")
doTheStuff("1.0~")
doTheStuff("1.~")
doTheStuff("1~")
doTheStuff("1")

doTheStuff("1.0.1m-FULL")

