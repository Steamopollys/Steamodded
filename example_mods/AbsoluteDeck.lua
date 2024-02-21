--- STEAMODDED HEADER
--- MOD_NAME: Absolute Deck
--- MOD_ID: AbsoluteDeck
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Absolute Deck of PolyGlass!

----------------------------------------------
------------MOD CODE -------------------------

local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
	Backapply_to_runRef(arg_56_0)

	if arg_56_0.effect.config.polyglass then
		G.E_MANAGER:add_event(Event({
			func = function()
				for iter_57_0 = #G.playing_cards, 1, -1 do
					sendDebugMessage(G.playing_cards[iter_57_0].base.id)

					G.playing_cards[iter_57_0]:set_ability(G.P_CENTERS.m_glass)
					G.playing_cards[iter_57_0]:set_edition({
						polychrome = true
					}, true, true)
				end

				return true
			end
		}))
	end
end

local Backgenerate_UIRef = Back.generate_UI
function Back.generate_UI(other, ui_scale, min_dims, challenge)
	local deck = Backgenerate_UIRef(other, ui_scale, min_dims, challenge)
	local name = other.name

	sendDebugMessage(inspectDepth(deck))

	if name == "Absolute Deck" then
		min_dims = min_dims or 0.7

		local loc_args, loc_nodes = nil, {}

		localize{type = 'descriptions', key = "b_absolute", set = 'Back', nodes = loc_nodes, vars = loc_args}

		return {
			n=G.UIT.ROOT, config={align = "cm", minw = min_dims*5, minh = min_dims*2.5, id = name, colour = G.C.CLEAR}, nodes={
				desc_from_rows(loc_nodes, true, min_dims*5)
			}
		}
	end
	return deck
end

-- G.localization.descriptions[args.set][args.key]

local loc_def = {
	["name"]="Absolute Deck",
	["text"]={
		[1]="Start with a Deck",
		[2]="full of",
		[3]="{C:attention}Polyglass{} cards"
	},
}

local absolute = SMODS.Deck:new("Absolute Deck", "absolute", {polyglass = true}, {x = 0, y = 3}, loc_def)
absolute:register()

----------------------------------------------
------------MOD CODE END----------------------
