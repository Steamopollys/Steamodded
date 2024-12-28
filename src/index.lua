SMODS.fetch_index = function()
    SMODS.index = {}
    local https = require"https"
    local status, contents = https.request("https://github.com/Aurelius7309/Steamodded.index/archive/refs/heads/main.zip")
    if status ~= 200 then return false end
    love.filesystem.write('index.zip', contents)
    if not love.filesystem.mount('index.zip', 'index') then return false end
    local path = 'index/Steamodded.index-main/mods/'
    for _, filename in ipairs(love.filesystem.getDirectoryItems(path)) do
        local key, ext = filename:sub(1, -6), filename:sub(-5)
        if ext:lower() == '.json' then
            local success, data = pcall(function() return JSON.decode(love.filesystem.read(path..filename)) end)
            if success and data.id == key then SMODS.index[key] = data end
        end
    end
    love.filesystem.unmount('index.zip')
    return true
end

SMODS.update_mod_files = function(id)
    local mod = SMODS.Mods[id]
    if not mod then return false end
    local use_git = os.execute('git -v') == 0
    if false and use_git and os.execute(('cd %s & git pull'):format(mod.path)) == 0 then
        return true
    end
    local https = require"https"
    local url = mod.github or (SMODS.index[id] or {}).github
    local status, contents = https.request(url) -- TODO account for branches
    local hash = contents:match('"currentOid":"([^"]*)"')
    sendWarnMessage(hash, "Index")
end
