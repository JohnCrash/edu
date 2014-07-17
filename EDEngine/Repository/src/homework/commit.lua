local json = require "json"
local kits = require "kits"
local uikits = require "uikits"
local WorkFlow = require "homework/workflow"
local Score = require "homework/score"
local loadingbox = require "homework/loadingbox"
local login = require 'login'
local mt = require "mt"
local cache = require "cache"

local ui = {
	FILE = 'homework/z2_1/z2_1.json',
	BACK = 'white/back',
	CAPTION = 'white/lesson_name',
	END_DATE = 'white/time_over',
	LIST = 'top_view',
	ITEM = 'top_view/top_1',
	WORKFLOW = 'objective_item/start_objective',
	WORKFLOW_COMPLETE = 'objective_item/completed_objective',
	WORKFLOW2 = 'subjective_item/start_subjective',
	WORKFLOW2_COMPLETE = 'subjective_item/completed_subjective',
	COMMIT = 'submit',
	OBJECTIVE_NUM = 'objective_item/objective_no',
	SUBJECTIVE_NUM = 'objective_item/subjective_no',
	WHITE_STAR = 'objective_item/white_star_',
	RED_STAR = 'objective_item/red_star_',
	WHITE_STAR2 = 'subjective_item/white_star_',
	RED_STAR2 = 'subjective_item/red_star_',	
	TYPE_TEXT = 'account_information/lesson_text',
	TIMELABEL = 'white/text',
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

local commit_url = 'http://new.www.lejiaolexue.com/student/SubmitPaper.aspx'
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

function WorkCommit:init_star()
	self._white_star = {}
	self._red_star = {}
	self._white_star2 = {}
	self._red_star2 = {}
	for i = 1,5 do
		self._white_star[i] = uikits.child( self._root,ui.WHITE_STAR..i )
		self._red_star[i] =  uikits.child( self._root,ui.RED_STAR..i )
		self._white_star2[i] = uikits.child( self._root,ui.WHITE_STAR2..i )
		self._red_star2[i] =  uikits.child( self._root,ui.RED_STAR2..i )		
	end
end

function WorkCommit:setPercent2( p )
	if p < 0 then p = 0 end
	if p > 100 then p = 100 end
	local n = math.floor( p / 20 )
	for i = 1, 5 do
		if i <= n then
			self._red_star2[i]:setVisible(true)
			self._white_star2[i]:setVisible(false)
		else
			self._red_star2[i]:setVisible(false)
			self._white_star2[i]:setVisible(true)		
		end
	end
end
--p = 1 ~ 100 ?
function WorkCommit:setPercent( p )
	if p < 0 then p = 0 end
	if p > 100 then p = 100 end
	local n = math.floor( p / 20 )
	for i = 1, 5 do
		if i <= n then
			self._red_star[i]:setVisible(true)
			self._white_star[i]:setVisible(false)
		else
			self._red_star[i]:setVisible(false)
			self._white_star[i]:setVisible(true)		
		end
	end
end

function WorkCommit:init()
	if not self._root then
		self._root = uikits.fromJson{file=ui.FILE}
		self:addChild(self._root)
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
		
		self:init_star()
	end						

	if self._arguments then
		local but1
		local but2
		if self._arguments.cnt_item_finish and self._arguments.cnt_item and self._arguments.cnt_item <=self._arguments.cnt_item_finish then
			uikits.child(self._root,ui.WORKFLOW):setVisible(false)
			but1 = uikits.child(self._root,ui.WORKFLOW_COMPLETE)
		else
			but1 = uikits.child(self._root,ui.WORKFLOW)
			 uikits.child(self._root,ui.WORKFLOW_COMPLETE):setVisible(false)
		end
		but2 = uikits.child(self._root,ui.WORKFLOW2)
		uikits.child(self._root,ui.WORKFLOW2_COMPLETE):setVisible(false)
		but1:setVisible(true)
		but2:setVisible(true)
		uikits.event(but1,
						function(sender)
							uikits.pushScene(WorkFlow.create{pid=self._arguments.pid,uid=self._arguments.uid})
						end,'click')
		uikits.event(but2,
						function(sender)
							uikits.pushScene(WorkFlow.create(self._arguments.url2))
						end,'click')		
		local caption = uikits.child(self._root,ui.CAPTION)
		if self._arguments.caption then
			caption:setString( self._arguments.caption )
		end
		local end_date = uikits.child(self._root,ui.END_DATE)
		if self._arguments.finish_time_unix then
			local scheduler = self:getScheduler()
			local end_time = self._arguments.finish_time_unix
			local dt = self._arguments.finish_time_unix - os.time()
			if dt > 0 then
				end_date:setString( kits.toDiffDateString(dt))
				local function timer_func()
					dt = end_time - os.time()
					if dt > 0 then
						end_date:setString(kits.toDiffDateString(dt))
					else
						--过期
						local txt = uikits.child( self._root,ui.TIMELABEL )
						if txt then txt:setString('已过期:') end
						end_date:setString(kits.toDiffDateString(-dt))
						scheduler:unscheduleScriptEntry(self._scID)
						self._scID = nil
					end		
				end
				self._scID = scheduler:scheduleScriptFunc( timer_func,1,false )					
			else
				--过期
				local txt = uikits.child( self._root,ui.TIMELABEL )
				if txt then txt:setString('已过期:') end
				end_date:setString(kits.toDiffDateString(-dt))				
			end
		end
		local obj_num = uikits.child(self._root,ui.OBJECTIVE_NUM)
		if self._arguments.cnt_item then
			obj_num:setString(tostring(self._arguments.cnt_item))
		end
		local subj_num = uikits.child(self._root,ui.SUBJECTIVE_NUM)
		if self._arguments.subjective_num then
			subj_num:setString(tostring(self._arguments.subjective_num))
		end
		local type_txt = uikits.child(self._root,ui.TYPE_TEXT)
		if type_txt and self._arguments.course_name then
			type_txt:setString( self._arguments.course_name )
		end
		local commit = uikits.child(self._root,ui.COMMIT)
		if self._arguments.status ~= 0 then --提交状态,0未提交,10,11已经提交
			commit:setEnabled(false)
		else
			commit:setEnabled(true)
			uikits.event(commit,function(sender)
					--提交
					if self._arguments.status == 0 then
						self:commit()
					end
				end,'click')			
		end	
		if self._arguments.cnt_item_finish and self._arguments.cnt_item and self._arguments.cnt_item_finish > 0 then
			self:setPercent( self._arguments.cnt_item_finish*100.0/self._arguments.cnt_item )
		else
			self:setPercent(0)
		end
	end		
end

function WorkCommit:commit()
	local loadbox = loadingbox.open( self )
	local url = commit_url..'?examId='..self._arguments.exam_id..'&tid='..self._arguments.tid
	local ret = mt.new('GET',url,login.cookie(),
						function(obj)
							if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
								if obj.state == 'OK'  then
									if obj.data then
										kits.write_cache( cache.get_name(url),obj.data)
									end
									--成功提交
									self._arguments = 10 --标记已经提交
									uikits.pushScene( Score.create(self._arguments) )
								else
									--失败
								end
								loadbox:removeFromParent()
							end
						end )
	if not ret then
		--提交失败
		kits.log('WorkCommit:commit error : '..url )
		loadbox:removeFromParent()
	end
end

function WorkCommit:release()
	if self._scID then
		self:getScheduler():unscheduleScriptEntry(self._scID)
		self._scID = nil
	end
end

return WorkCommit