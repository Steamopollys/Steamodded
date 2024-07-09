--- STEAMODDED HEADER
--- MOD_NAME: CustomKeybinds
--- MOD_ID: CKeybinds
--- MOD_AUTHOR: [stupxd]
--- MOD_DESCRIPTION: Custom keybinds example!

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Keybind{
	key = 'undo',
	key_pressed = 'z',
    held_keys = {'lctrl'}, -- other key(s) that need to be held

    action = function(controller)
        sendInfoMessage("Ctrl+Z pressed")
    end,
}

SMODS.Keybind{
	key = 'debugmessage',
	key_pressed = '9',
    -- held_keys = {'lshift'}, -- other key(s) that need to be held

    action = function(controller)
        sendInfoMessage("9 pressed")
    end,
}

----------------------------------------------
------------MOD CODE END----------------------
