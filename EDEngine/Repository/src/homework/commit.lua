local json = require "json-c"
local kits = require "kits"
local uikits = require "uikits"
local topics = require "homework/topics"
local WorkFlow = require "homework/workflow"
local Subjective = require "homework/subjective"
local Score = require "homework/score"
local loadingbox = require "loadingbox"
local StudentWatch = require "homework/studentwatch"
local cache = require "cache"
local login = require "login"
local messagebox = require "messagebox"
--[[
local ui = {
	FILE = 'homework/commit.json',
	FILE_3_4 = 'homework/commit43.json',
	BACK = 'white/back',
	CAPTION = 'white/lesson_name',
	END_DATE = 'white/time_over',
	LIST = 'top_view',
	NAME = 'name',
	PHOTO = 'student_logo_1',
	TIME = 'time_student',
	NUMBER = 'number_1',
	ITEM = 'top_view/top_1',
	TOPICS = 'red_case',
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
--]]
local ui = {
	FILE = 'homework/commit.json',
	FILE_3_4 = 'homework/commit43.json',
	BACK = 'white/back',
	CAPTION = 'white/lesson_name',
	END_DATE = 'white/time_over',
	LIST = 'top_view',
	NAME = 'name',
	PHOTO = 'student_logo_1',
	TIME = 'time_student',
	NUMBER = 'number_1',
	ITEM = 'top_view/top_1',
	TOPICS = 'red_case',
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
--[[
	取得提交顺序
--]]
local commit_sort_url = ''
--[[
	取得作业表
--]]
local loadpaper_url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx"
local loadextam_url = "http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx"
local commit_answer_url = 'http://new.www.lejiaolexue.com/student/handler/SubmitAnswer.ashx'
local cloud_answer_url = 'http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx'
--local commit_url = 'http://new.www.lejiaolexue.com/student/SubmitPaper.aspx'
local commit_url = 'http://new.www.lejiaolexue.com/student/handler/submitpaper.ashx'
local commit_list_url = 'http://new.www.lejiaolexue.com/student/handler/GetSubmitPaperSequence.ashx'
local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/current'

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
			layer._args = t
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

function WorkCommit:addCommitStudent( id,na,ti )
	local item
	if self._item then
		item = self._item:clone()
	end
	if item then
		self._list = self._list or {}
		self._list[#self._list+1] = item	
		item:setVisible( true )
		local num = uikits.child(item,ui.NUMBER)
		if num then
			num:setString( tostring(#self._list) )
		end
		local name = uikits.child(item,ui.NAME)
		if name then
			name:setString( na )
		end
		local commit_time = uikits.child(item,ui.TIME)
		if commit_time and ti and type(ti)=='string' then
			local d = os.time()-kits.unix_date_by_string(ti)
			commit_time:setString(kits.time_to_string_simple(d))
		end
		local photo = uikits.child(item,ui.PHOTO)
		if photo then
			local url = login.get_logo(id)
			cache.request( url,
				function(b)
					if b then
						photo:loadTexture( cache.get_name(url) )
					else
						kits.log('error : WorkCommit:addCommitStudent request logo')
					end
				end)
		end
		self._scrollview:addChild( item )
	end
end

function WorkCommit:relayoutScroolView()
	if not self._list then return end
	
	local height = self._item_height*(#self._list)
	self._scrollview:setInnerContainerSize(cc.size(self._item_width,height))
	local offy = 0
	local size = self._scrollview:getContentSize()
	
	if height < size.height then
		offy = size.height - height --顶到顶
	end

	for i = 1,#self._list do
		self._list[#self._list-i+1]:setPosition(cc.p(self._item_ox,self._item_height*(i-1)+offy))
	end
end

function WorkCommit:init_commit_list_by_table( t )
	if t and type(t)=='table' then
		local ldt = {}
		for i,v in pairs(t) do --将没提交的删除
			if v.status == 10 or v.status == 11 then
				table.insert(ldt,v)
			end
		end
		uikits.scrollview_step_add(self._scrollview,ldt,9,function(v)
			if v then 
				if type(v) == 'table' and v.student_id and v.student_name and v.finish_time then
					self:addCommitStudent( v.student_id,v.student_name,v.finish_time )
				end
			else
				self:relayoutScroolView()
			end
		end)
		self:relayoutScroolView()
	end
end

function WorkCommit:clear_commit_list()
	if self._list then
		for i,v in pairs(self._list) do
			v:removeFromParent()
		end
		self._list = {}
	end
end
--提交列表
function WorkCommit:init_commit_list()
	if self._args and self._args.exam_id and self._args.tid and self._scrollview then
		self:clear_commit_list()
		local url = commit_list_url..'?examId='..self._args.exam_id..'&teacherId='..self._args.tid
		local function load_from_cache()
			local data = cache.get_data(url)
			if data then
				local result = json.decode(data)
				if result then
					self:init_commit_list_by_table( result )
				else
					kits.log("error : WorkCommit:init_commit_lis decode failed")
				end
			end
		end
		local circle = loadingbox.circle( self._scrollview )
		cache.request(url,
			function(b)
				if circle and cc_isobj(circle) then
					circle:removeFromParent()
				else
					kits.log('WARNING : WorkCommit:init_commit_list circle is not obj')
					return
				end
				if b then
					load_from_cache()
				else
					kits.log( 'error : WorkCommit:init_commit_list '..url )
				end
			end)
	else
		kits.log('ERROR WorkCommit:init_commit_list _args _args invalid')
	end
end

function WorkCommit:init_student_page()
	local but1
	local but2
	--if self._args.cnt_item_finish and self._args.cnt_item and self._args.cnt_item <=self._args.cnt_item_finish and 
	--只要已经提交就不能进入做作业了
	if self._args.status == 10 or self._args.status == 11 then
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
	if self._args.status == 10 or self._args.status == 11 then --提交状态,0,1未提交,10,11已经提交
		uikits.event(but1,
						function(sender)
							uikits.pushScene(StudentWatch.create(self._args))
						end,'click')		
	else
		uikits.event(but1,
						function(sender)
							uikits.pushScene(WorkFlow.create(self._args))
						end,'click')
	end
	uikits.event(but2,
					function(sender)
						uikits.pushScene(Subjective.create(self._args.url2))
					end,'click')		
end

function WorkCommit:init_parents_page()
	local but1
	uikits.child(self._root,ui.WORKFLOW):setVisible(false)
	but1 = uikits.child(self._root,ui.WORKFLOW_COMPLETE)
	uikits.child(self._root,ui.WORKFLOW2_COMPLETE):setVisible(false)
	but1:setVisible(true)
	uikits.event(but1,
					function(sender)
						uikits.pushScene(StudentWatch.create(self._args))
					end,'click')		
end

function WorkCommit:init_commit_page()
	if self._args then
		if self._args._user_type and type(self._args._user_type)=='table' and self._args._user_type.result==0 and 
			self._args._user_type.uig and (self._args._user_type.uig[1].user_role==2 or self._args._user_type.uig[1].user_role==3) then
			self:init_parents_page()
		else
			self:init_student_page()
		end
		local caption = uikits.child(self._root,ui.CAPTION)
		if self._args.caption then
			caption:setString( self._args.caption )
		end
		local end_date = uikits.child(self._root,ui.END_DATE)
		if self._args.finish_time_unix then
			local scheduler = self:getScheduler()
			local end_time = self._args.finish_time_unix
			local dt = self._args.finish_time_unix - os.time()
			if dt > 0 then
				end_date:setString( kits.time_to_string_simple(dt))
				local function timer_func()
					dt = end_time - os.time()
					if dt > 0 then
						end_date:setString(kits.time_to_string_simple(dt))
					else
						--过期
						local txt = uikits.child( self._root,ui.TIMELABEL )
						if txt then txt:setString('已过期:') end
						end_date:setString(kits.time_to_string_simple(-dt))
						scheduler:unscheduleScriptEntry(self._scID)
						self._scID = nil
					end		
				end
				self._scID = scheduler:scheduleScriptFunc( timer_func,1,false )					
			else
				--过期
				local txt = uikits.child( self._root,ui.TIMELABEL )
				if txt then txt:setString('已过期:') end
				end_date:setString(kits.time_to_string_simple(-dt))				
			end
		end
		local obj_num = uikits.child(self._root,ui.OBJECTIVE_NUM)
		if self._args.cnt_item then
			obj_num:setString(tostring(self._args.cnt_item))
		end
		local subj_num = uikits.child(self._root,ui.SUBJECTIVE_NUM)
		if self._args.subjective_num then
			subj_num:setString(tostring(self._args.subjective_num))
		end
		local type_txt = uikits.child(self._root,ui.TYPE_TEXT)
		if type_txt and self._args.course_name then
			type_txt:setString( self._args.course_name )
		end
		local commit = uikits.child(self._root,ui.COMMIT)
		if self._args.status == 10 or self._args.status == 11 then --提交状态,0未提交,10,11已经提交
			commit:setBright(false)
			commit:setHighlighted(false)
			commit:setVisible(false)
			commit:setEnabled(false)
			--临时修改
			uikits.event(commit,function(sender)
					uikits.pushScene( Score.create(self._args) )
				end,'click')				
		else
			if self._args.cnt_item_finish>=self._args.cnt_item then
				commit:setEnabled(true)
				commit:setBright(true)
			else
				commit:setEnabled(false)
				commit:setBright(false)			
			end
			commit:setVisible(true)
			commit:setHighlighted(true)
			uikits.event(commit,function(sender)
					--提交
					if self._args.status == 0 or self._args.status == 1 then
						self:commit()
					end
				end,'click')			
		end
		if self._args.cnt_item_finish and self._args.cnt_item and self._args.cnt_item_finish > 0 then
			self:setPercent( math.floor(self._args.cnt_item_finish*100.0/self._args.cnt_item) )
		else
			self:setPercent(0)
		end
		self:init_commit_list()
	end
end

function WorkCommit:init()
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		self._scrollview = uikits.child( self._root,ui.LIST )
		self._item = uikits.child( self._root,ui.ITEM )
		self._topics = uikits.child( self._root,ui.TOPICS)
		if self._item then
			self._item:setVisible(false)
			local size = self._item:getContentSize()
			self._item_width = size.width
			self._item_height = size.height
		end
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				cache.request_cancel()
				uikits.popScene()
			end)
		
		self:init_star()
	end						
	--加载作业,然后计算出客观题和主观题数量
	--做作业时也使用该数据.
	
	local url_topics
	if self._args.exam_id then
		--取作业
		url_topics = loadextam_url..'?examId='..self._args.exam_id..'&teacherId='..self._args.tid
		--取得以前做的答案
		self._topics_table = topics.read( self._args.exam_id ) or {}
	elseif self._args.pid then
		--取卷面
		url_topics = loadpaper_url..'?pid='..self._args.pid..'&uid='..self._args.uid
		--取得以前做的答案
		self._topics_table = topics.read( self._args.pid ) or {}
	else
		kits.log('error : WorkFlow:init_data exam_id=nil and pid=nil')
		return
	end
	kits.log('WorkCommit:init request :'..url_topics )
	local loadbox = loadingbox.open( self )
	local ret = cache.request_json( url_topics,function(t)
				if not loadbox:removeFromParent() then
					return
				end
				if t then
					self._args._exam_table = t
					self._args.url_topics = url_topics
					--统计能做的客观题数量
					self._args.cnt_item = self:calc_objective_num(t)
					self:init_user_type()
				else
					--既没有网络也没有缓冲
					messagebox.open(self,function(e)
						if e == messagebox.TRY then
							self:init()
						elseif e == messagebox.CLOSE then
							uikits.popScene()
						end
					end,messagebox.RETRY)					
				end
			end)	
end

function WorkCommit:init_user_type()
	local url = get_uesr_info_url
	local loadbox = loadingbox.open( self )
	cache.request_json( url,function(t)
		if not loadbox:removeFromParent() then
			return
		end
		if t then
			self._args._user_type = t
		end
		self:init_commit_page()
	end)
end

--计算客观题数量
function WorkCommit:calc_objective_num(t)
	local ds
	if t.item and type(t.item)=='table' then
		ds = t.item
	else
		ds = t
	end
	local count = 0
	if ds then
		for i,v in pairs(ds) do
			if v.item_type and topics.types[v.item_type] then
				count = count + 1
			end
		end
	end
	return count
end

function WorkCommit:commit_topics( v )
	local answer
	local answer
	if v and v.my_answer and type(v.my_answer)=='string' then
		answer = v.my_answer
	elseif v and v.my_answer and type(v.my_answer)=='table' then
		answer = ''
		for i,v in pairs(v.my_answer) do
			if i ~= 1 then answer = answer..',' end
			answer = answer..v
		end
	else
		kits.log('ERROR commit my_answer invalid')
		return
	end	
	local url = commit_answer_url..'?examId='..tostring(self._args.exam_id)
	..'&itemId='..tostring(v.item_id)
	..'&answer='..tostring(answer)
	..'&times='..v.user_time --做题题目计时器
	..'&tid='..tostring(self._args.tid)
	local ret = mt.new('GET',url,login.cookie(),
					function(obj)
						if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
							if obj.state == 'OK' and obj.data then
								self._faild_commit_count = self._faild_commit_count-1
								kits.log('	commit '..url..' success!')
							else
								self._faild_commit_flag = true
								kits.log('ERROR : WorkFlow:commit_topics')
								kits.log('	commit '..url..' faild!')
							end
						end
					end )
	if not ret then
		self._faild_commit_flag = true
		kits.log('ERROR : WorkFlow:commit_topics')
		kits.log('	commit '..url..' faild!')
	end
end

function WorkCommit:commit_topics()	
	--做题的时候有可能没有正确提交答案，这里再次检查。
	self._faild_commit_count = 0
	self._faild_commit_flag = false
	if self._topics_table and  self._topics_table.answers then
		for k,v in pairs(self._topics_table.answers) do
			if v.commit_faild then --做题过程中没有正确提交
				self._faild_commit_count = self._faild_commit_count+1
				self:commit_topics{my_answer=v.answers,user_time=v.user_time}
			end
		end
	else
		kits.log('ERROR WorkCommit:commit self._topics_table = nil')
		return
	end
end

function WorkCommit:commit()	
	if self._commitSCID then 
		return
	end
	local scheduler = self:getScheduler()
	local step = 0
	local function close_scheduler()
		if self._commitSCID then
			self:getScheduler():unscheduleScriptEntry(self._commitSCID)
			self._commitSCID = nil
		end
	end
	local function commit_func(dt)
		if step==0 then
			--处理还没有提交的题
			step = 1
			self:commit_topics()
		elseif step == 1 then
			--检查是否全部成功
			if self._faild_commit_flag then --上传中发生错误
				step = 3
				close_scheduler()
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:commit()
					end
				end,messagebox.RETRY)
			elseif self._faild_commit_count <= 0 then
				step = 2
			end
		elseif step==2 then
			--开始提交作业
			step = 3
			close_scheduler()
			local loadbox = loadingbox.open( self )
			local url = commit_url..'?examId='..self._args.exam_id..'&tid='..self._args.tid
			cache.request_json(url,
				function(t)
					loadbox:removeFromParent()
					if t then
						self._args.status = 10 --标记已经提交
						self._args.commit_order = t.num
						self._args.workflow_time = t.times
						uikits.pushScene( Score.create(self._args) )
					else
						--加入提交失败的对话框
						messagebox.open(self,function(e)
							if e == messagebox.TRY then
								self:commit()
							end
						end,messagebox.RETRY)						
						kits.log('WorkCommit:commit error : '..url )
					end
				end)				
		end
	end
	self._commitSCID = scheduler:scheduleScriptFunc( commit_func,0.05,false )
end

function WorkCommit:release()
	if self._scID then
		self:getScheduler():unscheduleScriptEntry(self._scID)
		self._scID = nil
	end
	if self._commitSCID then
		self:getScheduler():unscheduleScriptEntry(self._commitSCID)
		self._commitSCID = nil
	end
end

return WorkCommit