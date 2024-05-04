--- STEAMODDED CORE
--- MODULE MODLOADER

SMODS.mod_priorities = {}
SMODS.mod_list = {}
-- Attempt to require nativefs
local nfs_success, nativefs = pcall(require, "nativefs")
local lovely_success, lovely = pcall(require, "lovely")

if nfs_success then
    if lovely_success then
        SMODS.MODS_DIR = lovely.mod_dir
    else
        sendErrorMessage("Error loading lovely library!", 'Loader')
        SMODS.MODS_DIR = "Mods"
    end
else
    sendErrorMessage("Error loading nativefs library!", 'Loader')
    SMODS.MODS_DIR = "Mods"
    nativefs = love.filesystem
end

NFS = nativefs

function loadMods(modsDirectory)
    local mods = {}
    local header_components = {
        name         = { pattern = '%-%-%- MOD_NAME: ([^\n]+)\n', required = true },
        id           = { pattern = '%-%-%- MOD_ID: ([^%s]+)\n', required = true },
        author       = { pattern = '%-%-%- MOD_AUTHOR: %[(.-)%]\n', required = true, parse_array = true },
        description  = { pattern = '%-%-%- MOD_DESCRIPTION: (.-)\n', required = true },
        priority     = { pattern = '%-%-%- PRIORITY: (%-?%d+)\n', handle = function(x) return x and x + 0 or 0 end },
        badge_colour = { pattern = '%-%-%- BADGE_COLO[U]?R: (%x-)\n', handle = function(x) return HEX(x or '666666FF') end },
        display_name = { pattern = '%-%-%- DISPLAY_NAME: (.-)\n' },
        dependencies = { pattern = '%-%-%- DEPENDENCIES: [(.-)%]\n', parse_array = true },
        icon_atlas   = { pattern = '%-%-%- ICON_ATLAS: (.-)\n', handle = function(x) return x or 'tags' end },
        prefix       = { pattern = '%-%-%- PREFIX: (.-)\n' },
    }
    local smods_dir

    -- Function to process each directory (including subdirectories) with depth tracking
    local function processDirectory(directory, depth)
        if depth > 3 then
            return -- Stop processing if the depth is greater than 3
        end

        for _, filename in ipairs(NFS.getDirectoryItems(directory)) do
            local file_path = directory .. "/" .. filename

            -- Check if the current file is a directory
            if NFS.getInfo(file_path).type == "directory" then
                -- If it's a directory and depth is within limit, recursively process it
                processDirectory(file_path, depth + 1)
            elseif filename:match("%.lua$") then -- Check if the file is a .lua file
                local file_content = NFS.read(file_path)

                -- Convert CRLF in LF
                file_content = file_content:gsub("\r\n", "\n")

                -- Check the header lines using string.match
                local headerLine = file_content:match("^(.-)\n")
                if headerLine == "--- STEAMODDED HEADER" then
                    boot_print_stage('Processing Mod File: '.. filename)
                    local mod = {}
                    local sane = true
                    for k, v in pairs(header_components) do
                        local component = file_content:match(v.patttern)
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
                    if mods[mod.id] then
                        sane = false
                        sendWarnMessage("Duplicate Mod ID: " .. mod.id, 'Loader')
                    end
                    
                    if sane then
                        boot_print_stage('Saving Mod Info: '..mod.id)
                        mod.path = directory .. '/'
                        mod.display_name = mod.display_name or mod.name
                        mod.prefix = mod.prefix or mod.id:lower():sub(1, 4)
                        mod.content = file_content
                        mod.optional_dependencies = {}
                        mods[mod.id] = mod
                        SMODS.mod_priorities[mod.priority] = SMODS.mod_priorities[mod.priority] or {}
                        table.insert(SMODS.mod_priorities[mod.priority], mod)
                    end
                elseif headerLine == '--- STEAMODDED CORE' then
                    smods_dir = smods_dir or directory:match('^(.+)/')
                else
                    sendTraceMessage("Skipping non-Lua file or invalid header: " .. filename, 'Loader')
                end
            end
        end
    end

    -- Start processing with the initial directory at depth 1
    processDirectory(modsDirectory, 1)

    -- sort by priority
    local keyset = {}
    for k, _ in pairs(SMODS.mod_priorities) do
        keyset[#keyset + 1] = k
    end
    table.sort(keyset)

    -- load the mod files
    for _, priority in ipairs(keyset) do
        for _, mod in ipairs(SMODS.mod_priorities[priority]) do
            boot_print_stage('Loading Mod: ' .. mod.id)
            SMODS.mod_list[#SMODS.mod_list + 1] = mod -- keep mod list in prioritized load order
            SMODS.current_mod = mod
            assert(load(mod.content))()
        end
    end

    return mods
end

function SMODS.injectItems()
    SMODS.injectObjects(SMODS.GameObject)
    SMODS.LOAD_LOC()
    SMODS.SAVE_UNLOCKS()
end

local function initializeModUIFunctions()
    for id, modInfo in pairs(SMODS.mod_list) do
        boot_print_stage("Initializing Mod UI: " .. modInfo.id)
        G.FUNCS["openModUI_" .. modInfo.id] = function(arg_736_0)
            G.ACTIVE_MOD_UI = modInfo
            G.FUNCS.overlay_menu({
                definition = create_UIBox_mods(arg_736_0)
            })
        end
    end
end

function initSteamodded()
    boot_print_stage("Loading Stack Trace")
    injectStackTrace()
    boot_print_stage("Loading APIs")
    loadAPIs()
    boot_print_stage("Loading Mods")
    SMODS.Mods = loadMods(SMODS.MODS_DIR)

    initGlobals()

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

----------------------------------------------
------------MOD LOADER END--------------------
