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

        sendDebugMessage("The Seal named " ..
        seal.name .. " have been registered at the id " .. #G.P_CENTER_POOLS.Seal .. ".")
    end
    SMODS.BUFFERS.Seals = {}
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

-- Orginally from @axbolduc
-- Add the seal to be randomly generated in standard packs
-- This is bad because we have to reimplement the seal generation logic for standard packs
-- for my seal to be randomly generated. Because of how the logic is implemented in the base
-- game we cannot call the base function or else we'll end up with twice the amount of cards in the pack.
-- This means that any other mod that touches the standard pack may be wiped out
local card_open_ref = Card.open
function Card:open()
    if self.ability.set == "Booster" and not self.ability.name:find('Standard') then
        return card_open_ref(self)
    else
        stop_use()
        G.STATE_COMPLETE = false
        self.opening = true

        if not self.config.center.discovered then
            discover_card(self.config.center)
        end
        self.states.hover.can = false
        G.STATE = G.STATES.STANDARD_PACK
        G.GAME.pack_size = self.ability.extra

        G.GAME.pack_choices = self.config.center.config.choose or 1

        if self.cost > 0 then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    inc_career_stat('c_shop_dollars_spent', self.cost)
                    self:juice_up()
                    return true
                end
            }))
            ease_dollars(-self.cost)
        else
            delay(0.2)
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                self:explode()
                local pack_cards = {}

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        local _size = self.ability.extra

                        for i = 1, _size do
                            local card = nil
                            card = create_card(
                                (pseudorandom(pseudoseed('stdset' .. G.GAME.round_resets.ante)) > 0.6) and
                                "Enhanced" or
                                "Base", G.pack_cards, nil, nil, nil, true, nil, 'sta')
                            local edition_rate = 2
                            local edition = poll_edition('standard_edition' .. G.GAME.round_resets.ante,
                                edition_rate,
                                true)
                            card:set_edition(edition)
                            local seal_rate = 10
                            local seal_poll = pseudorandom(pseudoseed('stdseal' .. G.GAME.round_resets.ante))
                            if seal_poll > 1 - 0.02 * seal_rate then
                                -- This is basically the only code that is changed
                                local seal_type = pseudorandom(
                                    pseudoseed('stdsealtype' .. G.GAME.round_resets.ante),
                                    1,
                                    #G.P_CENTER_POOLS['Seal']
                                )

                                local sealName
                                for k, v in pairs(G.P_SEALS) do
                                    if v.order == seal_type then sealName = k end
                                end

                                if sealName == nil then sendDebugMessage("SEAL NAME IS NIL") end

                                card:set_seal(sealName)
                                -- End changed code
                            end
                            card.T.x = self.T.x
                            card.T.y = self.T.y
                            card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 1.5 * G.SETTINGS.GAMESPEED)
                            pack_cards[i] = card
                        end
                        return true
                    end
                }))

                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 1.3 * math.sqrt(G.SETTINGS.GAMESPEED),
                    blockable = false,
                    blocking = false,
                    func = function()
                        if G.pack_cards then
                            if G.pack_cards and G.pack_cards.VT.y < G.ROOM.T.h then
                                for k, v in ipairs(pack_cards) do
                                    G.pack_cards:emplace(v)
                                end
                                return true
                            end
                        end
                    end
                }))

                for i = 1, #G.jokers.cards do
                    G.jokers.cards[i]:calculate_joker({ open_booster = true, card = self })
                end

                if G.GAME.modifiers.inflation then
                    G.GAME.inflation = G.GAME.inflation + 1
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            for k, v in pairs(G.I.CARD) do
                                if v.set_cost then v:set_cost() end
                            end
                            return true
                        end
                    }))
                end

                return true
            end
        }))
    end
end


