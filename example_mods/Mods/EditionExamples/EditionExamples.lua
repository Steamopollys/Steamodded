--- STEAMODDED HEADER
--- MOD_NAME: Edition Examples
--- MOD_ID: EditionExamples
--- PREFIX: edex
--- MOD_AUTHOR: [Eremel_, stupxd]
--- MOD_DESCRIPTION: Adds editions that demonstrate Edition API.
--- BADGE_COLOUR: 3FC7EB
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0905a]

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
        info_queue[#info_queue + 1] = G.P_CENTERS.e_greyscale
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
                sendDebugMessage(G.localization.misc.labels["edex_greyscale"], "EditionExamples")
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
        info_queue[#info_queue + 1] = G.P_CENTERS.e_greyscale
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
        consumables = { 'c_edex_grey_card' },
        vouchers = { 'v_hone' }
    },
    discovered = true,
    unlocked = true
})

---- CUSTOM VARS USAGE EXAMPLE
SMODS.Shader {
    key = 'gold',
    path = 'gold.fs',
    -- card can be nil if sprite.role.major is not Card
    send_vars = function (sprite, card)
        return {
            lines_offset = card and card.edition.example_gold_seed or 0
        }
    end,
}
SMODS.Edition {
    key = "gold",
    shader = "gold",
    on_apply = function (card)
        -- Randomize offset to -1..1
        -- Save in card.edition table so it persists after game restart.
        card.edition.example_gold_seed = pseudorandom('e_example_gold') * 2 - 1
    end,
}
---- CUSTOM VARS USAGE EXAMPLE END


SMODS.Shader({ key = 'anaglyphic', path = 'anaglyphic.fs' })
SMODS.Shader({ key = 'flipped', path = 'flipped.fs' })
SMODS.Shader({ key = 'fluorescent', path = 'fluorescent.fs' })
-- SMODS.Shader({key = 'gilded', path = 'gilded.fs'})
SMODS.Shader({ key = 'greyscale', path = 'greyscale.fs' })
-- SMODS.Shader({key = 'ionized', path = 'ionized.fs'})
-- SMODS.Shader({key = 'laminated', path = 'laminated.fs'})
-- SMODS.Shader({key = 'monochrome', path = 'monochrome.fs'})
SMODS.Shader({ key = 'overexposed', path = 'overexposed.fs' })
-- SMODS.Shader({key = 'sepia', path = 'sepia.fs'})

SMODS.Edition({
    key = "flipped",
    loc_txt = {
        name = "Flipped",
        label = "Flipped",
        text = {
            "nothin"
        }
    },
    -- Stop shadow from being rendered under the card
    disable_shadow = true,
    -- Stop extra layer from being rendered below the card.
    -- For edition that modify shape or transparency of the card.
    disable_base_shader = true,
    shader = "flipped",
    discovered = true,
    unlocked = true,
    config = {},
    in_shop = true,
    weight = 8,
    extra_cost = 6,
    apply_to_float = true,
    loc_vars = function(self)
        return { vars = {} }
    end
})

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
        return { vars = { self.config.p_dollars } }
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
        return { vars = { self.config.chips, self.config.mult } }
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
