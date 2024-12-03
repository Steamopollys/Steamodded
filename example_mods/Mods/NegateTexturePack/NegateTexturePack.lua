--- STEAMODDED HEADER
--- MOD_NAME: Negate Texture Pack
--- MOD_ID: NegateTexturePack
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Negated Balatro... THIS IS AN EXAMPLE MOD, FEEL FREE TO USE IT AS A BASE
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

----------------------------------------------
------------MOD CODE -------------------------


sendDebugMessage("Launching Negate Texture Pack!", "NegateTexturePack")

SMODS.Atlas{key = "Joker", path = "Jokers-negate.png", px = 71, py = 95, prefix_config = { key = false } }
SMODS.Atlas{key = "Booster", path = "boosters-negate.png", px = 71, py = 95, prefix_config = { key = false } }
SMODS.Atlas{key = "blind_chips", path = "BlindChips-negate.png", px = 34, py = 34, prefix_config = { key = false }, atlas_table = 'ANIMATION_ATLAS', frames = 21}

----------------------------------------------
------------MOD CODE END----------------------
