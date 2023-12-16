--- STEAMODDED HEADER
--- MOD_NAME: Five of a Flush
--- MOD_ID: FiveOfAFlush
--- MOD_AUTHOR: [MathIsFun_]
--- MOD_DESCRIPTION: Adds Balatro's most requested hand type.

----------------------------------------------
------------MOD CODE -------------------------

-- Adding 5oaf

function SMODS.INIT.FOAF()
	local foaf_mod = SMODS.findModByID("FiveOfAFlush")
	--Atlas
	local s_vulcan = SMODS.Sprite:new("fish", 71, 95,  foaf_mod.path .. "vulcan.png")
	s_vulcan:register()

	-- Adding Vulcan as its planet
	G.P_CENTERS.c_vulcan = {
		cost = 4,
		name = "Vulcan",
		freq = 1,
		effect = "Hand Upgrade",
		cost_mult = 1,
		discovered = true,
		consumeable = true,
		set = "Planet",
		order = 12,
		pos = {
			x = 0,
			y = 0,
			atlas = "fish"
		},
		config = {
			hand_type = "Five of a Flush",
			softlock = true
		}
	}

	--Localization
	G.localization.descriptions.Planet.c_vulcan = {
		name = "Vulcan",
		text = {
			"{S:0.8}({S:0.8,V:1}lvl.#1#{S:0.8}){} Level up",
			"{C:attention}#2#",
			"{C:mult}+#3#{} Mult and",
			"{C:chips}+#4#{} chips"
		}
	}

	--Update localization
	for iter_231_8, iter_231_9 in pairs(G.localization) do
		if iter_231_8 == "descriptions" then
			for iter_231_10, iter_231_11 in pairs(iter_231_9) do
				for iter_231_12, iter_231_13 in pairs(iter_231_11) do
					iter_231_13.text_parsed = {}
					
					for iter_231_14, iter_231_15 in ipairs(iter_231_13.text) do
						iter_231_13.text_parsed[#iter_231_13.text_parsed + 1] = loc_parse_string(iter_231_15)
					end
					
					iter_231_13.name_parsed = {}
					
					for iter_231_16, iter_231_17 in ipairs(type(iter_231_13.name) == "table" and iter_231_13.name or {
						iter_231_13.name
					}) do
						iter_231_13.name_parsed[#iter_231_13.name_parsed + 1] = loc_parse_string(iter_231_17)
					end
					
					if iter_231_13.unlock then
						iter_231_13.unlock_parsed = {}
						
						for iter_231_18, iter_231_19 in ipairs(iter_231_13.unlock) do
							iter_231_13.unlock_parsed[#iter_231_13.unlock_parsed + 1] = loc_parse_string(iter_231_19)
						end
					end
				end
			end
		end
	end

	-- Update tables
	G.P_CENTER_POOLS.Planet = {}

	for iter_236_8, iter_236_9 in pairs(G.P_CENTERS) do
		iter_236_9.key = iter_236_8
		
		if iter_236_9.set == "Planet" then
			table.insert(G.P_CENTER_POOLS.Planet, iter_236_9)
		end
	end

	table.sort(G.P_CENTER_POOLS.Planet, function(arg_238_0, arg_238_1)
		return arg_238_0.order < arg_238_1.order
	end)

	-- load other Files of the Mod
	assert(load(love.filesystem.read(foaf_mod.path .. "FOAF_ops.lua")))()
end


----------------------------------------------
------------MOD CODE END----------------------