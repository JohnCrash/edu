local json = require "json"
local kits = require "kits"
local uikits = require "uikits"
local WorkFlow = require "homework/workflow"
local Score = require "homework/score"

local ui = {
	FILE = 'homework/z2_1/z2_1.json',
	BACK = 'white/back',
	CAPTION = 'white/lesson_name',
	END_DATE = 'white/time_over',
	LIST = 'top_view',
	ITEM = 'top_view/top_1',
	WORKFLOW = 'objective_item/start_objective',
	WORKFLOW2 = 'subjective_item/completed_subjective',
	COMMIT = 'submit',
	OBJECTIVE_NUM = 'objective_no',
	SUBJECTIVE_NUM = 'subjective_no',
}

--[[
	作业提交
--]]
local commit_url = ''
--[[
	取得提交顺序
--]]
local commit_sort_url = ''
--[[
	取得作业表
--]]
local topics_url = 'http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx'
local WorkCommit = class("WorkCommit")
WorkCommit.__index = WorkCommit

--[[
	参数表:
	caption			标题
	end_date		结束日期
	topics_num	客观题数量
	subjective_num	主观题数量
	pid					?
	uid					?
--]]
function WorkCommit.create( t )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkCommit)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer._arguments = t
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function WorkCommit:init()
	if not self._root then
		self._root = uikits.fromJson{file=ui.FILE}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
	
		uikits.event(uikits.child(self._root,ui.WORKFLOW),
						function(sender)
							uikits.pushScene(WorkFlow.create(self._arguments.url))
						end,'click')
		uikits.event(uikits.child(self._root,ui.WORKFLOW2),
						function(sender)
							uikits.pushScene(WorkFlow.create(self._arguments.url2))
						end,'click')						
		self:addChild(self._root)
		
		if self._arguments then
			local caption = uikits.child(self._root,ui.CAPTION)
			if self._arguments.caption then
				caption:setText( self._arguments.caption )
			end
			local end_date = uikits.child(self._root,ui.END_DATE)
			if self._arguments.end_date then
				end_date:setText( self._arguments.end_date )
			end
			local obj_num = uikits.child(self._root,ui.OBJECTIVE_NUM)
			if self._arguments.topics_num then
				obj_num:setText(tostring(self._arguments.topics_num))
			end
			local subj_num = uikits.child(self._root,ui.SUBJECTIVE_NUM)
			if self._arguments.subjective_num then
				subj_num:setText(tostring(self._arguments.subjective_num))
			end
			local commit = uikits.child(self._root,ui.COMMIT)
			
			uikits.event(commit,function(sender)
					--提交
					uikits.pushScene( Score.create{} )
				end,'click')
		end		
	end
end

function WorkCommit:release()
end

return WorkCommit