load_compat_0_9_8_done = false

function load_compat_0_9_8()
    if load_compat_0_9_8_done then
        return
    end

    function loc_vars_compat_0_9_8(self, info_queue, card)
        local vars, main_end
        if self.loc_def and type(self.loc_def) == 'function' then
            if card == nil then
                card = compat_0_9_8_generate_UIBox_ability_table_card
            end
            vars, main_end = self.loc_def(card, info_queue)
        end
        if self.tooltip and type(self.tooltip) == 'function' then
            self.tooltip(self, info_queue)
        end
        if vars then
            return {
                vars = vars,
                main_end = main_end
            }
        else
            return {}
        end
    end

    SMODS['INIT'] = {}
    SMODS.INIT_DONE = {}
    function SMODS.findModByID(id)
        return SMODS.Mods[id]
    end
    function SMODS.end_calculate_context(c)
        return c.joker_main
    end

    SMODS.Deck_new = SMODS.Back:extend {
        loc_vars = loc_vars_compat_0_9_8,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            SMODS.Deck_new.super.register(self)
        end
    }
    SMODS.Deck = {}
    function SMODS.Deck.new(self, name, slug, config, spritePos, loc_txt, unlocked, discovered)
        return SMODS.Deck_new {
            name = name,
            key = slug,
            config = config,
            pos = spritePos,
            loc_txt = loc_txt,
            unlocked = unlocked,
            discovered = discovered,
            atlas = config and config.atlas
        }
    end
    SMODS.Decks = SMODS.Centers

    SMODS.Sprite = {}
    function SMODS.Sprite.new(self, name, top_lpath, path, px, py, type, frames)
        local atlas_table
        if type == 'animation_atli' then
            atlas_table = 'ANIMATION_ATLAS'
        else
            atlas_table = 'ASSET_ATLAS'
        end
        return SMODS.Atlas {
            key = name,
            path = path,
            atlas_table = atlas_table,
            px = px,
            py = py,
            frames = frames
        }
    end
    SMODS.Sprites = SMODS.Atlases

    SMODS.Joker_new = SMODS.Joker:extend {
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            if self.atlas == 0 then
                self.atlas = self.key
            end
            SMODS.Joker_new.super.register(self)
        end,
        __newindex = function(t, k, v)
            if k == 'calculate' or k == 'set_ability' or k == 'set_badges' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            end
            rawset(t, k, v)
        end,
    }
    function SMODS.Joker.new(self, name, slug, config, spritePos, loc_txt, rarity, cost, unlocked, discovered,
                             blueprint_compat, eternal_compat, effect, atlas, soul_pos)
        local x = SMODS.Joker_new {
            name = name,
            key = slug,
            config = config,
            pos = spritePos,
            loc_txt = loc_txt,
            rarity = rarity,
            cost = cost,
            unlocked = unlocked,
            discovered = discovered,
            blueprint_compat = blueprint_compat,
            eternal_compat = eternal_compat,
            effect = effect,
            atlas = atlas or 0,
            soul_pos = soul_pos
        }
        return x
    end
    SMODS.Jokers = SMODS.Centers

    SMODS.Tarot_new = SMODS.Tarot:extend {
        loc_vars = loc_vars_compat_0_9_8,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            if self.atlas == 0 then
                self.atlas = self.key
            end
            SMODS.Tarot_new.super.register(self)
        end,
        __newindex = function(t, k, v)
            if k == 'set_badges' or k == 'use' or k == 'can_use' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Tarot.new(self, name, slug, config, pos, loc_txt, cost, cost_mult, effect, consumeable, discovered,
                             atlas)
        return SMODS.Tarot_new {
            name = name,
            key = slug,
            config = config,
            pos = pos,
            loc_txt = loc_txt,
            cost = cost,
            cost_mult = cost_mult,
            effect = effect,
            consumeable = consumeable,
            discovered = discovered,
            atlas = atlas or 0
        }
    end
    SMODS.Tarots = SMODS.Centers

    SMODS.Planet_new = SMODS.Planet:extend {
        loc_vars = loc_vars_compat_0_9_8,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            if self.atlas == 0 then
                self.atlas = self.key
            end
            SMODS.Planet_new.super.register(self)
        end,
        __newindex = function(t, k, v)
            if k == 'set_badges' or k == 'use' or k == 'can_use' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Planet.new(self, name, slug, config, pos, loc_txt, cost, cost_mult, effect, freq, consumeable,
                              discovered, atlas)
        return SMODS.Planet_new {
            name = name,
            key = slug,
            config = config,
            pos = pos,
            loc_txt = loc_txt,
            cost = cost,
            cost_mult = cost_mult,
            effect = effect,
            freq = freq,
            consumeable = consumeable,
            discovered = discovered,
            atlas = atlas or 0
        }
    end
    SMODS.Planets = SMODS.Centers

    SMODS.Spectral_new = SMODS.Spectral:extend {
        loc_vars = loc_vars_compat_0_9_8,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            if self.atlas == 0 then
                self.atlas = self.key
            end
            SMODS.Spectral_new.super.register(self)
        end,
        __newindex = function(t, k, v)
            if k == 'set_badges' or k == 'use' or k == 'can_use' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Spectral.new(self, name, slug, config, pos, loc_txt, cost, consumeable, discovered, atlas)
        return SMODS.Spectral_new {
            name = name,
            key = slug,
            config = config,
            pos = pos,
            loc_txt = loc_txt,
            cost = cost,
            consumeable = consumeable,
            discovered = discovered,
            atlas = atlas or 0
        }
    end
    SMODS.Spectrals = SMODS.Centers

    SMODS.Seal_new = SMODS.Seal:extend {
        omit_prefix = true,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            if self:check_dependencies() and not self.obj_table[self.label] then
                self.obj_table[self.label] = self
                self.obj_buffer[#self.obj_buffer + 1] = self.label
                self.registered = true
            end
        end
    }
    function SMODS.Seal.new(self, name, label, full_name, pos, loc_txt, atlas, discovered, color)
        return SMODS.Seal_new {
            name = name,
            key = name,
            label = label,
            full_name = full_name,
            pos = pos,
            loc_txt = {
                description = loc_txt,
                label = full_name
            },
            atlas = atlas or 0,
            discovered = discovered,
            colour = color
        }
    end

    SMODS.Voucher_new = SMODS.Voucher:extend {
        loc_vars = loc_vars_compat_0_9_8,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            if self.atlas == 0 then
                self.atlas = self.key
            end
            SMODS.Voucher_new.super.register(self)
        end,
        __newindex = function(t, k, v)
            if k == 'redeem' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Voucher.new(self, name, slug, config, pos, loc_txt, cost, unlocked, discovered, available, requires,
                               atlas)
        return SMODS.Voucher_new {
            name = name,
            key = slug,
            config = config,
            pos = pos,
            loc_txt = loc_txt,
            cost = cost,
            unlocked = unlocked,
            discovered = discovered,
            available = available,
            requires = requires,
            atlas = atlas or 0
        }
    end
    SMODS.Vouchers = SMODS.Centers

    SMODS.Blind_new = SMODS.Blind:extend {
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.slug = self.key
            SMODS.Blind_new.super.register(self)
        end,
        __newindex = function(t, k, v)
            if k == 'set_blind'
            or k == 'disable'
            or k == 'defeat'
            or k == 'debuff_card'
            or k == 'stay_flipped'
            or k == 'drawn_to_hand'
            or k == 'debuff_hand'
            or k == 'modify_hand'
            or k == 'press_play'
            or k == 'get_loc_debuff_text' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Blind.new(self, name, slug, loc_txt, dollars, mult, vars, debuff, pos, boss, boss_colour, defeated,
                             atlas)
        return SMODS.Blind_new {
            name = name,
            key = slug,
            loc_txt = loc_txt,
            dollars = dollars,
            mult = mult,
            loc_vars = {
                vars = vars,
            },
            debuff = debuff,
            pos = pos,
            boss = boss,
            boss_colour = boss_colour,
            defeated = defeated,
            atlas = atlas
        }
    end

    for _, cls_name in ipairs{ 'Deck_new', 'Joker_new', 'Tarot_new', 'Planet_new', 'Spectral_new', 'Voucher_new' } do
        local __index_ref = SMODS[cls_name].__index
        SMODS[cls_name].__index = function(t, k)
            if k == 'loc_vars' then
                if t['loc_def'] and type(t['loc_def']) == 'function'
                or t['tooltip'] and type(t['tooltip']) == 'function' then
                    return loc_vars_compat_0_9_8
                else
                    return nil
                end
            elseif k == 'generate_ui' then
                if t['loc_def'] and type(t['loc_def']) == 'function'
                or t['tooltip'] and type(t['tooltip']) == 'function' then
                    return SMODS[cls_name].super.generate_ui
                else
                    return nil
                end
            end
            return __index_ref[k]
        end
    end

    load_compat_0_9_8_done = true
end
