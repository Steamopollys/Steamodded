--- STEAMODDED HEADER
--- MOD_NAME: CustomKeybinds
--- MOD_ID: CKeybinds
--- MOD_AUTHOR: [stupxd]
--- MOD_DESCRIPTION: Custom keybinds example!

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Keybind{
	key = 'imrich',
	key_pressed = 'm',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(controller)
        G.GAME.dollars = 1000000
        sendInfoMessage("money set to 1 million")
    end,
}

-- ctrl + shift + k = Xe10 money
-- ctrl + k = X100 money
SMODS.Keybind{
	key = 'moneyglitch',
	key_pressed = 'k',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(controller)
        if controller.held_keys['lshift'] then
          G.GAME.dollars = G.GAME.dollars * 10000000000
          sendInfoMessage("money Xe10")
        else
          G.GAME.dollars = G.GAME.dollars * 100
          sendInfoMessage("money X100")
        end
    end,
}

SMODS.Keybind{
	key = 'broke',
	key_pressed = 'p',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(controller)
        G.GAME.dollars = 1
        sendInfoMessage("money set to 1")
    end,
}

----------------------------------------------
------------MOD CODE END----------------------
