SMODS.SOUND_SOURCES = {}

function Add_Custom_Sound_Global(modID)
    local mod = SMODS.findModByID(modID)
    for _, filename in ipairs(love.filesystem.getDirectoryItems(mod.path .. 'Assets')) do
        local extension = string.sub(filename, -4)
        if extension == '.ogg' or extension == '.mp3' or extension=='.wav' then --please use .ogg or .wav files
            local sound = nil
            local sound_code = string.sub(filename, 1, -5)
            sound = {sound = love.audio.newSource(mod.path .. 'assets/sounds/' .. filename, 'static')}
            sound.sound_code = sound_code
            SMODS.SOUND_SOURCES[sound_code]=sound
	    sendInfoMessage("Registered sound " .. name .. " from file " .. filename, 'SoundAPI')
        end
    end
end


function register_sound(name, path, filename) --Keep that here to support old versions
	local sound_code = string.sub(filename, 1, -5)
	local s = {
		sound = love.audio.newSource(path .. "assets/sounds/" .. filename, (string.find(sound_code,'music') or string.find(sound_code,'stream') and "stream" or 'static'),
		filepath = path .. "assets/sounds/" .. filename
	}
	--s.original_pitch = 1
	--s.original_volume = 0.75
	s.sound_code = name

	sendInfoMessage("Registered sound " .. name .. " from file " .. filename, 'SoundAPI')
	SMODS.SOUND_SOURCES[name] = s
end


function Custom_Play_Sound(sound_code,stop_previous_instance, volume, pitch)
    if SMODS.SOUND_SOURCES[sound_code] then
	sendTraceMessage("found sound code: " .. sound_code, 'SoundAPI')
        local s = SMODS.SOUND_SOURCES[sound_code]
        stop_previous_instance = (stop_previous_instance == nil) and true or stop_previous_instance
        volume = volume or 1
        s.sound:setPitch(pitch or 1)
        local sound_vol = volume*(G.SETTINGS.SOUND.volume/100.0)*(G.SETTINGS.SOUND.game_sounds_volume/100.0)
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
