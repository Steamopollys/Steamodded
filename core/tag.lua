SMODS.Tags = {}
SMODS.Tag = {
	name = "",
	slug = "",
	config = {},
	pos = {},
	loc_txt = {},
	discovered = false,
	min_ante = nil
}

function SMODS.Tag:new(name, slug, config, pos, loc_txt, min_ante, discovered, atlas)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.loc_txt = loc_txt
	o.name = name
	o.slug = "tag_" .. slug
	o.config = config or {}
	o.pos = pos or {
		x = 0,
		y = 0
	}
	o.min_ante = min_ante or nil
	o.discovered = discovered or false
	o.atlas = atlas or "tags"
	o.mod_name = SMODS._MOD_NAME
	o.badge_colour = SMODS._BADGE_COLOUR
	return o
end

function SMODS.Tag:register()
	SMODS.Tags[self.slug] = self
	local minId = table_length(G.P_CENTER_POOLS['Tag']) + 1
	local id = 0
	local i = 0

	i = i + 1
	id = i + minId
	local tag_obj = {
		discovered = self.discovered,
		name = self.name,
		set = "Tag",
		order = id,
		key = self.slug,
		pos = self.pos,
		config = self.config,
		min_ante = self.min_ante,
		atlas = self.atlas,
		mod_name = self.mod_name,
		badge_colour = self.badge_colour
	}

	for _i, sprite in ipairs(SMODS.Sprites) do
		if sprite.name == tag_obj.key then
			tag_obj.atlas = sprite.name
		end
	end

	G.P_TAGS[self.slug] = tag_obj
	table.insert(G.P_CENTER_POOLS['Tag'], tag_obj)

	G.localization.descriptions["Tag"][self.slug] = self.loc_txt

end

local tag_generate_UIref = Tag.generate_UI
function Tag:generate_UI(_size)
    _size = _size or 0.8

    local tag_sprite_tab = nil

    local tag_sprite = Sprite(0,0,_size*1,_size*1,G.ASSET_ATLAS[(not self.hide_ability) and G.P_TAGS[self.key].atlas or "tags"], (self.hide_ability) and G.tag_undiscovered.pos or self.pos)
    tag_sprite.T.scale = 1
    tag_sprite_tab = {n= G.UIT.C, config={align = "cm", ref_table = self, group = self.tally}, nodes={
        {n=G.UIT.O, config={w=_size*1,h=_size*1, colour = G.C.BLUE, object = tag_sprite, focus_with_object = true}},
    }}
    tag_sprite:define_draw_steps({
        {shader = 'dissolve', shadow_height = 0.05},
        {shader = 'dissolve'},
    })
    tag_sprite.float = true
    tag_sprite.states.hover.can = true
    tag_sprite.states.drag.can = false
    tag_sprite.states.collide.can = true
    tag_sprite.config = {tag = self, force_focus = true}

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

                self:get_uibox_table(tag_sprite)
                _self.config.h_popup =  G.UIDEF.card_h_popup(_self)
                _self.config.h_popup_config ={align = 'cl', offset = {x=-0.1,y=0},parent = _self}
                Node.hover(_self)
                if _self.children.alert then 
                    _self.children.alert:remove()
                    _self.children.alert = nil
                    if self.key and G.P_TAGS[self.key] then G.P_TAGS[self.key].alerted = true end
                    G:save_progress()
                end
            end
        end
    end
    tag_sprite.stop_hover = function(_self) _self.hovering = false; Node.stop_hover(_self); _self.hover_tilt = 0 end

    tag_sprite:juice_up()
    self.tag_sprite = tag_sprite

    return tag_sprite_tab, tag_sprite
end

function create_UIBox_your_collection_tags()
	local tag_matrix = {}

	local counter = 0

	local tag_tab = {}
	for k, v in pairs(G.P_TAGS) do
		counter = counter + 1
	  	tag_tab[#tag_tab+1] = v
	end
  
	for i = 1, math.ceil(counter / 6) do
		table.insert(tag_matrix, {})
	end

	table.sort(tag_tab, function (a, b) return a.order < b.order end)
  
	local tags_to_be_alerted = {}
	for k, v in ipairs(tag_tab) do
	  local discovered = v.discovered
	  local temp_tag = Tag(v.key, true)
	  if not v.discovered then temp_tag.hide_ability = true end
	  local temp_tag_ui, temp_tag_sprite = temp_tag:generate_UI()
	  tag_matrix[math.ceil((k-1)/6+0.001)][1+((k-1)%6)] = {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
		temp_tag_ui,
	  }}
	  if discovered and not v.alerted then 
		tags_to_be_alerted[#tags_to_be_alerted+1] = temp_tag_sprite
	  end
	end
  
	G.E_MANAGER:add_event(Event({
	  trigger = 'immediate',
	  func = (function()
		  for _, v in ipairs(tags_to_be_alerted) do
			v.children.alert = UIBox{
			  definition = create_UIBox_card_alert(), 
			  config = { align="tri", offset = {x = 0.1, y = 0.1}, parent = v}
			}
			v.children.alert.states.collide.can = false
		  end
		  return true
	  end)
	}))
  
	table_nodes = {}
	for i = 1, math.ceil(counter / 6) do
		table.insert(table_nodes, {n=G.UIT.R, config={align = "cm"}, nodes=tag_matrix[i]})
	end

	local t = create_UIBox_generic_options({ back_func = 'your_collection', contents = {
	  {n=G.UIT.C, config={align = "cm", r = 0.1, colour = G.C.BLACK, padding = 0.1, emboss = 0.05}, nodes={
		{n=G.UIT.C, config={align = "cm"}, nodes={
		  {n=G.UIT.R, config={align = "cm"}, nodes=table_nodes}
		}} 
	  }}  
	}})
	return t
end



local apply_to_runref = Tag.apply_to_run
function Tag:apply_to_run(_context)
	local ret_val = apply_to_runref(self, _context)
	if not self.triggered and self.config.type == _context.type then
		local key = self.key
        local tag_obj = SMODS.Tags[key]
        if tag_obj and tag_obj.apply and type(tag_obj.apply) == "function" then
            local o = tag_obj.apply(self, _context)
            if o then return o end
        end
	end

	return ret_val;
end