local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local music = require "han/music"

local ui = {
	FILE = 'han/shezhi.json',
	FILE_3_4 = 'han/shezhi43.json',
	BACK = 'ding/fan',
	MUSIC = 'kuang/kg',
}

local setting = uikits.SceneClass("setting")
--[[
local setting = class("setting")
setting.__index = setting

function setting.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),setting)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end
--]]
function setting:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
	else
		self._ss = cc.size(1440,1080)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		local check = uikits.child(self._root,ui.MUSIC)
		self._mut = kits.config("hitmouse_mute","get")
		check:setSelectedState(not self._mut)
		uikits.event(check,function(sender)
			if sender:getSelectedState() then
				--当前打开声音状态
				self._mut = false
				music.play()
			else
				self._mut = true
				music.stop()
			end
		end)		
	end
end

function setting:release()
	kits.config("hitmouse_mute",self._mut)
end

return setting