--- STEAMODDED HEADER
--- MOD_NAME: Edition Examples
--- MOD_ID: EditionExamples
--- PREFIX: edex
--- MOD_AUTHOR: [Eremel_]
--- MOD_DESCRIPTION: Adds editions that demonstrate Edition API.
--- BADGE_COLOUR: 3FC7EB


local mod_path = SMODS.current_mod.path
-- SMODS.Sprite:new("High Exposure", mod.path, "high exposure.png", 71, 95, "asset_atli"):register()
-- SMODS.Sprite:new("Neon", mod.path, "neon.png", 71, 95, "asset_atli"):register()
-- SMODS.Sprite:new("Grey", mod.path, "grey.png", 71, 95, "asset_atli"):register()

-- local fluorDef = {
--     name = "Fluorescent",
--     slug = "fluorescent",
--     config = { labels = {'mult_mod'}, values = {100} },
--     shader_path = mod.path .. "/assets/shaders/fluorescent.fs",
--     loc_txt = { name = "Fluorescent", text = {"{C:mult}+#1#{} Mult"}},
--     discovered = true,
--     unlocked = true,
--     unlock_condition = {},
--     badge_colour = G.C.EDITION,
--     extra_cost = 5,
--     calculate = function(self, context)
--         if context.edition or (context.cardarea == G.play and self.playing_card) then
--             ret = {}
--             for k, v in pairs(self.edition) do
--                 ret[k] = v
--             end
--             return ret
--         end
--     end
-- }

-- local overexposedDef = {
--     name = "Overexposed",
--     slug = "overexposed",
--     config = { labels = {'repetitions'}, values = {1} },
--     shader_path = mod.path .. "/assets/shaders/overexposed.fs",
--     loc_txt = { name = "Overexposed", text = {"{C:money}+$#1#{} when a hand","is scored"}},
--     discovered = true,
--     unlocked = true,
--     unlock_condition = {},
--     apply_to_float = true,
--     badge_colour = G.C.DARK_EDITION,
--     weight = 5,
--     in_shop = true,
--     extra_cost = 4,
--     calculate = function(self, context)
--         if context.repetition then
--             return {
--                 message = localize('k_again_ex'),
--                 repetitions = 1,
--                 card = self
--             }
--         end
--     end
-- }

local greyDef = {
    name = "Greyscale",
    key = "greyscale",
    config = { labels = {'chip_mod','mult_mod','x_mult_mod'}, values = {200, 10, 2} },
    shader_path = mod_path .. "/assets/shaders/greyscale.fs",
    loc_txt = { name = "Greyscale", text = {"{C:chips}+#1#{} chips, {C:mult}+#2#{} Mult", "and {X:mult,C:white}X#3#{} Mult"}},
    discovered = true,
    unlocked = true,
    unlock_condition = {},
    apply_to_float = true,
    weight = 8,
    in_shop = true,
    extra_cost = 6,
    calculate = function(self, context)
        if context.edition or (context.cardarea == G.play and self.playing_card) then
            ret = {}
            for k, v in pairs(self.edition) do
                ret[k] = v
            end
            return ret
        end
    end
}

-- local anaglyphDef = {
--     name = "Anaglyphic",
--     slug = "anaglyphic",
--     config = { labels = {'chip_mod', 'mult_mod'}, values = {-50, 50} },
--     shader_path = mod.path .. "/assets/shaders/anaglyphic.fs",
--     loc_txt = { name = "Anaglyphic", text = {"{C:chips}#1#{} chips, {C:mult}+#2#{} Mult"}},
--     discovered = true,
--     unlocked = true,
--     unlock_condition = {},
--     badge_colour = G.C.DARK_EDITION,
--     weight = 10,
--     in_shop = true,
--     extra_cost = 1,
--     calculate = function(self, context)
--         if context.edition or (context.cardarea == G.play and self.playing_card) then
--             ret = {}
--             for k, v in pairs(self.edition) do
--                 ret[k] = v
--             end
--             return ret
--         end
--     end
-- }

-- local flippedDef = {
--     name = "Monochrome",
--     slug = "monochrome",
--     config = { labels = {'chip_mod'}, values = {10} },
--     shader_path = mod.path .. "/assets/shaders/monochrome.fs",
--     loc_txt = { name = "Monochrome", text = {"Earn {C:money}$#1#{} when a","hand is scored"}},
--     discovered = true,
--     unlocked = true,
--     unlock_condition = {},
--     badge_colour = G.C.DARK_EDITION,
--     calculate = function(self, context)
--         if context.edition or (context.cardarea == G.play and self.playing_card) then
--             ease_dollars(self.edition.p_dollars)
--             card_eval_status_text(self, 'dollars', self.edition.p_dollars)
--         end
--     end
-- }

-- local sepiaDef = {
--     name = "Sepia",
--     slug = "sepia",
--     config = { labels = {'chip_mod'}, values = {10} },
--     shader_path = mod.path .. "/assets/shaders/sepia.fs",
--     loc_txt = { name = "Sepia", text = {"{C:chips}+#1#{} chips"}},
--     discovered = true,
--     unlocked = true,
--     unlock_condition = {},
--     badge_colour = G.C.DARK_EDITION,
--     weight = 3,
--     in_shop = true,
--     extra_cost = 4,
--     calculate = function(self, context)
--         if context.edition or (context.cardarea == G.play and self.playing_card) then
--             hand_chips = mod_chips(hand_chips + self.edition.chip_mod)
--             update_hand_text({delay = 0}, {chips = hand_chips})
--             card_eval_status_text(self, 'chips', self.edition. chip_mod, percent)
--             -- ret = {}
--             -- for k, v in pairs(self.edition) do
--             --     ret[k] = v
--             -- end
--             -- return ret
--         end
--     end
-- }

SMODS.Edition:new(greyDef):register()
-- SMODS.Edition:new(anaglyphDef):register()
-- SMODS.Edition:new(overexposedDef):register()
-- SMODS.Edition:new(fluorDef):register()
-- SMODS.Edition:new(flippedDef):register()
-- SMODS.Edition:new(sepiaDef):register()    
    
-- local c_high_exposure = SMODS.Spectral:new('High Exposure', 'high_exposure', {}, {
--     x = 0,
--     y = 0
-- }, {
--     name = "Test Card",
--     text = {"Add {C:dark_edition}Foil{} or {C:dark_edition}Sepia{}","to a random joker"}
-- }, 4, nil, nil, 'High Exposure')

-- local c_neon = SMODS.Spectral:new('Neon', 'neon', {}, {
--     x = 0,
--     y = 0
-- }, {
--     name = "+Sepia",
--     text = {"Increase {C:dark_edition}Sepia{} chip", "value by {C:chips}+10{}"}
-- }, 4, nil, nil, 'Neon')

-- local c_grey = SMODS.Spectral:new('Grey', 'grey', {}, {
--     x = 0,
--     y = 0
-- }, {
--     name = "Grey",
--     text = {"Add {C:dark_edition}Greyscale{}", "to a random joker"}
-- }, 4, nil, nil, 'Grey')

-- c_high_exposure:register()
-- c_neon:register()
-- c_grey:register()


-- -- two cards in hand overexposed
-- function SMODS.Spectrals.c_high_exposure.can_use(card)
--     if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or
--         any_state then
--             if G.hand and (#G.hand.highlighted == 4) and G.hand.highlighted[1] and G.hand.highlighted[2] and G.hand.highlighted[3] and G.hand.highlighted[4] and (not G.hand.highlighted[1].edition) and (not G.hand.highlighted[2].edition) and (not G.hand.highlighted[3].edition) and (not G.hand.highlighted[4].edition) then return true end
--     end
-- end

-- function SMODS.Spectrals.c_high_exposure.use(card, area, copier)
--     local used_tarot = (copier or card)
--     local selected_cards = G.hand.highlighted
--     for _,_card in ipairs(selected_cards) do
--     G.E_MANAGER:add_event(Event({
--         trigger = 'after',
--         delay = 0.6,
--         func = function()
--                 local selected_edition = poll_edition("custom_editions", nil, nil, true, {{name = "sepia", weight = 1}, {name = "overexposed", weight = 1}, {name = "anaglyphic", weight = 1}, {name = "fluorescent", weight = 1}})
--                 _card.set_edition(_card, selected_edition)
--                 for k,_ in pairs(selected_edition) do
--                     used_tarot:juice_up(0.3, 0.5)
--                 attention_text({
--                     text = "+ "..k,
--                     scale = 1, 
--                     hold = 0.4,
--                     major = used_tarot,
--                     backdrop_colour = G.C.UI_CHIPS,
--                     align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
--                     offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
--                     silent = true
--                     })
--                 end
--                 return true
--             end
--         }))
--     end
-- end

-- -- -- Set joker overexposed
-- -- function SMODS.Spectrals.c_high_exposure.can_use(card)
-- --     if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or
-- --         any_state then
        
-- --         if next(SMODS.Edition:get_editionless_jokers({})) then
-- --             return true
-- --         end
-- --     end
-- -- end

-- -- function SMODS.Spectrals.c_high_exposure.use(card, area, copier)
-- --     local used_tarot = (copier or card)
-- --     local selected_cards = G.hand.highlighted
-- --     local eligible_jokers = SMODS.Edition:get_editionless_jokers({})
-- --     G.E_MANAGER:add_event(Event({
-- --         trigger = 'after',
-- --         delay = 0.4,
-- --         func = function()
-- --             local selected_joker = pseudorandom_element(eligible_jokers, pseudoseed('seed'))
-- --             local selected_edition = poll_edition("photograph", nil, nil, true, {{name = "foil", weight = 1}, {name = "polychrome", weight = 1}})
-- --             selected_joker.set_edition(selected_joker, { overexposed = true })
-- --             used_tarot:juice_up(0.3, 0.5)
-- --             return true
-- --         end
-- --     }))
-- -- end

-- function SMODS.Spectrals.c_high_exposure.loc_def(self, info_queue)
--     info_queue[#info_queue+1] = G.P_CENTERS.e_foil
--     info_queue[#info_queue+1] = G.P_CENTERS.e_sepia
--     return {}
--     end

-- function SMODS.Spectrals.c_neon.can_use(card)
--     if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or
--         any_state then
--         -- if next(SMODS.Edition:get_eligible_jokers({})) then
--         --     return true
--         -- end
--         return true
--     end
-- end

-- function SMODS.Spectrals.c_neon.use(card, area, copier)
--     local used_tarot = (copier or card)
--     local eligible_jokers = SMODS.Edition:get_editionless_jokers({})
--     G.E_MANAGER:add_event(Event({
--         trigger = 'after',
--         delay = 0.4,
--         func = function()
--             local over = false
--             -- local selected_joker = pseudorandom_element(eligible_jokers, pseudoseed('seed'))
--             -- selected_joker.set_edition(selected_joker, { fluorescent = true })
--             SMODS.Editions.sepia:change_modifier("chip_mod", 10)
--             attention_text({
--                 text = "+10 chips",
--                 scale = 1, 
--                 hold = 1.4,
--                 major = used_tarot,
--                 backdrop_colour = G.C.UI_CHIPS,
--                 align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
--                 offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
--                 silent = true
--                 })
--             used_tarot:juice_up(0.3, 0.5)
--             return true
--         end
--     }))
-- end

-- function SMODS.Spectrals.c_neon.loc_def(self, info_queue)
--     info_queue[#info_queue+1] = G.P_CENTERS.e_sepia
--     return {}
--     end

SMODS.Atlas({
    key = 'edition_example',
    px = 71,
    py = 95,
    path = 'Tarots.png'
})

SMODS.Consumable({
    set = "Spectral",
    key = "grey_card",
    pos = {
        x = 0,
        y = 0
    },
    loc_txt = {
        name = "Grey",
        text = {
            "Add {C:dark_edition}Greyscale{}",
            "to a random joker"
        }
    },
    atlas = 'edition_example',
    cost = 4,
    discovered = true,
    can_use = function(self, card)
        if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or
        any_state then
            if next(SMODS.Edition:get_editionless_jokers({})) then
                return true
            end
        end
    end,
    use = function(card, area, copier)
        local used_tarot = (copier or card)
        local eligible_jokers = SMODS.Edition:get_editionless_jokers({})
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                local selected_joker = pseudorandom_element(eligible_jokers, pseudoseed('seed'))
                local selected_edition = poll_edition("custom_editions", nil, nil, true, {{name = "holo", weight = 1}, {name = "greyscale", weight = 1}, {name = "negative", weight = 1}, {name = "foil", weight = 1}})
                selected_joker.set_edition(selected_joker, { negative = true })
                used_tarot:juice_up(0.3, 0.5)
                return true
            end
        }))
    end,
    loc_vars = function(self, info_queue)
        info_queue[#info_queue+1] = G.P_CENTERS.e_greyscale
        return {}
    end
})

SMODS.Back({
    name = 'test_deck',
    key = 'test_deck',
    loc_txt = {
        name = 'Test Deck',
        text = {
            "Start with a {C:spectral}Grey Card{}."
        }
    },
    config = {
        consumables = {'c_edex_grey_card'},
    },
    discovered = true,
    unlocked = true
})

if G.P_CENTERS['b_edex_test_deck'] then
    sendInfoMessage("Test Deck loaded", "Edition Example")
else
    sendInfoMessage("Test Deck not loaded", "Edition Example")
end




----------------------------------------------
------------MOD CODE END----------------------
