local uikits = require "uikits"
local WorkList = require "homework/worklist"

local ui = {
	FILE = 'homework/studentloading.json',
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
		self._root = uikits.fromJson{file=ui.FILE}
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