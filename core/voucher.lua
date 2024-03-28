SMODS.Vouchers = {}
SMODS.Voucher = {
  name = "",
  slug = "",
	cost = 10,
	config = {},
  pos = {},
	loc_txt = {},
	discovered = false, 
	unlocked = true, 
	available = true
}

function SMODS.Voucher:new(name, slug, config, pos, loc_txt, cost, unlocked, discovered, available,
    eternal_compat)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt
    o.name = name
    o.slug = "v_" .. slug
    o.config = config or {}
    o.pos = pos or {
        x = 0,
        y = 0
    }
    o.cost = cost
    o.unlocked = unlocked or true
    o.discovered = discovered or false
	o.available = available or true
	return o
end

function SMODS.Voucher:register()
	SMODS.Vouchers[self.slug] = self

	local minId = table_length(G.P_CENTER_POOLS['Voucher']) + 1
    local id = 0
    local i = 0
	i = i + 1
	-- Prepare some Datas
	id = i + minId

	local voucher_obj = {
		discovered = self.discovered,
		available = self.available,
		name = self.name,
		set = "Voucher",
		unlocked = self.unlocked,
		order = id,
		key = self.slug,
		pos = self.pos,
		config = self.config,
		cost = self.cost
	}

	for _i, sprite in ipairs(SMODS.Sprites) do
		sendDebugMessage(sprite.name)
		sendDebugMessage(voucher_obj.key)
		if sprite.name == voucher_obj.key then
			voucher_obj.atlas = sprite.name
		end
	end

	-- Now we replace the others
	G.P_CENTERS[self.slug] = voucher_obj
	table.insert(G.P_CENTER_POOLS['Voucher'], voucher_obj)

	-- Setup Localize text
	G.localization.descriptions["Voucher"][self.slug] = self.loc_txt

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

	sendDebugMessage("The Voucher named " .. self.name .. " with the slug " .. self.slug ..
						 " have been registered at the id " .. id .. ".")
end