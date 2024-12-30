--- STEAMODDED CORE
--- MODULE MODLOADER

function loadMods(modsDirectory)
    SMODS.Mods = {}
    SMODS.Mods[SMODS.id] = SMODS
    SMODS.Mods['Lovely'] = {
        id = 'Lovely',
        can_load = true,
        version = require'lovely'.version,
        meta_mod = true,
    }
    SMODS.Mods['Balatro'] = {
        id = 'Balatro',
        can_load = true,
        version = G.VERSION,
        meta_mod = true,
    }
    SMODS.mod_priorities = {}
    SMODS.mod_list = {}
    SMODS.provided_mods = {}
    -- for legacy header support
    local header_components = {
        name          = { pattern = '%-%-%- MOD_NAME: ([^\n]+)\n', required = true },
        id            = { pattern = '%-%-%- MOD_ID: ([^ \n]+)\n', required = true },
        author        = { pattern = '%-%-%- MOD_AUTHOR: %[(.-)%]\n', required = true, parse_array = true },
        description   = { pattern = '%-%-%- MOD_DESCRIPTION: (.-)\n', required = true },
        priority      = { pattern = '%-%-%- PRIORITY: (%-?%d+)\n', handle = function(x) return x and x + 0 or 0 end },
        badge_colour  = { pattern = '%-%-%- BADGE_COLO[U]?R: (%x-)\n', handle = function(x) return HEX(x or '666666FF') end },
        badge_text_colour   = { pattern = '%-%-%- BADGE_TEXT_COLO[U]?R: (%x-)\n', handle = function(x) return HEX(x or 'FFFFFF') end },
        display_name  = { pattern = '%-%-%- DISPLAY_NAME: (.-)\n' },
        dependencies  = {
            pattern = {
                '%-%-%- DEPENDENCIES: %[(.-)%]\n',
                '%-%-%- DEPENDS: %[(.-)%]\n',
                '%-%-%- DEPS: %[(.-)%]\n',
            },
            parse_array = true,
            handle = function(x)
                local t = {}
                for _, v in ipairs(x) do
                    table.insert(t, {
                        id = v:match '(.-)[<>]' or v,
                        min_version = v:match '>=([^<>]+)',
                        max_version = v:match '<=([^<>]+)',
                    })
                end
                return t
            end,
        },
        conflicts     = {
            pattern = '%-%-%- CONFLICTS: %[(.-)%]\n',
            parse_array = true,
            handle = function(x)
                local t = {}
                for _, v in ipairs(x) do
                    table.insert(t, {
                        id = v:match '(.-)[<>]',
                        min_version = v:match '>=([^<>]+)',
                        max_version = v:match '<=([^<>]+)',
                    })
                    if t.min_version and not V(t[#t].min_version):is_valid() then t[#t].min_version = nil end
                    if t.max_version and not V(t[#t].max_version):is_valid() then t[#t].max_version = nil end
                end
                
                return t
            end
        },
        prefix        = { pattern = '%-%-%- PREFIX: (.-)\n' },
        version       = { pattern = '%-%-%- VERSION: (.-)\n', handle = function(x) return x and V(x):is_valid() and x or '0.0.0' end },
        outdated      = { pattern = { 'SMODS%.INIT', 'SMODS%.Deck[:.]new' } },
        dump_loc      = { pattern = { '%-%-%- DUMP_LOCALIZATION\n'}}
    }

    
    local json_spec = {
        id = { type = 'string', required = true },
        author = { type = 'table', required = true, check = function(mod, t)
            for k, v in pairs(t) do
                if type(k) ~= 'number' or type(v) ~= 'string' then t[k] = nil end
            end
            return t
        end },
        name = { type = 'string', required = true },
        display_name = { type = 'string', check = function(mod, s) mod.display_name = s or mod.name end },
        description = { type = 'string', required = true },
        priority = { type = 'number', default = 0 },
        badge_colour = { type = 'string', check = function(mod, s) local success, hex = pcall(HEX, s); mod.badge_colour = success and hex or HEX('666665FF') end },
        badge_text_colour = { type = 'string', check = function(mod, s) local success, hex = pcall(HEX, s); mod.badge_text_colour = success and hex or HEX('FFFFFFFF') end},
        prefix = { type = 'string', required = true },
        version = { type = 'string', check = function(mod, x) return x and V(x):is_valid() and x or '0.0.0' end },
        dump_loc = { type = 'boolean' },
        dependencies = { type = 'table', check = function(mod, t)
            local ops = {
                ['<<'] = function(a,b) return a<b end,
                -- ['<~'] = function(a,b) return a<b end,
                ['>>'] = function(a,b) return a>b end,
                ['<='] = function(a,b) return a<=b end,
                ['>='] = function(a,b) return a>=b end,
                ['=='] = function(a,b) return a==b end
            }
            for i,v in ipairs(t or {}) do
                local parts = {}
                parts.str = v
                for part in v:gmatch('([^|]+)') do
                    local x = {}
                    x.id = part:match '^([^(%s]+)'
                    local j = 1
                    for version_string in string.gmatch(part, '%((.-)%)') do
                        local operator, version = string.match(version_string, '^(..)(.*)$')
                        local op = ops[operator]
                        local ver = V(version)
                        -- if operator == '<<' and not ver.rev then
                        --     ver.beta = -1
                        --     ver.rev = '~'
                        -- end
                        if op and ver:is_valid(true) then
                           x[j] = { op = op, ver = ver }
                           j = j+1
                        end
                    end
                    parts[#parts+1] = x
                end
                t[i] = parts
            end
        end},
        conflicts = { type = 'table', check = function(mod, t)
            local ops = {
                ['<<'] = function(a,b) return a<b end,
                --['<~'] = function(a,b) return a<b end,
                ['>>'] = function(a,b) return a>b end,
                ['<='] = function(a,b) return a<=b end,
                ['>='] = function(a,b) return a>=b end,
                ['=='] = function(a,b) return a==b end
            }
            for i,v in ipairs(t or {}) do
                v = v:gsub('%s', '')
                local x = {}
                x.str = v
                v = v:gsub('%s', '')
                x.id = v:match '^([^(%s]+)'
                local j = 1
                for version_string in string.gmatch(v, '%((.-)%)') do
                    local operator, version = string.match(version_string, '^(..)(.*)$')
                    local op = ops[operator]
                    local ver = V(version)
                    -- if operator == '<<' and not ver.rev then
                    --     ver.beta = -1
                    --     ver.rev = '~'
                    -- end
                    if op and ver:is_valid(true) then
                        x[j] = { op = op, ver = ver, str = '('..version_string..')' }
                        j = j+1
                    end
                end
                t[i] = x
            end
        end},
        main_file = { type = 'string', required = true },
        __ = { check = function(mod)
            if SMODS.Mods[mod.id] then error('dupe') end
        end},
        provides = { type = 'table', check = function(mod, t)
            t = t or {}
            for _,v in pairs(t) do
                v = v:gsub('%s', '')
                local id = v:match '^([^(%s]+)'
                local ver = v:match '%((.-)%)'
                ver = (ver and V(ver):is_valid()) and ver or mod.version
                if id and ver then 
                    SMODS.provided_mods[id] = SMODS.provided_mods[id] or {}
                    table.insert(SMODS.provided_mods[id], { version = ver, mod = mod })
                end
            end
        end}
        
    }
    

    local used_prefixes = {}
    local lovely_directories = {}

    -- Function to process each directory (including subdirectories) with depth tracking
    local function processDirectory(directory, depth)
        if depth > 3 or directory..'/' == SMODS.path then
            return
        end

        local isDirLovely = false

        for _, filename in ipairs(NFS.getDirectoryItems(directory)) do
            local file_path = directory .. "/" .. filename

            -- Check if the current file is a directory
            local file_type = NFS.getInfo(file_path).type
            if file_type == 'directory' or file_type == 'symlink' then
                -- Lovely patches 
                if depth == 2 and filename == "lovely" and not isDirLovely then
                    isDirLovely = true
                    table.insert(lovely_directories, directory .. "/")
                end
                -- If it's a directory and depth is within limit, recursively process it
                if depth < 2 or (filename:lower() ~= 'localization' and filename:lower() ~= 'assets') then
                    processDirectory(file_path, depth + 1)
                end
            elseif depth == 2 and filename == "lovely.toml" and not isDirLovely then
                isDirLovely = true
                table.insert(lovely_directories, directory .. "/")
            elseif filename:lower():match('%.json') and depth > 1 then
                local json_str = NFS.read(file_path)
                local parsed, mod = pcall(JSON.decode, json_str)
                local valid = true
                local err
                if not parsed then
                    valid = false
                    err = mod
                else
                    mod.json = true
                    mod.path = directory .. '/'
                    mod.optional_dependencies = {}
                    local success, e = pcall(function()
                        -- remove invalid fields and check required ones first
                        for k, v in pairs(json_spec) do
                            if v.type and type(mod[k]) ~= v.type then mod[k] = nil end
                            if v.required and mod[k] == nil then error(k) end
                        end
                        -- perform additional checks and fill in defaults
                        for k, v in pairs(json_spec) do
                            if v.default then mod[k] = mod[k] or v.default end
                            if v.check then v.check(mod, mod[k]) end
                        end
                    end)
                    if not success then 
                        valid = false
                        err = e
                    end
                end
                if not valid then
                    sendErrorMessage(('Found invalid metadata JSON file at %s, ignoring: %s'):format(file_path, err), 'Loader')
                else
                    sendInfoMessage('Valid JSON file found')
                    if NFS.getInfo(directory..'/.lovelyignore') then
                        mod.disabled = true
                    end
                    if mod.prefix and used_prefixes[mod.prefix] then
                        mod.can_load = false
                        mod.load_issues = { 
                            prefix_conflict = used_prefixes[mod.prefix],
                            dependencies = {},
                            conflicts = {},
                        }
                        sendWarnMessage(('Duplicate Mod prefix %s used by %s, %s'):format(mod.prefix, mod.id, used_prefixes[mod.prefix]), 'Loader')
                    end
                    if not NFS.getInfo(mod.path..mod.main_file) then
                        mod.can_load = false
                        mod.load_issues = {
                            main_file_not_found = true,
                            dependencies = {},
                            conflicts = {},
                        }
                        sendWarnMessage(('Unable to load Mod %s: cannot find main file'):format(mod.id), 'Loader')
                    end
                    if mod.dump_loc then
                        SMODS.dump_loc = {
                            path = mod.path,
                        }
                    end
                    SMODS.Mods[mod.id] = mod
                    SMODS.mod_priorities[mod.priority] = SMODS.mod_priorities[mod.priority] or {}
                    table.insert(SMODS.mod_priorities[mod.priority], mod)
                end
            elseif filename:lower():match("%.lua$") then -- Check for legacy headers
                if depth == 1 then
                    sendWarnMessage(('Found lone Lua file %s in Mods directory :: Please place the files for each mod in its own subdirectory.'):format(filename), 'Loader')
                end
                local file_content = NFS.read(file_path)

                -- Convert CRLF in LF
                file_content = file_content:gsub("\r\n", "\n")

                -- Check the header lines using string.match
                local headerLine = file_content:match("^(.-)\n")
                if headerLine == "--- STEAMODDED HEADER" then
                    sendTraceMessage('Processing Mod file (Legacy header): ' .. filename, "Loader")
                    local mod = {}
                    local sane = true
                    for k, v in pairs(header_components) do
                        local component = nil
                        if type(v.pattern) == "table" then
                            for _, pattern in ipairs(v.pattern) do
                                component = file_content:match(pattern) or component
                                if component then break end
                            end
                        else
                            component = file_content:match(v.pattern)
                        end
                        if v.required and not component then
                            sane = false
                            sendWarnMessage(string.format('Mod file %s is missing required header component: %s',
                                filename, k), 'Loader')
                            break
                        end
                        if v.parse_array then
                            local list = {}
                            component = component or ''
                            for val in string.gmatch(component, "([^,]+)") do
                                table.insert(list, val:match("^%s*(.-)%s*$")) -- Trim spaces
                            end
                            component = list
                        end
                        if v.handle and type(v.handle) == 'function' then
                            component = v.handle(component)
                        end
                        mod[k] = component
                    end
                    if NFS.getInfo(directory..'/.lovelyignore') then
                        mod.disabled = true
                    end
                    if SMODS.Mods[mod.id] then
                        sane = false
                        sendWarnMessage("Duplicate Mod ID: " .. mod.id, 'Loader')
                    end
                
                    if mod.outdated then
                        mod.prefix_config = { key = { mod = false }, atlas = false }
                    else
                        mod.prefix = mod.prefix or (mod.id or ''):lower():sub(1, 4)
                    end
                    if mod.prefix and used_prefixes[mod.prefix] then
                        mod.can_load = false
                        mod.load_issues = { 
                            prefix_conflict = used_prefixes[mod.prefix],
                            dependencies = {},
                            conflicts = {},
                        }
                        sendWarnMessage(('Duplicate Mod prefix %s used by %s, %s'):format(mod.prefix, mod.id, used_prefixes[mod.prefix]), 'Loader')
                    end

                    if sane then
                        sendTraceMessage('Saving Mod Info: ' .. mod.id, 'Loader')
                        mod.path = directory .. '/'
                        mod.main_file = filename
                        mod.display_name = mod.display_name or mod.name
                        if mod.prefix then
                            used_prefixes[mod.prefix] = mod.id
                        end
                        mod.optional_dependencies = {}
                        if mod.dump_loc then
                            SMODS.dump_loc = {
                                path = mod.path,
                            }
                        end
                        SMODS.Mods[mod.id] = mod
                        SMODS.mod_priorities[mod.priority] = SMODS.mod_priorities[mod.priority] or {}
                        table.insert(SMODS.mod_priorities[mod.priority], mod)
                    end
                end
            end
        end
    end

    
    boot_print_stage('Processing Mod Files')
    -- Start processing with the initial directory at depth 1
    processDirectory(modsDirectory, 1)
    for _, path in ipairs(lovely_directories) do
        local hasSMOD = false
        for _, mod in pairs(SMODS.Mods) do
            if mod.path == path then
                mod.lovely = true
                hasSMOD = true
            end
        end
        if not hasSMOD then 
            local name = string.match(path, "[/\\]([^/\\]+)[/\\]?$")
            local disabled = not not NFS.getInfo(path .. '/.lovelyignore')
            local mod = {
                name = name,
                id = "lovely-compat-" .. name,
                author = {"???"},
                description = "A lovely mod.",
                prefix_config = { key = { mod = false }, atlas = false },
                priority = 0,
                badge_colour = HEX("666666FF"),
                badge_text_colour = HEX('FFFFFF'),
                path = path,
                main_file = "",
                display_name = name,
                dependencies = {},
                optional_dependencies = {},
                conflicts = {},
                version = "0.0.0",
                can_load = not disabled,
                lovely = true,
                lovely_only = true,
                meta_mod = true,
                disabled = disabled,
                load_issues = {
                    dependencies = {},
                    conflicts = {},
                    disabled = disabled
                }

            }
            SMODS.mod_priorities[mod.priority] = SMODS.mod_priorities[mod.priority] or {}
            table.insert(SMODS.mod_priorities[mod.priority], mod)
            SMODS.Mods[mod.id] = mod
        end
    end

    -- sort by priority
    local keyset = {}
    for k, _ in pairs(SMODS.mod_priorities) do
        keyset[#keyset + 1] = k
    end
    table.sort(keyset)

    local function check_dependencies(mod, seen)
        if not (mod.can_load == nil) then return mod.can_load end
        seen = seen or {}
        local can_load = true
        if seen[mod.id] then return true end
        seen[mod.id] = true
        local load_issues = {
            dependencies = {},
            conflicts = {},
        }
        if not mod.json then 
            for _, v in ipairs(mod.conflicts or {}) do
                -- block load even if the conflict is also blocked
                if
                    SMODS.Mods[v.id] and
                    (not v.max_version or V(SMODS.Mods[v.id].version) <= V(v.max_version)) and
                    (not v.min_version or V(SMODS.Mods[v.id].version) >= V(v.min_version))
                then
                    can_load = false
                    table.insert(load_issues.conflicts, v.id..(v.max_version and '<='..v.max_version or '')..(v.min_version and '>='..v.min_version or ''))
                end
            end
            for _, v in ipairs(mod.dependencies or {}) do
                -- recursively check dependencies of dependencies to make sure they are actually fulfilled
                if
                    not SMODS.Mods[v.id] or
                    not check_dependencies(SMODS.Mods[v.id], seen) or
                    (v.max_version and V(SMODS.Mods[v.id].version) > V(v.max_version)) or
                    (v.min_version and V(SMODS.Mods[v.id].version) < V(v.min_version))
                then
                    can_load = false
                    table.insert(load_issues.dependencies,
                        v.id .. (v.min_version and '>=' .. v.min_version or '') .. (v.max_version and '<=' .. v.max_version or ''))
                    if v.id == 'Steamodded' then
                        load_issues.version_mismatch = ''..(v.min_version and '>='..v.min_version or '')..(v.max_version and '<='..v.max_version or '')
                    end
                end
            end
        else
            for _, x in ipairs(mod.dependencies or {}) do
                local fulfilled
                for _, y in ipairs(x) do
                    if fulfilled then break end
                    local id = y.id
                    if SMODS.Mods[id] and check_dependencies(SMODS.Mods[id], seen) then
                        fulfilled = true
                        local dep_ver = V(SMODS.Mods[id].version)
                        for _, v in ipairs(y) do
                            if not v.op(dep_ver, v.ver) then
                                fulfilled = false
                            end
                        end
                        if fulfilled then y.fulfilled = true end
                    else
                        for _, provided in ipairs(SMODS.provided_mods[id] or {}) do
                            if provided.mod ~= mod and check_dependencies(provided.mod, seen) then
                                fulfilled = true
                                local dep_ver = V(provided.version)
                                for _, v in ipairs(y) do
                                    if not v.op(dep_ver, v.ver) then
                                        fulfilled = false
                                    end
                                end
                                if fulfilled then y.fulfilled = true; y.provided = provided end
                            end
                        end
                    end
                end
                if not fulfilled then
                    can_load = false
                    table.insert(load_issues.dependencies, x.str)
                end
            end
            for _, y in ipairs(mod.conflicts or {}) do
                local id = y.id
                local conflict = false
                if SMODS.Mods[id] and check_dependencies(SMODS.Mods[id], seen) then
                    conflict = true
                    local dep_ver = V(SMODS.Mods[id].version)
                    for _, v in ipairs(y) do
                        if not v.op(dep_ver, v.ver) then
                            conflict = false
                            break
                        end
                    end
                else
                    for _, provided in ipairs(SMODS.provided_mods[id] or {}) do
                        if provided.mod ~= mod and check_dependencies(provided.mod, seen) then
                            conflict = true
                            local dep_ver = V(provided.version)
                            for _, v in ipairs(y) do
                                if not v.op(dep_ver, v.ver) then
                                    conflict = false
                                    break
                                end
                            end
                        end
                    end
                end
                if conflict then
                    can_load = false
                    table.insert(load_issues.conflicts, y.str)
                end
            end
        end
        if mod.disabled then
            can_load = false
            load_issues.disabled = true
        end
        if not can_load then
            mod.load_issues = load_issues
            return false
        end
        for _, x in ipairs(mod.dependencies or {}) do
            for _, y in ipairs(x) do
                if y.fulfilled then 
                    if y.provided then
                        y.provided.mod.can_load = true
                    else
                        SMODS.Mods[y.id].can_load = true 
                    end
                end
            end 
        end
        return true
    end

    -- check dependencies first (for object dependencies)
    for _, mod in pairs(SMODS.Mods) do mod.can_load = check_dependencies(mod) end

    boot_print_stage('Loading Mods')
    -- load the mod files
    for _, priority in ipairs(keyset) do
        table.sort(SMODS.mod_priorities[priority],
            function(mod_a, mod_b)
                return mod_a.id < mod_b.id
            end)
        for _, mod in ipairs(SMODS.mod_priorities[priority]) do
            SMODS.mod_list[#SMODS.mod_list + 1] = mod -- keep mod list in prioritized load order
            if mod.can_load and not mod.lovely_only then
                SMODS.current_mod = mod
                if mod.outdated then
                    SMODS.compat_0_9_8.with_compat(function()
                        mod.config = {}
                        assert(load(NFS.read(mod.path..mod.main_file), ('=[SMODS %s "%s"]'):format(mod.id, mod.main_file)))()
                        for k, v in pairs(SMODS.compat_0_9_8.init_queue) do
                            v()
                            SMODS.compat_0_9_8.init_queue[k] = nil
                        end
                    end)
                else
                    SMODS.load_mod_config(mod)
                    assert(load(NFS.read(mod.path..mod.main_file), ('=[SMODS %s "%s"]'):format(mod.id, mod.main_file)))()
                end
                SMODS.current_mod = nil
            elseif not mod.lovely_only then
                sendTraceMessage(string.format("Mod %s was unable to load: %s%s%s%s", mod.id,
                    mod.load_issues.outdated and
                    'Outdated: Steamodded versions 0.9.8 and below are no longer supported!\n' or '',
                    mod.load_issues.main_file_not_found and "The main file could not be found.\n" or '',
                    next(mod.load_issues.dependencies) and
                    ('Missing Dependencies: ' .. inspect(mod.load_issues.dependencies) .. '\n') or '',
                    next(mod.load_issues.conflicts) and
                    ('Unresolved Conflicts: ' .. inspect(mod.load_issues.conflicts) .. '\n') or ''
                ), 'Loader')
            end
        end
    end
    -- compat after loading mods
    if SMODS.compat_0_9_8.load_done then
        -- Invasive change to Card:generate_UIBox_ability_table()
        local Card_generate_UIBox_ability_table_ref = Card.generate_UIBox_ability_table
        function Card:generate_UIBox_ability_table(...)
            SMODS.compat_0_9_8.generate_UIBox_ability_table_card = self
            local ret = Card_generate_UIBox_ability_table_ref(self, ...)
            SMODS.compat_0_9_8.generate_UIBox_ability_table_card = nil
            return ret
        end
    end
end

function SMODS.injectItems()
    -- Set .key for vanilla undiscovered, locked objects
    for k, v in pairs(G) do
        if type(k) == 'string' and (k:sub(-12, -1) == 'undiscovered' or k:sub(-6, -1) == 'locked') then
            v.key = k
        end
    end
    SMODS.injectObjects(SMODS.GameObject)
    if SMODS.dump_loc then
        boot_print_stage('Dumping Localization')
        SMODS.create_loc_dump()
    end
    boot_print_stage('Initializing Localization')
    init_localization()
    SMODS.SAVE_UNLOCKS()
    table.sort(G.P_CENTER_POOLS["Back"], function (a, b) return (a.order - (a.unlocked and 100 or 0)) < (b.order - (b.unlocked and 100 or 0)) end)
    for _, t in ipairs{
        G.P_CENTERS,
        G.P_BLINDS,
        G.P_TAGS,
        G.P_SEALS,
    } do
        for k, v in pairs(t) do
            assert(v._discovered_unlocked_overwritten)
        end
    end
end

local function initializeModUIFunctions()
    for id, modInfo in pairs(SMODS.mod_list) do
        G.FUNCS["openModUI_" .. modInfo.id] = function(e)
            G.ACTIVE_MOD_UI = modInfo
            G.FUNCS.overlay_menu({
                definition = create_UIBox_mods(e)
            })
        end
    end
end

local function checkForLoadFailure()
    SMODS.mod_button_alert = false
    for k,v in pairs(SMODS.Mods) do
        if v and not v.can_load and not v.disabled then
            SMODS.mod_button_alert = true
            return
        end 
    end
end

function initSteamodded()
    initGlobals()
    boot_print_stage("Loading APIs")
    loadAPIs()
    loadMods(SMODS.MODS_DIR)
    checkForLoadFailure()
    initializeModUIFunctions()
    boot_print_stage("Injecting Items")
    SMODS.injectItems()
    SMODS.booted = true
end

-- re-inject on reload
local init_item_prototypes_ref = Game.init_item_prototypes
function Game:init_item_prototypes()
    init_item_prototypes_ref(self)
    convert_save_data()
    if SMODS.booted then
        SMODS.injectItems()
    end
end

SMODS.booted = false
function boot_print_stage(stage)
    if not SMODS.booted then
        boot_timer(nil, "STEAMODDED - " .. stage, 0.95)
    end
end

function boot_timer(_label, _next, progress)
    progress = progress or 0
    G.LOADING = G.LOADING or {
        font = love.graphics.setNewFont("resources/fonts/m6x11plus.ttf", 20),
        love.graphics.dis
    }
    local realw, realh = love.window.getMode()
    love.graphics.setCanvas()
    love.graphics.push()
    love.graphics.setShader()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(0.6, 0.8, 0.9, 1)
    if progress > 0 then love.graphics.rectangle('fill', realw / 2 - 150, realh / 2 - 15, progress * 300, 30, 5) end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle('line', realw / 2 - 150, realh / 2 - 15, 300, 30, 5)
    love.graphics.print("LOADING: " .. _next, realw / 2 - 150, realh / 2 + 40)
    love.graphics.pop()
    love.graphics.present()

    G.ARGS.bt = G.ARGS.bt or love.timer.getTime()
    G.ARGS.bt = love.timer.getTime()
end

function SMODS.load_file(path, id)
    if not path or path == "" then
        error("No path was provided to load.")
    end
    local mod
    if not id then
        if not SMODS.current_mod then
            error("No ID was provided! Usage without an ID is only available when file is first loaded.")
        end
        mod = SMODS.current_mod
    else 
        mod = SMODS.Mods[id]
    end
    if not mod then
        error("Mod not found. Ensure you are passing the correct ID.")
    end 
    local file_path = mod.path .. path
    local file_content, err = NFS.read(file_path)
    if not file_content then return  nil, "Error reading file '" .. path .. "' for mod with ID '" .. mod.id .. "': " .. err end
    local chunk, err = load(file_content, "=[SMODS " .. mod.id .. ' "' .. path .. '"]')
    if not chunk then return nil, "Error processing file '" .. path .. "' for mod with ID '" .. mod.id .. "': " .. err end
    return chunk
end

----------------------------------------------
------------MOD LOADER END--------------------
