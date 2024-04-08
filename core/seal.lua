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
    if not SMODS.Seals[self.label] then
        SMODS.Seals[self.label] = self
        SMODS.BUFFERS.Seals[#SMODS.BUFFERS.Seals+1] = self.label
    end
end

function SMODS.injectSeals()
    local seal = nil
    for _, label in ipairs(SMODS.BUFFERS.Seals) do
        seal = SMODS.Seals[label]
        local seal_obj = {
            discovered = seal.discovered,
            set = "Seal",
            order = #G.P_CENTER_POOLS.Seal + 1,
            key = seal.name
        }

        G.shared_seals[seal.name] = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[seal.atlas], seal.pos)

        -- Now we replace the others
        G.P_SEALS[seal.name] = seal_obj
        table.insert(G.P_CENTER_POOLS.Seal, seal_obj)

        -- Setup Localize text
        G.localization.descriptions.Other[seal.label] = seal.loc_txt
        G.localization.misc.labels[seal.label] = seal.full_name

        sendInfoMessage("Registered Seal " .. seal.name .. " at ID " .. #G.P_CENTER_POOLS.Seal .. ".", 'SealAPI')
    end
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