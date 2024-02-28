----------------------------------------------
------------MOD LOADER------------------------

SMODS.INIT = {}

function loadMods(modsDirectory)
    local mods = {}
    local modIDs = {}

    -- Function to process each directory (including subdirectories) with depth tracking
    local function processDirectory(directory, depth)
        if depth > 2 then
            return  -- Stop processing if the depth is greater than 2
        end

        for _, filename in ipairs(love.filesystem.getDirectoryItems(directory)) do
            local filePath = directory .. "/" .. filename

            -- Check if the current file is a directory
            if love.filesystem.getInfo(filePath).type == "directory" then
                -- If it's a directory and depth is within limit, recursively process it
                processDirectory(filePath, depth + 1)
            elseif filename:match("%.lua$") then  -- Check if the file is a .lua file
                local fileContent = love.filesystem.read(filePath)

                -- Convert CRLF in LF
                fileContent = fileContent:gsub("\r\n", "\n")

                -- Check the header lines using string.match
                local headerLine, secondaryLine = fileContent:match("^(.-)\n(.-)\n")
                if headerLine == "--- STEAMODDED HEADER" and secondaryLine == "--- SECONDARY MOD FILE" then
                    sendDebugMessage("Skipping secondary mod file: " .. filename)
                elseif headerLine == "--- STEAMODDED HEADER" then
                    -- Extract individual components from the header
                    local modName, modID, modAuthorString, modDescription = fileContent:match("%-%-%- MOD_NAME: ([^\n]+)\n%-%-%- MOD_ID: ([^\n]+)\n%-%-%- MOD_AUTHOR: %[(.-)%]\n%-%-%- MOD_DESCRIPTION: ([^\n]+)")

                    -- Validate MOD_ID to ensure it doesn't contain spaces
                    if modID and string.find(modID, " ") then
                        sendDebugMessage("Invalid mod ID: " .. modID)
                    elseif modIDs[modID] then
                        sendDebugMessage("Duplicate mod ID: " .. modID)
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
                                path = directory .. "/" -- Store the directory path
                            })
                            modIDs[modID] = true  -- Mark this ID as used

                            -- Load the mod file
                            assert(load(fileContent))()
                        end
                    end
                else
                    sendDebugMessage("Skipping non-Lua file or invalid header: " .. filename)
                end
            end
        end
    end

    -- Start processing with the initial directory at depth 1
    processDirectory(modsDirectory, 1)

    return mods
end

function initMods()
    for modName, initFunc in pairs(SMODS.INIT) do
        if type(initFunc) == "function" then
			sendDebugMessage("Launch Init Function for: " .. modName .. ".")
            initFunc()
        end
    end
end

function initSteamodded()
	SMODS.MODS = loadMods("Mods")

	sendDebugMessage(inspectDepth(SMODS.MODS, 0, 0))

    initGlobals()

	if SMODS.MODS then
		initializeModUIFunctions()
		initMods()
	end

    SMODS.injectSprites()
	SMODS.injectDecks()
    SMODS.injectJokers()
	sendDebugMessage(inspectDepth(G.P_CENTER_POOLS.Back))
end

----------------------------------------------
------------MOD LOADER END--------------------