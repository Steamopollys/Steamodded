--- STEAMODDED HEADER
--- MOD_NAME: Keyboard Controller
--- MOD_ID: KeyboardController
--- PREFIX: kbc
--- MOD_AUTHOR: [Aure]
--- MOD_DESCRIPTION: Enables the built-in keyboard controller and adds config options to customize it.
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]
--- CONFLICTS: [BlackHole]
--- VERSION: 1.0.0

KBC = SMODS.current_mod
KBC.save_config = function(self)
    SMODS.save_mod_config(self)
    G.keybind_mapping = {}
    -- Setup keyboard emulation
    for k, v in pairs(self.config.keybinds) do G.keybind_mapping[v] = k end
    function G.CONTROLLER.keyboard_controller.setVibration() end
end
KBC:save_config()
local kbc_options = {
    'dpleft',
    'dpright',
    'dpup',
    'dpdown',
    'x',
    'y',
    'a',
    'b',
    'start',
    'triggerleft',
    'triggerright',
    'leftshoulder',
    'rightshoulder',
    'back',
}
KBC.config_tab = function()
    local loc_options = {}
    for i, v in ipairs(kbc_options) do loc_options[i] = localize(v, 'kbc_keybinds') end
    KBC.current_keybind = KBC.current_keybind or 'dpleft'
    KBC.current_keybind_val = KBC.config.keybinds[KBC.current_keybind] or ''
    return {n = G.UIT.ROOT, config = {r = 0.1, minw = 5, align = "cm", padding = 0.2, colour = G.C.BLACK}, nodes = {
        create_toggle({label = localize('kbc_enable'), ref_table = KBC.config, ref_value = 'enable', callback = function() KBC:save_config() end }),
        {n = G.UIT.R, config = { align = "cm", padding = 0.01 }, nodes = {
            create_text_input({
                w = 4, max_length = 9, prompt_text = KBC.config.keybinds[KBC.current_keybind],
                extended_corpus = true, ref_table = KBC, ref_value = 'current_keybind_val', keyboard_offset = 1,
                callback = function(e)
                    KBC.config.keybinds[KBC.current_keybind] = KBC.current_keybind_val
                    KBC:save_config()
                end
            }),
        }},
        create_option_cycle({
            label = localize('kbc_current_keybind'),
            scale = 0.8,
            w = 4,
            options = loc_options,
            opt_callback = 'kbc_select_keybind',
            current_option = KBC.current_keybind_idx or 1,
        }),
    }}
end

function G.FUNCS.kbc_select_keybind(e)
    local hook = G.OVERLAY_MENU:get_UIE_by_ID('text_input').children[1].children[1]
    hook.config.ref_table.callback()
    KBC.current_keybind = kbc_options[e.to_key]
    KBC.current_keybind_idx = e.to_key
    hook.config.ref_value =  KBC.current_keybind
    G.CONTROLLER.text_input_hook = hook
    G.CONTROLLER.text_input_id = 'text_input'
    for i = 1, 9 do
      G.FUNCS.text_input_key({key = 'right'})
    end
    for i = 1, 9 do
        G.FUNCS.text_input_key({key = 'backspace'})
    end
    local text = KBC.config.keybinds[KBC.current_keybind]
    for i = 1, #text do
      local c = text:sub(i,i)
      G.FUNCS.text_input_key({key = c})
    end
    G.FUNCS.text_input_key({key = 'return'})
    --KBC.current_keybind_val = KBC.config.keybinds[KBC.current_keybind]
    KBC:save_config()
end