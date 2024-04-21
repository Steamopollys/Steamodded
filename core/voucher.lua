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
    o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
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
        boot_print_stage("Injecting Voucher: "..slug)
        voucher = SMODS.Vouchers[slug]
        if voucher.order then
            id = voucher.order
        else
            i = i + 1
            id = i + minId
        end
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
            mod_name = voucher.mod_name,
            badge_colour = voucher.badge_colour
        }

        for _i, sprite in ipairs(SMODS.Sprites) do
            if sprite.name == voucher_obj.key then
                voucher_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[voucher.slug] = voucher_obj
        if voucher.taken_ownership then
            for k, v in ipairs(G.P_CENTER_POOLS['Voucher']) do
                if v.key == slug then G.P_CENTER_POOLS['Voucher'][k] = voucher_obj end
            end
        else
            table.insert(G.P_CENTER_POOLS['Voucher'], voucher_obj)
        end
        

        -- Setup Localize text
        G.localization.descriptions["Voucher"][voucher.slug] = voucher.loc_txt

        sendInfoMessage("Registered Voucher " .. voucher.name .. " with the slug " .. voucher.slug .. " at ID " .. id .. ".", 'VoucherAPI')
    end
end

function SMODS.Voucher:take_ownership(slug)
    if not (string.sub(slug, 1, 2) == 'v_') then slug = 'v_' .. slug end
    local obj = G.P_CENTERS[slug]
    if not obj then
        sendWarnMessage('Tried to take ownership of non-existent Voucher: ' .. slug, 'ConsumableAPI')
        return nil
    end
    if obj.mod_name then
        sendWarnMessage('Can only take ownership of unclaimed vanilla Vouchers! ' ..
            slug .. ' belongs to ' .. obj.mod_name, 'ConsumableAPI')
        return nil
    end
    o = {}
    setmetatable(o, self)
    self.__index = self
    o.loc_txt = G.localization.descriptions['Voucher'][slug]
    o.slug = slug
    for k, v in pairs(obj) do
        o[k] = v
    end
	o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
	o.taken_ownership = true
	return o
end

local Card_apply_to_run_ref = Card.apply_to_run
function Card:apply_to_run(center)
    local center_table = {
        name = center and center.name or self and self.ability.name,
        extra = center and center.config.extra or self and self.ability.extra
    }
    local key = center and center.key or self and self.config.center.key
    local voucher_obj = SMODS.Vouchers[key]
    if voucher_obj and voucher_obj.redeem and type(voucher_obj.redeem) == 'function' then
        voucher_obj.redeem(center_table)
    end
    Card_apply_to_run_ref(self, center)
end