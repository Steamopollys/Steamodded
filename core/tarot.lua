SMODS.Tarots = {}
SMODS.Tarot = {
	name = "",
	slug = "",
	cost = 3,
	config = {},
	pos = {},
	loc_txt = {},
	discovered = false,
	consumeable = true,
	effect = "",
	cost_mult = 1.0,
}

function SMODS.Tarot:new(name, slug, config, pos, loc_txt, cost, cost_mult, effect, consumeable, discovered, atlas)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.loc_txt = loc_txt
	o.name = name
	o.slug = "c_" .. slug
	o.config = config or {}
	o.pos = pos or {
		x = 0,
		y = 0
	}
	o.cost = cost
	o.unlocked = true
	o.discovered = discovered or false
	o.consumeable = consumeable or true
	o.effect = effect or ""
	o.cost_mult = cost_mult or 1.0
	o.atlas = atlas
	o.mod_name = SMODS._MOD_NAME
	o.badge_colour = SMODS._BADGE_COLOUR
	return o
end

function SMODS.Tarot:register()
	if not SMODS.Tarots[self.slug] then
		SMODS.Tarots[self.slug] = self
		SMODS.BUFFERS.Tarots[#SMODS.BUFFERS.Tarots + 1] = self.slug
	end
end

function SMODS.injectTarots()
	local minId = table_length(G.P_CENTER_POOLS['Tarot']) + 1
	local id = 0
	local i = 0
	local tarot = nil
	for _, slug in ipairs(SMODS.BUFFERS.Tarots) do
		tarot = SMODS.Tarots[slug]
		i = i + 1
		-- Prepare some Datas
		id = i + minId
		local tarot_obj = {
			unlocked = tarot.unlocked,
			discovered = tarot.discovered,
			consumeable = tarot.consumeable,
			name = tarot.name,
			set = "Tarot",
			order = id,
			key = tarot.slug,
			pos = tarot.pos,
			config = tarot.config,
			effect = tarot.effect,
			cost = tarot.cost,
			cost_mult = tarot.cost_mult,
			atlas = tarot.atlas,
			mod_name = tarot.mod_name,
			badge_colour = tarot.badge_colour
		}

		for _i, sprite in ipairs(SMODS.Sprites) do
			if sprite.name == tarot_obj.key then
				tarot_obj.atlas = sprite.name
			end
		end

		-- Now we replace the others
		G.P_CENTERS[tarot.slug] = tarot_obj
		table.insert(G.P_CENTER_POOLS['Tarot'], tarot_obj)

		-- Setup Localize text
		G.localization.descriptions["Tarot"][tarot.slug] = tarot.loc_txt
		sendDebugMessage("The Tarot named " .. tarot.name .. " with the slug " .. tarot.slug ..
			" have been registered at the id " .. id .. ".")
	end
end

function create_UIBox_your_collection_tarots()
	local deck_tables = {}

	G.your_collection = {}
	for j = 1, 2 do
		G.your_collection[j] = CardArea(
			G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
			(4.25 + j) * G.CARD_W,
			1 * G.CARD_H,
			{ card_limit = 4 + j, type = 'title', highlight_limit = 0, collection = true })
		table.insert(deck_tables,
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0, no_fill = true },
				nodes = {
					{ n = G.UIT.O, config = { object = G.your_collection[j] } }
				}
			}
		)
	end

	local tarot_options = {}
	for i = 1, math.ceil(#G.P_CENTER_POOLS.Tarot / 11) do
		table.insert(tarot_options,
			localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#G.P_CENTER_POOLS.Tarot / 11)))
	end

	for j = 1, #G.your_collection do
		for i = 1, 4 + j do
			local center = G.P_CENTER_POOLS["Tarot"][i + (j - 1) * (5)]
			local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y, G
				.CARD_W, G.CARD_H, nil, center)
			card:start_materialize(nil, i > 1 or j > 1)
			G.your_collection[j]:emplace(card)
		end
	end

	INIT_COLLECTION_CARD_ALERTS()

	local t = create_UIBox_generic_options({
		back_func = 'your_collection',
		contents = {
			{ n = G.UIT.R, config = { align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables },
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					create_option_cycle({
						options = tarot_options,
						w = 4.5,
						cycle_shoulders = true,
						opt_callback =
						'your_collection_tarot_page',
						focus_args = { snap_to = true, nav = 'wide' },
						current_option = 1,
						colour =
							G.C.RED,
						no_pips = true
					})
				}
			}
		}
	})
	return t
end

local generate_card_ui_ref = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
	local original_full_UI_table = full_UI_table
	local original_main_end = main_end
	local first_pass = nil
	if not full_UI_table then
		first_pass = true
		full_UI_table = {
			main = {},
			info = {},
			type = {},
			name = nil,
			badges = badges or {}
		}
	end

	local desc_nodes = (not full_UI_table.name and full_UI_table.main) or full_UI_table.info
	local name_override = nil
	local info_queue = {}

	local loc_vars = nil

	if not (card_type == 'Locked') and not hide_desc and not (specific_vars and specific_vars.debuffed) then
		local key = _c.key
		local center_obj = SMODS.Tarots[key] or SMODS.Planets[key] or SMODS.Spectrals[key] or SMODS.Vouchers[key]
		if center_obj and center_obj.loc_def and type(center_obj.loc_def) == 'function' then
			local o, m = center_obj.loc_def(_c, info_queue)
			if o then loc_vars = o end
			if m then main_end = m end
		end
		local joker_obj = SMODS.Jokers[key]
		if joker_obj and joker_obj.tooltip and type(joker_obj.tooltip) == 'function' then
			joker_obj.tooltip(_c, info_queue)
		end
	end

	if first_pass and not (_c.set == 'Edition') and badges and next(badges) then
		for _, v in ipairs(badges) do
			if SMODS.Seals[v] then info_queue[#info_queue + 1] = { key = v, set = 'Other' } end
		end
	end

	if loc_vars or next(info_queue) then
		if full_UI_table.name then
			full_UI_table.info[#full_UI_table.info + 1] = {}
			desc_nodes = full_UI_table.info[#full_UI_table.info]
		end
		if not full_UI_table.name then
			if specific_vars and specific_vars.no_name then
				full_UI_table.name = true
			elseif card_type == 'Locked' then
				full_UI_table.name = localize { type = 'name', set = 'Other', key = 'locked', nodes = {} }
			elseif card_type == 'Undiscovered' then
				full_UI_table.name = localize { type = 'name', set = 'Other', key = 'undiscovered_' .. (string.lower(_c.set)), name_nodes = {} }
			elseif specific_vars and (card_type == 'Default' or card_type == 'Enhanced') then
				if (_c.name == 'Stone Card') then full_UI_table.name = true end
				if (specific_vars.playing_card and (_c.name ~= 'Stone Card')) then
					full_UI_table.name = {}
					localize { type = 'other', key = 'playing_card', set = 'Other', nodes = full_UI_table.name, vars = { localize(specific_vars.value, 'ranks'), localize(specific_vars.suit, 'suits_plural'), colours = { specific_vars.colour } } }
					full_UI_table.name = full_UI_table.name[1]
				end
			elseif card_type == 'Booster' then

			else
				full_UI_table.name = localize { type = 'name', set = _c.set, key = _c.key, nodes = full_UI_table.name }
			end
			full_UI_table.card_type = card_type or _c.set
		end
		if main_start then
			desc_nodes[#desc_nodes + 1] = main_start
		end
		if loc_vars then
			localize { type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars }
			if not ((specific_vars and not specific_vars.sticker) and (card_type == 'Default' or card_type == 'Enhanced')) then
				if desc_nodes == full_UI_table.main and not full_UI_table.name then
					localize { type = 'name', key = _c.key, set = _c.set, nodes = full_UI_table.name }
					if not full_UI_table.name then full_UI_table.name = {} end
				elseif desc_nodes ~= full_UI_table.main then
					desc_nodes.name = localize { type = 'name_text', key = name_override or _c.key, set = name_override and 'Other' or _c.set }
				end
			end
		end
		if _c.set == 'Joker' then
			if specific_vars and specific_vars.pinned then info_queue[#info_queue + 1] = { key = 'pinned_left', set =
				'Other' } end
			if specific_vars and specific_vars.sticker then info_queue[#info_queue + 1] = { key = string.lower(
				specific_vars.sticker) .. '_sticker', set = 'Other' } end
			localize { type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = specific_vars or {} }
		end
		if main_end then
			desc_nodes[#desc_nodes + 1] = main_end
		end

		for _, v in ipairs(info_queue) do
			generate_card_ui(v, full_UI_table)
		end
		return full_UI_table
	end
	return generate_card_ui_ref(_c, original_full_UI_table, specific_vars, card_type, badges, hide_desc, main_start,
		original_main_end)
end

local card_use_consumeable_ref = Card.use_consumeable
function Card:use_consumeable(area, copier)
	local key = self.config.center.key
	local center_obj = SMODS.Tarots[key] or SMODS.Planets[key] or SMODS.Spectrals[key]
	if center_obj and center_obj.use and type(center_obj.use) == 'function' then
		stop_use()
		if not copier then set_consumeable_usage(self) end
		if self.debuff then return nil end
		if self.ability.consumeable.max_highlighted then
			update_hand_text({ immediate = true, nopulse = true, delay = 0 },
				{ mult = 0, chips = 0, level = '', handname = '' })
		end
		center_obj.use(self, area, copier)
	else
		card_use_consumeable_ref(self, area, copier)
	end
end

local card_can_use_consumeable_ref = Card.can_use_consumeable
function Card:can_use_consumeable(any_state, skip_check)
    if not skip_check and ((G.play and #G.play.cards > 0) or
            (G.CONTROLLER.locked) or
            (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
    then
        return false
    end
    if (G.STATE == G.STATES.HAND_PLAYED or G.STATE == G.STATES.DRAW_TO_HAND or G.STATE == G.STATES.PLAY_TAROT) and not any_state then
        return false
    end
    local t = nil
    local key = self.config.center.key
    local center_obj = SMODS.Tarots[key] or SMODS.Planets[key] or SMODS.Spectrals[key]
    if center_obj and center_obj.can_use and type(center_obj.can_use) == 'function' then
        t = center_obj.can_use(self) or t
    end
    if not (t == nil) then
        return t
    else
        return card_can_use_consumeable_ref(self, any_state, skip_check)
    end
end

local card_h_popup_ref = G.UIDEF.card_h_popup
function G.UIDEF.card_h_popup(card)
	local t = card_h_popup_ref(card)
    if not card.config.center or -- no center
	(card.config.center.unlocked == false and not card.bypass_lock) or -- locked card
	card.debuff or -- debuffed card
	(not card.config.center.discovered and ((card.area ~= G.jokers and card.area ~= G.consumeables and card.area) or not card.area)) -- undiscovered card
	then return t end
	local badges = t.nodes[1].nodes[1].nodes[1].nodes[3]
	badges = badges and badges.nodes or nil
	local key = card.config.center.key
	local center_obj = SMODS.Jokers[key] or SMODS.Tarots[key] or SMODS.Planets[key] or SMODS.Spectrals[key] or
		SMODS.Vouchers[key]
	if center_obj then
		if center_obj.set_badges and type(center_obj.set_badges) == 'function' then
			center_obj.set_badges(card, badges)
		end
		if not G.SETTINGS.no_mod_tracking then
			local mod_name = string.sub(center_obj.mod_name, 1, 16)
			local len = string.len(mod_name)
			badges[#badges + 1] = create_badge(mod_name, center_obj.badge_colour or G.C.UI.BACKGROUND_INACTIVE, nil,
				len <= 6 and 0.9 or 0.9 - 0.02 * (len - 6))
		end
	end
	return t
end

local settings_ref = G.UIDEF.settings_tab
function G.UIDEF.settings_tab(tab)
	local t = settings_ref(tab)
	if tab == 'Game' then
		t.nodes[7] = create_toggle { label = 'Disable Mod Tracking', ref_table = G.SETTINGS, ref_value = 'no_mod_tracking' }
	end
	return t
end