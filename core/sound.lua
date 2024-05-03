--- STEAMODDED CORE
--- MODULE SOUND

SMODS.SOUND_SOURCES = {}

function register_sound(name, path, filename)
	local sound_code = string.sub(filename, 1, -5)
	local s = {
		sound = love.audio.newSource(path .. "assets/sounds/" .. filename, string.find(sound_code,'music') and "stream" or 'static'),
		filepath = path .. "assets/sounds/" .. filename
	}
	s.original_pitch = 1
	s.original_volume = 0.75
	s.sound_code = name

	sendInfoMessage("Registered sound " .. name .. " from file " .. filename, 'SoundAPI')
	SMODS.SOUND_SOURCES[name] = s
end


function modded_play_sound(sound_code, stop_previous_instance, volume, pitch)
    stop_previous_instance = stop_previous_instance or false
    sound_code = string.lower(sound_code)
    for _, s in pairs(SMODS.SOUND_SOURCES) do
        if s.sound_code == sound_code then
            if volume then
                s.original_volume = volume
            else
                s.original_volume = 1
            end
            if pitch then
                s.original_pitch = pitch
            else
                s.original_pitch = 1
            end
            sendTraceMessage("found sound code: " .. sound_code, 'SoundAPI')
            s.sound:setPitch(pitch)
            local sound_vol = s.original_volume*(G.SETTINGS.SOUND.volume/100.0)*(G.SETTINGS.SOUND.game_sounds_volume/100.0)
            if sound_vol <= 0 then
                s.sound:setVolume(0)
            else
                s.sound:setVolume(sound_vol)
            end
            s.sound:setPitch(s.original_pitch)
            if stop_previous_instance and s.sound:isPlaying() then
                s.sound:stop()
            end
            love.audio.play(s.sound)
            return true
        end
    end
    return false
end