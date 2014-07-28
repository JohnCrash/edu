local uikits = require "uikits"
local WorkList = require "homework/worklist"

local ui = {
	FILE = 'homework/studentloading.json',
	FILE_3_4 = 'homework/studentloading43.json',
}

local WorkLoading = class("WorkLoading")
WorkLoading.__index = WorkLoading

function WorkLoading.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkLoading)
	
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

function WorkLoading:init()
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)	
	end
	--test
	uikits.delay_call( self,
		function(self)
			uikits.pushScene( WorkList,cc.TransitionFlipX )
		end,1)
end

function WorkLoading:release()
end

return WorkLoading