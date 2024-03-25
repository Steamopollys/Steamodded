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
                         eternal_compat, effect, atlas)
    o = {}
    setmetatable(o, self)
    self.__index = self

    o.loc_txt = loc_txt
    o.name = name
    o.slug = "j_" .. slug
    o.config = config or {}
    o.spritePos = spritePos or {
        x = 0,
        y = 0
    }
    o.rarity = rarity or 1
    o.cost = cost
    o.unlocked = (unlocked == nil) and true or unlocked
    o.discovered = (discovered == nil) and true or discovered
    o.blueprint_compat = blueprint_compat or false
    o.eternal_compat = (eternal_compat == nil) and true or eternal_compat
    o.effect = effect or ''
    o.atlas = atlas or nil
    return o
end

function SMODS.Joker:register()
    if not SMODS.Jokers[self.slug] then
        SMODS.Jokers[self.slug] = self
    end
end

function SMODS.injectJokers()
    local minId = table_length(G.P_CENTER_POOLS['Joker']) + 1
    local id = 0
    local i = 0

    for k, joker in pairs(SMODS.Jokers) do
        i = i + 1
        -- Prepare some Datas
        id = i + minId

        local joker_obj = {
            discovered = joker.discovered,
            name = joker.name,
            set = "Joker",
            unlocked = joker.unlocked,
            order = id,
            key = joker.slug,
            pos = joker.spritePos,
            config = joker.config,
            rarity = joker.rarity,
            blueprint_compat = joker.blueprint_compat,
            eternal_compat = joker.eternal_compat,
            effect = joker.effect,
            cost = joker.cost,
            cost_mult = 1.0,
            atlas = joker.atlas or nil
        }

        for _i, sprite in ipairs(SMODS.Sprites) do
            sendDebugMessage(sprite.name)
            sendDebugMessage(joker_obj.key)
            if sprite.name == joker_obj.key then
                joker_obj.atlas = sprite.name
            end
        end

        -- Now we replace the others
        G.P_CENTERS[joker.slug] = joker_obj
        table.insert(G.P_CENTER_POOLS['Joker'], joker_obj)
        table.insert(G.P_JOKER_RARITY_POOLS[joker_obj.rarity], joker_obj)

        -- Setup Localize text
        G.localization.descriptions["Joker"][k] = joker.loc_txt

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

        sendDebugMessage("The Joker named " .. joker.name .. " with the slug " .. joker.slug ..
            " have been registered at the id " .. id .. ".")
    end
    SMODS.SAVE_UNLOCKS()
end

local carfset_abilityRef = Card.set_ability
function Card.set_ability(self, center, initial, delay_sprites)
    carfset_abilityRef(self, center, initial, delay_sprites)

    -- Iterate over each object in SMODS.JKR_EFFECT
    for _k, obj in pairs(SMODS.Jokers) do
        --! CHANGED from effect due to overlap
        -- Check if the object's name matches self.ability.name and if it has an ability function
        if obj.name == self.ability.name and type(obj.set_ability) == "function" then
            obj.set_ability(self, center, initial, delay_sprites)
        end
    end
end

local calculate_jokerref = Card.calculate_joker;
function Card:calculate_joker(context)
    local ret_val = calculate_jokerref(self, context);

    if self.ability.set == "Joker" and not self.debuff then
        for _k, obj in pairs(SMODS.Jokers) do
            -- Check if the object's name matches self.ability.name and if it has a calculate function
            if obj.name == self.ability.name and type(obj.calculate) == "function" then
                local o = obj.calculate(self, context)
                if o then return o end
            end
        end
    end

    return ret_val;
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
        for _, v in pairs(SMODS.Jokers) do
            if v.loc_def and type(v.loc_def) == 'function' then
                loc_vars = v:loc_def(self) or loc_vars
            end
        end
    end
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

          if self.sticker then
              loc_vars = loc_vars or {};
              loc_vars.sticker = self.sticker
          end

          local center = self.config.center
          return generate_card_ui(center, nil, loc_vars, card_type, badges, hide_desc, main_start, main_end)
    end
    return ability_table_ref(self)
end
--[[
    function SMODS.Joker.j_example:loc_def(card)
        if card.ability.name == 'Example Joker' then
            return {card.ability.extra.mult}
        end
    end
]]

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
