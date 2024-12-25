--[[
------------------------------Basic Table of Contents------------------------------
Line 17, Atlas ---------------- Explains the parts of the atlas.
Line 29, Joker 2 -------------- Explains the basic structure of a joker
Line 88, Runner 2 ------------- Uses a bit more complex contexts, and shows how to scale a value.
Line 127, Golden Joker 2 ------ Shows off a specific function that's used to add money at the end of a round.
Line 163, Merry Andy 2 -------- Shows how to use add_to_deck and remove_from_deck.
Line 207, Sock and Buskin 2 --- Shows how you can retrigger cards and check for faces
Line 240, Perkeo 2 ------------ Shows how to use the event manager, eval_status_text, randomness, and soul_pos.
Line 285, Walkie Talkie 2 ----- Shows how to look for multiple specific ranks, and explains returning multiple values
Line 319, Gros Michel 2 ------- Shows the no_pool_flag, sets a pool flag, another way to use randomness, and end of round stuff.
Line 393, Cavendish 2 --------- Shows yes_pool_flag, has X Mult, mainly to go with Gros Michel 2.
Line 457, Castle 2 ------------ Shows the use of reset_game_globals and colour variables in loc_vars.
--]]

--Creates an atlas for cards to use
SMODS.Atlas {
  -- Key for code to find it with
  key = "ModdedVanilla",
  -- The name of the file, for the code to pull the atlas from
  path = "ModdedVanilla.png",
  -- Width of each sprite in 1x size
  px = 71,
  -- Height of each sprite in 1x size
  py = 95
}


SMODS.Joker {
  -- How the code refers to the joker.
  key = 'joker2',
  -- loc_text is the actual name and description that show in-game for the card.
  loc_txt = {
    name = 'Joker 2',
    text = {
      --[[
      The #1# is a variable that's stored in config, and is put into loc_vars.
      The {C:} is a color modifier, and uses the color "mult" for the "+#1# " part, and then the empty {} is to reset all formatting, so that Mult remains uncolored.
      There's {X:}, which sets the background, usually used for XMult.
      There's {s:}, which is scale, and multiplies the text size by the value, like 0.8
      There's one more, {V:1}, but is more advanced, and is used in Castle and Ancient Jokers. It allows for a variable to dynamically change the color, but is very rarely used.
      Multiple variables can be used in one space, as long as you separate them with a comma. {C:attention, X:chips, s:1.3} would be the yellow attention color, with a blue chips-colored background,, and 1.3 times the scale of other text.
      You can find the vanilla joker descriptions and names as well as several other things in the localization files.
      ]]
      "{C:mult}+#1# {} Mult"
    }
  },
  --[[
  Config sets all the variables for your card, you want to put all numbers here.
  This is really useful for scaling numbers, but should be done with static numbers -
      If you want to change the static value, you'd only change this number, instead
      of going through all your code to change each instance individually.
  ]]
  config = { extra = { mult = 4 } },
  -- loc_vars gives your loc_text variables to work with, in the format of #n#, n being the variable in order.
  -- #1# is the first variable in vars, #2# the second, #3# the third, and so on.
  -- It's also where you'd add to the info_queue, which is where things like the negative tooltip are.
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.mult } }
  end,
  -- Sets rarity. 1 common, 2 uncommon, 3 rare, 4 legendary.
  rarity = 1,
  -- Which atlas key to pull from.
  atlas = 'ModdedVanilla',
  -- This card's position on the atlas, starting at {x=0,y=0} for the very top left.
  pos = { x = 0, y = 0 },
  -- Cost of card in shop.
  cost = 2,
  -- The functioning part of the joker, looks at context to decide what step of scoring the game is on, and then gives a 'return' value if something activates.
  calculate = function(self, card, context)
    -- Tests if context.joker_main == true.
    -- joker_main is a SMODS specific thing, and is where the effects of jokers that just give +stuff in the joker area area triggered, like Joker giving +Mult, Cavendish giving XMult, and Bull giving +Chips.
    if context.joker_main then
      -- Tells the joker what to do. In this case, it pulls the value of mult from the config, and tells the joker to use that variable as the "mult_mod".
      return {
        mult_mod = card.ability.extra.mult,
        -- This is a localize function. Localize looks through the localization files, and translates it. It ensures your mod is able to be translated. I've left it out in most cases for clarity reasons, but this one is required, because it has a variable.
        -- This specifically looks in the localization table for the 'variable' category, specifically under 'v_dictionary' in 'localization/en-us.lua', and searches that table for 'a_mult', which is short for add mult.
        -- In the localization file, a_mult = "+#1#". Like with loc_vars, the vars in this message variable replace the #1#.
        message = localize { type = 'variable', key = 'a_mult', vars = { card.ability.extra.mult } }
        -- Without this, the mult will stil be added, but it'll just show as a blank red square that doesn't have any text.
      }
    end
  end
}


SMODS.Joker {
  key = 'runner2',
  loc_txt = {
    name = 'Runner 2',
    text = {
      "Gains {C:chips}+#2#{} Chips",
      "if played hand",
      "contains a {C:attention}Straight{}",
      "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips)"
    }
  },
  config = { extra = { chips = 0, chip_gain = 15 } },
  rarity = 1,
  atlas = 'ModdedVanilla',
  pos = { x = 1, y = 0 },
  cost = 5,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.chips, card.ability.extra.chip_gain } }
  end,
  calculate = function(self, card, context)
    if context.joker_main then
      return {
        chip_mod = card.ability.extra.chips,
        message = localize { type = 'variable', key = 'a_chips', vars = { card.ability.extra.chips } }
      }
    end

    -- context.before checks if context.before == true, and context.before is true when it's before the current hand is scored.
    -- (context.poker_hands['Straight']) checks if the current hand is a 'Straight'.
    -- The 'next()' part makes sure it goes over every option in the table, which the table is context.poker_hands.
    -- context.poker_hands contains every valid hand type in a played hand.
    -- not context.blueprint ensures that Blueprint or Brainstorm don't copy this upgrading part of the joker, but that it'll still copy the added chips.
    if context.before and next(context.poker_hands['Straight']) and not context.blueprint then
      -- Updated variable is equal to current variable, plus the amount of chips in chip gain.
      -- 15 = 0+15, 30 = 15+15, 75 = 60+15.
      card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_gain
      return {
        message = 'Upgraded!',
        colour = G.C.CHIPS,
        -- The return value, "card", is set to the variable "card", which is the joker.
        -- Basically, this tells the return value what it's affecting, which if it's the joker itself, it's usually card.
        -- It can be things like card = context.other_card in some cases, so specifying card (return value) = card (variable from function) is required.
        card = card
      }
    end
  end
}


SMODS.Joker {
  key = 'golden2',
  loc_txt = {
    name = 'Golden Joker 2',
    text = {
      "Earn {C:money}$#1#{} at",
      "end of round"
    }
  },
  config = { extra = { money = 4 } },
  rarity = 1,
  atlas = 'ModdedVanilla',
  pos = { x = 2, y = 0 },
  cost = 6,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.money } }
  end,
  -- SMODS specific function, gives the returned value in dollars at the end of round, double checks that it's greater than 0 before returning.
  calc_dollar_bonus = function(self, card)
    local bonus = card.ability.extra.money
    if bonus > 0 then return bonus end
  end
  -- Since there's nothing else to calculate, a calculate function is completely unnecessary.
}


SMODS.Joker {
  key = 'merry_andy2',
  loc_txt = {
    name = 'Merry Andy',
    text = {
      "{C:red}+#1#{} discards",
      "each round,",
      "{C:red}#2#{} hand size"
    }
  },
  config = { extra = { discard_size = 3, hand_size = -1 } },
  rarity = 2,
  atlas = 'ModdedVanilla',
  pos = { x = 3, y = 0 },
  cost = 7,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.discard_size, card.ability.extra.hand_size } }
  end,
  -- This function is called when the card is added to deck. from_debuff is true whenever a card gets debuffed and then undebuffed.
  -- Debuffs usually call both of these functions, essentially, when a joker is debuffed, it's simply removed from your jokers, except for the fact that it takes up a slot.
  add_to_deck = function(self, card, from_debuff)
    -- Changes a G.GAME variable, which is usually a global value that's specific to the current run.
    -- These are initialized in game.lua under the Game:init_game_object() function, and you can look through them to get an idea of the things you can change.
    G.GAME.round_resets.discards = G.GAME.round_resets.discards + card.ability.extra.discard_size
    G.hand:change_size(card.ability.extra.hand_size)
  end,
  -- Inverse of above function.
  remove_from_deck = function(self, card, from_debuff)
    -- Adds - instead of +, so they get subtracted when this card is removed.
    G.GAME.round_resets.discards = G.GAME.round_resets.discards - card.ability.extra.discard_size
    G.hand:change_size(-card.ability.extra.hand_size)
  end
  -- Because all the functionality is in remove_from_deck and add_to deck, calculate is unnecessary.

  --[[
  Extra note, having the config as something like
    config = {d_size = 3, h_size = -1, extra = {whatever variables you put}}
  automatically applies these changes.
  However, these values outside of the extra table are constants, so they aren't good for jokers with values that change.
  You can find a fuller list of them at card.lua:275.
  ]]
}


SMODS.Joker {
  key = 'sock_and_buskin2',
  loc_txt = {
    name = 'Sock and Buskin',
    text = {
      "Retrigger all",
      "played {C:attention}face{} cards"
    }
  },
  config = { extra = { repetitions = 1 } },
  rarity = 2,
  atlas = 'ModdedVanilla',
  pos = { x = 4, y = 0 },
  cost = 6,
  calculate = function(self, card, context)
    -- Checks that the current cardarea is G.play, or the cards that have been played, then checks to see if it's time to check for repetition.
    -- The "not context.repetition_only" is there to keep it separate from seals.
    if context.cardarea == G.play and context.repetition and not context.repetition_only then
      -- context.other_card is something that's used when either context.individual or context.repetition is true
      -- It is each card 1 by 1, but in other cases, you'd need to iterate over the scoring hand to check which cards are there.
      if context.other_card:is_face() then
        return {
          message = 'Again!',
          repetitions = card.ability.extra.repetitions,
          -- The card the repetitions are applying to is context.other_card
          card = context.other_card
        }
      end
    end
  end
}


SMODS.Joker {
  key = 'perkeo2',
  loc_txt = {
    name = 'Perkeo 2',
    text = {
      "Creates a {C:dark_edition}Negative{} copy of",
      "{C:attention}1{} random {C:attention}consumable{}",
      "card in your possession",
      "at the end of the {C:attention}shop",
    }
  },
  -- Extra is empty, because it only happens once. If you wanted to copy multiple cards, you'd need to restructure the code and add a for loop or something.
  config = { extra = {} },
  rarity = 4,
  atlas = 'ModdedVanilla',
  pos = { x = 0, y = 1 },
  -- soul_pos sets the soul sprite, only used in vanilla for legenedaries and Hologram.
  soul_pos = { x = 4, y = 1 },
  cost = 20,
  calculate = function(self, card, context)
    if context.ending_shop then
      -- Ask someone to explain how to use the event manager in detail here.
      G.E_MANAGER:add_event(Event({
        func = function()
          -- pseudorandom_element is a vanilla function that chooses a single random value from a table of values, which in this case, is your consumables.
          -- pseudoseed('perkeo2') could be replaced with any text string at all - It's simply a way to make sure that it's affected by the game seed, because if you use math.random(), a base Lua function, then it'll generate things truly randomly, and can't be reproduced with the same Balatro seed. LocalThunk likes to have the joker names in the pseudoseed string, so you'll often find people do the same.
          local card = copy_card(pseudorandom_element(G.consumeables.cards, pseudoseed('perkeo2')), nil)

          -- Vanilla function, it's (edition, immediate, silent), so this is ({edition = 'e_negative'}, immediate = true, silent = nil)
          card:set_edition('e_negative', true)
          card:add_to_deck()
          -- card:emplace puts a card in a cardarea, this one is G.consumeables, but G.jokers works, and custom card areas could also work.
          -- I think playing cards use "create_playing_card()" and are separate.
          G.consumeables:emplace(card)
          return true
        end
      }))
      -- Ask someone who knows eval_status_text better to elaborate on this.
      card_eval_status_text(context.blueprint_card or card, 'extra', nil, nil, nil,
        { message = localize('k_duplicated_ex') })
    end
  end
}


SMODS.Joker {
  key = 'walkie_talkie2',
  loc_txt = {
    name = 'Walkie Talkie',
    text = {
      "Each played {C:attention}10{} or {C:attention}4",
      "gives {C:chips}+#1#{} Chips and",
      "{C:mult}+#2#{} Mult when scored"
    }
  },
  config = { extra = { chips = 10, mult = 4 } },
  rarity = 1,
  atlas = 'ModdedVanilla',
  pos = { x = 1, y = 1 },
  cost = 4,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.chips, card.ability.extra.mult } }
  end,
  calculate = function(self, card, context)
    if context.individual and context.cardarea == G.play then
      -- :get_id tests for the rank of the card. Other than 2-10, Jack is 11, Queen is 12, King is 13, and Ace is 14.
      if context.other_card:get_id() == 10 or context.other_card:get_id() == 4 then
        -- Specifically returning to context.other_card is fine with multiple values in a single return value, chips/mult are different from chip_mod and mult_mod, and automatically come with a message which plays in order of return.
        return {
          chips = card.ability.extra.chips,
          mult = card.ability.extra.mult,
          card = context.other_card
        }
      end
    end
  end
}


SMODS.Joker {
  key = 'gros_michel2',
  loc_txt = {
    name = 'Gros Michel 2',
    text = {
      "{C:mult}+#1#{} Mult",
      "{C:green}#2# in #3#{} chance this",
      "card is destroyed",
      "at end of round"
    }
  },
  -- This searches G.GAME.pool_flags to see if Gros Michel went extinct. If so, no longer shows up in the shop.
  no_pool_flag = 'gros_michel_extinct2',
  config = { extra = { mult = 15, odds = 6 } },
  rarity = 1,
  atlas = 'ModdedVanilla',
  pos = { x = 2, y = 1 },
  cost = 5,
  -- Gros Michel is incompatible with the eternal sticker, so this makes sure it can't be eternal.
  eternal_compat = false,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.mult, (G.GAME.probabilities.normal or 1), card.ability.extra.odds } }
  end,
  calculate = function(self, card, context)
    if context.joker_main then
      return {
        mult_mod = card.ability.extra.mult,
        message = localize { type = 'variable', key = 'a_mult', vars = { card.ability.extra.mult } }
      }
    end

    -- Checks to see if it's end of round, and if context.game_over is false.
    -- Also, not context.repetition ensures it doesn't get called during repetitions.
    if context.end_of_round and not context.repetition and context.game_over == false and not context.blueprint then
      -- Another pseudorandom thing, randomly generates a decimal between 0 and 1, so effectively a random percentage.
      if pseudorandom('gros_michel2') < G.GAME.probabilities.normal / card.ability.extra.odds then
        -- This part plays the animation.
        G.E_MANAGER:add_event(Event({
          func = function()
            play_sound('tarot1')
            card.T.r = -0.2
            card:juice_up(0.3, 0.4)
            card.states.drag.is = true
            card.children.center.pinch.x = true
            -- This part destroys the card.
            G.E_MANAGER:add_event(Event({
              trigger = 'after',
              delay = 0.3,
              blockable = false,
              func = function()
                G.jokers:remove_card(card)
                card:remove()
                card = nil
                return true;
              end
            }))
            return true
          end
        }))
        -- Sets the pool flag to true, meaning Gros Michel 2 doesn't spawn, and Cavendish 2 does.
        G.GAME.pool_flags.gros_michel_extinct2 = true
        return {
          message = 'Extinct!'
        }
      else
        return {
          message = 'Safe!'
        }
      end
    end
  end
}


SMODS.Joker {
  key = 'cavendish2',
  loc_txt = {
    name = 'Cavendish 2',
    text = {
      "{X:mult,C:white} X#1# {} Mult",
      "{C:green}#2# in #3#{} chance this",
      "card is destroyed",
      "at end of round"
    }
  },
  -- This also searches G.GAME.pool_flags to see if Gros Michel went extinct. If so, enables the ability to show up in shop.
  yes_pool_flag = 'gros_michel_extinct2',
  config = { extra = { Xmult = 3, odds = 1000 } },
  rarity = 1,
  atlas = 'ModdedVanilla',
  pos = { x = 3, y = 1 },
  cost = 4,
  eternal_compat = false,
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.Xmult, (G.GAME.probabilities.normal or 1), card.ability.extra.odds } }
  end,
  calculate = function(self, card, context)
    if context.joker_main then
      return {
        message = localize { type = 'variable', key = 'a_xmult', vars = { card.ability.extra.Xmult } },
        Xmult_mod = card.ability.extra.Xmult
      }
    end
    if context.end_of_round and context.game_over == false and not context.repetition and not context.blueprint then
      if pseudorandom('cavendish2') < G.GAME.probabilities.normal / card.ability.extra.odds then
        G.E_MANAGER:add_event(Event({
          func = function()
            play_sound('tarot1')
            card.T.r = -0.2
            card:juice_up(0.3, 0.4)
            card.states.drag.is = true
            card.children.center.pinch.x = true
            G.E_MANAGER:add_event(Event({
              trigger = 'after',
              delay = 0.3,
              blockable = false,
              func = function()
                G.jokers:remove_card(card)
                card:remove()
                card = nil
                return true;
              end
            }))
            return true
          end
        }))
        return {
          message = 'Extinct!'
        }
      else
        return {
          message = 'Safe!'
        }
      end
    end
  end
}

SMODS.Joker {
  key = 'castle2',
  loc_txt = {
    name = 'Castle 2',
    text = {
      "This Joker gains {C:chips}+#1#{} Chips",
      "per discarded {V:1}#2#{} card,",
      "suit changes every round",
      "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips)",
    }
  },
  blueprint_compat = true,
  perishable_compat = false,
  eternal_compat = true,
  rarity = 2,
  cost = 6,
  config = { extra = { chips = 0, chip_mod = 3 }},
  atlas = 'ModdedVanilla',
  pos = { x = 5, y = 0 },
  loc_vars = function(self, info_queue, card)
    return { vars = { 
      card.ability.extra.chip_mod, 
      localize(G.GAME.current_round.castle2_card.suit, 'suits_singular'), -- gets the localized name of the suit 
      card.ability.extra.chips,
      colours = {G.C.SUITS[G.GAME.current_round.castle2_card.suit]} -- sets the colour of the text affected by `{V:1}`
    }}
  end,
  calculate = function(self, card, context)
    if 
      context.discard and 
      not context.other_card.debuff and 
      context.other_card:is_suit(G.GAME.current_round.castle2_card.suit) and 
      not context.blueprint
    then
      card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
      return {
        message = localize('k_upgrade_ex'),
        colour = G.C.CHIPS,
        card = card
      }
    end
    if context.joker_main and card.ability.extra.chips > 0 then
      return {
        message = localize{type='variable',key='a_chips',vars={card.ability.extra.chips}},
        chip_mod = card.ability.extra.chips, 
        colour = G.C.CHIPS
    }
    end
  end
}

local igo = Game.init_game_object
function Game:init_game_object()
  local ret = igo(self)
  ret.current_round.castle2_card = { suit = 'Spades' } 
  return ret
end

function SMODS.current_mod.reset_game_globals(run_start)
  -- The suit changes every round, so we use reset_game_globals to choose a suit.
  G.GAME.current_round.castle2_card = { suit = 'Spades' }
  local valid_castle_cards = {}
  for _, v in ipairs(G.playing_cards) do
    if not SMODS.has_no_suit(v) then -- Abstracted enhancement check for jokers being able to give cards additional enhancements
        valid_castle_cards[#valid_castle_cards+1] = v
    end
  end
  if valid_castle_cards[1] then 
      local castle_card = pseudorandom_element(valid_castle_cards, pseudoseed('2cas'..G.GAME.round_resets.ante))
      G.GAME.current_round.castle2_card.suit = castle_card.base.suit
  end
end


-- TODO
-- Have someone with more knowledge explain the details of the event manager and eval_status_text
-- Have people proofread, make sure my overly long way of writing is actually legible or cut down to make sure it's legible.


----------------------------------------------
------------MOD CODE END----------------------
