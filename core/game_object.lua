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
        o.mod = SMODS.current_mod
        if o.mod and not o.raw_atlas_key and not (self.set == 'Sprite') then
            for _, v in ipairs({'atlas', 'hc_atlas', 'lc_atlas', 'hc_ui_atlas', 'lc_ui_atlas'}) do
                if o[v] then o[v] = ('%s_%s'):format(o.mod.prefix, o[v]) end
            end
        end
        setmetatable(o, self)
        for _, v in ipairs(o.required_params or {}) do
            assert(not (o[v] == nil), ('Missing required parameter for %s declaration: %s'):format(o.set, v))
        end
        if not o.omit_prefix then
            o.key = ('%s_%s_%s'):format(o.prefix, o.mod.prefix, o.key)
        end
        o:register()
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
            boot_print_stage(('Injecting %s: %s'):format(o.set, o.key))
            o.atlas = o.atlas or o.set

            if o._d == nil and o._u == nil then
                o._d, o._u = o.discovered, o.unlocked
            else
                o.discovered, o.unlocked = o._d, o._u
            end

            -- Add centers to pools
            o:inject(i)

            -- Setup Localize text
            o:process_loc_text()

            sendInfoMessage(
                ('Registered game object %s of type %s with key %s')
                :format(o.name or o.key, o.set, o.key), o.set or 'GameObject')
        end
    end

    --- Takes control of vanilla objects. Child class must implement get_obj for this to function.
    function SMODS.GameObject:take_ownership(key, obj)
        key = (self.omit_prefix or key:sub(1, #self.prefix + 1) == self.prefix .. '_') and key or
            ('%s_%s'):format(self.prefix, key)
        local o = self.obj_table[key] or self:get_obj(key)
        if not o then
            sendWarnMessage(
                ('Cannot take ownership of %s %s: Does not exist.'):format(self.set or self.__name, key)
            )
            return
        end
        setmetatable(o, self)
        if o.mod then
            o.dependencies = o.dependencies or {}
            table.insert(o.dependencies, SMODS.current_mod.id)
        else
            o.mod = SMODS.current_mod
            o.key = key
            o.rarity_original = o.rarity
            -- preserve original text unless it's changed
            o.loc_txt = {}
        end
        for k, v in pairs(obj) do o[k] = v end
        o.taken_ownership = true
        o:register()
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
    ----- INTERNAL API CODE GameObject._Loc
    -------------------------------------------------------------------------------------------------

    SMODS._Loc = SMODS.GameObject:extend {
        obj_table = {},
        obj_buffer = {},
        silent = true,
        __call = function() error('INTERNAL CLASS, DO NOT CALL') end,
        injector = function()
            for _, mod in ipairs(SMODS.mod_list) do
                if mod.process_loc_text and type(mod.process_loc_text) == 'function' then
                    mod.process_loc_text()
                end
            end
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
        set = 'Sprite',
        omit_prefix = true,
        register = function(self)
            local key = self.key
            if not self.raw_key and self.mod then
                key = ('%s_%s'):format(self.mod.prefix, key)
            end
            if self.language then
                key = ('%s_%s'):format(key, self.language)
            end
            if self:check_dependencies() and not self.obj_table[key] then
                self.key = key
                self.obj_table[self.key] = self
                self.obj_buffer[#self.obj_buffer + 1] = self.key
            end
        end,
        inject = function(self)
            local file_path = type(self.path) == 'table' and
                (self.path[G.SETTINGS.language] or self.path['default'] or self.path['en-us']) or self.path
            if file_path == 'DEFAULT' then return end
            -- language specific sprites override fully defined sprites only if that language is set
            if self.language and not (G.SETTINGS.language == self.language) then return end
            if not self.language and self.obj_table[('%s_%s'):format(self.key, G.SETTINGS.language)] then return end
            self.full_path = (self.mod and self.mod.path or SMODS.dir) ..
                'assets/' .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. file_path
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
                },
                failure_o = {
                    text = {
                        '{C:attention}Outdated!{} Steamodded',
                        'versions {C:money}0.9.8{} and below',
                        'are no longer supported.'
                    }
                },
                failure_i = {
                    text = {
                        '{C:attention}Incompatible!{} Needs version',
                        '#1# of Steamodded,',
                        'but #2# is installed.'
                    }
                }
            }
        },
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_success', self.loc_txt, 'success')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_d', self.loc_txt, 'failure_d')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_c', self.loc_txt, 'failure_c')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_d_c', self.loc_txt, 'failure_d_c')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_o', self.loc_txt, 'failure_o')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'load_failure_i', self.loc_txt, 'failure_i')
        end
    }

        -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Stake
    -------------------------------------------------------------------------------------------------

    SMODS.Stakes = {}
    SMODS.Stake = SMODS.GameObject:extend {
        obj_table = SMODS.Stakes,
        obj_buffer = {},
        prefix = 'stake',
        unlocked = false,
        set = 'Stake',
        atlas = 'chips',
        injected = false,
        required_params = {
            'name',
            'pos',
            'loc_txt',
            'applied_stakes'
        },
        injector = function(self)
            G.P_CENTER_POOLS[self.set] = {}
            G.P_STAKES = {}
            self.super.injector(self)
        end,
        inject = function(self)
            if not self.injected then
                -- Inject stake in the correct spot
                local count = #G.P_CENTER_POOLS[self.set]+1
                if self.above_stake then
                count = G.P_STAKES[self.prefix.."_"..self.above_stake].stake_level+1
                end
                self.order = count
                self.stake_level = count
                for _, v in pairs(G.P_STAKES) do
                if v.stake_level >= self.stake_level then
                    v.stake_level = v.stake_level + 1
                    v.order = v.stake_level
                end
                end
                G.P_STAKES[self.key] = self
                -- Localization text for applying stakes
                if next(self.loc_txt) then
                local applied_text = "{s:0.8}Applies "
                for _, v in pairs(self.applied_stakes) do
                    applied_text = applied_text .. G.P_STAKES[self.prefix.."_"..v].name .. ", "
                end
                applied_text = applied_text:sub(1, -3)
                if (applied_text == "{s:0.8}Applie") then applied_text = "{s:0.8}" end
                self.loc_txt.text[#self.loc_txt.text+1] = applied_text
                end
                -- Sticker sprites (stake_ prefix is removed for vanilla compatiblity)
                if self.sticker_pos ~= nil then
                    if self.sticker_atlas ~= nil then
                        G.shared_stickers[self.key:sub(7)] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[self.sticker_atlas], self.sticker_pos)
                    else
                        G.shared_stickers[self.key:sub(7)] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS["stickers"], self.sticker_pos)
                    end
                    G.sticker_map[self.stake_level] = self.key:sub(7)
                else
                    G.sticker_map[self.stake_level] = nil
                end
            else
                G.P_STAKES[self.key] = self
            end
            G.P_CENTER_POOLS[self.set] = {}
            for _, v in pairs(G.P_STAKES) do
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], v)
            end
            table.sort(G.P_CENTER_POOLS[self.set], function(a,b) return a.stake_level < b.stake_level end)
            G.C.STAKES = {}
            for i = 1, #G.P_CENTER_POOLS[self.set] do
                G.C.STAKES[i] = G.P_CENTER_POOLS[self.set][i].color or G.C.WHITE
            end
            self.injected = true
        end,
        process_loc_text = function(self)
            -- empty loc_txt indicates there are existing values that shouldn't be changed or it isn't necessary
            if next(self.loc_txt) then
                SMODS.process_loc_text(G.localization.descriptions[self.set], self.key, self.loc_txt)
            end
            if self.sticker_loc_txt and next(self.sticker_loc_txt) then
                SMODS.process_loc_text(G.localization.descriptions["Other"], self.key:sub(7).."_sticker", self.sticker_loc_txt)
            end
        end,
        get_obj = function(self, key) return G.P_STAKES[key] end
    }

    function SMODS.setup_stake(i)
    if G.P_CENTER_POOLS['Stake'][i].modifiers then
        G.P_CENTER_POOLS['Stake'][i].modifiers()
    end
    if G.P_CENTER_POOLS['Stake'][i].applied_stakes then
        for _, v in pairs(G.P_CENTER_POOLS['Stake'][i].applied_stakes) do
        SMODS.setup_stake(G.P_STAKES["stake_"..v].stake_level)
        end
    end
    end

    function SMODS.applied_stakes_UI(i, stake_desc_rows, num_added)
    if num_added == nil then num_added = {val = 0} end
    if G.P_CENTER_POOLS['Stake'][i].applied_stakes then
        for _, v in pairs(G.P_CENTER_POOLS['Stake'][i].applied_stakes) do
        if v ~= "white" then
            --todo: manage this with pages
            if num_added.val < 8 then
                local i = G.P_STAKES["stake_"..v].stake_level
                local _stake_desc = {}
                local _stake_center = G.P_CENTER_POOLS.Stake[i]
                localize{type = 'descriptions', key = _stake_center.key, set = _stake_center.set, nodes = _stake_desc}
                local _full_desc = {}
                for k, v in ipairs(_stake_desc) do
                _full_desc[#_full_desc+1] = {n=G.UIT.R, config={align = "cm"}, nodes=v}
                end
                _full_desc[#_full_desc] = nil
                stake_desc_rows[#stake_desc_rows+1] = {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.C, config={align = 'cm'}, nodes ={{n=G.UIT.C, config={align = "cm", colour = get_stake_col(i), r = 0.1, minh = 0.35, minw = 0.35, emboss = 0.05}, nodes={}}, {n=G.UIT.B, config={w=0.1,h=0.1}}}},
                {n=G.UIT.C, config={align = "cm", padding = 0.03, colour = G.C.WHITE, r = 0.1, minh = 0.7, minw = 4.8}, nodes=_full_desc},
                }}
            end
            num_added.val = num_added.val + 1
            num_added.val = SMODS.applied_stakes_UI(G.P_STAKES["stake_"..v].stake_level, stake_desc_rows, num_added)
        end
        end
    end
    end

    -- We're overwriting so much that it's better to just remake this
    function G.UIDEF.deck_stake_column(_deck_key)
        local deck_usage = G.PROFILES[G.SETTINGS.profile].deck_usage[_deck_key]
        local stake_col = {}
        local valid_option = nil
        local num_stakes = #G.P_CENTER_POOLS['Stake']
        for i = #G.P_CENTER_POOLS['Stake'], 1, -1 do
        local _wins = deck_usage and deck_usage.wins[i] or 0
        if (deck_usage and deck_usage.wins[i-1]) or i == 1 or G.PROFILES[G.SETTINGS.profile].all_unlocked then valid_option = true end
        stake_col[#stake_col+1] = {n=G.UIT.R, config={id = i, align = "cm", colour = _wins > 0 and G.C.GREY or G.C.CLEAR, outline = 0, outline_colour = G.C.WHITE, r = 0.1, minh = 2/num_stakes, minw = valid_option and 0.45 or 0.25, func = 'RUN_SETUP_check_back_stake_highlight'}, nodes={
            {n=G.UIT.R, config={align = "cm", minh = valid_option and 1.36/num_stakes or 1.04/num_stakes, minw = valid_option and 0.37 or 0.13, colour = _wins > 0 and get_stake_col(i) or G.C.UI.TRANSPARENT_LIGHT, r = 0.1},nodes={}}
        }}
        if i > 1 then stake_col[#stake_col+1] = {n=G.UIT.R, config={align = "cm", minh = 0.8/num_stakes, minw = 0.04},nodes={}} end
        end
        return {n=G.UIT.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes =stake_col}
    end

    --Register vanilla stakes
    SMODS.Stake{
        name = "White Stake",
        key = "stake_white",
        omit_prefix = true,
        unlocked_stake = "red",
        unlocked = true,
        applied_stakes = {},
        pos = {x = 0, y = 0},
        sticker_pos = {x = 1, y = 0},
        color = G.C.WHITE,
        loc_txt = {}
    }
    SMODS.Stake{
        name = "Red Stake",
        key = "stake_red",
        omit_prefix = true,
        unlocked_stake = "green",
        applied_stakes = {"white"},
        pos = {x = 1, y = 0},
        sticker_pos = {x = 2, y = 0},
        modifiers = function()
            G.GAME.modifiers.no_blind_reward = G.GAME.modifiers.no_blind_reward or {}
            G.GAME.modifiers.no_blind_reward.Small = true
        end,
        color = G.C.RED,
        loc_txt = {}
    }
    SMODS.Stake{
        name = "Green Stake",
        key = "stake_green",
        omit_prefix = true,
        unlocked_stake = "black",
        applied_stakes = {"red"},
        pos = {x = 2, y = 0},
        sticker_pos = {x = 3, y = 0},
        modifiers = function()
            G.GAME.modifiers.scaling = math.max(G.GAME.modifiers.scaling or 0, 2)
        end,
        color = G.C.GREEN,
        loc_txt = {}
    }
    SMODS.Stake{
        name = "Black Stake",
        key = "stake_black",
        omit_prefix = true,
        unlocked_stake = "blue",
        applied_stakes = {"green"},
        pos = {x = 4, y = 0},
        sticker_pos = {x = 0, y = 1},
        modifiers = function()
            G.GAME.modifiers.enable_eternals_in_shop = true
        end,
        color = G.C.BLACK,
        loc_txt = {}
    }
    SMODS.Stake{
        name = "Blue Stake",
        key = "stake_blue",
        omit_prefix = true,
        unlocked_stake = "purple",
        applied_stakes = {"black"},
        pos = {x = 3, y = 0},
        sticker_pos = {x = 4, y = 0},
        modifiers = function()
            G.GAME.starting_params.discards = G.GAME.starting_params.discards - 1
        end,
        color = G.C.BLUE,
        loc_txt = {}
    }
    SMODS.Stake{
        name = "Purple Stake",
        key = "stake_purple",
        omit_prefix = true,
        unlocked_stake = "orange",
        applied_stakes = {"blue"},
        pos = {x = 0, y = 1},
        sticker_pos = {x = 1, y = 1},
        modifiers = function()
            G.GAME.modifiers.scaling = math.max(G.GAME.modifiers.scaling or 0, 3)
        end,
        color = G.C.PURPLE,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Orange Stake",
        key = "stake_orange",
        omit_prefix = true,
        unlocked_stake = "gold",
        applied_stakes = {"purple"},
        pos = {x = 1, y = 1},
        sticker_pos = {x = 2, y = 1},
        modifiers = function()
            G.GAME.modifiers.enable_perishables_in_shop = true
        end,
        color = G.C.ORANGE,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Gold Stake",
        key = "stake_gold",
        omit_prefix = true,
        applied_stakes = {"orange"},
        pos = {x = 2, y = 1},
        sticker_pos = {x = 3, y = 1},
        modifiers = function()
            G.GAME.modifiers.enable_rentals_in_shop = true
        end,
        color = G.C.GOLD,
        shiny = true,
        loc_txt = {}
    }


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
            if self.rarities then
                self.rarity_pools = {}
                local total = 0
                for _, v in ipairs(self.rarities) do
                    total = total + v.rate
                end
                for _, v in ipairs(self.rarities) do
                    v.rate = v.rate/total
                    self.rarity_pools[v.key] = {}
                end
            end
        end,
        inject_card = function(self, center)
            if self.rarities and self.rarity_pools[center.rarity] then
                SMODS.insert_pool(self.rarity_pools[center.rarity], center)
            end
        end,
        delete_card = function(self, center)
            if self.rarities and self.rarity_pools[center.rarity] then
                SMODS.remove_pool(self.rarity_pools[center.rarity], center)
            end
        end,
        process_loc_text = function(self)
            if not next(self.loc_txt) then return end
            SMODS.process_loc_text(G.localization.misc.dictionary, 'k_' .. string.lower(self.key), self.loc_txt, 'name')
            SMODS.process_loc_text(G.localization.misc.dictionary, 'b_' .. string.lower(self.key) .. '_cards',
                self.loc_txt, 'collection')
            SMODS.process_loc_text(G.localization.misc.labels, string.lower(self.key), self.loc_txt, 'label')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'undiscovered_' .. string.lower(self.key),
                self.loc_txt, 'undiscovered')
        end
    }

    SMODS.ConsumableType {
        key = 'Tarot',
        collection_rows = { 5, 6 },
        primary_colour = G.C.SET.Tarot,
        secondary_colour = G.C.SECONDARY_SET.Tarot,
        inject_card = function(self, center)
            SMODS.ConsumableType.inject_card(self, center)
            SMODS.insert_pool(G.P_CENTER_POOLS['Tarot_Planet'], center)
        end,
        delete_card = function(self, center)
            SMODS.ConsumableType.delete_card(self, center)
            SMODS.remove_pool(G.P_CENTER_POOLS['Tarot_Planet'], center.key)
        end,
        loc_txt = {},
    }
    SMODS.ConsumableType {
        key = 'Planet',
        collection_rows = { 6, 6 },
        primary_colour = G.C.SET.Planet,
        secondary_colour = G.C.SECONDARY_SET.Planet,
        inject_card = function(self, center)
            SMODS.ConsumableType.inject_card(self, center)
            SMODS.insert_pool(G.P_CENTER_POOLS['Tarot_Planet'], center)
        end,
        delete_card = function(self, center)
            SMODS.ConsumableType.delete_card(self, center)
            SMODS.remove_pool(G.P_CENTER_POOLS['Tarot_Planet'], center.key)
        end,
        loc_txt = {},
    }
    SMODS.ConsumableType {
        key = 'Spectral',
        collection_rows = { 4, 5 },
        primary_colour = G.C.SET.Spectral,
        secondary_colour = G.C.SECONDARY_SET.Spectral,
        loc_txt = {},
    }

    local game_init_game_object_ref = Game.init_game_object
    function Game:init_game_object()
        local t = game_init_game_object_ref(self)
        for _, v in pairs(SMODS.ConsumableTypes) do
            local key = v.key:lower() .. '_rate'
            t[key] = v.shop_rate or t[key] or 0
        end
        return t
    end


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
        end,
        delete = function(self)
            G.P_CENTERS[self.key] = nil
            SMODS.remove_pool(G.P_CENTER_POOLS[self.set], self.key)
            local j
            for i, v in ipairs(self.obj_buffer) do
                if v == self.key then j = i end
            end
            if j then table.remove(self.obj_buffer, j) end
            self = nil
            return true
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
        legendaries = {},
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
            SMODS.insert_pool(G.P_CENTER_POOLS['Consumeables'], self)
            self.type = SMODS.ConsumableTypes[self.set]
            if self.hidden then
                self.soul_set = self.soul_set or 'Spectral'
                self.soul_rate = self.soul_rate or 0.003
                table.insert(self.legendaries, self)
            end
            if self.type and self.type.inject_card and type(self.type.inject_card) == 'function' then
                self.type:inject_card(self)
            end
        end,
        delete = function(self)
            if self.type and self.type.delete_card and type(self.type.delete_card) == 'function' then
                self.type:delete_card(self)
            end
            SMODS.remove_pool(G.P_CENTER_POOLS['Consumeables'], self.key)
            self.super.delete(self)
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
        atlas = 'centers',
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

    local function stake_mod(stake)
        return {
            inject = function(self)
                self.unlock_condition.stake = SMODS.Stakes[stake].stake_level
            end
        }
    end
    SMODS.Back:take_ownership('zodiac', stake_mod('stake_red'))
    SMODS.Back:take_ownership('painted', stake_mod('stake_green'))
    SMODS.Back:take_ownership('anaglyph', stake_mod('stake_black'))
    SMODS.Back:take_ownership('plasma', stake_mod('stake_blue'))
    SMODS.Back:take_ownership('erratic', stake_mod('stake_orange'))

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
    SMODS.UndiscoveredSprite { key = 'Joker', atlas = 'Joker', pos = G.j_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Edition', atlas = 'Joker', pos = G.j_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Tarot', atlas = 'Tarot', pos = G.t_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Planet', atlas = 'Tarot', pos = G.p_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Spectral', atlas = 'Tarot', pos = G.s_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Voucher', atlas = 'Voucher', pos = G.v_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Booster', atlas = 'Booster', pos = G.booster_undiscovered.pos }

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
        atlas = 'blind_chips',
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
        reverse_lookup = {},
        set = 'Seal',
        atlas = 'centers',
        discovered = false,
        colour = HEX('FFFFFF'),
        required_params = {
            'key',
            'pos',
            'loc_txt'
        },
        inject = function(self)
            G.P_SEALS[self.key] = self
            G.shared_seals[self.key] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[self.atlas] or G.ASSET_ATLAS['centers'], self.pos)
            self.reverse_lookup[self.key:lower()..'_seal'] = self.key
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
            self.rng_buffer[#self.rng_buffer + 1] = self.key
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, self.key:lower() .. '_seal', self.loc_txt,
                'description')
            SMODS.process_loc_text(G.localization.misc.labels, self.key:lower() .. '_seal', self.loc_txt, 'label')
        end,
        get_obj = function(self, key) return G.P_SEALS[key] end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Suit
    -------------------------------------------------------------------------------------------------

    SMODS.permutations = function(list, n)
        list = list or
            { 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U',
                'V',
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
            if not card_key then error(('Unable to find valid ID for %s: %s'):format(self.set, self.key)) end
            return card_key
        end,
        process_loc_text = function(self)
            -- empty loc_txt indicates there are existing values that shouldn't be changed
            if next(self.loc_txt) then
                SMODS.process_loc_text(G.localization.misc.suits_plural, self.key, self.loc_txt, 'plural')
                SMODS.process_loc_text(G.localization.misc.suits_singular, self.key, self.loc_txt, 'singular')
                if type(self.lc_colour) == 'string' then self.lc_colour = HEX(self.lc_colour) end
                if type(self.hc_colour) == 'string' then self.hc_colour = HEX(self.hc_colour) end
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
    }
    SMODS.Suit {
        key = 'Clubs',
        card_key = 'C',
        pos = { y = 1 },
        ui_pos = { x = 2, y = 1 },
        loc_txt = {},
    }
    SMODS.Suit {
        key = 'Hearts',
        card_key = 'H',
        pos = { y = 0 },
        ui_pos = { x = 0, y = 1 },
        loc_txt = {},
    }
    SMODS.Suit {
        key = 'Spades',
        card_key = 'S',
        pos = { y = 3 },
        ui_pos = { x = 3, y = 1 },
        loc_txt = {},
    }
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
        }
    end
    SMODS.Rank {
        key = '10',
        card_key = 'T',
        pos = { x = 8 },
        nominal = 10,
        next = { 'Jack' },
        loc_txt = {},
    }
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
    }
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
    }
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
    }
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
    }
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
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    play_sound('tarot1')
                    used_tarot:juice_up(0.3, 0.5)
                    return true
                end
            }))
            for i = 1, #G.hand.highlighted do
                local percent = 1.15 - (i - 0.999) / (#G.hand.highlighted - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.highlighted[i]:flip(); play_sound('card1', percent); G.hand.highlighted[i]:juice_up(0.3,
                            0.3); return true
                    end
                }))
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
    })
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
    })
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
    })
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
    })
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
    })
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
                        local _suit, _rank =
                            SMODS.Suits[pseudorandom_element(suit_list, pseudoseed('incantation_create'))].card_key,
                            pseudorandom_element(numbers, pseudoseed('incantation_create'))
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
    })
    SMODS.Blind:take_ownership('eye', {
        set_blind = function(self, blind, reset, silent)
            if not reset then
                for _, v in ipairs(G.handlist) do
                    self.hands[v] = false
                end
            end
        end
    })

    -- no point in using lovely for this, since no part of the original function is useful
    function get_straight(hand)
        local ret = {}
        local four_fingers = next(find_joker('Four Fingers'))
        local can_skip = next(find_joker('Shortcut'))
        if #hand < (5 - (four_fingers and 1 or 0)) then return ret end
        local t = {}
        local RANKS = {}
        for i = 1, #hand do
            if hand[i]:get_id() > 0 then
                local rank = hand[i].base.value
                RANKS[rank] = RANKS[rank] or {}
                RANKS[rank][#RANKS[rank] + 1] = hand[i]
            end
        end
        local straight_length = 0
        local straight = false
        local skipped_rank = false
        local vals = {}
        for k, v in pairs(SMODS.Ranks) do
            if v.straight_edge then
                table.insert(vals, k)
            end
        end
        local init_vals = {}
        for _, v in ipairs(vals) do
            init_vals[v] = true
        end
        if not next(vals) then table.insert(vals, 'Ace') end
        local initial = true
        local br = false
        local end_iter = false
        local i = 0
        while 1 do
            end_iter = false
            if straight_length >= (5 - (four_fingers and 1 or 0)) then
                straight = true
            end
            i = i + 1
            if br or (i > #SMODS.Rank.obj_buffer + 1) then break end
            if not next(vals) then break end
            for _, val in ipairs(vals) do
                if init_vals[val] and not initial then br = true end
                if RANKS[val] then
                    straight_length = straight_length + 1
                    skipped_rank = false
                    for _, vv in ipairs(RANKS[val]) do
                        t[#t + 1] = vv
                    end
                    vals = SMODS.Ranks[val].next
                    initial = false
                    end_iter = true
                    break
                end
            end
            if not end_iter then
                local new_vals = {}
                for _, val in ipairs(vals) do
                    for _, r in ipairs(SMODS.Ranks[val].next) do
                        table.insert(new_vals, r)
                    end
                end
                vals = new_vals
                if can_skip and not skipped_rank then
                    skipped_rank = true
                else
                    straight_length = 0
                    skipped_rank = false
                    if not straight then t = {} end
                    if straight then break end
                end
            end
        end
        if not straight then return ret end
        table.insert(ret, t)
        return ret
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.PokerHand
    -------------------------------------------------------------------------------------------------

    SMODS.PokerHands = {}
    SMODS.PokerHand = SMODS.GameObject:extend {
        obj_table = SMODS.PokerHands,
        obj_buffer = {},
        required_params = {
            'key',
            'above_hand',
            'mult',
            'chips',
            'l_mult',
            'l_chips',
            'example',
            'loc_txt'
        },
        order_lookup = {},
        visible = true,
        played = 0,
        played_this_round = 0,
        level = 1,
        prefix = 'h',
        set = 'PokerHand',
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.poker_hands, self.key, self.loc_txt, 'name')
            SMODS.process_loc_text(G.localization.misc.poker_hand_descriptions, self.key, self.loc_txt, 'description')
        end,
        register = function(self)
            if self:check_dependencies() and not self.obj_table[self.key] then
                local j
                for i, v in ipairs(G.handlist) do
                    if v == self.above_hand then j = i end
                end
                -- insertion must not happen more than once, so do it on registration
                table.insert(G.handlist, j, self.key)
                self.order_lookup[j] = (self.order_lookup[j] or 0) - 0.001
                self.order = j + self.order_lookup[j]
                self.s_mult = self.mult
                self.s_chips = self.chips
                self.visible = self.visible
                self.level = self.level
                self.played = self.played
                self.played_this_round = self.played_this_round
                self.obj_table[self.key] = self
                self.obj_buffer[#self.obj_buffer + 1] = self.key
            end
        end,
        inject = function(self) end
    }

    -- this would be annoying to patch in with lovely
    local init_game_object_ref = Game.init_game_object
    function Game:init_game_object()
        local t = init_game_object_ref(self)
        for _, key in ipairs(SMODS.PokerHand.obj_buffer) do
            t.hands[key] = {}
            for k, v in pairs(SMODS.PokerHands[key]) do
                -- G.GAME needs to be able to be serialized
                if type(v) == 'number' or type(v) == 'boolean' or k == 'example' then
                    t.hands[key][k] = v
                end
            end
        end
        return t
    end
    -- why bother patching when i basically change everything
    function G.FUNCS.get_poker_hand_info(_cards)
        local poker_hands = evaluate_poker_hand(_cards)
        local scoring_hand = {}
        local text, disp_text, loc_disp_text = 'NULL', 'NULL', 'NULL'
        for _, v in ipairs(G.handlist) do
            if next(poker_hands[v]) then
                text = v
                scoring_hand = poker_hands[v][1]
                break
            end
        end
        disp_text = text
        local _hand = SMODS.PokerHands[text]
        if text == 'Straight Flush' then
            local royal = true
            for j = 1, #scoring_hand do
                local rank = SMODS.Ranks[scoring_hand[j].base.value]
                royal = royal and (rank.key == 'Ace' or rank.key == '10' or rank.face)
            end
            if royal then
                disp_text = 'Royal Flush'
            end
        elseif _hand and _hand.modify_display_text and type(_hand.modify_display_text) == 'function' then
            disp_text = _hand.modify_display_text(_cards, scoring_hand) or disp_text
        end
        loc_disp_text = localize(disp_text, 'poker_hands')
        return text, loc_disp_text, poker_hands, scoring_hand, disp_text
    end

    function create_UIBox_current_hands(simple)
        G.current_hands = {}
        local index = 0
        for _, v in ipairs(G.handlist) do
            local ui_element = create_UIBox_current_hand_row(v, simple)
            G.current_hands[index + 1] = ui_element
            if ui_element then
                index = index + 1
            end
            if index >= 10 then
                break
            end
        end

        local visible_hands = {}
        for _, v in ipairs(G.handlist) do
            if G.GAME.hands[v].visible then
                table.insert(visible_hands, v)
            end
        end

        local hand_options = {}
        for i = 1, math.ceil(#visible_hands / 10) do
            table.insert(hand_options,
                localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_hands / 10)))
        end

        local object = {
            n = G.UIT.ROOT,
            config = { align = "cm", colour = G.C.CLEAR },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.04 },
                    nodes = G.current_hands
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0 },
                    nodes = {
                        create_option_cycle({
                            options = hand_options,
                            w = 4.5,
                            cycle_shoulders = true,
                            opt_callback = 'your_hands_page',
                            focus_args = { snap_to = true, nav = 'wide' },
                            current_option = 1,
                            colour = G.C.RED,
                            no_pips = true
                        })
                    }
                }
            }
        }

        local t = {
            n = G.UIT.ROOT,
            config = { align = "cm", minw = 3, padding = 0.1, r = 0.1, colour = G.C.CLEAR },
            nodes = {
                {
                    n = G.UIT.O,
                    config = {
                        id = 'hand_list',
                        object = UIBox {
                            definition = object,
                            config = { offset = { x = 0, y = 0 }, align = 'cm' }
                        }
                    }
                }
            }
        }
        return t
    end

    G.FUNCS.your_hands_page = function(args)
        if not args or not args.cycle_config then return end
        G.current_hands = {}


        local index = 0
        for _, v in ipairs(G.handlist) do
            local ui_element = create_UIBox_current_hand_row(v, simple)
            if index >= (0 + 10 * (args.cycle_config.current_option - 1)) and index < 10 * args.cycle_config.current_option then
                G.current_hands[index - (10 * (args.cycle_config.current_option - 1)) + 1] = ui_element
            end

            if ui_element then
                index = index + 1
            end

            if index >= 10 * args.cycle_config.current_option then
                break
            end
        end

        local visible_hands = {}
        for _, v in ipairs(G.handlist) do
            if G.GAME.hands[v].visible then
                table.insert(visible_hands, v)
            end
        end

        local hand_options = {}
        for i = 1, math.ceil(#visible_hands / 10) do
            table.insert(hand_options,
                localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_hands / 10)))
        end

        local object = {
            n = G.UIT.ROOT,
            config = { align = "cm", colour = G.C.CLEAR },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.04 },
                    nodes = G.current_hands
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0 },
                    nodes = {
                        create_option_cycle({
                            options = hand_options,
                            w = 4.5,
                            cycle_shoulders = true,
                            opt_callback =
                            'your_hands_page',
                            focus_args = { snap_to = true, nav = 'wide' },
                            current_option = args.cycle_config.current_option,
                            colour = G
                                .C.RED,
                            no_pips = true
                        })
                    }
                }
            }
        }

        local hand_list = G.OVERLAY_MENU:get_UIE_by_ID('hand_list')
        if hand_list then
            if hand_list.config.object then
                hand_list.config.object:remove()
            end
            hand_list.config.object = UIBox {
                definition = object,
                config = { offset = { x = 0, y = 0 }, align = 'cm', parent = hand_list }
            }
        end
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Challenge
    -------------------------------------------------------------------------------------------------

    SMODS.Challenges = {}
    SMODS.Challenge = SMODS.GameObject:extend {
    obj_table = SMODS.Challenges,
    obj_buffer = {},
    set = "Challenge",
    required_params = {
        'name',
        'key', 
    },
    deck = {type = "Challenge Deck"},
    rules = {custom = {},modifiers = {}},
    jokers = {},
    consumeables = {},
    vouchers = {},
    restrictions = {banned_cards = {}, banned_tags = {}, banned_other = {}},
    prefix = 'c',
    process_loc_text = function(self)
        SMODS.process_loc_text(G.localization.misc.challenge_names, self.key, self.name)
    end,
    inject = function(self)
        self.id = self.key
        SMODS.insert_pool(G.CHALLENGES, self)
    end,
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Stake
    -------------------------------------------------------------------------------------------------

    SMODS.Stakes = {}
    SMODS.Stake = SMODS.GameObject:extend {
        obj_table = SMODS.Stakes,
        obj_buffer = {},
        prefix = 'stake',
        unlocked = false,
        set = 'Stake',
        atlas = 'chips',
        injected = false,
        required_params = {
            'name',
            'pos',
            'loc_txt',
            'applied_stakes'
        },
        inject = function(self)
            if not self.injected then
                -- Inject stake in the correct spot
                local count = #G.P_CENTER_POOLS[self.set]+1
                if self.above_stake then
                count = G.P_STAKES[self.prefix.."_"..self.above_stake].stake_level+1
                end
                self.order = count
                self.stake_level = count
                for _, v in pairs(G.P_STAKES) do
                if v.stake_level >= self.stake_level then
                    v.stake_level = v.stake_level + 1
                    v.order = v.stake_level
                end
                end
                G.P_STAKES[self.key] = self
                -- Localization text for applying stakes
                if next(self.loc_txt) then
                local applied_text = "{s:0.8}Applies "
                for _, v in pairs(self.applied_stakes) do
                    applied_text = applied_text .. G.P_STAKES[self.prefix.."_"..v].name .. ", "
                end
                applied_text = applied_text:sub(1, -3)
                if (applied_text == "{s:0.8}Applie") then applied_text = "{s:0.8}" end
                self.loc_txt.text[#self.loc_txt.text+1] = applied_text
                end
                -- Sticker sprites (stake_ prefix is removed for vanilla compatiblity)
                if self.sticker_pos ~= nil then
                    G.shared_stickers[self.key:sub(7)] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[self.sticker_atlas] or G.ASSET_ATLAS["stickers"], self.sticker_pos)
                    G.sticker_map[self.stake_level] = self.key:sub(7)
                else
                    G.sticker_map[self.stake_level] = nil
                end
            else
                G.P_STAKES[self.key] = self
            end
            G.P_CENTER_POOLS[self.set] = {}
            for _, v in pairs(G.P_STAKES) do
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], v)
            end
            table.sort(G.P_CENTER_POOLS[self.set], function(a,b) return a.stake_level < b.stake_level end)
            G.C.STAKES = {}
            for i = 1, #G.P_CENTER_POOLS[self.set] do
                G.C.STAKES[i] = G.P_CENTER_POOLS[self.set][i].color or G.C.WHITE
            end
            self.injected = true
        end,
        process_loc_text = function(self)
            -- empty loc_txt indicates there are existing values that shouldn't be changed or it isn't necessary
            if next(self.loc_txt) then
                SMODS.process_loc_text(G.localization.descriptions[self.set], self.key, self.loc_txt)
            end
            if self.sticker_loc_txt and next(self.sticker_loc_txt) then
                SMODS.process_loc_text(G.localization.descriptions["Other"], self.key:sub(7).."_sticker", self.sticker_loc_txt)
            end
        end,
        get_obj = function(self, key) return G.P_STAKES[key] end
    }

    function SMODS.setup_stake(i)
    if G.P_CENTER_POOLS['Stake'][i].modifiers then
        G.P_CENTER_POOLS['Stake'][i].modifiers()
    end
    if G.P_CENTER_POOLS['Stake'][i].applied_stakes then
        for _, v in pairs(G.P_CENTER_POOLS['Stake'][i].applied_stakes) do
        SMODS.setup_stake(G.P_STAKES["stake_"..v].stake_level)
        end
    end
    end

    function SMODS.applied_stakes_UI(i, stake_desc_rows, num_added)
    if num_added == nil then num_added = {val = 0} end
    if G.P_CENTER_POOLS['Stake'][i].applied_stakes then
        for _, v in pairs(G.P_CENTER_POOLS['Stake'][i].applied_stakes) do
        if v ~= "white" then
            --todo: manage this with pages
            if num_added.val < 8 then
                local i = G.P_STAKES["stake_"..v].stake_level
                local _stake_desc = {}
                local _stake_center = G.P_CENTER_POOLS.Stake[i]
                localize{type = 'descriptions', key = _stake_center.key, set = _stake_center.set, nodes = _stake_desc}
                local _full_desc = {}
                for k, v in ipairs(_stake_desc) do
                _full_desc[#_full_desc+1] = {n=G.UIT.R, config={align = "cm"}, nodes=v}
                end
                _full_desc[#_full_desc] = nil
                stake_desc_rows[#stake_desc_rows+1] = {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.C, config={align = 'cm'}, nodes ={{n=G.UIT.C, config={align = "cm", colour = get_stake_col(i), r = 0.1, minh = 0.35, minw = 0.35, emboss = 0.05}, nodes={}}, {n=G.UIT.B, config={w=0.1,h=0.1}}}},
                {n=G.UIT.C, config={align = "cm", padding = 0.03, colour = G.C.WHITE, r = 0.1, minh = 0.7, minw = 4.8}, nodes=_full_desc},
                }}
            end
            num_added.val = num_added.val + 1
            num_added.val = SMODS.applied_stakes_UI(G.P_STAKES["stake_"..v].stake_level, stake_desc_rows, num_added)
        end
        end
    end
    end

    -- We're overwriting so much that it's better to just remake this
    function G.UIDEF.deck_stake_column(_deck_key)
        local deck_usage = G.PROFILES[G.SETTINGS.profile].deck_usage[_deck_key]
        local stake_col = {}
        local valid_option = nil
        local num_stakes = #G.P_CENTER_POOLS['Stake']
        for i = #G.P_CENTER_POOLS['Stake'], 1, -1 do
        local _wins = deck_usage and deck_usage.wins[i] or 0
        if (deck_usage and deck_usage.wins[i-1]) or i == 1 or G.PROFILES[G.SETTINGS.profile].all_unlocked then valid_option = true end
        stake_col[#stake_col+1] = {n=G.UIT.R, config={id = i, align = "cm", colour = _wins > 0 and G.C.GREY or G.C.CLEAR, outline = 0, outline_colour = G.C.WHITE, r = 0.1, minh = 2/num_stakes, minw = valid_option and 0.45 or 0.25, func = 'RUN_SETUP_check_back_stake_highlight'}, nodes={
            {n=G.UIT.R, config={align = "cm", minh = valid_option and 1.36/num_stakes or 1.04/num_stakes, minw = valid_option and 0.37 or 0.13, colour = _wins > 0 and get_stake_col(i) or G.C.UI.TRANSPARENT_LIGHT, r = 0.1},nodes={}}
        }}
        if i > 1 then stake_col[#stake_col+1] = {n=G.UIT.R, config={align = "cm", minh = 0.8/num_stakes, minw = 0.04},nodes={}} end
        end
        return {n=G.UIT.ROOT, config={align = 'cm', colour = G.C.CLEAR}, nodes =stake_col}
    end

    --Register vanilla stakes
    G.P_CENTER_POOLS['Stake'] = {}
    G.P_STAKES = {}
    SMODS.Stake({
        name = "White Stake",
        key = "stake_white",
        omit_prefix = true,
        unlocked_stake = "red",
        unlocked = true,
        applied_stakes = {},
        pos = {x = 0, y = 0},
        sticker_pos = {x = 1, y = 0},
        color = G.C.WHITE,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Red Stake",
        key = "stake_red",
        omit_prefix = true,
        unlocked_stake = "green",
        applied_stakes = {"white"},
        pos = {x = 1, y = 0},
        sticker_pos = {x = 2, y = 0},
        modifiers = function()
            G.GAME.modifiers.no_blind_reward = G.GAME.modifiers.no_blind_reward or {}
            G.GAME.modifiers.no_blind_reward.Small = true
        end,
        color = G.C.RED,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Green Stake",
        key = "stake_green",
        omit_prefix = true,
        unlocked_stake = "black",
        applied_stakes = {"red"},
        pos = {x = 2, y = 0},
        sticker_pos = {x = 3, y = 0},
        modifiers = function()
            G.GAME.modifiers.scaling = math.max(G.GAME.modifiers.scaling or 0, 2)
        end,
        color = G.C.GREEN,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Black Stake",
        key = "stake_black",
        omit_prefix = true,
        unlocked_stake = "blue",
        applied_stakes = {"green"},
        pos = {x = 4, y = 0},
        sticker_pos = {x = 0, y = 1},
        modifiers = function()
            G.GAME.modifiers.enable_eternals_in_shop = true
        end,
        color = G.C.BLACK,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Blue Stake",
        key = "stake_blue",
        omit_prefix = true,
        unlocked_stake = "purple",
        applied_stakes = {"black"},
        pos = {x = 3, y = 0},
        sticker_pos = {x = 4, y = 0},
        modifiers = function()
            G.GAME.starting_params.discards = G.GAME.starting_params.discards - 1
        end,
        color = G.C.BLUE,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Purple Stake",
        key = "stake_purple",
        omit_prefix = true,
        unlocked_stake = "orange",
        applied_stakes = {"blue"},
        pos = {x = 0, y = 1},
        sticker_pos = {x = 1, y = 1},
        modifiers = function()
            G.GAME.modifiers.scaling = math.max(G.GAME.modifiers.scaling or 0, 3)
        end,
        color = G.C.PURPLE,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Orange Stake",
        key = "stake_orange",
        omit_prefix = true,
        unlocked_stake = "gold",
        applied_stakes = {"purple"},
        pos = {x = 1, y = 1},
        sticker_pos = {x = 2, y = 1},
        modifiers = function()
            G.GAME.modifiers.enable_perishables_in_shop = true
        end,
        color = G.C.ORANGE,
        loc_txt = {}
    }):register()
    SMODS.Stake({
        name = "Gold Stake",
        key = "stake_gold",
        omit_prefix = true,
        applied_stakes = {"orange"},
        pos = {x = 2, y = 1},
        sticker_pos = {x = 3, y = 1},
        modifiers = function()
            G.GAME.modifiers.enable_rentals_in_shop = true
        end,
        color = G.C.GOLD,
        shiny = true,
        loc_txt = {}
    }):register()

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Tag
    -------------------------------------------------------------------------------------------------

    SMODS.Tags = {}
    SMODS.Tag = SMODS.GameObject:extend {
        obj_table = SMODS.Tags,
        obj_buffer = {},
        required_params = {
            'key',
            'name',
            'loc_txt'
        },
        discovered = false,
        min_ante = nil,
        atlas = 'tags',
        prefix = 'tag',
        set = 'Tag',
        pos = { x = 0, y = 0 },
        config = {},
        get_obj = function(key) return G.P_TAGS[key] end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Tag, self.key, self.loc_txt)
        end,
        inject = function(self)
            G.P_TAGS[self.key] = self
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
        end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Sticker
    -------------------------------------------------------------------------------------------------

    SMODS.Stickers = {}
    SMODS.Sticker = SMODS.GameObject:extend {
        obj_table = SMODS.Stickers,
        obj_buffer = {},
        set = 'Sticker',
        required_params = {
            'key',
            'loc_txt'
        },
        prefix = 'st',
        rate = 0.3,
        atlas = 'stickers',
        pos = { x = 0, y = 0 },
        colour = HEX 'FFFFFF',
        default_compat = true,
        compat_exceptions = {},
        sets = { Joker = true },
        needs_enable_flag = true,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, self.key, self.loc_txt, 'description')
            SMODS.process_loc_text(G.localization.misc.labels, self.key, self.loc_txt, 'label')
        end,
        inject = function() end,
        set_sticker = function(self, card, val)
            card.ability[self.key] = val
        end
    }
end
