SMODS.Seals = {}
SMODS.Seal = {
  	name = "",
  	pos = {},
	loc_txt = {},
	discovered = false,
	atlas = "centers",
	label = "",
	full_name = "",
	color = HEX("FFFFFF")
}

function SMODS.Seal:new(name, label, full_name, pos, loc_txt, atlas, discovered, color)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt
    o.name = name
	o.label = label
	o.full_name = full_name
    o.pos = pos or {
        x = 0,
        y = 0
    }
    o.discovered = discovered or false
    o.atlas = atlas or "centers"
	o.color = color or HEX("FFFFFF")
	return o
end

function SMODS.Seal:register()
	SMODS.Seals[self.label] = self

	local seal_obj = {
		discovered = self.discovered,
		set = "Seal",
		order = #G.P_CENTER_POOLS.Seal + 1,
		key = self.name
	}

	G.shared_seals[self.name] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[self.atlas], self.pos)

	-- Now we replace the others
	G.P_SEALS[self.name] = seal_obj
	table.insert(G.P_CENTER_POOLS.Seal, seal_obj)

	-- Setup Localize text
	G.localization.descriptions.Other[self.label] = self.loc_txt
	G.localization.misc.labels[self.label] = self.full_name

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
                    for _, line in ipairs(type(center.name) == 'table' and center.name or { center.name }) do
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

	sendDebugMessage("The Seal named " .. self.name .. " have been registered at the id " .. #G.P_CENTER_POOLS.Seal .. ".")
end

local get_badge_colourref = get_badge_colour
function get_badge_colour(key)
    local fromRef = get_badge_colourref(key)

	for k, v in pairs(SMODS.Seals) do
		if key == k then
			return v.color
		end
	end
    return fromRef
end

-- UI code for seal
local generate_card_ui_ref = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start, main_end)
    local fromRef = generate_card_ui_ref(_c, full_UI_table, specific_vars, card_type, badges, hide_desc, main_start,
        main_end)

    local info_queue = {}


    if not (_c.set == 'Edition') and badges then
        for k, v in ipairs(badges) do
			for k1, v1 in pairs(SMODS.Seals) do
				if v == k1 then info_queue[#info_queue + 1] = { key = k1, set = 'Other' } end
			end
           
        end
    end

    for _, v in ipairs(info_queue) do
        generate_card_ui(v, fromRef)
    end

    return fromRef
end