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

function SMODS.Voucher:new(name, slug, config, pos, loc_txt, cost, unlocked, discovered, available, requires,
    atlas)
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
	o.requires = requires
    o.atlas = atlas
	return o
end

function SMODS.Voucher:register()
    if not SMODS.Vouchers[self.slug] then
        SMODS.Vouchers[self.slug] = self
        SMODS.BUFFERS.Vouchers[#SMODS.BUFFERS.Vouchers + 1] = self.slug
    end
end

function SMODS.injectVouchers()
    local minId = table_length(G.P_CENTER_POOLS['Voucher']) + 1
    local id = 0
    local i = 0
    local voucher = nil
    for _, slug in ipairs(SMODS.BUFFERS.Vouchers) do
        i = i + 1
        id = i + minId
        voucher = SMODS.Vouchers[slug]
        local voucher_obj = {
            discovered = voucher.discovered,
            available = voucher.available,
            name = voucher.name,
            set = "Voucher",
            unlocked = voucher.unlocked,
            order = id,
            key = voucher.slug,
            pos = voucher.pos,
            config = voucher.config,
            cost = voucher.cost,
            atlas = voucher.atlas,
            requires = voucher.requires,
        }

        for _i, sprite in ipairs(SMODS.Sprites) do
            sendDebugMessage(sprite.name)
            sendDebugMessage(voucher_obj.key)
            if sprite.name == voucher_obj.key then
                voucher_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[voucher.slug] = voucher_obj
        table.insert(G.P_CENTER_POOLS['Voucher'], voucher_obj)

        -- Setup Localize text
        G.localization.descriptions["Voucher"][voucher.slug] = voucher.loc_txt

        sendDebugMessage("The Voucher named " .. voucher.name .. " with the slug " .. voucher.slug ..
            " have been registered at the id " .. id .. ".")
    end
    SMODS.BUFFERS.Vouchers = {}
end

local Card_apply_to_run_ref = Card.apply_to_run
function Card:apply_to_run(center)
    local center_table = {
        name = center and center.name or self and self.ability.name,
        extra = center and center.config.extra or self and self.ability.extra
    }
    for _, v in pairs(SMODS.Vouchers) do
        if v.redeem and type(v.redeem) == 'function' then
            v:redeem(center_table)
        end
    end
    Card_apply_to_run_ref(self, center)
end