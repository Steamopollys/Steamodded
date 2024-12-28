--- STEAMODDED HEADER
--- MOD_NAME: Ultimate Random Deck
--- MOD_ID: UltimateRandomDeck
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Ultimate Random Deck!
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

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

SMODS.Back{
    name = "Ultimate Random",
    key = "ultimate",
    pos = {x = 4, y = 3},
    config = {random = true},
    loc_txt = {
        name = "Ultimate Random",
        text ={
            "Start with a Deck",
            "full of",
            "{C:attention}Random{} cards"
        }
    },
    apply = function()
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
                local trandom_g = {
                    "Red",
                    "Blue",
                    "Gold",
                    "Purple",
                    "NOTHING"
                }
                for i = #G.playing_cards, 1, -1 do
                    local random_m = randomSelect(trandom_m)
                    local random_e = randomSelect(trandom_e)
                    local random_r = randomSelect(trandom_r)
                    local random_s = randomSelect(trandom_s)
                    local random_g = randomSelect(trandom_g)

                    G.playing_cards[i]:set_base(G.P_CARDS[random_s .. "_" .. random_r])
                    if random_m  ~= "NOTHING" then
                        G.playing_cards[i]:set_ability(random_m)
                    end
                    if random_e ~= "NOTHING" then
                        G.playing_cards[i]:set_edition(random_e, true, true)
                    end
                    if random_g ~= "NOTHING" then
                        G.playing_cards[i]:set_seal(random_g, true, true)
                    end
                end

                return true
            end
        }))
    end
}

----------------------------------------------
------------MOD CODE END----------------------
