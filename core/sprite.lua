----------------------------------------------
------------MOD CORE API SPRITE---------------


-- Original Code by MathIsFun_
-- A proper ressources handler will be created later
function add_sprite_atlas(px, py, name, path)
	local newAtlas = {
		px = px,
		name = name,
		py = py,
		path = path
	}
	G.ASSET_ATLAS[newAtlas.name] = {}
	G.ASSET_ATLAS[newAtlas.name].name = newAtlas.name
	G.ASSET_ATLAS[newAtlas.name].image = love.graphics.newImage(newAtlas.path, {
		mipmaps = true,
		dpiscale = G.SETTINGS.GRAPHICS.texture_scaling
	})
	G.ASSET_ATLAS[newAtlas.name].type = newAtlas.type
	G.ASSET_ATLAS[newAtlas.name].px = newAtlas.px
	G.ASSET_ATLAS[newAtlas.name].py = newAtlas.py
end

-- Original Code by MathIsFun_
-- It replace the game function, will be made modular later 
function Card.set_sprites(arg_865_0, arg_865_1, arg_865_2)
	if arg_865_2 then
		if arg_865_0.children.front then
			arg_865_0.children.front.atlas = G.ASSET_ATLAS[arg_865_2.atlas] or G.ASSET_ATLAS.cards
			
			arg_865_0.children.front:set_sprite_pos(arg_865_0.config.card.pos)
		else
			if arg_865_0.config.card.pos.atlas then
				arg_865_0.children.front = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, arg_865_2.atlas and G.ASSET_ATLAS[arg_865_0.config.card.pos.atlas], arg_865_0.config.card.pos)
			else
				arg_865_0.children.front = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, arg_865_2.atlas and G.ASSET_ATLAS[arg_865_2.atlas] or G.ASSET_ATLAS.cards, arg_865_0.config.card.pos)
			end
			arg_865_0.children.front.states.hover = arg_865_0.states.hover
			arg_865_0.children.front.states.click = arg_865_0.states.click
			arg_865_0.children.front.states.drag = arg_865_0.states.drag
			arg_865_0.children.front.states.collide.can = false
			
			arg_865_0.children.front:set_role({
				role_type = "Minor",
				major = arg_865_0,
				draw_major = arg_865_0
			})
		end
	end
	
	if arg_865_1 then
		if arg_865_1.set then
			if arg_865_0.children.center then
				if arg_865_0.config.center.pos.atlas then
					arg_865_0.children.center.atlas = G.ASSET_ATLAS[arg_865_0.config.center.pos.atlas]
				else
					arg_865_0.children.center.atlas = G.ASSET_ATLAS[arg_865_1.atlas or not (arg_865_1.set ~= "Joker" and not arg_865_1.consumeable and arg_865_1.set ~= "Voucher") and arg_865_1.set or "centers"]
				end
				arg_865_0.children.center:set_sprite_pos(arg_865_0.config.center.pos)
			else
				if arg_865_0.config.center.pos.atlas then
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS[arg_865_0.config.center.pos.atlas], arg_865_0.config.center.pos)
				elseif arg_865_1.set == "Joker" and not arg_865_1.unlocked and not arg_865_0.params.bypass_discovery_center then
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS.Joker, G.j_locked.pos)
				elseif arg_865_0.config.center.set == "Voucher" and not arg_865_0.config.center.unlocked and not arg_865_0.params.bypass_discovery_center then
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS.Voucher, G.v_locked.pos)
				elseif arg_865_0.config.center.consumeable and arg_865_0.config.center.demo then
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS.Tarot, G.c_locked.pos)
				elseif not arg_865_0.params.bypass_discovery_center and (arg_865_1.set == "Edition" or arg_865_1.set == "Joker" or arg_865_1.consumeable or arg_865_1.set == "Voucher" or arg_865_1.set == "Booster") and not arg_865_1.discovered then
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS[arg_865_1.atlas or arg_865_1.set], arg_865_1.set == "Joker" and G.j_undiscovered.pos or arg_865_1.set == "Edition" and G.j_undiscovered.pos or arg_865_1.set == "Tarot" and G.t_undiscovered.pos or arg_865_1.set == "Planet" and G.p_undiscovered.pos or arg_865_1.set == "Spectral" and G.s_undiscovered.pos or arg_865_1.set == "Voucher" and G.v_undiscovered.pos or arg_865_1.set == "Booster" and G.booster_undiscovered.pos)
				elseif arg_865_1.set == "Joker" or arg_865_1.consumeable or arg_865_1.set == "Voucher" then
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS[arg_865_1.set], arg_865_0.config.center.pos)
				else
					arg_865_0.children.center = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS[arg_865_1.atlas or "centers"], arg_865_0.config.center.pos)
				end
				
				arg_865_0.children.center.states.hover = arg_865_0.states.hover
				arg_865_0.children.center.states.click = arg_865_0.states.click
				arg_865_0.children.center.states.drag = arg_865_0.states.drag
				arg_865_0.children.center.states.collide.can = false
				
				arg_865_0.children.center:set_role({
					role_type = "Minor",
					major = arg_865_0,
					draw_major = arg_865_0
				})
			end
			
			if arg_865_1.name == "Half Joker" and (arg_865_1.discovered or arg_865_0.bypass_discovery_center) then
				arg_865_0.children.center.scale.y = arg_865_0.children.center.scale.y / 1.7
			end
		end
		
		if arg_865_1.soul_pos then
			arg_865_0.children.floating_sprite = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS.Joker, arg_865_0.config.center.soul_pos)
			arg_865_0.children.floating_sprite.role.draw_major = arg_865_0
			arg_865_0.children.floating_sprite.states.hover.can = false
			arg_865_0.children.floating_sprite.states.click.can = false
		end
		
		if not arg_865_0.children.back then
			arg_865_0.children.back = Sprite(arg_865_0.T.x, arg_865_0.T.y, arg_865_0.T.w, arg_865_0.T.h, G.ASSET_ATLAS.centers, arg_865_0.params.bypass_back or arg_865_0.playing_card and G.GAME[arg_865_0.back].pos or G.P_CENTERS.b_red.pos)
			arg_865_0.children.back.states.hover = arg_865_0.states.hover
			arg_865_0.children.back.states.click = arg_865_0.states.click
			arg_865_0.children.back.states.drag = arg_865_0.states.drag
			arg_865_0.children.back.states.collide.can = false
			
			arg_865_0.children.back:set_role({
				role_type = "Minor",
				major = arg_865_0,
				draw_major = arg_865_0
			})
		end
	end
end

----------------------------------------------
------------MOD CORE API SPRITE END-----------
