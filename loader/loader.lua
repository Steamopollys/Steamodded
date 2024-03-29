----------------------------------------------
------------MOD LOADER------------------------

SMODS.INIT = {}
SMODS._MOD_PRIO_MAP = {}
SMODS._INIT_PRIO_MAP = {}
SMODS._INIT_KEYS = {}

-- Attempt to require nativefs
local nfs_success, nativefs = pcall(require, "nativefs")
local lovely_success, lovely = pcall(require, "lovely")

if nfs_success then
    if lovely_success then
        SMODS.MODS_DIR = lovely.mod_dir
    else
        sendErrorMessage("Error loading lovely library!", "SteamoddedLoader")
        SMODS.MODS_DIR = "Mods"
    end
else
    sendErrorMessage("Error loading nativefs library!", "SteamoddedLoader")
    SMODS.MODS_DIR = "Mods"
    nativefs = love.filesystem
end

NFS = nativefs

function loadMods(modsDirectory)
    local mods = {}
    local modIDs = {}

    -- Function to process each directory (including subdirectories) with depth tracking
    local function processDirectory(directory, depth)
        if depth > 3 then
            return  -- Stop processing if the depth is greater than 3
        end

        for _, filename in ipairs(NFS.getDirectoryItems(directory)) do
            local filePath = directory .. "/" .. filename

            -- Check if the current file is a directory
            if NFS.getInfo(filePath).type == "directory" then
                -- If it's a directory and depth is within limit, recursively process it
                processDirectory(filePath, depth + 1)
            elseif filename:match("%.lua$") then  -- Check if the file is a .lua file
                local fileContent = NFS.read(filePath)

                -- Convert CRLF in LF
                fileContent = fileContent:gsub("\r\n", "\n")

                -- Check the header lines using string.match
                local headerLine, secondaryLine = fileContent:match("^(.-)\n(.-)\n")
                if headerLine == "--- STEAMODDED HEADER" and secondaryLine == "--- SECONDARY MOD FILE" then
                    sendInfoMessage("Skipping secondary mod file: " .. filename, "SteamoddedLoader")
                elseif headerLine == "--- STEAMODDED HEADER" then
                    -- Extract individual components from the header
                    local modName, modID, modAuthorString, modDescription = fileContent:match("%-%-%- MOD_NAME: ([^\n]+)\n%-%-%- MOD_ID: ([^\n]+)\n%-%-%- MOD_AUTHOR: %[(.-)%]\n%-%-%- MOD_DESCRIPTION: ([^\n]+)")
                    local priority = fileContent:match("%-%-%- PRIORITY: (%-?%d+)")
                    priority = priority and priority + 0 or 0

                    -- Validate MOD_ID to ensure it doesn't contain spaces
                    if modID and string.find(modID, " ") then
                        sendErrorMessage("Invalid mod ID: " .. modID, "SteamoddedLoader")
                    elseif modIDs[modID] then
                        sendErrorMessage("Duplicate mod ID: " .. modID, "SteamoddedLoader")
                    else
                        if modName and modID and modAuthorString and modDescription then
                            -- Parse MOD_AUTHOR array
                            local modAuthorArray = {}
                            for author in string.gmatch(modAuthorString, "([^,]+)") do
                                table.insert(modAuthorArray, author:match("^%s*(.-)%s*$")) -- Trim spaces
                            end

                            -- Store mod information in the global table, including the directory path
                            table.insert(mods, {
                                name = modName,
                                id = modID,
                                author = modAuthorArray,
                                description = modDescription,
                                path = directory .. "/", -- Store the directory path
                                priority = priority,
                            })
                            modIDs[modID] = true  -- Mark this ID as used

                            SMODS._MOD_PRIO_MAP[priority] = SMODS._MOD_PRIO_MAP[priority] or {}
                            table.insert(SMODS._MOD_PRIO_MAP[priority], fileContent)
                        end
                    end
                else
                    sendInfoMessage("Skipping non-Lua file or invalid header: " .. filename, "SteamoddedLoader")
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
    for _,priority in ipairs(keyset) do
        for __,v in ipairs(SMODS._MOD_PRIO_MAP[priority]) do
            assert(load(v))()
            -- set priority of added init functions
            for modName, initFunc in pairs(SMODS.INIT) do
                if type(initFunc) == 'function' and SMODS._INIT_KEYS[modName] == nil then
                    SMODS._INIT_PRIO_MAP[priority] = SMODS._INIT_PRIO_MAP[priority] or {}
                    table.insert(SMODS._INIT_PRIO_MAP[priority], modName)
                    SMODS._INIT_KEYS[modName] = true
                end
            end
        end
    end

    return mods
end

function initMods()
    local keyset = {}
    for k, _ in pairs(SMODS._INIT_PRIO_MAP) do
        keyset[#keyset + 1] = k
    end
    table.sort(keyset)
    for _,k in ipairs(keyset) do
        for _, modName in ipairs(SMODS._INIT_PRIO_MAP[k]) do
            sendInfoMessage("Launch Init Function for: " .. modName .. ".", "SteamoddedLoader")
            SMODS.INIT[modName]()
        end
    end
end

function initSteamodded()
    injectStackTrace()
	SMODS.MODS = loadMods(SMODS.MODS_DIR)

	sendDebugMessage(inspectDepth(SMODS.MODS, 0, 0), "SteamoddedLoader")

    initGlobals()

	if SMODS.MODS then
		initializeModUIFunctions()
		initMods()
	end

    SMODS.injectSprites()
	SMODS.injectDecks()
    SMODS.injectJokers()
    SMODS.injectTarots()
    SMODS.injectPlanets()
    SMODS.injectSpectrals()
    SMODS.injectVouchers()
    SMODS.injectBlinds()
    SMODS.injectSeals()
    SMODS.LOAD_LOC()
    SMODS.SAVE_UNLOCKS()
	sendDebugMessage(inspectDepth(G.P_CENTER_POOLS.Back), "SteamoddedLoader")
end

----------------------------------------------
------------MOD LOADER END--------------------
