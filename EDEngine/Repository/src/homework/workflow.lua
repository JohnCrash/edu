local uikits = require "uikits"

local ui = {
	FILE = 'homework/z21_1/z21_1.json',
	BACK = 'milk_write/back',
}

local WorkFlow = class("WorkFlow")
WorkFlow.__index = WorkFlow

function WorkFlow.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkFlow)
	
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

function WorkFlow:init()
	self._root = uikits.fromJson{file=ui.FILE}
	if self._root then
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)cc.Director:getInstance():popScene()end)	
	end
end

function WorkFlow:release()
end

return WorkFlow