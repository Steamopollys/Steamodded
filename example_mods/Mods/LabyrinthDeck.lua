--- STEAMODDED HEADER
--- MOD_NAME: Labyrinth Deck
--- MOD_ID: LabyrinthDeck
--- MOD_AUTHOR: [MathIsFun_]
--- MOD_DESCRIPTION: Implements an unused deck hidden in the game's textures
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0812d]

----------------------------------------------
------------MOD CODE -------------------------

SMODS.Back{
    name = "Labyrinth Deck",
    key = "labyrinth",
    pos = {x = 0, y = 4},
    config = {hands = -3, discards = 5},
    loc_txt = {
        name = "Labyrinth Deck",
        text = {
            "{C:red}+#1#{} discards",
            "{C:blue}#2#{} hands",
            "every round"
        }
    },
    loc_vars = function(self)
        return { vars = { self.config.discards, self.config.hands }}
    end
}

----------------------------------------------
------------MOD CODE END----------------------