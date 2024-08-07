--- STEAMODDED HEADER
--- MOD_NAME: More Speed
--- MOD_ID: MoreSpeed
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: More Speed options!
--- This mod is deprecated, use Nopeus instead: https://github.com/jenwalter666/Nopeus

----------------------------------------------
------------MOD CODE -------------------------



local setting_tabRef = G.UIDEF.settings_tab
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

        local free_speed_text = {
            n = G.UIT.R,
            config = {
                align = "cm",
                id = "free_speed_text"
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        align = "cm",
						scale = 0.3 * 1.5,
						text = "Free Speed",
						colour = G.C.UI.TEXT_LIGHT
                    }
                }
            }
        }

        local free_speed_box = {
            n = G.UIT.R,
            config = {
                align = "cm",
                padding = 0.05,
                id = "free_speed_box" 
            },
            nodes = {
                create_text_input({
                    hooked_colour = G.C.RED,
                    colour = G.C.RED,
                    all_caps = true,
                    align = "cm",
                    w = 2,
                    max_length = 4,
                    prompt_text = 'Custom Speed',
                    ref_table = G.SETTINGS.COMP,
                    ref_value = 'name'
                })
            }
        }
        setting_tab.nodes[1] = speeds
        -- TODO fix this
        --table.insert(setting_tab.nodes, 2, free_speed_text)
        --table.insert(setting_tab.nodes, 3, free_speed_box)
    end
    return setting_tab
end

----------------------------------------------
------------MOD CODE END----------------------