local ff = require "ff"
local kits = require "kits"
local uikits = require "uikits"

local _soundGroup = {}
local _allStreams = {}

local function isSupport()
	return ff
end

local function playStream( filename,event_func )
	local as = ff.new(filename)
	local state = 0
	local play_state = 3
	local _texture
	local layer
	
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
				_allStreams[as] = nil
				return false
			end		
			if state == 0 and as.isOpen then
				state = 1
				as:pause()
				eventFunc(state)
			elseif state == 1 and not as.isOpen then
				eventFunc(0)
				if _texture then _texture:release() end
				cc.TextureCache:getInstance():removeUnusedTextures()
				_allStreams[as] = nil
				return false
			end
			if state == 1 then
				if play_state ~= 2 and (as.isPlaying and not as.isEnd) then
					play_state = 2
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
					_texture = cc.Texture2D:new()
					_texture:retain()
					_texture:initWithData(data,as.width,as.height)		
					eventFunc(6,_texture)
				end				
			end			
			return true
		end,1/30)
		_allStreams[as] = as
	end
	return as
end

local function playSound( group,file,eventCallback )
	if kits.exist_file(file) or kits.exist_cache(file) or FileUtils:isFileExist(file) then
		local filename = file
		if kits.exist_cache(file) then
			filename = kits.get_cache_path()..file
		end
		local as = playStream( filename,eventCallback )
		if as then
			_soundGroup[group] = _soundGroup[group] or {}
			table.insert(_soundGroup[group],as)
			return as
		else
			kits.log('ERROR ffplayer.playSound can not open '..tostring(file))
		end
	else
		kits.log('ERROR ffplayer.playSound file not exist '..tostring(file))
	end
end

local function stopSoundGroup( group )
	if _soundGroup[group] then
		for k,v in pairs(_soundGroup[group]) do
			if v and v.isOpen then
				v:close()
			end
		end
		_soundGroup[group] = {}
	end
end

local function stopAllGroup()
	for k,v in pairs(_soundGroup) do
		for i,as in pairs(v) do
			if as and as.isOpen then
				as:close()
			end
		end
	end
	_soundGroup = {}
end

local function getSoundGroup()
	return _soundGroup
end

local _pauseStreams={}
local directorEventDispatcher = cc.Director:getInstance():getEventDispatcher()
local onPause = cc.EventListenerCustom:create("event_come_to_background",
	function(event)
		kits.log("OnPause")
		for as,v in pairs(_allStreams) do
			if as and v and (as.isOpen and as.isPlaying and not as.isEnd) then
				as:pause()
				table.insert(_pauseStreams,as)
			end
		end
	end)
local onResume = cc.EventListenerCustom:create("event_come_to_foreground",
	function(event)
		kits.log("OnResume")
		for i,as in pairs(_pauseStreams) do
			as:play()
		end
		_pauseStreams = {}
	end)
directorEventDispatcher:addEventListenerWithFixedPriority(onPause,1)
directorEventDispatcher:addEventListenerWithFixedPriority(onResume,1)

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
	playSound = playSound,
	stopSoundGroup = stopSoundGroup,
	stopAllGroup = stopAllGroup,
	getSoundGroup = getSoundGroup,
	isSupport = isSupport,
}
