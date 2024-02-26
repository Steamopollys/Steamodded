----------------------------------------------
------------MOD CORE--------------------------

SMODS = {}

MODDED_VERSION = "0.6.2-STEAMODDED"

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
					text = "Modded Version!",
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
	return authors or "Unknown"
end




function create_UIBox_mods(arg_736_0)
	local var_495_0 = 0.75  -- Scale factor for text
	local maxCharsPerLine = 50

	local wrappedDescription = wrapText(G.ACTIVE_MOD_UI.description, maxCharsPerLine)

	local authors = "Author" .. (#G.ACTIVE_MOD_UI.author > 1 and "s: " or ": ") .. concatAuthors(G.ACTIVE_MOD_UI.author)

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




-- Helper function to create a clickable mod box
local function createClickableModBox(modInfo, scale)
	return {
		n = G.UIT.R,
		config = {
			padding = 0,
			align = "cm",
		},
		nodes = {
			UIBox_button({
				label = {" " .. modInfo.name .. " ", " By: " .. concatAuthors(modInfo.author) .. " "},
				shadow = true,
				scale = scale,
				colour = G.C.BOOSTER,
				button = "openModUI_" .. modInfo.id,
				minh = 0.8,
				minw = 8
			})
		}
	}
end

local function initializeModUIFunctions()
	for id, modInfo in pairs(SMODS.MODS) do
		G.FUNCS["openModUI_" .. modInfo.id] = function(arg_736_0)
			G.ACTIVE_MOD_UI = modInfo
			G.FUNCS.overlay_menu({
				definition = create_UIBox_mods(arg_736_0)
			})
		end
	end
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

function create_UIBox_mods_button()
	local var_495_0 = 0.75

	return (create_UIBox_generic_options({
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
								label = "Mods",
								chosen = true,
								tab_definition_function = function()
									local modNodes = {}

									-- Iterate over each mod in S.MODS and create a clickable UI node for it
									for id, modInfo in pairs(SMODS.MODS) do
										table.insert(modNodes, createClickableModBox(modInfo, var_495_0 * 0.5))
									end

									-- If no mods are loaded, show a default message
									if #modNodes == 0 then
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
														text = "No mods have been detected...",
														shadow = true,
														scale = var_495_0 * 0.5,
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
                                                    label = {"Open Mods directory"},
                                                    shadow = true,
                                                    scale = scale,
                                                    colour = G.C.BOOSTER,
                                                    button = "openModsDirectory",
                                                    minh = 0.8,
                                                    minw = 8
                                                })
                                            }
                                        })
									end

									return {
										n = G.UIT.ROOT,
										config = {
											emboss = 0.05,
											minh = 6,
											r = 0.1,
											minw = 10,
											align = "tm",
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
															text = "List of Activated Mods",
															shadow = true,
															scale = var_495_0 * 0.6,
															colour = G.C.UI.TEXT_LIGHT
														}
													}
												}
											},
											{
												n = G.UIT.R,
												config = {
													r = 0.1,
													align = "cm",
													padding = 0.2,
												},
												nodes = modNodes
											},
										}
									}
								end
							},
							{

								label = " Steamodded Credits ",
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
															text = "Mod Loader",
															shadow = true,
															scale = var_495_0 * 0.8,
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
															text = "developed by ",
															shadow = true,
															scale = var_495_0 * 0.8,
															colour = G.C.UI.TEXT_LIGHT
														}
													},
													{
														n = G.UIT.T,
														config = {
															text = "Steamo",
															shadow = true,
															scale = var_495_0 * 0.8,
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
														label = {
															"Github Project"
														}
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
															text = "You can report any bugs there !",
															shadow = true,
															scale = var_495_0 * 0.5,
															colour = G.C.UI.TEXT_LIGHT
														}
													}
												}
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
		label = {"MODS"},
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

-- Function to find a mod by its ID
function SMODS.findModByID(modID)
    for _, mod in pairs(SMODS.MODS) do
        if mod.id == modID then
            return mod
        end
    end
    return nil  -- Return nil if no mod is found with the given ID
end

-- Disable achievments and crash report upload
function initGlobals()
	G.F_NO_ACHIEVEMENTS = true
	G.F_CRASH_REPORTS = false
end

----------------------------------------------
------------MOD CORE END----------------------