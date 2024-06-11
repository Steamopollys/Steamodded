SMODS.compat_0_9_8 = {}
SMODS.compat_0_9_8.load_done = false

function SMODS.compat_0_9_8.load()
    if SMODS.compat_0_9_8.load_done then
        return
    end

    function SMODS.compat_0_9_8.loc_vars(self, info_queue, card)
        local vars, main_end
        if self.loc_def and type(self.loc_def) == 'function' then
            if card == nil then
                card = SMODS.compat_0_9_8.generate_UIBox_ability_table_card
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

    SMODS.INIT = {}
    SMODS.INIT_DONE = {}
    function SMODS.findModByID(id)
        return SMODS.Mods[id]
    end
    function SMODS.end_calculate_context(c)
        return c.joker_main
    end

    SMODS.Deck_new = SMODS.Back:extend {
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
        loc_vars = SMODS.compat_0_9_8.loc_vars,
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
        loc_vars = SMODS.compat_0_9_8.loc_vars,
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
        loc_vars = SMODS.compat_0_9_8.loc_vars,
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
        loc_vars = SMODS.compat_0_9_8.loc_vars,
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
        loc_vars = SMODS.compat_0_9_8.loc_vars,
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

    SMODS.compat_0_9_8.load_done = true
end

function SMODS.compat_0_9_8.with_compat(func)
    SMODS.compat_0_9_8.load()
    -- local localization_ref = G.localization
    -- local captured_loc, captured_loc_mt
    -- captured_loc_mt = {
    --     __index = function(t, k)
    --         local v = rawget(t, k)
    --         if v ~= nil then
    --             return v
    --         end
    --         local corr_v = rawget(t, 'corr_t')[k]
    --         if corr_v then
    --             if type(corr_v) ~= 'table' then
    --                 return corr_v
    --             else
    --                 -- corr_v is a table
    --                 local ret = rawset(t, k, setmetatable({corr_t = corr_v}, captured_loc_mt))
    --                 print("ret:")
    --                 print(inspectDepth(ret))
    --                 return ret
    --             end
    --         end
    --         return nil
    --     end
    -- }
    -- -- top-level proxy for G.localization
    -- captured_loc = setmetatable({corr_t = localization_ref}, captured_loc_mt)
    -- G.localization = captured_loc
    -- local init_localization_ref = init_localization
    -- init_localization = function()
    --     G.localization = localization_ref
    --     print("init_localization interposed!")
    --     init_localization_ref()
    --     G.localization = captured_loc
    -- end
    func()
    -- init_localization = init_localization_ref
    -- G.localization = localization_ref
    -- local function recursive_clear_metatable(t)
    --     setmetatable(t, nil)
    --     for _, v in pairs(t) do
    --         setmetatable(t, nil)
    --     end
    -- end
    -- recursive_clear_metatable(captured_loc)
    -- print("captured_loc:")
    -- print(inspect(captured_loc))
    -- function SMODS.current_mod.process_loc_text()
    --     local function recurse(t, corr_t)
    --         for k, v in pairs(t) do
    --             if type(v) == 'table' then
    --                 if corr_t[k] ~= nil then
    --                     corr_t[k] = {}
    --                 end
    --                 -- process values individually to avoid overwriting a whole table
    --                 recurse(v, corr_t[k])
    --             else
    --                 corr_t[k] = v
    --             end
    --         end
    --     end
    --     recurse(captured_loc, G.localization)
    -- end
end
