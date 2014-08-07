local uikits = require "uikits"
local StudentList = require "homework/studentlist"

local ui = {
	FILE = 'laoshizuoye/jinruzgt.json',
	FILE_3_4 = 'laoshizuoye/jinruzgt43.json',
	BACK = 'ding/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
	STUDENT_LIST_BUTTON = 'ding/liebiao',
}

local TeacherSubjective = class("TeacherSubjective")
TeacherSubjective.__index = TeacherSubjective

function TeacherSubjective.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TeacherSubjective)
	
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

function TeacherSubjective:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)uikits.popScene()end)	
	local student_but = uikits.child(self._root,ui.STUDENT_LIST_BUTTON)
	uikits.event(student_but,function(sender)
			uikits.pushScene(StudentList.create())
		end)
end

function TeacherSubjective:init()
	if not self._root then
		self:init_gui()
	end
end

function TeacherSubjective:release()
	
end

return TeacherSubjective