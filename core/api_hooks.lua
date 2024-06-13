--- STEAMODDED CORE
--- MODULE API HOOKS

-------------------------------------------------------------------------------------------------
----- API HOOKS GameObject.Stake
-------------------------------------------------------------------------------------------------

function SMODS.applied_stakes_UI(i, stake_desc_rows, num_added)
	if num_added == nil then num_added = { val = 0 } end
	if G.P_CENTER_POOLS['Stake'][i].applied_stakes then
		for _, v in pairs(G.P_CENTER_POOLS['Stake'][i].applied_stakes) do
			if v ~= "white" then
				--todo: manage this with pages
				if num_added.val < 8 then
					local i = G.P_STAKES["stake_" .. v].stake_level
					local _stake_desc = {}
					local _stake_center = G.P_CENTER_POOLS.Stake[i]
					localize { type = 'descriptions', key = _stake_center.key, set = _stake_center.set, nodes = _stake_desc }
					local _full_desc = {}
					for k, v in ipairs(_stake_desc) do
						_full_desc[#_full_desc + 1] = { n = G.UIT.R, config = { align = "cm" }, nodes = v }
					end
					_full_desc[#_full_desc] = nil
					stake_desc_rows[#stake_desc_rows + 1] = {
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.C, config = { align = 'cm' },                                                                nodes = { { n = G.UIT.C, config = { align = "cm", colour = get_stake_col(i), r = 0.1, minh = 0.35, minw = 0.35, emboss = 0.05 }, nodes = {} }, { n = G.UIT.B, config = { w = 0.1, h = 0.1 } } } },
							{ n = G.UIT.C, config = { align = "cm", padding = 0.03, colour = G.C.WHITE, r = 0.1, minh = 0.7, minw = 4.8 }, nodes = _full_desc },
						}
					}
				end
				num_added.val = num_added.val + 1
				num_added.val = SMODS.applied_stakes_UI(G.P_STAKES["stake_" .. v].stake_level, stake_desc_rows, num_added)
			end
		end
	end
end

-- We're overwriting so much that it's better to just remake this
function G.UIDEF.deck_stake_column(_deck_key)
	local deck_usage = G.PROFILES[G.SETTINGS.profile].deck_usage[_deck_key]
	local stake_col = {}
	local valid_option = nil
	local num_stakes = #G.P_CENTER_POOLS['Stake']
	for i = #G.P_CENTER_POOLS['Stake'], 1, -1 do
		local _wins = deck_usage and deck_usage.wins[i] or 0
		if (deck_usage and deck_usage.wins[i - 1]) or i == 1 or G.PROFILES[G.SETTINGS.profile].all_unlocked then valid_option = true end
		stake_col[#stake_col + 1] = {
			n = G.UIT.R,
			config = { id = i, align = "cm", colour = _wins > 0 and G.C.GREY or G.C.CLEAR, outline = 0, outline_colour = G.C.WHITE, r = 0.1, minh = 2 / num_stakes, minw = valid_option and 0.45 or 0.25, func = 'RUN_SETUP_check_back_stake_highlight' },
			nodes = {
				{ n = G.UIT.R, config = { align = "cm", minh = valid_option and 1.36 / num_stakes or 1.04 / num_stakes, minw = valid_option and 0.37 or 0.13, colour = _wins > 0 and get_stake_col(i) or G.C.UI.TRANSPARENT_LIGHT, r = 0.1 }, nodes = {} }
			}
		}
		if i > 1 then stake_col[#stake_col + 1] = { n = G.UIT.R, config = { align = "cm", minh = 0.8 / num_stakes, minw = 0.04 }, nodes = {} } end
	end
	return { n = G.UIT.ROOT, config = { align = 'cm', colour = G.C.CLEAR }, nodes = stake_col }
end

-------------------------------------------------------------------------------------------------
----- API HOOKS GameObject.Suit / GameObject.Rank
-------------------------------------------------------------------------------------------------

-- no point in using lovely for this, since no part of the original function is useful
function get_straight(hand)
	local ret = {}
	local four_fingers = next(SMODS.find_card('j_four_fingers'))
	local can_skip = next(SMODS.find_card('j_shortcut'))
	if #hand < (5 - (four_fingers and 1 or 0)) then return ret end
	local t = {}
	local RANKS = {}
	for i = 1, #hand do
		if hand[i]:get_id() > 0 then
			local rank = hand[i].base.value
			RANKS[rank] = RANKS[rank] or {}
			RANKS[rank][#RANKS[rank] + 1] = hand[i]
		end
	end
	local straight_length = 0
	local straight = false
	local skipped_rank = false
	local vals = {}
	for k, v in pairs(SMODS.Ranks) do
		if v.straight_edge then
			table.insert(vals, k)
		end
	end
	local init_vals = {}
	for _, v in ipairs(vals) do
		init_vals[v] = true
	end
	if not next(vals) then table.insert(vals, 'Ace') end
	local initial = true
	local br = false
	local end_iter = false
	local i = 0
	while 1 do
		end_iter = false
		if straight_length >= (5 - (four_fingers and 1 or 0)) then
			straight = true
		end
		i = i + 1
		if br or (i > #SMODS.Rank.obj_buffer + 1) then break end
		if not next(vals) then break end
		for _, val in ipairs(vals) do
			if init_vals[val] and not initial then br = true end
			if RANKS[val] then
				straight_length = straight_length + 1
				skipped_rank = false
				for _, vv in ipairs(RANKS[val]) do
					t[#t + 1] = vv
				end
				vals = SMODS.Ranks[val].next
				initial = false
				end_iter = true
				break
			end
		end
		if not end_iter then
			local new_vals = {}
			for _, val in ipairs(vals) do
				for _, r in ipairs(SMODS.Ranks[val].next) do
					table.insert(new_vals, r)
				end
			end
			vals = new_vals
			if can_skip and not skipped_rank then
				skipped_rank = true
			else
				straight_length = 0
				skipped_rank = false
				if not straight then t = {} end
				if straight then break end
			end
		end
	end
	if not straight then return ret end
	table.insert(ret, t)
	return ret
end

-- yeah no, modifying this with lovely is so inefficient
function G.UIDEF.deck_preview(args)
	local _minh, _minw = 0.35, 0.5
	local suit_labels = {}
	local suit_counts = {}
	local mod_suit_counts = {}
	for _, v in ipairs(SMODS.Suit.obj_buffer) do
		suit_counts[v] = 0
		mod_suit_counts[v] = 0
	end
	local mod_suit_diff = false
	local wheel_flipped, wheel_flipped_text = 0, nil
	local flip_col = G.C.WHITE
	local rank_counts = {}
	local deck_tables = {}
	remove_nils(G.playing_cards)
	table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
	local SUITS = {}
	for _, suit in ipairs(SMODS.Suit.obj_buffer) do
		SUITS[suit] = {}
		for _, rank in ipairs(SMODS.Rank.obj_buffer) do
			SUITS[suit][rank] = {}
		end
	end
	local stones = nil
	local suit_map = {}
	for i = #SMODS.Suit.obj_buffer, 1, -1 do
		suit_map[#suit_map + 1] = SMODS.Suit.obj_buffer[i]
	end
	local rank_name_mapping = {}
	for i = #SMODS.Rank.obj_buffer, 1, -1 do
		rank_name_mapping[#rank_name_mapping + 1] = SMODS.Rank.obj_buffer[i]
	end
	for k, v in ipairs(G.playing_cards) do
		if v.ability.effect == 'Stone Card' then
			stones = stones or 0
		end
		if (v.area and v.area == G.deck) or v.ability.wheel_flipped then
			if v.ability.wheel_flipped then wheel_flipped = wheel_flipped + 1 end
			if v.ability.effect == 'Stone Card' then
				stones = stones + 1
			else
				for kk, vv in pairs(suit_counts) do
					if v.base.suit == kk then suit_counts[kk] = suit_counts[kk] + 1 end
					if v:is_suit(kk) then mod_suit_counts[kk] = mod_suit_counts[kk] + 1 end
				end
				if SUITS[v.base.suit][v.base.value] then
					table.insert(SUITS[v.base.suit][v.base.value], v)
				end
				rank_counts[v.base.value] = (rank_counts[v.base.value] or 0) + 1
			end
		end
	end

	wheel_flipped_text = (wheel_flipped > 0) and
		{ n = G.UIT.T, config = { text = '?', colour = G.C.FILTER, scale = 0.25, shadow = true } } or nil
	flip_col = wheel_flipped_text and mix_colours(G.C.FILTER, G.C.WHITE, 0.7) or G.C.WHITE

	suit_labels[#suit_labels + 1] = {
		n = G.UIT.R,
		config = { align = "cm", r = 0.1, padding = 0.04, minw = _minw, minh = 2 * _minh + 0.25 },
		nodes = {
			stones and
			{ n = G.UIT.T, config = { text = localize('ph_deck_preview_stones') .. ': ', colour = G.C.WHITE, scale = 0.25, shadow = true } }
			or nil,
			stones and
			{ n = G.UIT.T, config = { text = '' .. stones, colour = (stones > 0 and G.C.WHITE or G.C.UI.TRANSPARENT_LIGHT), scale = 0.4, shadow = true } }
			or nil,
		}
	}

	local _row = {}
	local _bg_col = G.C.JOKER_GREY
	for k, v in ipairs(rank_name_mapping) do
		local _tscale = 0.3
		local _colour = G.C.BLACK
		local rank_col = SMODS.Ranks[v].face and G.C.WHITE or _bg_col
		rank_col = mix_colours(rank_col, _bg_col, 0.8)

		local _col = {
			n = G.UIT.C,
			config = { align = "cm" },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm", r = 0.1, minw = _minw, minh = _minh, colour = rank_col, emboss = 0.04, padding = 0.03 },
					nodes = {
						{
							n = G.UIT.R,
							config = { align = "cm" },
							nodes = {
								{ n = G.UIT.T, config = { text = '' .. SMODS.Ranks[v].shorthand, colour = _colour, scale = 1.6 * _tscale } },
							}
						},
						{
							n = G.UIT.R,
							config = { align = "cm", minw = _minw + 0.04, minh = _minh, colour = G.C.L_BLACK, r = 0.1 },
							nodes = {
								{ n = G.UIT.T, config = { text = '' .. (rank_counts[v] or 0), colour = flip_col, scale = _tscale, shadow = true } }
							}
						}
					}
				}
			}
		}
		table.insert(_row, _col)
	end
	table.insert(deck_tables, { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = _row })

	for _, suit in ipairs(suit_map) do
		if not SMODS.Suits[suit].disabled then
			_row = {}
			_bg_col = mix_colours(G.C.SUITS[suit], G.C.L_BLACK, 0.7)
			for _, rank in ipairs(rank_name_mapping) do
				local _tscale = #SUITS[suit][rank] > 0 and 0.3 or 0.25
				local _colour = #SUITS[suit][rank] > 0 and flip_col or G.C.UI.TRANSPARENT_LIGHT

				local _col = {
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05, minw = _minw + 0.098, minh = _minh },
					nodes = {
						{ n = G.UIT.T, config = { text = '' .. #SUITS[suit][rank], colour = _colour, scale = _tscale, shadow = true, lang = G.LANGUAGES['en-us'] } },
					}
				}
				table.insert(_row, _col)
			end
			table.insert(deck_tables,
				{
					n = G.UIT.R,
					config = { align = "cm", r = 0.1, padding = 0.04, minh = 0.4, colour = _bg_col },
					nodes =
						_row
				})
		end
	end

	for k, v in ipairs(suit_map) do
		if not SMODS.Suits[v].disabled then
			local t_s = Sprite(0, 0, 0.3, 0.3,
				G.ASSET_ATLAS[SMODS.Suits[v][G.SETTINGS.colourblind_option and "hc_ui_atlas" or "lc_ui_atlas"]] or
				G.ASSET_ATLAS[("ui_" .. (G.SETTINGS.colourblind_option and "2" or "1"))], SMODS.Suits[v].ui_pos)
			t_s.states.drag.can = false
			t_s.states.hover.can = false
			t_s.states.collide.can = false

			if mod_suit_counts[v] ~= suit_counts[v] then mod_suit_diff = true end

			suit_labels[#suit_labels + 1] =
			{
				n = G.UIT.R,
				config = { align = "cm", r = 0.1, padding = 0.03, colour = G.C.JOKER_GREY },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = _minw, minh = _minh },
						nodes = {
							{ n = G.UIT.O, config = { can_collide = false, object = t_s } }
						}
					},
					{
						n = G.UIT.C,
						config = { align = "cm", minw = _minw * 2.4, minh = _minh, colour = G.C.L_BLACK, r = 0.1 },
						nodes = {
							{ n = G.UIT.T, config = { text = '' .. suit_counts[v], colour = flip_col, scale = 0.3, shadow = true, lang = G.LANGUAGES['en-us'] } },
							mod_suit_counts[v] ~= suit_counts[v] and
							{ n = G.UIT.T, config = { text = ' (' .. mod_suit_counts[v] .. ')', colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7), scale = 0.28, shadow = true, lang = G.LANGUAGES['en-us'] } } or
							nil,
						}
					}
				}
			}
		end
	end


	local t =
	{
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.JOKER_GREY, r = 0.1, emboss = 0.05, padding = 0.07 },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", r = 0.1, emboss = 0.05, colour = G.C.BLACK, padding = 0.1 },
				nodes = {
					{
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.C, config = { align = "cm", padding = 0.04 }, nodes = suit_labels },
							{ n = G.UIT.C, config = { align = "cm", padding = 0.02 }, nodes = deck_tables }
						}
					},
					mod_suit_diff and {
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7) },              nodes = {} },
							{ n = G.UIT.T, config = { text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3 } },
						}
					} or nil,
					wheel_flipped_text and {
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = flip_col }, nodes = {} },
							{
								n = G.UIT.T,
								config = {
									text = ' ' .. (wheel_flipped > 1 and
										localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
										localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
									colour = G.C.WHITE,
									scale = 0.3
								}
							},
						}
					} or nil,
				}
			}
		}
	}
	return t
end

function G.UIDEF.view_deck(unplayed_only)
	local deck_tables = {}
	remove_nils(G.playing_cards)
	G.VIEWING_DECK = true
	table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
	local SUITS = {}
	local suit_map = {}
	for i = #SMODS.Suit.obj_buffer, 1, -1 do
		SUITS[SMODS.Suit.obj_buffer[i]] = {}
		suit_map[#suit_map + 1] = SMODS.Suit.obj_buffer[i]
	end
	for k, v in ipairs(G.playing_cards) do
		table.insert(SUITS[v.base.suit], v)
	end
	local num_suits = 0
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then num_suits = num_suits + 1 end
	end
	for j = 1, #suit_map do
		if SUITS[suit_map[j]][1] then
			local view_deck = CardArea(
				G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
				6.5 * G.CARD_W,
				((num_suits > 8) and 0.2 or (num_suits > 4) and (1 - 0.1 * num_suits) or 0.6) * G.CARD_H,
				{
					card_limit = #SUITS[suit_map[j]],
					type = 'title',
					view_deck = true,
					highlight_limit = 0,
					card_w = G
						.CARD_W * 0.7,
					draw_layers = { 'card' }
				})
			table.insert(deck_tables,
				{
					n = G.UIT.R,
					config = { align = "cm", padding = 0 },
					nodes = {
						{ n = G.UIT.O, config = { object = view_deck } }
					}
				}
			)

			for i = 1, #SUITS[suit_map[j]] do
				if SUITS[suit_map[j]][i] then
					local greyed, _scale = nil, 0.7
					if unplayed_only and not ((SUITS[suit_map[j]][i].area and SUITS[suit_map[j]][i].area == G.deck) or SUITS[suit_map[j]][i].ability.wheel_flipped) then
						greyed = true
					end
					local copy = copy_card(SUITS[suit_map[j]][i], nil, _scale)
					copy.greyed = greyed
					copy.T.x = view_deck.T.x + view_deck.T.w / 2
					copy.T.y = view_deck.T.y

					copy:hard_set_T()
					view_deck:emplace(copy)
				end
			end
		end
	end

	local flip_col = G.C.WHITE

	local suit_tallies = {}
	local mod_suit_tallies = {}
	for _, v in ipairs(suit_map) do
		suit_tallies[v] = 0
		mod_suit_tallies[v] = 0
	end
	local rank_tallies = {}
	local mod_rank_tallies = {}
	local rank_name_mapping = SMODS.Rank.obj_buffer
	for _, v in ipairs(rank_name_mapping) do
		rank_tallies[v] = 0
		mod_rank_tallies[v] = 0
	end
	local face_tally = 0
	local mod_face_tally = 0
	local num_tally = 0
	local mod_num_tally = 0
	local ace_tally = 0
	local mod_ace_tally = 0
	local wheel_flipped = 0

	for k, v in ipairs(G.playing_cards) do
		if v.ability.name ~= 'Stone Card' and (not unplayed_only or ((v.area and v.area == G.deck) or v.ability.wheel_flipped)) then
			if v.ability.wheel_flipped and unplayed_only then wheel_flipped = wheel_flipped + 1 end
			--For the suits
			suit_tallies[v.base.suit] = (suit_tallies[v.base.suit] or 0) + 1
			for kk, vv in pairs(mod_suit_tallies) do
				mod_suit_tallies[kk] = (vv or 0) + (v:is_suit(kk) and 1 or 0)
			end

			--for face cards/numbered cards/aces
			local card_id = v:get_id()
			face_tally = face_tally + ((SMODS.Ranks[v.base.value].face) and 1 or 0)
			mod_face_tally = mod_face_tally + (v:is_face() and 1 or 0)
			if not SMODS.Ranks[v.base.value].face and card_id ~= 14 then
				num_tally = num_tally + 1
				if not v.debuff then mod_num_tally = mod_num_tally + 1 end
			end
			if card_id == 14 then
				ace_tally = ace_tally + 1
				if not v.debuff then mod_ace_tally = mod_ace_tally + 1 end
			end

			--ranks
			rank_tallies[v.base.value] = rank_tallies[v.base.value] + 1
			if not v.debuff then mod_rank_tallies[v.base.value] = mod_rank_tallies[v.base.value] + 1 end
		end
	end
	local modded = face_tally ~= mod_face_tally
	for kk, vv in pairs(mod_suit_tallies) do
		modded = modded or (vv ~= suit_tallies[kk])
		if modded then break end
	end

	if wheel_flipped > 0 then flip_col = mix_colours(G.C.FILTER, G.C.WHITE, 0.7) end

	local rank_cols = {}
	for i = #rank_name_mapping, 1, -1 do
		local mod_delta = mod_rank_tallies[i] ~= rank_tallies[i]
		rank_cols[#rank_cols + 1] = {
			n = G.UIT.R,
			config = { align = "cm", padding = 0.07 },
			nodes = {
				{
					n = G.UIT.C,
					config = { align = "cm", r = 0.1, padding = 0.04, emboss = 0.04, minw = 0.5, colour = G.C.L_BLACK },
					nodes = {
						{ n = G.UIT.T, config = { text = SMODS.Ranks[rank_name_mapping[i]].shorthand, colour = G.C.JOKER_GREY, scale = 0.35, shadow = true } },
					}
				},
				{
					n = G.UIT.C,
					config = { align = "cr", minw = 0.4 },
					nodes = {
						mod_delta and
						{ n = G.UIT.O, config = { object = DynaText({ string = { { string = '' .. rank_tallies[i], colour = flip_col }, { string = '' .. mod_rank_tallies[i], colour = G.C.BLUE } }, colours = { G.C.RED }, scale = 0.4, y_offset = -2, silent = true, shadow = true, pop_in_rate = 10, pop_delay = 4 }) } } or
						{ n = G.UIT.T, config = { text = rank_tallies[rank_name_mapping[i]], colour = flip_col, scale = 0.45, shadow = true } },
					}
				}
			}
		}
	end

	local tally_ui = {
		-- base cards
		{
			n = G.UIT.R,
			config = { align = "cm", minh = 0.05, padding = 0.07 },
			nodes = {
				{ n = G.UIT.O, config = { object = DynaText({ string = { { string = localize('k_base_cards'), colour = G.C.RED }, modded and { string = localize('k_effective'), colour = G.C.BLUE } or nil }, colours = { G.C.RED }, silent = true, scale = 0.4, pop_in_rate = 10, pop_delay = 4 }) } }
			}
		},
		-- aces, faces and numbered cards
		{
			n = G.UIT.R,
			config = { align = "cm", minh = 0.05, padding = 0.1 },
			nodes = {
				tally_sprite({ x = 1, y = 0 },
					{ { string = '' .. ace_tally, colour = flip_col }, { string = '' .. mod_ace_tally, colour = G.C.BLUE } },
					{ localize('k_aces') }), --Aces
				tally_sprite({ x = 2, y = 0 },
					{ { string = '' .. face_tally, colour = flip_col }, { string = '' .. mod_face_tally, colour = G.C.BLUE } },
					{ localize('k_face_cards') }), --Face
				tally_sprite({ x = 3, y = 0 },
					{ { string = '' .. num_tally, colour = flip_col }, { string = '' .. mod_num_tally, colour = G.C.BLUE } },
					{ localize('k_numbered_cards') }), --Numbers
			}
		},
	}
	-- add suit tallies
	local i = 1
	while i <= #suit_map do
		local n = {
			n = G.UIT.R,
			config = { align = "cm", minh = 0.05, padding = 0.1 },
			nodes = {}
		}
		for _ = 1, 2 do
			while i <= #suit_map and SMODS.Suits[suit_map[i]].disabled do
				i = i + 1
			end
			if not suit_map[i] then break end
			table.insert(n.nodes, tally_sprite(
				SMODS.Suits[suit_map[i]].ui_pos,
				{
					{
						string = '' .. suit_tallies[suit_map[i]],
						colour = flip_col
					},
					{
						string = '' .. mod_suit_tallies[suit_map[i]],
						colour = G.C.BLUE
					}
				},
				{ localize(suit_map[i], 'suits_plural') },
				suit_map[i]
			))
			i = i + 1
		end
		table.insert(tally_ui, n)
	end
	local t =
	{
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{ n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = {} },
			{
				n = G.UIT.R,
				config = { align = "cm" },
				nodes = {
					{
						n = G.UIT.C,
						config = { align = "cm", minw = 1.5, minh = 2, r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
						nodes = {
							{
								n = G.UIT.C,
								config = { align = "cm", padding = 0.1 },
								nodes = {
									{
										n = G.UIT.R,
										config = { align = "cm", r = 0.1, colour = G.C.L_BLACK, emboss = 0.05, padding = 0.15 },
										nodes = {
											{
												n = G.UIT.R,
												config = { align = "cm" },
												nodes = {
													{ n = G.UIT.O, config = { object = DynaText({ string = G.GAME.selected_back.loc_name, colours = { G.C.WHITE }, bump = true, rotate = true, shadow = true, scale = 0.6 - string.len(G.GAME.selected_back.loc_name) * 0.01 }) } },
												}
											},
											{
												n = G.UIT.R,
												config = { align = "cm", r = 0.1, padding = 0.1, minw = 2.5, minh = 1.3, colour = G.C.WHITE, emboss = 0.05 },
												nodes = {
													{
														n = G.UIT.O,
														config = {
															object = UIBox {
																definition = G.GAME.selected_back:generate_UI(nil, 0.7, 0.5, G.GAME.challenge),
																config = { offset = { x = 0, y = 0 } }
															}
														}
													}
												}
											}
										}
									},
									{ n = G.UIT.R, config = { align = "cm", r = 0.1, outline_colour = G.C.L_BLACK, line_emboss = 0.05, outline = 1.5 }, nodes = tally_ui } }
							},
							{ n = G.UIT.C, config = { align = "cm" },    nodes = rank_cols },
							{ n = G.UIT.B, config = { w = 0.1, h = 0.1 } },
						}
					},
					{ n = G.UIT.B, config = { w = 0.2, h = 0.1 } },
					{ n = G.UIT.C, config = { align = "cm", padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables }
				}
			},
			{
				n = G.UIT.R,
				config = { align = "cm", minh = 0.8, padding = 0.05 },
				nodes = {
					modded and {
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = mix_colours(G.C.BLUE, G.C.WHITE, 0.7) },              nodes = {} },
							{ n = G.UIT.T, config = { text = ' ' .. localize('ph_deck_preview_effective'), colour = G.C.WHITE, scale = 0.3 } },
						}
					} or nil,
					wheel_flipped > 0 and {
						n = G.UIT.R,
						config = { align = "cm" },
						nodes = {
							{ n = G.UIT.C, config = { padding = 0.3, r = 0.1, colour = flip_col }, nodes = {} },
							{
								n = G.UIT.T,
								config = {
									text = ' ' .. (wheel_flipped > 1 and
										localize { type = 'variable', key = 'deck_preview_wheel_plural', vars = { wheel_flipped } } or
										localize { type = 'variable', key = 'deck_preview_wheel_singular', vars = { wheel_flipped } }),
									colour = G.C.WHITE,
									scale = 0.3
								}
							},
						}
					} or nil,
				}
			}
		}
	}
	return t
end

-------------------------------------------------------------------------------------------------
----- API HOOKS GameObject.PokerHand
-------------------------------------------------------------------------------------------------
-- this would be annoying to patch in with lovely
local init_game_object_ref = Game.init_game_object
function Game:init_game_object()
	local t = init_game_object_ref(self)
	for _, key in ipairs(SMODS.PokerHand.obj_buffer) do
		t.hands[key] = {}
		for k, v in pairs(SMODS.PokerHands[key]) do
			-- G.GAME needs to be able to be serialized
			if type(v) == 'number' or type(v) == 'boolean' or k == 'example' then
				t.hands[key][k] = v
			end
		end
	end
	return t
end

-- why bother patching when i basically change everything
function G.FUNCS.get_poker_hand_info(_cards)
	local poker_hands = evaluate_poker_hand(_cards)
	local scoring_hand = {}
	local text, disp_text, loc_disp_text = 'NULL', 'NULL', 'NULL'
	for _, v in ipairs(G.handlist) do
		if next(poker_hands[v]) then
			text = v
			scoring_hand = poker_hands[v][1]
			break
		end
	end
	disp_text = text
	local _hand = SMODS.PokerHands[text]
	if text == 'Straight Flush' then
		local royal = true
		for j = 1, #scoring_hand do
			local rank = SMODS.Ranks[scoring_hand[j].base.value]
			royal = royal and (rank.key == 'Ace' or rank.key == '10' or rank.face)
		end
		if royal then
			disp_text = 'Royal Flush'
		end
	elseif _hand and _hand.modify_display_text and type(_hand.modify_display_text) == 'function' then
		disp_text = _hand:modify_display_text(_cards, scoring_hand) or disp_text
	end
	loc_disp_text = localize(disp_text, 'poker_hands')
	return text, loc_disp_text, poker_hands, scoring_hand, disp_text
end

function create_UIBox_current_hands(simple)
	G.current_hands = {}
	local index = 0
	for _, v in ipairs(G.handlist) do
		local ui_element = create_UIBox_current_hand_row(v, simple)
		G.current_hands[index + 1] = ui_element
		if ui_element then
			index = index + 1
		end
		if index >= 10 then
			break
		end
	end

	local visible_hands = {}
	for _, v in ipairs(G.handlist) do
		if G.GAME.hands[v].visible then
			table.insert(visible_hands, v)
		end
	end

	local hand_options = {}
	for i = 1, math.ceil(#visible_hands / 10) do
		table.insert(hand_options,
			localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_hands / 10)))
	end

	local object = {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.04 },
				nodes = G.current_hands
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0 },
				nodes = {
					create_option_cycle({
						options = hand_options,
						w = 4.5,
						cycle_shoulders = true,
						opt_callback = 'your_hands_page',
						focus_args = { snap_to = true, nav = 'wide' },
						current_option = 1,
						colour = G.C.RED,
						no_pips = true
					})
				}
			}
		}
	}

	local t = {
		n = G.UIT.ROOT,
		config = { align = "cm", minw = 3, padding = 0.1, r = 0.1, colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.O,
				config = {
					id = 'hand_list',
					object = UIBox {
						definition = object,
						config = { offset = { x = 0, y = 0 }, align = 'cm' }
					}
				}
			}
		}
	}
	return t
end

G.FUNCS.your_hands_page = function(args)
	if not args or not args.cycle_config then return end
	G.current_hands = {}


	local index = 0
	for _, v in ipairs(G.handlist) do
		local ui_element = create_UIBox_current_hand_row(v, simple)
		if index >= (0 + 10 * (args.cycle_config.current_option - 1)) and index < 10 * args.cycle_config.current_option then
			G.current_hands[index - (10 * (args.cycle_config.current_option - 1)) + 1] = ui_element
		end

		if ui_element then
			index = index + 1
		end

		if index >= 10 * args.cycle_config.current_option then
			break
		end
	end

	local visible_hands = {}
	for _, v in ipairs(G.handlist) do
		if G.GAME.hands[v].visible then
			table.insert(visible_hands, v)
		end
	end

	local hand_options = {}
	for i = 1, math.ceil(#visible_hands / 10) do
		table.insert(hand_options,
			localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_hands / 10)))
	end

	local object = {
		n = G.UIT.ROOT,
		config = { align = "cm", colour = G.C.CLEAR },
		nodes = {
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0.04 },
				nodes = G.current_hands
			},
			{
				n = G.UIT.R,
				config = { align = "cm", padding = 0 },
				nodes = {
					create_option_cycle({
						options = hand_options,
						w = 4.5,
						cycle_shoulders = true,
						opt_callback =
						'your_hands_page',
						focus_args = { snap_to = true, nav = 'wide' },
						current_option = args.cycle_config.current_option,
						colour = G
							.C.RED,
						no_pips = true
					})
				}
			}
		}
	}

	local hand_list = G.OVERLAY_MENU:get_UIE_by_ID('hand_list')
	if hand_list then
		if hand_list.config.object then
			hand_list.config.object:remove()
		end
		hand_list.config.object = UIBox {
			definition = object,
			config = { offset = { x = 0, y = 0 }, align = 'cm', parent = hand_list }
		}
	end
end


-------------------------------------------------------------------------------------------------
----- API HOOKS GameObject.Edition
-------------------------------------------------------------------------------------------------

function create_UIBox_your_collection_editions(exit)
    local deck_tables = {}
    local rows, cols = (#G.P_CENTER_POOLS.Edition > 5 and 2 or 1), 5
    local page = 0

    G.your_collection = {}
    for j = 1, rows do
        G.your_collection[j] = CardArea(G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h, 5.3 * G.CARD_W, 1.03 * G.CARD_H,
            {
                card_limit = cols,
                type = 'title',
                highlight_limit = 0,
                collection = true
            })
        table.insert(deck_tables, { n = G.UIT.R, config = { align = "cm", padding = 0, no_fill = true },
            nodes = {{ n = G.UIT.O, config = { object = G.your_collection[j] } }}
        })
    end

	table.sort(G.P_CENTER_POOLS.Edition, function(a,b) return a.order < b.order end)

    local count = math.min(cols * rows, #G.P_CENTER_POOLS["Edition"])
    local index = 1 + (rows * cols * page)
    for j = 1, rows do
        for i = 1, cols do

            local center = G.P_CENTER_POOLS.Edition[index]

            if not center then
                break
            end
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y,
                G.CARD_W, G.CARD_H, nil, center)
            card:start_materialize(nil, i > 1 or j > 1)
            card:set_edition(center.key, true, true)
            G.your_collection[j]:emplace(card)
            index = index + 1
        end
        if index > count then
            break
        end
    end

    local edition_options = {}

    local t = create_UIBox_generic_options({
        infotip = localize('ml_edition_seal_enhancement_explanation'), back_func = exit or 'your_collection', snap_back = true,
        contents = {{ n = G.UIT.R, config = { align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
            nodes = deck_tables }}
    })

    if #G.P_CENTER_POOLS["Edition"] > rows * cols then
        for i = 1, math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols)) do
            table.insert(edition_options, localize('k_page') .. ' ' .. tostring(i) .. '/' ..
                tostring(math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols))))
        end
        t = create_UIBox_generic_options({ infotip = localize('ml_edition_seal_enhancement_explanation'), back_func = exit or 'your_collection', snap_back = true,
            contents = {{ n = G.UIT.R, config = { align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 },
                nodes = deck_tables
            }, { n = G.UIT.R, config = { align = "cm" },
                nodes = {create_option_cycle({
                    options = edition_options,
                    w = 4.5,
                    cycle_shoulders = true,
                    opt_callback = 'your_collection_editions_page',
                    focus_args = { snap_to = true, nav = 'wide' },
                    current_option = 1,
                    r = rows,
                    c = cols,
                    colour = G.C.RED,
                    no_pips = true
                })}
            }}
        })
    end
    return t
end

G.FUNCS.your_collection_editions_page = function(args)
    if not args or not args.cycle_config then
        return
    end
    local rows = (#G.P_CENTER_POOLS.Edition > 5 and 2 or 1), 5
    local cols = 5
    local page = args.cycle_config.current_option
    if page > math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols)) then
        page = page - math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols))
    end
    local count = rows * cols
    local offset = (rows * cols) * (page - 1)

    for j = 1, #G.your_collection do
        for i = #G.your_collection[j].cards, 1, -1 do
            if G.your_collection[j] ~= nil then
                local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
                c:remove()
                c = nil
            end
        end
    end

    for j = 1, rows do
        for i = 1, cols do
            if count % rows > 0 and i <= count % rows and j == cols then
                offset = offset - 1
                break
            end
            local idx = i + (j - 1) * cols + offset
            if idx > #G.P_CENTER_POOLS["Edition"] then return end
            local center = G.P_CENTER_POOLS["Edition"][idx]
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y,
                G.CARD_W, G.CARD_H, G.P_CARDS.empty, center)
            card:set_edition(center.key, true, true)
            card:start_materialize(nil, i > 1 or j > 1)
            G.your_collection[j]:emplace(card)
        end
    end
end

-- self = pass the card
-- edition =
-- nil (removes edition)
-- OR key as string
-- OR { name_of_edition = true } (key without e_). This is from the base game, prefer using a string.
-- OR another card's self.edition table
-- immediate = boolean value
-- silent = boolean value
function Card.set_edition(self, edition, immediate, silent)
	-- Check to see if negative is being removed and reduce card_limit accordingly
	if (self.added_to_deck or self.area == G.hand) and self.edition and self.edition.card_limit then
		if self.ability.consumeable and self.area == G.consumeables then
			G.consumeables.config.card_limit = G.consumeables.config.card_limit - self.edition.card_limit
		elseif self.ability.set == 'Joker' and self.area == G.jokers then
			G.jokers.config.card_limit = G.jokers.config.card_limit - self.edition.card_limit
		elseif self.area == G.hand then
			G.hand.config.card_limit = G.hand.config.card_limit - self.edition.card_limit
		end
	end
	
	local edition_type = nil
	if type(edition) == 'string' then
		assert(string.sub(edition, 1, 2) == 'e_')
		edition_type = string.sub(edition, 3)
	elseif type(edition) == 'table' then
		if edition.type then
			edition_type = edition.type
		else
			for k, v in pairs(edition) do
				if v then
					assert(not edition_type)
					edition_type = k
				end
			end
		end
	end
	
	if not edition_type or edition_type == 'base' then
		if self.edition == nil then -- early exit
			return
		end
		self.edition = nil -- remove edition from card
		self:set_cost()
		if not silent then
			G.E_MANAGER:add_event(Event({
				trigger = 'after',
				delay = not immediate and 0.2 or 0,
				blockable = not immediate,
				func = function()
					self:juice_up(1, 0.5)
					play_sound('whoosh2', 1.2, 0.6)
					return true
				end
			}))
		end
        return
    end
    
	self.edition = {}
	self.edition[edition_type] = true
	self.edition.type = edition_type
	self.edition.key = 'e_'..edition_type

	for k, v in pairs(G.P_CENTERS['e_'..edition_type].config) do
		if type(v) == 'table' then
			self.edition[k] = copy_table(v)
		else
			self.edition[k] = v
		end
		if k == 'card_limit' and (self.added_to_deck or self.area == G.hand) and G.jokers and G.consumeables then
			if self.ability.consumeable then
				G.consumeables.config.card_limit = G.consumeables.config.card_limit + v
			elseif self.ability.set == 'Joker' then
				G.jokers.config.card_limit = G.jokers.config.card_limit + v
			elseif self.area == G.hand and not (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) then
			    G.hand.config.card_limit = G.hand.config.card_limit + v
			    G.E_MANAGER:add_event(Event({
			        trigger = 'immediate',
			        func = function()
			            G.FUNCS.draw_from_deck_to_hand()
			            return true
			        end
			    }))
			end
		end
	end

    if self.area and self.area == G.jokers then 
        if self.edition then
            if not G.P_CENTERS['e_'..(self.edition.type)].discovered then 
                discover_card(G.P_CENTERS['e_'..(self.edition.type)])
            end
        else
            if not G.P_CENTERS['e_base'].discovered then 
                discover_card(G.P_CENTERS['e_base'])
            end
        end
    end

    if self.edition and not silent then
        G.CONTROLLER.locks.edition = true
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = not immediate and 0.2 or 0,
            blockable = not immediate,
            func = function()
                self:juice_up(1, 0.5)
				local ed = G.P_CENTERS['e_'..(self.edition.type)]
                play_sound(ed.sound.sound, ed.sound.per, ed.sound.vol)
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                G.CONTROLLER.locks.edition = false
                return true
            end
        }))
    end

	if G.jokers and self.area == G.jokers then 
        check_for_unlock({type = 'modify_jokers'})
    end

    self:set_cost()

end


-- _key = key value for random seed
-- _mod = scale of chance against base card (does not change guaranteed weights)
-- _no_neg = boolean value to disable negative edition
-- _guaranteed = boolean value to determine whether an edition is guaranteed
-- _options = list of keys of editions to include in the poll
-- OR list of tables { name = key, weight = number }
function poll_edition(_key, _mod, _no_neg, _guaranteed, _options)
    local _modifier = 1
    local edition_poll = pseudorandom(pseudoseed(_key or 'edition_generic')) -- Generate the poll value
	local available_editions = {} -- Table containing a list of editions and their weights

	if not _options then
		_options = {'e_negative', 'e_polychrome', 'e_holo', 'e_foil'}
		if _key == "wheel_of_fortune" or _key == "aura" then -- set base game edition polling
		else
			for _,v in ipairs(G.P_CENTER_POOLS.Edition) do
				if v.in_shop then
					sendDebugMessage(v.key)
					table.insert(_options, v.key)
				end
			end
		end
	end
	for _,v in ipairs(_options) do
		local edition_option = {}
		if type(v) == 'string' then
			assert(string.sub(v, 1, 2) == 'e_')
			edition_option = { name = v, weight = G.P_CENTERS[v].weight }
		elseif type(v) == 'table' then
			assert(string.sub(v.name, 1, 2) == 'e_')
			edition_option = { name = v.name, weight = v.weight }
		end
		table.insert(available_editions, edition_option)
	end

    -- Calculate total weight of editions
    local total_weight = 0
    for _,v in ipairs(available_editions) do
		total_weight = total_weight + (v.weight) -- total all the weights of the polled editions
    end
    -- sendDebugMessage("Edition weights: "..total_weight, "EditionAPI")
    -- If not guaranteed, calculate the base card rate to maintain base 4% chance of editions
    if not _guaranteed then
        _modifier = _mod or 1
        total_weight = total_weight + (total_weight / 4 * 96)  -- Find total weight with base_card_rate as 96%
		for _,v in ipairs(available_editions) do
			v.weight = G.P_CENTERS[v.name]:get_weight() -- Apply game modifiers where appropriate (defined in edition declaration)
		end
    
    end
    -- sendDebugMessage("Total weight: "..total_weight, "EditionAPI")
    -- sendDebugMessage("Editions: "..#available_editions, "EditionAPI")
    -- sendDebugMessage("Poll: "..edition_poll, "EditionAPI")
    
    -- Calculate whether edition is selected
    local weight_i = 0
    for _,v in ipairs(available_editions) do
		weight_i = weight_i + v.weight*_modifier
		-- sendDebugMessage(v.name.." weight is "..v.weight*_modifier)
		-- sendDebugMessage("Checking for "..v.name.." at "..(1 - (weight_i)/total_weight), "EditionAPI")
		if edition_poll > 1 - (weight_i)/total_weight then
			if not (v.name == 'e_negative' and _no_neg) then -- skip return if negative is selected and _no_neg is true
				-- sendDebugMessage("Matched edition: "..v.name, "EditionAPI")
				return v.name
			end
		end
	end

    return nil
end


-------------------------------------------------------------------------------------------------
----- API HOOKS GameObject.Palette
-------------------------------------------------------------------------------------------------
G.SETTINGS.selected_colours = G.SETTINGS.selected_colours or {}
G.SEND_TO_SHADER = {}

G.FUNCS.update_recolor = function(args)
    G.SETTINGS.selected_colours[args.cycle_config.type] = SMODS.Palettes[args.cycle_config.type][args.to_val]
    G:save_settings()
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