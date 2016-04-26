local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local global = require "calc/global"
local json = require "json-c"

local ui = {
	FILE = 'calc/shezhi.json',
	FILE_3_4 = 'calc/shezhi43.json',
	designWidth = 1080,
	designHeight = 1920,	
	BG = 'ding',
	BACK = 'Button_5_0',
	EMAIL_BUTTON = 'Button_mail',
	SETTING_BUTTON = 'Button_Setup',
	EMAIL_FLAG = 'Button_mail/Image_10',
	EMAIL_NUM = 'Button_mail/Image_10/Label_13',
	MUSIC_CHECK = 'lei/kaig',
	EFFECT_CHECK = 'lei/kaig',
	--LEFTHAND_CHECK = 'ScrollView_blueground/Panel_setupground/Image_60/CheckBox_86',
}

local setup = global.SceneClass("setup",ui)

function setup:config(key,method)
	local t = global.get_game_configure()
	if method=="get" then
		return t[key]
	else
		if t[key]~=method then
			t[key]=method
			self._configMotify = true
		end
	end
end

function setup:storeConfig()
	if not self._configMotify then return end
	
	local t = global.get_game_configure()
	local s = json.encode(t)
	global.post_data(self._root,"save_config",{v1=s},
	function(v)
		return v and v.v1
	end,
	function(v)
		kits.log("upload configure!")
	end,
	function()
		self:storeConfig()
	end,nil,true)	
end

function setup:init(b)
	if b then
		self._bg = uikits.child(self._root,ui.BG)
		global.back(self._bg,ui.BACK)
		self._music_check = uikits.child(self._root,ui.MUSIC_CHECK)
		--self._effect_check = uikits.child(self._bg,ui.EFFECT_CHECK)
		--self._lefthand_check = uikits.child(self._bg,ui.LEFTHAND_CHECK)
		--self._mut = kits.config("calc_mute","get")
		--self._audio = kits.config("calc_audio","get")
		--self._left = kits.config("calc_left","get")
		self._mut = self:config("calc_mute","get")
		self._audio = self:config("calc_audio","get")
		self._left = self:config("calc_left","get")		
		self._music_check:setSelectedState(self._mut)
		--self._effect_check:setSelectedState(self._audio)
		--self._lefthand_check:setSelectedState(self._left)
		
		uikits.event(self._music_check,function(sender,b)
			print("music :"..tostring(b))
			self._mut = b
			if b then
				global.play()
			else
				global.stop()
			end
		end)
		
		--[[
		uikits.event(self._effect_check,function(sender,b)
			print("effect :"..tostring(b))
			self._audio = b
			uikits.muteClickSound(not self._audio)
		end)
		
		uikits.event(self._lefthand_check,function(sender,b)
			print("left hand :"..tostring(b))
			self._left = b
			if b then
			else
			end			
		end)
		--]]		
	end
	global.initEmailFlag(self._bg,ui.EMAIL_BUTTON,ui.EMAIL_FLAG,ui.EMAIL_NUM,nil,true)	
end

function setup:release()
--	kits.config("calc_mute",self._mut)
--	kits.config("calc_audio",self._audio)
--	kits.config("calc_left",self._left)
	self:config("calc_mute",self._mut)
	self:config("calc_audio",self._audio)
	self:config("calc_left",self._left)	
	self:storeConfig()
end

return setup