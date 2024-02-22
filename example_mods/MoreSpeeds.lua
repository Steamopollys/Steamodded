--- STEAMODDED HEADER
--- MOD_NAME: More Speed
--- MOD_ID: MoreSpeed
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: More Speed options!

----------------------------------------------
------------MOD CODE -------------------------

setting_tabRef = G.UIDEF.settings_tab
function G.UIDEF.settings_tab(tab)
    local setting_tab = setting_tabRef(tab)

    if tab == 'Game' then
        local speeds = create_option_cycle({label = localize('b_set_gamespeed'), scale = 0.8, options = {0.25, 0.5, 1, 2, 3, 4, 8, 16}, opt_callback = 'change_gamespeed', current_option = (
            G.SETTINGS.GAMESPEED == 0.25 and 1 or
            G.SETTINGS.GAMESPEED == 0.5 and 2 or 
            G.SETTINGS.GAMESPEED == 1 and 3 or 
            G.SETTINGS.GAMESPEED == 2 and 4 or
            G.SETTINGS.GAMESPEED == 3 and 5 or
            G.SETTINGS.GAMESPEED == 4 and 6 or 
            G.SETTINGS.GAMESPEED == 8 and 7 or 
            G.SETTINGS.GAMESPEED == 16 and 8 or 
            3 -- Default to 1 if none match, adjust as necessary
        )})
        setting_tab.nodes[1] = speeds
    end
    return setting_tab
end

----------------------------------------------
------------MOD CODE END----------------------