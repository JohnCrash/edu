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
		back:addTouchEventListener(
				function(sender,eventType)
					if eventType == ccui.TouchEventType.ended then
						cc.Director:getInstance():popScene()
					end
				end)
		local news = uikits.child(self._root,'white/new2')
	end
end

function WorkList:release()
end

return WorkList

