local ff = require "ff"
local uikits = require "uikits"

local _current_as

local function playStream( filename,event_func )
	if _current_as then
		_current_as:close()
	end
	
	cc.TextureCache:getInstance():removeUnusedTextures()
	local as = ff.new(filename)
	_current_as = as
	local state = 0
	local play_state = 3
	local _texture
	
	local function eventFunc(state,param)
		if event_func then
			event_func(state,as,param)
		end
	end
	if as then
		uikits.delay_call(nil,function()
			if as.isError then
				eventFunc(-1,as)
				as:close()
				return false
			end		
			if state == 0 and as.isOpen then
				state = 1
				as:pause()
				eventFunc(state)
			elseif state == 1 and not as.isOpen then
				eventFunc(0)
				return false
			end
			if state == 1 then
				if play_state ~= 2 and (as.isPlaying and not as.isEnd) then
					play_state = 2
					eventFunc(2,_texture)
					return true
				elseif play_state ~= 3 and (as.isPause and not as.isEnd) then
					play_state = 3
					eventFunc(3)
				elseif play_state ~= 4 and as.isEnd then
					play_state = 4
					eventFunc(4)
				end
			end
			if play_state == 2 then
				eventFunc(5)
			end
			local data = as:refresh()
			if _texture and data then
				_texture:updateWithData(data,0,0,as.width,as.height)
			elseif not _texture and data then
				if as.hasVideo then
					local data = as:refresh()
					_texture = cc.Texture2D:new()
					_texture:initWithData(data,as.width,as.height)		
					eventFunc(6,_texture)
				end				
			end			
			return true
		end,1/30)
	end
	return as
end

return {
	STATE_CLOSE = 0,
	STATE_OPEN = 1,
	STATE_ERROR = -1,
	STATE_PLAYING = 2,
	STATE_PAUSED = 3,
	STATE_END = 4,
	STATE_PROGRESS = 5,
	STATE_OPEN_VIDEO = 6,
	playStream = playStream,
}
