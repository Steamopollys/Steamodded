local init_game_objectref = Game.init_game_object
function Game:init_game_object()
    local t = init_game_objectref(self)
    for i, hand in pairs(SMODS.PokerHands) do
        t.hands[hand.name] =  {
            visible = hand.visible,
            order = t.hands[hand.after_hand].order + 0.1,
            mult = hand.base_mult,
            chips = hand.base_chips,
            s_mult = hand.base_mult,
            s_chips = hand.base_chips,
            l_mult = hand.levelup_mult,
            l_chips = hand.levelup_chips,
            played = 0, 
            played_this_round = 0,
            example = hand.example,
            level = 1
        }
    end

    return t
end


function compare_hands(a,b)
    return G.GAME.hands[a.after_hand].order + 0.1 < G.GAME.hands[b.after_hand].order + 0.1
end


local evaluate_poker_handref = evaluate_poker_hand
function evaluate_poker_hand(hand)
    local results = evaluate_poker_handref(hand)
    for i, hand in pairs(SMODS.PokerHands) do
        results[hand.name] = {}
    end

    table.sort(SMODS.PokerHands, compare_hands)

    for _, _hand in pairs(SMODS.PokerHands) do
        if _hand.can_play and type(_hand.can_play) == 'function' then
            local actual_hand = _hand.can_play(hand)
			if next(actual_hand) then
                results[_hand.name] = {actual_hand}
                if not results.top then results.top = results[_hand.name] end
            end
		end
    end

    return results
end

function G.FUNCS.get_poker_hand_info(_cards)
    local poker_hands = evaluate_poker_hand(_cards)
    local scoring_hand = {}
    local text, disp_text, loc_disp_text = 'NULL', 'NULL', 'NULL'
    for _, v in ipairs(G.handlist) do
        if next(poker_hands[v]) then
            text = v
            scoring_hand = poker_hands[v][1]
            break
        end
    end
    disp_text = text
    loc_disp_text = localize(disp_text, 'poker_hands')
    return text, loc_disp_text, poker_hands, scoring_hand, disp_text
end

function create_UIBox_current_hands(simple)

    G.current_hands = {}

    local index = 0
    for _, v in ipairs(G.handlist) do
        local ui_element = create_UIBox_current_hand_row(v, simple)
        if index < 10 then
            G.current_hands[index+1] = ui_element
        end

        if ui_element then
            index = index + 1
        end

        if index >= 10 then
            break
        end
    end

    local visible_hands = {}
    for _, v in ipairs(G.handlist) do
        if G.GAME.hands[v].visible then
            table.insert(visible_hands, v)
        end
    end

    local hand_options = {}
    for i = 1, math.ceil(#visible_hands / 10) do
        table.insert(hand_options,
            localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_hands / 10)))
    end

    local object = { 
        n = G.UIT.ROOT,
        config = { align = "cm", colour = G.C.CLEAR },
        nodes = {
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.04 },
                nodes = G.current_hands
            },
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0 },
                nodes = {
                    create_option_cycle({
                        options = hand_options,
                        w = 4.5,
                        cycle_shoulders = true,
                        opt_callback =
                        'your_hands_page',
                        focus_args = { snap_to = true, nav = 'wide' },
                        current_option = 1,
                        colour = G
                            .C.RED,
                        no_pips = true
                    })
                }
            }
        }
    }
    
    

    local t = {
        n = G.UIT.ROOT,
        config = { align = "cm", minw = 3, padding = 0.1, r = 0.1, colour = G.C.CLEAR },
        nodes = {
            { n = G.UIT.O, config = { id = 'hand_list', object = UIBox {
                definition = object,
                config = { offset = { x = 0, y = 0 }, align = 'cm' }
            }}} 
        }
    }



    return t
end


function create_hands_menu(page) 
    
end

G.FUNCS.your_hands_page = function(args)
    if not args or not args.cycle_config then return end
    G.current_hands = {}
    

    local index = 0
    for _, v in ipairs(G.handlist) do
        local ui_element = create_UIBox_current_hand_row(v, simple)
        if index >= (0 + 10 * (args.cycle_config.current_option - 1)) and index < 10 * args.cycle_config.current_option then
            G.current_hands[index - (10 * (args.cycle_config.current_option - 1)) + 1] = ui_element
        end

        if ui_element then
            index = index + 1
        end

        if index >= 10 * args.cycle_config.current_option then
            break
        end
    end

    local visible_hands = {}
    for _, v in ipairs(G.handlist) do
        if G.GAME.hands[v].visible then
            table.insert(visible_hands, v)
        end
    end

    local hand_options = {}
    for i = 1, math.ceil(#visible_hands / 10) do
        table.insert(hand_options,
            localize('k_page') .. ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#visible_hands / 10)))
    end

    local object = { 
        n = G.UIT.ROOT,
        config = { align = "cm", colour = G.C.CLEAR },
        nodes = {
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.04 },
                nodes = G.current_hands
            },
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0 },
                nodes = {
                    create_option_cycle({
                        options = hand_options,
                        w = 4.5,
                        cycle_shoulders = true,
                        opt_callback =
                        'your_hands_page',
                        focus_args = { snap_to = true, nav = 'wide' },
                        current_option = args.cycle_config.current_option,
                        colour = G
                            .C.RED,
                        no_pips = true
                    })
                }
            }
        }
    }

    local hand_list = G.OVERLAY_MENU:get_UIE_by_ID('hand_list')
    if hand_list then
        if hand_list.config.object then
            hand_list.config.object:remove()
        end
        hand_list.config.object = UIBox {
            definition = object,
            config = { offset = { x = 0, y = 0 }, align = 'cm', parent = hand_list }
        }
    end


end



function create_UIBox_hand_tip(handname)
    if not G.GAME.hands[handname].example then return {n=G.UIT.R, config={align = "cm"},nodes = {}} end 
    local cardarea = CardArea(
      2,2,
      3.5*G.CARD_W,
      0.75*G.CARD_H, 
      {card_limit = 5, type = 'title', highlight_limit = 0})
    for k, v in ipairs(G.GAME.hands[handname].example) do
        local card = Card(0,0, 0.5*G.CARD_W, 0.5*G.CARD_H, G.P_CARDS[v[1]], v[3] or G.P_CENTERS.c_base)
        if v[2] then card:juice_up(0.3, 0.2) end
        if k == 1 then play_sound('paper1',0.95 + math.random()*0.1, 0.3) end
        ease_value(card.T, 'scale',v[2] and 0.25 or -0.15,nil,'REAL',true,0.2)
        cardarea:emplace(card)
    end
  
    return {n=G.UIT.R, config={align = "cm", colour = G.C.WHITE, r = 0.1}, nodes={
      {n=G.UIT.C, config={align = "cm"}, nodes={
        {n=G.UIT.O, config={object = cardarea}}
      }}
    }}
end


HandAPI = {}

SMODS.PokerHands = {}
SMODS.PokerHand = {
    name = "",
    slug = "",
    loc_txt = "",
    visible = true,
    after_hand = "High Card",
    base_chips = 1,
    base_mult = 1,
    levelup_chips = 1,
    levelup_mult = 1,
    example = {}
}

function SMODS.PokerHand:new(name, slug, loc_txt, visible, after_hand, base_chips, base_mult, levelup_chips, levelup_mult, example)
    o = {}
    setmetatable(o, self)
    self.__index = self
  
    o.loc_txt = loc_txt
    o.name = name
    o.slug = "ph_" .. slug
    o.visible = not (visible == false)
    o.after_hand = after_hand or "High Card"
    o.base_chips = base_chips or 1
    o.base_mult = base_mult or 1
    o.levelup_chips = levelup_chips or 1
    o.levelup_mult = levelup_mult or 1
    o.example = example or {}
    return o
end

function SMODS.PokerHand:register()
    SMODS.PokerHands[self.slug] = self
    SMODS.PokerHands[self.slug].index = (#SMODS.PokerHands * 0.001)

    G.localization.misc['poker_hands'][self.name] = self.name
    G.localization.misc['poker_hand_descriptions'][self.name] = self.loc_txt

    local ii = {}
    for i, v in ipairs(G.handlist) do
        local hand_to_add = (v == self.after_hand) and self.name or nil
        if hand_to_add then
            ii[hand_to_add] = i
        end
    end
    
    local j = 0
    for hand, i in pairs(ii) do
        table.insert(G.handlist, i + j, hand)
        j = j + 1
    end
end
