--- STEAMODDED HEADER
--- MOD_NAME: Negate Texture Pack
--- MOD_ID: NegateTexturePack
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Negated Balatro... THIS IS AN EXAMPLE MOD, FEEL FREE TO USE IT AS A BASE

----------------------------------------------
------------MOD CODE -------------------------

function SMODS.INIT.NegateTexturePack()
    sendInfoMessage("Launching Negate Texture Pack!", "SteamoddedNegateTexturePack")

    local negate_mod = SMODS.findModByID("NegateTexturePack")
    local sprite_jkr = SMODS.Sprite:new("Joker", negate_mod.path, "Jokers-negate.png", 71, 95, "asset_atli")
    local sprite_boost = SMODS.Sprite:new("Booster", negate_mod.path, "boosters-negate.png", 71, 95, "asset_atli")
    local sprite_blind = SMODS.Sprite:new("blind_chips", negate_mod.path, "BlindChips-negate.png", 34, 34, "animation_atli", 21)

    sprite_jkr:register()
    sprite_boost:register()
    sprite_blind:register()
end

----------------------------------------------
------------MOD CODE END----------------------