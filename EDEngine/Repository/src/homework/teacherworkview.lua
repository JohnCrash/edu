local uikits = require "uikits"

local ui = {
	FILE = 'homework/studenthomework_1/studenthomework_1.json',
	BACK = 'white/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
}

local TeacherWorkView = class("TeacherWorkView")
TeacherWorkView.__index = TeacherWorkView

function TeacherWorkView.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TeacherWorkView)
	
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

function TeacherWorkView:init()
	
end

function TeacherWorkView:release()
	
end

return TeacherWorkView