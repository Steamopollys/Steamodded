--- STEAMODDED HEADER
--- MOD_NAME: Royal Flush
--- MOD_ID: RoyalFlush
--- MOD_AUTHOR: [MathIsFun_]
--- MOD_DESCRIPTION: Adds Royal Flush to demonstrated Steamodded Poker Hand API
--- BADGE_COLOUR: A67C00
--- PREFIX: ex_royal_flush
--- DEPENDENCIES: [Steamodded>=1.0.0-ALPHA-0710a]

SMODS.PokerHand {
    key = 'Royal Flush',
    above_hand = 'Straight Flush',
    chips = 110,
    mult = 9,
    l_chips = 40,
    l_mult = 4,
    example = {
        { 'S_A',    true },
        { 'S_K',    true },
        { 'S_Q',    true },
        { 'S_J',    true },
        { 'S_T',    true },
    },
    loc_txt = {
        ['en-us'] = {
            name = 'Royal Flush',
            description = {
                '5 cards in a row (consecutive ranks) with',
                'all cards sharing the same suit',
                'made of only Aces, tens, and face cards'
            }
        }
    },
    composite = function(parts)
        local ret = {}
        if next(parts._flush) and next(parts._straight) then
            local _s, _f = parts._straight, parts._flush
            for _, v in ipairs(_f[1]) do
              ret[#ret+1] = v
            end
            for _, v in ipairs(_s[1]) do
              local in_straight = nil
              for _, vv in ipairs(_f[1]) do
                if vv == v then in_straight = true end
              end
              if not in_straight then ret[#ret+1] = v end
            end
        end
        if #ret > 0 then
            local royal = true
            for j = 1, #ret do
                local rank = SMODS.Ranks[ret[j].base.value]
                royal = royal and (rank.key == 'Ace' or rank.key == '10' or rank.face)
            end
            if not royal then return {} end
        end
        return {ret}
    end
}

SMODS.Atlas { key = 'vulcan', path = 'vulcan.png', px = 71, py = 95 }

SMODS.Consumable {
    set = 'Planet',
    key = 'vulcan',
    config = { hand_type = 'h_ex_royal_flush_Royal Flush' },
    pos = {x = 0, y = 0 },
    atlas = 'vulcan',
    set_card_type_badge = function(self, card, badges)
        badges[1] = create_badge(localize('k_planet_q'), get_type_colour(self or card.config, card), nil, 1.2)
    end,
    process_loc_text = function(self)
        --use another planet's loc txt instead
        local target_text = G.localization.descriptions[self.set]['c_mercury'].text
        SMODS.Consumable.process_loc_text(self)
        G.localization.descriptions[self.set][self.key].text = target_text
    end,
    generate_ui = 0,
    loc_txt = {
        ['en-us'] = {
            name = 'Vulcan'
        }
    }
}

----------------------------------------------
------------MOD CODE -------------------------