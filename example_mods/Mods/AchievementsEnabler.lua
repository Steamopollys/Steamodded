--- STEAMODDED HEADER
--- MOD_NAME: Achievements Enabler
--- MOD_ID: AchievementsEnabler
--- MOD_AUTHOR: [Steamo]
--- MOD_DESCRIPTION: Mod to activate Achievements

----------------------------------------------
------------MOD CODE -------------------------

function SMODS.INIT.AchievementsEnabler()
    sendInfoMessage("AchievementsEnabler Activated!", "SteamoddedAchievementsEnabler")
    G.F_NO_ACHIEVEMENTS = false
end

----------------------------------------------
------------MOD CODE END----------------------