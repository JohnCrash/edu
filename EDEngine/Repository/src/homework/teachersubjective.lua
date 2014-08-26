local kits = require "kits"
local uikits = require "uikits"
local StudentList = require "homework/studentlist"

local ui = {
	FILE = 'laoshizuoye/jinruzgt.json',
	FILE_3_4 = 'laoshizuoye/jinruzgt43.json',
	BACK = 'ding/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
	STUDENT_LIST_BUTTON = 'ding/liebiao',
	SUBJECTIVE_LIST = 'gundong',
	SUBJECTIVE_ITEM = 'xuesheng1',
	TITLE = 'ding/kewen',
	CLASS = 'ding/banji',
	ITEM_NAME = 'mingzhi',
	ITEM_TIME = 'tijiaoshijian',
	ITEM_ANSWER = 'xswenzi',
	ITEM_AUDIO = 'yuyin',
	ITEM_AUDIO_TIME = 'shijian',
	ITEM_IMAGE = 'xszp',
	ITEM_GOOD = 'zan',
	ITEM_INPUT = 'dianping/dpwenzi',
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
	
	self._subjectives = uikits.scroll(self._root,ui.SUBJECTIVE_LIST,ui.SUBJECTIVE_ITEM)
	
	local result = kits.read_cache("sujective_work.json")
	if result then
		local t = json.decode(result)
		if t then
			for k,v in pairs(t) do
				local item = self._subjectives:additem{
					[ui.ITEM_NAME] = v.name or '',
					[ui.ITEM_TIME] = v.time or '',
					[ui.ITEM_ANSWER] = v.answer or '',
					[ui.ITEM_AUDIO] = function(child,item)
						if v.audio and type(v.audio)=='string' and string.len(v.audio) > 0 then
							uikits.event(child,function(sender)
								uikits.playSound(v.audio)
							end)
						else
							child:setVisible(false)
						end
					end
				}
				local layout = uikits.scroll(item,nil,ui.ITEM_IMAGE,true,16)
				layout:clear()
				if v.image and type(v.image) == 'table' then
					for i,p in pairs(v.image) do
						if p and type(p)=='string' and string.len(p)>0 then
							local it = layout:additem()
							if it then
								it:loadTexture(p)
							end
						end
					end
				end
				layout:relayout()
			end
			self._subjectives:relayout()
		end
	end
end

function TeacherSubjective:init()
	if not self._root then
		self:init_gui()
	end
end

function TeacherSubjective:release()
	
end

return TeacherSubjective