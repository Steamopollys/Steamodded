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

        sendDebugMessage("The Deck named " ..
        deck.name .. " with the slug " .. deck.slug .. " have been registered at the id " .. id .. ".")
    end
end

local back_initref = Back.init;
function Back:init(selected_back)
	back_initref(self, selected_back)
	self.atlas = "centers"
    if self.effect.center.config.atlas then
        self.atlas = self.effect.center.config.atlas
    end
end

local back_changetoref = Back.change_to;
function Back:change_to(new_back)
	back_changetoref(self, new_back)
	self.atlas = "centers"
    if new_back.config.atlas then
        self.atlas = new_back.config.atlas
    end
end

local change_viewed_backref = G.FUNCS.change_viewed_back
G.FUNCS.change_viewed_back = function(args)
	change_viewed_backref(args)
	
	for key, val in pairs(G.sticker_card.area.cards) do
		val.children.back = false
		val:set_ability(val.config.center, true)
	  end
end

local set_spritesref = Card.set_sprites;
function Card:set_sprites(_center, _front)
	if _center then 
		if not self.children.back then
            local atlas_id = "centers"

			if G.GAME.selected_back then
                if G.GAME.selected_back.atlas then
                    atlas_id = G.GAME.selected_back.atlas
                end
            end

            if G.GAME.viewed_back and G.GAME.viewed_back ~= G.GAME.selected_back then
                if G.GAME.viewed_back.atlas then
                    atlas_id = G.GAME.viewed_back.atlas
                end
                
            end
			
            self.children.back = Sprite(self.T.x, self.T.y, self.T.w, self.T.h, G.ASSET_ATLAS[atlas_id], self.params.bypass_back or (self.playing_card and G.GAME[self.back].pos or G.P_CENTERS['b_red'].pos))
            atlas_id = "centers"
            self.children.back.states.hover = self.states.hover
            self.children.back.states.click = self.states.click
            self.children.back.states.drag = self.states.drag
            self.children.back.states.collide.can = false
            self.children.back:set_role({major = self, role_type = 'Glued', draw_major = self})
        end
	end

	set_spritesref(self, _center, _front);
end

----------------------------------------------
------------MOD CORE API DECK END-------------