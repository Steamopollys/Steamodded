----------------------------------------------
------------MOD LOADER------------------------


function loadMods(modsDirectory)
	local mods = {}
	local modIDs = {}

	for _, filename in ipairs(love.filesystem.getDirectoryItems(modsDirectory)) do
		local filePath = modsDirectory .. "/" .. filename
		local fileContent = love.filesystem.read(filePath)

		-- Remove leading blank lines
		local contentWithoutLeadingBlanks = fileContent:match("^%s*(.*)")

		if contentWithoutLeadingBlanks:find("^%-%-%- STEAMODDED HEADER") then

			-- Extract individual components from the header
			local modName = contentWithoutLeadingBlanks:match("%-%-%- MOD_NAME: ([^\n]+)")
			local modID = contentWithoutLeadingBlanks:match("%-%-%- MOD_ID: ([^\n]+)")
			local modAuthorString = contentWithoutLeadingBlanks:match("%-%-%- MOD_AUTHOR: %[(.-)%]")
			local modDescription = contentWithoutLeadingBlanks:match("%-%-%- MOD_DESCRIPTION: ([^\n]+)")

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

					-- Store mod information in the global table
					table.insert(mods, {
						name = modName,
						id = modID,
						author = modAuthorArray,
						description = modDescription
					})
					modIDs[modID] = true  -- Mark this ID as used

					-- Load the mod file
					assert(load(fileContent))()
				end
			end
		else
			sendDebugMessage("Skipping mod: " .. filename .. " (header not at start of file)")
		end
	end

	return mods
end


SMODS.MODS = loadMods("Mods")

sendDebugMessage(inspectDepth(SMODS.MODS, 0, 0))

if SMODS.MODS then
	initializeModUIFunctions()
end

SMODS.injectDecks()

----------------------------------------------
------------MOD LOADER END--------------------
