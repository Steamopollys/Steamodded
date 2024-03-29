--- STEAMODDED HEADER
--- MOD_NAME: Deck of 4
--- MOD_ID: DeckOf4
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Create a special deck that only contains 4s!

----------------------------------------------
------------MOD CODE -------------------------

local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
	Backapply_to_runRef(arg_56_0)

	if arg_56_0.effect.config.only_one_rank then
		G.E_MANAGER:add_event(Event({
			func = function()
				for iter_57_0 = #G.playing_cards, 1, -1 do
					sendDebugMessage(G.playing_cards[iter_57_0].base.id, "SteamoddedDecksOf4s")
					if G.playing_cards[iter_57_0].base.id ~= 4 then
						local suit = string.sub(G.playing_cards[iter_57_0].base.suit, 1, 1) .. "_"
						local rank = "4"

						G.playing_cards[iter_57_0]:set_base(G.P_CARDS[suit .. rank])
					end
				end

				return true
			end
		}))
	end
end

local loc_def = {
	["name"]="Deck of fours",
	["text"]={
		[1]="Start with a Deck",
		[2]="full of",
		[3]="{C:attention}Fours{}"
	},
}

local dfours = SMODS.Deck:new("Deck of fours", "fours", {only_one_rank = 4}, {x = 1, y = 3}, loc_def)
dfours:register()

----------------------------------------------
------------MOD CODE END----------------------
