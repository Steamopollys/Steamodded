SMODS.GUI = {}
SMODS.GUI.DynamicUIManager = {}

function STR_UNPACK(str)
    local chunk, err = loadstring(str)
    if chunk then
        setfenv(chunk, {}) -- Use an empty environment to prevent access to potentially harmful functions
        local success, result = pcall(chunk)
        if success then
            return result
        else
            print("Error unpacking string: " .. result)
            return nil
        end
    else
        print("Error loading string: " .. err)
        return nil
    end
end


local gameMainMenuRef = Game.main_menu
function Game:main_menu(change_context)
    gameMainMenuRef(self, change_context)
    UIBox({
        definition = {
            n = G.UIT.ROOT,
            config = {
                align = "cm",
                colour = G.C.UI.TRANSPARENT_DARK
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        scale = 0.3,
                        text = MODDED_VERSION,
                        colour = G.C.UI.TEXT_LIGHT
                    }
                }
            }
        },
        config = {
            align = "tri",
            bond = "Weak",
            offset = {
                x = 0,
                y = 0.3
            },
            major = G.ROOM_ATTACH
        }
    })
end

local gameUpdateRef = Game.update
function Game:update(dt)
    if G.STATE ~= G.STATES.SPLASH and G.MAIN_MENU_UI then
        local node = G.MAIN_MENU_UI:get_UIE_by_ID("main_menu_play")

        if node and not node.children.alert then
            node.children.alert = UIBox({
                definition = create_UIBox_card_alert({
                    text = localize('b_modded_version'),
                    no_bg = true,
                    scale = 0.4,
                    text_rot = -0.2
                }),
                config = {
                    align = "tli",
                    offset = {
                        x = -0.1,
                        y = 0
                    },
                    major = node,
                    parent = node
                }
            })
            node.children.alert.states.collide.can = false
        end
    end
    gameUpdateRef(self, dt)
end

local function wrapText(text, maxChars)
    local wrappedText = ""
    local currentLineLength = 0

    for word in text:gmatch("%S+") do
        if currentLineLength + #word <= maxChars then
            wrappedText = wrappedText .. word .. ' '
            currentLineLength = currentLineLength + #word + 1
        else
            wrappedText = wrappedText .. '\n' .. word .. ' '
            currentLineLength = #word + 1
        end
    end

    return wrappedText
end

-- Helper function to concatenate author names
local function concatAuthors(authors)
    if type(authors) == "table" then
        return table.concat(authors, ", ")
    end
    return authors or localize('b_unknown')
end


SMODS.LAST_SELECTED_MOD_TAB = "mod_desc"
function create_UIBox_mods(args)
    local mod = G.ACTIVE_MOD_UI
    if not SMODS.LAST_SELECTED_MOD_TAB then SMODS.LAST_SELECTED_MOD_TAB = "mod_desc" end

    local mod_tabs = {}
    table.insert(mod_tabs, buildModDescTab(mod))
    local additions_tab = buildAdditionsTab(mod)
    if additions_tab then table.insert(mod_tabs, additions_tab) end
    local credits_func = mod.credits_tab
    if credits_func and type(credits_func) == 'function' then 
        table.insert(mod_tabs, {
            label = localize("b_credits"),
            chosen = SMODS.LAST_SELECTED_MOD_TAB == "credits" or false,
            tab_definition_function = function(...)
                SMODS.LAST_SELECTED_MOD_TAB = "credits"
                return credits_func(...)
            end
        })
    end
    local config_func = mod.config_tab
    if config_func and type(config_func) == 'function' then 
        table.insert(mod_tabs, {
            label = localize("b_config"),
            chosen = SMODS.LAST_SELECTED_MOD_TAB == "config" or false,
            tab_definition_function = function(...)
                SMODS.LAST_SELECTED_MOD_TAB = "config"
                return config_func(...)
            end
        })
    end

    local mod_has_achievement
    for _, v in pairs(SMODS.Achievements) do
        if v.mod.id == mod.id then mod_has_achievement = true end
    end
    if mod_has_achievement then table.insert(mod_tabs, 
        {
            label = localize("b_achievements"),
            chosen = SMODS.LAST_SELECTED_MOD_TAB == "achievements" or false,
            tab_definition_function = function()
                SMODS.LAST_SELECTED_MOD_TAB = "achievements"
                return buildAchievementsTab(mod)
            end
        })
    end

    local custom_ui_func = mod.extra_tabs
    if custom_ui_func and type(custom_ui_func) == 'function' then
        local custom_tabs = custom_ui_func()
        if next(custom_tabs) and #custom_tabs == 0 then custom_tabs = { custom_tabs } end
        for i, v in ipairs(custom_tabs) do
            local id = mod.id..'_'..i
            v.chosen = (SMODS.LAST_SELECTED_MOD_TAB == id) or false
            v.label = v.label or ''
            local def = v.tab_definition_function
            assert(def, ('Custom defined mod tab with label "%s" from mod with id %s is missing definition function'):format(v.label, mod.id))
            v.tab_definition_function = function(...)
                SMODS.LAST_SELECTED_MOD_TAB = id
                return def(...)
            end
            table.insert(mod_tabs, v)
        end
    end

    return (create_UIBox_generic_options({
        back_func = "mods_button",
        contents = {
            {
                n = G.UIT.R,
                config = {
                    padding = 0,
                    align = "tm"
                },
                nodes = {
                    create_tabs({
                        snap_to_nav = true,
                        colour = G.C.BOOSTER,
                        tabs = mod_tabs
                    })
                }
            }
        }
    }))
end

function buildModDescTab(mod)
    G.E_MANAGER:add_event(Event({
        blockable = false,
        func = function()
            G.REFRESH_ALERTS = nil
            return true
        end
    }))
    local label = mod.name
    if (G.localization.descriptions.Mod or {})[mod.id] then
        label = localize { type = 'name_text', set = 'Mod', key = mod.id }
    end
    return {
        label = label,
        chosen = SMODS.LAST_SELECTED_MOD_TAB == "mod_desc" or false,
        tab_definition_function = function()
            local modNodes = {}
            local scale = 0.75 -- Scale factor for text
            local maxCharsPerLine = 50

            local wrappedDescription = wrapText(mod.description or '', maxCharsPerLine)

            local authors = localize('b_author' .. (#mod.author > 1 and 's' or '')) .. ': ' .. concatAuthors(mod.author)

            -- Authors names in blue
            table.insert(modNodes, {
                n = G.UIT.R,
                config = {
                    padding = 0,
                    align = "cm",
                    r = 0.1,
                    emboss = 0.1,
                    outline = 1,
                    padding = 0.07
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = authors,
                            shadow = true,
                            scale = scale * 0.65,
                            colour = G.C.BLUE,
                        }
                    }
                }
            })

            -- Mod description
            if (G.localization.descriptions.Mod or {})[mod.id] then
                modNodes[#modNodes + 1] = {}
                local loc_vars = mod.description_loc_vars and mod:description_loc_vars() or {}
                localize { type = 'descriptions', key = loc_vars.key or mod.id, set = 'Mod', nodes = modNodes[#modNodes], vars = loc_vars.vars, scale = loc_vars.scale, text_colour = loc_vars.text_colour }
                modNodes[#modNodes] = desc_from_rows(modNodes[#modNodes])
                modNodes[#modNodes].config.colour = loc_vars.background_colour or modNodes[#modNodes].config.colour
            else
                table.insert(modNodes, {
                    n = G.UIT.R,
                    config = {
                        padding = 0.2,
                        align = "cm"
                    },
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = {
                                text = wrappedDescription,
                                shadow = true,
                                scale = scale * 0.5,
                                colour = G.C.UI.TEXT_LIGHT
                            }
                        }
                    }
                })
            end

            local custom_ui_func = mod.custom_ui
            if custom_ui_func and type(custom_ui_func) == 'function' then
                custom_ui_func(modNodes)
            end

            return {
                n = G.UIT.ROOT,
                config = {
                    emboss = 0.05,
                    minh = 6,
                    r = 0.1,
                    minw = 6,
                    align = "tm",
                    padding = 0.2,
                    colour = G.C.BLACK
                },
                nodes = modNodes
            }
        end
    }
end

function buildAdditionsTab(mod)
    local consumable_nodes = {}
    for _, key in ipairs(SMODS.ConsumableType.ctype_buffer) do
        local id = 'your_collection_'..key:lower()..'s'
        local tally = modsCollectionTally(G.P_CENTER_POOLS[key])
        if tally.of > 0 then
            consumable_nodes[#consumable_nodes+1] = UIBox_button({button = id, label = {localize('b_'..key:lower()..'_cards')}, count = tally, minw = 4, id = id, colour = G.C.SECONDARY_SET[key]})
        end
    end
    if #consumable_nodes > 3 then
        consumable_nodes = { UIBox_button({ button = 'your_collection_consumables', label = {localize('b_stat_consumables'), localize{ type = 'variable', key = 'c_types', vars = {#consumable_nodes} } }, count = modsCollectionTally(G.P_CENTER_POOLS.Consumeables), minw = 4, minh = 4, id = 'your_collection_consumables', colour = G.C.FILTER }) }
    end

    local leftside_nodes = {}
    for _, v in ipairs { { k = 'Joker', minh = 1.7, scale = 0.6 }, { k = 'Back', b = 'decks' }, { k = 'Voucher' } } do
        v.b = v.b or v.k:lower()..'s'
        v.l = v.l or v.b
        local tally = modsCollectionTally(G.P_CENTER_POOLS[v.k])
        if tally.of > 0 then
            leftside_nodes[#leftside_nodes+1] = UIBox_button({button = 'your_collection_'..v.b, label = {localize('b_'..v.l)}, count = modsCollectionTally(G.P_CENTER_POOLS[v.k]),  minw = 5, minh = v.minh, scale = v.scale, id = 'your_collection_'..v.b})
        end
    end
    if #consumable_nodes > 0 then
        leftside_nodes[#leftside_nodes + 1] = {
            n = G.UIT.R,
            config = { align = "cm", padding = 0.1, r = 0.2, colour = G.C.BLACK },
            nodes = {
                {
                    n = G.UIT.C,
                    config = { align = "cm", maxh = 2.9 },
                    nodes = {
                        { n = G.UIT.T, config = { text = localize('k_cap_consumables'), scale = 0.45, colour = G.C.L_BLACK, vert = true, maxh = 2.2 } },
                    }
                },
                { n = G.UIT.C, config = { align = "cm", padding = 0.15 }, nodes = consumable_nodes }
            }
        }
    end

    local rightside_nodes = {}
    for _, v in ipairs { { k = 'Enhanced', b = 'enhancements', l = 'enhanced_cards'}, { k = 'Seal' }, { k = 'Edition' }, { k = 'Booster', l = 'booster_packs' }, { b = 'tags', p = G.P_TAGS }, { b = 'blinds', p = G.P_BLINDS, minh = 2.0 }, } do
        v.b = v.b or v.k:lower()..'s'
        v.l = v.l or v.b
        v.p = v.p or G.P_CENTER_POOLS[v.k]
        local tally = modsCollectionTally(v.p)
        if tally.of > 0 then
            rightside_nodes[#rightside_nodes+1] = UIBox_button({button = 'your_collection_'..v.b, label = {localize('b_'..v.l)}, count = modsCollectionTally(v.p),  minw = 5, minh = v.minh, id = 'your_collection_'..v.b})
        end
    end
    local has_other_gameobjects = create_UIBox_Other_GameObjects()
    if has_other_gameobjects then
        rightside_nodes[#rightside_nodes+1] = UIBox_button({button = 'your_collection_other_gameobjects', label = {localize('k_other')}, minw = 5, id = 'your_collection_other_gameobjects', focus_args = {snap_to = true}})
    end

    local t = {n=G.UIT.R, config={align = "cm",padding = 0.2, minw = 7}, nodes={
        {n=G.UIT.C, config={align = "cm", padding = 0.15}, nodes = leftside_nodes },
      {n=G.UIT.C, config={align = "cm", padding = 0.15}, nodes = rightside_nodes }
    }}

    local modNodes = {}
    table.insert(modNodes, t)
    return (#leftside_nodes > 0 or #rightside_nodes > 0 ) and {
        label = localize("b_additions"),
        chosen = SMODS.LAST_SELECTED_MOD_TAB == "additions" or false,
        tab_definition_function = function()
            SMODS.LAST_SELECTED_MOD_TAB = "additions"
            return {
                n = G.UIT.ROOT,
                config = {
                    emboss = 0.05,
                    minh = 6,
                    r = 0.1,
                    minw = 6,
                    align = "tm",
                    padding = 0.2,
                    colour = G.C.BLACK
                },
                nodes = modNodes
            }
        end
    } or nil
end

-- Disable alerts when in Additions tab
local set_alerts_ref = set_alerts
function set_alerts()
    if G.ACTIVE_MOD_UI then
    else 
        set_alerts_ref()
    end
end

G.FUNCS.your_collection_other_gameobjects = function(e)
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{
      definition = create_UIBox_Other_GameObjects(),
    }
end

function create_UIBox_Other_GameObjects()
    local custom_gameobject_tabs = {{}}
    local curr_height = 0
    local curr_col = 1
    local other_collections_tabs = {}
    local smods_uibox_buttons = {
        {
            count = G.ACTIVE_MOD_UI and modsCollectionTally(SMODS.Stickers), --Returns nil outside of G.ACTIVE_MOD_UI but we don't use it anyways
            button = UIBox_button({button = 'your_collection_stickers', label = {localize('b_stickers')}, count = G.ACTIVE_MOD_UI and modsCollectionTally(SMODS.Stickers), minw = 5, id = 'your_collection_stickers'})
        }
    }

    if G.ACTIVE_MOD_UI then
        for _, tab in pairs(smods_uibox_buttons) do
            if tab.count.of > 0 then other_collections_tabs[#other_collections_tabs+1] = tab.button end
        end
        if G.ACTIVE_MOD_UI and G.ACTIVE_MOD_UI.custom_collection_tabs then
            object_tabs = G.ACTIVE_MOD_UI.custom_collection_tabs()
            for _, tab in ipairs(object_tabs) do
                other_collections_tabs[#other_collections_tabs+1] = tab
            end
        end
    else
        for _, tab in pairs(smods_uibox_buttons) do
            other_collections_tabs[#other_collections_tabs+1] = tab.button
        end
        for _, mod in pairs(SMODS.Mods) do
            if mod.custom_collection_tabs and type(mod.custom_collection_tabs) == "function" then
                object_tabs = mod.custom_collection_tabs()
                for _, tab in ipairs(object_tabs) do
                    other_collections_tabs[#other_collections_tabs+1] = tab
                end
            end
        end
    end

    local custom_gameobject_rows = {}
    if #other_collections_tabs > 0 then
        for _, gameobject_tabs in ipairs(other_collections_tabs) do
            table.insert(custom_gameobject_tabs[curr_col], gameobject_tabs)
            curr_height = curr_height + gameobject_tabs.nodes[1].config.minh
            if curr_height > 6 then --TODO: Verify that this is the ideal number
                curr_height = 0
                curr_col = curr_col + 1
                custom_gameobject_tabs[curr_col] = {}
            end
        end
        for _, v in ipairs(custom_gameobject_tabs) do
            table.insert(custom_gameobject_rows, {n=G.UIT.C, config={align = "cm", padding = 0.15}, nodes = v})
        end

        local t = {n=G.UIT.C, config={align = "cm", r = 0.1, colour = G.C.BLACK, padding = 0.1, emboss = 0.05, minw = 7}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0.15}, nodes = custom_gameobject_rows}
        }}
    
        return create_UIBox_generic_options({ back_func = G.ACTIVE_MOD_UI and "openModUI_"..G.ACTIVE_MOD_UI.id or 'your_collection', contents = {t}})
    else
        return nil
    end
end

G.FUNCS.your_collection_consumables = function(e)
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{
      definition = create_UIBox_your_collection_consumables(),
    }
end

function create_UIBox_your_collection_consumables()
    local t = create_UIBox_generic_options({ back_func = G.ACTIVE_MOD_UI and "openModUI_"..G.ACTIVE_MOD_UI.id or 'your_collection', contents = {
        { n = G.UIT.C, config = { align = 'cm', minw = 11.5, minh = 6 }, nodes = {
            { n = G.UIT.O, config = { id = 'consumable_collection', object = Moveable() },}
        }},
    }})
    G.E_MANAGER:add_event(Event({func = function()
        G.FUNCS.your_collection_consumables_page({ cycle_config = { current_option = 1 }})
        return true
    end}))
    return t
end

G.FUNCS.your_collection_consumables_page = function(args)
    if not args or not args.cycle_config then return end
  if G.OVERLAY_MENU then
    local uie = G.OVERLAY_MENU:get_UIE_by_ID('consumable_collection')
    if uie then 
      if uie.config.object then 
        uie.config.object:remove() 
      end
      uie.config.object = UIBox{
        definition =  G.UIDEF.consumable_collection_page(args.cycle_config.current_option),
        config = { align = 'cm', parent = uie}
      }
    end
  end
end

G.UIDEF.consumable_collection_page = function(page)
    local nodes_per_page = 10
    local page_offset = nodes_per_page * ((page or 1) - 1)
    local type_buf = {}
    if G.ACTIVE_MOD_UI then
        for _, v in ipairs(SMODS.ConsumableType.ctype_buffer) do
            if modsCollectionTally(G.P_CENTER_POOLS[v]).of > 0 then type_buf[#type_buf + 1] = v end
        end
    else
        type_buf = SMODS.ConsumableType.ctype_buffer
    end
    local center_options = {}
    for i = 1, math.ceil(#type_buf / nodes_per_page) do
        table.insert(center_options,
            localize('k_page') ..
            ' ' .. tostring(i) .. '/' .. tostring(math.ceil(#type_buf / nodes_per_page)))
    end
    local option_nodes = { create_option_cycle({
        options = center_options,
        w = 4.5,
        cycle_shoulders = true,
        opt_callback = 'your_collection_consumables_page',
        focus_args = { snap_to = true, nav = 'wide' },
        current_option = page or 1,
        colour = G.C.RED,
        no_pips = true
    }) }
    local function create_consumable_nodes(_start, _end)
        local t = {}
        for i = _start, _end do
            local key = type_buf[i]
            if not key then
                if i == _start then break end
                t[#t+1] = { n = G.UIT.R, config = { align ='cm', minh = 0.81 }, nodes = {}}
            else 
                local id = 'your_collection_'..key:lower()..'s'
                t[#t+1] = UIBox_button({button = id, label = {localize('b_'..key:lower()..'_cards')}, count = G.ACTIVE_MOD_UI and modsCollectionTally(G.P_CENTER_POOLS[key]) or G.DISCOVER_TALLIES[key:lower()..'s'], minw = 4, id = id, colour = G.C.SECONDARY_SET[key]})
            end
        end
        return t
    end 

    local t = { n = G.UIT.C, config = { align = 'cm' }, nodes = {
        {n=G.UIT.R, config = {align="cm"}, nodes = {
            {n=G.UIT.C, config={align = "tm", padding = 0.15}, nodes= create_consumable_nodes(page_offset + 1, page_offset + math.ceil(nodes_per_page/2))},
            {n=G.UIT.C, config={align = "tm", padding = 0.15}, nodes= create_consumable_nodes(page_offset+1+math.ceil(nodes_per_page/2), page_offset + nodes_per_page)},
        }},
        {n=G.UIT.R, config = {align="cm"}, nodes = option_nodes},
    }}
    return t
end

function buildAchievementsTab(mod, current_page)
    current_page = current_page or 1
    fetch_achievements()
    local achievement_matrix = {{},{}}
    local achievements_per_row = 3
    local achievements_pool = {}
    for k, v in pairs(G.ACHIEVEMENTS) do
        if v.mod and v.mod.id == mod.id then achievements_pool[#achievements_pool+1] = v end
    end

    local achievement_tab = {}
    for k, v in pairs(achievements_pool) do
        achievement_tab[#achievement_tab+1] = v
    end
    
    table.sort(achievement_tab, function(a, b) return (a.order or 1) < (b.order or 1) end)
    
    local row = 1
    local max_lines = 2
    for i = 1, achievements_per_row*2 do
        local v = achievement_tab[i+((achievements_per_row*2)*(current_page-1))]
        if not v then break end
        local temp_achievement = Sprite(0,0,1.1,1.1,G.ASSET_ATLAS[v.atlas or "achievements"], v.earned and v.pos or {x=0, y=0})
        temp_achievement:define_draw_steps({
            {shader = 'dissolve', shadow_height = 0.05},
            {shader = 'dissolve'}
        })
        if i == 1 then 
            G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = (function()
                G.CONTROLLER:snap_to{node = temp_achievement}
                return true
            end)
            }))
        end
        temp_achievement.float = true
        temp_achievement.states.hover.can = true
        temp_achievement.states.drag.can = false
        temp_achievement.states.collide.can = true
        --temp_achievement.config = {blind = v, force_focus = true}
        temp_achievement.hover = function()
            if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then 
                if not temp_achievement.hovering and temp_achievement.states.visible then
                    temp_achievement.hovering = true
                    temp_achievement.hover_tilt = 3
                    temp_achievement:juice_up(0.05, 0.02)
                    play_sound('chips1', math.random()*0.1 + 0.55, 0.12)
                    Node.hover(temp_achievement)
                    if temp_achievement.children.alert then 
                        temp_achievement.children.alert:remove()
                        temp_achievement.children.alert = nil
                        v.alerted = true
                        G:save_progress()
                    end
                end
            end
            temp_achievement.stop_hover = function() temp_achievement.hovering = false; Node.stop_hover(temp_achievement); temp_achievement.hover_tilt = 0 end
        end

        -- Description
        local achievement_text = {}
        local maxCharsPerLine = 30
        local function wrapText(text, maxChars)
            local wrappedText = {""}
            local curr_line = 1
            local currentLineLength = 0
        
            for word in text:gmatch("%S+") do
                if currentLineLength + #word <= maxChars then
                    wrappedText[curr_line] = wrappedText[curr_line] .. word .. ' '
                    currentLineLength = currentLineLength + #word + 1
                else
                    wrappedText[curr_line] = string.sub(wrappedText[curr_line], 0, -2)
                    curr_line = curr_line + 1
                    wrappedText[curr_line] = ""
                    wrappedText[curr_line] = wrappedText[curr_line] .. word .. ' '
                    currentLineLength = #word + 1
                end
            end
        
            wrappedText[curr_line] = string.sub(wrappedText[curr_line], 0, -2)
            return wrappedText
        end
    
        local loc_target = (v.hidden_text and not v.earned) and {localize("hidden_achievement", 'achievement_descriptions')} or wrapText(localize(v.key, 'achievement_descriptions'), maxCharsPerLine)
        local loc_name = (v.hidden_name and not v.earned) and localize("hidden_achievement", 'achievement_names') or localize(v.key, 'achievement_names')

        local ability_text = {}
        if loc_target then 
            for k, v in ipairs(loc_target) do
                ability_text[#ability_text + 1] = {n=G.UIT.R, config={align = "cm"}, nodes={{n=G.UIT.T, config={text = v, scale = 0.35, shadow = true, colour = G.C.WHITE}}}}
            end
        end
        max_lines = math.max(max_lines, #ability_text)
        achievement_text[#achievement_text + 1] =
        {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, minw = 4, maxw = 4, padding = 0.05, colour = G.C.WHITE, minh = 0.4*max_lines+0.1}, nodes={
            ability_text[1] and {n=G.UIT.R, config={align = "cm", padding = 0.08, colour = G.C.GREY, r = 0.1, emboss = 0.05, minw = 3.9, maxw = 3.9, minh = 0.4*max_lines}, nodes=ability_text} or nil
        }}

        table.insert(achievement_matrix[row], {
            n = G.UIT.C,
            config = { align = "cm", padding = 0.1 },
            nodes = {
                {n=G.UIT.R, config = {align = "cm"}, nodes = {
                    {n=G.UIT.R, config = {align = "cm", padding = 0.1}, nodes = {{ n = G.UIT.O, config = { object = temp_achievement, focus_with_object = true }}}},
                    {
                        n=G.UIT.R, config = {align = "cm", minw = 4, maxw = 4, padding = 0.05}, nodes = {
                            {n=G.UIT.R, config={align = "cm", emboss = 0.05, r = 0.1, padding = 0.1, minh = 0.6, colour = G.C.GREY}, nodes={
                                {n=G.UIT.O, config={align = "cm", maxw = 3.8, object = DynaText({string = loc_name, maxw = 3.8, colours = {G.C.UI.TEXT_LIGHT}, shadow = true, spacing = 1, bump = true, scale = 0.4})}},
                            }},
                            {n=G.UIT.R, config={align = "cm"}, nodes=achievement_text},
                        },
                    },
                }},
            },
        })
        if #achievement_matrix[row] == achievements_per_row then 
            row = row + 1
            achievement_matrix[row] = {}
            max_lines = 2
        end
    end

    local achievements_options = {}
    for i = 1, math.ceil(#achievements_pool/(2*achievements_per_row)) do
        table.insert(achievements_options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#achievements_pool/(2*achievements_per_row))))
    end

    local t = {
        {n=G.UIT.C, config={}, nodes={ 
        {n=G.UIT.C, config={align = "cm"}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
            {n=G.UIT.R, config={align = "cm", padding = 0.1 }, nodes=achievement_matrix[1]},
            {n=G.UIT.R, config={align = "cm", padding = 0.1 }, nodes=achievement_matrix[2]},
            create_option_cycle({options = achievements_options, w = 4.5, cycle_shoulders = true, opt_callback = 'achievments_tab_page', focus_args = {snap_to = true, nav = 'wide'},current_option = current_page, colour = G.C.RED, no_pips = true})
        }}
        }}
    }}}
    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 6,
            align = "tm",
            padding = 0.2,
            colour = G.C.BLACK
        },
        nodes = t
    }
end

G.FUNCS.achievments_tab_page = function(args)
    if not args or not args.cycle_config then return end
    achievement_matrix = {{},{}}

    local tab_contents = G.OVERLAY_MENU:get_UIE_by_ID('tab_contents')
    tab_contents.config.object:remove()
    tab_contents.config.object = UIBox{
        definition = buildAchievementsTab(G.ACTIVE_MOD_UI, args.cycle_config.current_option),
        config = {offset = {x=0,y=0}, parent = tab_contents, type = 'cm'}
    }
    tab_contents.UIBox:recalculate()
end

-- TODO: Optimize this. 
function modsCollectionTally(pool, set)
    local set = set or nil
    local obj_tally = {tally = 0, of = 0}

    for _, v in pairs(pool) do
        if v.mod and G.ACTIVE_MOD_UI.id == v.mod.id and not v.no_collection then
            if set then
                if v.set and v.set == set then
                    obj_tally.of = obj_tally.of+1
                    if v.discovered then 
                        obj_tally.tally = obj_tally.tally+1
                    end
                end
            else
                obj_tally.of = obj_tally.of+1
                if v.discovered then 
                    obj_tally.tally = obj_tally.tally+1
                end
            end
        end
    end

    return obj_tally
end

-- TODO: Make better solution
local UIBox_button_ref = UIBox_button
function UIBox_button(args)
    local button = UIBox_button_ref(args)
    button.nodes[1].config.count = args.count
    return button
end

function buildModtag(mod)
    local tag_pos, tag_message, tag_atlas = { x = 0, y = 0 }, "load_success", mod.prefix and mod.prefix .. '_modicon' or 'modicon'
    local specific_vars = {}

    if not mod.can_load then
        tag_message = "load_failure"
        tag_atlas = "mod_tags"
        specific_vars = {}
        if next(mod.load_issues.dependencies) then
            tag_message = tag_message..'_d'
            table.insert(specific_vars, concatAuthors(mod.load_issues.dependencies))
        end
        if next(mod.load_issues.conflicts) then
            tag_message = tag_message .. '_c'
            table.insert(specific_vars, concatAuthors(mod.load_issues.conflicts))
        end
        if mod.load_issues.outdated then tag_message = 'load_failure_o' end
        if mod.load_issues.version_mismatch then
            tag_message = 'load_failure_i'
            specific_vars = {mod.load_issues.version_mismatch, MODDED_VERSION:gsub('-STEAMODDED', '')}
        end
        if mod.load_issues.main_file_not_found then
            tag_message = 'load_failure_m'
            specific_vars = {mod.main_file}
        end
        if mod.load_issues.prefix_conflict then
            tag_message = 'load_failure_p'
            local name = mod.load_issues.prefix_conflict
            for _, m in ipairs(SMODS.mod_list) do
                if m.id == mod.load_issues.prefix_conflict then
                    name = m.name or name
                end
            end
            specific_vars = {name}
        end
        if mod.disabled then
            tag_pos = {x = 1, y = 0}
            tag_message = 'load_disabled'
        end
    end


    local tag_sprite_tab = nil
    
    local tag_sprite = Sprite(0, 0, 0.8*1, 0.8*1, G.ASSET_ATLAS[tag_atlas] or G.ASSET_ATLAS['tags'], tag_pos)
    tag_sprite.T.scale = 1
    tag_sprite_tab = {n= G.UIT.C, config={align = "cm", padding = 0}, nodes={
        {n=G.UIT.O, config={w=0.8*1, h=0.8*1, colour = G.C.BLUE, object = tag_sprite, focus_with_object = true}},
    }}
    tag_sprite:define_draw_steps({
        {shader = 'dissolve', shadow_height = 0.05},
        {shader = 'dissolve'},
    })
    tag_sprite.float = true
    tag_sprite.states.hover.can = true
    tag_sprite.states.drag.can = false
    tag_sprite.states.collide.can = true

    tag_sprite.hover = function(_self)
        if not G.CONTROLLER.dragging.target or G.CONTROLLER.using_touch then 
            if not _self.hovering and _self.states.visible then
                _self.hovering = true
                if _self == tag_sprite then
                    _self.hover_tilt = 3
                    _self:juice_up(0.05, 0.02)
                    play_sound('paper1', math.random()*0.1 + 0.55, 0.42)
                    play_sound('tarot2', math.random()*0.1 + 0.55, 0.09)
                end
                tag_sprite.ability_UIBox_table = generate_card_ui({set = "Other", discovered = false, key = tag_message}, nil, specific_vars, 'Other', nil, false)
                _self.config.h_popup =  G.UIDEF.card_h_popup(_self)
                _self.config.h_popup_config ={align = 'cl', offset = {x=-0.1,y=0},parent = _self}
                Node.hover(_self)
                if _self.children.alert then 
                    _self.children.alert:remove()
                    _self.children.alert = nil
                    G:save_progress()
                end
            end
        end
    end
    tag_sprite.stop_hover = function(_self) _self.hovering = false; Node.stop_hover(_self); _self.hover_tilt = 0 end

    tag_sprite:juice_up()

    return tag_sprite_tab
end

-- Helper function to create a clickable mod box
local function createClickableModBox(modInfo, scale)
    local function invert(c)
            return {1-c[1], 1-c[2], 1-c[3], c[4]}
        end
    local col, text_col
    if modInfo.should_enable == nil then
        modInfo.should_enable = not modInfo.disabled
    end
    if SMODS.full_restart == nil then
        SMODS.full_restart = 0
    end
    if modInfo.can_load then
        col = G.C.BOOSTER
    elseif modInfo.disabled then
        col = G.C.UI.BACKGROUND_INACTIVE
    else
        col = mix_colours(G.C.RED, G.C.UI.BACKGROUND_INACTIVE, 0.7)
        text_col = G.C.TEXT_DARK
    end
    local label =  { " " .. modInfo.name .. " " }
    if modInfo.lovely_only then
        label[2] = localize('b_lovely_mod')
    else
        label[2] = localize('b_by') .. concatAuthors(modInfo.author) .. " "
    end
    local but = UIBox_button {
        label = label,
        shadow = true,
        scale = scale,
        colour = col,
        text_colour = text_col,
        button = "openModUI_" .. modInfo.id,
        minh = 0.8,
        minw = 7
    }
    if modInfo.lovely_only then
        local config = but.nodes[1].nodes[2].nodes[1].config
        config.colour = mix_colours(invert(col), G.C.UI.TEXT_INACTIVE, 0.8)
        config.scale = scale * .8
    end
    if modInfo.version and modInfo.version ~= '0.0.0' then
        table.insert(but.nodes[1].nodes[1].nodes, {
            n = G.UIT.T,
            config = {
                text = ('(%s) '):format(modInfo.version),
                scale = scale*0.8,
                colour = mix_colours(invert(col), G.C.UI.TEXT_INACTIVE, 0.8),
                shadow = true,
            },
        })
    end 
    if modInfo.config_tab then
        table.insert(but.nodes[1].nodes[1].nodes, {
            n = G.UIT.O,
            config = {
                object = Sprite(0,0,0.4,0.4, G.ASSET_ATLAS['mod_tags'], {x=2,y=0})
            }
        })
    end
    return {
        n = G.UIT.R,
        config = { padding = 0, align = "cm" },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "cm" },
                nodes = {
                    buildModtag(modInfo)
                }
            },
            {
                n = G.UIT.C,
                config = { align = "cm", padding = 0.1 },
                nodes = {},
            },
            { n = G.UIT.C, config = { padding = 0, align = "cm" }, nodes = { but } },
            create_toggle({
                label = '',
                ref_table = modInfo,
                ref_value = 'should_enable',
                col = true,
                w = 0,
                h = 0.5,
                callback = (
                    function(_set_toggle)
                        if not modInfo.should_enable then
                            NFS.write(modInfo.path .. '.lovelyignore', '')
                        else
                            NFS.remove(modInfo.path .. '.lovelyignore')
                        end
                        local toChange = 1
                        if modInfo.should_enable == not modInfo.disabled then
                            toChange = -1
                        end
                        SMODS.full_restart = SMODS.full_restart + toChange
                    end
                )
            }),
    }}
    
end

function G.FUNCS.openModsDirectory(options)
    love.system.openURL(SMODS.MODS_DIR)
end

function G.FUNCS.mods_buttons_page(options)
    if not options or not options.cycle_config then
        return
    end
end

function SMODS.load_mod_config(mod)
    local s1, config = pcall(function()
        return load(NFS.read(('config/%s.jkr'):format(mod.id)), ('=[SMODS %s "config"]'):format(mod.id))()
    end)
    local s2, default_config = pcall(function()
        return load(NFS.read(('%sconfig.lua'):format(mod.path)), ('=[SMODS %s "default_config"]'):format(mod.id))()
    end)
    if not s1 or type(config) ~= 'table' then config = {} end
    if not s2 or type(default_config) ~= 'table' then default_config = {} end
    mod.config = {} 
    for k, v in pairs(default_config) do mod.config[k] = v end
    for k, v in pairs(config) do mod.config[k] = v end
    return mod.config
end
SMODS:load_mod_config()
function SMODS.save_mod_config(mod)
    local success = pcall(function()
        NFS.createDirectory('config')
        assert(mod.config and next(mod.config))
        local serialized = 'return '..serialize(mod.config)
        NFS.write(('config/%s.jkr'):format(mod.id), serialized)
    end)
    return success
end
function SMODS.save_all_config()
    SMODS:save_mod_config()
    for _, v in ipairs(SMODS.mod_list) do
        if v.can_load then 
            local save_func = type(v.save_mod_config) == 'function' and v.save_mod_config or SMODS.save_mod_config
            save_func(v)
        end
    end
end

function G.FUNCS.exit_mods(e)
    G.ACTIVE_MOD_UI = nil
    SMODS.save_all_config()
    if SMODS.full_restart and SMODS.full_restart ~= 0 then
        -- launch a new instance of the game and quit the current one
        SMODS.restart_game()
    end
    SMODS.IN_MODS_TAB = nil
    if e then
        -- This is only needed when back button is pressed
        G.FUNCS.exit_overlay_menu(e)
    end
end

function create_UIBox_mods_button()
    local scale = 0.75
    SMODS.browse_search = SMODS.browse_search or ''
    return (create_UIBox_generic_options({
        back_func = 'exit_mods',
        contents = {
            {
                n = G.UIT.R,
                config = {
                    padding = 0,
                    align = "cm"
                },
                nodes = {
                    create_tabs({
                        snap_to_nav = true,
                        colour = G.C.BOOSTER,
                        tabs = {
                            {
                                label = localize('b_mods'),
                                chosen = true,
                                tab_definition_function = function()
                                    return SMODS.GUI.DynamicUIManager.initTab({
                                        updateFunctions = {
                                            modsList = G.FUNCS.update_mod_list,
                                        },
                                        staticPageDefinition = SMODS.GUI.staticModListContent()
                                    })
                                end
                            },
                            -- {
                            -- 	label = localize('b_browse'),
                            -- 	tab_definition_function = function()
                            -- 		return {
                            --             n = G.UIT.ROOT,
                            --             config = {
                            --                 align = "cm",
                            --                 padding = 0.05,
                            --                 colour = G.C.CLEAR,
                            --             },
                            --             nodes = {
                            -- 				{
                            -- 					n = G.UIT.C,
                            -- 					config = { align = 'cm' },
                            -- 					nodes = {
                            -- 						{
                            -- 							n = G.UIT.R,
                            -- 							config = { align = 'cl' },
                            -- 							nodes = {
                            -- 								create_text_input{
                            -- 									prompt_text = localize('b_search_prompt'),
                            -- 									max_length = 50,
                            -- 									text_scale = 0.6,
                            -- 									w = 6,
                            -- 									h = 1,
                            -- 									ref_table = SMODS,
                            -- 									ref_value = "browse_search",
                            -- 									extended_corpus = true,
                            -- 								},
                            -- 								UIBox_button{
                            -- 									button = 'browse_search',
                            -- 									label = {localize('b_search_button')},
                            -- 									minw = 3,
                            -- 									colour = G.C.RED
                            -- 								}
                            -- 							}
                            -- 						},
                            -- 						{
                            -- 							n = G.UIT.R,
                            -- 							config = { align = 'cm', emboss = 0.05, colour = G.C.BLACK, minh=5, minw=10.5},
                            -- 							nodes = {
                            -- 								{
                            -- 									n = G.UIT.O,
                            -- 									config = { align = 'cm', object = Moveable(), id = 'browse_mods'}
                            -- 								}
                            -- 							}
                            -- 						}
                            -- 					}
                            -- 				}
                            -- 			}
                            -- 		}
                            -- 	end,
                            -- },
                            {

                                label = localize('b_credits'),
                                tab_definition_function = function()
                                    return {
                                        n = G.UIT.ROOT,
                                        config = {
                                            emboss = 0.05,
                                            minh = 6,
                                            r = 0.1,
                                            minw = 6,
                                            align = "cm",
                                            padding = 0.2,
                                            colour = G.C.BLACK
                                        },
                                        nodes = {
                                            {
                                                n = G.UIT.R,
                                                config = {
                                                    padding = 0,
                                                    align = "cm"
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = localize('b_mod_loader'),
                                                            shadow = true,
                                                            scale = scale * 0.8,
                                                            colour = G.C.UI.TEXT_LIGHT
                                                        }
                                                    }
                                                }
                                            },
                                            {
                                                n = G.UIT.R,
                                                config = {
                                                    padding = 0,
                                                    align = "cm"
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = localize('b_developed_by'),
                                                            shadow = true,
                                                            scale = scale * 0.8,
                                                            colour = G.C.UI.TEXT_LIGHT
                                                        }
                                                    },
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = "Steamo",
                                                            shadow = true,
                                                            scale = scale * 0.8,
                                                            colour = G.C.BLUE
                                                        }
                                                    }
                                                }
                                            },
                                            {
                                                n = G.UIT.R,
                                                config = {
                                                    padding = 0,
                                                    align = "cm"
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = localize('b_rewrite_by'),
                                                            shadow = true,
                                                            scale = scale * 0.8,
                                                            colour = G.C.UI.TEXT_LIGHT
                                                        }
                                                    },
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = "Aure",
                                                            shadow = true,
                                                            scale = scale * 0.8,
                                                            colour = G.C.BLUE
                                                        }
                                                    }
                                                }
                                            },
                                            {
                                                n = G.UIT.R,
                                                config = {
                                                    padding = 0.2,
                                                    align = "cm",
                                                },
                                                nodes = {
                                                    UIBox_button({
                                                        minw = 3.85,
                                                        button = "steamodded_github",
                                                        label = {localize('b_github_project')}
                                                    })
                                                }
                                            },
                                            {
                                                n = G.UIT.R,
                                                config = {
                                                    padding = 0.2,
                                                    align = "cm"
                                                },
                                                nodes = {
                                                    {
                                                        n = G.UIT.T,
                                                        config = {
                                                            text = localize('b_github_bugs_1')..'\n'..localize('b_github_bugs_2'),
                                                            shadow = true,
                                                            scale = scale * 0.5,
                                                            colour = G.C.UI.TEXT_LIGHT
                                                        }
                                                    },
                                                    
                                                }
                                            },
                                        }
                                    }
                                end
                            },
                            {
                                label = localize('b_config'),
                                tab_definition_function = function()
                                    return {
                                        n = G.UIT.ROOT,
                                        config = {
                                            align = "cm",
                                            padding = 0.05,
                                            colour = G.C.CLEAR,
                                        },
                                        nodes = {
                                            create_toggle {
                                                label = localize('b_disable_mod_badges'),
                                                ref_table = SMODS.config,
                                                ref_value = 'no_mod_badges',
                                            },
                                            create_toggle {
                                                label = localize('b_seeded_unlocks'),
                                                info = {localize('b_seeded_unlocks_info')},
                                                ref_table = SMODS.config,
                                                ref_value = 'seeded_unlocks',
                                            },
                                            create_option_cycle {
                                                w = 4.5,
                                                scale = 0.8,
                                                label = localize('b_achievements'),
                                                options = localize('ml_achievement_settings'),
                                                opt_callback = 'update_achievement_settings',
                                                current_option = SMODS.config.achievements,
                                                cycle_shoulders = true,
                                            }
                                        }
                                    }
                                end
                            }
                        }
                    })
                }
            }
        }
    }))
end

G.FUNCS.update_achievement_settings = function(e)
    local opt = (e.cycle_config or {}).current_option or 1
    SMODS.config.achievements = opt
    G.F_NO_ACHIEVEMENTS = opt == 1
end

G.FUNCS.browse_search = function(e)
    SMODS.fetch_index()

end

G.FUNCS.browse_mods_page = function(args)
    local page = args.cycle_config and args.cycle_config.current_option or 1
end

function G.FUNCS.steamodded_github(e)
    love.system.openURL("https://github.com/Steamopollys/Steamodded")
end

function G.FUNCS.mods_button(e)
    G.SETTINGS.paused = true
    SMODS.LAST_SELECTED_MOD_TAB = nil
    SMODS.IN_MODS_TAB = true

    G.FUNCS.overlay_menu({
        definition = create_UIBox_mods_button()
    })
end

local create_UIBox_main_menu_buttonsRef = create_UIBox_main_menu_buttons
function create_UIBox_main_menu_buttons()
    local modsButton = UIBox_button({
        id = "mods_button",
        minh = 1.55,
        minw = 1.85,
        col = true,
        button = "mods_button",
        colour = G.C.BOOSTER,
        label = {localize('b_mods_cap')},
        scale = 0.45 * 1.2
    })
    local menu = create_UIBox_main_menu_buttonsRef()
    table.insert(menu.nodes[1].nodes[1].nodes, modsButton)
    menu.nodes[1].nodes[1].config = {align = "cm", padding = 0.15, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK, mid = true}
    if SMODS.mod_button_alert then 
        G.E_MANAGER:add_event(Event({
            func = function()
                if G.MAIN_MENU_UI then -- Wait until the ui is rendered before spawning the alert
                    UIBox{definition = create_UIBox_card_alert(), config = {align="tri", offset = {x = 0.05, y = -0.05}, major = G.MAIN_MENU_UI:get_UIE_by_ID('mods_button'), can_collide = false}}
                    return true
                end
            end,
            blocking = false,
            blockable = false
        }))
    end
    return menu
end

local create_UIBox_profile_buttonRef = create_UIBox_profile_button
function create_UIBox_profile_button()
    local profile_menu = create_UIBox_profile_buttonRef()
    profile_menu.nodes[1].config = {align = "cm", padding = 0.11, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK}
    return(profile_menu)
end

-- Disable achievments and crash report upload
function initGlobals()
    G.F_NO_ACHIEVEMENTS = SMODS.config.achievements == 1
    G.F_CRASH_REPORTS = false
end

function G.FUNCS.update_mod_list(args)
    if not args or not args.cycle_config then return end
    SMODS.GUI.DynamicUIManager.updateDynamicAreas({
        ["modsList"] = SMODS.GUI.dynamicModListContent(args.cycle_config.current_option)
    })
end

-- Same as Balatro base game code, but accepts a value to match against (rather than the index in the option list)
-- e.g. create_option_cycle({ current_option = 1 })  vs. SMODS.GUID.createOptionSelector({ current_option = "Page 1/2" })
function SMODS.GUI.createOptionSelector(args)
    args = args or {}
    args.colour = args.colour or G.C.RED
    args.options = args.options or {
        'Option 1',
        'Option 2'
    }

    local current_option_index = 1
    for i, option in ipairs(args.options) do
        if option == args.current_option then
            current_option_index = i
            break
        end
    end
    args.current_option_val = args.options[current_option_index]
    args.current_option = current_option_index
    args.opt_callback = args.opt_callback or nil
    args.scale = args.scale or 1
    args.ref_table = args.ref_table or nil
    args.ref_value = args.ref_value or nil
    args.w = (args.w or 2.5)*args.scale
    args.h = (args.h or 0.8)*args.scale
    args.text_scale = (args.text_scale or 0.5)*args.scale
    args.l = '<'
    args.r = '>'
    args.focus_args = args.focus_args or {}
    args.focus_args.type = 'cycle'

    local info = nil
    if args.info then
        info = {}
        for k, v in ipairs(args.info) do
            table.insert(info, {n=G.UIT.R, config={align = "cm", minh = 0.05}, nodes={
                {n=G.UIT.T, config={text = v, scale = 0.3*args.scale, colour = G.C.UI.TEXT_LIGHT}}
            }})
        end
        info =  {n=G.UIT.R, config={align = "cm", minh = 0.05}, nodes=info}
    end

    local disabled = #args.options < 2
    local pips = {}
    for i = 1, #args.options do
        pips[#pips+1] = {n=G.UIT.B, config={w = 0.1*args.scale, h = 0.1*args.scale, r = 0.05, id = 'pip_'..i, colour = args.current_option == i and G.C.WHITE or G.C.BLACK}}
    end

    local choice_pips = not args.no_pips and {n=G.UIT.R, config={align = "cm", padding = (0.05 - (#args.options > 15 and 0.03 or 0))*args.scale}, nodes=pips} or nil

    local t =
    {n=G.UIT.C, config={align = "cm", padding = 0.1, r = 0.1, colour = G.C.CLEAR, id = args.id and (not args.label and args.id or nil) or nil, focus_args = args.focus_args}, nodes={
        {n=G.UIT.C, config={align = "cm",r = 0.1, minw = 0.6*args.scale, hover = not disabled, colour = not disabled and args.colour or G.C.BLACK,shadow = not disabled, button = not disabled and 'option_cycle' or nil, ref_table = args, ref_value = 'l', focus_args = {type = 'none'}}, nodes={
            {n=G.UIT.T, config={ref_table = args, ref_value = 'l', scale = args.text_scale, colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE}}
        }},
        args.mid and
                {n=G.UIT.C, config={id = 'cycle_main'}, nodes={
                    {n=G.UIT.R, config={align = "cm", minh = 0.05}, nodes={
                        args.mid
                    }},
                    not disabled and choice_pips or nil
                }}
                or {n=G.UIT.C, config={id = 'cycle_main', align = "cm", minw = args.w, minh = args.h, r = 0.1, padding = 0.05, colour = args.colour,emboss = 0.1, hover = true, can_collide = true, on_demand_tooltip = args.on_demand_tooltip}, nodes={
            {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.R, config={align = "cm"}, nodes={
                    {n=G.UIT.O, config={object = DynaText({string = {{ref_table = args, ref_value = "current_option_val"}}, colours = {G.C.UI.TEXT_LIGHT},pop_in = 0, pop_in_rate = 8, reset_pop_in = true,shadow = true, float = true, silent = true, bump = true, scale = args.text_scale, non_recalc = true})}},
                }},
                {n=G.UIT.R, config={align = "cm", minh = 0.05}, nodes={
                }},
                not disabled and choice_pips or nil
            }}
        }},
        {n=G.UIT.C, config={align = "cm",r = 0.1, minw = 0.6*args.scale, hover = not disabled, colour = not disabled and args.colour or G.C.BLACK,shadow = not disabled, button = not disabled and 'option_cycle' or nil, ref_table = args, ref_value = 'r', focus_args = {type = 'none'}}, nodes={
            {n=G.UIT.T, config={ref_table = args, ref_value = 'r', scale = args.text_scale, colour = not disabled and G.C.UI.TEXT_LIGHT or G.C.UI.TEXT_INACTIVE}}
        }},
    }}

    if args.cycle_shoulders then
        t =
        {n=G.UIT.R, config={align = "cm", colour = G.C.CLEAR}, nodes = {
            {n=G.UIT.C, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'leftshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = -0.1, y = 0}}}, nodes = {}},
            {n=G.UIT.C, config={id = 'cycle_shoulders', padding = 0.1}, nodes={t}},
            {n=G.UIT.C, config={minw = 0.7,align = "cm", colour = G.C.CLEAR,func = 'set_button_pip', focus_args = {button = 'rightshoulder', type = 'none', orientation = 'cm', scale = 0.7, offset = {x = 0.1, y = 0}}}, nodes = {}},
        }}
    else
        t =
        {n=G.UIT.R, config={align = "cm", colour = G.C.CLEAR, padding = 0.0}, nodes = {
            t
        }}
    end
    if args.label or args.info then
        t = {n=G.UIT.R, config={align = "cm", padding = 0.05, id = args.id or nil}, nodes={
            args.label and {n=G.UIT.R, config={align = "cm"}, nodes={
                {n=G.UIT.T, config={text = args.label, scale = 0.5*args.scale, colour = G.C.UI.TEXT_LIGHT}}
            }} or nil,
            t,
            info,
        }}
    end
    return t
end

local function generateBaseNode(staticPageDefinition)
    return {
        n = G.UIT.ROOT,
        config = {
            emboss = 0.05,
            minh = 6,
            r = 0.1,
            minw = 8,
            align = "cm",
            padding = 0.2,
            colour = G.C.BLACK
        },
        nodes = {
            staticPageDefinition
        }
    }
end

-- Initialize a tab with sections that can be updated dynamically (e.g. modifying text labels, showing additional UI elements after toggling buttons, etc.)
function SMODS.GUI.DynamicUIManager.initTab(args)
    local updateFunctions = args.updateFunctions
    local staticPageDefinition = args.staticPageDefinition

    for _, updateFunction in pairs(updateFunctions) do
        G.E_MANAGER:add_event(Event({func = function()
            updateFunction{cycle_config = {}}
            return true
        end}))
    end
    return generateBaseNode(staticPageDefinition)
end

-- Call this to trigger an update for a list of dynamic content areas
function SMODS.GUI.DynamicUIManager.updateDynamicAreas(uiDefinitions)
    for id, uiDefinition in pairs(uiDefinitions) do
        local dynamicArea = G.OVERLAY_MENU:get_UIE_by_ID(id)
        if dynamicArea and dynamicArea.config.object then
            dynamicArea.config.object:remove()
            dynamicArea.config.object = UIBox{
                definition = uiDefinition,
                config = {offset = {x=0, y=0}, align = 'cm', parent = dynamicArea}
            }
        end
    end
end

local function recalculateModsList(page)
    page = page or SMODS.LAST_VIEWED_MODS_PAGE or 1
    SMODS.LAST_VIEWED_MODS_PAGE = page
    local modsPerPage = 4
    local startIndex = (page - 1) * modsPerPage + 1
    local endIndex = startIndex + modsPerPage - 1
    local totalPages = math.ceil(#SMODS.mod_list / modsPerPage)
    local currentPage = localize('k_page') .. ' ' .. page .. "/" .. totalPages
    local pageOptions = {}
    for i = 1, totalPages do
        table.insert(pageOptions, (localize('k_page') .. ' ' .. tostring(i) .. "/" .. totalPages))
    end
    local showingList = #SMODS.mod_list > 0

    return currentPage, pageOptions, showingList, startIndex, endIndex, modsPerPage
end

-- Define the content in the pane that does not need to update
-- Should include OBJECT nodes that indicate where the dynamic content sections will be populated
-- EX: in this pane the 'modsList' node will contain the dynamic content which is defined in the function below
function SMODS.GUI.staticModListContent()
    local scale = 0.75
    local currentPage, pageOptions, showingList = recalculateModsList()
    return {
        n = G.UIT.ROOT,
        config = {
            minh = 6,
            r = 0.1,
            minw = 10,
            align = "tm",
            padding = 0.2,
            colour = G.C.BLACK
        },
        nodes = {
            -- row container
            {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.05 },
                nodes = {
                    -- column container
                    {
                        n = G.UIT.C,
                        config = { align = "cm", minw = 3, padding = 0.2, r = 0.1, colour = G.C.CLEAR },
                        nodes = {
                            -- title row
                            {
                                n = G.UIT.R,
                                config = {
                                    padding = 0.05,
                                    align = "cm"
                                },
                                nodes = {
                                    UIBox_button({
                                        label = { localize('b_mod_list') },
                                        shadow = true,
                                        scale = scale*0.85,
                                        colour = G.C.BOOSTER,
                                        button = "openModsDirectory",
                                        minh = scale,
                                        minw = 9
                                    }),
                                }
                            },

                            -- add some empty rows for spacing
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.05 },
                                nodes = {}
                            },

                            -- dynamic content rendered in this row container
                            -- list of 4 mods on the current page
                            {
                                n = G.UIT.R,
                                config = {
                                    padding = 0.05,
                                    align = "cm",
                                    minh = 2,
                                    minw = 4
                                },
                                nodes = {
                                    {n=G.UIT.O, config={id = 'modsList', object = Moveable()}},
                                }
                            },

                            -- another empty row for spacing
                            {
                                n = G.UIT.R,
                                config = { align = "cm", padding = 0.3 },
                                nodes = {}
                            },

                            -- page selector
                            -- does not appear when list of mods is empty
                            showingList and SMODS.GUI.createOptionSelector({label = "", scale = 0.8, options = pageOptions, opt_callback = 'update_mod_list', no_pips = true, current_option = (
                                    currentPage
                            )}) or nil
                        }
                    },
                }
            },
        }
    }
end

function SMODS.GUI.dynamicModListContent(page)
    local scale = 0.75
    local _, __, showingList, startIndex, endIndex, modsPerPage = recalculateModsList(page)

    local modNodes = {}

    -- If no mods are loaded, show a default message
    if showingList == false then
        table.insert(modNodes, {
            n = G.UIT.R,
            config = {
                padding = 0,
                align = "cm"
            },
            nodes = {
                {
                    n = G.UIT.T,
                    config = {
                        text = localize('b_no_mods'),
                        shadow = true,
                        scale = scale * 0.5,
                        colour = G.C.UI.TEXT_DARK
                    }
                }
            }
        })
    else
        local modCount = 0
        local id = 0
        
        for _, condition in ipairs({
            function(m) return not m.can_load and not m.disabled end,
            function(m) return m.can_load end,
            function(m) return m.disabled end,
        }) do
            for _, modInfo in ipairs(SMODS.mod_list) do
                if modCount >= modsPerPage then break end
                if condition(modInfo) then
                    id = id + 1
                    if id >= startIndex and id <= endIndex then
                        table.insert(modNodes, createClickableModBox(modInfo, scale * 0.5))
                        modCount = modCount + 1
                    end
                end
            end
        end
    end

    return {
        n = G.UIT.C,
        config = {
            r = 0.1,
            align = "cm",
            padding = 0.2,
        },
        nodes = modNodes
    }
end

G.FUNCS.SMODS_change_mipmap = function(args)
    SMODS.config.graphics_mipmap_level = args.to_key
    G:set_render_settings()
    SMODS:save_mod_config()
end

SMODS.card_collection_UIBox = function(_pool, rows, args)
    args = args or {}
    args.w_mod = args.w_mod or 1
    args.h_mod = args.h_mod or 1
    args.card_scale = args.card_scale or 1
    local deck_tables = {}
    local pool = SMODS.collection_pool(_pool)

    G.your_collection = {}
    local cards_per_page = 0
    local row_totals = {}
    for j = 1, #rows do
        if cards_per_page >= #pool and args.collapse_single_page then
            rows[j] = nil
        else
            row_totals[j] = cards_per_page
            cards_per_page = cards_per_page + rows[j]
            G.your_collection[j] = CardArea(
                G.ROOM.T.x + 0.2*G.ROOM.T.w/2,G.ROOM.T.h,
                (args.w_mod*rows[j]+0.25)*G.CARD_W,
                args.h_mod*G.CARD_H, 
                {card_limit = rows[j], type = args.area_type or 'title', highlight_limit = 0, collection = true}
            )
            table.insert(deck_tables, 
            {n=G.UIT.R, config={align = "cm", padding = 0.07, no_fill = true}, nodes={
                {n=G.UIT.O, config={object = G.your_collection[j]}}
            }})
        end
    end

    local options = {}
    for i = 1, math.ceil(#pool/cards_per_page) do
        table.insert(options, localize('k_page')..' '..tostring(i)..'/'..tostring(math.ceil(#pool/cards_per_page)))
    end

    G.FUNCS.SMODS_card_collection_page = function(e)
        if not e or not e.cycle_config then return end
        for j = 1, #G.your_collection do
            for i = #G.your_collection[j].cards, 1, -1 do
            local c = G.your_collection[j]:remove_card(G.your_collection[j].cards[i])
            c:remove()
            c = nil
            end
        end
        for j = 1, #rows do
            for i = 1, rows[j] do
            local center = pool[i+row_totals[j] + (cards_per_page*(e.cycle_config.current_option - 1))]
            if not center then break end
            local card = Card(G.your_collection[j].T.x + G.your_collection[j].T.w/2, G.your_collection[j].T.y, G.CARD_W*args.card_scale, G.CARD_H*args.card_scale, G.P_CARDS.empty, (args.center and G.P_CENTERS[args.center]) or center)
            if args.modify_card then args.modify_card(card, center, i, j) end
            if not args.no_materialize then card:start_materialize(nil, i>1 or j>1) end
            G.your_collection[j]:emplace(card)
            end
        end
        INIT_COLLECTION_CARD_ALERTS()
    end

    G.FUNCS.SMODS_card_collection_page{ cycle_config = { current_option = 1 }}
    
    local t =  create_UIBox_generic_options({ back_func = (args and args.back_func) or G.ACTIVE_MOD_UI and "openModUI_"..G.ACTIVE_MOD_UI.id or 'your_collection', snap_back = args.snap_back, infotip = args.infotip, contents = {
          {n=G.UIT.R, config={align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05}, nodes=deck_tables}, 
          (not args.hide_single_page or cards_per_page < #pool) and {n=G.UIT.R, config={align = "cm"}, nodes={
            create_option_cycle({options = options, w = 4.5, cycle_shoulders = true, opt_callback = 'SMODS_card_collection_page', current_option = 1, colour = G.C.RED, no_pips = true, focus_args = {snap_to = true, nav = 'wide'}})
          }} or nil,
      }})
    return t
end

create_UIBox_your_collection_jokers = function() 
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Joker, {5,5,5}, {
        no_materialize = true, 
        modify_card = function(card, center) card.sticker = get_joker_win_sticker(center) end,
        h_mod = 0.95,
    })
end
create_UIBox_your_collection_boosters = function()
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Booster, {4,4}, {
        h_mod = 1.3,
        w_mod = 1.25, 
        card_scale = 1.27,
    })
end
create_UIBox_your_collection_vouchers = function()
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Voucher, {4,4}, {
        area_type = 'voucher',
        modify_card = function(card, center, i, j)
            card.ability.order = i+(j-1)*4
        end,
    })
end
create_UIBox_your_collection_enhancements = function()
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Enhanced, {4,4}, {
        no_materialize = true,
        snap_back = true,
        h_mod = 1.03,
        infotip = localize('ml_edition_seal_enhancement_explanation'),
        hide_single_page = true,
    })
end 
create_UIBox_your_collection_editions = function()
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Edition, {5,5}, {
        snap_back = true,
        h_mod = 1.03,
        infotip = localize('ml_edition_seal_enhancement_explanation'),
        hide_single_page = true,
        collapse_single_page = true,
        modify_card = function(card, center)
            if center.discovered then card:set_edition(center.key, true, true) end
        end,
    })
end

create_UIBox_your_collection_seals = function()
    return SMODS.card_collection_UIBox(G.P_CENTER_POOLS.Seal, {5,5}, {
        snap_back = true,
        infotip = localize('ml_edition_seal_enhancement_explanation'),
        hide_single_page = true,
        collapse_single_page = true,
        center = 'c_base',
        h_mod = 1.03,
        modify_card = function(card, center)
            card:set_seal(center.key, true)
        end,
    })
end

G.FUNCS.your_collection_stickers = function(e)
    G.SETTINGS.paused = true
    G.FUNCS.overlay_menu{
      definition = create_UIBox_your_collection_stickers(),
    }
end

create_UIBox_your_collection_stickers = function()
    return SMODS.card_collection_UIBox(SMODS.Stickers, {5,5}, {
        snap_back = true,
        hide_single_page = true,
        collapse_single_page = true,
        center = 'c_base',
        h_mod = 1.03,
        back_func = 'your_collection_other_gameobjects',
        modify_card = function(card, center)
            card.ignore_pinned = true
            center:apply(card, true)
        end,
    })
end
