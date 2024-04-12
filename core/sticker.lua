SMODS.Stickers = {}
SMODS.Sticker = {
	name = "",
	label = "",
	config = {},
	pos = {},
	chance = 0.3,
	atlas = "",
    color = HEX("FFFFFF"),
    sticker_compat = {true, {}, {}},
}
SMODS.Card_Stickers = nil

function SMODS.Sticker:new(name, label, config, pos, chance, atlas, color, default_compat, auto_set_true, auto_set_false)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.name = name
	o.label = label
	o.config = config or {}
	o.pos = pos or {
		x = 0,
		y = 0
	}
	o.chance = chance or 0.3
	o.atlas = atlas or ""
    o.color = color or HEX("FFFFFF")
    o.default_compat = default_compat or true
    o.auto_set_true = auto_set_true or {}
    o.auto_set_false = auto_set_false or {}
	return o
end

--helper function for InjectStickers
function tableContains(table, key)
    if not table then return false end
    for _, value in pairs(table) do
        if value == key then
            return true
        end
    end
    return false
end

function SMODS.injectStickers()
    for _, label in ipairs(SMODS.BUFFERS.Stickers) do
        local sticker = SMODS.Stickers[label]
        for k, v in pairs(G.P_CENTERS) do
            if v.set == "Joker" and not G.P_CENTERS[v.key][sticker.label.."_compat"] then
                if sticker.auto_set_true and tableContains(sticker.auto_set_true, v.key) then
                    G.P_CENTERS[v.key][sticker.label.."_compat"] = true
                elseif sticker.auto_set_false and tableContains(sticker.auto_set_false, v.key) then
                    G.P_CENTERS[v.key][sticker.label.."_compat"] = false
                else
                    G.P_CENTERS[v.key][sticker.label.."_compat"] = sticker.default_compat
                end
            end
        end
    end
end

function SMODS.Sticker:register()
	if not SMODS.Stickers[self.label] then
		SMODS.Stickers[self.label] = self
		SMODS.BUFFERS.Stickers[#SMODS.BUFFERS.Stickers + 1] = self.label
	end
end

local GameStartUp_ref = Game.start_up
function Game:start_up()
    GameStartUp_ref(self)
    for _, label in ipairs(SMODS.BUFFERS.Stickers) do
        local asset_atlas = SMODS.Stickers[label].atlas
        local atlas_pos = SMODS.Stickers[label].pos
        if asset_atlas ~= "" then
            self.shared_stickers[label] = Sprite(0, 0, self.CARD_W, self.CARD_H, self.ASSET_ATLAS[asset_atlas], atlas_pos)
        else
            self.shared_stickers[label] = Sprite(0, 0, self.CARD_W, self.CARD_H, self.ASSET_ATLAS["stickers"], atlas_pos)
        end
    end
end

local create_card_ref = create_card
function create_card(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)
    local card = create_card_ref(_type, area, legendary, _rarity, skip_materialize, soulable, forced_key, key_append)

    if _type == 'Joker' and ((area == G.shop_jokers) or (area == G.pack_cards)) then 
        for k, v in pairs(SMODS.Stickers) do
            if pseudorandom('ssj'..v.label..G.GAME.round_resets.ante) > (1-v.chance) then
                local sticker_obj = SMODS.Stickers[v.label]
                if sticker_obj and sticker_obj.set_sticker and type(sticker_obj.set_sticker) == 'function' then
                    sticker_obj.set_sticker(card, true)
                end
            end
        end
    end
    return card
end

local get_badge_colourref = get_badge_colour
function get_badge_colour(key)
    local fromRef = get_badge_colourref(key)

	for k, v in pairs(SMODS.Stickers) do
		if key == k then
			return v.color
		end
	end
    return fromRef
end

local CardDraw = Card.draw
function Card.draw(self, layer)
    CardDraw(self, layer)
    if self.sprite_facing == 'front' then 
        for k, v in pairs(SMODS.Stickers) do
            if self.ability[v.label] then
                local sticker_obj = SMODS.Stickers[v.label]
                if sticker_obj and sticker_obj.set_shader and type(sticker_obj.set_shader) == 'function' then
                    sticker_obj.set_shader()
                else
                    G.shared_stickers[v.label].role.draw_major = self
                    G.shared_stickers[v.label]:draw_shader('dissolve', nil, nil, nil, self.children.center)
                    G.shared_stickers[v.label]:draw_shader('voucher', nil, self.ARGS.send_to_shader, nil, self.children.center)
                end
            end
        end
    end
end

--Shortcut around generate_UIBox_ability_table function
function SMODS.set_card_SMODS_sticker_info(card)
    local SMODS_sticker_count = nil
    for k, v in pairs(SMODS.Stickers) do
        if card.ability[v.label] then 
            if SMODS_sticker_count == nil then SMODS_sticker_count = {} end
            SMODS_sticker_count[#SMODS_sticker_count+1] = v.label 
        end
    end
    if SMODS_sticker_count ~= nil then 
        SMODS.Card_Stickers = SMODS_sticker_count 
    else 
        SMODS.Card_Stickers = nil
    end
end
