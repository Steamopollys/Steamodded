--- STEAMODDED HEADER
--- MOD_NAME: Escape Exit Button
--- MOD_ID: EscapeExitButton
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Add an "Exit" button into the "Escape" menu

----------------------------------------------
------------MOD CODE -------------------------

function G.FUNCS.exit_button(arg_736_0)
    G.SETTINGS.paused = true

    love.event.quit()
end

local createOptionsRef = create_UIBox_options
function create_UIBox_options()
    contents = createOptionsRef()
    local exit_button = UIBox_button({
        minw = 5,
        button = "exit_button",
        label = {
            "Exit Game"
        }
    })
    table.insert(contents.nodes[1].nodes[1].nodes[1].nodes, #contents.nodes[1].nodes[1].nodes[1].nodes + 1, exit_button)
    return contents
end

----------------------------------------------
------------MOD CODE END----------------------
