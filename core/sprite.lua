-- ----------------------------------------------
-- ------------MOD CORE API SPRITE---------------


-- BASE REFERENCES FROM MAIN GAME
-- G.animation_atli = {
--     {name = "blind_chips", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/BlindChips.png",px=34,py=34, frames = 21},
--     {name = "shop_sign", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/ShopSignAnimation.png",px=113,py=57, frames = 4}
-- }
-- G.asset_atli = {
--     {name = "cards_1", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/8BitDeck.png",px=71,py=95},
--     {name = "cards_2", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/8BitDeck_opt2.png",px=71,py=95},
--     {name = "centers", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/Enhancers.png",px=71,py=95},
--     {name = "Joker", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/Jokers.png",px=71,py=95},
--     {name = "Tarot", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/Tarots.png",px=71,py=95},
--     {name = "Voucher", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/Vouchers.png",px=71,py=95},
--     {name = "Booster", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/boosters.png",px=71,py=95},
--     {name = "ui_1", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/ui_assets.png",px=18,py=18},
--     {name = "ui_2", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/ui_assets_opt2.png",px=18,py=18},
--     {name = "balatro", path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/balatro.png",px=333,py=216},        
--     {name = 'gamepad_ui', path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/gamepad_ui.png",px=32,py=32},
--     {name = 'icons', path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/icons.png",px=66,py=66},
--     {name = 'tags', path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/tags.png",px=34,py=34},
--     {name = 'stickers', path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/stickers.png",px=71,py=95},
--     {name = 'chips', path = "resources/textures/"..self.SETTINGS.GRAPHICS.texture_scaling.."x/chips.png",px=29,py=29}
-- }
-- G.asset_images = {
--     {name = "playstack_logo", path = "resources/textures/1x/playstack-logo.png", px=1417,py=1417},
--     {name = "localthunk_logo", path = "resources/textures/1x/localthunk-logo.png", px=1390,py=560}
-- }

SMODS.Sprites = {}
SMODS.Sprite = {name = "", top_lpath = "", path = "", px = 0, py = 0, type = "", frames = 0}

function SMODS.Sprite:new(name, top_lpath, path, px, py, type, frames)
	o = {}
	setmetatable(o, self)
	self.__index = self

	o.name = name
    o.top_lpath = top_lpath .. "assets/"
	o.path = path
	o.px = px
	o.py = py
    if type == "animation_atli" then
        o.frames = frames
        o.type = type
    elseif type == "asset_atli" or type == "asset_images" then
        o.type = type
    else
        error("Bad Sprite type")
    end

	return o
end

function SMODS.Sprite:register()
	if not SMODS.Sprites[self] then
		table.insert(SMODS.Sprites, self)
	end
end

function SMODS.injectSprites()

	for i, sprite in ipairs(SMODS.Sprites) do
        local foundAndReplaced = false

		if sprite.type == "animation_atli" then
            for i, asset in ipairs(G.animation_atli) do
                if asset.name == sprite.name then
                    G.animation_atli[i] = {name = sprite.name, path = sprite.top_lpath .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. sprite.path, px = sprite.px, py = sprite.py , frames = sprite.frames}
                    foundAndReplaced = true
                    break
                end
            end
            if foundAndReplaced ~= true then
                table.insert(G.animation_atli, {name = sprite.name, path = sprite.top_lpath .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. sprite.path, px = sprite.px, py = sprite.py , frames = sprite.frames})
            end
        elseif sprite.type == "asset_atli" then
            for i, asset in ipairs(G.asset_atli) do
                if asset.name == sprite.name then
                    G.asset_atli[i] = {name = sprite.name, path = sprite.top_lpath .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. sprite.path, px = sprite.px, py = sprite.py}
                    foundAndReplaced = true
                    break
                end
            end
            if foundAndReplaced ~= true then
                table.insert(G.asset_atli, {name = sprite.name, path = sprite.top_lpath .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. sprite.path, px = sprite.px, py = sprite.py})
            end
        elseif sprite.type == "asset_images" then
            for i, asset in ipairs(G.asset_images) do
                if asset.name == sprite.name then
                    G.asset_images[i] = {name = sprite.name, path = sprite.top_lpath .. '1x/' .. sprite.path, px = sprite.px, py = sprite.py}
                    foundAndReplaced = true
                    break
                end
            end
            if foundAndReplaced ~= true then
                table.insert(G.asset_images, {name = sprite.name, path = sprite.top_lpath .. '1x/' .. sprite.path, px = sprite.px, py = sprite.py})
            end
        else
            error("Bad Sprite type")
        end

        sendDebugMessage("The Sprite named " .. sprite.name .. " with path " .. sprite.path .. " have been registered.")
	end

    --Reload Textures
    
    G.SETTINGS.GRAPHICS.texture_scaling = G.SETTINGS.GRAPHICS.texture_scaling or 2

    --Set fiter to linear interpolation and nearest, best for pixel art
    love.graphics.setDefaultFilter(
        G.SETTINGS.GRAPHICS.texture_scaling == 1 and 'nearest' or 'linear',
        G.SETTINGS.GRAPHICS.texture_scaling == 1 and 'nearest' or 'linear', 1)

    --self.CANVAS = self.CANVAS or love.graphics.newCanvas(500, 500, {readable = true})
    love.graphics.setLineStyle("rough")

    for i=1, #G.animation_atli do
        G.ANIMATION_ATLAS[G.animation_atli[i].name] = {}
        G.ANIMATION_ATLAS[G.animation_atli[i].name].name = G.animation_atli[i].name
        local file_data = NFS.newFileData( G.animation_atli[i].path )
        if file_data then
            local image_data = love.image.newImageData(file_data)
            if image_data then
                G.ANIMATION_ATLAS[G.animation_atli[i].name].image = love.graphics.newImage(image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
            else
                G.ANIMATION_ATLAS[G.animation_atli[i].name].image = love.graphics.newImage(G.animation_atli[i].path, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
            end
        else
            G.ANIMATION_ATLAS[G.animation_atli[i].name].image = love.graphics.newImage(G.animation_atli[i].path, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
        end
        G.ANIMATION_ATLAS[G.animation_atli[i].name].px = G.animation_atli[i].px
        G.ANIMATION_ATLAS[G.animation_atli[i].name].py = G.animation_atli[i].py
        G.ANIMATION_ATLAS[G.animation_atli[i].name].frames = G.animation_atli[i].frames
    end

    for i=1, #G.asset_atli do
        G.ASSET_ATLAS[G.asset_atli[i].name] = {}
        G.ASSET_ATLAS[G.asset_atli[i].name].name = G.asset_atli[i].name
        local file_data = NFS.newFileData( G.asset_atli[i].path )
        if file_data then
            local image_data = love.image.newImageData(file_data)
            if image_data then
                G.ASSET_ATLAS[G.asset_atli[i].name].image = love.graphics.newImage(image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
            else
                G.ASSET_ATLAS[G.asset_atli[i].name].image = love.graphics.newImage(G.asset_atli[i].path, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
            end
        else
            G.ASSET_ATLAS[G.asset_atli[i].name].image = love.graphics.newImage(G.asset_atli[i].path, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
        end
        G.ASSET_ATLAS[G.asset_atli[i].name].type = G.asset_atli[i].type
        G.ASSET_ATLAS[G.asset_atli[i].name].px = G.asset_atli[i].px
        G.ASSET_ATLAS[G.asset_atli[i].name].py = G.asset_atli[i].py
    end

    for i=1, #G.asset_images do
        G.ASSET_ATLAS[G.asset_images[i].name] = {}
        G.ASSET_ATLAS[G.asset_images[i].name].name = G.asset_images[i].name
        local file_data = NFS.newFileData( G.asset_images[i].path )
        if file_data then
            local image_data = love.image.newImageData(file_data)
            if image_data then
                G.ASSET_ATLAS[G.asset_images[i].name].image = love.graphics.newImage(image_data, {mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling})
            else
                G.ASSET_ATLAS[G.asset_images[i].name].image = love.graphics.newImage(G.asset_images[i].path, {mipmaps = true, dpiscale = 1})
            end
        else
            G.ASSET_ATLAS[G.asset_images[i].name].image = love.graphics.newImage(G.asset_images[i].path, {mipmaps = true, dpiscale = 1})
        end
        G.ASSET_ATLAS[G.asset_images[i].name].type = G.asset_images[i].type
        G.ASSET_ATLAS[G.asset_images[i].name].px = G.asset_images[i].px
        G.ASSET_ATLAS[G.asset_images[i].name].py = G.asset_images[i].py
    end

    for _, v in pairs(G.I.SPRITE) do
        v:reset()
    end

    G.ASSET_ATLAS.Planet = G.ASSET_ATLAS.Tarot
    G.ASSET_ATLAS.Spectral = G.ASSET_ATLAS.Tarot

    sendDebugMessage("All the sprites have been loaded!")
end

gameset_render_settingsRef = Game.set_render_settings
function Game:set_render_settings()
    gameset_render_settingsRef(self)
    SMODS.injectSprites()
end

-- Allows Jokers to have custom atlases
local set_spritesref = Card.set_sprites
function Card:set_sprites(_center, _front)
    set_spritesref(self, _center, _front);
    if _center then
        if _center.set then
            if (_center.set == 'Joker' or _center.consumeable or _center.set == 'Voucher') and _center.atlas then
                if self.params.bypass_discovery_center or (_center.unlocked and _center.discovered) then
                    self.children.center.atlas = G.ASSET_ATLAS
                    [(_center.atlas or (_center.set == 'Joker' or _center.consumeable or _center.set == 'Voucher') and _center.set) or 'centers']
                    self.children.center:set_sprite_pos(_center.pos)
                    sendDebugMessage(inspect(self.children.center))
                elseif not _center.discovered then
                    self.children.center.atlas = G.ASSET_ATLAS[_center.set]
                    self.children.center:set_sprite_pos(
                    (_center.set == 'Joker' and G.j_undiscovered.pos) or 
                    (_center.set == 'Edition' and G.j_undiscovered.pos) or 
                    (_center.set == 'Tarot' and G.t_undiscovered.pos) or 
                    (_center.set == 'Planet' and G.p_undiscovered.pos) or 
                    (_center.set == 'Spectral' and G.s_undiscovered.pos) or 
                    (_center.set == 'Voucher' and G.v_undiscovered.pos) or 
                    (_center.set == 'Booster' and G.booster_undiscovered.pos))
                end
            end
        end
    end
    if _front then
        self.children.front.atlas = G.ASSET_ATLAS[_front.atlas] or
        G.ASSET_ATLAS[G.SETTINGS.colourblind_option and _front.card_atlas_high_contrast or _front.card_atlas_low_contrast] or
        G.ASSET_ATLAS["cards_" .. (G.SETTINGS.colourblind_option and 2 or 1)]
        self.children.front:set_sprite_pos(self.config.card.pos)
    end
end


-- ----------------------------------------------
-- ------------MOD CORE API SPRITE END-----------