local uikits = require "uikits"

local WorkList = class("WorkList")
WorkList.__index = WorkList

function WorkList.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkList)
	
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

function WorkList:init()
	self._root = uikits.fromJson{file='homework/studenthomework_1/studenthomework_1.json'}
	if self._root then
		self:addChild(self._root)
		local back = uikits.child(self._root,'white/back')
		uikits.event(back,function(sender)cc.Director:getInstance():popScene()end)
		local v = uikits.child(self._root,'newview/subject1')
		print( '---------->'..cc_type(v) )
	end
end

function WorkList:release()
end

return WorkList

