local uikits = require "uikits"
local kits = require "kits"

local ui = {
	FILE = 'test/TestApplet_2.json',
	BACK = 'Button_9',
}

local Portrait = class("Portrait")
Portrait.__index = Portrait

function Portrait.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Portrait)
	
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

function Portrait:init()
	kits.log("Portrait run")
	cc_setUIOrientation(2)
	uikits.initDR{width=540,height=960}
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE}
	self:addChild(self._root)
	self._back = uikits.child(self._root,ui.BACK)
	uikits.event(self._back,function()
		uikits.popScene()
	end)	
end

function Portrait:release()
	
end

return Portrait