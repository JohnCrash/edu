local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse/level"

local ui = {
	FILE = 'hitmouse/chuangguan.json',
	FILE_3_4 = 'hitmouse/chuangguan43.json',
	BACK = 'ding/fan',
}

local levelScene = class("levelScene")
levelScene.__index = levelScene

function levelScene.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),levelScene)
	
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

function levelScene:init()
	self._ss = cc.size(1920,1080);
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
	end
end

function levelScene:release()
	
end

return levelScene