SMODS.calc = {}

-- TODO I don't handle end_round() currently

-- Functions to evaluate an `effect` table.
-- `effect`s are returned from calculate_joker() and eval_card() in the base game, and
-- calculate() functions in SMODS.

-- Constants
SMODS.playing_card_effect_order = {
	'chips',
	'mult',
	'dollars', -- dollars comes before x_mult in base game, for some reason
	-- Yes, this is where 'extra' is evaluated as a subeffect in base game.
	-- The weird position of 'extra' never matters in the base game.
	-- In SMODS, 'extra' is unnecessary; put 'func' and 'message'
	-- at top level.
	{['extra'] = {
		'func',
		'message'
	}},
	'x_mult',
	'func',
	-- 'message' will prevent other keys from displaying text, replacing them
	-- all with a single message
	'message',
	{['edition'] = {
		type = 'edition',
        'mult', 
		'chips', 
		'x_mult', 
		-- TODO unimplemented
		-- 'dollars',
		'message'
	}},
	-- TODO seals. Currently the game does not go through effects for seals
}
SMODS.before_joker_edition_effect_order = {
	type = 'edition',
    'mult',
    'chips'
}
SMODS.joker_effect_order = {
	'mult',
	'chips',
	'x_mult',
	-- in the base game, message for jokers is always set, and exactly
	-- one of mult, chips, or x_mult can be set
	'message'
}
SMODS.after_joker_edition_effect_order = {
	type = 'edition',
	'x_mult',
}

SMODS.calc.aliases = {
    chips = {'chip_mod'},
    mult = {'mult_mod'},
    x_mult = {'Xmult_mod, x_mult_mod'},
    dollars = {'p_dollars'}
}

-- SMODS.eval_effect() recursively evaluates an effect, looking for a specified 
-- list of keys.

-- Functions in this file take one `args` parameter.
-- `args` is a table that can contain the following fields:

-- `effect`: the effect we're evaluating right now, always a table or nil.
-- `effect` can be an array of effects; we evaluate each effect completely, in sequence.

-- `type`: type of the effect/subeffect we're evaluating; for example if
-- we're evaluating the effect `{ extra = inner_effect }`, we would 
-- recursively evaluate `inner_effect` with `args.type == 'extra'`.
-- If `type` is nil, we're evaluating normal playing card effects.

-- `key`: current key or list of keys we're evaluating.
-- Can be
-- * a string, for example "chips"
-- * a table with one field: `{[subeffect] = K}` where `K` is a an array of `key`s,
-- possibly with additional fields. (ex. `K` could be `{type = 'foo', 'key1', 'key2'}`)
-- If `K` has a field 'type', `K` will be evaluated with `args.type = K.type`.
-- * an array composed of either of the above forms. (ex. see `K` above)

-- `val`: the value of `effect[k]` where k is the current key we're evaluating

-- `card`: the card for which we're evaluating all effects for.
-- Not to be confused with `effect.card`, which determines the card that's
-- animated with juice_card()

-- `percent`: passed to card_eval_status_text, modifies the pitch of sound played
function SMODS.eval_effect(args, update)
	-- `update` is used internally
	args = merge_tables(update, args)



	if not args.effect then
		-- do nothing
	elseif args.effect[1] then
		-- Array of effects
		for _, effect2 in ipairs(args.effect) do
			SMODS.eval_effect(args, {effect = effect2})
		end
	elseif args.val then
		-- Reached a key-value pair inside the effect, evaluate it
		-----
		----- Calculate effect
		-----
		if args.type ~= 'edition'
		and not args.effect.message 
		and (
			args.key == 'chips' or args.key == 'mult' or args.key == 'x_mult'
			or args.key == 'dollars' or args.key == 'swap' or args.key == 'func')
		and args.effect.card then
			juice_card(args.effect.card)
		end
		if args.key == 'chips' then
			hand_chips = mod_chips(hand_chips + args.val)
			if not args.effect.message then
				update_hand_text({delay = 0}, {chips = hand_chips})
			end
		elseif args.key == 'mult' then
			mult = mod_mult(mult + args.val)
			if not args.effect.message then
				update_hand_text({delay = 0}, {mult = mult})
			end
		elseif args.key == 'x_mult' then
			mult = mod_mult(mult * args.val)
			if not args.effect.message then
				update_hand_text({delay = 0}, {mult = mult})
			end
		elseif args.key == 'dollars' then
			ease_dollars(args.val)
		elseif args.key == 'swap' then
			-- args.val does not matter
			local old_mult = mult
			mult = mod_mult(hand_chips)
			hand_chips = mod_chips(old_mult)
			if not args.effect.message then
				update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
			end
		elseif args.key == 'func' then
			args.val()
		end
		-----
		----- Display text of effect
		-----
		if args.type == 'edition' then
			local extra = {
				-- does not matter in base game, colour is overwritten if edition = true
				colour = G.C.DARK_EDITION,
				edition = true
			}
			if args.key == 'message' then
				extra.message = args.val
				-- only matters for the colour in base game.
				-- TODO handle colour better if custom message is given
				extra.chips = args.effect.chips
				extra.mult = args.effect.mult
				extra.x_mult = args.effect.x_mult
				card_eval_status_text(args.card, 'extra', nil, args.percent, nil, extra)
			else
				if not args.effect.message then
					if args.key == 'chips' then
						extra.message = extra.message or localize{type='variable',key='a_chips',vars={args.val}}
						extra.chips = args.val
					elseif args.key == 'mult' then
						extra.message = extra.message or localize{type='variable',key='a_mult',vars={args.val}}
						extra.mult = args.val
					elseif args.key == 'x_mult' then
						extra.message = extra.message or localize{type='variable',key='a_xmult',vars={args.val}}
						extra.x_mult = args.val
					end
					-- in base game, using 'extra' vs 'jokers' here doesn't matter
					card_eval_status_text(args.card, 'extra', nil, args.percent, nil, extra)
				end
			end
		else
			if args.key == 'chips' or args.key == 'mult' or args.key == 'x_mult' 
			or args.key == 'dollars' or args.key == 'swap' then
				if not args.effect.message then
					if args.effect.card then juice_card(args.effect.card) end
					card_eval_status_text(args.card, args.key, args.val, args.percent)
				end
			elseif args.key == 'message' then
				-- 'jokers' or 'extra' doesn't matter in base game
				if args.type == 'jokers' then
					card_eval_status_text(args.card, 'jokers', nil, args.percent, nil, args.effect)
				else -- nil or 'extra'
					card_eval_status_text(args.card, 'extra', nil, args.percent, nil, args.effect)
				end
			end
		end
	elseif type(args.key) == 'table' and args.key[1] then
		-- Array of keys
		if args.key.type then
			args.type = args.key.type
		end
		if args.type ~= 'edition' and args.effect.message then
			-- One juice for the whole effect, if args.effect.message is set
			if args.effect.card then juice_card(args.effect.card) end
		end
        for _, key2 in ipairs(args.key) do
            SMODS.eval_effect(args, {key = key2})
        end
    elseif type(args.key) == 'table' then
		-- Single-field table. Evaluate subeffect
		local subeffect, key2 = next(args.key)
		assert(next(args.key, subeffect) == nil, "SMODS.eval_effect(): args.key was a table with 2+ fields")
		if args.effect[subeffect] then
        	SMODS.eval_effect(args, {key = key2, effect = args.effect[subeffect]})
		end
	elseif type(args.key) == 'string' then
		-- One key
		local keys_found = {} -- For debugging purposes
		local val = args.effect[args.key]; if val then table.insert(keys_found, args.key) end
		if SMODS.calc.aliases[args.key] then
			for _, key_alias in ipairs(SMODS.calc.aliases[args.key]) do
				val = val or args.effect[key_alias]; if args.effect[key_alias] then table.insert(keys_found, key_alias) end
			end
		end
		assert(#keys_found <= 1,
			("Found multiple keys with the same meaning when evaluating effect %s:\n%s")
				:format(tprint(args.effect), inspect(keys_found))
		)
		if val then
			SMODS.eval_effect(args, {val = val})
		end
	end
end

function SMODS.eval_playing_card_effect(args)
	if args.key then
		sendWarnMessage("SMODS.eval_playing_card_effect() does not take a key.")
	end
	return SMODS.eval_effect(merge_tables(args, {key = SMODS.playing_card_effect_order}))
end
function SMODS.eval_joker_effect(args)
	if args.key then
		sendWarnMessage("SMODS.eval_playing_card_effect() does not take a key.")
	end
	return SMODS.eval_effect(merge_tables(args, {key = SMODS.joker_effect_order}))
end
-- legacy function, don't use
function SMODS.eval_this(effect)
	sendWarnMessage("SMODS.eval_this is a legacy function, use SMODS.eval_joker_effect instead")
	return SMODS.eval_joker_effect{effect = effect}
end

-- Merge the two tables, with t1 taking priority
function merge_tables(t1, t2)
	local ret = {}
	if t1 then
		for k, v in pairs(t1) do
			ret[k] = v
		end
	end
	if t2 then
		for k, v in pairs(t2) do
			if ret[k] == nil then
				ret[k] = v
			end
		end
	end
	return ret
end