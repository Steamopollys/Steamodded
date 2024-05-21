--- STEAMODDED CORE
--- MODULE SOUND
-- check this for more explanation on how to use this: https://github.com/Infarcactus/Balatro-Custom-Sound-Player

SMODS.SOUND_SOURCES = {}

function register_sound_global()
    local mod = SMODS.current_mod
    for _, filename in ipairs(love.filesystem.getDirectoryItems(mod.path ..'assets/sounds/')) do
        local extension = string.sub(filename, -4)
        if extension == '.ogg' or extension == '.mp3' or extension == '.wav' then -- please use .ogg or .wav files
            local sound = nil
            local sound_code = string.sub(filename, 1, -5)
            sound = {
                sound = love.audio.newSource(mod.path .. 'assets/sounds/' .. filename,
                ((string.find(sound_code, 'music') or string.find(sound_code, 'stream')) and "stream" or 'static'))
            }
            sound.sound_code = sound_code
            SMODS.SOUND_SOURCES[sound_code] = sound
            sendInfoMessage("Registered sound '" .. sound_code .. "' from file " .. filename, 'SoundAPI')
        end
    end
end

function register_sound(name, path, filename) -- Keep that here to support old versions
    local sound_code = string.sub(filename, 1, -5)
    local s = {
        sound = love.audio.newSource(
            path .. "assets/sounds/" .. filename,
            ((string.find(sound_code, 'music') or string.find(sound_code, 'stream')) and "stream" or 'static')
        ),
        filepath = path .. "assets/sounds/" .. filename
    }
    -- s.original_pitch = 1
    -- s.original_volume = 0.75
    s.sound_code = name

    sendInfoMessage("Registered sound '" .. name .. "' from file " .. filename, 'SoundAPI')
    SMODS.SOUND_SOURCES[name] = s
end

function Custom_Play_Sound(sound_code, stop_previous_instance, volume, pitch)
    if SMODS.SOUND_SOURCES[sound_code] then
        --sendTraceMessage("found sound code: " .. sound_code, 'SoundAPI') --this had to be taken down due to the modulate_sound
        local s = SMODS.SOUND_SOURCES[sound_code]
        stop_previous_instance = stop_previous_instance and true
        volume = volume or 1
        s.sound:setPitch(pitch or 1)
        
        local sound_vol = volume * (G.SETTINGS.SOUND.volume / 100.0)
        if string.find(s.sound_code,'music') then
            sound_vol = sound_vol * (G.SETTINGS.SOUND.music_volume / 100.0)
        else
            sound_vol = sound_vol * (G.SETTINGS.SOUND.game_sounds_volume / 100.0)
        end
        if sound_vol <= 0 then
            s.sound:setVolume(0)
        else
            s.sound:setVolume(sound_vol)
        end
        
        if stop_previous_instance and s.sound:isPlaying() then
            s.sound:stop()
        end
        love.audio.play(s.sound)
        return true
    end
    return false
end

SMODS.STOP_SOUNDS = {}

function register_stop_sound(sound_code)
    if type(sound_code) == "table" then
        for _, s_c in ipairs(sound_code) do
            if type(s_c) == "string" then
                SMODS.STOP_SOUNDS[s_c] = true
            else
                return false
            end
        end
    elseif type(sound_code) == "string" then
        SMODS.STOP_SOUNDS[sound_code] = true
    else
        return false
    end
    return true
end

SMODS.TEMPORARY_STOP_SOUNDS = {}

function register_temporary_stop_sound(sound_code,number_repeat)
    if number_repeat and type(number_repeat) == "number" and number_repeat>0 then
        if type(sound_code) == "table" then
            for _, s_c in ipairs(sound_code) do
                if type(s_c) == "string" then
                    SMODS.TEMPORARY_STOP_SOUNDS[s_c] = number_repeat
                else
                    return false
                end
            end
        elseif type(sound_code) == "string" then
            SMODS.TEMPORARY_STOP_SOUNDS[sound_code] = number_repeat
        else
            return false
        end
    else
        return false
    end
    return true
end

SMODS.REPLACE_SOUND_PLAYED = {}

function register_replace_sound_played(replace_code_table)
    if type(replace_code_table) == "table" then
        for original_sound_code, replacement_sound_code in pairs(replace_code_table) do
            if type(replacement_sound_code) == "table" or type(replacement_sound_code) == "string" then
                SMODS.REPLACE_SOUND_PLAYED[original_sound_code] = replacement_sound_code
            else
                return false
            end
        end
    else
        return false
    end
    return true
end

SMODS.TEMPORARY_REPLACE_SOUND_PLAYED = {}

function register_temporary_replace_sound_played(replace_code_table,number_repeat)
    if number_repeat and type(number_repeat) == "number" and number_repeat>0 then
        if type(replace_code_table) == "table" then
            for original_sound_code, replacement_sound_code in pairs(replace_code_table) do
                if type(replacement_sound_code) == "table" or type(replacement_sound_code) == "string" then
                    SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[original_sound_code] = {replacement_sound_code,number_repeat}
                else
                    return false
                end
            end
        else
            return false
        end
    else
        return false
    end
    return true
end

local Original_play_sound = play_sound
function play_sound(sound_code, per, vol)
    if SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[sound_code] then
        sendDebugMessage("Temporary replace sound played : " .. sound_code)
        local table_args = SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[sound_code]
        if type(table_args[1]) == "table" then
            local sound_args = table_args[1]
            Custom_Play_Sound(sound_args.sound_code,sound_args.stop_previous_instance,sound_args.volume, sound_args.pitch)
            if table_args[2] -1 <= 0 then
                SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[sound_code] = nil
            else
                SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[sound_code] = {table_args[1],table_args[2] -1}
            end
            if not (sound_args.continue_base_sound) then return end
        else
            Custom_Play_Sound(table_args[1])
            if table_args[2] -1 <= 0 then
                SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[sound_code] = nil
            else
                SMODS.TEMPORARY_REPLACE_SOUND_PLAYED[sound_code] = {table_args[1],table_args[2] -1}
            end
            return
        end
    end
    if SMODS.TEMPORARY_STOP_SOUNDS[sound_code] then
        sendDebugMessage("Temporary stop sound : " .. sound_code)
        if SMODS.TEMPORARY_STOP_SOUNDS[sound_code] -1 <= 0 then
            SMODS.TEMPORARY_STOP_SOUNDS[sound_code] = nil
        else
            SMODS.TEMPORARY_STOP_SOUNDS[sound_code] = SMODS.TEMPORARY_STOP_SOUNDS[sound_code] -1
        end
        return
    end
    if SMODS.REPLACE_SOUND_PLAYED[sound_code] then
        if type(SMODS.REPLACE_SOUND_PLAYED[sound_code]) == "table" then
            local sound_args = SMODS.REPLACE_SOUND_PLAYED[sound_code]
            Custom_Play_Sound(sound_args.sound_code,sound_args.stop_previous_instance,sound_args.volume, sound_args.pitch)
            if not (sound_args.continue_base_sound) then return end
        else
            Custom_Play_Sound(SMODS.REPLACE_SOUND_PLAYED[sound_code])
            return
        end
    end
    if SMODS.STOP_SOUNDS[sound_code] then return end
    return Original_play_sound(sound_code, per, vol)
end

local Old_music_being_played = ''
local Music_Sound_Codes = {'music1','music2','music3','music4','music5'}
local Orginial_modulate_sound=modulate_sound
function modulate_sound(dt)
    G.SPLASH_VOL = 2*dt*(G.STATE == G.STATES.SPLASH and 1 or 0) + (G.SPLASH_VOL or 1)*(1-2*dt)
    G.PITCH_MOD = (G.PITCH_MOD or 1)*(1 - dt) + dt*((not G.normal_music_speed and G.STATE == G.STATES.GAME_OVER) and 0.5 or 1)
    --flame control
    G.SETTINGS.ambient_control = G.SETTINGS.ambient_control or {}
    G.ARGS.score_intensity = G.ARGS.score_intensity or {}
    if type(G.GAME.current_round.current_hand.chips) ~= 'number' or type(G.GAME.current_round.current_hand.mult) ~= 'number' then
      G.ARGS.score_intensity.earned_score = 0
    else
      G.ARGS.score_intensity.earned_score = G.GAME.current_round.current_hand.chips*G.GAME.current_round.current_hand.mult
    end
    G.ARGS.score_intensity.required_score = G.GAME.blind and G.GAME.blind.chips or 0
    G.ARGS.score_intensity.flames = math.min(1, (G.STAGE == G.STAGES.RUN and 1 or 0)*(
      (G.ARGS.chip_flames and (G.ARGS.chip_flames.real_intensity + G.ARGS.chip_flames.change) or 0))/10)
    G.ARGS.score_intensity.organ = G.video_organ or G.ARGS.score_intensity.required_score > 0 and math.max(math.min(0.4, 0.1*math.log(G.ARGS.score_intensity.earned_score/(G.ARGS.score_intensity.required_score+1), 5)),0.) or 0

    local AC = G.SETTINGS.ambient_control
    G.ARGS.ambient_sounds = G.ARGS.ambient_sounds or {
      ambientFire2 = {volfunc = function(_prev_volume) return _prev_volume*(1 - dt) + dt*0.9*((G.ARGS.score_intensity.flames > 0.3) and 1 or G.ARGS.score_intensity.flames/0.3) end},
      ambientFire1 = {volfunc = function(_prev_volume) return _prev_volume*(1 - dt) + dt*0.8*((G.ARGS.score_intensity.flames > 0.3) and (G.ARGS.score_intensity.flames-0.3)/0.7 or 0) end},
      ambientFire3 = {volfunc = function(_prev_volume) return _prev_volume*(1 - dt) + dt*0.4*((G.ARGS.chip_flames and G.ARGS.chip_flames.change or 0) + (G.ARGS.mult_flames and G.ARGS.mult_flames.change or 0)) end},
      ambientOrgan1 = {volfunc = function(_prev_volume) return _prev_volume*(1 - dt) + dt*0.6*(G.SETTINGS.SOUND.music_volume + 100)/200*(G.ARGS.score_intensity.organ) end},
    }

    for k, v in pairs(G.ARGS.ambient_sounds) do
      AC[k] = AC[k] or {}
      AC[k].per = (k == 'ambientOrgan1') and 0.7 or (k == 'ambientFire1' and 1.1) or (k == 'ambientFire2' and 1.05) or 1
      AC[k].vol = (not G.video_organ and G.STATE == G.STATES.SPLASH) and 0 or AC[k].vol and v.volfunc(AC[k].vol) or 0
    end
    --flame control


    local desired_track =  
        G.video_soundtrack or
        (G.STATE == G.STATES.SPLASH and '') or
        (G.booster_pack_sparkles and not G.booster_pack_sparkles.REMOVED and 'music2') or
        (G.booster_pack_meteors and not G.booster_pack_meteors.REMOVED and 'music3') or
        (G.booster_pack and not G.booster_pack.REMOVED and 'music2') or
        (G.shop and not G.shop.REMOVED and 'music4') or
        (G.GAME.blind and G.GAME.blind.boss and 'music5') or 
        ('music1')
    
    

    -- it could be optimized
    for _,sound_code in ipairs(Music_Sound_Codes) do
        if not(sound_code==desired_track) then
            if SMODS.REPLACE_SOUND_PLAYED[sound_code] then
                if type(SMODS.REPLACE_SOUND_PLAYED[sound_code]) == "table" then  
                    local sound_args = SMODS.REPLACE_SOUND_PLAYED[sound_code]
                    Custom_Play_Sound(sound_args.sound_code,sound_args.stop_previous_instance,0, sound_args.pitch)
                else
                    Custom_Play_Sound(SMODS.REPLACE_SOUND_PLAYED[sound_code],true,0)
                end
            end
        elseif SMODS.REPLACE_SOUND_PLAYED[desired_track] then
            if type(SMODS.REPLACE_SOUND_PLAYED[desired_track]) == "table" then  
                local sound_args = SMODS.REPLACE_SOUND_PLAYED[desired_track]
                Custom_Play_Sound(sound_args.sound_code,sound_args.stop_previous_instance,sound_args.volume, sound_args.pitch)
            else
                Custom_Play_Sound(SMODS.REPLACE_SOUND_PLAYED[desired_track])
            end
        end
    end

    for _,sound_code in ipairs(Music_Sound_Codes) do
        if not(sound_code==desired_track) then
            if SMODS.REPLACE_SOUND_PLAYED[sound_code] then
                local sound_args=SMODS.REPLACE_SOUND_PLAYED[sound_code]
                if type(sound_args)=='table' then
                    SMODS.SOUND_SOURCES[sound_args.sound_code].sound:setVolume(0)
                else
                    SMODS.SOUND_SOURCES[sound_code].sound:setVolume(0)
                end
            end
        elseif SMODS.REPLACE_SOUND_PLAYED[sound_code] then
            local sound_args=SMODS.REPLACE_SOUND_PLAYED[sound_code]
            if type(sound_args)=='table' then
                SMODS.SOUND_SOURCES[sound_args.sound_code].sound:setVolume(sound_args.volume * (G.SETTINGS.SOUND.volume / 100.0) * (G.SETTINGS.SOUND.music_volume / 100.0))
            else
                SMODS.SOUND_SOURCES[sound_code].sound:setVolume(1)
            end
        end
    end
    -- end could be optimized
    if SMODS.REPLACE_SOUND_PLAYED[desired_track] then
        if type(SMODS.REPLACE_SOUND_PLAYED[desired_track]) == "table" then  
            local sound_args = SMODS.REPLACE_SOUND_PLAYED[desired_track]
            Custom_Play_Sound(sound_args.sound_code,sound_args.stop_previous_instance,sound_args.volume, sound_args.pitch)
            if not (sound_args.continue_base_sound) then return end
        else
            Custom_Play_Sound(SMODS.REPLACE_SOUND_PLAYED[desired_track])
            return
        end
    end
    if SMODS.STOP_SOUNDS[desired_track] then
        return 
    end
    return Orginial_modulate_sound(dt)
end
