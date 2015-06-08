require "AudioEngine"

local function stop_music()
	if AudioEngine.isMusicPlaying () then
		AudioEngine.stopMusic()
	end
end
local _music_idx
local function play_music()
	local name
	
	if AudioEngine.isMusicPlaying () then
		return
	end
	local idx = math.random(1,3)
	if _music_idx then
		for i=1,10 do
			if idx ~= _music_idx then
				_music_idx = idx
				break
			end
			idx = math.random(1,3)
		end
	else
		_music_idx = idx
	end
	if idx <=3 and idx >= 1 then
		name = 'hitmouse/snd/beijing'..idx..'.mp3'
	else
		return
	end
		
	AudioEngine.playMusic( name,true )
end

return {
	stop = stop_music,
	play = play_music,
}