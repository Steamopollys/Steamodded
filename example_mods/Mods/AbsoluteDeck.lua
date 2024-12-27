--- STEAMODDED HEADER
--- MOD_NAME: Absolute Deck
--- MOD_ID: AbsoluteDeck
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Absolute Deck of PolyGlass!
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Back{
    name = "Absolute Deck",
    key = "absolute",
    pos = {x = 0, y = 3},
    config = {polyglass = true},
    loc_txt = {
        name = "Absolute Deck",
        text ={
            "Start with a Deck",
            "full of {C:attention,T:e_polychrome}Poly{}{C:red,T:m_glass}glass{} cards"
        },
    },
    apply = function()
        G.E_MANAGER:add_event(Event({
            func = function()
                for i = #G.playing_cards, 1, -1 do
                    G.playing_cards[i]:set_ability(G.P_CENTERS.m_glass)
                    G.playing_cards[i]:set_edition({
                        polychrome = true
                    }, true, true)
                end
                return true
            end
        }))
    end
}

----------------------------------------------
------------MOD CODE END----------------------
