--- STEAMODDED HEADER
--- MOD_NAME: Absolute Deck
--- MOD_ID: AbsoluteDeck
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Ans Absolute Deck of PolyGlass!

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
function Back.generate_UI(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local deck = Backgenerate_UIRef(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	local name = arg_53_1 or arg_53_0.name

	if name == "Absolute Deck" then
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
								text = "full of",
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
								text = "Polyglass ",
								scale = arg_53_2 * 0.5,
								colour = G.C.SECONDARY_SET.Planet
							}
						},
						{
							n = G.UIT.T,
							config = {
								text = "cards",
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

local absolute = SMODS.Deck:new("Absolute Deck", "absolute", {polyglass = true}, {x = 0, y = 3})
absolute:register()

----------------------------------------------
------------MOD CODE END----------------------
