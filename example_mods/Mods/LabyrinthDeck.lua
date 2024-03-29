--- STEAMODDED HEADER
--- MOD_NAME: Labyrinth Deck
--- MOD_ID: LabyrinthDeck
--- MOD_AUTHOR: [MathIsFun_]
--- MOD_DESCRIPTION: Implements an unused deck hidden in the game's textures

----------------------------------------------
------------MOD CODE -------------------------

local Backgenerate_UIRef = Back.generate_UI
function Back.generate_UI(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local deck = Backgenerate_UIRef(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local name = arg_53_1 or arg_53_0.name

	if name == "Labyrinth Deck" then
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
								text = "-3",
								scale = arg_53_2 * 0.5,
								colour = G.C.BLUE
							}
						},
						{
							n = G.UIT.T,
							config = {
								text = " hands,",
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
								text = "+5",
								scale = arg_53_2 * 0.5,
								colour = G.C.RED
							}
						},
						{
							n = G.UIT.T,
							config = {
								text = " discards",
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
								text = "every round",
								scale = arg_53_2 * 0.5,
								colour = G.C.UI.TEXT_DARK
							}
						}
					}
				}
			}
		}
	end
	return deck
end

local labyrinth = SMODS.Deck:new("Labyrinth Deck", "labyrinth", {hands = -3, discards = 5}, {x = 0, y = 4})
labyrinth:register()

----------------------------------------------
------------MOD CODE END----------------------