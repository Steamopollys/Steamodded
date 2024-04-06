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
    o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
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
        spectral = SMODS.Spectrals[slug]
        if spectral.order then
            id = spectral.order
        else
            i = i + 1
            id = i + minId
        end
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
            cost = spectral.cost,
            mod_name = spectral.mod_name,
            badge_colour = spectral.badge_colour,
            -- * currently unsupported
            hidden = spectral.hidden
        }

        for _i, sprite in ipairs(SMODS.Sprites) do
            if sprite.name == tarot_obj.key then
                tarot_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[slug] = tarot_obj
        if not spectral.taken_ownership then
			table.insert(G.P_CENTER_POOLS['Spectral'], tarot_obj)
		else
			for k, v in ipairs(G.P_CENTER_POOLS['Spectral']) do
				if v.key == slug then G.P_CENTER_POOLS['Spectral'][k] = tarot_obj end
			end
		end

        -- Setup Localize text
        G.localization.descriptions["Spectral"][spectral.slug] = spectral.loc_txt

        sendInfoMessage("Registered Spectral " .. spectral.name .. " with the slug " .. spectral.slug .. " at ID " .. id .. ".", 'ConsumableAPI')
    end
end

function SMODS.Spectral:take_ownership(slug)
    if not (string.sub(slug, 1, 2) == 'c_') then slug = 'c_' .. slug end
    local obj = G.P_CENTERS[slug]
    if not obj then
        sendWarnMessage('Tried to take ownership of non-existent Spectral: ' .. slug, 'ConsumableAPI')
        return nil
    end
    if obj.mod_name then
        sendWarnMessage('Can only take ownership of unclaimed vanilla Spectrals! ' ..
            slug .. ' belongs to ' .. obj.mod_name, 'ConsumableAPI')
        return nil
    end
    o = {}
    setmetatable(o, self)
    self.__index = self
    o.loc_txt = G.localization.descriptions['Spectral'][slug]
    o.slug = slug
    for k, v in pairs(obj) do
        o[k] = v
    end
	o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
	o.taken_ownership = true
	return o
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
