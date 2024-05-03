--- STEAMODDED CORE
--- MODULE MODLOADER

SMODS.INIT = {}
SMODS._MOD_PRIO_MAP = {}
SMODS._INIT_PRIO_MAP = {}
SMODS.MODLIST = {}
SMODS.BUFFERS = {
    Seals = {},
}

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

    -- Function to process each directory (including subdirectories) with depth tracking
    local function processDirectory(directory, depth)
        if depth > 3 then
            return -- Stop processing if the depth is greater than 3
        end

        for _, filename in ipairs(NFS.getDirectoryItems(directory)) do
            local filePath = directory .. "/" .. filename

            -- Check if the current file is a directory
            if NFS.getInfo(filePath).type == "directory" then
                -- If it's a directory and depth is within limit, recursively process it
                processDirectory(filePath, depth + 1)
            elseif filename:match("%.lua$") then -- Check if the file is a .lua file
                local fileContent = NFS.read(filePath)

                -- Convert CRLF in LF
                fileContent = fileContent:gsub("\r\n", "\n")

                -- Check the header lines using string.match
                local headerLine, secondaryLine = fileContent:match("^(.-)\n(.-)\n")
                if headerLine == "--- STEAMODDED HEADER" and secondaryLine == "--- SECONDARY MOD FILE" then
                    sendTraceMessage("Skipping secondary mod file: " .. filename, 'Loader')
                elseif headerLine == "--- STEAMODDED HEADER" then
                    -- Extract individual components from the header
                    local modName, modID, modAuthorString, modDescription = fileContent:match(
                    "%-%-%- MOD_NAME: ([^\n]+)\n%-%-%- MOD_ID: ([^\n]+)\n%-%-%- MOD_AUTHOR: %[(.-)%]\n%-%-%- MOD_DESCRIPTION: ([^\n]+)")
                    boot_print_stage("Loading Mod: " .. modID)
                    local priority = fileContent:match("%-%-%- PRIORITY: (%-?%d+)")
                    priority = priority and priority + 0 or 0
                    local badge_colour = fileContent:match("%-%-%- BADGE_COLO[U]?R: (%x-)\n")
                    badge_colour = HEX(badge_colour or '666666FF')
                    local display_name = fileContent:match("%-%-%- DISPLAY_NAME: (.-)\n")
                    local prefix = fileContent:match("%-%-%- PREFIX: (.-)\n") or string.sub(string.lower(modID), 1, 4)
                    -- Validate MOD_ID to ensure it doesn't contain spaces
                    if modID and string.find(modID, " ") then
                        sendWarnMessage("Invalid mod ID: " .. modID, 'Loader')
                    elseif mods[modID] then
                        sendWarnMessage("Duplicate mod ID: " .. modID, 'Loader')
                    else
                        if modName and modID and modAuthorString and modDescription then
                            -- Parse MOD_AUTHOR array
                            local modAuthorArray = {}
                            for author in string.gmatch(modAuthorString, "([^,]+)") do
                                table.insert(modAuthorArray, author:match("^%s*(.-)%s*$")) -- Trim spaces
                            end

                            -- Store mod information in the global table, including the directory path
                            local mod = {
                                name = modName,
                                id = modID,
                                author = modAuthorArray,
                                description = modDescription,
                                path = directory .. "/", -- Store the directory path
                                priority = priority,
                                badge_colour = badge_colour,
                                display_name = display_name or modName,
                                prefix = prefix,
                                content = fileContent,
                            }
                            mods[modID] = mod
                            SMODS._MOD_PRIO_MAP[priority] = SMODS._MOD_PRIO_MAP[priority] or {}
                            table.insert(SMODS._MOD_PRIO_MAP[priority], mod)
                        end
                    end
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
    for k, _ in pairs(SMODS._MOD_PRIO_MAP) do
        keyset[#keyset + 1] = k
    end
    table.sort(keyset)

    -- load the mod files
    for _, priority in ipairs(keyset) do
        for _, mod in ipairs(SMODS._MOD_PRIO_MAP[priority]) do
            boot_print_stage('Loading Mod: ' .. mod.id)
            SMODS.MODLIST[#SMODS.MODLIST+1] = mod -- keep mod list in prioritized load order
            SMODS.current_mod = mod
            assert(load(mod.content))()
        end
    end

    return mods
end

function initMods()
    local keyset = {}
    for k, _ in pairs(SMODS._MOD_PRIO_MAP) do
        keyset[#keyset + 1] = k
    end
    table.sort(keyset)
    for _, k in ipairs(keyset) do
        for _, mod in ipairs(SMODS._MOD_PRIO_MAP[k]) do
            if mod.init and type(mod.init) == 'function' then
                SMODS.current_mod = mod
                boot_print_stage("Initializing Mod: " .. mod.id)
                sendInfoMessage("Launch Init Function for: " .. mod.id .. ".")
                mod:init()
            end
        end
    end
end

function SMODS.injectItems()
    SMODS.injectObjects(SMODS.GameObject)
    SMODS.LOAD_LOC()
    SMODS.SAVE_UNLOCKS()
end

local function initializeModUIFunctions()
	for id, modInfo in pairs(SMODS.MODLIST) do
		boot_print_stage("Initializing Mod UI: "..modInfo.id)
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

    boot_print_stage("Initializing Mods")
    if SMODS.Mods then
        initializeModUIFunctions()
        initMods()
    end
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
