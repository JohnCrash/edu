require "Cocos2d"
local kits = require "kits"
local ffplayer=require("ffplayer")

local resPath=require("kits").get_local_directory().."res/"

music=
{
	backgroundList=
	{
		"qwxt/audio/background/beijing (1).mp3",
		"qwxt/audio/background/beijing (2).mp3",
		"qwxt/audio/background/beijing (3).mp3",
		"qwxt/audio/background/beijing (4).mp3",
		"qwxt/audio/background/beijing (5).mp3",
		"qwxt/audio/background/beijing (6).mp3",
	},
	zuotiList=
	{
		"qwxt/audio/zuoti/zuoti (1).mp3",
		"qwxt/audio/zuoti/zuoti (2).mp3",
		"qwxt/audio/zuoti/zuoti (3).mp3",
		"qwxt/audio/zuoti/zuoti (4).mp3",
	},
	effectList=
	{
		"qwxt/audio/button.mp3",
		"qwxt/audio/levelup.mp3",
		"qwxt/audio/liandui.mp3",
		"qwxt/audio/pass.mp3",
		"qwxt/audio/right.mp3",
		"qwxt/audio/wrong.mp3",
	},

	on=false,
	zuotiOn=false,

	turnOn=function(on,zuotiOn)
		if on~=nil then music.on=on end
		if zuotiOn~=nil then music.zuotiOn=zuotiOn end
		require("qwxt/protocol").setBGMusic(music.on,music.zuotiOn)
	end,

	background=nil,
	playBackground=function()
		kits.log("playBackground")
		if music.zuoti~=nil and music.zuoti.isPlaying then music.zuoti:pause() end
		if music.on then
			kits.log("playBackground on")
			local function onPlayerEvent(state,as)
				if state==ffplayer.STATE_END then
					as:close()
					local nextIndex=math.random(1,#music.backgroundList)
					music.background=ffplayer.playSound("qwxt_background",resPath..music.backgroundList[nextIndex],onPlayerEvent)
				elseif state==ffplayer.STATE_OPEN then
					as:play()
				end
			end
			if music.background==nil then
				local index=math.random(1,#music.backgroundList)
				kits.log("ffplayer.playSound "..resPath..music.backgroundList[index])
				music.background=ffplayer.playSound("qwxt_background",resPath..music.backgroundList[index],onPlayerEvent)
			else
				if not music.background.isPlaying then music.background:play() end
			end
		else
			if music.background~=nil and music.background.isPlaying then
				music.background:pause()
			end
		end
	end,

	zuoti=nil,
	playZuoti=function()
		if music.background~=nil and music.background.isPlaying then music.background:pause() end
		if music.zuotiOn then
			local function onPlayerEvent(state,as)
				if state==ffplayer.STATE_END then
					as:close()
					local nextIndex=math.random(1,#music.zuotiList)
					music.zuoti=ffplayer.playSound("qwxt_zuoti",resPath..music.zuotiList[nextIndex],onPlayerEvent)
				elseif state==ffplayer.STATE_OPEN then
					as:play()
				end
			end
			if music.zuoti==nil then
				local index=math.random(1,#music.zuotiList)
				music.zuoti=ffplayer.playSound("qwxt_zuoti",resPath..music.zuotiList[index],onPlayerEvent)
			else
				if not music.zuoti.isPlaying then music.zuoti:play() end
			end
		else
			if music.zuoti~=nil and music.zuoti.isPlaying then
				music.zuoti:pause()
			end
		end
	end,

	playEffect=function(name,isLoop)
--		if not music.on then return end
		isLoop=isLoop or false
		local fileName="qwxt/audio/"..name..".mp3"
		AudioEngine.playEffect(fileName,isLoop)
	end,
}
