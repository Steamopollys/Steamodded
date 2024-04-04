SMODS.Blinds = {}
SMODS.Blind = {
    name = "",
    slug = "",
    loc_txt = {},
    dollars = 5,
    mult = 2,
    vars = {},
    debuff = {},
    pos = { x = 0, y = 0 },
    boss = {},
    boss_colour =
        HEX('FFFFFF'),
    defeated = false
}

function SMODS.Blind:new(name, slug, loc_txt, dollars, mult, vars, debuff, pos, boss, boss_colour, defeated, atlas)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt
    o.name = name
    o.slug = "bl_" .. slug
    o.dollars = dollars or 5
    o.mult = mult or 2
    o.vars = vars or {}
    o.debuff = debuff or {}
    o.pos = pos or { x = 0, y = 0 }
    o.boss = boss or {}
    o.boss_colour = boss_colour or HEX('FFFFFF')
    o.discovered = defeated or false
    o.atlas = atlas or "BlindChips"

    return o
end

function SMODS.Blind:register()
    if not SMODS.Blinds[self.slug] then
        SMODS.Blinds[self.slug] = self
        SMODS.BUFFERS.Blinds[#SMODS.BUFFERS.Blinds + 1] = self.slug
    end
end

function SMODS.injectBlinds()
    local minId = table_length(G.P_BLINDS) + 1
    local id = 0
    local i = 0
    local blind = nil

    for _, slug in ipairs(SMODS.BUFFERS.Blinds) do
        i = i + 1
        id = i + minId
        blind = SMODS.Blinds[slug]
        local blind_obj = {
            key = blind.slug,
            order = id,
            name = blind.name,
            dollars = blind.dollars,
            mult = blind.mult,
            vars = blind.vars,
            debuff = blind.debuff,
            pos = blind.pos,
            boss = blind.boss,
            boss_colour = blind.boss_colour,
            discovered = blind.discovered,
            atlas = blind.atlas
        }
        -- Now we replace the others
        G.P_BLINDS[blind.slug] = blind_obj

        -- Setup Localize text
        G.localization.descriptions["Blind"][blind.slug] = blind.loc_txt

        sendDebugMessage("The Blind named " ..
            blind.name .. " with the slug " .. blind.slug .. " have been registered at the id " .. id .. ".")
    end
end

local set_blindref = Blind.set_blind;
function Blind:set_blind(blind, reset, silent)
    set_blindref(self, blind, reset, silent)
    if not reset then
        local prev_anim = self.children.animatedSprite
        self.config.blind = blind or {}
        local blind_atlas = 'blind_chips'
        if self.config.blind and self.config.blind.atlas then
            blind_atlas = self.config.blind.atlas
        end
        self.children.animatedSprite = AnimatedSprite(self.T.x, self.T.y, self.T.w, self.T.h,
            G.ANIMATION_ATLAS[blind_atlas],
            G.P_BLINDS.bl_small.pos)
        self.children.animatedSprite.states = prev_anim.states
        self.children.animatedSprite.states.visible = prev_anim.states.visible
        self.children.animatedSprite.states.drag.can = prev_anim.states.drag.can
        local key = self.config.blind.key
        local blind_obj = SMODS.Blinds[key]
        if blind_obj and blind_obj.set_blind and type(blind_obj.set_blind) == 'function' then
            blind_obj.set_blind(self, blind, reset, silent)
        end
    end
    for _, v in ipairs(G.playing_cards) do
        self:debuff_card(v)
    end
    for _, v in ipairs(G.jokers.cards) do
        if not reset then self:debuff_card(v, true) end
    end
end

local blind_disable_ref = Blind.disable
function Blind:disable()
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.disable and type(blind_obj.disable) == 'function' then
        blind_obj.disable(self)
    end
    blind_disable_ref(self)
end

local blind_defeat_ref = Blind.defeat
function Blind:defeat(silent)
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.defeat and type(blind_obj.defeat) == 'function' then
        blind_obj.set_blind(self, silent)
    end
    blind_defeat_ref(self, silent)
end

local blind_debuff_card_ref = Blind.debuff_card
function Blind:debuff_card(card, from_blind)
    blind_debuff_card_ref(self, card, from_blind)
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.debuff_card and type(blind_obj.debuff_card) == 'function' and not self.disabled then
        blind_obj.debuff_card(self, card, from_blind)
    end
end

local blind_stay_flipped_ref = Blind.stay_flipped
function Blind:stay_flipped(area, card)
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.stay_flipped and type(blind_obj.stay_flipped) == 'function' and not self.disabled and area == G.hand then
        return blind_obj.stay_flipped(self, area, card)
    end
    return blind_stay_flipped_ref(self, area, card)
end

local blind_drawn_to_hand_ref = Blind.drawn_to_hand
function Blind:drawn_to_hand()
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.drawn_to_hand and type(blind_obj.drawn_to_hand) == 'function' and not self.disabled then
        blind_obj.drawn_to_hand(self)
    end
    blind_drawn_to_hand_ref(self)
end

local blind_debuff_hand_ref = Blind.debuff_hand
function Blind:debuff_hand(cards, hand, handname, check)
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.debuff_hand and type(blind_obj.debuff_hand) == 'function' and not self.disabled then
        return blind_obj.debuff_hand(self, cards, hand, handname, check)
    end
    return blind_debuff_hand_ref(self, cards, hand, handname, check)
end

local blind_modify_hand_ref = Blind.modify_hand
function Blind:modify_hand(cards, poker_hands, text, mult, hand_chips)
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.modify_hand and type(blind_obj.modify_hand) == 'function' and not self.debuff then
        return blind_obj.modify_hand(cards, poker_hands, text, mult, hand_chips)
    end
    return blind_modify_hand_ref(cards, poker_hands, text, mult, hand_chips)
end

local blind_press_play_ref = Blind.press_play
function Blind:press_play()
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.press_play and type(blind_obj.press_play) == 'function' and not self.disabled then
        return blind_obj.press_play(self)
    end
    return blind_press_play_ref(self)
end

local blind_get_loc_debuff_text_ref = Blind.get_loc_debuff_text
function Blind:get_loc_debuff_text()
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    if blind_obj and blind_obj.get_loc_debuff_text and type(blind_obj.get_loc_debuff_text) == 'function' then
        return blind_obj.get_loc_debuff_text(self)
    end
    return blind_get_loc_debuff_text_ref(self)
end

local blind_set_text = Blind.set_text
function Blind:set_text()
    local key = self.config.blind.key
    local blind_obj = SMODS.Blinds[key]
    local loc_vars = nil
    if blind_obj and blind_obj.loc_def and type(blind_obj.loc_def) == 'function' and not self.disabled then
        loc_vars = blind_obj.loc_def(self)
        local loc_target = localize { type = 'raw_descriptions', key = self.config.blind.key, set = 'Blind', vars = loc_vars or self.config.blind.vars }
        if loc_target then
            self.loc_name = self.name == '' and self.name or
                localize { type = 'name_text', key = self.config.blind.key, set = 'Blind' }
            self.loc_debuff_text = ''
            for k, v in ipairs(loc_target) do
                self.loc_debuff_text = self.loc_debuff_text .. v .. (k <= #loc_target and ' ' or '')
            end
            self.loc_debuff_lines[1] = loc_target[1] or ''
            self.loc_debuff_lines[2] = loc_target[2] or ''
        else
            self.loc_name = ''; self.loc_debuff_text = ''
            self.loc_debuff_lines[1] = ''
            self.loc_debuff_lines[2] = ''
        end
        return
    end
    blind_set_text(self)
end

function create_UIBox_blind_choice(type, run_info)
    if not G.GAME.blind_on_deck then
        G.GAME.blind_on_deck = 'Small'
    end
    if not run_info then G.GAME.round_resets.blind_states[G.GAME.blind_on_deck] = 'Select' end

    local disabled = false
    type = type or 'Small'

    local blind_choice = {
        config = G.P_BLINDS[G.GAME.round_resets.blind_choices[type]],
    }

    local blind_atlas = 'blind_chips'
    if blind_choice.config and blind_choice.config.atlas then
        blind_atlas = blind_choice.config.atlas
    end
    blind_choice.animation = AnimatedSprite(0, 0, 1.4, 1.4, G.ANIMATION_ATLAS[blind_atlas], blind_choice.config.pos)
    blind_choice.animation:define_draw_steps({
        { shader = 'dissolve', shadow_height = 0.05 },
        { shader = 'dissolve' }
    })
    local extras = nil
    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)

    G.GAME.orbital_choices = G.GAME.orbital_choices or {}
    G.GAME.orbital_choices[G.GAME.round_resets.ante] = G.GAME.orbital_choices[G.GAME.round_resets.ante] or {}

    if not G.GAME.orbital_choices[G.GAME.round_resets.ante][type] then
        local _poker_hands = {}
        for k, v in pairs(G.GAME.hands) do
            if v.visible then _poker_hands[#_poker_hands + 1] = k end
        end

        G.GAME.orbital_choices[G.GAME.round_resets.ante][type] = pseudorandom_element(_poker_hands, pseudoseed('orbital'))
    end



    if type == 'Small' then
        extras = create_UIBox_blind_tag(type, run_info)
    elseif type == 'Big' then
        extras = create_UIBox_blind_tag(type, run_info)
    elseif not run_info then
        local dt1 = DynaText({ string = { { string = localize('ph_up_ante_1'), colour = G.C.FILTER } }, colours = { G.C.BLACK }, scale = 0.55, silent = true, pop_delay = 4.5, shadow = true, bump = true, maxw = 3 })
        local dt2 = DynaText({ string = { { string = localize('ph_up_ante_2'), colour = G.C.WHITE } }, colours = { G.C.CHANCE }, scale = 0.35, silent = true, pop_delay = 4.5, shadow = true, maxw = 3 })
        local dt3 = DynaText({ string = { { string = localize('ph_up_ante_3'), colour = G.C.WHITE } }, colours = { G.C.CHANCE }, scale = 0.35, silent = true, pop_delay = 4.5, shadow = true, maxw = 3 })
        extras =
        {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.07, r = 0.1, colour = { 0, 0, 0, 0.12 }, minw = 2.9 },
                    nodes = {
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                { n = G.UIT.O, config = { object = dt1 } },
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                { n = G.UIT.O, config = { object = dt2 } },
                            }
                        },
                        {
                            n = G.UIT.R,
                            config = { align = "cm" },
                            nodes = {
                                { n = G.UIT.O, config = { object = dt3 } },
                            }
                        },
                    }
                },
            }
        }
    end
    G.GAME.round_resets.blind_ante = G.GAME.round_resets.blind_ante or G.GAME.round_resets.ante
    local loc_target = localize { type = 'raw_descriptions', key = blind_choice.config.key, set = 'Blind', vars = { localize(G.GAME.current_round.most_played_poker_hand, 'poker_hands') } }
    local loc_name = localize { type = 'name_text', key = blind_choice.config.key, set = 'Blind' }
    local text_table = loc_target
    local blind_col = get_blind_main_colour(type)
    local blind_amt = get_blind_amount(G.GAME.round_resets.blind_ante) * blind_choice.config.mult *
        G.GAME.starting_params.ante_scaling

    local blind_state = G.GAME.round_resets.blind_states[type]
    local _reward = true
    if G.GAME.modifiers.no_blind_reward and G.GAME.modifiers.no_blind_reward[type] then _reward = nil end
    if blind_state == 'Select' then blind_state = 'Current' end
    local run_info_colour = run_info and
        (blind_state == 'Defeated' and G.C.GREY or blind_state == 'Skipped' and G.C.BLUE or blind_state == 'Upcoming' and G.C.ORANGE or blind_state == 'Current' and G.C.RED or G.C.GOLD)
    local t =
    {
        n = G.UIT.R,
        config = { id = type, align = "tm", func = 'blind_choice_handler', minh = not run_info and 10 or nil, ref_table = { deck = nil, run_info = run_info }, r = 0.1, padding = 0.05 },
        nodes = {
            {
                n = G.UIT.R,
                config = { align = "cm", colour = mix_colours(G.C.BLACK, G.C.L_BLACK, 0.5), r = 0.1, outline = 1, outline_colour = G.C.L_BLACK },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.2 },
                        nodes = {
                            not run_info and
                            {
                                n = G.UIT.R,
                                config = { id = 'select_blind_button', align = "cm", ref_table = blind_choice.config, colour = disabled and G.C.UI.BACKGROUND_INACTIVE or G.C.ORANGE, minh = 0.6, minw = 2.7, padding = 0.07, r = 0.1, shadow = true, hover = true, one_press = true, button = 'select_blind' },
                                nodes = {
                                    { n = G.UIT.T, config = { ref_table = G.GAME.round_resets.loc_blind_states, ref_value = type, scale = 0.45, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.UI.TEXT_LIGHT, shadow = not disabled } }
                                }
                            } or
                            {
                                n = G.UIT.R,
                                config = { id = 'select_blind_button', align = "cm", ref_table = blind_choice.config, colour = run_info_colour, minh = 0.6, minw = 2.7, padding = 0.07, r = 0.1, emboss = 0.08 },
                                nodes = {
                                    { n = G.UIT.T, config = { text = localize(blind_state, 'blind_states'), scale = 0.45, colour = G.C.UI.TEXT_LIGHT, shadow = true } }
                                }
                            }
                        }
                    },
                    {
                        n = G.UIT.R,
                        config = { id = 'blind_name', align = "cm", padding = 0.07 },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm", r = 0.1, outline = 1, outline_colour = blind_col, colour = darken(blind_col, 0.3), minw = 2.9, emboss = 0.1, padding = 0.07, line_emboss = 1 },
                                nodes = {
                                    { n = G.UIT.O, config = { object = DynaText({ string = loc_name, colours = { disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE }, shadow = not disabled, float = not disabled, y_offset = -4, scale = 0.45, maxw = 2.8 }) } },
                                }
                            },
                        }
                    },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.05 },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { id = 'blind_desc', align = "cm", padding = 0.05 },
                                nodes = {
                                    {
                                        n = G.UIT.R,
                                        config = { align = "cm" },
                                        nodes = {
                                            {
                                                n = G.UIT.R,
                                                config = { align = "cm", minh = 1.5 },
                                                nodes = {
                                                    { n = G.UIT.O, config = { object = blind_choice.animation } },
                                                }
                                            },
                                            text_table[1] and
                                            {
                                                n = G.UIT.R,
                                                config = { align = "cm", minh = 0.7, padding = 0.05, minw = 2.9 },
                                                nodes = {
                                                    text_table[1] and {
                                                        n = G.UIT.R,
                                                        config = { align = "cm", maxw = 2.8 },
                                                        nodes = {
                                                            { n = G.UIT.T, config = { id = blind_choice.config.key, ref_table = { val = '' }, ref_value = 'val', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled, func = 'HUD_blind_debuff_prefix' } },
                                                            { n = G.UIT.T, config = { text = text_table[1] or '-', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled } }
                                                        }
                                                    } or nil,
                                                    text_table[2] and {
                                                        n = G.UIT.R,
                                                        config = { align = "cm", maxw = 2.8 },
                                                        nodes = {
                                                            { n = G.UIT.T, config = { text = text_table[2] or '-', scale = 0.32, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled } }
                                                        }
                                                    } or nil,
                                                }
                                            } or nil,
                                        }
                                    },
                                    {
                                        n = G.UIT.R,
                                        config = { align = "cm", r = 0.1, padding = 0.05, minw = 3.1, colour = G.C.BLACK, emboss = 0.05 },
                                        nodes = {
                                            {
                                                n = G.UIT.R,
                                                config = { align = "cm", maxw = 3 },
                                                nodes = {
                                                    { n = G.UIT.T, config = { text = localize('ph_blind_score_at_least'), scale = 0.3, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled } }
                                                }
                                            },
                                            {
                                                n = G.UIT.R,
                                                config = { align = "cm", minh = 0.6 },
                                                nodes = {
                                                    { n = G.UIT.O, config = { w = 0.5, h = 0.5, colour = G.C.BLUE, object = stake_sprite, hover = true, can_collide = false } },
                                                    { n = G.UIT.B, config = { h = 0.1, w = 0.1 } },
                                                    { n = G.UIT.T, config = { text = number_format(blind_amt), scale = score_number_scale(0.9, blind_amt), colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.RED, shadow = not disabled } }
                                                }
                                            },
                                            _reward and {
                                                n = G.UIT.R,
                                                config = { align = "cm" },
                                                nodes = {
                                                    { n = G.UIT.T, config = { text = localize('ph_blind_reward'), scale = 0.35, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.WHITE, shadow = not disabled } },
                                                    { n = G.UIT.T, config = { text = string.rep(localize("$"), blind_choice.config.dollars) .. '+', scale = 0.35, colour = disabled and G.C.UI.TEXT_INACTIVE or G.C.MONEY, shadow = not disabled } }
                                                }
                                            } or nil,
                                        }
                                    },
                                }
                            },
                        }
                    },
                }
            },
            {
                n = G.UIT.R,
                config = { id = 'blind_extras', align = "cm" },
                nodes = {
                    extras,
                }
            }

        }
    }
    return t
end

function create_UIBox_your_collection_blinds(exit)
    local blind_matrix = {
        {}, {}, {}, {}, {}, {}
    }
    local blind_tab = {}
    for k, v in pairs(G.P_BLINDS) do
        blind_tab[#blind_tab + 1] = v
    end

    local blinds_per_row = math.ceil(#blind_tab / 6)
    sendDebugMessage("Blinds per row:" .. tostring(blinds_per_row))

    table.sort(blind_tab, function(a, b) return a.order < b.order end)

    local blinds_to_be_alerted = {}
    for k, v in ipairs(blind_tab) do
        local discovered = v.discovered
        local atlas = 'blind_chips'
        if v.atlas and discovered then
            atlas = v.atlas
        end
        local temp_blind = AnimatedSprite(0, 0, 1.3, 1.3, G.ANIMATION_ATLAS[atlas],
            discovered and v.pos or G.b_undiscovered.pos)
        temp_blind:define_draw_steps({
            { shader = 'dissolve', shadow_height = 0.05 },
            { shader = 'dissolve' }
        })
        if k == 1 then
            G.E_MANAGER:add_event(Event({
                trigger = 'immediate',
                func = (function()
                    G.CONTROLLER:snap_to { node = temp_blind }
                    return true
                end)
            }))
        end
        temp_blind.float = true
        temp_blind.states.hover.can = true
        temp_blind.states.drag.can = false
        temp_blind.states.collide.can = true
        temp_blind.config = { blind = v, force_focus = true }
        if discovered and not v.alerted then
            blinds_to_be_alerted[#blinds_to_be_alerted + 1] = temp_blind
        end
        temp_blind.hover = function()
            if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then
                if not temp_blind.hovering and temp_blind.states.visible then
                    temp_blind.hovering = true
                    temp_blind.hover_tilt = 3
                    temp_blind:juice_up(0.05, 0.02)
                    play_sound('chips1', math.random() * 0.1 + 0.55, 0.12)
                    temp_blind.config.h_popup = create_UIBox_blind_popup(v, discovered)
                    temp_blind.config.h_popup_config = { align = 'cl', offset = { x = -0.1, y = 0 }, parent = temp_blind }
                    Node.hover(temp_blind)
                    if temp_blind.children.alert then
                        temp_blind.children.alert:remove()
                        temp_blind.children.alert = nil
                        temp_blind.config.blind.alerted = true
                        G:save_progress()
                    end
                end
            end
            temp_blind.stop_hover = function()
                temp_blind.hovering = false; Node.stop_hover(temp_blind); temp_blind.hover_tilt = 0
            end
        end
        local row = math.ceil((k - 1) / blinds_per_row + 0.001)
        sendDebugMessage("Y:" .. tostring(row) .. " X:" .. tostring(1 + ((k - 1) % 6)))
        table.insert(blind_matrix[row], {
            n = G.UIT.C,
            config = { align = "cm", padding = 0.1 },
            nodes = {
                ((k - blinds_per_row) % (2 * blinds_per_row) == 1) and { n = G.UIT.B, config = { h = 0.2, w = 0.5 } } or
                nil,
                { n = G.UIT.O, config = { object = temp_blind, focus_with_object = true } },
                ((k - blinds_per_row) % (2 * blinds_per_row) == 0) and { n = G.UIT.B, config = { h = 0.2, w = 0.5 } } or
                nil,
            }
        })
    end

    G.E_MANAGER:add_event(Event({
        trigger = 'immediate',
        func = (function()
            for _, v in ipairs(blinds_to_be_alerted) do
                v.children.alert = UIBox {
                    definition = create_UIBox_card_alert(),
                    config = { align = "tri", offset = { x = 0.1, y = 0.1 }, parent = v }
                }
                v.children.alert.states.collide.can = false
            end
            return true
        end)
    }))

    local ante_amounts = {}
    for i = 1, math.min(16, math.max(16, G.PROFILES[G.SETTINGS.profile].high_scores.furthest_ante.amt)) do
        local spacing = 1 -
            math.min(20, math.max(15, G.PROFILES[G.SETTINGS.profile].high_scores.furthest_ante.amt)) * 0.06
        if spacing > 0 and i > 1 then
            ante_amounts[#ante_amounts + 1] = { n = G.UIT.R, config = { minh = spacing }, nodes = {} }
        end
        local blind_chip = Sprite(0, 0, 0.2, 0.2, G.ASSET_ATLAS["ui_" .. (G.SETTINGS.colourblind_option and 2 or 1)],
            { x = 0, y = 0 })
        blind_chip.states.drag.can = false
        ante_amounts[#ante_amounts + 1] = {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.03 },
            nodes = {
                {
                    n = G.UIT.C,
                    config = { align = "cm", minw = 0.7 },
                    nodes = {
                        { n = G.UIT.T, config = { text = i, scale = 0.4, colour = G.C.FILTER, shadow = true } },
                    }
                },
                {
                    n = G.UIT.C,
                    config = { align = "cr", minw = 2.8 },
                    nodes = {
                        { n = G.UIT.O, config = { object = blind_chip } },
                        { n = G.UIT.C, config = { align = "cm", minw = 0.03, minh = 0.01 },                                                                                                                                         nodes = {} },
                        { n = G.UIT.T, config = { text = number_format(get_blind_amount(i)), scale = 0.4, colour = i <= G.PROFILES[G.SETTINGS.profile].high_scores.furthest_ante.amt and G.C.RED or G.C.JOKER_GREY, shadow = true } },
                    }
                }
            }
        }
    end

    local extras = nil
    local t = create_UIBox_generic_options({
        back_func = exit or 'your_collection',
        contents = {
            {
                n = G.UIT.C,
                config = { align = "cm", r = 0.1, colour = G.C.BLACK, padding = 0.1, emboss = 0.05 },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cm", r = 0.1, colour = G.C.L_BLACK, padding = 0.1, force_focus = true, focus_args = { nav = 'tall' } },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {
                                    {
                                        n = G.UIT.C,
                                        config = { align = "cm", minw = 0.7 },
                                        nodes = {
                                            { n = G.UIT.T, config = { text = localize('k_ante_cap'), scale = 0.4, colour = lighten(G.C.FILTER, 0.2), shadow = true } },
                                        }
                                    },
                                    {
                                        n = G.UIT.C,
                                        config = { align = "cr", minw = 2.8 },
                                        nodes = {
                                            { n = G.UIT.T, config = { text = localize('k_base_cap'), scale = 0.4, colour = lighten(G.C.RED, 0.2), shadow = true } },
                                        }
                                    }
                                }
                            },
                            { n = G.UIT.R, config = { align = "cm" }, nodes = ante_amounts }
                        }
                    },
                    {
                        n = G.UIT.C,
                        config = { align = "cm" },
                        nodes = {
                            {
                                n = G.UIT.R,
                                config = { align = "cm" },
                                nodes = {
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = blind_matrix[1] },
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = blind_matrix[2] },
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = blind_matrix[3] },
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = blind_matrix[4] },
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = blind_matrix[5] },
                                    { n = G.UIT.R, config = { align = "cm" }, nodes = blind_matrix[6] },
                                }
                            }
                        }
                    }
                }
            }
        }
    })
    return t
end

function create_UIBox_round_scores_row(score, text_colour)
    local label = G.GAME.round_scores[score] and localize('ph_score_' .. score) or ''
    local check_high_score = false
    local score_tab = {}
    local label_w, score_w, h = ({ hand = true, poker_hand = true })[score] and 3.5 or 2.9,
        ({ hand = true, poker_hand = true })[score] and 3.5 or 1, 0.5

    if score == 'furthest_ante' then
        label_w = 1.9
        check_high_score = true
        label = localize('k_ante')
        score_tab = {
            { n = G.UIT.O, config = { object = DynaText({ string = { number_format(G.GAME.round_resets.ante) }, colours = { text_colour or G.C.FILTER }, shadow = true, float = true, scale = 0.45 }) } },
        }
    end
    if score == 'furthest_round' then
        label_w = 1.9
        check_high_score = true
        label = localize('k_round')
        score_tab = {
            { n = G.UIT.O, config = { object = DynaText({ string = { number_format(G.GAME.round) }, colours = { text_colour or G.C.FILTER }, shadow = true, float = true, scale = 0.45 }) } },
        }
    end
    if score == 'seed' then
        label_w = 1.9
        score_w = 1.9
        label = localize('k_seed')
        score_tab = {
            { n = G.UIT.O, config = { object = DynaText({ string = { G.GAME.pseudorandom.seed }, colours = { text_colour or G.C.WHITE }, shadow = true, float = true, scale = 0.45 }) } },
        }
    end
    if score == 'defeated_by' then
        label = localize('k_defeated_by')
        local blind_choice = { config = G.GAME.blind.config.blind or G.P_BLINDS.bl_small }
        local atlas = 'blind_chips'
        if blind_choice.config.atlas then
            atlas = blind_choice.config.atlas
        end
        blind_choice.animation = AnimatedSprite(0, 0, 1.4, 1.4, G.ANIMATION_ATLAS[atlas], blind_choice.config.pos)
        blind_choice.animation:define_draw_steps({
            { shader = 'dissolve', shadow_height = 0.05 },
            { shader = 'dissolve' }
        })

        score_tab = {
            {
                n = G.UIT.R,
                config = { align = "cm", minh = 0.6 },
                nodes = {
                    { n = G.UIT.O, config = { object = DynaText({ string = localize { type = 'name_text', key = blind_choice.config.key, set = 'Blind' }, colours = { G.C.WHITE }, shadow = true, float = true, maxw = 2.2, scale = 0.45 }) } }
                }
            },
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.1 },
                nodes = {
                    { n = G.UIT.O, config = { object = blind_choice.animation } }
                }
            },
        }
    end

    local label_scale = 0.5

    if score == 'poker_hand' then
        local handname, amount = localize('k_none'), 0
        for k, v in pairs(G.GAME.hand_usage) do
            if v.count > amount then
                handname = v.order; amount = v.count
            end
        end
        score_tab = {
            { n = G.UIT.O, config = { object = DynaText({ string = { amount < 1 and handname or localize(handname, 'poker_hands') }, colours = { text_colour or G.C.WHITE }, shadow = true, float = true, scale = 0.45, maxw = 2.5 }) } },
            { n = G.UIT.T, config = { text = " (" .. amount .. ")", scale = 0.35, colour = G.C.JOKER_GREY } }
        }
    elseif score == 'hand' then
        check_high_score = true
        local chip_sprite = Sprite(0, 0, 0.3, 0.3, G.ASSET_ATLAS["ui_" .. (G.SETTINGS.colourblind_option and 2 or 1)],
            { x = 0, y = 0 })
        chip_sprite.states.drag.can = false
        score_tab = {
            {
                n = G.UIT.C,
                config = { align = "cm" },
                nodes = {
                    { n = G.UIT.O, config = { w = 0.3, h = 0.3, object = chip_sprite } }
                }
            },
            {
                n = G.UIT.C,
                config = { align = "cm" },
                nodes = {
                    { n = G.UIT.O, config = { object = DynaText({ string = { number_format(G.GAME.round_scores[score].amt) }, colours = { text_colour or G.C.RED }, shadow = true, float = true, scale = math.min(0.6, score_number_scale(1.2, G.GAME.round_scores[score].amt)) }) } },
                }
            },
        }
    elseif G.GAME.round_scores[score] and not score_tab[1] then
        score_tab = {
            { n = G.UIT.O, config = { object = DynaText({ string = { number_format(G.GAME.round_scores[score].amt) }, colours = { text_colour or G.C.FILTER }, shadow = true, float = true, scale = score_number_scale(0.6, G.GAME.round_scores[score].amt) }) } },
        }
    end
    return {
        n = G.UIT.R,
        config = { align = "cm", padding = 0.05, r = 0.1, colour = darken(G.C.JOKER_GREY, 0.1), emboss = 0.05, func = check_high_score and 'high_score_alert' or nil, id = score },
        nodes = {
            {
                n = score == 'defeated_by' and G.UIT.R or G.UIT.C,
                config = { align = "cm", padding = 0.02, minw = label_w, maxw = label_w },
                nodes = {
                    { n = G.UIT.T, config = { text = label, scale = label_scale, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
                }
            },
            {
                n = score == 'defeated_by' and G.UIT.R or G.UIT.C,
                config = { align = "cr" },
                nodes = {
                    {
                        n = G.UIT.C,
                        config = { align = "cm", minh = h, r = 0.1, minw = score == 'defeated_by' and label_w or score_w, colour = (score == 'seed' and G.GAME.seeded) and G.C.RED or G.C.BLACK, emboss = 0.05 },
                        nodes = {
                            { n = G.UIT.C, config = { align = "cm", padding = 0.05, r = 0.1, minw = score_w }, nodes = score_tab },
                        }
                    }
                }
            },
        }
    }
end

function add_round_eval_row(config)
    local config = config or {}
    local width = G.round_eval.T.w - 0.51
    local num_dollars = config.dollars or 1
    local scale = 0.9

    if config.name ~= 'bottom' then
        if config.name ~= 'blind1' then
            if not G.round_eval.divider_added then
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.25,
                    func = function()
                        local spacer = {
                            n = G.UIT.R,
                            config = { align = "cm", minw = width },
                            nodes = {
                                { n = G.UIT.O, config = { object = DynaText({ string = { '......................................' }, colours = { G.C.WHITE }, shadow = true, float = true, y_offset = -30, scale = 0.45, spacing = 13.5, font = G.LANGUAGES['en-us'].font, pop_in = 0 }) } }
                            }
                        }
                        G.round_eval:add_child(spacer,
                            G.round_eval:get_UIE_by_ID(config.bonus and 'bonus_round_eval' or 'base_round_eval'))
                        return true
                    end
                }))
                delay(0.6)
                G.round_eval.divider_added = true
            end
        else
            delay(0.2)
        end

        delay(0.2)

        G.E_MANAGER:add_event(Event({
            trigger = 'before',
            delay = 0.5,
            func = function()
                --Add the far left text and context first:
                local left_text = {}
                if config.name == 'blind1' then
                    local stake_sprite = get_stake_sprite(G.GAME.stake or 1, 0.5)
                    local atlas = 'blind_chips'
                    if G.GAME.blind.config.blind.atlas then
                        atlas = G.GAME.blind.config.blind.atlas
                    end
                    local blind_sprite = AnimatedSprite(0, 0, 1.2, 1.2, G.ANIMATION_ATLAS[atlas],
                        copy_table(G.GAME.blind.pos))
                    blind_sprite:define_draw_steps({
                        { shader = 'dissolve', shadow_height = 0.05 },
                        { shader = 'dissolve' }
                    })
                    table.insert(left_text,
                        { n = G.UIT.O, config = { w = 1.2, h = 1.2, object = blind_sprite, hover = true, can_collide = false } })

                    table.insert(left_text,
                        config.saved and
                        {
                            n = G.UIT.C,
                            config = { padding = 0.05, align = 'cm' },
                            nodes = {
                                {
                                    n = G.UIT.R,
                                    config = { align = 'cm' },
                                    nodes = {
                                        { n = G.UIT.O, config = { object = DynaText({ string = { ' ' .. localize('ph_mr_bones') .. ' ' }, colours = { G.C.FILTER }, shadow = true, pop_in = 0, scale = 0.5 * scale, silent = true }) } }
                                    }
                                }
                            }
                        }
                        or {
                            n = G.UIT.C,
                            config = { padding = 0.05, align = 'cm' },
                            nodes = {
                                {
                                    n = G.UIT.R,
                                    config = { align = 'cm' },
                                    nodes = {
                                        { n = G.UIT.O, config = { object = DynaText({ string = { ' ' .. localize('ph_score_at_least') .. ' ' }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4 * scale, silent = true }) } }
                                    }
                                },
                                {
                                    n = G.UIT.R,
                                    config = { align = 'cm', minh = 0.8 },
                                    nodes = {
                                        { n = G.UIT.O, config = { w = 0.5, h = 0.5, object = stake_sprite, hover = true, can_collide = false } },
                                        { n = G.UIT.T, config = { text = G.GAME.blind.chip_text, scale = scale_number(G.GAME.blind.chips, scale, 100000), colour = G.C.RED, shadow = true } }
                                    }
                                }
                            }
                        })
                elseif string.find(config.name, 'tag') then
                    local blind_sprite = Sprite(0, 0, 0.7, 0.7, G.ASSET_ATLAS['tags'], copy_table(config.pos))
                    blind_sprite:define_draw_steps({
                        { shader = 'dissolve', shadow_height = 0.05 },
                        { shader = 'dissolve' }
                    })
                    blind_sprite:juice_up()
                    table.insert(left_text,
                        { n = G.UIT.O, config = { w = 0.7, h = 0.7, object = blind_sprite, hover = true, can_collide = false } })
                    table.insert(left_text,
                        { n = G.UIT.O, config = { object = DynaText({ string = { config.condition }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4 * scale, silent = true }) } })
                elseif config.name == 'hands' then
                    table.insert(left_text,
                        { n = G.UIT.T, config = { text = config.disp or config.dollars, scale = 0.8 * scale, colour = G.C.BLUE, shadow = true, juice = true } })
                    table.insert(left_text,
                        { n = G.UIT.O, config = { object = DynaText({ string = { " " .. localize { type = 'variable', key = 'remaining_hand_money', vars = { G.GAME.modifiers.money_per_hand or 1 } } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4 * scale, silent = true }) } })
                elseif config.name == 'discards' then
                    table.insert(left_text,
                        { n = G.UIT.T, config = { text = config.disp or config.dollars, scale = 0.8 * scale, colour = G.C.RED, shadow = true, juice = true } })
                    table.insert(left_text,
                        { n = G.UIT.O, config = { object = DynaText({ string = { " " .. localize { type = 'variable', key = 'remaining_discard_money', vars = { G.GAME.modifiers.money_per_discard or 0 } } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4 * scale, silent = true }) } })
                elseif string.find(config.name, 'joker') then
                    table.insert(left_text,
                        { n = G.UIT.O, config = { object = DynaText({ string = localize { type = 'name_text', set = config.card.config.center.set, key = config.card.config.center.key }, colours = { G.C.FILTER }, shadow = true, pop_in = 0, scale = 0.6 * scale, silent = true }) } })
                elseif config.name == 'interest' then
                    table.insert(left_text,
                        { n = G.UIT.T, config = { text = num_dollars, scale = 0.8 * scale, colour = G.C.MONEY, shadow = true, juice = true } })
                    table.insert(left_text,
                        { n = G.UIT.O, config = { object = DynaText({ string = { " " .. localize { type = 'variable', key = 'interest', vars = { G.GAME.interest_amount, 5, G.GAME.interest_amount * G.GAME.interest_cap / 5 } } }, colours = { G.C.UI.TEXT_LIGHT }, shadow = true, pop_in = 0, scale = 0.4 * scale, silent = true }) } })
                end
                local full_row = {
                    n = G.UIT.R,
                    config = { align = "cm", minw = 5 },
                    nodes = {
                        { n = G.UIT.C, config = { padding = 0.05, minw = width * 0.55, minh = 0.61, align = "cl" }, nodes = left_text },
                        { n = G.UIT.C, config = { padding = 0.05, minw = width * 0.45, align = "cr" },              nodes = { { n = G.UIT.C, config = { align = "cm", id = 'dollar_' .. config.name }, nodes = {} } } }
                    }
                }

                if config.name == 'blind1' then
                    G.GAME.blind:juice_up()
                end
                G.round_eval:add_child(full_row,
                    G.round_eval:get_UIE_by_ID(config.bonus and 'bonus_round_eval' or 'base_round_eval'))
                play_sound('cancel', config.pitch or 1)
                play_sound('highlight1', (1.5 * config.pitch) or 1, 0.2)
                if config.card then config.card:juice_up(0.7, 0.46) end
                return true
            end
        }))
        local dollar_row = 0
        if num_dollars > 60 then
            local dollar_string = localize('$') .. num_dollars
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.38,
                func = function()
                    G.round_eval:add_child(
                        {
                            n = G.UIT.R,
                            config = { align = "cm", id = 'dollar_row_' .. (dollar_row + 1) .. '_' .. config.name },
                            nodes = {
                                { n = G.UIT.O, config = { object = DynaText({ string = { localize('$') .. num_dollars }, colours = { G.C.MONEY }, shadow = true, pop_in = 0, scale = 0.65, float = true }) } }
                            }
                        },
                        G.round_eval:get_UIE_by_ID('dollar_' .. config.name))

                    play_sound('coin3', 0.9 + 0.2 * math.random(), 0.7)
                    play_sound('coin6', 1.3, 0.8)
                    return true
                end
            }))
        else
            for i = 1, num_dollars or 1 do
                G.E_MANAGER:add_event(Event({
                    trigger = 'before',
                    delay = 0.18 - ((num_dollars > 20 and 0.13) or (num_dollars > 9 and 0.1) or 0),
                    func = function()
                        if i % 30 == 1 then
                            G.round_eval:add_child(
                                { n = G.UIT.R, config = { align = "cm", id = 'dollar_row_' .. (dollar_row + 1) .. '_' .. config.name }, nodes = {} },
                                G.round_eval:get_UIE_by_ID('dollar_' .. config.name))
                            dollar_row = dollar_row + 1
                        end

                        local r = { n = G.UIT.T, config = { text = localize('$'), colour = G.C.MONEY, scale = ((num_dollars > 20 and 0.28) or (num_dollars > 9 and 0.43) or 0.58), shadow = true, hover = true, can_collide = false, juice = true } }
                        play_sound('coin3', 0.9 + 0.2 * math.random(), 0.7 - (num_dollars > 20 and 0.2 or 0))

                        if config.name == 'blind1' then
                            G.GAME.current_round.dollars_to_be_earned = G.GAME.current_round.dollars_to_be_earned:sub(2)
                        end

                        G.round_eval:add_child(r,
                            G.round_eval:get_UIE_by_ID('dollar_row_' .. (dollar_row) .. '_' .. config.name))
                        G.VIBRATION = G.VIBRATION + 0.4
                        return true
                    end
                }))
            end
        end
    else
        delay(0.4)
        G.E_MANAGER:add_event(Event({
            trigger = 'before',
            delay = 0.5,
            func = function()
                UIBox {
                    definition = { n = G.UIT.ROOT, config = { align = 'cm', colour = G.C.CLEAR }, nodes = {
                        { n = G.UIT.R, config = { id = 'cash_out_button', align = "cm", padding = 0.1, minw = 7, r = 0.15, colour = G.C.ORANGE, shadow = true, hover = true, one_press = true, button = 'cash_out', focus_args = { snap_to = true } }, nodes = {
                            { n = G.UIT.T, config = { text = localize('b_cash_out') .. ": ", scale = 1, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
                            { n = G.UIT.T, config = { text = localize('$') .. config.dollars, scale = 1.2 * scale, colour = G.C.WHITE, shadow = true, juice = true } }
                        } }, } },
                    config = {
                        align = 'tmi',
                        offset = { x = 0, y = 0.4 },
                        major = G.round_eval }
                }

                --local left_text = {n=G.UIT.R, config={id = 'cash_out_button', align = "cm", padding = 0.1, minw = 2, r = 0.15, colour = G.C.ORANGE, shadow = true, hover = true, one_press = true, button = 'cash_out', focus_args = {snap_to = true}}, nodes={
                --    {n=G.UIT.T, config={text = localize('b_cash_out')..": ", scale = 1, colour = G.C.UI.TEXT_LIGHT, shadow = true}},
                --    {n=G.UIT.T, config={text = localize('$')..config.dollars, scale = 1.3*scale, colour = G.C.WHITE, shadow = true, juice = true}}
                --}}
                --G.round_eval:add_child(left_text,G.round_eval:get_UIE_by_ID('eval_bottom'))

                G.GAME.current_round.dollars = config.dollars

                play_sound('coin6', config.pitch or 1)
                G.VIBRATION = G.VIBRATION + 1
                return true
            end
        }))
    end
end

local blind_loadref = Blind.load
function Blind.load(self, blindTable)
    self.config.blind = G.P_BLINDS[blindTable.config_blind] or {}
    if self.config.blind.atlas then
        self.children.animatedSprite.atlas = G.ANIMATION_ATLAS[self.config.blind.atlas]
    end
    blind_loadref(self, blindTable)
end
