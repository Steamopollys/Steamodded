----------------------------------------------
------------MOD CORE API DECK-----------------

SMODS.Decks = {}
SMODS.Deck = {name = "", slug = "", config = {}, spritePos = {}, unlocked = true, discovered = true}

function SMODS.Deck:new(name, slug, config, spritePos, unlocked, discovered)
	o = {}
	setmetatable(o, self)
	self.__index = self

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
	local minId = 4
	local id = 0
	local replacedId = ""
	local replacedName = ""

	for i, deck in ipairs(SMODS.Decks) do
		-- Prepare some Datas
		id = i + minId - 1
		replacedId = G.BACKS.IDS[id]
		replacedName = G.BACKS.NAMES[id]

		-- Start by deleting placeholder values
		G.P_CENTERS[replacedId] = nil
		G.BACKS.NAME_TO_POS[replacedName] = nil
		G.BACKS.ID_TO_POS[replacedId] = nil

		-- Now we replace the others
		G.P_CENTERS[deck.slug] = {
			discovered = deck.discovered,
			name = deck.name,
			set = "Back",
			unlocked = deck.unlocked,
			order = id,
			pos = deck.spritePos,
			config = deck.config
		}
		G.BACKS.IDS[id] = deck.slug
		G.BACKS.NAMES[id] = deck.name
		G.BACKS.NAME_TO_POS[deck.name] = id
		G.BACKS.ID_TO_POS[deck.slug] = id
		G.BACKS.UNLOCKED_NAMES[id] = deck.name
		G.BACKS.AVAILABLE_NAMES[id] = deck.name

		sendDebugMessage("The Deck named " .. deck.name .. " with the slug " .. deck.slug .. " have been registered at the id " .. id .. ".")
	end
end

----------------------------------------------
------------MOD CORE API DECK END-------------