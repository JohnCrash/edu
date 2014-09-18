local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"


local ui = {
	FILE = 'homework/laoshizuoye/fubujieshu.json',
	FILE_3_4 = 'homework/laoshizuoye/fubujieshu43.json',
	BUT_BACK_MAIN = 'fhsy',
	BUT_PUBLISH_AGAIN = 'zcfa',
}

local Publishhwret = class("Publishhwret")
Publishhwret.__index = Publishhwret

function Publishhwret.create(tb_parent_view)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Publishhwret)
	layer.tb_parent_view = tb_parent_view
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

function Publishhwret:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
	local but_back_main = uikits.child(self._widget,ui.BUT_BACK_MAIN)
	local but_publish_again = uikits.child(self._widget,ui.BUT_PUBLISH_AGAIN)

	uikits.event(but_back_main,
		function(sender,eventType)
		uikits.popScene()
		uikits.popScene()
	end,"click")	
	
	uikits.event(but_publish_again,
		function(sender,eventType)
		uikits.popScene()
	end,"click")		
	
end

function Publishhwret:release()
	
end

return Publishhwret