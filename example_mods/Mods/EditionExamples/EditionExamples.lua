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
            if next(SMODS.Edition:get_edition_cards(G.jokers, true)) then
                return true
            end
        end
    end,
    use = function(card, area, copier)
        local used_tarot = (copier or card)
        local eligible_jokers = SMODS.Edition:get_edition_cards(G.jokers, true)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                local selected_joker = pseudorandom_element(eligible_jokers, pseudoseed('seed'))
                local selected_edition = poll_edition("aura", nil, true, false)
                selected_joker.set_edition(selected_joker, 'e_edex_greyscale')
                return true
            end
        }))
    end,
    loc_vars = function(self, info_queue)
        info_queue[#info_queue+1] = G.P_CENTERS.e_greyscale
        return {}
    end
})

SMODS.Consumable({
    set = "Spectral",
    key = "neon_crad",
    pos = {
        x = 1,
        y = 0
    },
    loc_txt = {
        name = "Neon",
        text = {
            "Remove any edition from", 
            "selected joker"
        }
    },
    atlas = 'edition_example',
    cost = 4,
    discovered = true,
    can_use = function(self, card)
        if G.STATE ~= G.STATES.HAND_PLAYED and G.STATE ~= G.STATES.DRAW_TO_HAND and G.STATE ~= G.STATES.PLAY_TAROT or
        any_state then
            if G.localization.misc.labels["edex_greyscale"] then
                sendDebugMessage(G.localization.misc.labels["edex_greyscale"])
            end
            if #G.jokers.highlighted == 1 and G.jokers.highlighted[1].edition then
                return true
            end
        end
    end,
    use = function(card, area, copier)
        local used_tarot = (copier or card)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                G.jokers.highlighted[1].set_edition(G.jokers.highlighted[1])
                G.jokers:unhighlight_all()
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
        vouchers = {'v_hone'}
    },
    discovered = true,
    unlocked = true
})

SMODS.Shader({key = 'anaglyphic', path = 'anaglyphic.fs'})
-- SMODS.Shader({key = 'flipped', path = 'flipped.fs'})
SMODS.Shader({key = 'fluorescent', path = 'fluorescent.fs'})
-- SMODS.Shader({key = 'gilded', path = 'gilded.fs'})
SMODS.Shader({key = 'greyscale', path = 'greyscale.fs'})
-- SMODS.Shader({key = 'ionized', path = 'ionized.fs'})
-- SMODS.Shader({key = 'laminated', path = 'laminated.fs'})
-- SMODS.Shader({key = 'monochrome', path = 'monochrome.fs'})
SMODS.Shader({key = 'overexposed', path = 'overexposed.fs'})
-- SMODS.Shader({key = 'sepia', path = 'sepia.fs'})

SMODS.Edition({
    key = "greyscale",
    loc_txt = {
        name = "Greyscale",
        label = "Greyscale",
        text = {
            "{C:chips}+#1#{} chips, {C:mult}+#2#{} Mult",
            "and {X:mult,C:white}X#3#{} Mult"
        }
    },
    shader = "greyscale",
    discovered = true,
    unlocked = true,
    config = { chips = 200, mult = 10, x_mult = 2 },
    in_shop = true,
    weight = 8,
    extra_cost = 6,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = { self.config.chips, self.config.mult, self.config.x_mult } }
    end
})

SMODS.Edition({
    key = "fluorescent",
    loc_txt = {
        name = "Fluorescent",
        label = "Fluorescent",
        text = {
            "Earn {C:money}$#1#{} when this",
            "card is scored"
        }
    },
    discovered = true,
    unlocked = true,
    shader = 'fluorescent',
    config = { p_dollars = 3 },
    in_shop = true,
    weight = 8,
    extra_cost = 4,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = {self.config.p_dollars}}
    end
})

SMODS.Edition({
    key = "anaglyphic",
    loc_txt = {
        name = "Anaglyphic",
        label = "Anaglyphic",
        text = {
            "{C:chips}+#1#{} Chips",
            "{C:red}+#2#{} Mult"
        }
    },
    discovered = true,
    unlocked = true,
    shader = 'anaglyphic',
    config = { chips = 10, mult = 4 },
    in_shop = true,
    weight = 8,
    extra_cost = 4,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = {self.config.chips, self.config.mult}}
    end
})

SMODS.Edition({
    key = "overexposed",
    loc_txt = {
        name = "Overexposed",
        label = "Overexposed",
        text = {
            "{C:green}Retrigger{} this card"
        }
    },
    discovered = true,
    unlocked = true,
    shader = 'overexposed',
    config = { repetitions = 1 },
    in_shop = true,
    weight = 8,
    extra_cost = 4,
    apply_to_float = true,
    loc_vars = function(self)
        return {}
    end
})



----------------------------------------------
------------MOD CODE END----------------------
