--- STEAMODDED HEADER
--- MOD_NAME: Edition API
--- MOD_ID: EditionAPI
--- MOD_AUTHOR: [Eremel_]
--- MOD_DESCRIPTION: Grants the ability to add custom editions to the game.
--- PRIORITY: -9001
----------------------------------------------
------------MOD CODE -------------------------
SMODS.Editions = {}
SMODS.Edition_List = {}
SMODS.Edition = {
    name = "",
    key = "",
    config = {},
    shader = "",
    loc_txt = {},
    discovered = true,
    unlocked = true,
    unlock_condition = {},
    badge_colour = "",
    custom = true,
    apply_to_float = false,
    weight = 0,
    in_shop = false,
    extra_cost = 0
}
SMODS.scoring_keys = {
    chip_mod = "a_chips",
    mult_mod = "a_mult",
    x_mult_mod = "a_xmult"
}

local base_game_edition_configs = {
    {
        base = true,
        name = "Foil",
        key = "foil",
        config = { labels = {'chip_mod'}, values = {50} },
        shader = "/assets/shaders/foil.fs",
        loc_txt = { name = "Foil", text = {"{C:chips}+#1#{} chips"}},
        sound = { sound = "foil1", per = 1.2, vol = 0.4 },
        discovered = false,
        unlocked = true,
        unlock_condition = {},
        badge_colour = G.C.DARK_EDITION,
        apply_to_float = false,
        weight = 20,
        in_shop = true,
        extra_cost = 2,
        calculate = function(self, context)
            if context.edition or (context.cardarea == G.play and self.playing_card) then
                ret = {}
                for k, v in pairs(self.edition) do
                    ret[k] = v
                end
                return ret
            end
        end
    },
    {
        base = true,
        name = "Holographic",
        key = "holo",
        config = { labels = {'mult_mod'}, values = {10} },
        shader = "holo",
        loc_txt = { name = "Holographic", text = { "{C:mult}+#1#{} Mult" }},
        sound = { sound = "holo1", per = 1.2*1.58, vol = 0.4 },
        discovered = false,
        unlocked = true,
        unlock_condition = {},
        badge_colour = G.C.DARK_EDITION,
        apply_to_float = false,
        weight = 14,
        in_shop = true,
        extra_cost = 3,
        calculate = function(self, context)
            if context.edition or (context.cardarea == G.play and self.playing_card) then
                ret = {}
                for k, v in pairs(self.edition) do
                    ret[k] = v
                end
                return ret
            end
        end
    },
    {   
        base = true,
        name = "Polychrome",
        key = "polychrome",
        config = { labels = {'x_mult_mod'}, values = {1.5} },
        shader = "polychrome",
        loc_txt = { name = "Polychrome", text = { "{X:mult,C:white} X#1# {} Mult" }},
        sound = { sound = "polychrome1", per = 1.2, vol = 0.7 },
        discovered = false,
        unlocked = true,
        unlock_condition = {},
        badge_colour = G.C.DARK_EDITION,
        apply_to_float = false,
        weight = 3,
        in_shop = true,
        extra_cost = 5,
        calculate = function(self, context)
            if context.edition or (context.cardarea == G.play and self.playing_card) then
                ret = {}
                for k, v in pairs(self.edition) do
                    ret[k] = v
                end
                return ret
            end
        end
    },
    {
        base = true,
        name = "Negative",
        key = "negative",
        config = { labels = {'card_limit'}, values = {1} },
        shader = "negative",
        loc_txt = { name = "Negative", text = { "{C:dark_edition}+#1#{} Joker slot" }},
        sound = { sound = "negative", per = 1.5, vol = 0.4 },
        discovered = false,
        unlocked = true,
        unlock_condition = {},
        badge_colour = G.C.DARK_EDITION,
        apply_to_float = false,
        weight = 3,
        in_shop = true,
        extra_cost = 5,
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
}

function SMODS.Edition:new(options)
    o = {}
    setmetatable(o, self)
    self.__index = self

    if options.base then else
        G.SHADERS[options.key] = love.graphics.newShader(options.shader_path)
    end

    o.base = options.base or nil
    o.loc_txt = options.loc_txt
    o.name = options.name
    o.key = "e_" .. options.key
    o.config = options.config or { labels = {}, values = {}}
    o.discovered = options.discovered or false
    o.unlocked = options.unlocked
    o.unlock_condition = options.unlock_condition or {}
    o.shader = options.key
    o.sound = options.sound or { sound = "foil1", per = 1.2, vol = 0.4 }
    o.mod_name = SMODS.current_mod.name
    o.badge_colour = options.badge_colour or SMODS._BADGE_COLOUR or G.C.DARK_EDITION
    o.apply_to_float = options.apply_to_float or false
    o.weight = options.weight or 0
    o.in_shop = options.in_shop or false
    o.extra_cost = options.extra_cost or 0
    o.calculate = options.calculate or nil
    return o
end

function SMODS.Edition:register()
    SMODS.Editions[self.key:sub(3)] = self
    local minId = #G.P_CENTER_POOLS['Edition'] + 1
    local id = 0
    local i = 0
    i = i + 1

    id = i + minId
    local edition_obj = {
        discovered = self.discovered,
        unlocked = self.unlocked,
        name = self.name,
        set = "Edition",
        custom = true,
        pos = {
            x = 0,
            y = 0
        },
        atlas = 'Joker',
        order = id,
        key = self.key,
        config = self.config,
        unlock_condition = self.unlock_condition,
        shader = self.shader,
        sound = self.sound,
        apply_to_float = self.apply_to_float,
        mod_name = self.mod_name,
        badge_colour = self.badge_colour,
        extra_cost = self.extra_cost,
        weight = self.weight
    }

    -- Populate pools
    G.P_CENTERS[self.key] = edition_obj
    table.insert(G.P_CENTER_POOLS['Edition'], edition_obj)

    if self.in_shop then
        table.insert(SMODS.Edition_List, self.key:sub(3))
    end

    -- Setup Localize text
    function SMODS.current_mod.process_loc_text()
        G.localization.descriptions['Edition'][self.key] = self.loc_txt
        G.localization.misc.labels[self.key:sub(3)] = self.name
    end
    

    sendInfoMessage("Registered " .. self.name .. " with the key " .. self.key .. " at ID " .. id .. ".",
        "EditionAPI")
    
end

local create_UIBox_your_collection_editions_ref = create_UIBox_your_collection_editions
function create_UIBox_your_collection_editions(exit)
    local deck_tables = {}
    local rows, cols = E_ROWS, E_COLS
    local page = 0


    G.your_collection = {}
    for j = 1, rows do
        G.your_collection[j] = CardArea(G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h, 5.3 * G.CARD_W, 1.03 * G.CARD_H,
            {
                card_limit = cols,
                type = 'title',
                highlight_limit = 0,
                collection = true
            })
        table.insert(deck_tables, {
            n = G.UIT.R,
            config = {
                align = "cm",
                padding = 0,
                no_fill = true
            },
            nodes = {{
                n = G.UIT.O,
                config = {
                    object = G.your_collection[j]
                }
            }}
        })
    end

    local count = math.min(cols * rows, #G.P_CENTER_POOLS["Edition"])
    local index = 1 + (rows * cols * page)
    for j = 1, rows do
        for i = 1, cols do

            local center = G.P_CENTER_POOLS.Edition[index]

            if not center then
                break
            end
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y,
                G.CARD_W, G.CARD_H, nil, center)
            card:start_materialize(nil, i > 1 or j > 1)
            card:set_edition({
                [center.key:sub(3)] = true
            }, true, true, {
                name = center.key:sub(3),
                config = center.config
            })
            G.your_collection[j]:emplace(card)
            index = index + 1
        end
        if index > count then
            break
        end
    end

    local edition_options = {}

    local t = create_UIBox_generic_options({
        infotip = localize('ml_edition_seal_enhancement_explanation'),
        back_func = exit or 'your_collection',
        snap_back = true,
        contents = {{
            n = G.UIT.R,
            config = {
                align = "cm",
                minw = 2.5,
                padding = 0.1,
                r = 0.1,
                colour = G.C.BLACK,
                emboss = 0.05
            },
            nodes = deck_tables
        }}
    })

    if #G.P_CENTER_POOLS["Edition"] > rows * cols then
        for i = 1, math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols)) do
            table.insert(edition_options, localize('k_page') .. ' ' .. tostring(i) .. '/' ..
                tostring(math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols))))
        end
        t = create_UIBox_generic_options({
            infotip = localize('ml_edition_seal_enhancement_explanation'),
            back_func = exit or 'your_collection',
            snap_back = true,
            contents = {{
                n = G.UIT.R,
                config = {
                    align = "cm",
                    minw = 2.5,
                    padding = 0.1,
                    r = 0.1,
                    colour = G.C.BLACK,
                    emboss = 0.05
                },
                nodes = deck_tables
            }, {
                n = G.UIT.R,
                config = {
                    align = "cm"
                },
                nodes = {create_option_cycle({
                    options = edition_options,
                    w = 4.5,
                    cycle_shoulders = true,
                    opt_callback = 'your_collection_editions_page',
                    focus_args = {
                        snap_to = true,
                        nav = 'wide'
                    },
                    current_option = 1,
                    r = rows,
                    c = cols,
                    colour = G.C.RED,
                    no_pips = true
                })}
            }}
        })
    end
    return t
end

G.FUNCS.your_collection_editions_page = function(args)
    if not args or not args.cycle_config then
        return
    end
    local rows = E_ROWS
    local cols = E_COLS
    local page = args.cycle_config.current_option
    if page > math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols)) then
        page = page - math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols))
    end
    sendDebugMessage(page .. " / " .. math.ceil(#G.P_CENTER_POOLS.Edition / (rows * cols)), "EditionAPI")
    local count = rows * cols
    local offset = (rows * cols) * (page - 1)
    sendDebugMessage("Page offset: " .. tostring(offset), "EditionAPI")

    for j = 1, #G.your_collection do
        for i = #G.your_collection[j].cards, 1, -1 do
            if G.your_collection[j] ~= nil then
                local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
                c:remove()
                c = nil
            end
        end
    end

    for j = 1, rows do
        for i = 1, cols do
            if count % rows > 0 and i <= count % rows and j == cols then
                offset = offset - 1
                break
            end
            local idx = i + (j - 1) * cols + offset
            if idx > #G.P_CENTER_POOLS["Edition"] then
                sendDebugMessage("End of Edition table.", "EditionAPI")
                return
            end
            sendDebugMessage("Loading Edition " .. tostring(idx), "EditionAPI")
            local center = G.P_CENTER_POOLS["Edition"][idx]
            sendDebugMessage("Edition " .. ((center and "loaded") or "did not load") .. " successfuly.", "EditionAPI")
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y,
                G.CARD_W, G.CARD_H, G.P_CARDS.empty, center)
            card:set_edition({
                [center.key:sub(3)] = true
            }, true, true, {
                name = center.key:sub(3),
                config = center.config
            })
            card:start_materialize(nil, i > 1 or j > 1)
            G.your_collection[j]:emplace(card)
        end
    end
    sendDebugMessage("All Editions of Page " .. page .. " loaded.", "EditionAPI")
end

function get_badge_colour(key)
    if key == "base" then return {1,0,0,1} end
    G.BADGE_COL = G.BADGE_COL or {
        eternal = G.C.ETERNAL,
        foil = G.C.DARK_EDITION,
        holographic = G.C.DARK_EDITION,
        polychrome = G.C.DARK_EDITION,
        negative = G.C.DARK_EDITION,
        gold_seal = G.C.GOLD,
        red_seal = G.C.RED,
        blue_seal = G.C.BLUE,
        purple_seal = G.C.PURPLE,
        pinned_left = G.C.ORANGE
    }
    return G.BADGE_COL[key:lower()] or SMODS.Editions[key:lower()].badge_colour or {1, 0, 0, 1}
end

local card_h_popup_ref = G.UIDEF.card_h_popup
function G.UIDEF.card_h_popup(card)
	local t = card_h_popup_ref(card)
    if card.edition then 
        local edition = nil
        for k,v in pairs(card.edition) do
            if SMODS.Editions[k] and not SMODS.Editions[k].base then
                edition = k
                break
            end
        end
        if not edition then return t end

        local badges = t.nodes[1].nodes[1].nodes[1].nodes[3]
        badges = badges and badges.nodes or nil
        local center_obj = card.config.center
        if center_obj then
            if center_obj.set_badges and type(center_obj.set_badges) == 'function' then
                center_obj.set_badges(card, badges)
            end
            if not G.SETTINGS.no_mod_tracking then
                local mod_name = string.sub(SMODS.Editions[edition].mod_name, 1, 16)
                local len = string.len(mod_name)
                badges[#badges + 1] = create_badge(mod_name, SMODS._BADGE_COLOUR or G.C.UI.BACKGROUND_INACTIVE, nil,
                    len <= 6 and 0.9 or 0.9 - 0.02 * (len - 6))
            end
        end
    end
	return t
end


function get_edition_options(key)
    return {
        name = key,
        sound = G.P_CENTERS["e_"..key].sound,
        config = G.P_CENTERS["e_"..key].config
    }
end

function Card:get_edition(context)
    if self.debuff then return end
    if self.edition then
        if context.repetition then
            for _,v in ipairs(SMODS.Editions[self.edition.type].config.labels) do
                if v == "repetitions" then
                    return SMODS.Editions[self.edition.type].calculate(self, context)
                end
            end
        else
            return SMODS.Editions[self.edition.type].calculate(self, context)
        end
    end
end


local set_edition_ref = Card.set_edition
-- self = pass the card
-- edition = { name_of_edition = true } (key without e_)
-- immediate = boolean value
-- silent = boolean value
-- options = Table containing name and config. { name = edition_name, config = {config in here}}
function Card.set_edition(self, edition, immediate, silent, options)
    self.edition = nil
    if not edition then
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = not immediate and 0.2 or 0,
            blockable = not immediate,
            func = function()
                self:juice_up(1, 0.5)
                play_sound('whoosh2', 1.2, 0.6)
                return true
            end
        }))
        return
    end
    
    if not options then
        for k,v in pairs(edition) do
            if k == 'type' then
                    if v then
                        options = get_edition_options(v)
                    end
            else
                if SMODS.Editions[k] then
                    if v then
                        options = get_edition_options(k)
                    end
                end
            end
        end
        if not options then
            return set_edition_ref(self, edition, immediate, silent)
        end
    end

    if not self.ability.edition then
        self.ability.edition = {}
    end
    
    
    if not self.edition then
        self.edition = {}
        self.edition[options.name] = true
        self.edition.type = options.name
        for k, v in ipairs(options.config.labels) do
            self.edition[v] = self.ability.edition[v] or options.config.values[k]
            if v == 'card_limit' then
                for k2,v2 in pairs(self.ability) do
                    sendDebugMessage(k2..": "..tostring(v2))
                end
                if self.ability.consumeable then
                    G.consumeables.config.card_limit = G.consumeables.config.card_limit + options.config.values[k]
                elseif self.set == 'Joker' then
                    G.jokers.config.card_limit = G.jokers.config.card_limit + options.config.values[k]
                end
            end
        end
    end

    if self.edition and not silent then
        G.CONTROLLER.locks.edition = true
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = not immediate and 0.2 or 0,
            blockable = not immediate,
            func = function()
                self:juice_up(1, 0.5)
                if self.edition then 
                    play_sound(options.sound.sound, options.sound.per, options.sound.vol)
                end
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                G.CONTROLLER.locks.edition = false
                return true
            end
        }))
    end

    self:set_cost()

end


-- _key = key value for random seed
-- _mod = scale of chance against base card (does not change guaranteed weights)
-- _no_neg = boolean value to disable negative edition
-- _guaranteed = boolean value to determine whether an edition is guaranteed
-- _options = list of key values of editions to include in the poll
function poll_edition(_key, _mod, _no_neg, _guaranteed, _options)
    local _modifier = 1
    local edition_rate = 1
    local edition_poll = pseudorandom(pseudoseed(_key or 'edition_generic'))

    -- Populate available editions for random selection
    local available_editions = {}
    if _options then
        available_editions = _options
    elseif _key == "wheel_of_fortune" or _key == "aura" then -- set base game edition polling
        available_editions = {'polychrome', 'holo', 'foil'}
    else
        available_editions = SMODS.Edition_List
    end

    -- Calculate total weight
    local total_weight = 0
    for _,v in ipairs(available_editions) do
        if not (v == 'negative' and _no_neg) then
            total_weight = total_weight + (v.weight or SMODS.Editions[v].weight)
        end
    end
    
    -- If not guaranteed (base game shop and packs) add base card weight to total weight
    if not _guaranteed then
        edition_rate = G.GAME.edition_rate
        _modifier = _mod or 1
        total_weight = total_weight*edition_rate*_modifier + base_weight
    end
    -- sendDebugMessage("Total weight: "..total_weight, "EditionAPI")
    -- sendDebugMessage("Editions: "..#available_editions, "EditionAPI")
    -- sendDebugMessage("Poll: "..edition_poll, "EditionAPI")
    
    -- Calculate whether edition is selected
    local weight_i = 0
    for _,v in ipairs(available_editions) do
        if not (v == 'negative' and _no_neg) then
            weight_i = weight_i + (v.weight or SMODS.Editions[v].weight)*edition_rate*_modifier
            -- sendDebugMessage("Checking for "..v.name.." at "..(1 - (weight_i)/total_weight), "EditionAPI")
            if edition_poll > 1 - (weight_i)/total_weight*edition_rate*_modifier then
                -- sendDebugMessage("Matched edition: "..v.name, "EditionAPI")
                return {[(v.name or v)] = true}
            end
        end
    end
    return nil
end

function SMODS.Edition:get_editionless_jokers(eligible_editionless_jokers)
    for k, v in pairs(G.jokers.cards) do
        if v.ability.set == 'Joker' and (not v.edition) then
            table.insert(eligible_editionless_jokers, v)
        end
    end
    return eligible_editionless_jokers
end

function SMODS.Edition:get_edition_jokers(eligible_edition_jokers)
    for k, v in pairs(G.jokers.cards) do
        if v.ability.set == 'Joker' and v.edition then
            table.insert(eligible_edition_jokers, v)
        end
    end
    return eligible_edition_jokers
end


function SMODS.Edition:set_weight(value)
    self.weight = value
    for k,v in pairs(base_editions) do
        if v.name == self.key:sub(3) then
            v.weight = value
            break
        end
    end
end

function SMODS.Edition:set_base_weight(value)
    base_weight = value
end

function SMODS.Edition:set_modifier(label, value)
    for k, v in ipairs(self.config.labels) do
        if v == label then
            self.config.values[k] = value
        end
    end
end

function SMODS.Edition:change_modifier(label, value)
    for k, v in ipairs(self.config.labels) do
        if v == label then
            self.config.values[k] = self.config.values[k] + value
            
        end
    end
end
    
function populate_base_edition(options)
    SMODS.Editions[options.key:sub(3)] = options
    local minId = #G.P_CENTER_POOLS['Edition'] + 1
    local id = 0
    local i = 0
    i = i + 1

    id = i + minId
    local edition_obj = {
        discovered = options.discovered,
        unlocked = options.unlocked,
        name = options.name,
        set = "Edition",
        custom = false,
        pos = {
            x = 0,
            y = 0
        },
        atlas = 'Joker',
        order = id,
        key = options.key,
        config = options.config or {
            chips = 0,
            mult = 0,
            x_mult = 1
        },
        unlock_condition = options.unlock_condition,
        shader = options.shader,
        apply_to_float = options.apply_to_float,
        mod_name = options.mod_name,
        sound = options.sound,
        badge_colour = options.badge_colour,
        extra_cost = options.extra_cost,
        weight = options.weight
    }

    -- Populate pools
    G.P_CENTERS[options.key] = edition_obj
    -- if options.name == "Negative" then
    --     G.P_CENTERS['e_negative_consumable'] = edition_obj
    -- end
    table.insert(G.P_CENTER_POOLS['Edition'], edition_obj)

    if options.in_shop then
        table.insert(SMODS.Edition_List, options.key:sub(3))
    end

    -- Setup Localize text
    function SMODS.current_mod.process_loc_text()
        G.localization.descriptions['Edition'][options.key] = options.loc_txt
        G.localization.misc.labels[options.key:sub(3)] = options.name
    end

    sendInfoMessage("Registered " .. options.name .. " with the key " .. options.key .. " at ID " .. id .. ".",
        "EditionAPI")
end

E_ROWS = 2
E_COLS = 5
base_weight = 960
base_editions = {
    { name = 'negative', weight = 3 },
    { name = 'polychrome', weight = 3 },
    { name = 'holo', weight = 14 },
    { name = 'foil', weight = 20 }
}
base_editions_no_neg = {
    { name = 'polychrome', weight = 3 },
    { name = 'holo', weight = 14 },
    { name = 'foil', weight = 20 }
}
sendInfoMessage("Size of Center Pools Edition: "..#G.P_CENTER_POOLS["Edition"], "EditionAPI")
local base = G.P_CENTER_POOLS["Edition"][1]
base.config = {labels = {}, values = {}}
G.P_CENTER_POOLS["Edition"] = {}
table.insert(G.P_CENTER_POOLS["Edition"], base)
for _,v in ipairs(base_game_edition_configs) do
    populate_base_edition(SMODS.Edition:new(v))
end
sendInfoMessage("Size of Center Pools Edition: "..#G.P_CENTER_POOLS["Edition"], "EditionAPI")

function SMODS.current_mod.process_loc_text()
    G.localization.misc.v_dictionary['p_dollars'] = '+$#1#'
end

sendInfoMessage("Loaded!", 'EditionAPI')





----------------------------------------------
------------MOD CODE END----------------------