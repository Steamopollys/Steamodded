--- STEAMODDED CORE
--- MODULE CORE

SMODS = {}
SMODS.GUI = {}
SMODS.GUI.DynamicUIManager = {}

MODDED_VERSION = "1.0.0-ALPHA-0617b-STEAMODDED"

function STR_UNPACK(str)
	local chunk, err = loadstring(str)
	if chunk then
	  setfenv(chunk, {})  -- Use an empty environment to prevent access to potentially harmful functions
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



function inspect(table)
	if type(table) ~= 'table' then
		return "Not a table"
	end

	local str = ""
	for k, v in pairs(table) do
		local valueStr = type(v) == "table" and "table" or tostring(v)
		str = str .. tostring(k) .. ": " .. valueStr .. "\n"
	end

	return str
end

function inspectDepth(table, indent, depth)
	if depth and depth > 5 then  -- Limit the depth to avoid deep nesting
		return "Depth limit reached"
	end

	if type(table) ~= 'table' then  -- Ensure the object is a table
		return "Not a table"
	end

	local str = ""
	if not indent then indent = 0 end

	for k, v in pairs(table) do
		local formatting = string.rep("  ", indent) .. tostring(k) .. ": "
		if type(v) == "table" then
			str = str .. formatting .. "\n"
			str = str .. inspectDepth(v, indent + 1, (depth or 0) + 1)
		elseif type(v) == 'function' then
			str = str .. formatting .. "function\n"
		elseif type(v) == 'boolean' then
			str = str .. formatting .. tostring(v) .. "\n"
		else
			str = str .. formatting .. tostring(v) .. "\n"
		end
	end

	return str
end

function inspectFunction(func)
	if type(func) ~= 'function' then
		return "Not a function"
	end

	local info = debug.getinfo(func)
	local result = "Function Details:\n"

	if info.what == "Lua" then
		result = result .. "Defined in Lua\n"
	else
		result = result .. "Defined in C or precompiled\n"
	end

	result = result .. "Name: " .. (info.name or "anonymous") .. "\n"
	result = result .. "Source: " .. info.source .. "\n"
	result = result .. "Line Defined: " .. info.linedefined .. "\n"
	result = result .. "Last Line Defined: " .. info.lastlinedefined .. "\n"
	result = result .. "Number of Upvalues: " .. info.nups .. "\n"

	return result
end


local gameMainMenuRef = Game.main_menu
function Game.main_menu(arg_280_0, arg_280_1)
	gameMainMenuRef(arg_280_0, arg_280_1)
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
function Game.update(arg_298_0, arg_298_1)
	if G.STATE ~= G.STATES.SPLASH and G.MAIN_MENU_UI then
		local var_298_0 = G.MAIN_MENU_UI:get_UIE_by_ID("main_menu_play")

		if var_298_0 and not var_298_0.children.alert then
			var_298_0.children.alert = UIBox({
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
					major = var_298_0,
					parent = var_298_0
				}
			})
			var_298_0.children.alert.states.collide.can = false
		end
	end
	gameUpdateRef(arg_298_0, arg_298_1)
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

SMODS.customUIElements = {}

function SMODS.registerUIElement(modID, uiElements)
	SMODS.customUIElements[modID] = uiElements
end

function create_UIBox_mods(arg_736_0)
	local var_495_0 = 0.75  -- Scale factor for text
	local maxCharsPerLine = 50

	local wrappedDescription = wrapText(G.ACTIVE_MOD_UI.description, maxCharsPerLine)

	local authors = localize('b_author'.. (#G.ACTIVE_MOD_UI.author > 1 and 's' or '')) .. ': ' .. concatAuthors(G.ACTIVE_MOD_UI.author)

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
						tabs = {
							{
								label = G.ACTIVE_MOD_UI.name,
								chosen = true,
								tab_definition_function = function()
									local modNodes = {}


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
													scale = var_495_0 * 0.65,
													colour = G.C.BLUE,
												}
											}
										}
									})

									-- Mod description
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
													scale = var_495_0 * 0.5,
													colour = G.C.UI.TEXT_LIGHT
												}
											}
										}
									})

									local customUI = SMODS.customUIElements[G.ACTIVE_MOD_UI.id]
									if customUI then
										for _, uiElement in ipairs(customUI) do
											table.insert(modNodes, uiElement)
										end
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
							},
						}
					})
				}
			}
		}
	}))
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
	local col, text_col
	modInfo.should_enable = not modInfo.disabled
    if modInfo.can_load then
        col = G.C.BOOSTER
    elseif modInfo.disabled then
        col = G.C.UI.BACKGROUND_INACTIVE
    else
        col = mix_colours(G.C.RED, G.C.UI.BACKGROUND_INACTIVE, 0.7)
        text_col = G.C.TEXT_DARK
    end
	local but = UIBox_button {
        label = { " " .. modInfo.name .. " ", localize('b_by') .. concatAuthors(modInfo.author) .. " " },
        shadow = true,
        scale = scale,
        colour = col,
        text_colour = text_col,
        button = "openModUI_" .. modInfo.id,
        minh = 0.8,
        minw = 7
    }
    if modInfo.version ~= '0.0.0' then
		local function invert(c)
			return {1-c[1], 1-c[2], 1-c[3], c[4]}
		end
        table.insert(but.nodes[1].nodes[1].nodes, {
            n = G.UIT.T,
            config = {
                text = ('(%s)'):format(modInfo.version),
                scale = scale*0.8,
                colour = mix_colours(invert(col), G.C.UI.TEXT_INACTIVE, 0.8),
                shadow = true,
            },
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
							if NFS.getInfo(modInfo.path .. 'lovely') or NFS.getInfo(modInfo.path .. 'lovely.toml') then
								SMODS.full_restart = true
							else
								SMODS.partial_reload = true
							end
						else
							NFS.remove(modInfo.path .. '.lovelyignore')
							if NFS.getInfo(modInfo.path .. 'lovely') or NFS.getInfo(modInfo.path .. 'lovely.toml') then
								SMODS.full_restart = true
							else
								SMODS.partial_reload = true
							end
						end
					end
				)
			}),
    }}
	
end

function G.FUNCS.openModsDirectory(options)
    if not love.filesystem.exists("Mods") then
        love.filesystem.createDirectory("Mods")
    end

    love.system.openURL("file://"..love.filesystem.getSaveDirectory().."/Mods")
end

function G.FUNCS.mods_buttons_page(options)
    if not options or not options.cycle_config then
        return
    end
end

function G.FUNCS.exit_mods(e)
    if SMODS.full_restart then
		-- launch a new instance of the game and quit the current one
		SMODS.restart_game()
    elseif SMODS.partial_reload then
		-- re-initialize steamodded
        SMODS.reload()
    end
	G.FUNCS.exit_overlay_menu(e)
end

function create_UIBox_mods_button()
	local scale = 0.75
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
							{

								label = localize('b_steamodded_credits'),
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
                                label = localize('b_steamodded_settings'),
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
												label = localize('b_disable_mod_badges')
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

function G.FUNCS.steamodded_github(arg_736_0)
	love.system.openURL("https://github.com/Steamopollys/Steamodded")
end

function G.FUNCS.mods_button(arg_736_0)
	G.SETTINGS.paused = true

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
	table.insert(menu.nodes[1].nodes[1].nodes, #menu.nodes[1].nodes[1].nodes + 1, modsButton)
	menu.nodes[1].nodes[1].config = {align = "cm", padding = 0.15, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK, mid = true}
	return(menu)
end

local create_UIBox_profile_buttonRef = create_UIBox_profile_button
function create_UIBox_profile_button()
	local profile_menu = create_UIBox_profile_buttonRef()
	profile_menu.nodes[1].config = {align = "cm", padding = 0.11, r = 0.1, emboss = 0.1, colour = G.C.L_BLACK}
	return(profile_menu)
end

-- Disable achievments and crash report upload
function initGlobals()
	G.F_NO_ACHIEVEMENTS = true
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
			updateFunction{cycle_config = {current_option = 1}}
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
	local currentPage, pageOptions, showingList = recalculateModsList(1)
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
									{
										n = G.UIT.T,
										config = {
											text = localize('b_mod_list'),
											shadow = true,
											scale = scale * 0.6,
											colour = G.C.UI.TEXT_LIGHT
										}
									}
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
        table.insert(modNodes, {
            n = G.UIT.R,
            config = {
                padding = 0,
                align = "cm",
            },
            nodes = {
                UIBox_button({
                    label = { localize('b_open_mods_dir') },
                    shadow = true,
                    scale = scale,
                    colour = G.C.BOOSTER,
                    button = "openModsDirectory",
                    minh = 0.8,
                    minw = 8
                })
            }
        })
    else
        local modCount = 0
		local id = 0
        for _, modInfo in ipairs(SMODS.mod_list) do
			if modCount >= modsPerPage then break end
            if not modInfo.can_load and not modInfo.disabled then
                id = id + 1
                if id >= startIndex and id <= endIndex then
                    table.insert(modNodes, createClickableModBox(modInfo, scale * 0.5))
                    modCount = modCount + 1
                end
            end
        end
        for _, modInfo in ipairs(SMODS.mod_list) do
			if modCount >= modsPerPage then break end
            if modInfo.can_load then
                id = id + 1
                if id >= startIndex and id <= endIndex then
                    table.insert(modNodes, createClickableModBox(modInfo, scale * 0.5))
                    modCount = modCount + 1
                end
            end
        end
		for _, modInfo in ipairs(SMODS.mod_list) do
			if modCount >= modsPerPage then break end
            if modInfo.disabled then
                id = id + 1
                if id >= startIndex and id <= endIndex then
                    table.insert(modNodes, createClickableModBox(modInfo, scale * 0.5))
                    modCount = modCount + 1
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

function SMODS.SAVE_UNLOCKS()
    boot_print_stage("Saving Unlocks")
	G:save_progress()
    -------------------------------------
    local TESTHELPER_unlocks = false and not _RELEASE_MODE
    -------------------------------------
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '') then
        love.filesystem.createDirectory(G.SETTINGS.profile ..
            '')
    end
    if not love.filesystem.getInfo(G.SETTINGS.profile .. '/' .. 'meta.jkr') then
        love.filesystem.append(
            G.SETTINGS.profile .. '/' .. 'meta.jkr', 'return {}')
    end

    convert_save_to_meta()

    local meta = STR_UNPACK(get_compressed(G.SETTINGS.profile .. '/' .. 'meta.jkr') or 'return {}')
    meta.unlocked = meta.unlocked or {}
    meta.discovered = meta.discovered or {}
    meta.alerted = meta.alerted or {}

    for k, v in pairs(G.P_CENTERS) do
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.unlocked = true; v.discovered = true; v.alerted = true
            end --REMOVE THIS
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) and meta.unlocked[k] then
                v.unlocked = true
            end
            if not v.unlocked and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^v_')) then
                G.P_LOCKED[#G.P_LOCKED + 1] = v
            end
            if not v.discovered and (string.find(k, '^j_') or string.find(k, '^b_') or string.find(k, '^e_') or string.find(k, '^c_') or string.find(k, '^p_') or string.find(k, '^v_')) and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] or v.set == 'Back' or v.start_alerted then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end

	table.sort(G.P_LOCKED, function (a, b) return a.order and b.order and a.order < b.order end)

	for k, v in pairs(G.P_BLINDS) do
        v.key = k
        if not v.wip and not v.demo then 
            if TESTHELPER_unlocks then v.discovered = true; v.alerted = true  end --REMOVE THIS
            if not v.discovered and meta.discovered[k] then 
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
	for k, v in pairs(G.P_TAGS) do
        v.key = k
        if not v.wip and not v.demo then 
            if TESTHELPER_unlocks then v.discovered = true; v.alerted = true  end --REMOVE THIS
            if not v.discovered and meta.discovered[k] then 
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then 
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
    for k, v in pairs(G.P_SEALS) do
        v.key = k
        if not v.wip and not v.demo then
            if TESTHELPER_unlocks then
                v.discovered = true; v.alerted = true
            end                                                                   --REMOVE THIS
            if not v.discovered and meta.discovered[k] then
                v.discovered = true
            end
            if v.discovered and meta.alerted[k] then
                v.alerted = true
            elseif v.discovered then
                v.alerted = false
            end
        end
    end
end

function SMODS.process_loc_text(ref_table, ref_value, loc_txt, key)
    local target = (type(loc_txt) == 'table') and
    (loc_txt[G.SETTINGS.language] or loc_txt['default'] or loc_txt['en-us']) or loc_txt
    if key and (type(target) == 'table') then target = target[key] end
    if not (type(target) == 'string' or target and next(target)) then return end
    ref_table[ref_value] = target
end

function SMODS.handle_loc_file(path)
    local dir = path .. 'localization/'
	local file_name
    for k, v in ipairs({ dir .. G.SETTINGS.language .. '.lua', dir .. 'default.lua', dir .. 'en-us.lua' }) do
        if NFS.getInfo(v) then
            file_name = v
            break
        end
    end
    if not file_name then return end
    local loc_table = assert(loadstring(NFS.read(file_name)))()
    local function recurse(target, ref_table)
        if type(target) ~= 'table' then return end --this shouldn't happen unless there's a bad return value
        for k, v in pairs(target) do
            if not ref_table[k] or (type(v) ~= 'table') then
                ref_table[k] = v
            else
                recurse(v, ref_table[k])
            end
        end
    end
	recurse(loc_table, G.localization)
end

function SMODS.insert_pool(pool, center, replace)
	if replace == nil then replace = center.taken_ownership end
	if replace then
		for k, v in ipairs(pool) do
            if v.key == center.key then
                pool[k] = center
            end
		end
    else
		local prev_order = (pool[#pool] and pool[#pool].order) or 0
		if prev_order ~= nil then 
			center.order = prev_order + 1
		end
		table.insert(pool, center)
	end
end

function SMODS.remove_pool(pool, key)
    local j
    for i, v in ipairs(pool) do
        if v.key == key then j = i end
    end
    if j then return table.remove(pool, j) end
end

-- TODO
function SMODS.eval_effect_key(card, subeffect, key, percent)
end

function SMODS.eval_effect(card, effect, percent)
	if effect.chips then 
		if effect.card then juice_card(effect.card) end
		hand_chips = mod_chips(hand_chips + effect.chips)
		update_hand_text({delay = 0}, {chips = hand_chips})
		card_eval_status_text(card, 'chips', effect.chips, percent)
	end
	local mult_effect = effect.mult or effect.h_mult
	if mult_effect then 
		if effect.card then juice_card(effect.card) end
		mult = mod_mult(mult + mult_effect)
		update_hand_text({delay = 0}, {mult = mult})
		card_eval_status_text(card, 'mult', mult_effect, percent)
	end
	if effect.p_dollars then 
		if effect.card then juice_card(effect.card) end
		ease_dollars(effect.p_dollars)
		card_eval_status_text(card, 'dollars', effect.p_dollars, percent)
	end
	if effect.dollars then 
		if effect.card then juice_card(effect.card) end
		ease_dollars(effect.dollars)
		card_eval_status_text(card, 'dollars', effect.dollars, percent)
	end
	if effect.extra then 
		if effect.card then juice_card(effect.card) end
		local extras = {mult = false, hand_chips = false}
		if effect.extra.mult_mod then mult =mod_mult( mult + effect.extra.mult_mod);extras.mult = true end
		if effect.extra.chip_mod then hand_chips = mod_chips(hand_chips + effect.extra.chip_mod);extras.hand_chips = true end
		if effect.extra.swap then 
			local old_mult = mult
			mult = mod_mult(hand_chips)
			hand_chips = mod_chips(old_mult)
			extras.hand_chips = true; extras.mult = true
		end
		if effect.extra.func then effect.extra.func() end
		update_hand_text({delay = 0}, {chips = extras.hand_chips and hand_chips, mult = extras.mult and mult})
		card_eval_status_text(card, 'extra', nil, percent, nil, effect.extra)
	end
	if effect.x_mult then 
		if effect.card then juice_card(effect.card) end
		mult = mod_mult(mult*effect.x_mult)
		update_hand_text({delay = 0}, {mult = mult})
		card_eval_status_text(card, 'x_mult', effect.x_mult, percent)
	end
	if effect.message then

		if effect.card then juice_card(effect.card) end
		card_eval_status_text(card, 'extra', nil, percent, nil, effect)
	end
	local chips_effect = effect.edition.chips or effect.edition.chip_mod
	if chips_effect then
	end
	if effect.edition then
		local chips_effect = effect.edition.chips or effect.edition.chip_mod
		local mult_effect = effect.edition.mult or effect.edition.mult_mod
		local x_mult_effect = effect.edition.x_mult or effect.edition.x_mult_mod
		hand_chips = mod_chips(hand_chips + (chips_effect or 0))
		mult = mult + (mult_effect or 0)
		mult = mod_mult(mult*(x_mult_effect or 1))
		update_hand_text({delay = 0}, {
			chips = chips_effect and hand_chips or nil,
			mult = (mult_effect or x_mult_effect) and mult or nil,
		})
		card_eval_status_text(card, 'extra', nil, percent, nil, {
			message = (chips_effect and localize{type='variable',key='a_chips',vars={chips_effect}}) or
					(mult_effect and localize{type='variable',key='a_mult',vars={mult_effect}}) or
					(x_mult_effect and localize{type='variable',key='a_xmult',vars={x_mult_effect}}),
			chip_mod =  chips_effect,
			mult_mod =  mult_effect,
			x_mult_mod =  x_mult_effect,
			colour = G.C.DARK_EDITION,
			edition = true})
	end
	if effect.jokers then
        local extras = { mult = false, hand_chips = false }
		local mult_effect =  effect.jokers.mult or effect.jokers.mult_mod
        if mult_effect then
            mult = mod_mult(mult + mult_effect); extras.mult = true
        end
		local chips_effect = effect.jokers.chips or effect.jokers.chips_mod
        if chips_effect then
            hand_chips = mod_chips(hand_chips + chips_effect); extras.hand_chips = true
        end
		local x_mult_effect = effect.jokers.x_mult or effect.jokers.Xmult_mod
        if x_mult_effect then
            mult = mod_mult(mult * x_mult_effect); extras.mult = true
        end
        update_hand_text({ delay = 0 }, { chips = extras.hand_chips and hand_chips, mult = extras.mult and mult })
        if effect.message then
            card_eval_status_text(effect.card, 'jokers', nil, percent, nil, effect)
        end
    end
end
-- legacy function, don't use
function SMODS.eval_this(card, effect)
	sendWarnMessage("SMODS.eval_this is a legacy function, use SMODS.eval_effect instead")
    return SMODS.eval_effect(card, {jokers = effect})
end

-- Return an array of all (non-debuffed) jokers or consumables with key `key`.
-- Debuffed jokers count if `count_debuffed` is true.
-- This function replaces find_joker(); please use SMODS.find_card() instead
-- to avoid name conflicts with other mods.
function SMODS.find_card(key, count_debuffed)
	local results = {}
	if not G.jokers or not G.jokers.cards then return {} end
	for k, v in pairs(G.jokers.cards) do
	  if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
		table.insert(results, v)
	  end
	end
	for k, v in pairs(G.consumeables.cards) do
	  if v and type(v) == 'table' and v.config.center.key == key and (count_debuffed or not v.debuff) then
		table.insert(results, v)
	  end
	end
	return results
end

function SMODS.init_settings()
    SMODS.SETTINGS = {
        no_mod_badges = false,
    }
end

function SMODS.reload()
    local lfs = love.filesystem
    local function recurse(dir)
        local files = lfs.getDirectoryItems(dir)
        for i, v in ipairs(files) do
            local file = (dir == '') and v or (dir .. '/' .. v)
            sendTraceMessage(file)
            if v == 'Mods' or v:len() == 1 then
                -- exclude save files
            elseif lfs.isFile(file) then
                lua_reload.ReloadFile(file)
            elseif lfs.isDirectory(file) then
                recurse(file)
            end
        end
    end
    recurse('')
    SMODS.booted = false
    G:init_item_prototypes()
    initSteamodded()
end

function SMODS.restart_game()
	if love.system.getOS() ~= 'OS X' then
		love.system.openURL('steam://rungameid/2379780')
	else
		os.execute('sh "/Users/$USER/Library/Application Support/Steam/steamapps/common/Balatro/run_lovely.sh" &')
	end
	love.event.quit()
end

function SMODS.create_mod_badges(obj, badges)
    if not G.SETTINGS.no_mod_badges and obj and obj.mod and obj.mod.display_name and not obj.no_mod_badges then
        local mods = {}
        badges.mod_set = badges.mod_set or {}
        if not badges.mod_set[obj.mod.id] and not obj.no_main_mod_badge then table.insert(mods, obj.mod) end
        badges.mod_set[obj.mod.id] = true
        if obj.dependencies then
            for _, v in ipairs(obj.dependencies) do
                local m = SMODS.Mods[v]
                if not badges.mod_set[m.id] then
                    table.insert(mods, m)
                    badges.mod_set[m.id] = true
                end
            end
        end
        for i, mod in ipairs(mods) do
            local mod_name = string.sub(mod.display_name, 1, 16)
            local len = string.len(mod_name)
            local size = 0.9 - (len > 6 and 0.02 * (len - 6) or 0)
            badges[#badges + 1] = create_badge(mod_name, mod.badge_colour or G.C.UI.BACKGROUND_INACTIVE, nil, size)
        end
    end
end

function SMODS.create_loc_dump()
    local _old, _new = SMODS.dump_loc.pre_inject, G.localization
    local _dump = {}
    local function recurse(old, new, dump)
        for k, _ in pairs(new) do
            if type(new[k]) == 'table' then
                dump[k] = {}
                if not old[k] then
                    dump[k] = new[k]
                else
                    recurse(old[k], new[k], dump[k])
                end
            elseif old[k] ~= new[k] then
                dump[k] = new[k]
            end
        end
    end
    recurse(_old, _new, _dump)
    local function cleanup(dump)
        for k, v in pairs(dump) do
            if type(v) == 'table' then
                cleanup(v)
                if not next(v) then dump[k] = nil end
            end
        end
    end
    cleanup(_dump)
    local str = 'return ' .. serialize(_dump)
	NFS.createDirectory(SMODS.dump_loc.path..'localization/')
	NFS.write(SMODS.dump_loc.path..'localization/dump.lua', str)
end

function serialize(t, indent)
    indent = indent or ''
    local str = '{\n'
	for k, v in ipairs(t) do
        str = str .. indent .. '\t'
		if type(v) == 'number' then
            str = str .. v
        elseif type(v) == 'string' then
            str = str .. serialize_string(v)
        elseif type(v) == 'table' then
            str = str .. serialize(v, indent .. '\t')
        else
            assert(false)
        end
		str = str .. ',\n'
	end
    for k, v in pairs(t) do
		if type(k) == 'string' then
        	str = str .. indent .. '\t' .. '[' .. serialize_string(k) .. '] = '
			if type(v) == 'number' then
				str = str .. v
			elseif type(v) == 'string' then
				str = str .. serialize_string(v)
			elseif type(v) == 'table' then
				str = str .. serialize(v, indent .. '\t')
			else
				assert(false)
			end
			str = str .. ',\n'
		end
    end
    str = str .. indent .. '}'
	return str
end

function serialize_string(s)
	return string.format("%q", s)
end

----------------------------------------------
------------MOD CORE END----------------------
