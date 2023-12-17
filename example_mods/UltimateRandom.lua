--- STEAMODDED HEADER
--- MOD_NAME: Ultimate Random Deck
--- MOD_ID: UltimateRandomDeck
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Ultimate Random Deck!

----------------------------------------------
------------MOD CODE -------------------------

function randomSelect(table)
	for i = 1, 5 do
		math.random()
	end
    if #table == 0 then
        return nil -- Table is empty
    end
    local randomIndex = math.random(1, #table)
    return table[randomIndex]
end

local Backapply_to_runRef = Back.apply_to_run
function Back.apply_to_run(arg_56_0)
	Backapply_to_runRef(arg_56_0)

	if arg_56_0.effect.config.random then
		G.E_MANAGER:add_event(Event({
			func = function()
				local trandom_m = {
					G.P_CENTERS.m_stone,
					G.P_CENTERS.m_steel,
					G.P_CENTERS.m_glass,
					G.P_CENTERS.m_gold,
					G.P_CENTERS.m_bonus,
					G.P_CENTERS.m_mult,
					G.P_CENTERS.m_wild,
					G.P_CENTERS.m_lucky,
					"NOTHING"
				}
				local trandom_e = {
					{foil = true},
					{holo = true},
					{polychrome = true},
					"NOTHING"
				}
				local trandom_r = {
					"A",
					"K",
					"Q",
					"J",
					"T",
					"9",
					"8",
					"7",
					"6",
					"5",
					"4",
					"3",
					"2"
				}
				local trandom_s = {
					"C",
					"D",
					"H",
					"S"
				}
				for iter_57_0 = #G.playing_cards, 1, -1 do
					sendDebugMessage("id: " .. G.playing_cards[iter_57_0].base.id)
					local random_m = randomSelect(trandom_m)
					local random_e = randomSelect(trandom_e)
					local random_r = randomSelect(trandom_r)
					local random_s = randomSelect(trandom_s)

					G.playing_cards[iter_57_0]:set_base(G.P_CARDS[random_s .. "_" .. random_r])
					if random_m  ~= "NOTHING" then
						G.playing_cards[iter_57_0]:set_ability(random_m)
					end
					if random_e ~= "NOTHING" then
						G.playing_cards[iter_57_0]:set_edition(random_e, true, true)
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

	if name == "Ultimate Random" then
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
								text = "Random ",
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

function SMODS.INIT.UltimateRandomDeck()
	local absolute = SMODS.Deck:new("Ultimate Random", "ultimate", {random = true}, {x = 4, y = 3})
	absolute:register()
end

----------------------------------------------
------------MOD CODE END----------------------
