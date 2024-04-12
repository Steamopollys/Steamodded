-- ----------------------------------------------
-- ------------MOD CORE API JOKER----------------

SMODS.Jokers = {}
SMODS.Joker = {
    name = "",
    slug = "",
    config = {},
    spritePos = {},
    loc_txt = {},
    rarity = 1,
    cost = 0,
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    effect = ""
}

function SMODS.Joker:new(name, slug, config, spritePos, loc_txt, rarity, cost, unlocked, discovered, blueprint_compat,
                         eternal_compat, effect, atlas, soul_pos)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt
    o.name = name
    o.slug = "j_" .. slug
    o.config = config or {}
    o.pos = spritePos or {
        x = 0,
        y = 0
    }
    o.soul_pos = soul_pos
    o.rarity = rarity or 1
    o.cost = cost
    o.unlocked = (unlocked == nil) and true or unlocked
    o.discovered = (discovered == nil) and true or discovered
    o.blueprint_compat = blueprint_compat or false
    o.eternal_compat = (eternal_compat == nil) and true or eternal_compat
    o.effect = effect or ''
    o.atlas = atlas or nil
    o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
    return o
end

function SMODS.Joker:register()
    if not SMODS.Jokers[self.slug] then
        SMODS.Jokers[self.slug] = self
        SMODS.BUFFERS.Jokers[#SMODS.BUFFERS.Jokers + 1] = self.slug
    end
end

function SMODS.injectJokers()
    local minId = table_length(G.P_CENTER_POOLS['Joker']) + 1
    local id = 0
    local i = 0
    local joker = nil
    for k, slug in ipairs(SMODS.BUFFERS.Jokers) do
        joker = SMODS.Jokers[slug]
        if joker.order then
            id = joker.order
        else
            i = i + 1
            id = i + minId
        end
        local joker_obj = {
            discovered = joker.discovered,
            name = joker.name,
            set = "Joker",
            unlocked = joker.unlocked,
            order = id,
            key = joker.slug,
            pos = joker.pos,
            config = joker.config,
            rarity = joker.rarity,
            blueprint_compat = joker.blueprint_compat,
            eternal_compat = joker.eternal_compat,
            effect = joker.effect,
            cost = joker.cost,
            cost_mult = 1.0,
            atlas = joker.atlas or nil,
            mod_name = joker.mod_name,
            badge_colour = joker.badge_colour,
            soul_pos = joker.soul_pos,
            -- * currently unsupported
            no_pool_flag = joker.no_pool_flag,
            yes_pool_flag = joker.yes_pool_flag,
            unlock_condition = joker.unlock_condition,
            enhancement_gate = joker.enhancement_gate,
            start_alerted = joker.start_alerted
        }
        for _i, sprite in ipairs(SMODS.Sprites) do
            if sprite.name == joker_obj.key then
                joker_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[slug] = joker_obj
        if not joker.taken_ownership then
            table.insert(G.P_CENTER_POOLS['Joker'], joker_obj)
            table.insert(G.P_JOKER_RARITY_POOLS[joker_obj.rarity], joker_obj)
        else
            for kk, v in ipairs(G.P_CENTER_POOLS['Joker']) do
                if v.key == slug then G.P_CENTER_POOLS['Joker'][kk] = joker_obj end
            end
            if joker_obj.rarity == joker.rarity_original then
                for kk, v in ipairs(G.P_JOKER_RARITY_POOLS[joker_obj.rarity]) do
                    if v.key == slug then G.P_JOKER_RARITY_POOLS[kk] = joker_obj end
                end
            else
                table.insert(G.P_JOKER_RARITY_POOLS[joker_obj.rarity], joker_obj)
                local j
                for kk, v in ipairs(G.P_JOKER_RARITY_POOLS[joker.rarity_original]) do
                    if v.key == slug then j = kk end
                end
                table.remove(G.P_JOKER_RARITY_POOLS[joker.rarity_original], j)
            end
        end
        -- Setup Localize text
        G.localization.descriptions["Joker"][slug] = joker.loc_txt

        sendInfoMessage("Registered Joker " .. joker.name .. " with the slug " .. joker.slug .. " at ID " .. id .. ".")
    end
end

function SMODS.Joker:take_ownership(slug)
    if not (string.sub(slug, 1, 2) == 'j_') then slug = 'j_' .. slug end
    local joker = G.P_CENTERS[slug]
    if not joker then
        sendWarnMessage('Tried to take ownership of non-existent Joker: ' .. slug, 'JokerAPI')
        return nil
    end
    if joker.mod_name then
        sendWarnMessage('Can only take ownership of unclaimed vanilla Jokers! ' ..
            slug .. ' belongs to ' .. joker.mod_name, 'JokerAPI')
        return nil
    end
    o = {}
    setmetatable(o, self)
    self.__index = self
    o.loc_txt = G.localization.descriptions['Joker'][slug]
    o.slug = slug
    for k, v in pairs(joker) do
        o[k] = v
    end
    o.rarity_original = o.rarity
    o.mod_name = SMODS._MOD_NAME
    o.badge_colour = SMODS._BADGE_COLOUR
    o.taken_ownership = true
    return o
end

local cardset_abilityRef = Card.set_ability
function Card.set_ability(self, center, initial, delay_sprites)
    cardset_abilityRef(self, center, initial, delay_sprites)
    local key = self.config.center.key
    local joker_obj = SMODS.Jokers[key]
    if joker_obj and joker_obj.set_ability and type(joker_obj.set_ability) == 'function' then
        joker_obj.set_ability(self, center, initial, delay_sprites)
    end
end

local calculate_jokerref = Card.calculate_joker;
function Card:calculate_joker(context)
    for k, v in pairs(SMODS.Stickers) do
        if self.ability[v.label] then
            if v.calculate_joker and type(v.calculate_joker) == 'function' then
                v.calculate_sticker(self, context)
            end
        end
    end
    if not self.debuff then
        local key = self.config.center.key
        local center_obj = SMODS.Jokers[key] or SMODS.Tarots[key] or SMODS.Planets[key] or SMODS.Spectrals[key]
        if center_obj and center_obj.calculate and type(center_obj.calculate) == "function" then
            local o = center_obj.calculate(self, context)
            if o then return o end
        end
    end
    return calculate_jokerref(self, context)
end

local ability_table_ref = Card.generate_UIBox_ability_table
function Card:generate_UIBox_ability_table()
    local card_type, hide_desc = self.ability.set or "None", nil
    local loc_vars = nil
    local main_start, main_end = nil, nil
    local no_badge = nil
    if not self.bypass_lock and self.config.center.unlocked ~= false and
        self.ability.set == 'Joker' and
        not self.config.center.discovered and
        ((self.area ~= G.jokers and self.area ~= G.consumeables and self.area) or not self.area) then
        card_type = 'Undiscovered'
    end

    if self.config.center.unlocked == false and not self.bypass_lock then    -- For everyting that is locked
    elseif card_type == 'Undiscovered' and not self.bypass_discovery_ui then -- Any Joker or tarot/planet/voucher that is not yet discovered
    elseif self.debuff then
    elseif card_type == 'Default' or card_type == 'Enhanced' then
    elseif self.ability.set == 'Joker' then
        local key = self.config.center.key
        local joker_obj = SMODS.Jokers[key]
        if joker_obj and joker_obj.loc_def and type(joker_obj.loc_def) == 'function' then
            local o, m = joker_obj.loc_def(self)
            if o then loc_vars = o end
            if m then main_end = m end
        end
    end
    SMODS.set_card_SMODS_sticker_info(self)
    if loc_vars then
        local badges = {}
        if (card_type ~= 'Locked' and card_type ~= 'Undiscovered' and card_type ~= 'Default') or self.debuff then
            badges.card_type = card_type
        end
        if self.ability.set == 'Joker' and self.bypass_discovery_ui and (not no_badge) then
            badges.force_rarity = true
        end
        if self.edition then
            if self.edition.type == 'negative' and self.ability.consumeable then
                badges[#badges + 1] = 'negative_consumable'
            else
                badges[#badges + 1] = (self.edition.type == 'holo' and 'holographic' or self.edition.type)
            end
        end
        if self.seal then
            badges[#badges + 1] = string.lower(self.seal) .. '_seal'
        end
        if self.ability.eternal then
            badges[#badges + 1] = 'eternal'
        end
        if self.pinned then
            badges[#badges + 1] = 'pinned_left'
        end

        for k, v in pairs(SMODS.Stickers) do
            sendInfoMessage(type(v))
            if self.ability[v] == true then badges[#badges + 1] = v end
        end

        if self.sticker then
            loc_vars = loc_vars or {};
            loc_vars.sticker = self.sticker
        end

        local center = self.config.center
        return generate_card_ui(center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end)
    end
    return ability_table_ref(self)
end

function SMODS.end_calculate_context(c)
    if not c.after and not c.before and not c.other_joker and not c.repetition and not c.individual and
        not c.end_of_round and not c.discard and not c.pre_discard and not c.debuffed_hand and not c.using_consumeable and
        not c.remove_playing_cards and not c.cards_destroyed and not c.destroying_card and not c.setting_blind and
        not c.first_hand_drawn and not c.playing_card_added and not c.skipping_booster and not c.skip_blind and
        not c.ending_shop and not c.reroll_shop and not c.selling_card and not c.selling_self and not c.buying_card and
        not c.open_booster then
        return true
    end
    return false
end

-- ----------------------------------------------
-- ------------MOD CORE API JOKER END------------
