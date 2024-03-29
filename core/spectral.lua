SMODS.Spectrals = {}
SMODS.Spectral = {
    name = "",
    slug = "",
    cost = 4,
    config = {},
    pos = {},
    loc_txt = {},
    discovered = false,
    consumeable = true
}

function SMODS.Spectral:new(name, slug, config, pos, loc_txt, cost, consumeable, discovered, atlas)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt
    o.name = name
    o.slug = "c_" .. slug
    o.config = config or {}
    o.pos = pos or {
        x = 0,
        y = 0
    }
    o.cost = cost
    o.discovered = discovered or false
    o.unlocked = true
    o.consumeable = consumeable or true
    o.atlas = atlas
    return o
end

function SMODS.Spectral:register()
    if not SMODS.Spectrals[self.slug] then
        SMODS.Spectrals[self.slug] = self
        SMODS.BUFFERS.Spectrals[#SMODS.BUFFERS.Spectrals + 1] = self.slug
    end
end

function SMODS.injectSpectrals()
    local minId = table_length(G.P_CENTER_POOLS['Spectral']) + 1
    local id = 0
    local i = 0
    local spectral = nil
    for _, slug in ipairs(SMODS.BUFFERS.Spectrals) do
        i = i + 1
        id = i + minId
        spectral = SMODS.Spectrals[slug]
        local tarot_obj = {
            unlocked = spectral.unlocked,
            discovered = spectral.discovered,
            consumeable = spectral.consumeable,
            name = spectral.name,
            set = "Spectral",
            order = id,
            key = spectral.slug,
            pos = spectral.pos,
            config = spectral.config,
            atlas = spectral.atlas,
            cost = spectral.cost
        }

        for _i, sprite in ipairs(SMODS.Sprites) do
            sendDebugMessage(sprite.name, "SteamoddedSpectral")
            sendDebugMessage(tarot_obj.key, "SteamoddedSpectral")
            if sprite.name == tarot_obj.key then
                tarot_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[spectral.slug] = tarot_obj
        table.insert(G.P_CENTER_POOLS['Spectral'], tarot_obj)

        -- Setup Localize text
        G.localization.descriptions["Spectral"][spectral.slug] = spectral.loc_txt

        sendInfoMessage("The Spectral named " .. spectral.name .. " with the slug " .. spectral.slug ..
            " have been registered at the id " .. id .. ".", "SteamoddedSpectral")
    end
    SMODS.BUFFERS.Spectrals = {}
end

function create_UIBox_your_collection_spectrals()
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
        for i = 1, 3 + j do
            local center = G.P_CENTER_POOLS["Spectral"][i + (j - 1) * 3 + j - 1]

            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w / 2, G.your_collection[j].T.y, G
                .CARD_W,
                G.CARD_H, nil, center)
            card:start_materialize(nil, i > 1 or j > 1)
            G.your_collection[j]:emplace(card)
        end
    end

    local spectral_options = {}
    for i = 1, math.ceil(#G.P_CENTER_POOLS.Spectral / 9) do
        table.insert(spectral_options,
            localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#G.P_CENTER_POOLS.Spectral / 9)))
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
                        options = spectral_options,
                        w = 4.5,
                        cycle_shoulders = true,
                        opt_callback =
                        'your_collection_spectral_page',
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
