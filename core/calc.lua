-- TODO I don't handle end_round() currently

-- Functions to evaluate an `effect` table.
-- `effect`s are returned from calculate_joker() and eval_card() in the base game, and
-- calculate() functions in SMODS.

-- Order of effects
SMODS.playing_card_effect_order = {
	'chips',
	'mult',
	'dollars', -- dollars comes before x_mult in base game, for some reason
	-- the weird placement of extra never matters in the base game
	{['extra'] = {
		'mult', 
		'chips', 
		'swap', -- unused in base game
		'func', 
		-- in an effect, message replaces the displayed text of other keys;
		-- no other keys will show text
		'message',
	}},
	'x_mult',
	-- plain message never happens in the base game
	'message',
	-- in the base game, message is always manually set, and exactly
	-- one of mult, chips, or x_mult can be set
	{['edition'] = {
        'mult', 
		'chips', 
		'x_mult', 
		'dollars',
		'message'
	}},
	-- TODO seals. Currently the game does not go through effects for seals
}
SMODS.before_joker_edition_effect_order = {
    'mult',
    'chips'
}
SMODS.joker_effect_order = {
	'mult',
	'chips',
	'x_mult',
	'message'
}
SMODS.after_joker_edition_effect_order = {
	'x_mult',
}

SMODS.calc.aliases = {
    chips = {'chip_mod'},
    mult = {'mult_mod'},
    x_mult = {'Xmult_mod, x_mult_mod'},
    dollars = {'p_dollars'}
}

-- Recursively evaluates an effect,
-- looking for a specified list of keys.

-- This function takes one `args` parameter.
-- `args` is a table that can contain the following fields:

-- `effect`: the effect we're evaluating right now, always a table.
-- `effect` can be an array of effects; we evaluate each effect completely, in sequence.

-- `type`: type of the effect/subeffect we're evaluating; for example if
-- we're evaluating the effect `{ extra = inner_effect }`, we would 
-- recursively evaluate `inner_effect` with `args.type == 'extra'`.
-- If `type` is nil, we're evaluating normal playing card effects.

-- `key`: current key or list of keys we're evaluating.
-- Can be
-- * a string, for example "chips"
-- * an array of valid `key`s
-- * a table with one field: `{[type] = K}` where K is a valid `key`.
-- K will be evaluated with args.type = type.

-- `val`: the value of `effect[k]` where k is the current key we're evaluating

-- `update` is used internally
function SMODS.eval_effect(args, update)
    -- Prologue
	update = update or {}
    for k, v in pairs(update) do
        args[k], update[k] = update[k], args[k]
    end
	-- now update holds the old key/value pairs

    if args.effect[1] then
		-- Array of effects
		for _, effect2 in ipairs(v) do
			SMODS.eval_effect(args, {effect = effect2})
		end
	elseif args.val then
		-- Reached a key-value pair inside the effect, evaluate it
		-- Calculate effect
		if args.key == 'chips' then
			hand_chips = mod_chips(hand_chips + args.val)
			update_hand_text({delay = 0}, {chips = hand_chips})
		elseif args.key == 'mult' then
			mult = mod_mult(mult + args.val)
			update_hand_text({delay = 0}, {mult = mult})
		elseif args.key == 'x_mult' then
			mult = mod_mult(mult * args.val)
			update_hand_text({delay = 0}, {mult = mult})
		elseif args.key == 'dollars' then
			ease_dollars(args.val)
		elseif args.key == 'swap' then
			-- args.val does not matter
			local old_mult = mult
			mult = mod_mult(hand_chips)
			hand_chips = mod_chips(old_mult)
			update_hand_text({delay = 0}, {chips = hand_chips, mult = mult})
		elseif args.key == 'func' then
			args.val()
		end
		-- Text of effect
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
			if args.key == 'chips' 
			or args.key == 'mult' 
			or args.key == 'x_mult' 
			or args.key == 'dollars'
			or args.key == 'swap' then
				if not args.effect.message then
					card_eval_status_text(args.card, args.key, args.val, args.percent)
				end
			elseif args.key == 'message' then
				if args.type == 'jokers' then
					card_eval_status_text(args.card, 'jokers', nil, args.percent, nil, args.effect)
				else -- nil or 'extra'
					card_eval_status_text(args.card, 'extra', nil, args.percent, nil, args.effect)
				end
			end
		end
	elseif type(args.key) == 'table' and args.key[1] then
		-- Array of keys
        for _, key2 in ipairs(args.key) do
            SMODS.eval_effect(args, {key = key2})
        end
    elseif type(args.key) == 'table' and #args.key == 1 then
		-- Single-field table
		local type, key2 = next(args.key)
        SMODS.eval_effect(args, {type = type, key = key2})
	elseif type(args.key) == 'string' then
		-- One key
		local val = args.effect[args.key]
		if SMODS.calc.aliases[args.key] then
			for _, key_alias in ipairs(SMODS.calc.aliases[args.key]) do
				val = val or args.effect[key_alias]
			end
		end
		if val then
			SMODS.eval_effect(args, {val = val})
		end
	end

    -- Epilogue
    for k, v in pairs(update) do
        args[k], update[k] = update[k], args[k]
    end
end

function SMODS.eval_playing_card_effect(args)
	if not args.key then args.key = SMODS.playing_card_effect_order end
	return SMODS.eval_effect(args)
end
function SMODS.eval_joker_effect(args)
	if not args.key then args.key = SMODS.joker_effect_order end
	if not args.type then args.type = 'jokers' end
	return SMODS.eval_effect(args)
end
-- legacy function, don't use
function SMODS.eval_this(card, effect)
	sendWarnMessage("SMODS.eval_this is a legacy function, use SMODS.eval_joker_effect instead")
    return SMODS.eval_joker_effect{
		card = card,
		effect = effect
	}
end
