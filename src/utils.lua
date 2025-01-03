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

function SMODS._save_d_u(o)
    assert(not o._discovered_unlocked_overwritten)
    o._d, o._u = o.discovered, o.unlocked
    o._saved_d_u = true
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

    G.P_LOCKED = {}
    for k, v in pairs(G.P_CENTERS) do
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.unlocked = true; v.discovered = true; v.alerted = true
            end --REMOVE THIS
            if not v.unlocked and meta.unlocked[k] then
                v.unlocked = true
            end
            if not v.unlocked then
                G.P_LOCKED[#G.P_LOCKED + 1] = v
            end
            if not v.discovered and meta.discovered[k] then
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
    for _, t in ipairs{
        G.P_CENTERS,
        G.P_BLINDS,
        G.P_TAGS,
        G.P_SEALS,
    } do
        for k, v in pairs(t) do
            v._discovered_unlocked_overwritten = true
        end
    end
end

function SMODS.process_loc_text(ref_table, ref_value, loc_txt, key)
    local target = (type(loc_txt) == 'table') and
    ((G.SETTINGS.real_language and loc_txt[G.SETTINGS.real_language]) or loc_txt[G.SETTINGS.language] or loc_txt['default'] or loc_txt['en-us']) or loc_txt
    if key and (type(target) == 'table') then target = target[key] end
    if not (type(target) == 'string' or target and next(target)) then return end
    ref_table[ref_value] = target
end

local function parse_loc_file(file_name, force)
    local loc_table = nil
    if file_name:lower():match("%.json$") then
        loc_table = assert(JSON.decode(NFS.read(file_name)))
    else
        loc_table = assert(loadstring(NFS.read(file_name)))()
    end
    local function recurse(target, ref_table)
        if type(target) ~= 'table' then return end --this shouldn't happen unless there's a bad return value
        for k, v in pairs(target) do
            -- If the value doesn't exist *or*
            -- force mode is on and the value is not a table,
            -- change/add the thing
            -- brings back compatibility with language patching mods
            if (not ref_table[k] and type(k) ~= 'number') or (force and ((type(v) ~= 'table') or type(v[1]) == 'string')) then
                ref_table[k] = v
            else
                recurse(v, ref_table[k])
            end
        end
    end
	recurse(loc_table, G.localization)
end

local function handle_loc_file(dir, language, force)
    for k, v in ipairs({ dir .. language .. '.lua', dir .. language .. '.json' }) do
        if NFS.getInfo(v) then
            parse_loc_file(v, force)
            break
        end
    end
end

function SMODS.handle_loc_file(path)
    local dir = path .. 'localization/'
    handle_loc_file(dir, G.SETTINGS.language, true)
    if G.SETTINGS.real_language then handle_loc_file(dir, G.SETTINGS.real_language, true) end
    handle_loc_file(dir, 'default')
    handle_loc_file(dir, 'en-us')
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

-- Change a card's suit, rank, or both.
-- Accepts keys for both objects instead of needing to build a card key yourself.
function SMODS.change_base(card, suit, rank)
    if not card then return false end
    local _suit = SMODS.Suits[suit or card.base.suit]
    local _rank = SMODS.Ranks[rank or card.base.value]
    if not _suit or not _rank then
        sendWarnMessage(('Tried to call SMODS.change_base with invalid arguments: suit="%s", rank="%s"'):format(suit, rank), 'Util')
        return false
    end
    card:set_base(G.P_CARDS[('%s_%s'):format(_suit.card_key, _rank.card_key)])
    return card
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

function SMODS.create_card(t)
    if not t.area and t.key and G.P_CENTERS[t.key] then
        t.area = G.P_CENTERS[t.key].consumeable and G.consumeables or G.P_CENTERS[t.key].set == 'Joker' and G.jokers
    end
    if not t.area and not t.key and t.set and SMODS.ConsumableTypes[t.set] then
        t.area = G.consumeables
    end
    SMODS.bypass_create_card_edition = t.no_edition
    local _card = create_card(t.set, t.area, t.legendary, t.rarity, t.skip_materialize, t.soulable, t.key, t.key_append)
    SMODS.bypass_create_card_edition = nil

    -- Should this be restricted to only cards able to handle these
    -- or should that be left to the person calling SMODS.create_card to use it correctly? 
    if t.edition then _card:set_edition(t.edition) end
    if t.enhancement then _card:set_ability(G.P_CENTERS[t.enhancement]) end
    if t.seal then _card:set_seal(t.seal) end
    if t.stickers then 
        for i, v in ipairs(t.stickers) do
            local s = SMODS.Stickers[v]
            if not s or type(s.should_apply) ~= 'function' or s:should_apply(_card, t.area, true) then
                SMODS.Stickers[v]:apply(_card, true)
            end
        end
    end

    return _card
end

function SMODS.add_card(t)
    local card = SMODS.create_card(t)
    card:add_to_deck()
    local area = t.area or G.jokers
    area:emplace(card)
    return card
end

function SMODS.debuff_card(card, debuff, source)
    debuff = debuff or nil
    source = source and tostring(source) or nil
    if debuff == 'reset' then card.ability.debuff_sources = {}; return end
    card.ability.debuff_sources = card.ability.debuff_sources or {}
    card.ability.debuff_sources[source] = debuff
    card:set_debuff()
end

-- Recalculate whether a card should be debuffed
function SMODS.recalc_debuff(card)
    G.GAME.blind:debuff_card(card)
end

function SMODS.restart_game()
    if ((G or {}).SOUND_MANAGER or {}).channel then
        G.SOUND_MANAGER.channel:push({
            type = "kill",
        })
    end
    if ((G or {}).SAVE_MANAGER or {}).channel then
        G.SAVE_MANAGER.channel:push({
            type = "kill",
        })
    end
    if ((G or {}).HTTP_MANAGER or {}).channel then
        G.HTTP_MANAGER.channel:push({
            type = "kill",
        })
    end
    if love.system.getOS() ~= 'OS X' then
        love.thread.newThread("os.execute(...)\n"):start('"' .. arg[-2] .. '" ' .. table.concat(arg, " "))
    else
        os.execute('sh "/Users/$USER/Library/Application Support/Steam/steamapps/common/Balatro/run_lovely.sh" &')
    end

    love.event.quit()
end

function SMODS.create_mod_badges(obj, badges)
    if not SMODS.config.no_mod_badges and obj and obj.mod and obj.mod.display_name and not obj.no_mod_badges then
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
            local mod_name = string.sub(mod.display_name, 1, 20)
            local size = 0.9
            local font = G.LANG.font
            local max_text_width = 2 - 2*0.05 - 4*0.03*size - 2*0.03
            local calced_text_width = 0
            -- Math reproduced from DynaText:update_text
            for _, c in utf8.chars(mod_name) do
                local tx = font.FONT:getWidth(c)*(0.33*size)*G.TILESCALE*font.FONTSCALE + 2.7*1*G.TILESCALE*font.FONTSCALE
                calced_text_width = calced_text_width + tx/(G.TILESIZE*G.TILESCALE)
            end
            local scale_fac =
                calced_text_width > max_text_width and max_text_width/calced_text_width
                or 1
            badges[#badges + 1] = {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.R, config={align = "cm", colour = mod.badge_colour or G.C.GREEN, r = 0.1, minw = 2, minh = 0.36, emboss = 0.05, padding = 0.03*size}, nodes={
                  {n=G.UIT.B, config={h=0.1,w=0.03}},
                  {n=G.UIT.O, config={object = DynaText({string = mod_name or 'ERROR', colours = {mod.badge_text_colour or G.C.WHITE},float = true, shadow = true, offset_y = -0.05, silent = true, spacing = 1*scale_fac, scale = 0.33*size*scale_fac})}},
                  {n=G.UIT.B, config={h=0.1,w=0.03}},
                }}
              }}
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

-- Serializes an input table in valid Lua syntax
-- Keys must be of type number or string
-- Values must be of type number, boolean, string or table
function serialize(t, indent)
    indent = indent or ''
    local str = '{\n'
	for k, v in ipairs(t) do
        str = str .. indent .. '\t'
		if type(v) == 'number' then
            str = str .. v
        elseif type(v) == 'boolean' then
            str = str .. (v and 'true' or 'false')
        elseif type(v) == 'string' then
            str = str .. serialize_string(v)
        elseif type(v) == 'table' then
            str = str .. serialize(v, indent .. '\t')
        else
            -- not serializable
            str = str .. 'nil'
        end
		str = str .. ',\n'
	end
    for k, v in pairs(t) do
		if type(k) == 'string' then
        	str = str .. indent .. '\t' .. '[' .. serialize_string(k) .. '] = '
            
			if type(v) == 'number' then
				str = str .. v
            elseif type(v) == 'boolean' then
                str = str .. (v and 'true' or 'false')
			elseif type(v) == 'string' then
				str = str .. serialize_string(v)
			elseif type(v) == 'table' then
				str = str .. serialize(v, indent .. '\t')
			else
				-- not serializable
                str = str .. 'nil'
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

-- Starting with `t`, insert any key-value pairs from `defaults` that don't already
-- exist in `t` into `t`. Modifies `t`.
-- Returns `t`, the result of the merge.
--
-- `nil` inputs count as {}; `false` inputs count as a table where
-- every possible key maps to `false`. Therefore,
-- * `t == nil` is weak and falls back to `defaults`
-- * `t == false` explicitly ignores `defaults`
-- (This function might not return a table, due to the above)
function SMODS.merge_defaults(t, defaults)
    if t == false then return false end
    if defaults == false then return false end

    -- Add in the keys from `defaults`, returning a table
    if defaults == nil then return t end
    if t == nil then t = {} end
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = v
        end
    end
    return t
end
V_MT = {
    __eq = function(a, b)
        local minorWildcard = a.minor == -2 or b.minor == -2
        local patchWildcard = a.patch == -2 or b.patch == -2
        local betaWildcard = a.rev == '~' or b.rev == '~'
        return a.major == b.major and
        (a.minor == b.minor or minorWildcard) and
        (a.patch == b.patch or minorWildcard or patchWildcard) and
        (a.rev == b.rev or minorWildcard or patchWildcard or betaWildcard) and
        (betaWildcard or a.beta == b.beta)
    end,
    __le = function(a, b)
        local b = {
            major = b.major + (b.minor == -2 and 1 or 0),
            minor = b.minor == -2 and 0 or (b.minor + (b.patch == -2 and 1 or 0)),
            patch = b.patch == -2 and 0 or b.patch,
            beta = b.beta,
            rev = b.rev,
        }
        if a.major ~= b.major then return a.major < b.major end
        if a.minor ~= b.minor then return a.minor < b.minor end
        if a.patch ~= b.patch then return a.patch < b.patch end
        if a.beta ~= b.beta then return a.beta < b.beta end
        return a.rev <= b.rev
    end,
    __lt = function(a, b)
        return a <= b and not (a == b)
    end,
    __call = function(_, str)
        str = str or '0.0.0'
        local _, _, major, minorFull, minor, patchFull, patch, rev = string.find(str, '^(%d+)(%.?([%d%*]*))(%.?([%d%*]*))(.*)$')
        local minorWildcard = string.match(minor, '%*')
        local patchWildcard = string.match(patch, '%*')
        if (minorFull ~= "" and minor == "") or (patchFull ~= "" and patch == "") then
            sendWarnMessage('Trailing dot found in version "' .. str .. '".')
            major, minor, patch = -1, 0, 0
        end
        local t = {
            major = tonumber(major),
            minor = minorWildcard and -2 or tonumber(minor) or 0,
            patch = patchWildcard and -2 or tonumber(patch) or 0,
            rev = rev or '',
            beta = rev and rev:sub(1,1) == '~' and -1 or 0
        }
        return setmetatable(t, V_MT)
    end
}
V = setmetatable({}, V_MT)
V_MT.__index = V
function V.is_valid(v, allow_wildcard)
    if getmetatable(v) ~= V_MT then return false end
    return(pcall(function() return V() <= v and (allow_wildcard or (v.minor ~= -2 and v.patch ~= -2 and v.rev ~= '~')) end))
end

-- Flatten the given arrays of arrays into one, then
-- add elements of each table to a new table in order,
-- skipping any duplicates.
function SMODS.merge_lists(...)
    local t = {}
    for _, v in ipairs({...}) do
        for _, vv in ipairs(v) do
            table.insert(t, vv)
        end
    end
    local ret = {}
    local seen = {}
    for _, li in ipairs(t) do
        assert(type(li) == 'table')
        for _, v in ipairs(li) do
            if not seen[v] then
                ret[#ret+1] = v
                seen[v] = true
            end
        end
    end
    return ret
end

--#region Number formatting

function round_number(num, precision)
	precision = 10^(precision or 0)
	
	return math.floor(num * precision + 0.4999999999999994) / precision
end

-- Formatting util for UI elements (look number_formatting.toml)
function format_ui_value(value)
    if type(value) ~= "number" then
        return tostring(value)
    end

    return number_format(value, 1000000)
end

--#endregion


function SMODS.poll_seal(args)
    args = args or {}
    local key = args.key or 'stdseal'
    local mod = args.mod or 1
    local guaranteed = args.guaranteed or false
    local options = args.options or get_current_pool("Seal")
    local type_key = args.type_key or key.."type"..G.GAME.round_resets.ante
    key = key..G.GAME.round_resets.ante

    local available_seals = {}
    local total_weight = 0
    for _, v in ipairs(options) do
        if v ~= "UNAVAILABLE" then
            local seal_option = {}
            if type(v) == 'string' then
                assert(G.P_SEALS[v])
                seal_option = { key = v, weight = G.P_SEALS[v].weight or 5 } -- default weight set to 5 to replicate base game weighting
            elseif type(v) == 'table' then
                assert(G.P_SEALS[v.key])
                seal_option = { key = v.key, weight = v.weight }
            end
            if seal_option.weight > 0 then
                table.insert(available_seals, seal_option)
                total_weight = total_weight + seal_option.weight
            end
        end
	end
    total_weight = total_weight + (total_weight / 2 * 98) -- set base rate to 2%

    local type_weight = 0 -- modified weight total
    for _,v in ipairs(available_seals) do
        v.weight = G.P_SEALS[v.key].get_weight and G.P_SEALS[v.key]:get_weight() or v.weight
        type_weight = type_weight + v.weight
    end
    
    local seal_poll = pseudorandom(pseudoseed(key or 'stdseal'..G.GAME.round_resets.ante))
    if seal_poll > 1 - (type_weight*mod / total_weight) or guaranteed then -- is a seal generated
        local seal_type_poll = pseudorandom(pseudoseed(type_key)) -- which seal is generated
        local weight_i = 0
        for k, v in ipairs(available_seals) do
            weight_i = weight_i + v.weight
            if seal_type_poll > 1 - (weight_i / type_weight) then
                return v.key
            end
        end
    end
end

function SMODS.get_blind_amount(ante)
    local scale = G.GAME.modifiers.scaling
    local amounts = {
        300,
        700 + 100*scale,
        1400 + 600*scale,
        2100 + 2900*scale,
        15000 + 5000*scale*math.log(scale),
        12000 + 8000*(scale+1)*(0.4*scale),
        10000 + 25000*(scale+1)*((scale/4)^2),
        50000 * (scale+1)^2 * (scale/7)^2
    }
    
    if ante < 1 then return 100 end
    if ante <= 8 then return amounts[ante] - amounts[ante]%(10^math.floor(math.log10(amounts[ante])-1)) end
    local a, b, c, d = amounts[8], amounts[8]/amounts[7], ante-8, 1 + 0.2*(ante-8)
    local amount = math.floor(a*(b + (b*0.75*c)^d)^c)
    amount = amount - amount%(10^math.floor(math.log10(amount)-1))
    return amount
end

function SMODS.stake_from_index(index)
    local stake = G.P_CENTER_POOLS.Stake[index] or nil
    if not stake then return "error" end
    return stake.key
end

function convert_save_data()
    for k, v in pairs(G.PROFILES[G.SETTINGS.profile].deck_usage) do
        local first_pass = not v.wins_by_key and not v.losses_by_key
        v.wins_by_key = v.wins_by_key or {}
        for index, number in pairs(v.wins or {}) do
            if index > 8 and not first_pass then break end
            v.wins_by_key[SMODS.stake_from_index(index)] = number
        end
        v.losses_by_key = v.losses_by_key or {}
        for index, number in pairs(v.losses or {}) do
            if index > 8 and not first_pass then break end
            v.losses_by_key[SMODS.stake_from_index(index)] = number
        end
    end
    for k, v in pairs(G.PROFILES[G.SETTINGS.profile].joker_usage) do
        local first_pass = not v.wins_by_key and not v.losses_by_key
        v.wins_by_key = v.wins_by_key or {}
        for index, number in pairs(v.wins or {}) do
            if index > 8 and not first_pass then break end
            v.wins_by_key[SMODS.stake_from_index(index)] = number
        end
        v.losses_by_key = v.losses_by_key or {}
        for index, number in pairs(v.losses or {}) do
            if index > 8 and not first_pass then break end
            v.losses_by_key[SMODS.stake_from_index(index)] = number
        end
    end
    G:save_settings()
end


function SMODS.poll_rarity(_pool_key, _rand_key)
	local rarity_poll = pseudorandom(pseudoseed(_rand_key or ('rarity'..G.GAME.round_resets.ante))) -- Generate the poll value
	local available_rarities = copy_table(SMODS.ObjectTypes[_pool_key].rarities) -- Table containing a list of rarities and their rates
    local vanilla_rarities = {["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4}
    
    -- Calculate total rates of rarities
    local total_weight = 0
    for _, v in ipairs(available_rarities) do
        v.mod = G.GAME[tostring(v.key):lower().."_mod"] or 1
        -- Should this fully override the v.weight calcs? 
        if SMODS.Rarities[v.key] and SMODS.Rarities[v.key].get_weight and type(SMODS.Rarities[v.key].get_weight) == "function" then
            v.weight = SMODS.Rarities[v.key]:get_weight(v.weight, SMODS.ObjectTypes[_pool_key])
        end
        v.weight = v.weight*v.mod
        total_weight = total_weight + v.weight
    end
    -- recalculate rarities to account for v.mod
    for _, v in ipairs(available_rarities) do
        v.weight = v.weight / total_weight
    end

	-- Calculate selected rarity
	local weight_i = 0
	for _, v in ipairs(available_rarities) do
		weight_i = weight_i + v.weight
		if rarity_poll < weight_i then
            if vanilla_rarities[v.key] then 
                return vanilla_rarities[v.key]
            else
			    return v.key
            end
		end
	end
	return nil
end

function SMODS.poll_enhancement(args)
    args = args or {}
    local key = args.key or 'std_enhance'
    local mod = args.mod or 1
    local guaranteed = args.guaranteed or false
    local options = args.options or get_current_pool("Enhanced")
    local type_key = args.type_key or key.."type"..G.GAME.round_resets.ante
    key = key..G.GAME.round_resets.ante

    local available_enhancements = {}
    local total_weight = 0
    for _, v in ipairs(options) do
        if v ~= "UNAVAILABLE" then
            local enhance_option = {}
            if type(v) == 'string' then
                assert(G.P_CENTERS[v])
                enhance_option = { key = v, weight = G.P_CENTERS[v].weight or 5 } -- default weight set to 5 to replicate base game weighting
            elseif type(v) == 'table' then
                assert(G.P_CENTERS[v.key])
                enhance_option = { key = v.key, weight = v.weight }
            end
            if enhance_option.weight > 0 then
                table.insert(available_enhancements, enhance_option)
                total_weight = total_weight + enhance_option.weight
            end
        end
	  end
    total_weight = total_weight + (total_weight / 40 * 60) -- set base rate to 40%

    local type_weight = 0 -- modified weight total
    for _,v in ipairs(available_enhancements) do
        v.weight = G.P_CENTERS[v.key].get_weight and G.P_CENTERS[v.key]:get_weight() or v.weight
        type_weight = type_weight + v.weight
    end
    
    local enhance_poll = pseudorandom(pseudoseed(key))
    if enhance_poll > 1 - (type_weight*mod / total_weight) or guaranteed then -- is an enhancement selected
        local seal_type_poll = pseudorandom(pseudoseed(type_key)) -- which enhancement is selected
        local weight_i = 0
        for k, v in ipairs(available_enhancements) do
            weight_i = weight_i + v.weight
            if seal_type_poll > 1 - (weight_i / type_weight) then
                return v.key
            end
        end
    end
end

function time(func, ...)
    local start_time = love.timer.getTime()
    func(...)
    local end_time = love.timer.getTime()
    return 1000*(end_time-start_time)
end

function SMODS.get_enhancements(card, extra_only)
    local enhancements = {}
    if card.config.center.key ~= "c_base" and not extra_only then
        enhancements[card.config.center.key] = true
    end
    if G.jokers and G.jokers.cards then
        for i=1, #G.jokers.cards do
            local eval = G.jokers.cards[i]:calculate_joker({other_card = card, check_enhancement = true, no_blueprint = true })
            if eval then 
                for k, _ in pairs(eval) do
                    if G.P_CENTERS[k] then
                        enhancements[k] = true
                    end
                end
            end
        end
    end
    if extra_only and enhancements[card.config.center.key] then
        enhancements[card.config.center.key] = nil
    end
    return enhancements
end

function SMODS.has_enhancement(card, key)
    if card.config.center.key == key then return true end
    if G.jokers and G.jokers.cards then
        for i=1, #G.jokers.cards do
            local eval = G.jokers.cards[i]:calculate_joker({other_card = card, check_enhancement = true, no_blueprint = true })
            if eval and type(eval) == 'table' and eval[key] then return true end
        end
    end
    return false
end

function SMODS.has_no_suit(card)
    local is_stone = false
    local is_wild = false
    for k, _ in pairs(SMODS.get_enhancements(card)) do
        if k == 'm_stone' or G.P_CENTERS[k].no_suit then is_stone = true end
        if k == 'm_wild' or G.P_CENTERS[k].any_suit then is_wild = true end
    end
    return is_stone and not is_wild
end
function SMODS.has_any_suit(card)
    for k, _ in pairs(SMODS.get_enhancements(card)) do
        if k == 'm_wild' or G.P_CENTERS[k].any_suit then return true end
    end
end
function SMODS.has_no_rank(card)
    for k, _ in pairs(SMODS.get_enhancements(card)) do
        if k == 'm_stone' or G.P_CENTERS[k].no_rank then return true end
    end
end
function SMODS.always_scores(card)
    for k, _ in pairs(SMODS.get_enhancements(card)) do
        if k == 'm_stone' or G.P_CENTERS[k].always_scores then return true end
    end
end

SMODS.collection_pool = function(_base_pool)
    local pool = {}
    if type(_base_pool) ~= 'table' then return pool end
    local is_array = _base_pool[1]
    local ipairs = is_array and ipairs or pairs
    for _, v in ipairs(_base_pool) do
        if (not G.ACTIVE_MOD_UI or v.mod == G.ACTIVE_MOD_UI) and not v.no_collection then
            pool[#pool+1] = v
        end
    end
    if not is_array then table.sort(pool, function(a,b) return a.order < b.order end) end
    return pool
end

SMODS.find_mod = function(id)
    local ret = {}
    local mod = SMODS.Mods[id] or {}
    if mod.can_load then ret[#ret+1] = mod end
    for _,v in ipairs(SMODS.provided_mods[id] or {}) do
        if v.mod.can_load then ret[#ret+1] = v.mod end
    end
    return ret
end

local flat_copy_table = function(tbl)
    local new = {}
    for i, v in pairs(tbl) do
        new[i] = v
    end
    return new
end

---Seatch for val anywhere deep in tbl. Return a table of finds, or the first found if immediate is provided.
SMODS.deepfind = function(tbl, val, immediate)
    local seen = {[tbl] = true}
    local collector = {}
    local stack = { {tbl = tbl, path = {}, objpath = {}} }

    --while there are any elements to traverse
    while #stack > 0 do
        --pull the top off of the stack and start traversing it (by default this will be the last element of the last traversed table found in pairs)
        local current = table.remove(stack)
        --the current table we wish to traverse
        local currentTbl = current.tbl
        --the current path
        local currentPath = current.path
        --the current object path
        local currentObjPath = current.objpath

        --for every table that we have
        for i, v in pairs(currentTbl) do
            --if the value matches
            if v == val then
                --copy our values and store it in the collector
                local newPath = flat_copy_table(currentPath)
                local newObjPath = flat_copy_table(currentObjPath)
                table.insert(newPath, i)
                table.insert(newObjPath, v)
                table.insert(collector, {table = currentTbl, index = i, tree = newPath, objtree = newObjPath})
                if immediate then
                    return collector
                end
                --otherwise, if its a traversable table we havent seen yet
            elseif type(v) == "table" and not seen[v] then
                --make sure we dont see it again
                seen[v] = true
                --and then place it on the top of the stack
                local newPath = flat_copy_table(currentPath)
                local newObjPath = flat_copy_table(currentObjPath)
                table.insert(newPath, i)
                table.insert(newObjPath, v)
                table.insert(stack, {tbl = v, path = newPath, objpath = newObjPath})
            end
        end
    end

    return collector
end

--Seatch for val as an index anywhere deep in tbl. Return a table of finds, or the first found if immediate is provided.
SMODS.deepfindbyindex = function(tbl, val, immediate)
    local seen = {[tbl] = true}
    local collector = {}
    local stack = { {tbl = tbl, path = {}, objpath = {}} }

    --while there are any elements to traverse
    while #stack > 0 do
        --pull the top off of the stack and start traversing it (by default this will be the last element of the last traversed table found in pairs)
        local current = table.remove(stack)
        --the current table we wish to traverse
        local currentTbl = current.tbl
        --the current path
        local currentPath = current.path
        --the current object path
        local currentObjPath = current.objpath

        --for every table that we have
        for i, v in pairs(currentTbl) do
            --if the value matches
            if i == val then
                --copy our values and store it in the collector
                local newPath = flat_copy_table(currentPath)
                local newObjPath = flat_copy_table(currentObjPath)
                table.insert(newPath, i)
                table.insert(newObjPath, v)
                table.insert(collector, {table = currentTbl, index = i, tree = newPath, objtree = newObjPath})
                if immediate then
                    return collector
                end
                --otherwise, if its a traversable table we havent seen yet
            elseif type(v) == "table" and not seen[v] then
                --make sure we dont see it again
                seen[v] = true
                --and then place it on the top of the stack
                local newPath = flat_copy_table(currentPath)
                local newObjPath = flat_copy_table(currentObjPath)
                table.insert(newPath, i)
                table.insert(newObjPath, v)
                table.insert(stack, {tbl = v, path = newPath, objpath = newObjPath})
            end
        end
    end

    return collector
end

-- this is for debugging
SMODS.debug_calculation = function()
    G.contexts = {}
    local cj = Card.calculate_joker
    function Card:calculate_joker(context)
        for k,v in pairs(context) do G.contexts[k] = (G.contexts[k] or 0) + 1 end
        return cj(self, context)
    end
end
