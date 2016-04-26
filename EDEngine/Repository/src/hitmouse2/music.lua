local ffplayer = require "ffplayer"

local _current_as

local function stop_music()
	ffplayer.stopSoundGroup("music")
	_current_as = nil
end

local _music_idx

local function play_music()
	local name
	
	if _current_as and _current_as.isPlaying then
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
		name = 'res/hitmouse2/snd/beijing'..idx..'.mp3'
	else
		return
	end
		
	_current_as = ffplayer.playSound( "music",name,
		function(state,as,param)
			if state==ffplayer.STATE_OPEN then
				as:play()
			elseif state==ffplayer.STATE_END then
				as:close()
				_current_as = nil
				play_music()
			end
		end)
end

return {
	stop = stop_music,
	play = play_music,
}