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
