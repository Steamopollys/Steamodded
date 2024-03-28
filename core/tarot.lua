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
	cost_mult = 1.0
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
			cost_mult = tarot.cost_mult,
			atlas = tarot.atlas
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
	SMODS.BUFFERS.Tarots = {}
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
	sendDebugMessage(inspect(_c))
    sendDebugMessage(inspect(full_UI_table))
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
	local loc_vars = {}
	if main_start then
		desc_nodes[#desc_nodes + 1] = main_start
	end
	
    if not (card_type == 'Locked') and not hide_desc then
        if _c.set == 'Tarot' then
            for _, v in pairs(SMODS.Tarots) do
                if v.loc_def and type(v.loc_def) == 'function' then
                    local o, m = v:loc_def(_c, info_queue)
                    if o and next(o) then loc_vars = o end
                    if m then main_end = m end
                end
            end
        end
        if _c.set == 'Spectral' then
            for _, v in pairs(SMODS.Spectrals) do
                if v.loc_def and type(v.loc_def) == 'function' then
                    local o, m = v:loc_def(_c, info_queue)
                    if o and next(o) then loc_vars = o end
                    if m then main_end = m end
                end
            end
        end
        if _c.set == 'Voucher' then
            for _, v in pairs(SMODS.Vouchers) do
                if v.loc_def and type(v.loc_def) == 'function' then
                    local o, m = v:loc_def(_c, info_queue)
                    if o and next(o) then loc_vars = o end
                    if m then main_end = m end
                end
            end
        end
    end

	if first_pass and not (_c.set == 'Edition') and badges and next(badges) then
		for _, v in ipairs(badges) do
			for k, _ in pairs(SMODS.Seals) do
				if k == v then info_queue[#info_queue + 1] = { key = v, set = 'Other' } end
			end
		end
	end

    if next(loc_vars) then
        localize { type = 'descriptions', key = _c.key, set = _c.set, nodes = desc_nodes, vars = loc_vars }
    end

    if main_end then
        desc_nodes[#desc_nodes + 1] = main_end
    end

	for _, v in ipairs(info_queue) do
		sendDebugMessage(inspect(v))
		generate_card_ui(v, full_UI_table)
	end
	if next(loc_vars) or next(info_queue) then return full_UI_table end
	return generate_card_ui_ref(_c, original_full_UI_table, specific_vars, card_type, badges, hide_desc, main_start,
		original_main_end)
end

local card_use_consumeable_ref = Card.use_consumeable
function Card:use_consumeable(area, copier)
	if self.debuff then return nil end
	card_use_consumeable_ref(self, area, copier)
	for _, v in pairs(SMODS.Tarots) do
		if (v.use and type(v.use) == 'function') then
			v:use(self, area, copier)
		end
	end
	for _, v in pairs(SMODS.Planets) do
		if (v.use and type(v.use) == 'function') then
			v:use(self, area, copier)
		end
	end
	for _, v in pairs(SMODS.Spectrals) do
		if (v.use and type(v.use) == 'function') then
			v:use(self, area, copier)
		end
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
	for _, v in pairs(SMODS.Tarots) do
		if (v.use and type(v.use) == 'function') then
			local o = v:can_use(self)
			t = (o == nil) and t or o
		end
	end
	for _, v in pairs(SMODS.Planets) do
		if (v.can_use and type(v.can_use) == 'function') then
			local o = v:can_use(self)
			t = (o == nil) and t or o
		end
	end
	for _, v in pairs(SMODS.Spectrals) do
		if (v.can_use and type(v.can_use) == 'function') then
			local o = v:can_use(self)
			t = (o == nil) and t or o
		end
	end
	if not (t == nil) then
		return t
	else
		return card_can_use_consumeable_ref(self, any_state, skip_check)
	end
end
