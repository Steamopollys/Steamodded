SMODS.Planets = {}
SMODS.Planet = {
    name = "",
    slug = "",
    cost = 3,
    config = {},
    pos = {},
    loc_txt = {},
    discovered = false,
    consumeable = true,
    effect = "Hand Upgrade",
    freq = 1,
    cost_mult = 1.0
}

function SMODS.Planet:new(name, slug, config, pos, loc_txt, cost, cost_mult, effect, freq, consumeable, discovered, atlas)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt or {
        name = name,
        text = {
            [1] = '{S:0.8}({S:0.8,V:1}lvl.#1#{S:0.8}){} Level up',
            [2] = '{C:attention}#2#',
            [3] = '{C:mult}+#3#{} Mult and',
            [4] = '{C:chips}+#4#{} chips',
        }
    }
    o.name = name
    o.slug = "c_" .. slug
    o.config = config or {}
    o.pos = pos or {
        x = 0,
        y = 0
    }
    o.cost = cost
    o.unlocked = true
    o.discovered = discovered or false
    o.consumeable = consumeable or true
    o.effect = effect or "Hand Upgrade"
    o.freq = freq or 1
    o.cost_mult = cost_mult or 1.0
    o.atlas = atlas
    o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
    return o
end

function SMODS.Planet:register()
    if not SMODS.Planets[self.slug] then
        SMODS.Planets[self.slug] = self
        SMODS.BUFFERS.Planets[#SMODS.BUFFERS.Planets + 1] = self.slug
    end
end

function SMODS.injectPlanets()
    local minId = table_length(G.P_CENTER_POOLS['Planet']) + 1
    local id = 0
    local i = 0
    local planet = nil
    for _, slug in ipairs(SMODS.BUFFERS.Planets) do
        planet = SMODS.Planets[slug]
        i = i + 1
        id = i + minId

        local planet_obj = {
            unlocked = planet.unlocked,
            discovered = planet.discovered,
            consumeable = planet.consumeable,
            name = planet.name,
            set = "Planet",
            order = id,
            key = planet.slug,
            pos = planet.pos,
            cost = planet.cost,
            config = planet.config,
            effect = planet.effect,
            cost_mult = planet.cost_mult,
            freq = planet.freq,
            atlas = planet.atlas,
            mod_name = planet.mod_name,
            badge_colour = planet.badge_colour
        }

        for _i, sprite in ipairs(SMODS.Sprites) do
            if sprite.name == planet_obj.key then
                planet_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[planet.slug] = planet_obj
        table.insert(G.P_CENTER_POOLS['Planet'], planet_obj)

        -- Setup Localize text
        G.localization.descriptions["Planet"][planet.slug] = planet.loc_txt

        sendDebugMessage("The Planet named " .. planet.name .. " with the slug " .. planet.slug ..
            " have been registered at the id " .. id .. ".")
    end
end

function create_UIBox_your_collection_planets()
    local deck_tables = {}

    G.your_collection = {}
    for j = 1, 2 do
        G.your_collection[j] = CardArea(
            G.ROOM.T.x + 0.2 * G.ROOM.T.w / 2, G.ROOM.T.h,
            (3.25 + j) * G.CARD_W,
            1 * G.CARD_H,
            { card_limit = j + 3, type = 'title', highlight_limit = 0, collection = true })
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

    for j = 1, #G.your_collection do
        for i = 1, 3 do
            local center = G.P_CENTER_POOLS["Planet"][i + (j - 1) * (3)]
            sendDebugMessage(tostring(i + (j - 1) * (4)))
            sendDebugMessage(inspect(center))
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y, G
                .CARD_W,
                G.CARD_H, nil, center)
            card:start_materialize(nil, i > 1 or j > 1)
            G.your_collection[j]:emplace(card)
        end
    end

    local tarot_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Planet / 6) do
        table.insert(tarot_options,
            localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#G.P_CENTER_POOLS.Planet / 6)))
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
                        options = tarot_options,
                        w = 4.5,
                        cycle_shoulders = true,
                        opt_callback =
                        'your_collection_planet_page',
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
end

G.FUNCS.your_collection_planet_page = function(args)
    if not args or not args.cycle_config then return end
    for j = 1, #G.your_collection do
        for i = #G.your_collection[j].cards, 1, -1 do
            local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
            c:remove()
            c = nil
        end
    end

    for j = 1, #G.your_collection do
        for i = 1, 3 do
            local center = G.P_CENTER_POOLS["Planet"][i + (j - 1) * (3) + (6 * (args.cycle_config.current_option - 1))]
            if not center then break end
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y, G
                .CARD_W, G.CARD_H, G.P_CARDS.empty, center)
            card:start_materialize(nil, i > 1 or j > 1)
            G.your_collection[j]:emplace(card)
        end
    end
    INIT_COLLECTION_CARD_ALERTS()
end
