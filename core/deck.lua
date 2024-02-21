----------------------------------------------
------------MOD CORE API DECK-----------------

SMODS.Decks = {}
SMODS.Deck = {name = "", slug = "", config = {}, spritePos = {}, loc_txt = {}, unlocked = true, discovered = true}

function SMODS.Deck:new(name, slug, config, spritePos, loc_txt, unlocked, discovered)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.loc_txt = loc_txt
	o.name = name
	o.slug = "b_" .. slug
	o.config = config or {}
	o.spritePos = spritePos or {x = 0, y = 0}
	o.unlocked = unlocked or true
	o.discovered = discovered or true

	return o
end

--[[ local Backgenerate_UIRef = Back.generate_UI
function SMODS.Deck:createUI()
	Back.generate_UI = function(arg_53_0, arg_53_1, arg_53_2, arg_53_3)
	end
end ]]

function SMODS.Deck:register()
	if not SMODS.Decks[self] then
		table.insert(SMODS.Decks, self)
	end
end

function SMODS.injectDecks()
	local minId = 17
	local id = 0
	local replacedId = ""
	local replacedName = ""

	for i, deck in ipairs(SMODS.Decks) do
		-- Prepare some Datas
		id = i + minId - 1

		local deck_obj = {
			stake = 1,
			key = deck.slug,
			discovered = deck.discovered,
			alerted = true,
			name = deck.name,
			set = "Back",
			unlocked = deck.unlocked,
			order = id - 1,
			pos = deck.spritePos,
			config = deck.config
		}
		-- Now we replace the others
		G.P_CENTERS[deck.slug] = deck_obj
		G.P_CENTER_POOLS.Back[id - 1] = deck_obj

		-- Setup Localize text
		G.localization.descriptions["Back"][deck.slug] = deck.loc_txt

		-- Load it
		for g_k, group in pairs(G.localization) do
			if g_k == 'descriptions' then
			  for _, set in pairs(group) do
				for _, center in pairs(set) do
				  center.text_parsed = {}
				  for _, line in ipairs(center.text) do
					center.text_parsed[#center.text_parsed+1] = loc_parse_string(line)
				  end
				  center.name_parsed = {}
				  for _, line in ipairs(type(center.name) == 'table' and center.name or {center.name}) do
					center.name_parsed[#center.name_parsed+1] = loc_parse_string(line)
				  end
				  if center.unlock then
					center.unlock_parsed = {}
					for _, line in ipairs(center.unlock) do
					  center.unlock_parsed[#center.unlock_parsed+1] = loc_parse_string(line)
					end
				  end
				end
			  end
			end
		  end

		sendDebugMessage("The Deck named " .. deck.name .. " with the slug " .. deck.slug .. " have been registered at the id " .. id .. ".")
	end
end

----------------------------------------------
------------MOD CORE API DECK END-------------