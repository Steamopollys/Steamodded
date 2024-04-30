SMODS.Stickers = {}
SMODS.Sticker = {
	name = "",
	slug = "",
	config = {},
	pos = {},
	chance = 0.3,
	atlas = "",
    color = HEX("FFFFFF"),
    default_compat = true,
    compat_exceptions = {}
}

function SMODS.Sticker:new(name, slug, config, pos, chance, atlas, color, default_compat, compat_exceptions)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.name = name
	o.slug = 'st_'..slug
	o.config = config or {}
	o.pos = pos or {
		x = 0,
		y = 0
	}
	o.chance = chance or 0.3
	o.atlas = atlas or ""
    o.color = color or HEX("FFFFFF")
    o.default_compat = default_compat or true
    o.compat_exceptions = compat_exceptions or {}
	return o
end

function SMODS.injectStickers()
    for _, slug in ipairs(SMODS.BUFFERS.Stickers) do
        local sticker = SMODS.Stickers[slug]
        for k, v in pairs(G.P_CENTERS) do
            if v.set == "Joker" and G.P_CENTERS[v.key][sticker.slug.."_compat"] == nil then
                if sticker.compat_exceptions[v.key] ~= nil then
                    G.P_CENTERS[v.key][sticker.slug.."_compat"] = sticker.compat_exceptions[v.key]
                else
                    G.P_CENTERS[v.key][sticker.slug.."_compat"] = sticker.default_compat
                end
            end
        end
        get_badge_colour("eternal")
        G.BADGE_COL[sticker.slug] = sticker.color
    end
end

function SMODS.Sticker:register()
	if not SMODS.Stickers[self.slug] then
		SMODS.Stickers[self.slug] = self
		SMODS.BUFFERS.Stickers[#SMODS.BUFFERS.Stickers + 1] = self.slug
	end
end
