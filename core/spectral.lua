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

function SMODS.Spectral:new(name, slug, config, pos, loc_txt, cost, consumeable, discovered)
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
    o.consumeable = consumeable or true
	return o
end

function SMODS.Spectral:register()
	SMODS.Spectrals[self.slug] = self

	local minId = table_length(G.P_CENTER_POOLS['Spectral']) + 1
    local id = 0
    local i = 0
	i = i + 1
	-- Prepare some Datas
	id = i + minId

	local tarot_obj = {
		discovered = self.discovered,
		consumeable = self.consumeable,
		name = self.name,
		set = "Spectral",
		order = id,
		key = self.slug,
		pos = self.pos,
		config = self.config
	}

	for _i, sprite in ipairs(SMODS.Sprites) do
		sendDebugMessage(sprite.name)
		sendDebugMessage(tarot_obj.key)
		if sprite.name == tarot_obj.key then
			tarot_obj.atlas = sprite.name
		end
	end

	-- Now we replace the others
	G.P_CENTERS[self.slug] = tarot_obj
	table.insert(G.P_CENTER_POOLS['Spectral'], tarot_obj)

	-- Setup Localize text
	G.localization.descriptions["Spectral"][self.slug] = self.loc_txt

	-- Load it
	for g_k, group in pairs(G.localization) do
		if g_k == 'descriptions' then
			for _, set in pairs(group) do
				for _, center in pairs(set) do
					center.text_parsed = {}
					for _, line in ipairs(center.text) do
						center.text_parsed[#center.text_parsed + 1] = loc_parse_string(line)
					end
					center.name_parsed = {}
					for _, line in ipairs(type(center.name) == 'table' and center.name or {center.name}) do
						center.name_parsed[#center.name_parsed + 1] = loc_parse_string(line)
					end
					if center.unlock then
						center.unlock_parsed = {}
						for _, line in ipairs(center.unlock) do
							center.unlock_parsed[#center.unlock_parsed + 1] = loc_parse_string(line)
						end
					end
				end
			end
		end
	end

	sendDebugMessage("The Spectral named " .. self.name .. " with the slug " .. self.slug ..
						 " have been registered at the id " .. id .. ".")
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
