--- STEAMODDED HEADER
--- MOD_NAME: CustomKeybinds
--- MOD_ID: CKeybinds
--- MOD_AUTHOR: [stupxd]
--- MOD_DESCRIPTION: Custom keybinds example!
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Keybind{
	key = 'imrich',
	key_pressed = 'm',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(self)
        G.GAME.dollars = 1000000
        sendInfoMessage("money set to 1 million", "CustomKeybinds")
    end,
}

-- ctrl + shift + k = Xe10 money
-- ctrl + k = X100 money
SMODS.Keybind{
	key = 'moneyglitch',
	key_pressed = 'k',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(self)
        if G.CONTROLLER.held_keys['lshift'] then
          G.GAME.dollars = G.GAME.dollars * 10000000000
          sendInfoMessage("money Xe10", "CustomKeybinds")
        else
          G.GAME.dollars = G.GAME.dollars * 100
          sendInfoMessage("money X100", "CustomKeybinds")
        end
    end,
}

SMODS.Keybind{
	key = 'broke',
	key_pressed = 'p',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(self)
        G.GAME.dollars = 1
        sendInfoMessage("money set to 1", "CustomKeybinds")
    end,
}

----------------------------------------------
------------MOD CODE END----------------------
