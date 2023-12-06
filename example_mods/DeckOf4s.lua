--- STEAMODDED HEADER
--- MOD_NAME: Deck of 4
--- MOD_ID: DeckOf4
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Create a special deck that only contains 4s!

----------------------------------------------
------------MOD CODE -------------------------

G.P_CENTERS.b_empt_aa = nil

G.BACKS.NAME_TO_POS.aa = nil

G.BACKS.ID_TO_POS.b_empt_aa = nil

G.P_CENTERS.b_fours = {
	discovered = true,
	name = "Deck of Fours",
	set = "Back",
	unlocked = true,
	order = 4,
	pos = {
		x = 1,
		y = 3
	},
	config = {
		only_one_rank = 4
	}
}

G.BACKS.IDS[4] = "b_fours"

G.BACKS.NAMES[4] = "Deck of Fours"

G.BACKS.NAME_TO_POS["Deck of Fours"] = 4

G.BACKS.ID_TO_POS.b_fours = 4

G.BACKS.UNLOCKED_NAMES[4] = "Deck of Fours"

G.BACKS.AVAILABLE_NAMES[4] = "Deck of Fours"


local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
	Backapply_to_runRef(arg_56_0)

	if arg_56_0.effect.config.only_one_rank then
		G.E_MANAGER:add_event(Event({
			func = function()
				for iter_57_0 = #G.playing_cards, 1, -1 do
					sendDebugMessage(G.playing_cards[iter_57_0].base.id)
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

local Backgenerate_UIRef = Back.generate_UI
function Back.generate_UI(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local deck = Backgenerate_UIRef(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local name = arg_53_1 or arg_53_0.name

	if name == "Deck of Fours" then
		arg_53_3 = arg_53_3 or 0.7
		arg_53_2 = arg_53_2 or 0.9

		return {
			n = G.UIT.ROOT,
			config = {
				align = "cm",
				minw = arg_53_3 * 3,
				minh = arg_53_3 * 2.5,
				id = arg_53_0.name,
				colour = G.C.CLEAR
			},
			nodes = {
				{
					n = G.UIT.R,
					config = {
						align = "cm"
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = "Start with a Deck",
								scale = arg_53_2 * 0.5,
								colour = G.C.UI.TEXT_DARK
							}
						}
					}
				},
				{
					n = G.UIT.R,
					config = {
						align = "cm"
					},
					nodes = {
						{
							n = G.UIT.T,
							config = {
								text = "full of ",
								scale = arg_53_2 * 0.5,
								colour = G.C.UI.TEXT_DARK
							}
						},
						{
							n = G.UIT.T,
							config = {
								text = "Fours",
								scale = arg_53_2 * 0.5,
								colour = G.C.SECONDARY_SET.Planet
							}
						}
					}
				}
			}
		}
	end
	return deck
end

----------------------------------------------
------------MOD CODE END----------------------
