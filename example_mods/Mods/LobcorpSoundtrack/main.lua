--- STEAMODDED HEADER
--- MOD_NAME: Lobotomy Corporation Soundtrack
--- MOD_ID: LobcorpSoundtrack
--- PREFIX: lobc_ost
--- MOD_AUTHOR: [Mysthaps]
--- MOD_DESCRIPTION: A standalone mod that replaces the in-game music with Lobotomy Corporation themes.
--- DEPENDENCIES: [Steamodded>=1.0.0~ALPHA-0909a]
--- CONFLICTS: [LobotomyCorp>=0.9.0]

-- For "pitch = 0.7", speed up the sound files by 10/7 for them to sound normal in-game.
SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_story1",
    path = "Story1.ogg",
    select_music_track = function()
        return (G.STATE == G.STATES.MENU) and 10 or false
    end,
})

SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_neutral1",
    path = "Neutral1.ogg",
    select_music_track = function()
        return (G.GAME and G.GAME.round_resets.ante <= 2) and 0 or false
    end,
    sync = {
        lobc_ost_music_neutral1 = true,
        lobc_ost_music_neutral2 = true,
        lobc_ost_music_neutral3 = true,
        lobc_ost_music_neutral4 = true,
    }
})

SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_neutral2",
    path = "Neutral2.ogg",
    select_music_track = function()
        return (G.GAME and G.GAME.round_resets.ante >= 3 and G.GAME.round_resets.ante <= 4) and 0 or false
    end,
    sync = {
        lobc_ost_music_neutral1 = true,
        lobc_ost_music_neutral2 = true,
        lobc_ost_music_neutral3 = true,
        lobc_ost_music_neutral4 = true,
    }
})

SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_neutral3",
    path = "Neutral3.ogg",
    select_music_track = function()
        return (G.GAME and G.GAME.round_resets.ante >= 5 and G.GAME.round_resets.ante <= 6) and 0 or false
    end,
    sync = {
        lobc_ost_music_neutral1 = true,
        lobc_ost_music_neutral2 = true,
        lobc_ost_music_neutral3 = true,
        lobc_ost_music_neutral4 = true,
    }
})

SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_neutral4",
    path = "Neutral4.ogg",
    select_music_track = function()
        return (G.GAME and G.GAME.round_resets.ante >= 7) and 0 or false
    end,
    sync = {
        lobc_ost_music_neutral1 = true,
        lobc_ost_music_neutral2 = true,
        lobc_ost_music_neutral3 = true,
        lobc_ost_music_neutral4 = true,
    }
})

SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_first_warning",
    path = "Emergency1.ogg",
    select_music_track = function()
        return (G.GAME and G.GAME.blind and (G.GAME.blind.config.blind.boss and not G.GAME.blind.config.blind.boss.showdown)) and 1 or false
    end,
})

SMODS.Sound({
    vol = 0.6,
    pitch = 0.7,
    key = "music_second_warning",
    path = "Emergency2.ogg",
    select_music_track = function()
        return (G.GAME and G.GAME.blind and (G.GAME.blind.config.blind.boss and G.GAME.blind.config.blind.boss.showdown)) and 2 or false
    end,
})
