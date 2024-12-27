--- STEAMODDED HEADER
--- MOD_NAME: Deck of 4
--- MOD_ID: DeckOf4
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Create a special deck that only contains 4s!
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Back{
    name = "Deck of fours",
    key = "fours",
    pos = {x = 1, y = 3},
    config = {only_one_rank = '4'},
    loc_txt = {
        name ="Deck of fours",
        text={
            "Start with a Deck",
            "full of {C:attention}Fours{}",
        },
    },
    apply = function(self)
        G.E_MANAGER:add_event(Event({
            func = function()
                for _, card in ipairs(G.playing_cards) do
                    assert(SMODS.change_base(card, nil, self.config.only_one_rank))
                end
                return true
            end
        }))
    end
}

----------------------------------------------
------------MOD CODE END----------------------
