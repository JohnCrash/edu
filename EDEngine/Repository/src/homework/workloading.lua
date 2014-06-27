local uikits = require "uikits"

local ui = {
	FILE = 'homework/studentloading_1/studentloading_1.json',
	BACK = 'white/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
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
	self._root = uikits.fromJson{file=ui.FILE}
end

function WorkLoading:release()
end

return WorkLoading