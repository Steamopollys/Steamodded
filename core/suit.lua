-- ----------------------------------------------
-- ------------MOD CORE API CARDS----------------
SMODS.Card = {}
SMODS.Card.SUIT_LIST = { 'Spades', 'Hearts', 'Clubs', 'Diamonds' }
SMODS.Card.SUITS = {
	["Hearts"] = {
		name = 'Hearts',
		prefix = 'H',
		suit_nominal = 0.03,
		ui_pos = { x = 0, y = 1 },
		card_pos = { y = 0 },
	},
	["Diamonds"] = {
		name = 'Diamonds',
		prefix = 'D',
		suit_nominal = 0.01,
		ui_pos = { x = 1, y = 1 },
		card_pos = { y = 2 },
	},
	["Clubs"] = {
		name = 'Clubs',
		prefix = 'C',
		suit_nominal = 0.02,
		ui_pos = { x = 2, y = 1 },
		card_pos = { y = 1 },
	},
	["Spades"] = {
		name = 'Spades',
		prefix = 'S',
		suit_nominal = 0.04,
		ui_pos = { x = 3, y = 1 },
		card_pos = { y = 3 }
	},
}
SMODS.Card.MAX_SUIT_NOMINAL = 0.04
SMODS.Card.RANKS = {
	['2'] = { value = '2', pos = { x = 0 }, id = 2, nominal = 2, next = { '3' } },
	['3'] = { value = '3', pos = { x = 1 }, id = 3, nominal = 3, next = { '4' } },
	['4'] = { value = '4', pos = { x = 2 }, id = 4, nominal = 4, next = { '5' } },
	['5'] = { value = '5', pos = { x = 3 }, id = 5, nominal = 5, next = { '6' } },
	['6'] = { value = '6', pos = { x = 4 }, id = 6, nominal = 6, next = { '7' } },
	['7'] = { value = '7', pos = { x = 5 }, id = 7, nominal = 7, next = { '8' } },
	['8'] = { value = '8', pos = { x = 6 }, id = 8, nominal = 8, next = { '9' } },
	['9'] = { value = '9', pos = { x = 7 }, id = 9, nominal = 9, next = { '10' } },
	['10'] = { suffix = 'T', value = '10', pos = { x = 8 }, id = 10, nominal = 10, next = { 'Jack' } },
	['Jack'] = { suffix = 'J', value = 'Jack', pos = { x = 9 }, id = 11, nominal = 10, face_nominal = 0.1, face = true, next = { 'Queen' }, shorthand = 'J' },
	['Queen'] = { suffix = 'Q', value = 'Queen', pos = { x = 10 }, id = 12, nominal = 10, face_nominal = 0.2, face = true, next = { 'King' }, shorthand = 'Q' },
	['King'] = { suffix = 'K', value = 'King', pos = { x = 11 }, id = 13, nominal = 10, face_nominal = 0.3, face = true, next = { 'Ace', shorthand = 'K' } },
	['Ace'] = { suffix = 'A', value = 'Ace', pos = { x = 12 }, id = 14, nominal = 11, face_nominal = 0.4, next = { '2' }, straight_edge = true, shorthand = 'A' }
}
SMODS.Card.RANK_LIST = { '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A' }
SMODS.Card.RANK_SHORTHAND_LOOKUP = {
	['J'] = 'Jack',
	['Q'] = 'Queen',
	['K'] = 'King',
	['A'] = 'Ace',
}
SMODS.Card.MAX_ID = 14
function SMODS.Card.generate_prefix()
	local permutations
	permutations = function(list, len)
		len = len or 2
		if len <= 1 then return list end
		local t = permutations(list, len - 1)
		local o = {}
		for _, a in ipairs(list) do
			for _, b in ipairs(t) do
				table.insert(o, a .. b)
			end
		end
		return o
	end
	local possible_prefixes = { 'A', 'B', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'T', 'U', 'V',
		'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
		't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9' }
	local perm = permutations(possible_prefixes, 2)
	for _, a in ipairs(perm) do
		table.insert(possible_prefixes, a)
	end
	for _, v in pairs(SMODS.Card.SUITS) do
		for i, vv in ipairs(possible_prefixes) do
			if v.prefix == vv then
				table.remove(possible_prefixes, i)
			end
		end
	end
	return possible_prefixes[1]
end

function SMODS.Card.generate_suffix()
	local permutations
	permutations = function(list, len)
		len = len or 2
		if len <= 1 then return list end
		local t = permutations(list, len - 1)
		local o = {}
		for _, a in ipairs(list) do
			for _, b in ipairs(t) do
				table.insert(o, a .. b)
			end
		end
		return o
	end
	local possible_suffixes = { 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'L', 'M', 'N', 'O', 'P', 'R', 'S', 'T', 'U', 'V',
		'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
        't', 'u', 'v', 'w', 'x', 'y', 'z' }
	local perm = permutations(possible_suffixes, 2)
	for _, a in ipairs(perm) do
		table.insert(possible_suffixes, a)
	end
	for _, v in pairs(SMODS.Card.RANKS) do
		for i, vv in ipairs(possible_suffixes) do
			if v.suffix == vv then
				table.remove(possible_suffixes, i)
			end
		end
	end
	return possible_suffixes[1]
end

function SMODS.Card:new_suit(name, card_atlas_low_contrast, card_atlas_high_contrast, card_pos, ui_atlas_low_contrast,
							 ui_atlas_high_contrast, ui_pos, colour_low_contrast, colour_high_contrast, create_cards)
	if SMODS.Card.SUITS[name] then
		sendDebugMessage('Failed to register duplicate suit:' .. name)
		return nil
	end
	local prefix = SMODS.Card.generate_prefix()
	if not prefix then
		sendDebugMessage('Too many suits! Failed to assign valid prefix to:' .. name)
	end
	SMODS.Card.MAX_SUIT_NOMINAL = SMODS.Card.MAX_SUIT_NOMINAL + 0.01
	create_cards = not (create_cards == false)
	SMODS.Card.SUITS[name] = {
		name = name,
		prefix = prefix,
		suit_nominal = SMODS.Card.MAX_SUIT_NOMINAL,
		card_atlas_low_contrast = card_atlas_low_contrast,
		card_atlas_high_contrast = card_atlas_high_contrast,
		card_pos = { y = card_pos.y },
		ui_atlas_low_contrast = ui_atlas_low_contrast,
		ui_atlas_high_contrast = ui_atlas_high_contrast,
		ui_pos = ui_pos,
		disabled = not create_cards or nil
	}
	SMODS.Card.SUIT_LIST[#SMODS.Card.SUIT_LIST + 1] = name
	colour_low_contrast = colour_low_contrast or '000000'
	colour_high_contrast = colour_high_contrast or '000000'
	if not (type(colour_low_contrast) == 'table') then colour_low_contrast = HEX(colour_low_contrast) end
	if not (type(colour_high_contrast) == 'table') then colour_high_contrast = HEX(colour_high_contrast) end
	G.C.SO_1[name] = colour_low_contrast
	G.C.SO_2[name] = colour_high_contrast
	G.C.SUITS[name] = G.C["SO_" .. (G.SETTINGS.colourblind_option and 2 or 1)][name]
	G.localization.misc['suits_plural'][name] = name
	G.localization.misc['suits_singular'][name] = name:match("(.+)s$")
	if create_cards then
		SMODS.Card:populate_suit(name)
	end
	return SMODS.Card.SUITS[name]
end

-- DELETES ALL DATA ASSOCIATED WITH THE PROVIDED SUIT EXCEPT LOCALIZATION
function SMODS.Card:delete_suit(name)
	local suit_data = SMODS.Card.SUITS[name]
	if not suit_data then
		sendWarnMessage('Tried to delete non-existent suit: ' .. name, 'PlayingCardAPI')
		return false
	end
	local prefix = suit_data.prefix
	for _, v in pairs(SMODS.Card.RANKS) do
		G.P_CARDS[prefix .. '_' .. (v.suffix or v.value)] = nil
	end
	local i
	for j, v in ipairs(SMODS.Card.SUIT_LIST) do if v == suit_data.name then i = j end end
	table.remove(SMODS.Card.SUIT_LIST, i)
	SMODS.Card.SUITS[name] = nil
	return true
end

-- Deletes the playing cards of the provided suit from G.P_CARDS
function SMODS.Card:wipe_suit(name)
	local suit_data = SMODS.Card.SUITS[name]
	if not suit_data then
		sendWarnMessage('Tried to wipe non-existent suit: ' .. name, 'PlayingCardAPI')
		return false
	end
	local prefix = suit_data.prefix
	for _, v in pairs(SMODS.Card.RANKS) do
		G.P_CARDS[prefix .. '_' .. (v.suffix or v.value)] = nil
	end
	SMODS.Card.SUITS[name].disabled = true
	return true
end

-- Populates G.P_CARDS with cards of all ranks and the given suit
function SMODS.Card:populate_suit(name)
	local suit_data = SMODS.Card.SUITS[name]
	if not suit_data then
		sendWarnMessage('Tried to populate non-existent suit: ' .. name, 'PlayingCardAPI')
		return false
	end
	for _, v in pairs(SMODS.Card.RANKS) do
		if not v.disabled then
			G.P_CARDS[suit_data.prefix .. '_' .. (v.suffix or v.value)] = {
				name = v.value .. ' of ' .. name,
				value = v.value,
				suit = name,
				pos = { x = v.pos.x, y = (v.suit_map and v.suit_map[name]) and v.suit_map[name].y or suit_data.card_pos.y },
				card_atlas_low_contrast = (v.atlas_low_contrast and v.suit_map and v.suit_map[name]) and v
					.atlas_low_contrast or suit_data.card_atlas_low_contrast,
				card_atlas_high_contrast = (v.atlas_low_contrast and v.suit_map and v.suit_map[name]) and
					v.atlas_high_contrast or suit_data.card_atlas_high_contrast,
			}
		end
	end
	SMODS.Card.SUITS[name].disabled = nil
	return true
end

function SMODS.Card:new_rank(value, nominal, atlas_low_contrast, atlas_high_contrast, pos, suit_map, options,
							 create_cards)
	options = options or {}
	if SMODS.Card.RANKS[value] then
		sendWarnMessage('Failed to register duplicate rank: ' .. value, 'PlayingCardAPI')
		return nil
	end
	local suffix = SMODS.Card:generate_suffix()
	if not suffix then
		sendWarnMessage('Too many ranks! Failed to assign valid suffix to: ' .. value, 'PlayingCardAPI')
		return nil
	end
	SMODS.Card.MAX_ID = SMODS.Card.MAX_ID + 1
	create_cards = not (create_cards == false)
	local shorthand =
		options.shorthand.unique or
		options.shorthand.length and string.sub(value, 1, options.shorthand.length) or
		string.sub(value, 1, 1)
	SMODS.Card.RANK_LIST[#SMODS.Card.RANK_LIST + 1] = shorthand
    SMODS.Card.RANK_SHORTHAND_LOOKUP[shorthand] = value
	SMODS.Card.RANKS[value] = {
		value = value,
		suffix = suffix,
		pos = { x = pos.x },
		id = SMODS.Card.MAX_ID,
		nominal = nominal,
		atlas_low_contrast = atlas_low_contrast,
		atlas_high_contrast = atlas_high_contrast,
		suit_map = suit_map,
		face = options.face,
		face_nominal = options.face_nominal,
		strength_effect = options.strength_effect or {
			fixed = 1,
			random = false,
			ignore = false
		},
		next = options.next,
		straight_edge = options.straight_edge,
		disabled = not create_cards or nil,
		shorthand = shorthand,
    }
	local function nominal(v) 
        local rank_data = SMODS.Card.RANKS[SMODS.Card.RANK_SHORTHAND_LOOKUP[v] or v]
		return rank_data.nominal + (rank_data.face_nominal or 0)
	end
	table.sort(SMODS.Card.RANK_LIST, function(a, b) return nominal(a) < nominal(b) end)
	if create_cards then
		SMODS.Card:populate_rank(value)
	end
	G.localization.misc['ranks'][value] = value
	return SMODS.Card.RANKS[value]
end

-- DELETES ALL DATA ASSOCIATED WITH THE PROVIDED RANK EXCEPT LOCALIZATION
function SMODS.Card:delete_rank(value)
	local rank_data = SMODS.Card.RANKS[value]
	if not rank_data then
		sendWarnMessage('Tried to delete non-existent rank: ' .. value, 'PlayingCardAPI')
		return false
	end
	local suffix = rank_data.suffix or rank_data.value
	for _, v in pairs(SMODS.Card.SUITS) do
		G.P_CARDS[v.prefix .. '_' .. suffix] = nil
	end
	local i
    for j, v in ipairs(SMODS.Card.RANK_LIST) do if v == rank_data.shorthand or v == rank_data.value then i = j end end
	table.remove(SMODS.Card.RANK_LIST, i)
	SMODS.Card.RANKS[value] = nil
	return true
end

-- Deletes the playing cards of the provided rank from G.P_CARDS
function SMODS.Card:wipe_rank(value)
	local rank_data = SMODS.Card.RANKS[value]
	if not rank_data then
		sendWarnMessage('Tried to wipe non-existent rank: ' .. value, 'PlayingCardAPI')
		return false
	end
	local suffix = rank_data.suffix or rank_data.value
	for _, v in pairs(SMODS.Card.SUITS) do
		G.P_CARDS[v.prefix .. '_' .. suffix] = nil
	end
	SMODS.Card.RANKS[value].disabled = true
	return true
end

-- Populates G.P_CARDS with cards of all suits and the provided rank
function SMODS.Card:populate_rank(value)
	local rank_data = SMODS.Card.RANKS[value]
	if not rank_data then
		sendWarnMessage('Tried to populate non-existent rank: ' .. value, 'PlayingCardAPI')
		return false
	end
	local suffix = rank_data.suffix or rank_data.value
	for k, v in pairs(SMODS.Card.SUITS) do
		if not v.disabled then
			if rank_data.suit_map[k] then
				G.P_CARDS[v.prefix .. '_' .. suffix] = {
					name = value .. ' of ' .. v.name,
					value = value,
					pos = { x = rank_data.pos.x, y = rank_data.suit_map[k].y or v.card_pos.y },
					suit = v.name,
					card_atlas_low_contrast = rank_data.atlas_low_contrast,
					card_atlas_high_contrast = rank_data.atlas_high_contrast
				}
			else
				-- blank sprite
				G.P_CARDS[v.prefix .. '_' .. suffix] = {
					name = value .. ' of ' .. v.name,
					value = value,
					suit = v.name,
					pos = { x = 0, y = 5 }
				}
			end
		end
	end
	SMODS.Card.RANKS[value].disabled = nil
	return true
end

function SMODS.Card:new(suit, value, name, pos, atlas_low_contrast, atlas_high_contrast)
	local suit_data = SMODS.Card.SUITS[suit]
	local rank_data = SMODS.Card.RANKS[value]
	if not suit_data then
		sendWarnMessage('Suit does not exist: ' .. suit, 'PlayingCardAPI')
		return nil
	elseif not rank_data then
		sendWarnMessage('Rank does not exist: ' .. value, 'PlayingCardAPI')
		return nil
	end
	G.P_CARDS[suit_data.prefix .. '_' .. (rank_data.suffix or rank_data.value)] = {
		name = name or (value .. ' of ' .. suit),
		suit = suit,
		value = value,
		pos = pos or { x = rank_data.pos.x, y = suit_data.card_pos.y },
		card_atlas_low_contrast = atlas_low_contrast or rank_data.atlas_low_contrast or suit_data.atlas_low_contrast,
		card_atlas_high_contrast = atlas_high_contrast or rank_data.atlas_high_contrast or suit_data.atlas_high_contrast
	}
	return G.P_CARDS[suit_data.prefix .. '_' .. (rank_data.suffix or rank_data.value)]
end

function SMODS.Card:remove(suit, value)
	local suit_data = SMODS.Card.SUITS[suit]
	local rank_data = SMODS.Card.RANKS[value]
	if not suit_data then
		sendWarnMessage('Suit does not exist: ' .. suit, 'PlayingCardAPI')
		return false
	elseif not rank_data then
		sendWarnMessage('Rank does not exist: ' .. value, 'PlayingCardAPI')
		return false
	elseif not G.P_CARDS[suit_data.prefix .. '_' .. (rank_data.suffix or rank_data.value)] then
		sendWarnMessage('Card not found at index: ' .. suit_data.prefix .. '_' .. (rank_data.suffix or rank_data.value), 'PlayingCardAPI')
		return false
	end
	G.P_CARDS[suit_data.prefix .. '_' .. (rank_data.suffix or rank_data.value)] = nil
	return true
end

function SMODS.Card:_extend()
	local Game_init_game_object = Game.init_game_object
	function Game:init_game_object()
		local t = Game_init_game_object(self)
		t.cards_played = {}
		for k, v in pairs(SMODS.Card.RANKS) do
			t.cards_played[k] = { suits = {}, total = 0 }
		end
		return t
	end

	local loc_colour_ref = loc_colour
	function loc_colour(_c, _default)
		loc_colour_ref(_c, _default)
		for k, c in pairs(G.C.SUITS) do
			G.ARGS.LOC_COLOURS[k:lower()] = c
		end
		return G.ARGS.LOC_COLOURS[_c] or _default or G.C.UI.TEXT_DARK
	end

	function get_flush(hand)
		local ret = {}
		local four_fingers = next(find_joker('Four Fingers'))
		local suits = SMODS.Card.SUIT_LIST
		if #hand < (5 - (four_fingers and 1 or 0)) then
			return ret
		else
			for j = 1, #suits do
				local t = {}
				local suit = suits[j]
				local flush_count = 0
				for i = 1, #hand do
					if hand[i]:is_suit(suit, nil, true) then
						flush_count = flush_count + 1
						t[#t + 1] = hand[i]
					end
				end
				if flush_count >= (5 - (four_fingers and 1 or 0)) then
					table.insert(ret, t)
					return ret
				end
			end
			return {}
		end
	end

	function get_straight(hand)
		local ret = {}
		local four_fingers = next(find_joker('Four Fingers'))
		local can_skip = next(find_joker('Shortcut'))
		if #hand < (5 - (four_fingers and 1 or 0)) then return ret end
		local t = {}
		local RANKS = {}
		for i = 1, #hand do
			local rank = hand[i].base.value
			if RANKS[rank] then
				RANKS[rank][#RANKS[rank] + 1] = hand[i]
			else
				RANKS[rank] = { hand[i] }
			end
		end
		local straight_length = 0
		local straight = false
		local skipped_rank = false
		local vals = {}
		for k, v in pairs(SMODS.Card.RANKS) do
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
			if br or (i > #SMODS.Card.RANK_LIST + 1) then break end
			if not next(vals) then break end
			for _, val in ipairs(vals) do
				if init_vals[val] and not initial then br = true end
				if RANKS[val] then
					straight_length = straight_length + 1
					skipped_rank = false
					for _, vv in ipairs(RANKS[val]) do
						t[#t + 1] = vv
					end
					vals = SMODS.Card.RANKS[val].next
					initial = false
					end_iter = true
					break
				end
			end
			if not end_iter then
				local new_vals = {}
				for _, val in ipairs(vals) do
					for _, r in ipairs(SMODS.Card.RANKS[val].next) do
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

    function get_X_same(num, hand)
        local vals = {}
        for i = 1, SMODS.Card.MAX_ID do
            vals[i] = {}
        end
        for i = #hand, 1, -1 do
            local curr = {}
            table.insert(curr, hand[i])
            for j = 1, #hand do
                if hand[i]:get_id() == hand[j]:get_id() and i ~= j then
                    table.insert(curr, hand[j])
                end
            end
            if #curr == num then
                vals[curr[1]:get_id()] = curr
            end
        end
        local ret = {}
        for i = #vals, 1, -1 do
            if next(vals[i]) then table.insert(ret, vals[i]) end
        end
        return ret
    end
	
	function Card:get_nominal(mod)
		local mult = 1
		if mod == 'suit' then mult = 10000 end
		if self.ability.effect == 'Stone Card' then mult = -10000 end
		return 10*self.base.nominal + self.base.suit_nominal*mult + (self.base.suit_nominal_original or 0)*0.0001*mult + 10*self.base.face_nominal + 0.000001*self.unique_val
	end

	function G.UIDEF.view_deck(unplayed_only)
		local deck_tables = {}
		remove_nils(G.playing_cards)
		G.VIEWING_DECK = true
		table.sort(G.playing_cards, function(a, b) return a:get_nominal('suit') > b:get_nominal('suit') end)
		local suit_list = SMODS.Card.SUIT_LIST
		local SUITS = {}
		for _, v in ipairs(suit_list) do
			SUITS[v] = {}
		end
		for k, v in ipairs(G.playing_cards) do
			table.insert(SUITS[v.base.suit], v)
		end
		local num_suits = 0
		for j = 1, #suit_list do
			if SUITS[suit_list[j]][1] then num_suits = num_suits + 1 end
		end
		for j = 1, #suit_list do
			if SUITS[suit_list[j]][1] then
				local view_deck = CardArea(
					G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
					6.5 * G.CARD_W,
					((num_suits > 8) and 0.2 or (num_suits > 4) and (1 - 0.1 * num_suits) or 0.6) * G.CARD_H,
					{
						card_limit = #SUITS[suit_list[j]],
						type = 'title',
						view_deck = true,
						highlight_limit = 0,
						card_w = G.CARD_W * 0.6,
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

				for i = 1, #SUITS[suit_list[j]] do
					if SUITS[suit_list[j]][i] then
						local greyed, _scale = nil, 0.7
						if unplayed_only and not ((SUITS[suit_list[j]][i].area and SUITS[suit_list[j]][i].area == G.deck) or SUITS[suit_list[j]][i].ability.wheel_flipped) then
							greyed = true
						end
						local copy = copy_card(SUITS[suit_list[j]][i], nil, _scale)
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
		for _, v in ipairs(suit_list) do
			suit_tallies[v] = 0
			mod_suit_tallies[v] = 0
		end
		local rank_tallies = {}
		local mod_rank_tallies = {}
        local rank_name_mapping = SMODS.Card.RANK_LIST
		local id_index_mapping = {}
        for i, v in ipairs(SMODS.Card.RANK_LIST) do
			local rank_data = SMODS.Card.RANKS[SMODS.Card.RANK_SHORTHAND_LOOKUP[v] or v]
			id_index_mapping[rank_data.id] = i
			rank_tallies[i] = 0
			mod_rank_tallies[i] = 0
		end
		local face_tally = 0
		local mod_face_tally = 0
		local num_tally = 0
		local mod_num_tally = 0
		local ace_tally = 0
		local mod_ace_tally = 0
		local wheel_flipped = 0

		for _, v in ipairs(G.playing_cards) do
			if v.ability.name ~= 'Stone Card' and (not unplayed_only or ((v.area and v.area == G.deck) or v.ability.wheel_flipped)) then
				if v.ability.wheel_flipped and unplayed_only then wheel_flipped = wheel_flipped + 1 end
				--For the suits
				suit_tallies[v.base.suit] = (suit_tallies[v.base.suit] or 0) + 1
				for kk, vv in pairs(mod_suit_tallies) do
					mod_suit_tallies[kk] = (vv or 0) + (v:is_suit(kk) and 1 or 0)
				end

				--for face cards/numbered cards/aces
				local card_id = v:get_id()
				face_tally = face_tally + ((SMODS.Card.RANKS[v.base.value].face) and 1 or 0)
				mod_face_tally = mod_face_tally + (v:is_face() and 1 or 0)
				if not SMODS.Card.RANKS[v.base.value].face and card_id ~= 14 then
					num_tally = num_tally + 1
					if not v.debuff then mod_num_tally = mod_num_tally + 1 end
				end
				if card_id == 14 then
					ace_tally = ace_tally + 1
					if not v.debuff then mod_ace_tally = mod_ace_tally + 1 end
				end

				--ranks
				rank_tallies[id_index_mapping[card_id]] = rank_tallies[id_index_mapping[card_id]] + 1
				if not v.debuff then mod_rank_tallies[id_index_mapping[card_id]] = mod_rank_tallies[id_index_mapping[card_id]] + 1 end
			end
		end

		local modded = (face_tally ~= mod_face_tally)
		for kk, vv in pairs(mod_suit_tallies) do
			if vv ~= suit_tallies[kk] then modded = true end
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
							{ n = G.UIT.T, config = { text = rank_name_mapping[i], colour = G.C.JOKER_GREY, scale = 0.35, shadow = true } },
						}
					},
					{
						n = G.UIT.C,
						config = { align = "cr", minw = 0.4 },
						nodes = {
							mod_delta and
							{ n = G.UIT.O, config = { object = DynaText({ string = { { string = '' .. rank_tallies[i], colour = flip_col }, { string = '' .. mod_rank_tallies[i], colour = G.C.BLUE } }, colours = { G.C.RED }, scale = 0.4, y_offset = -2, silent = true, shadow = true, pop_in_rate = 10, pop_delay = 4 }) } } or
							{ n = G.UIT.T, config = { text = rank_tallies[i] or 'NIL', colour = flip_col, scale = 0.45, shadow = true } },
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
		for i = 1, #suit_list, 2 do
			local n = {
				n = G.UIT.R,
				config = { align = "cm", minh = 0.05, padding = 0.1 },
				nodes = {
					tally_sprite(SMODS.Card.SUITS[suit_list[i]].ui_pos,
						{ { string = '' .. suit_tallies[suit_list[i]], colour = flip_col }, { string = '' .. mod_suit_tallies[suit_list[i]], colour = G.C.BLUE } },
						{ localize(suit_list[i], 'suits_plural') },
						suit_list[i]),
					suit_list[i + 1] and tally_sprite(SMODS.Card.SUITS[suit_list[i + 1]].ui_pos,
						{ { string = '' .. suit_tallies[suit_list[i + 1]], colour = flip_col }, { string = '' .. mod_suit_tallies[suit_list[i + 1]], colour = G.C.BLUE } },
						{ localize(suit_list[i + 1], 'suits_plural') },
						suit_list[i + 1]) or nil,
				}
			}
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
										{
											n = G.UIT.R,
											config = { align = "cm", r = 0.1, outline_colour = G.C.L_BLACK, line_emboss = 0.05, outline = 1.5 },
											nodes = tally_ui
										}
									}
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

	local UIDEF_challenge_description_tab_ref = G.UIDEF.challenge_description_tab
	function G.UIDEF.challenge_description_tab(args)
		if args._tab == 'Deck' then
			local challenge = G.CHALLENGES[args._id]
			local deck_tables = {}
			local SUITS = {}
			for _, v in pairs(SMODS.Card.SUITS) do
				SUITS[v.prefix] = {}
			end
			local suit_map = {}
			for i, v in ipairs(SMODS.Card.SUIT_LIST) do
				table.insert(suit_map, SMODS.Card.SUITS[v].prefix)
			end
			local card_protos = nil
			local _de = nil
			if challenge then
				_de = challenge.deck
			end

			if _de and _de.cards then
				card_protos = _de.cards
			end

			if not card_protos then
				card_protos = {}
				for k, v in pairs(G.P_CARDS) do
					local rank_data = SMODS.Card.RANKS[v.value]
					local suit_data = SMODS.Card.SUITS[v.suit]
					local _r, _s = (rank_data.suffix or rank_data.value), suit_data.prefix
					local keep, _e, _d, _g = true, nil, nil, nil
					if _de then
						if _de.yes_ranks and not _de.yes_ranks[_r] then keep = false end
						if _de.no_ranks and _de.no_ranks[_r] then keep = false end
						if _de.yes_suits and not _de.yes_suits[_s] then keep = false end
						if _de.no_suits and _de.no_suits[_s] then keep = false end
						if _de.enhancement then _e = _de.enhancement end
						if _de.edition then _d = _de.edition end
						if _de.seal then _g = _de.seal end
					end

					if keep then card_protos[#card_protos + 1] = { s = _s, r = _r, e = _e, d = _d, g = _g } end
				end
			end
			for k, v in ipairs(card_protos) do
				local _card = Card(0, 0, G.CARD_W * 0.45, G.CARD_H * 0.45, G.P_CARDS[v.s .. '_' .. v.r],
					G.P_CENTERS[v.e or 'c_base'])
				if v.d then _card:set_edition({ [v.d] = true }, true, true) end
				if v.g then _card:set_seal(v.g, true, true) end
				SUITS[v.s][#SUITS[v.s] + 1] = _card
			end
			local num_suits = 0
			for j = 1, #suit_map do
				if SUITS[suit_map[j]][1] then num_suits = num_suits + 1 end
			end
			for j = 1, #suit_map do
				if SUITS[suit_map[j]][1] then
					table.sort(SUITS[suit_map[j]], function(a, b) return a:get_nominal() > b:get_nominal() end)
					local view_deck = CardArea(
						0, 0,
						5.5 * G.CARD_W,
						(0.42 - (num_suits <= 4 and 0 or num_suits >= 8 and 0.28 or 0.07 * (num_suits - 4))) * G.CARD_H,
						{
							card_limit = #SUITS[suit_map[j]],
							type = 'title_2',
							view_deck = true,
							highlight_limit = 0,
							card_w =
								G.CARD_W * 0.5,
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
							view_deck:emplace(SUITS[suit_map[j]][i])
						end
					end
				end
			end
			return {
				n = G.UIT.ROOT,
				config = { align = "cm", padding = 0, colour = G.C.BLACK, r = 0.1, minw = 11.4, minh = 4.2 },
				nodes =
					deck_tables
			}
		else
			return UIDEF_challenge_description_tab_ref(args)
		end
	end

	function G.UIDEF.deck_preview(args)
		local _minh, _minw = 0.35, 0.5
		local suit_list = SMODS.Card.SUIT_LIST
		local suit_labels = {}
		local suit_counts = {}
		local mod_suit_counts = {}
		for _, v in ipairs(suit_list) do
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
		for _, v in ipairs(suit_list) do
			SUITS[v] = {}
		end

		for k, v in pairs(SUITS) do
			for i = 1, SMODS.Card.MAX_ID do
				SUITS[k][#SUITS[k] + 1] = {}
			end
		end

		local stones = nil
        local rank_name_mapping = {}
		local id_index_mapping = {}
        for i = #SMODS.Card.RANK_LIST, 1, -1 do
			local v = SMODS.Card.RANK_LIST[i]
			local rank_data = SMODS.Card.RANKS[SMODS.Card.RANK_SHORTHAND_LOOKUP[v] or v]
			id_index_mapping[rank_data.id] = #rank_name_mapping+1
			rank_name_mapping[#rank_name_mapping + 1] = v
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
					if SUITS[v.base.suit][v.base.id] then
						table.insert(SUITS[v.base.suit][v.base.id], v)
					end
					rank_counts[id_index_mapping[v.base.id]] = (rank_counts[id_index_mapping[v.base.id]] or 0) + 1
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
        for i = #SMODS.Card.RANK_LIST, 1, -1 do
			local v = SMODS.Card.RANK_LIST[i]
			local rank_data = SMODS.Card.RANKS[SMODS.Card.RANK_SHORTHAND_LOOKUP[v] or v]
			local _tscale = 0.3
			local _colour = G.C.BLACK
			local rank_col = v == 'A' and _bg_col or (v == 'K' or v == 'Q' or v == 'J') and G.C.WHITE or _bg_col
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
									{ n = G.UIT.T, config = { text = '' .. v, colour = _colour, scale = 1.6 * _tscale } },
								}
							},
							{
								n = G.UIT.R,
								config = { align = "cm", minw = _minw + 0.04, minh = _minh, colour = G.C.L_BLACK, r = 0.1 },
								nodes = {
									{ n = G.UIT.T, config = { text = '' .. (rank_counts[id_index_mapping[rank_data.id]] or 0), colour = flip_col, scale = _tscale, shadow = true } }
								}
							}
						}
					}
				}
			}
			table.insert(_row, _col)
		end
		table.insert(deck_tables, { n = G.UIT.R, config = { align = "cm", padding = 0.04 }, nodes = _row })

		for j = 1, #suit_list do
			_row = {}
			_bg_col = mix_colours(G.C.SUITS[suit_list[j]], G.C.L_BLACK, 0.7)
			for i = SMODS.Card.MAX_ID, 2, -1 do
				local _tscale = #SUITS[suit_list[j]][i] > 0 and 0.3 or 0.25
				local _colour = #SUITS[suit_list[j]][i] > 0 and flip_col or G.C.UI.TRANSPARENT_LIGHT

				local _col = {
					n = G.UIT.C,
					config = { align = "cm", padding = 0.05, minw = _minw + 0.098, minh = _minh },
					nodes = {
						{ n = G.UIT.T, config = { text = '' .. #SUITS[suit_list[j]][i], colour = _colour, scale = _tscale, shadow = true, lang = G.LANGUAGES['en-us'] } },
					}
				}
				if id_index_mapping[i] then table.insert(_row, _col) end
			end
			table.insert(deck_tables,
				{
					n = G.UIT.R,
					config = { align = "cm", r = 0.1, padding = 0.04, minh = 0.4, colour = _bg_col },
					nodes =
						_row
				})
		end

		for _, v in ipairs(suit_list) do
			local suit_data = SMODS.Card.SUITS[v]
			local t_s = Sprite(0, 0, 0.3, 0.3, (suit_data.ui_atlas_low_contrast or suit_data.ui_atlas_high_contrast) and
				G.ASSET_ATLAS
				[G.SETTINGS.colourblind_option and suit_data.ui_atlas_high_contrast or suit_data.ui_atlas_low_contrast] or
				G.ASSET_ATLAS["ui_" .. (G.SETTINGS.colourblind_option and 2 or 1)],
				suit_data.ui_pos)
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

	function Card:set_base(card, initial)
		card = card or {}

		self.config.card = card
		for k, v in pairs(G.P_CARDS) do
			if card == v then self.config.card_key = k end
		end

		if next(card) then
			self:set_sprites(nil, card)
		end

		local suit_base_nominal_original = nil
		if self.base and self.base.suit_nominal_original then
			suit_base_nominal_original = self.base
				.suit_nominal_original
		end
		self.base = {
			name = self.config.card.name,
			suit = self.config.card.suit,
			value = self.config.card.value,
			nominal = 0,
			suit_nominal = 0,
			face_nominal = 0,
			colour = G.C.SUITS[self.config.card.suit],
			times_played = 0
		}
		local rank_data = SMODS.Card.RANKS[self.base.value] or {}
		local suit_data = SMODS.Card.SUITS[self.base.suit] or {}
		self.base.nominal = rank_data.nominal or 0
		self.base.id = rank_data.id or 0
		self.base.face_nominal = rank_data.face_nominal or 0

		if initial then self.base.original_value = self.base.value end

		self.base.suit_nominal = suit_data.suit_nominal or 0
		self.base.suit_nominal_original = suit_base_nominal_original or
			suit_data.suit_nominal and suit_data.suit_nominal / 10 or nil

		if not initial then G.GAME.blind:debuff_card(self) end
		if self.playing_card and not initial then check_for_unlock({ type = 'modify_deck' }) end
	end

	function Card:change_suit(new_suit)
		local new_code = SMODS.Card.SUITS[new_suit].prefix or ''
		local new_val = SMODS.Card.RANKS[self.base.value].suffix or SMODS.Card.RANKS[self.base.value].value
		local new_card = G.P_CARDS[new_code .. '_' .. new_val] or nil
		self:set_base(new_card)
		G.GAME.blind:debuff_card(self)
	end

	function Card:is_face(from_boss)
		if self.debuff and not from_boss then return end
		if self:get_id() < 0 then return end
		local val = self.base.value
		if next(find_joker('Pareidolia')) or (val and SMODS.Card.RANKS[val] and SMODS.Card.RANKS[val].face) then return true end
	end

	local Card_use_consumeable_ref = Card.use_consumeable
	function Card:use_consumeable(area, copier)
		if self.ability.name == 'Strength' or self.ability.name == 'Sigil' or self.ability.name == 'Ouija' or self.ability.name == 'Familiar' or self.ability.name == 'Grim' or self.ability.name == 'Incantation' then
			stop_use()
			if not copier then set_consumeable_usage(self) end
			if self.debuff then return nil end
			local used_tarot = copier or self

			if self.ability.consumeable.max_highlighted then
				update_hand_text({ immediate = true, nopulse = true, delay = 0 },
					{ mult = 0, chips = 0, level = '', handname = '' })
			end
			if self.ability.name == 'Strength' then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.4,
					func = function()
						play_sound('tarot1')
						used_tarot:juice_up(0.3, 0.5)
						return true
					end
				}))
				for i = 1, #G.hand.highlighted do
					local percent = 1.15 - (i - 0.999) / (#G.hand.highlighted - 0.998) * 0.3
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.15,
						func = function()
							G.hand.highlighted[i]:flip(); play_sound('card1', percent); G.hand.highlighted[i]:juice_up(
								0.3,
								0.3); return true
						end
					}))
				end
				delay(0.2)
				for i = 1, #G.hand.highlighted do
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.1,
						func = function()
							local card = G.hand.highlighted[i]
							local suit_data = SMODS.Card.SUITS[card.base.suit]
							local suit_prefix = suit_data.prefix .. '_'
							local rank_data = SMODS.Card.RANKS[card.base.value]
							local behavior = rank_data.strength_effect or { fixed = 1, ignore = false, random = false }
							local rank_suffix = ''
							if behavior.ignore or not next(rank_data.next) then
								return true
							elseif behavior.random then
								local r = pseudorandom_element(rank_data.next, pseudoseed('strength'))
								rank_suffix = SMODS.Card.RANKS[r].suffix or SMODS.Card.RANKS[r].value
							else
								local ii = (behavior.fixed and rank_data.next[behavior.fixed]) and behavior.fixed or 1
								rank_suffix = SMODS.Card.RANKS[rank_data.next[ii]].suffix or
									SMODS.Card.RANKS[rank_data.next[ii]].value
							end
							card:set_base(G.P_CARDS[suit_prefix .. rank_suffix])
							return true
						end
					}))
				end
				for i = 1, #G.hand.highlighted do
					local percent = 0.85 + (i - 0.999) / (#G.hand.highlighted - 0.998) * 0.3
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.15,
						func = function()
							G.hand.highlighted[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.highlighted[i]
								:juice_up(
									0.3, 0.3); return true
						end
					}))
				end
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.2,
					func = function()
						G.hand:unhighlight_all(); return true
					end
				}))
				delay(0.5)
			elseif self.ability.name == 'Sigil' or self.ability.name == 'Ouija' then
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.4,
					func = function()
						play_sound('tarot1')
						used_tarot:juice_up(0.3, 0.5)
						return true
					end
				}))
				for i = 1, #G.hand.cards do
					local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.15,
						func = function()
							G.hand.cards[i]:flip(); play_sound('card1', percent); G.hand.cards[i]:juice_up(0.3, 0.3); return true
						end
					}))
				end
				delay(0.2)
				if self.ability.name == 'Sigil' then
					local _suit = SMODS.Card.SUITS[pseudorandom_element(SMODS.Card.SUIT_LIST, pseudoseed('sigil'))]
						.prefix
					for i = 1, #G.hand.cards do
						G.E_MANAGER:add_event(Event({
							func = function()
								local card = G.hand.cards[i]
								local suit_prefix = _suit .. '_'
								local rank_data = SMODS.Card.RANKS[card.base.value]
								local rank_suffix = rank_data.suffix or rank_data.value
								card:set_base(G.P_CARDS[suit_prefix .. rank_suffix])
								return true
							end
						}))
					end
				end
				if self.ability.name == 'Ouija' then
					local rank_data = pseudorandom_element(SMODS.Card.RANKS, pseudoseed('ouija'))
					local _rank = rank_data.suffix or rank_data.value
					for i = 1, #G.hand.cards do
						G.E_MANAGER:add_event(Event({
							func = function()
								local card = G.hand.cards[i]
								local suit_data = SMODS.Card.SUITS[card.base.suit]
								local suit_prefix = suit_data.prefix .. '_'
								local rank_suffix = _rank
								card:set_base(G.P_CARDS[suit_prefix .. rank_suffix])
								return true
							end
						}))
					end
					G.hand:change_size(-1)
				end
				for i = 1, #G.hand.cards do
					local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
					G.E_MANAGER:add_event(Event({
						trigger = 'after',
						delay = 0.15,
						func = function()
							G.hand.cards[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.cards[i]:juice_up(0.3, 0.3); return true
						end
					}))
				end
				delay(0.5)
			elseif self.ability.name == 'Familiar' or self.ability.name == 'Grim' or self.ability.name == 'Incantation' then
				local destroyed_cards = {}
				destroyed_cards[#destroyed_cards + 1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.4,
					func = function()
						play_sound('tarot1')
						used_tarot:juice_up(0.3, 0.5)
						return true
					end
				}))
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.1,
					func = function()
						for i = #destroyed_cards, 1, -1 do
							local card = destroyed_cards[i]
							if card.ability.name == 'Glass Card' then
								card:shatter()
							else
								card:start_dissolve(nil, i ~= #destroyed_cards)
							end
						end
						return true
					end
				}))
				G.E_MANAGER:add_event(Event({
					trigger = 'after',
					delay = 0.7,
					func = function()
						local cards = {}
						for i = 1, self.ability.extra do
							cards[i] = true
							local _suit, _rank = nil, nil
							if self.ability.name == 'Familiar' then
								local faces = {}
								for _, v in pairs(SMODS.Card.RANKS) do
									if v.face then table.insert(faces, v.suffix or v.value) end
								end
								_rank = pseudorandom_element(faces, pseudoseed('familiar_create'))
								_suit = SMODS.Card.SUITS
									[pseudorandom_element(SMODS.Card.SUIT_LIST, pseudoseed('familiar_create'))].prefix
							elseif self.ability.name == 'Grim' then
								_rank = 'A'
								_suit = SMODS.Card.SUITS
									[pseudorandom_element(SMODS.Card.SUIT_LIST, pseudoseed('grim_create'))].prefix
							elseif self.ability.name == 'Incantation' then
								local numbers = {}
								for k, v in pairs(SMODS.Card.RANKS) do
									if k ~= 'Ace' and not v.face then table.insert(numbers, v.suffix or v.value) end
								end
								_rank = pseudorandom_element(numbers, pseudoseed('incantation_create'))
								_suit = SMODS.Card.SUITS
									[pseudorandom_element(SMODS.Card.SUIT_LIST, pseudoseed('incantation_create'))]
									.prefix
							end
							_suit = _suit or 'S'; _rank = _rank or 'A'
							local cen_pool = {}
							for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
								if v.key ~= 'm_stone' then
									cen_pool[#cen_pool + 1] = v
								end
							end
							create_playing_card(
								{
									front = G.P_CARDS[_suit .. '_' .. _rank],
									center = pseudorandom_element(cen_pool,
										pseudoseed('spe_card'))
								}, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
						end
						playing_card_joker_effects(cards)
						return true
					end
				}))
				delay(0.3)
				for i = 1, #G.jokers.cards do
					G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
				end
			end
		else
			Card_use_consumeable_ref(self, area, copier)
		end
	end

	local Blind_set_blind_ref = Blind.set_blind
	function Blind:set_blind(blind, reset, silent)
		Blind_set_blind_ref(self, blind, reset, silent)
		if (self.name == "The Eye") and not reset then
			for _, v in ipairs(G.handlist) do
				self.hands[v] = false
			end
		end
	end

	local tally_sprite_ref = tally_sprite
	function tally_sprite(pos, value, tooltip, suit)
		local node = tally_sprite_ref(pos, value, tooltip)
		if not suit then return node end
		local suit_data = SMODS.Card.SUITS[suit]
		if suit_data.ui_atlas_low_contrast or suit_data.ui_atlas_high_contrast then
			local t_s = Sprite(0, 0, 0.5, 0.5,
				G.ASSET_ATLAS
				[G.SETTINGS.colourblind_option and suit_data.ui_atlas_high_contrast or suit_data.ui_atlas_low_contrast],
				{ x = suit_data.ui_pos.x or 0, y = suit_data.ui_pos.y or 0 })
			t_s.states.drag.can = false
			t_s.states.hover.can = false
			t_s.states.collide.can = false
			node.nodes[1].nodes[1].config.object = t_s
		end
		return node
	end
end

SMODS.Card:_extend()
-- ----------------------------------------------
-- ------------MOD CORE API SPRITE END-----------
