--- STEAMODDED CORE
--- UTILITY FUNCTIONS
function inspect(table)
	if type(table) ~= 'table' then
		return "Not a table"
	end

	local str = ""
	for k, v in pairs(table) do
		local valueStr = type(v) == "table" and "table" or tostring(v)
		str = str .. tostring(k) .. ": " .. valueStr .. "\n"
	end

	return str
end

function inspectDepth(table, indent, depth)
	if depth and depth > 5 then  -- Limit the depth to avoid deep nesting
		return "Depth limit reached"
	end

	if type(table) ~= 'table' then  -- Ensure the object is a table
		return "Not a table"
	end

	local str = ""
	if not indent then indent = 0 end

	for k, v in pairs(table) do
		local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
		if type(v) == "table" then
			str = str .. formatting .. "\n"
			str = str .. inspectDepth(v, indent + 1, (depth or 0) + 1)
		elseif type(v) == 'function' then
			str = str .. formatting .. "function\n"
		elseif type(v) == 'boolean' then
			str = str .. formatting .. tostring(v) .. "\n"
		else
			str = str .. formatting .. tostring(v) .. "\n"
		end
	end

	return str
end

function inspectFunction(func)
    if type(func) ~= 'function' then
        return "Not a function"
    end

    local info = debug.getinfo(func)
    local result = "Function Details:\n"

    if info.what == "Lua" then
        result = result .. "Defined in Lua\n"
    else
        result = result .. "Defined in C or precompiled\n"
    end

    result = result .. "Name: " .. (info.name or "anonymous") .. "\n"
    result = result .. "Source: " .. info.source .. "\n"
    result = result .. "Line Defined: " .. info.linedefined .. "\n"
    result = result .. "Last Line Defined: " .. info.lastlinedefined .. "\n"
    result = result .. "Number of Upvalues: " .. info.nups .. "\n"

    return result
end

function SMODS.SAVE_UNLOCKS()
    boot_print_stage("Saving Unlocks")
	G:save_progress()
    -------------------------------------
    local TESTHELPER_unlocks = false and not _RELEASE_MODE
    -------------------------------------
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '') then
        love.filesystem.createDirectory(G.SETTINGS.profile ..
            '')
    end
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '/' .. 'meta.jkr') then
        love.filesystem.append(
            G.SETTINGS.profile .. '/' .. 'meta.jkr', 'return {}')
    end

    convert_save_to_meta()

    local meta = STR_UNPACK(get_compressed(G.SETTINGS.profile .. '/' .. 'meta.jkr') or 'return {}')
    meta.unlocked = meta.unlocked or {}
    meta.discovered = meta.discovered or {}
    meta.alerted = meta.alerted or {}

    for k, v in pairs(G.P_CENTERS) do
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.unlocked = true; v.discovered = true; v.alerted = true
            end --REMOVE THIS
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) and meta.unlocked[k] then
                v.unlocked = true
            end
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) then
                G.P_LOCKED[#G.P_LOCKED + 1] = v
            end
            if not v.discovered and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^e_') or string.find(k, '^c_') or string.find(k, '^p_') or string.find(k, '^v_')) and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] or v.set == 'Back' or v.start_alerted then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end

	table.sort(G.P_LOCKED, function (a, b) return a.order and b.order and a.order < b.order end)

	for k, v in pairs(G.P_BLINDS) do
        v.key = k
        if not v.wip and not v.demo then 
            if TESTHELPER_unlocks then v.discovered = true; v.alerted = true  end --REMOVE THIS
            if not v.discovered and meta.discovered[k] then 
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
	for k, v in pairs(G.P_TAGS) do
        v.key = k
        if not v.wip and not v.demo then 
            if TESTHELPER_unlocks then v.discovered = true; v.alerted = true  end --REMOVE THIS
            if not v.discovered and meta.discovered[k] then 
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
    for k, v in pairs(G.P_SEALS) do
        v.key = k
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.discovered = true; v.alerted = true
            end                                                                   --REMOVE THIS
            if not v.discovered and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
end

function SMODS.process_loc_text(ref_table, ref_value, loc_txt, key)
    local target = (type(loc_txt) == 'table') and
    (loc_txt[G.SETTINGS.language] or loc_txt['default'] or loc_txt['en-us']) or loc_txt
    if key and (type(target) == 'table') then target = target[key] end
    if not (type(target) == 'string' or target and next(target)) then return end
    ref_table[ref_value] = target
end

function SMODS.handle_loc_file(path)
    local dir = path .. 'localization/'
	local file_name
    for k, v in ipairs({ dir .. G.SETTINGS.language .. '.lua', dir .. 'default.lua', dir .. 'en-us.lua' }) do
        if NFS.getInfo(v) then
            file_name = v
            break
        end
    end
    if not file_name then return end
    local loc_table = assert(loadstring(NFS.read(file_name)))()
    local function recurse(target, ref_table)
        if type(target) ~= 'table' then return end --this shouldn't happen unless there's a bad return value
        for k, v in pairs(target) do
            if not ref_table[k] or (type(v) ~= 'table') then
                ref_table[k] = v
            else
                recurse(v, ref_table[k])
            end
        end
    end
	recurse(loc_table, G.localization)
end

function SMODS.insert_pool(pool, center, replace)
	if replace == nil then replace = center.taken_ownership end
	if replace then
		for k, v in ipairs(pool) do
            if v.key == center.key then
                pool[k] = center
            end
		end
    else
		local prev_order = (pool[#pool] and pool[#pool].order) or 0
		if prev_order ~= nil then 
			center.order = prev_order + 1
		end
		table.insert(pool, center)
	end
end

function SMODS.remove_pool(pool, key)
    local j
    for i, v in ipairs(pool) do
        if v.key == key then j = i end
    end
    if j then return table.remove(pool, j) end
end

function SMODS.juice_up_blind()
    local ui_elem = G.HUD_blind:get_UIE_by_ID('HUD_blind_debuff')
    for _, v in ipairs(ui_elem.children) do
        v.children[1]:juice_up(0.3, 0)
    end
    G.GAME.blind:juice_up()
end

function SMODS.eval_this(_card, effects)
    if effects then
        local extras = { mult = false, hand_chips = false }
        if effects.mult_mod then
            mult = mod_mult(mult + effects.mult_mod); extras.mult = true
        end
        if effects.chip_mod then
            hand_chips = mod_chips(hand_chips + effects.chip_mod); extras.hand_chips = true
        end
        if effects.Xmult_mod then
            mult = mod_mult(mult * effects.Xmult_mod); extras.mult = true
        end
        update_hand_text({ delay = 0 }, { chips = extras.hand_chips and hand_chips, mult = extras.mult and mult })
        if effects.message then
            card_eval_status_text(_card, 'jokers', nil, nil, nil, effects)
        end
    end
end

-- Return an array of all (non-debuffed) jokers or consumables with key `key`.
-- Debuffed jokers count if `count_debuffed` is true.
-- This function replaces find_joker(); please use SMODS.find_card() instead
-- to avoid name conflicts with other mods.
function SMODS.find_card(key, count_debuffed)
    local results = {}
    if not G.jokers or not G.jokers.cards then return {} end
    for k, v in pairs(G.jokers.cards) do
        if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
            table.insert(results, v)
        end
    end
    for k, v in pairs(G.consumeables.cards) do
        if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
            table.insert(results, v)
        end
    end
    return results
end

function SMODS.reload()
    local lfs = love.filesystem
    local function recurse(dir)
        local files = lfs.getDirectoryItems(dir)
        for i, v in ipairs(files) do
            local file = (dir == '') and v or (dir .. '/' .. v)
            sendTraceMessage(file)
            if v == 'Mods' or v:len() == 1 then
                -- exclude save files
            elseif lfs.isFile(file) then
                lua_reload.ReloadFile(file)
            elseif lfs.isDirectory(file) then
                recurse(file)
            end
        end
    end
    recurse('')
    SMODS.booted = false
    G:init_item_prototypes()
    initSteamodded()
end

function SMODS.restart_game()
	if love.system.getOS() ~= 'OS X' then
		love.system.openURL('steam://rungameid/2379780')
	else
		os.execute('sh "/Users/$USER/Library/Application Support/Steam/steamapps/common/Balatro/run_lovely.sh" &')
	end
	love.event.quit()
end

function SMODS.create_mod_badges(obj, badges)
    if not G.SETTINGS.no_mod_badges and obj and obj.mod and obj.mod.display_name and not obj.no_mod_badges then
        local mods = {}
        badges.mod_set = badges.mod_set or {}
        if not badges.mod_set[obj.mod.id] and not obj.no_main_mod_badge then table.insert(mods, obj.mod) end
        badges.mod_set[obj.mod.id] = true
        if obj.dependencies then
            for _, v in ipairs(obj.dependencies) do
                local m = SMODS.Mods[v]
                if not badges.mod_set[m.id] then
                    table.insert(mods, m)
                    badges.mod_set[m.id] = true
                end
            end
        end
        for i, mod in ipairs(mods) do
            local mod_name = string.sub(mod.display_name, 1, 16)
            local len = string.len(mod_name)
            local size = 0.9 - (len > 6 and 0.02 * (len - 6) or 0)
            badges[#badges + 1] = create_badge(mod_name, mod.badge_colour or G.C.UI.BACKGROUND_INACTIVE, nil, size)
        end
    end
end

function SMODS.create_loc_dump()
    local _old, _new = SMODS.dump_loc.pre_inject, G.localization
    local _dump = {}
    local function recurse(old, new, dump)
        for k, _ in pairs(new) do
            if type(new[k]) == 'table' then
                dump[k] = {}
                if not old[k] then
                    dump[k] = new[k]
                else
                    recurse(old[k], new[k], dump[k])
                end
            elseif old[k] ~= new[k] then
                dump[k] = new[k]
            end
        end
    end
    recurse(_old, _new, _dump)
    local function cleanup(dump)
        for k, v in pairs(dump) do
            if type(v) == 'table' then
                cleanup(v)
                if not next(v) then dump[k] = nil end
            end
        end
    end
    cleanup(_dump)
    local str = 'return ' .. serialize(_dump)
	NFS.createDirectory(SMODS.dump_loc.path..'localization/')
	NFS.write(SMODS.dump_loc.path..'localization/dump.lua', str)
end

function serialize(t, indent)
    indent = indent or ''
    local str = '{\n'
	for k, v in ipairs(t) do
        str = str .. indent .. '\t'
		if type(v) == 'number' then
            str = str .. v
        elseif type(v) == 'string' then
            str = str .. serialize_string(v)
        elseif type(v) == 'table' then
            str = str .. serialize(v, indent .. '\t')
        else
            assert(false)
        end
		str = str .. ',\n'
	end
    for k, v in pairs(t) do
		if type(k) == 'string' then
        	str = str .. indent .. '\t' .. '[' .. serialize_string(k) .. '] = '
			if type(v) == 'number' then
				str = str .. v
			elseif type(v) == 'string' then
				str = str .. serialize_string(v)
			elseif type(v) == 'table' then
				str = str .. serialize(v, indent .. '\t')
			else
				assert(false)
			end
			str = str .. ',\n'
		end
    end
    str = str .. indent .. '}'
	return str
end

function serialize_string(s)
	return string.format("%q", s)
end

-- fill in only the values from t2 that don't exist in t1
function SMODS.merge_defaults(t, defaults)
    if not (t and defaults) then return end
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = v
        end
    end
end

--#region palettes
G.SETTINGS.selected_colours = G.SETTINGS.selected_colours or {}
G.PALETTE = {}

G.FUNCS.update_recolor = function(args)
    G.SETTINGS.selected_colours[args.cycle_config.type] = SMODS.Palettes[args.cycle_config.type][args.to_val]
	G:save_settings()
	G.FUNCS.update_atlas(args.cycle_config.type)
end

-- Set the atlases of all cards of the correct type to be the new palette
G.FUNCS.update_atlas = function(type)
	local atlas_keys = {}
	if type == "Suits" then
		atlas_keys = {"cards_1", "ui_1"}
		G.C["SO_1"].Clubs = G.SETTINGS.selected_colours[type].new_colours[1] or G.C["SO_1"].Clubs
		G.C["SO_1"].Spades = G.SETTINGS.selected_colours[type].new_colours[2] or G.C["SO_1"].Spades
		G.C["SO_1"].Diamonds = G.SETTINGS.selected_colours[type].new_colours[3] or G.C["SO_1"].Diamonds
		G.C["SO_1"].Hearts = G.SETTINGS.selected_colours[type].new_colours[4] or G.C["SO_1"].Hearts
		G.C.SUITS = G.C.SO_1
			
	else
		for _,v in pairs(G.P_CENTER_POOLS[type]) do
			atlas_keys[v.atlas or type] = v.atlas or type
		end
	end
	for _,v in pairs(atlas_keys) do
		if G.ASSET_ATLAS[v][G.SETTINGS.selected_colours[type].name] then
			G.ASSET_ATLAS[v].image = G.ASSET_ATLAS[v][G.SETTINGS.selected_colours[type].name].image
		end
	end
end

G.FUNCS.card_colours = function(e)
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{
      definition = G.UIDEF.card_colours(),
    }
  end

G.UIDEF.card_colours = function()
    local nodeRet = {}
    for _,k in ipairs(SMODS.Palettes.Types) do
		local v = SMODS.Palettes[k]
        if #v.names > 1 then
            nodeRet[#nodeRet+1] = create_option_cycle({w = 4,scale = 0.8, label = k.." colours" ,options = v.names, opt_callback = "update_recolor", current_option = G.SETTINGS.selected_colours[k].order, type=k})
        end
    end
    local t = create_UIBox_generic_options({back_func = 'options', contents = nodeRet})
    return t
end

G.FUNCS.recolour_image = function(x,y,r,g,b,a)
	if G.PALETTE.NEW.old_colours then
		for i=1, #G.PALETTE.NEW.old_colours do
			local defaultColour = G.PALETTE.NEW.old_colours[i]
			if defaultColour[1] == r and defaultColour[2] == g and defaultColour[3] == b then
				r = G.PALETTE.NEW.new_colours[i][1]
				g = G.PALETTE.NEW.new_colours[i][2]
				b = G.PALETTE.NEW.new_colours[i][3]
				return r,g,b,a
			end
		end
	end
	return r, g, b, a
end

function HEX_HSL(base_colour)
	local rgb = HEX(base_colour)
	local low = math.min(rgb[1], rgb[2], rgb[3])
	local high = math.max(rgb[1], rgb[2], rgb[3])
	local delta = high - low
	local sum = high + low
	local hsl = {0, 0, 0.5 * sum, rgb[4]}
	
	if delta == 0 then return hsl end
	
	if hsl[3] == 1 or hsl[3] == 0 then
		hsl[2] = 0
	else
		hsl[2] = delta/1-math.abs(2*hsl[3] - 1)
	end
	
	if high == rgb[1] then
		hsl[1] = ((rgb[2]-rgb[3])/delta) % 6
	elseif high == rgb[2] then
		hsl[1] = 2 + (rgb[3]-rgb[1])/delta
	else
		hsl[1] = 4 + (rgb[1]-rgb[2])/delta 
	end
	hsl[1] = hsl[1]/6
	return hsl
end

function HSL_RGB(base_colour)
	if base_colour[2] < 0.0001 then return {base_colour[3], base_colour[3], base_colour[3], base_colour[4]} end
	local t = (base_colour[3] < 0.5 and (base_colour[2]*base_colour[3] + base_colour[3]) or (-1 * base_colour[2] * base_colour[3] + (base_colour[2]+base_colour[3])))
	local s = 2 * base_colour[3] - t

	return {HUE(s, t, base_colour[1] + (1/3)), HUE(s,t,base_colour[1]), HUE(s,t,base_colour[1] - (1/3)), base_colour[4]}
end

function HUE(s, t, h)
	local hs = (h % 1) * 6
	if hs < 1 then return (t-s) * hs + s end
	if hs < 3 then return t end
	if hs < 4 then return (t-s) * (4-hs) + s end
	return s
end

--#endregion
