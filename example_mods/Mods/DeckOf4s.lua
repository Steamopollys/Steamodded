--- STEAMODDED HEADER
--- MOD_NAME: Deck of 4
--- MOD_ID: DeckOf4
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Create a special deck that only contains 4s!
--- LOADER_VERSION_GEQ: 1.0.0

----------------------------------------------
------------MOD CODE -------------------------

local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
	Backapply_to_runRef(arg_56_0)

	if arg_56_0.effect.config.only_one_rank then
		G.E_MANAGER:add_event(Event({
			func = function()
				for i = #G.playing_cards, 1, -1 do
					sendDebugMessage(G.playing_cards[i].base.id)
					if G.playing_cards[i].base.id ~= 4 then
						local suit = string.sub(G.playing_cards[i].base.suit, 1, 1) .. "_"
						local rank = "4"

						G.playing_cards[i]:set_base(G.P_CARDS[suit .. rank])
					end
				end

				return true
			end
		}))
	end
end

SMODS.Back{
	name = "Deck of fours",
	key = "fours",
	pos = {x = 1, y = 3},
	config = {only_one_rank = 4},
	loc_txt = {
		name ="Deck of fours",
		text={
			"Start with a Deck",
			"full of {C:attention}Fours{}",
		},
    },
	apply = function(back)
		G.E_MANAGER:add_event(Event({
			func = function()
                for i = #G.playing_cards, 1, -1 do
                    local suit_data = SMODS.Suits[G.playing_cards[i].base.suit]
					G.playing_cards[i]:set_base(G.P_CARDS[suit_data.card_key .. '_' .. back.effect.config.only_one_rank])
				end
				return true
			end
		}))
	end
}

----------------------------------------------
------------MOD CODE END----------------------
