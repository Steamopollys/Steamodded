--- STEAMODDED CORE
--- MODULE API

function loadAPIs()
    -------------------------------------------------------------------------------------------------
    --- API CODE GameObject
    -------------------------------------------------------------------------------------------------

    --- GameObject base class. You should always use the appropriate subclass to register your object.
    SMODS.GameObject = Object:extend()
    SMODS.GameObject.children = {}
    function SMODS.GameObject:extend(o)
        local cls = Object.extend(self)
        for k, v in pairs(o or {}) do
            cls[k] = v
        end
        self.children[#self.children + 1] = cls
        cls.children = {}
        return cls
    end

    function SMODS.GameObject:__call(o)
        setmetatable(o, self)
        o.mod = SMODS.current_mod
        for _, v in ipairs(o.required_params or {}) do
            assert(not (o[v] == nil), string.format('Missing required parameter for %s declaration: %s', o.set, v))
        end
        if not o.omit_prefix then
            o.key = string.format('%s_%s_%s', o.prefix, o.mod.prefix, o.key)
        end
        return o
    end

    function SMODS.GameObject:register()
        if self:check_dependencies() and not self.obj_table[self.key] then
            self.obj_table[self.key] = self
            self.obj_buffer[#self.obj_buffer + 1] = self.key
        end
    end

    function SMODS.GameObject:check_dependencies()
        local keep = true
        if self.dependencies then
            -- ensure dependencies are a table
            if type(self.dependencies) == 'string' then self.dependencies = { self.dependencies } end
            for _, v in ipairs(self.dependencies) do
                self.mod.optional_dependencies[v] = true
                if not SMODS.Mods[v] then keep = false end
            end
        end
        return keep
    end

    function SMODS.GameObject:process_loc_text()
        SMODS.process_loc_text(G.localization.descriptions[self.set], self.key, self.loc_txt)
    end

    function SMODS.GameObject:injector()
        local o = nil
        for i, key in ipairs(self.obj_buffer) do
            o = self.obj_table[key]
            boot_print_stage(string.format('Injecting %s: %s', o.set, o.key))
            o.atlas = o.atlas or SMODS.Sprites[key] and o.key or o.set

            -- Add centers to pools
            o:inject(i)

            -- Setup Localize text
            o:process_loc_text()

            sendInfoMessage(string.format(
                'Registered game object %s of type %s with key %s',
                o.name or o.key, o.set, o.key), o.set or 'GameObject')
        end
    end

    --- Takes control of vanilla objects. Child class must implement get_obj for this to function.
    function SMODS.GameObject:take_ownership(key, obj)
        key = (self.omit_prefix or key:sub(1, #self.prefix + 1) == self.prefix .. '_') and key or
            string.format('%s_%s', self.prefix, key)
        local o = self:get_obj(key)
        if not o then
            sendWarnMessage(
                string.format('Tried to take ownership of non-existent %s: %s', self.set or self.__name, key),
                'CenterAPI')
            return nil
        end
        if o.mod then
            sendWarnMessage(string.format('Failed to take ownership of %s: %s. Object already belongs to %s.',
                self.set or self.__name, key, o.mod.name))
            return nil
        end
        setmetatable(o, self)
        o.mod = SMODS.current_mod
        o.key = key
        o.rarity_original = o.rarity
        -- preserve original text unless it's changed
        o.loc_txt = {}
        for k, v in pairs(obj) do o[k] = v end
        o.taken_ownership = true
        return o
    end

    function SMODS.injectObjects(class)
        if class.obj_table and class.obj_buffer then
            class:injector()
        else
            for _, subclass in ipairs(class.children) do SMODS.injectObjects(subclass) end
        end
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Language
    -------------------------------------------------------------------------------------------------

    SMODS.Languages = {}
    SMODS.Language = SMODS.GameObject:extend {
        obj_table = SMODS.Languages,
        obj_buffer = {},
        required_params = {
            'key',
            'label',
            'path',
            'font',
        },
        omit_prefix = true,
        process_loc_text = function() end,
        inject = function(self)
            self.full_path = self.mod.path .. 'localization/' .. self.path
            if type(self.font) == 'number' then
                self.font = G.FONTS[self.font]
            end
            G.LANGUAGES[self.key] = self
        end,
        injector = function(self)
            self.super.injector(self)
            G:set_language()
        end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Sprite
    -------------------------------------------------------------------------------------------------

    SMODS.Sprites = {}
    SMODS.Sprite = SMODS.GameObject:extend {
        obj_table = SMODS.Sprites,
        obj_buffer = {},
        required_params = {
            'key',
            'atlas',
            'path',
            'px',
            'py'
        },
        omit_prefix = true,
        register = function(self)
            if self.language then
                self.key = string.format('%s_%s', self.key, self.language)
            end
            self.super.register(self)
        end,
        inject = function(self)
            local file_path = type(self.path) == 'table' and (self.path[G.SETTINGS.language] or self.path['default'] or self.path['en-us']) or self.path
            if file_path == 'DEFAULT' then return end
            -- language specific sprites override fully defined sprites only if that language is set
            if self.language and not (G.SETTINGS.language == self.language) then return end
            if not self.language and self.obj_buffer[string.format('%s_%s', self.key, G.SETTINGS.language)] then return end
            self.full_path = (self.mod and self.mod.path or SMODS.dir) .. 'assets/' .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. file_path
            local file_data = NFS.newFileData(self.full_path)
            if file_data then
                local image_data = love.image.newImageData(file_data)
                if image_data then
                    self.image = love.graphics.newImage(image_data,
                        { mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling })
                else
                    self.image = love.graphics.newImage(self.full_path,
                        { mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling })
                end
            else
                self.image = love.graphics.newImage(self.full_path,
                    { mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling })
            end
            G[self.atlas:upper()][self.key] = self
        end,
        process_loc_text = function() end
    }

    SMODS.Sprite {
        key = 'tag_error',
        atlas = 'ASSET_ATLAS',
        path = 'tag_error.png',
        px = 34,
        py = 34,
        loc_txt = {
            ['en-us'] = {
                success = {
                    text = {
                        'Mod loaded',
                        '{C:green}successfully!'
                    }
                },
                failure_d = {
                    text = {
                        'Missing {C:attention}dependencies!',
                        '#1#',
                    }
                },
                failure_c = {
                    text = {
                        'Unresolved {C:attention}conflicts!',
                        '#1#'
                    }
                },
                failure_d_c = {
                    text = {
                        'Missing {C:attention}dependencies!',
                        '#1#',
                        'Unresolved {C:attention}conflicts!',
                        '#2#'
                    }
                }
            }
        },
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_success', self.loc_txt, 'success')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_d', self.loc_txt, 'failure_d')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_c', self.loc_txt, 'failure_c')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_d_c', self.loc_txt, 'failure_d_c')
        end
    }:register()


    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.ConsumableType
    -------------------------------------------------------------------------------------------------

    SMODS.ConsumableTypes = {}
    SMODS.ConsumableType = SMODS.GameObject:extend {
        obj_table = SMODS.ConsumableTypes,
        obj_buffer = {},
        set = 'ConsumableType',
        required_params = {
            'key',
            'primary_colour',
            'secondary_colour',
            'loc_txt'
        },
        omit_prefix = true,
        collection_rows = { 6, 6 },
        create_UIBox_your_collection = function(self)
            local deck_tables = {}

            G.your_collection = {}
            for j = 1, #self.collection_rows do
                G.your_collection[j] = CardArea(
                    G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
                    (self.collection_rows[j] + 0.25) * G.CARD_W,
                    1 * G.CARD_H,
                    { card_limit = self.collection_rows[j], type = 'title', highlight_limit = 0, collection = true })
                table.insert(deck_tables,
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0, no_fill = true },
                        nodes = {
                            { n = G.UIT.O, config = { object = G.your_collection[j] } }
                        }
                    }
                )
            end

            local sum = 0
            for j = 1, #G.your_collection do
                for i = 1, self.collection_rows[j] do
                    sum = sum + 1
                    local center = G.P_CENTER_POOLS[self.key][sum]
                    if not center then break end
                    local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y,
                        G.CARD_W, G.CARD_H, nil, center)
                    card:start_materialize(nil, i > 1 or j > 1)
                    G.your_collection[j]:emplace(card)
                end
            end

            local center_options = {}
            for i = 1, math.ceil(#G.P_CENTER_POOLS[self.key] / sum) do
                table.insert(center_options,
                    localize('k_page') ..
                    ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#G.P_CENTER_POOLS[self.key] / sum)))
            end

            INIT_COLLECTION_CARD_ALERTS()

            local t = create_UIBox_generic_options({
                back_func = 'your_collection',
                contents = {
                    { n = G.UIT.R, config = { align = "cm", minw = 2.5, padding = 0.1, r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables },
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0 },
                        nodes = {
                            create_option_cycle({
                                options = center_options,
                                w = 4.5,
                                cycle_shoulders = true,
                                opt_callback =
                                    'your_collection_' .. string.lower(self.key) .. '_page',
                                focus_args = { snap_to = true, nav = 'wide' },
                                current_option = 1,
                                colour = G
                                    .C.RED,
                                no_pips = true
                            })
                        }
                    },
                }
            })
            return t
        end,
        inject = function(self)
            G.P_CENTER_POOLS[self.key] = G.P_CENTER_POOLS[self.key] or {}
            G.localization.descriptions[self.key] = G.localization.descriptions[self.key] or {}
            G.C.SET[self.key] = self.primary_colour
            G.C.SECONDARY_SET[self.key] = self.secondary_colour
            G.FUNCS['your_collection_' .. string.lower(self.key) .. 's'] = function(e)
                G.SETTINGS.paused = true
                G.FUNCS.overlay_menu {
                    definition = self:create_UIBox_your_collection(),
                }
            end
            G.FUNCS['your_collection_' .. string.lower(self.key) .. '_page'] = function(args)
                if not args or not args.cycle_config then return end
                for j = 1, #G.your_collection do
                    for i = #G.your_collection[j].cards, 1, -1 do
                        local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
                        c:remove()
                        c = nil
                    end
                end
                local sum = 0
                for j = 1, #G.your_collection do
                    sum = sum + self.collection_rows[j]
                end
                sum = sum * (args.cycle_config.current_option - 1)
                for j = 1, #G.your_collection do
                    for i = 1, self.collection_rows[j] do
                        sum = sum + 1
                        local center = G.P_CENTER_POOLS[self.key][sum]
                        if not center then break end
                        local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2,
                            G.your_collection[j].T.y, G
                            .CARD_W, G.CARD_H, G.P_CARDS.empty, center)
                        card:start_materialize(nil, i > 1 or j > 1)
                        G.your_collection[j]:emplace(card)
                    end
                end
                INIT_COLLECTION_CARD_ALERTS()
            end
        end,
        process_loc_text = function(self)
            if not next(self.loc_txt) then return end
            SMODS.process_loc_text(G.localization.misc.dictionary, 'k_' .. string.lower(self.key), self.loc_txt, 'name')
            SMODS.process_loc_text(G.localization.misc.dictionary, 'b_' .. string.lower(self.key) .. '_cards',
                self.loc_txt, 'collection')
            SMODS.process_loc_text(G.localization.misc.labels, string.lower(self.key), self.loc_txt, 'label')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'undiscovered_'..string.lower(self.key), self.loc_txt, 'undiscovered')
        end
    }

    SMODS.ConsumableType {
        key = 'Tarot',
        collection_rows = { 5, 6 },
        primary_colour = G.C.SET.Tarot,
        secondary_colour = G.C.SECONDARY_SET.Tarot,
        inject_card = function(self)
            SMODS.insert_pool(G.P_CENTER_POOLS['Tarot_Planet'], self)
        end,
        loc_txt = {},
    }:register()
    SMODS.ConsumableType {
        key = 'Planet',
        collection_rows = { 6, 6 },
        primary_colour = G.C.SET.Planet,
        secondary_colour = G.C.SECONDARY_SET.Planet,
        inject_card = function(self)
            SMODS.insert_pool(G.P_CENTER_POOLS['Tarot_Planet'], self)
        end,
        loc_txt = {},
    }:register()
    SMODS.ConsumableType {
        key = 'Spectral',
        collection_rows = { 4, 5 },
        primary_colour = G.C.SET.Spectral,
        secondary_colour = G.C.SECONDARY_SET.Spectral,
        loc_txt = {},
    }:register()

    -- TODO
    -- create_card_for_shop logic
    -- create_card forcing legendary consumables
    -- get_current_pool logic, defaults


    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Center
    -------------------------------------------------------------------------------------------------

    SMODS.Centers = {}
    --- Shared class for center objects. Holds no default values; only register an object directly using this if it doesn't fit any subclass, creating one isn't justified and you know what you're doing.
    SMODS.Center = SMODS.GameObject:extend {
        obj_table = SMODS.Centers,
        obj_buffer = {},
        get_obj = function(self, key) return G.P_CENTERS[key] end,
        inject = function(self)
            G.P_CENTERS[self.key] = self
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
        end
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Joker
    -------------------------------------------------------------------------------------------------

    SMODS.Joker = SMODS.Center:extend {
        rarity = 1,
        unlocked = true,
        discovered = false,
        blueprint_compat = false,
        perishable_compat = true,
        eternal_compat = true,
        pos = { x = 0, y = 0 },
        cost = 3,
        config = {},
        set = 'Joker',
        prefix = 'j',
        required_params = {
            'key',
            'name',
            'loc_txt'
        },
        inject = function(self)
            -- call the parent function to ensure all pools are set
            SMODS.Center.inject(self)
            if self.taken_ownership and self.rarity_original == self.rarity then
                SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[self.rarity_original], self.key)
                SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self, false)
            else
                SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self)
            end
        end
    }

    function SMODS.end_calculate_context(c)
        if not c.after and not c.before and not c.other_joker and not c.repetition and not c.individual and
            not c.end_of_round and not c.discard and not c.pre_discard and not c.debuffed_hand and not c.using_consumeable and
            not c.remove_playing_cards and not c.cards_destroyed and not c.destroying_card and not c.setting_blind and
            not c.first_hand_drawn and not c.playing_card_added and not c.skipping_booster and not c.skip_blind and
            not c.ending_shop and not c.reroll_shop and not c.selling_card and not c.selling_self and not c.buying_card and
            not c.open_booster then
            return true
        end
        return false
    end

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Consumable
    -------------------------------------------------------------------------------------------------

    SMODS.Consumable = SMODS.Center:extend {
        unlocked = true,
        discovered = false,
        consumeable = true,
        pos = { x = 0, y = 0 },
        cost = 3,
        config = {},
        prefix = 'c',
        required_params = {
            'set',
            'key',
            'name',
            'loc_txt'
        },
        inject = function(self)
            SMODS.Center.inject(self)
            self.type = SMODS.ConsumableTypes[self.set]
            if self.type and self.type.inject_card and type(self.type.inject_card) == 'function' then
                self.type.inject_card(self)
            end
        end,
        loc_def = function(self, info_queue)
            return {}
        end
    }


    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Voucher
    -------------------------------------------------------------------------------------------------

    SMODS.Voucher = SMODS.Center:extend {
        set = 'Voucher',
        cost = 10,
        discovered = false,
        unlocked = true,
        available = true,
        pos = { x = 0, y = 0 },
        config = {},
        prefix = 'v',
        required_params = {
            'key',
            'name',
            'loc_txt',
        }
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Back
    -------------------------------------------------------------------------------------------------

    SMODS.Back = SMODS.Center:extend {
        set = 'Back',
        discovered = false,
        unlocked = true,
        pos = { x = 0, y = 0 },
        config = {},
        stake = 1,
        prefix = 'b',
        required_params = {
            'key',
            'name',
            'loc_txt'
        }
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.UndiscoveredSprite
    -------------------------------------------------------------------------------------------------

    SMODS.UndiscoveredSprites = {}
    SMODS.UndiscoveredSprite = SMODS.GameObject:extend {
        obj_buffer = {},
        obj_table = SMODS.UndiscoveredSprites,
        injector = function() end,
        omit_prefix = true,
        required_params = {
            'key',
            'atlas',
            'pos',
        }
    }
    SMODS.UndiscoveredSprite { key = 'Joker', atlas = 'Joker', pos = G.j_undiscovered.pos }:register()
    SMODS.UndiscoveredSprite { key = 'Edition', atlas = 'Joker', pos = G.j_undiscovered.pos }:register()
    SMODS.UndiscoveredSprite { key = 'Tarot', atlas = 'Tarot', pos = G.t_undiscovered.pos }:register()
    SMODS.UndiscoveredSprite { key = 'Planet', atlas = 'Tarot', pos = G.p_undiscovered.pos }:register()
    SMODS.UndiscoveredSprite { key = 'Spectral', atlas = 'Tarot', pos = G.s_undiscovered.pos }:register()
    SMODS.UndiscoveredSprite { key = 'Voucher', atlas = 'Voucher', pos = G.v_undiscovered.pos }:register()
    SMODS.UndiscoveredSprite { key = 'Booster', atlas = 'Booster', pos = G.booster_undiscovered.pos }:register()

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Blind
    -------------------------------------------------------------------------------------------------

    SMODS.Blinds = {}
    SMODS.Blind = SMODS.GameObject:extend {
        obj_table = SMODS.Blinds,
        obj_buffer = {},
        prefix = 'bl',
        debuff = {},
        vars = {},
        dollars = 5,
        mult = 2,
        discovered = false,
        pos = { x = 0, y = 0 },
        required_params = {
            'key',
            'name',
            'loc_txt',
        },
        set = 'Blind',
        get_obj = function(self, key) return G.P_BLINDS[key] end,
        inject = function(self, i)
            -- no pools to query length of, so we assign order manually
            self.order = 30 + i
            G.P_BLINDS[self.key] = self
        end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Seal
    -------------------------------------------------------------------------------------------------

    SMODS.Seals = {}
    SMODS.Seal = SMODS.GameObject:extend {
        obj_table = SMODS.Seals,
        obj_buffer = {},
        rng_buffer = { 'Purple', 'Gold', 'Blue', 'Red' },
        set = 'Seal',
        discovered = false,
        badge_colour = HEX('FFFFFF'),
        required_params = {
            'key',
            'pos',
        },
        inject = function(self)
            G.P_SEALS[self.key] = self
            G.shared_seals[self.key] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[self.atlas or 'centers'], self.pos)
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
            self.rng_buffer[#self.rng_buffer + 1] = self.key
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, self.key:lower() .. '_seal', self.loc_txt, 'description')
            SMODS.process_loc_text(G.localization.misc.labels, self.key:lower() .. '_seal', self.loc_txt, 'label')
        end,
        get_obj = function(self, key) return G.P_SEALS[key] end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Suit
    -------------------------------------------------------------------------------------------------

    SMODS.permutations = function(list, n)
        list = list or
            { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V',
                'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q',
                'r',
                's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7', '8', '9' }
        n = n or 2
        if n <= 1 then return list end
        local t = SMODS.permutations(list, n - 1)
        local o = {}
        for _, a in ipairs(list) do
            for _, b in ipairs(t) do
                table.insert(o, a .. b)
            end
        end
        return o
    end
    SMODS.valid_card_keys = SMODS.permutations()

    SMODS.Suits = {}
    SMODS.Suit = SMODS.GameObject:extend {
        obj_table = SMODS.Suits,
        obj_buffer = {},
        set = 'Suit',
        omit_prefix = true,
        required_params = {
            'key',
            'pos',
            'ui_pos',
            'loc_txt'
        },
        hc_atlas = 'cards_2',
        lc_atlas = 'cards_1',
        hc_ui_atlas = 'ui_2',
        lc_ui_atlas = 'ui_1',
        hc_colour = HEX '000000',
        lc_colour = HEX '000000',
        max_nominal = {
            value = 0,
        },
        register = function(self)
            self.card_key = self:get_card_key(self.card_key)
            self.max_nominal.value = self.max_nominal.value + 0.01
            self.suit_nominal = self.max_nominal.value
            self.super.register(self)
        end,
        populate = function(self)
            for _, other in pairs(SMODS.Ranks) do
                if not other.disabled then
                    self:update_p_card(other)
                end
            end
            self.disabled = nil
        end,
        inject = function(self)
            if not self.disabled then self:populate() end
        end,
        disable = function(self)
            for _, other in pairs(SMODS.Ranks) do
                self:update_p_card(other, true)
            end
            self.disabled = true
        end,
        delete = function(self)
            self:disable()
            local i
            for j, v in ipairs(self.obj_buffer) do
                if v == self.key then i = j end
            end
            table.remove(self.obj_buffer, i)
            self = nil
        end,
        update_p_card = function(self, other, remove)
            G.P_CARDS[self.card_key .. '_' .. other.card_key] = not remove and {
                name = other.key .. ' of ' .. self.key,
                value = other.key,
                suit = self.key,
                pos = { x = other.pos.x, y = other.suit_map[self.key] or self.pos.y },
                lc_atlas = other.suit_map[self.key] and other.lc_atlas or self.lc_atlas,
                hc_atlas = other.suit_map[self.key] and other.hc_atlas or self.hc_atlas,
            }
        end,
        get_card_key = function(self, card_key)
            local set = {}
            for _, v in ipairs(SMODS.valid_card_keys) do set[v] = true end
            for _, v in pairs(self.obj_table) do
                set[v.card_key] = false
            end
            if not card_key or (set[card_key] == false) then
                for _, v in pairs(SMODS.valid_card_keys) do
                    if set[v] then
                        card_key = v
                        break
                    end
                end
            end
            if not card_key then error(string.format('Unable to find valid ID for %s: %s', self.set, self.key)) end
            return card_key
        end,
        process_loc_text = function(self)
            -- empty loc_txt indicates there are existing values that shouldn't be changed
            if next(self.loc_txt) then
                SMODS.process_loc_text(G.localization.misc.suits_plural, self.key, self.loc_txt, 'plural')
                SMODS.process_loc_text(G.localization.misc.suits_singular, self.key, self.loc_txt, 'singular')
                G.C.SO_1[self.key] = self.lc_colour
                G.C.SO_2[self.key] = self.hc_colour
                G.C.SUITS[self.key] = G.C["SO_" .. (G.SETTINGS.colourblind_option and 2 or 1)][self.key]
            end
        end,
    }
    SMODS.Suit {
        key = 'Diamonds',
        card_key = 'D',
        pos = { y = 2 },
        ui_pos = { x = 1, y = 1 },
        loc_txt = {},
    }:register()
    SMODS.Suit {
        key = 'Clubs',
        card_key = 'C',
        pos = { y = 1 },
        ui_pos = { x = 2, y = 1 },
        loc_txt = {},
    }:register()
    SMODS.Suit {
        key = 'Hearts',
        card_key = 'H',
        pos = { y = 0 },
        ui_pos = { x = 0, y = 1 },
        loc_txt = {},
    }:register()
    SMODS.Suit {
        key = 'Spades',
        card_key = 'S',
        pos = { y = 3 },
        ui_pos = { x = 3, y = 1 },
        loc_txt = {},
    }:register()
    SMODS.Suit {
        key = 'Hearts?',
        card_key = 'Hq',
        pos = { y = 0 },
        ui_pos = { x = 0, y = 1 },
        hc_colour = G.C.SO_2.Hearts,
        lc_colour = G.C.SO_1.Hearts,
        loc_txt = {
            singular = 'Heart?',
            plural = 'Hearts?'
        }
    }:register()
    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Rank
    -------------------------------------------------------------------------------------------------

    SMODS.Ranks = {}
    SMODS.Rank = SMODS.GameObject:extend {
        obj_table = SMODS.Ranks,
        obj_buffer = {},
        set = 'Rank',
        omit_prefix = true,
        required_params = {
            'key',
            'pos',
            'loc_txt',
            'nominal',
        },
        hc_atlas = 'cards_2',
        lc_atlas = 'cards_1',
        strength_effect = {
            fixed = 1,
            random = false,
            ignore = false
        },
        next = {},
        straight_edge = false,
        suit_map = {
            Hearts = 0,
            Clubs = 1,
            Diamonds = 2,
            Spades = 3,
        },
        max_id = {
            value = 1,
        },
        valid_cards_keys = SMODS.Suit.valid_card_keys,
        get_card_key = SMODS.Suit.get_card_key,
        register = function(self)
            -- custom buffer insertion logic, so i copied
            if self.requires then
                local keep = true
                if type(self.requires) == 'string' then self.requires = { self.requires } end
                for _, v in ipairs(self.requires) do
                    self.mod.optional_dependencies[v] = true
                    if not SMODS.Mods[v] then keep = false end
                end
                if not keep then return end
            end
            self.card_key = self:get_card_key(self.card_key)
            self.max_id.value = self.max_id.value + 1
            self.id = self.max_id.value
            self.shorthand = self.shorthand or self.key
            self.sort_nominal = self.nominal + (self.face_nominal or 0)
            if self:check_dependencies() and not self.obj_table[self.key] then
                self.obj_table[self.key] = self
                local j
                -- keep buffer sorted in ascending nominal order
                for i = 1, #self.obj_buffer - 1 do
                    if self.obj_table[self.obj_buffer[i]].sort_nominal > self.sort_nominal then
                        j = i
                        break
                    end
                end
                if j then
                    table.insert(self.obj_buffer, j, self.key)
                else
                    table.insert(self.obj_buffer, self.key)
                end
            end
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.ranks, self.key, self.loc_txt)
        end,
        populate = function(self)
            for _, other in pairs(SMODS.Suits) do
                if not other.disabled then
                    other:update_p_card(self)
                end
            end
            self.disabled = nil
        end,
        inject = SMODS.Suit.inject,
        disable = function(self)
            for _, other in pairs(SMODS.Suits) do
                other:update_p_card(self, true)
            end
            self.disabled = true
        end,
        delete = SMODS.Suit.delete,
    }
    for _, v in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9 }) do
        SMODS.Rank {
            key = v .. '',
            card_key = v .. '',
            pos = { x = v - 2 },
            nominal = v,
            next = { (v + 1) .. '' },
            loc_txt = {},
        }:register()
    end
    SMODS.Rank {
        key = '10',
        card_key = 'T',
        pos = { x = 8 },
        nominal = 10,
        next = { 'Jack' },
        loc_txt = {},
    }:register()
    SMODS.Rank {
        key = 'Jack',
        card_key = 'J',
        pos = { x = 9 },
        nominal = 10,
        face_nominal = 0.1,
        face = true,
        shorthand = 'J',
        next = { 'Queen' },
        loc_txt = {},
    }:register()
    SMODS.Rank {
        key = 'Queen',
        card_key = 'Q',
        pos = { x = 10 },
        nominal = 10,
        face_nominal = 0.2,
        face = true,
        shorthand = 'Q',
        next = { 'King' },
        loc_txt = {},
    }:register()
    SMODS.Rank {
        key = 'King',
        card_key = 'K',
        pos = { x = 11 },
        nominal = 10,
        face_nominal = 0.3,
        face = true,
        shorthand = 'K',
        next = { 'Ace' },
        loc_txt = {},
    }:register()
    SMODS.Rank {
        key = 'Ace',
        card_key = 'A',
        pos = { x = 12 },
        nominal = 11,
        face_nominal = 0.4,
        shorthand = 'A',
        straight_edge = true,
        next = { '2' },
        loc_txt = {},
    }:register()
    -- make consumable effects compatible with added suits
    local function juice_flip(used_tarot)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                used_tarot:juice_up(0.3, 0.5)
                return true
            end
        }))
        for i = 1, #G.hand.cards do
            local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    G.hand.cards[i]:flip(); play_sound('card1', percent); G.hand.cards[i]:juice_up(0.3, 0.3); return true
                end
            }))
        end
    end
    SMODS.Consumable:take_ownership('strength', {
        use = function(self, area, copier)
            local used_tarot = copier or self
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                play_sound('tarot1')
                used_tarot:juice_up(0.3, 0.5)
                return true end }))
            for i=1, #G.hand.highlighted do
                local percent = 1.15 - (i-0.999)/(#G.hand.highlighted-0.998)*0.3
                G.E_MANAGER:add_event(Event({trigger = 'after',delay = 0.15,func = function() G.hand.highlighted[i]:flip();play_sound('card1', percent);G.hand.highlighted[i]:juice_up(0.3, 0.3);return true end }))
            end
            delay(0.2)
            for i = 1, #G.hand.highlighted do
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.1,
                    func = function()
                        local card = G.hand.highlighted[i]
                        local suit_data = SMODS.Suits[card.base.suit]
                        local suit_prefix = suit_data.card_key
                        local rank_data = SMODS.Ranks[card.base.value]
                        local behavior = rank_data.strength_effect or { fixed = 1, ignore = false, random = false }
                        local rank_suffix = ''
                        if behavior.ignore or not next(rank_data.next) then
                            return true
                        elseif behavior.random then
                            local r = pseudorandom_element(rank_data.next, pseudoseed('strength'))
                            rank_suffix = SMODS.Ranks[r].card_key
                        else
                            local ii = (behavior.fixed and rank_data.next[behavior.fixed]) and behavior.fixed or 1
                            rank_suffix = SMODS.Ranks[rank_data.next[ii]].card_key
                        end
                        card:set_base(G.P_CARDS[suit_prefix .. '_' .. rank_suffix])
                        return true
                    end
                }))
            end
            for i = 1, #G.hand.highlighted do
                local percent = 0.85 + (i - 0.999) / (#G.hand.highlighted - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.highlighted[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.highlighted[i]
                            :juice_up(
                                0.3, 0.3); return true
                    end
                }))
            end
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    G.hand:unhighlight_all(); return true
                end
            }))
            delay(0.5)
        end,
        loc_def = 0,
    }):register()
    SMODS.Consumable:take_ownership('sigil', {
        use = function(self, area, copier)
            local used_tarot = copier or self
            juice_flip(used_tarot)
            -- need reverse nominal order to preserve vanilla RNG
            local suit_list = {}
            for i = #SMODS.Suit.obj_buffer, 1, -1 do
                suit_list[#suit_list + 1] = SMODS.Suit.obj_buffer[i]
            end
            local _suit = SMODS.Suits[pseudorandom_element(suit_list, pseudoseed('sigil'))]
            for i = 1, #G.hand.cards do
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local card = G.hand.cards[i]
                        local _rank = SMODS.Ranks[card.base.value]
                        card:set_base(G.P_CARDS[_suit.card_key .. '_' .. _rank.card_key])
                        return true
                    end
                }))
            end
            for i = 1, #G.hand.cards do
                local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.cards[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.cards[i]:juice_up(0.3, 0.3); return true
                    end
                }))
            end
            delay(0.5)
        end,
        loc_def = 0,
    }):register()
    SMODS.Consumable:take_ownership('ouija', {
        use = function(self, area, copier)
            local used_tarot = copier or self
            juice_flip(used_tarot)
            local _rank = SMODS.Ranks[pseudorandom_element(SMODS.Rank.obj_buffer, pseudoseed('ouija'))]
            for i = 1, #G.hand.cards do
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local card = G.hand.cards[i]
                        local _suit = SMODS.Suits[card.base.suit]
                        card:set_base(G.P_CARDS[_suit.card_key .. '_' .. _rank.card_key])
                        return true
                    end
                }))
            end
            G.hand:change_size(-1)
            for i = 1, #G.hand.cards do
                local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.cards[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.cards[i]:juice_up(0.3, 0.3); return true
                    end
                }))
            end
            delay(0.5)
        end,
        loc_def = 0,
    }):register()
    local function random_destroy(used_tarot)
        local destroyed_cards = {}
        destroyed_cards[#destroyed_cards + 1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                used_tarot:juice_up(0.3, 0.5)
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                for i = #destroyed_cards, 1, -1 do
                    local card = destroyed_cards[i]
                    if card.ability.name == 'Glass Card' then
                        card:shatter()
                    else
                        card:start_dissolve(nil, i ~= #destroyed_cards)
                    end
                end
                return true
            end
        }))
        return destroyed_cards
    end
    SMODS.Consumable:take_ownership('grim', {
        use = function(self, area, copier)
            local used_tarot = copier or self
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, self.ability.extra do
                        cards[i] = true
                        local suit_list = {}
                        for i = #SMODS.Suit.obj_buffer, 1, -1 do
                            suit_list[#suit_list + 1] = SMODS.Suit.obj_buffer[i]
                        end
                        local _suit, _rank =
                            SMODS.Suits[pseudorandom_element(suit_list, pseudoseed('grim_create'))].card_key, 'A'
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if v.key ~= 'm_stone' then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end,
        loc_def = 0,
    }):register()
    SMODS.Consumable:take_ownership('familiar', {
        use = function(self, area, copier)
            local used_tarot = copier or self
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, self.ability.extra do
                        cards[i] = true
                        local suit_list = {}
                        for i = #SMODS.Suit.obj_buffer, 1, -1 do
                            suit_list[#suit_list + 1] = SMODS.Suit.obj_buffer[i]
                        end
                        local faces = {}
                        for _, v in ipairs(SMODS.Rank.obj_buffer) do
                            local r = SMODS.Ranks[v]
                            if r.face then table.insert(faces, r.card_key) end
                        end
                        local _suit, _rank =
                        SMODS.Suits[pseudorandom_element(suit_list, pseudoseed('familiar_create'))].card_key,
                            pseudorandom_element(faces, pseudoseed('familiar_create'))
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if v.key ~= 'm_stone' then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end,
        loc_def = 0,
    }):register()
    SMODS.Consumable:take_ownership('incantation', {
        use = function(self, area, copier)
            local used_tarot = copier or self
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, self.ability.extra do
                        cards[i] = true
                        local suit_list = {}
                        for i = #SMODS.Suit.obj_buffer, 1, -1 do
                            suit_list[#suit_list + 1] = SMODS.Suit.obj_buffer[i]
                        end
                        local numbers = {}
                        for _RELEASE_MODE, v in ipairs(SMODS.Rank.obj_buffer) do
                            local r = SMODS.Ranks[v]
                            if v ~= 'Ace' and not r.face then table.insert(numbers, r.card_key) end
                        end
                        local _suit, _rank = SMODS.Suits[pseudorandom_element(suit_list, pseudoseed('incantation_create'))].card_key, pseudorandom_element(numbers, pseudoseed('incantation_create'))
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if v.key ~= 'm_stone' then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end,
        loc_def = 0,
    }):register()
    SMODS.Blind:take_ownership('eye', {
        set_blind = function(self, blind, reset, silent)
            if not reset then
                for _, v in ipairs(G.handlist) do
                    self.hands[v] = false
                end
            end
        end
    })
end
