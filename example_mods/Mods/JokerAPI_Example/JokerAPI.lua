--- STEAMODDED HEADER
--- MOD_NAME: JAPI
--- MOD_ID: JAPI
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Joker API Test Mod
--- LOADER_VERSION_GEQ: 1.0.0

----------------------------------------------
------------MOD CODE -------------------------

function SMODS.current_mod.process_loc_text()
    G.localization.descriptions.Other['joker_test_key'] = {
        name = 'Tooltip Test',
        text = {
            'So {C:red}HILARIOUS{}!',
            'Still {C:red}+#1#{} Mult'
        }
    }
end

SMODS.Atlas{
    key = "jokers",
    path = "jokers.png",
    px = 71,
    py = 95
}

-- Available specific Joker parameters
-- SMODS.Joker{key, name, rarity, unlocked, discovered, blueprint_compat, perishable_compat, eternal_compat, pos, cost, config, set, prefix}
SMODS.Joker{
    key = "test",
    name = "Joker Test",
    rarity = 1,
    discovered = true,
    pos = {x = 0, y = 0},
    cost = 4,
    config = {mult = 20},
    loc_txt = {
        name = "Joker Test",
        text = {
            "AHAHA",
            "Jokes on",
            "{C:attention}You{}!",
            "{C:inactive}({C:mult}+#1#{C:inactive} Mult)"
        }
    },
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue+1] = {set = 'Other', key = 'joker_test_key', vars = {card.ability.mult}}
        return {vars = {card.ability.mult}}
    end,
    calculate = function(card, context)
        if SMODS.end_calculate_context(context) then
            return {
                mult_mod = card.ability.mult,
                colour = G.C.RED,
                message = "AHAHAHAH"
            }
        end
    end,
    atlas = "jokers"
}

----------------------------------------------
------------MOD CODE END----------------------
