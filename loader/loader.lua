--- STEAMODDED CORE
--- MODULE MODLOADER

function loadMods(modsDirectory)
    SMODS.Mods = {}
    SMODS.mod_priorities = {}
    SMODS.mod_list = {}
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
            pattern = '%-%-%- DEPENDENCIES: %[(.-)%]\n',
            parse_array = true,
            handle = function(x)
                local t = {}
                for _, v in ipairs(x) do
                    table.insert(t, {
                        id = v:match '(.-)[<>]' or v,
                        v_geq = v:match '>=([^<>]+)',
                        v_leq = v:match '<=([^<>]+)',
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
                        v_geq = v:match '>=([^<>]+)',
                        v_leq = v:match '<=([^<>]+)',
                    })
                end
                return t
            end
        },
        prefix        = { pattern = '%-%-%- PREFIX: (.-)\n' },
        version       = { pattern = '%-%-%- VERSION: (.-)\n', handle = function(x) return x or '0.0.0' end },
        l_version_geq = {
            pattern = '%-%-%- LOADER_VERSION_GEQ: (.-)\n',
            handle = function(x)
                return x and x:gsub('%-STEAMODDED', '')
            end
        },
        l_version_leq = {
            pattern = '%-%-%- LOADER_VERSION_LEQ: (.-)\n',
            handle = function(x)
                return x and x:gsub('%-STEAMODDED', '')
            end
        },
        outdated      = { pattern = { 'SMODS%.INIT', 'SMODS%.Deck' } },
        dump_loc      = { pattern = { '%-%-%- DUMP_LOCALIZATION\n'}}
    }
    
    local used_prefixes = {}

    -- Function to process each directory (including subdirectories) with depth tracking
    local function processDirectory(directory, depth)
        if depth > 3 or directory..'/' == SMODS.path then
            return
        end

        for _, filename in ipairs(NFS.getDirectoryItems(directory)) do
            local file_path = directory .. "/" .. filename

            -- Check if the current file is a directory
            local file_type = NFS.getInfo(file_path).type
            if file_type == 'directory' or file_type == 'symlink' then
                -- If it's a directory and depth is within limit, recursively process it
                processDirectory(file_path, depth + 1)
            elseif filename:lower():match("%.lua$") then -- Check if the file is a .lua file
                if depth == 1 then
                    sendWarnMessage(('Found lone Lua file %s in Mods directory :: Please place the files for each mod in its own subdirectory.'):format(filename))
                end
                local file_content = NFS.read(file_path)

                -- Convert CRLF in LF
                file_content = file_content:gsub("\r\n", "\n")

                -- Check the header lines using string.match
                local headerLine = file_content:match("^(.-)\n")
                if headerLine == "--- STEAMODDED HEADER" then
                    sendTraceMessage('Processing Mod File: ' .. filename)
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
                                filename, k))
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
                        sane = false
                        sendWarnMessage(('Duplicate Mod prefix %s used by %s, %s'):format(mod.prefix, mod.id, used_prefixes[mod.prefix]))
                    end

                    if sane then
                        sendTraceMessage('Saving Mod Info: ' .. mod.id)
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
                else
                    sendTraceMessage("Skipping non-Lua file or invalid header: " .. filename, 'Loader')
                end
            end
        end
    end

    boot_print_stage('Processing Mod Files')
    -- Start processing with the initial directory at depth 1
    processDirectory(modsDirectory, 1)

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
        for _, v in ipairs(mod.conflicts or {}) do
            -- block load even if the conflict is also blocked
            if
                SMODS.Mods[v.id] and
                (not v.v_leq or SMODS.Mods[v.id].version <= v.v_leq) and
                (not v.v_geq or SMODS.Mods[v.id].version >= v.v_geq)
            then
                can_load = false
                table.insert(load_issues.conflicts, v.id..(v.v_leq and '<='..v.v_leq or '')..(v.v_geq and '>='..v.v_geq or ''))
            end
        end
        for _, v in ipairs(mod.dependencies or {}) do
            -- recursively check dependencies of dependencies to make sure they are actually fulfilled
            if
                not SMODS.Mods[v.id] or
                not check_dependencies(SMODS.Mods[v.id], seen) or
                (v.v_leq and SMODS.Mods[v.id].version > v.v_leq) or
                (v.v_geq and SMODS.Mods[v.id].version < v.v_geq)
            then
                can_load = false
                table.insert(load_issues.dependencies,
                    v.id .. (v.v_geq and '>=' .. v.v_geq or '') .. (v.v_leq and '<=' .. v.v_leq or ''))
            end
        end
        if mod.outdated then
            load_issues.outdated = true
        end
        if mod.disabled then
            can_load = false
            load_issues.disabled = true
        end
        local loader_version = MODDED_VERSION:gsub('%-STEAMODDED', '')
        if
            (mod.l_version_geq and loader_version < mod.l_version_geq) or
            (mod.l_version_leq and loader_version > mod.l_version_geq)
        then
            can_load = false
            load_issues.version_mismatch = ''..(mod.l_version_geq and '>='..mod.l_version_geq or '')..(mod.l_version_leq and '<='..mod.l_version_leq or '')
        end
        if not can_load then
            mod.load_issues = load_issues
            return false
        end
        for _, v in ipairs(mod.dependencies) do
            SMODS.Mods[v.id].can_load = true
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
            if mod.can_load then
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
                    local load_func = type(mod.load_mod_config) == 'function' and mod.load_mod_config or SMODS.load_mod_config
                    load_func(mod)
                    assert(load(NFS.read(mod.path..mod.main_file), ('=[SMODS %s "%s"]'):format(mod.id, mod.main_file)))()
                end
                SMODS.current_mod = nil
            else
                sendTraceMessage(string.format("Mod %s was unable to load: %s%s%s", mod.id,
                    mod.load_issues.outdated and
                    'Outdated: Steamodded versions 0.9.8 and below are no longer supported!\n' or '',
                    next(mod.load_issues.dependencies) and
                    ('Missing Dependencies: ' .. inspect(mod.load_issues.dependencies) .. '\n') or '',
                    next(mod.load_issues.conflicts) and
                    ('Unresolved Conflicts: ' .. inspect(mod.load_issues.conflicts) .. '\n') or ''
                ))
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
        G.FUNCS["openModUI_" .. modInfo.id] = function(arg_736_0)
            G.ACTIVE_MOD_UI = modInfo
            G.FUNCS.overlay_menu({
                definition = create_UIBox_mods(arg_736_0)
            })
        end
    end
end

function initSteamodded()
    initGlobals()
    boot_print_stage("Loading APIs")
    loadAPIs()
    loadMods(SMODS.MODS_DIR)
    initializeModUIFunctions()
    boot_print_stage("Injecting Items")
    SMODS.injectItems()
    SMODS.booted = true
end

-- re-inject on reload
local init_item_prototypes_ref = Game.init_item_prototypes
function Game:init_item_prototypes()
    init_item_prototypes_ref(self)
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
