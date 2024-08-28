--- STEAMODDED CORE
--- MODULE CORE

SMODS = {}
MODDED_VERSION = "1.0.0~ALPHA-0828b-STEAMODDED"
SMODS.id = 'Steamodded'
SMODS.version = MODDED_VERSION:gsub('%-STEAMODDED', '')
SMODS.can_load = true

-- Include lovely and nativefs modules
local nativefs = require "nativefs"
local lovely = require "lovely"
local json = require "json"

local lovely_mod_dir = lovely.mod_dir:gsub("/$", "")
NFS = nativefs
-- make lovely_mod_dir an absolute path.
-- respects symlink/.. combos
NFS.setWorkingDirectory(lovely_mod_dir)
lovely_mod_dir = NFS.getWorkingDirectory()
-- make sure NFS behaves the same as love.filesystem
NFS.setWorkingDirectory(love.filesystem.getSaveDirectory())

JSON = json

local function set_mods_dir()
    local love_dirs = {
        love.filesystem.getSaveDirectory(),
        love.filesystem.getSourceBaseDirectory()
    }
    for _, love_dir in ipairs(love_dirs) do
        if lovely_mod_dir:sub(1, #love_dir) == love_dir then
            -- relative path from love_dir
            SMODS.MODS_DIR = lovely_mod_dir:sub(#love_dir+2)
            if nfs_success then
                -- make sure NFS behaves the same as love.filesystem.
                -- not perfect: NFS won't read from both getSaveDirectory()
                -- and getSourceBaseDirectory()
                NFS.setWorkingDirectory(love_dir)
            end
            return
        end
    end
    SMODS.MODS_DIR = lovely_mod_dir
end
set_mods_dir()

local function find_self(directory, target_filename, target_line, depth)
	depth = depth or 1
	if depth > 3 then return end
	for _, filename in ipairs(NFS.getDirectoryItems(directory)) do
		local file_path = directory .. "/" .. filename
		local file_type = NFS.getInfo(file_path).type
		if file_type == 'directory' or file_type == 'symlink' then
			local f = find_self(file_path, target_filename, target_line, depth+1)
			if f then return f end
		elseif filename == target_filename then
			local first_line = NFS.read(file_path):match('^(.-)\n')
			if first_line == target_line then
				-- use parent directory
				return directory:match('^(.+/)')
			end
		end
	end
end

SMODS.path = find_self(SMODS.MODS_DIR, 'core.lua', '--- STEAMODDED CORE')

for _, path in ipairs {
	"core/ui.lua",
	"core/utils.lua",
	"core/overrides.lua",
	"core/game_object.lua",
	"debug/debug.lua",
	"core/compat_0_9_8.lua",
	"loader/loader.lua",
} do
	assert(load(NFS.read(SMODS.path..path), ('=[SMODS _ "%s"]'):format(path)))()
end
