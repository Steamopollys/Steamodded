SMODS.compat_0_9_8 = {}
SMODS.compat_0_9_8.load_done = false

function SMODS.compat_0_9_8.load()
    if SMODS.compat_0_9_8.load_done then
        return
    end

    function SMODS.compat_0_9_8.delay_register(cls, self)
        if self.delay_register then
            self.delay_register = nil
            return
        end
        cls.super.register(self)
    end

    function SMODS.compat_0_9_8.joker_loc_vars(self, info_queue, card)
        local vars, main_end
        if self.loc_def and type(self.loc_def) == 'function' then
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
    -- Applies to Tarot, Planet, Spectral and Voucher
    function SMODS.compat_0_9_8.tarot_loc_vars(self, info_queue, card)
        local vars, main_end
        if self.loc_def and type(self.loc_def) == 'function' then
            vars, main_end = self.loc_def(self, info_queue)
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

    SMODS.compat_0_9_8.init_queue = {}
    SMODS.INIT = setmetatable({}, {
        __newindex = function(t, k, v)
            SMODS.compat_0_9_8.init_queue[k] = v
            rawset(t, k, v)
        end
    })
    function SMODS.findModByID(id)
        return SMODS.Mods[id]
    end
    function SMODS.end_calculate_context(c)
        return c.joker_main
    end
    function SMODS.LOAD_LOC()
        init_localization()
    end

    SMODS.SOUND_SOURCES = SMODS.Sounds
    function register_sound(name, path, filename)
        SMODS.Sound {
            key = name,
            path = filename,
        }
    end
    function modded_play_sound(sound_code, stop_previous_instance, volume, pitch)
        return SMODS.Sound.play(nil, pitch, volume, stop_previous_instance, sound_code)
    end

    SMODS.Card = {
        SUITS = SMODS.Suits,
        RANKS = SMODS.Ranks,
        SUIT_LIST = SMODS.Suit.obj_buffer,
        RANK_LIST = SMODS.Rank.obj_buffer,
    }

    SMODS.compat_0_9_8.Deck_new = SMODS.Back:extend {
        register = function(self)
            SMODS.compat_0_9_8.delay_register(SMODS.compat_0_9_8.Deck_new, self)
        end,
        __index = function(t, k)
            if k == 'slug' then return t.key
            elseif k == 'spritePos' then return t.pos
            end
            return getmetatable(t)[k]
        end,
        __newindex = function(t, k, v)
            if k == 'slug' then t.key = v; return
            elseif k == 'spritePos' then t.pos = v; return
            end
            rawset(t, k, v)
        end,
    }
    SMODS.Deck = {}
    function SMODS.Deck.new(self, name, slug, config, spritePos, loc_txt, unlocked, discovered)
        return SMODS.compat_0_9_8.Deck_new {
            name = name,
            key = slug,
            config = config,
            pos = spritePos,
            loc_txt = loc_txt,
            unlocked = unlocked,
            discovered = discovered,
            atlas = config and config.atlas,
            delay_register = true
        }
    end
    SMODS.Decks = SMODS.Centers

    SMODS.Sprites = {}
    SMODS.compat_0_9_8.Sprite_new = SMODS.Atlas:extend {
        register = function(self)
            if self.delay_register then
                self.delay_register = nil
                return
            end
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            SMODS.compat_0_9_8.Sprite_new.super.register(self)
            table.insert(SMODS.Sprites, self)
        end,
        __index = function(t, k)
            if k == 'name' then return t.key
            end
            return getmetatable(t)[k]
        end,
        __newindex = function(t, k, v)
            if k == 'name' then t.key = v; return
            end
            rawset(t, k, v)
        end,
    }
    SMODS.Sprite = {}
    function SMODS.Sprite.new(self, name, top_lpath, path, px, py, type, frames)
        local atlas_table
        if type == 'animation_atli' then
            atlas_table = 'ANIMATION_ATLAS'
        else
            atlas_table = 'ASSET_ATLAS'
        end
        return SMODS.compat_0_9_8.Sprite_new {
            key = name,
            path = path,
            atlas_table = atlas_table,
            px = px,
            py = py,
            frames = frames,
            delay_register = true
        }
    end

    SMODS.compat_0_9_8.Joker_new = SMODS.Joker:extend {
        loc_vars = SMODS.compat_0_9_8.joker_loc_vars,
        register = function(self)
            SMODS.compat_0_9_8.delay_register(SMODS.compat_0_9_8.Joker_new, self)
        end,
        __index = function(t, k)
            if k == 'slug' then return t.key
            elseif k == 'atlas' and SMODS.Atlases[t.key] then return t.key
            elseif k == 'spritePos' then return t.pos
            end
            return getmetatable(t)[k]
        end,
        __newindex = function(t, k, v)
            if k == 'slug' then t.key = v; return
            elseif k == 'spritePos' then t.pos = v; return
            end
            if k == 'calculate' or k == 'set_ability' or k == 'set_badges' or k == 'update' then
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
        local x = SMODS.compat_0_9_8.Joker_new {
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
            atlas = atlas,
            soul_pos = soul_pos,
            delay_register = true
        }
        return x
    end
    SMODS.Jokers = SMODS.Centers

    function SMODS.compat_0_9_8.extend_consumable_class(SMODS_cls)
        local cls
        cls = SMODS_cls:extend {
            loc_vars = SMODS.compat_0_9_8.tarot_loc_vars,
            register = function(self)
                SMODS.compat_0_9_8.delay_register(cls, self)
            end,
            __index = function(t, k)
                if k == 'slug' then
                    return t.key
                elseif k == 'atlas' and SMODS.Atlases[t.key] then
                    return t.key
                end
                return getmetatable(t)[k]
            end,
            __newindex = function(t, k, v)
                if k == 'slug' then
                    t.key = v; return
                elseif k == 'spritePos' then
                    t.pos = v; return
                end
                if k == 'set_badges' or k == 'use' or k == 'can_use' or k == 'update' then
                    local v_ref = v
                    v = function(self, ...)
                        return v_ref(...)
                    end
                end
                rawset(t, k, v)
            end
        }
        return cls
    end

    SMODS.compat_0_9_8.Tarot_new = SMODS.compat_0_9_8.extend_consumable_class(SMODS.Tarot)
    function SMODS.Tarot.new(self, name, slug, config, pos, loc_txt, cost, cost_mult, effect, consumeable, discovered,
                             atlas)
        return SMODS.compat_0_9_8.Tarot_new {
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
            atlas = atlas,
            delay_register = true
        }
    end
    SMODS.Tarots = SMODS.Centers

    SMODS.compat_0_9_8.Planet_new = SMODS.compat_0_9_8.extend_consumable_class(SMODS.Planet)
    function SMODS.Planet.new(self, name, slug, config, pos, loc_txt, cost, cost_mult, effect, freq, consumeable,
                              discovered, atlas)
        return SMODS.compat_0_9_8.Planet_new {
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
            atlas = atlas,
            delay_register = true
        }
    end
    SMODS.Planets = SMODS.Centers

    SMODS.compat_0_9_8.Spectral_new = SMODS.compat_0_9_8.extend_consumable_class(SMODS.Spectral)
    function SMODS.Spectral.new(self, name, slug, config, pos, loc_txt, cost, consumeable, discovered, atlas)
        return SMODS.compat_0_9_8.Spectral_new {
            name = name,
            key = slug,
            config = config,
            pos = pos,
            loc_txt = loc_txt,
            cost = cost,
            consumeable = consumeable,
            discovered = discovered,
            atlas = atlas,
            delay_register = true
        }
    end
    SMODS.Spectrals = SMODS.Centers

    SMODS.compat_0_9_8.Seal_new = SMODS.Seal:extend {
        class_prefix = false,
        register = function(self)
            if self.delay_register then
                self.delay_register = nil
                return
            end
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            if self:check_dependencies() and not self.obj_table[self.label] then
                self.obj_table[self.label] = self
                self.obj_buffer[#self.obj_buffer + 1] = self.label
                self.registered = true
            end
        end,
        __index = function(t, k)
            if k == 'name' then return t.key
            end
            return getmetatable(t)[k]
        end,
        __newindex = function(t, k, v)
            if k == 'name' then t.key = v; return
            end
            rawset(t, k, v)
        end,
    }
    function SMODS.Seal.new(self, name, label, full_name, pos, loc_txt, atlas, discovered, color)
        return SMODS.compat_0_9_8.Seal_new {
            key = name,
            label = label,
            full_name = full_name,
            pos = pos,
            loc_txt = {
                description = loc_txt,
                label = full_name
            },
            atlas = atlas,
            discovered = discovered,
            colour = color,
            delay_register = true
        }
    end

    SMODS.compat_0_9_8.Voucher_new = SMODS.Voucher:extend {
        loc_vars = SMODS.compat_0_9_8.tarot_loc_vars,
        register = function(self)
            SMODS.compat_0_9_8.delay_register(SMODS.compat_0_9_8.Voucher_new, self)
        end,
        __index = function(t, k)
            if k == 'slug' then return t.key
            elseif k == 'atlas' and SMODS.Atlases[t.key] then return t.key
            end
            return getmetatable(t)[k]
        end,
        __newindex = function(t, k, v)
            if k == 'slug' then t.key = v; return
            end
            if k == 'update' then
                local v_ref = v
                v = function(self, ...)
                    return v_ref(...)
                end
            elseif k == 'redeem' then
                local v_ref = v
                v = function(center, card)
                    local center_table = {
                        name = center and center.name or card and card.ability.name,
                        extra = center and center.config.extra or card and card.ability.extra
                    }
                    return v_ref(center_table)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Voucher.new(self, name, slug, config, pos, loc_txt, cost, unlocked, discovered, available, requires,
                               atlas)
        return SMODS.compat_0_9_8.Voucher_new {
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
            atlas = atlas,
            delay_register = true
        }
    end
    SMODS.Vouchers = SMODS.Centers

    SMODS.compat_0_9_8.Blind_new = SMODS.Blind:extend {
        register = function(self)
            SMODS.compat_0_9_8.delay_register(SMODS.compat_0_9_8.Blind_new, self)
        end,
        __index = function(t, k)
            if k == 'slug' then return t.key
            end
            return getmetatable(t)[k]
        end,
        __newindex = function(t, k, v)
            if k == 'slug' then t.key = v; return
            end
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
                    return v_ref(G.GAME.blind, ...)
                end
            end
            rawset(t, k, v)
        end
    }
    function SMODS.Blind.new(self, name, slug, loc_txt, dollars, mult, vars, debuff, pos, boss, boss_colour, defeated,
                             atlas)
        return SMODS.compat_0_9_8.Blind_new {
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
            atlas = atlas,
            delay_register = true
        }
    end

    SMODS.compat_0_9_8.loc_proxies = setmetatable({}, {__mode = 'k'})
    -- Indexing a table `t` that has this metatable instead indexes `t.capture_table`.
    -- Handles nested indices by instead indexing `t.capture_table` with the
    -- concatenation of all indices, separated by dots.
    SMODS.compat_0_9_8.loc_proxy_mt = {
        __index = function(t, k)
            if rawget(t, 'stop_capture') then
                return t.orig_t[k]
            end
            local new_idx_str = t.idx_str .. "." .. k
            -- first check capture_table
            if t.capture_table[new_idx_str] ~= nil then
                return t.capture_table[new_idx_str]
            end
            -- then fall back to orig_t
            local orig_v = t.orig_t[k]
            if type(orig_v) ~= 'table' then
                -- reached a non-table value, stop proxying
                return orig_v
            end
            local ret = setmetatable({
                -- concatenation of all indexes, starting from G.localization
                -- separated by dots and preceded by a dot
                idx_str = new_idx_str,
                -- table we would be indexing
                orig_t = orig_v,
                capture_table = t.capture_table,
            }, SMODS.compat_0_9_8.loc_proxy_mt)
            SMODS.compat_0_9_8.loc_proxies[ret] = true
            return ret
        end,
        __newindex = function(t, k, v)
            if rawget(t, 'stop_capture') then
                t.orig_t[k] = v; return
            end
            local new_idx_str = t.idx_str .. "." .. k
            t.capture_table[new_idx_str] = v
        end
    }
    -- Drop-in replacement for G.localization. Captures changes in `capture_table`
    function SMODS.compat_0_9_8.loc_proxy(capture_table)
        local ret = setmetatable({
            idx_str = '',
            orig_t = G.localization,
            capture_table = capture_table,
        }, SMODS.compat_0_9_8.loc_proxy_mt)
        SMODS.compat_0_9_8.loc_proxies[ret] = true
        return ret
    end
    function SMODS.compat_0_9_8.stop_loc_proxies()
        collectgarbage()
        for proxy, _ in pairs(SMODS.compat_0_9_8.loc_proxies) do
            rawset(proxy, 'stop_capture', true)
            SMODS.compat_0_9_8.loc_proxies[proxy] = nil
        end
    end

    SMODS.compat_0_9_8.load_done = true
end

function SMODS.compat_0_9_8.with_compat(func)
    SMODS.compat_0_9_8.load()
    local localization_ref = G.localization
    init_localization_ref = init_localization
    local captured_loc = {}
    G.localization = SMODS.compat_0_9_8.loc_proxy(captured_loc)
    function init_localization()
        G.localization = localization_ref
        init_localization_ref()
        G.localization = SMODS.compat_0_9_8.loc_proxy(captured_loc)
    end
    func()
    G.localization = localization_ref
    init_localization = init_localization_ref
    SMODS.compat_0_9_8.stop_loc_proxies()
    function SMODS.current_mod.process_loc_text()
        for idx_str, v in pairs(captured_loc) do
            local t = G
            local k = 'localization'
            for cur_k in idx_str:gmatch("[^%.]+") do
                t, k = t[k], cur_k
            end
            t[k] = v
        end
    end
end
