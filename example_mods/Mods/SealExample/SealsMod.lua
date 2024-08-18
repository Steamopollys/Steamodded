--- STEAMODDED HEADER
--- MOD_NAME: Modded Seal
--- MOD_ID: seel-mod
--- MOD_AUTHOR: [stupxd]
--- PREFIX: seel
--- MOD_DESCRIPTION: Modded seal example
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Seal {
    name = "modded-Seal",
    key = "blu",
    badge_colour = HEX("1d4fd7"),
	config = { mult = 5, chips = 20, money = 1, x_mult = 1.5  },
    loc_txt = {
        -- Badge name (displayed on card description when seal is applied)
        label = 'Blu Seal',
        -- Tooltip description
        description = {
            name = 'Blu Seal',
            text = {
                '{C:mult}+#1#{} Mult',
                '{C:chips}+#2#{} Chips',
                '{C:money}$#3#{}',
                '{X:mult,C:white}X#4#{} Mult',
            }
        },
    },
    loc_vars = function(self, info_queue)
        return { vars = {self.config.mult, self.config.chips, self.config.money, self.config.x_mult, } }
    end,
    atlas = "seal_atlas",
    pos = {x=0, y=0},

    -- self - this seal prototype
    -- card - card this seal is applied to
    calculate = function(self, card, context)
        -- repetition_only context is used for red seal retriggers
        if not context.repetition_only and context.cardarea == G.play then
            return {
                mult = self.config.mult,
                chips = self.config.chips,
                dollars = self.config.money,
                x_mult = self.config.x_mult
            }
        end
    end,
}

SMODS.Atlas {
    key = "seal_atlas",
    path = "modded_seal.png",
    px = 71,
    py = 95
}

-- Create consumable that will add this seal.

SMODS.Consumable {
    set = "Spectral",
    name = "modded-Spectral",
    key = "honk",
	config = {
        -- This will add a tooltip for seal when hovering on spectral.
        -- `s` means seal (set), `seel` is mod prefix, `_seal` is added at the end automatically for all seals
        mod_conv = 's_seel_blu_seal',
        -- Tooltip args
        seal = { mult = 5, chips = 20, money = 1, x_mult = 1.5 },
        -- How many cards can be selected.
        max_highlighted = 1,
    },
    loc_vars = function(self, info_queue, center)
        -- Handle creating a tooltip with seal args.
        info_queue[#info_queue+1] = {
            set = 'Other',
            key = 's_seel_blu_seal',
            specific_vars = {
                self.config.seal.mult,
                self.config.seal.chips,
                self.config.seal.money,
                self.config.seal.x_mult,
            }
        }
        -- Description vars
        return {vars = {center.ability.max_highlighted}}
    end,
    loc_txt = {
        name = 'Honk',
        text = {
            "Select {C:attention}#1#{} card to",
            "apply {C:attention}Blu Seal{}"
        }
    },
    cost = 4,
    atlas = "honk_atlas",
    pos = {x=0, y=0},
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                for i = 1, card.ability.max_highlighted do
                    local highlighted = G.hand.highlighted[i]

                    if highlighted then
                        highlighted:set_seal('s_seel_blu')
                    else
                        break
                    end
                end
                return true
            end
        }))
    end
}

SMODS.Atlas {
    key = "honk_atlas",

    path = "honk.png",
    px = 71,
    py = 95
}

----------------------------------------------
------------MOD CODE END----------------------
