--- STEAMODDED HEADER
--- SECONDARY MOD FILE

----------------------------------------------
------------MOD CODE--------------------------

-- Modification from Steamo
-- Only Modify returned objects
local evaluate_poker_handRef = evaluate_poker_hand
function evaluate_poker_hand(arg_182_0)
	rvalue = evaluate_poker_handRef(arg_182_0)
	rvalue["Five of a Flush"] = {}
	
	if next(get_X_same(5, arg_182_0)) and next(get_flush(arg_182_0)) then
		rvalue["Five of a Flush"] = get_X_same(5, arg_182_0)
		
		if not rvalue.top then
			rvalue.top = rvalue["Five of a Flush"]
		end
	end
	
	return rvalue
end

-- Modification from Steamo
-- Only Modify returned objects
local GFUNCSget_poker_hand_infoRef = G.FUNCS.get_poker_hand_info
function G.FUNCS.get_poker_hand_info(arg_540_0)
	rvar_540_2, rvar_540_4, rvar_540_0, rvar_540_1 = GFUNCSget_poker_hand_infoRef(arg_540_0)

	if next(rvar_540_0["Five of a Flush"]) then
		rvar_540_2 = "Five of a Flush"
		rvar_540_1 = rvar_540_0["Five of a Flush"][1]
	end
	
	return rvar_540_2, rvar_540_2, rvar_540_0, rvar_540_1
end

-- Modification from Steamo
-- Only Modify returned object
local ingameobjRef = Game.init_game_object;
function Game.init_game_object(arg_291_0)
	local gameObj = ingameobjRef(arg_291_0)
	gameObj.hands["Five of a Flush"] = {
		l_chips = 25,
		chips = 250,
		played = 0,
		mult = 25,
		visible = false,
		l_mult = 3,
		level = 1,
		description = {
			"5 cards with the same rank and suit"
		},
		example = {
			{
				"S_A",
				true
			},
			{
				"S_A",
				true
			},
			{
				"S_A",
				true
			},
			{
				"S_A",
				true
			},
			{
				"S_A",
				true
			}
		}
	}
	return gameObj;
end

-- Modification from Steamo
-- Only Modify returned object
local globalsRef = Game.set_globals;
function Game.set_globals(arg_337_0)
	globalsRef(arg_337_0)	
	table.insert(arg_337_0.handlist[1], 1, "Five of a Flush")
end

-- Modification from Steamo
-- Only Modify returned object
local create_UIBox_current_handsRef = create_UIBox_current_hands
function create_UIBox_current_hands(arg_457_0)
	local uitable = create_UIBox_current_handsRef(arg_457_0)
	local box = create_UIBox_current_hand_row("Five of a Flush", arg_457_0)

	table.insert(uitable.nodes[1].nodes, 1, box)
	return uitable
end

-- Make Vulcan a "Planet?"
-- Modification from Steamo
-- Only Modify returned object
local GUIDEFcard_h_popupRef = G.UIDEF.card_h_popup
function G.UIDEF.card_h_popup(arg_414_0, arg_414_1)
	local obj = GUIDEFcard_h_popupRef(arg_414_0, arg_414_1)

	if arg_414_0.ability.name == "Vulcan" then
		obj.nodes[1].nodes[1].nodes[1].nodes[3] = create_badge(localize("k_planet_q"), get_type_colour(arg_414_0.config.center, arg_414_0))
	end

	return obj
end


-- Add to collection
-- Will be reworked when added to the API
function create_UIBox_your_collection_planets()
	local var_469_0 = {}
	
	G.your_collection = {}
	
	for iter_469_0 = 1, 2 do
		G.your_collection[iter_469_0] = CardArea(G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h, 6.25 * G.CARD_W, 1 * G.CARD_H, {
			highlight_limit = 0,
			collection = true,
			type = "title",
			card_limit = 6
		})
		
		table.insert(var_469_0, {
			n = G.UIT.R,
			config = {
				no_fill = true,
				align = "cm",
				padding = 0
			},
			nodes = {
				{
					n = G.UIT.O,
					config = {
						object = G.your_collection[iter_469_0]
					}
				}
			}
		})
	end
	
	for iter_469_1 = 1, #G.your_collection do
		for iter_469_2 = 1, 6 do
			local var_469_1 = G.P_CENTER_POOLS.Planet[iter_469_2 + (iter_469_1 - 1) * 6]
			local var_469_2 = Card(G.your_collection[iter_469_1].T.x + G.your_collection[iter_469_1].T.w / 2, G.your_collection[iter_469_1].T.y, G.CARD_W, G.CARD_H, nil, var_469_1)
			
			var_469_2:start_materialize(nil, iter_469_2 > 1 or iter_469_1 > 1)
			G.your_collection[iter_469_1]:emplace(var_469_2)
		end
	end
	
	INIT_COLLECTION_CARD_ALERTS()
	
	return (create_UIBox_generic_options({
		back_func = "your_collection",
		contents = {
			{
				n = G.UIT.R,
				config = {
					emboss = 0.05,
					r = 0.1,
					minw = 2.5,
					align = "cm",
					padding = 0.1,
					colour = G.C.BLACK
				},
				nodes = var_469_0
			},
			{
				n = G.UIT.R,
				config = {
					padding = 0,
					align = "cm"
				},
				nodes = {}
			}
		}
	}))
end

----------------------------------------------
------------MOD CODE END----------------------