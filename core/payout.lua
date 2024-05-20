-- ----------------------------------------------
-- ------------MOD CORE API PAYOUT----------------

SMODS.Payout_Args = {}
SMODS.Payout_Arg = {
    name = "",
    key = "",
    config = {},
    above_dot_bar = false,
    symbol_config = {character = '$', color = G.C.MONEY, needs_localize = true},
    custom_message_config = {message = nil, color = nil, scale = nil},
}

function SMODS.Payout_Arg:new(payout_config)
    o = payout_config
    setmetatable(o, self)
    self.__index = self

    o.name = payout_config.name
    o.key = 'p_'..payout_config.key
    o.config = payout_config.config or {}
    o.above_dot_bar = payout_config.above_dot_bar or false
    o.symbol_config = payout_config.symbol_config or {character = '$', color = G.C.MONEY, needs_localize = true, scale = 0.58}
    o.custom_message_config = payout_config.custom_message_config or {message = nil, color = nil, scale = nil}
    return o
end

function SMODS.Payout_Arg:register()
    if not SMODS.Payout_Args[self.key] then
        SMODS.Payout_Args[self.key] = self
        SMODS.BUFFERS.Payout_Args[#SMODS.BUFFERS.Payout_Args + 1] = self.key
    end
end

--[[function SMODS.Payout_Args.p_payout_arg_name.payout(self, pitch)
    if condition_is_met then
        return self.config.money_gained
    end
end]]
--[[function SMODS.Payout_Args.p_payout_arg_name.table_left_text(payout_arg, config, left_text, scale)
    table.insert(left_text, {n=G.UIT.O, config={object = DynaText({string = payout_arg.name, colours = {G.C.FILTER}, shadow = true, pop_in = 0, scale = 0.6*scale, silent = true})}})
end]]

-- ----------------------------------------------
-- ------------MOD CORE API PAYOUT END------------
