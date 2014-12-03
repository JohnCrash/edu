local crash = require "crash"
local json = require "json-c"
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local WorkCommit = require "homework/commit"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"
local messagebox = require "messagebox"

--[[
	lly卢乐颜进行修改部分：
	1. class后，为worklist添加一个属性_laStats_Stu，用于指向统计层
	2. init_gui 里面加载自定义统计层并隐藏
	3. init_statistics 中隐藏原数据列表，显示自定义统计层
	4. init_new_list init_history_list init_setting 中隐藏自定义的统计层
	5. refresh_list 中注释掉 load_statistics 因为刷新列表时不对统计层有效
	6. require 统计层
]]
local moStats = require "homework/lly/LaStatisticsStudent"

crash.open("homework",1)

local course_icon = topics.course_icon
--[[
argument
status:-1
course:-1
timer:-1
type:-1
p:1
--]]
--local worklist_url = 'http://new.www.lejiaolexue.com/student/handler/APIWorkList.ashx'
local worklist_url = 'http://new.www.lejiaolexue.com/student/handler/APIWorkList.ashx'
local ERR_DATA = 1
local ERR_NOTCONNECT = 2

local res_local = "homework/"

local ui = {
	FILE = 'homework/studenthomework_1.json',
	FILE_3_4 = 'homework/studenthomework43.json',
	STATISTICS_FILE = 'homework/statistics.json',
	STATISTICS_FILE_3_4 = 'homework/statistics43.json',
	LOADING_FILE = 'homework/studentloading.json',
	LOADING_FILE_3_4 = 'homework/studentloading43.json',	
	MORE = 'homework/more.json',
	MORE_3_4 = 'homework/more43.json',
	MORE2 = 'homework/more2.json',
	MORE2_3_4 = 'homework/more243.json',
	MORE_VIEW = 'more_view',
	MORE_SOUND = 'sound',
	MORE_DEBUG = 'debug',
	LESSON = 'lesson',
	BACK = 'white/back',
	LIST = 'newview',
	ITEM = 'subject_1',
	ITEM_TEACHER_NAME = 'teacher_name',
	ITEM_TEACHER_LOGO = 'teacher_photo',
	ITEM_TITLE = 'textname',
	ITEM_CURSE = 'subjectbox/subjecttext',
	ITEM_BAR = 'finish2',
	ITEM_PERCENT_TEXT = 'finishtext',
	ITEM_FINISH = 'questionsnumber',
	ITEM_COUNT = 'questions_number1',
	ITEM_COUNT2 = 'questions_number2', --主观题数量
	END_DATE = 'Label_34',
	SCORE = 'fenshu',
	NEW_BUTTON = 'white/new1',
	HISTORY_BUTTON = 'white/history1',
	STATIST_BUTTON = 'white/statistical1',
	SETTING_BUTTON = 'white/more1',
	BUTTON_LINE = 'white/redline',
	ISCOMMIT = 'hassubmitted',
	ISMARK = 'comment',
	MARKING = 'comment2',
	TIMELABEL = 'time_text',
	COMMENT = 'comment',
	HISTORY = 1,
	NEW = 2,
	STATIST = 3,
	SETTING = 4,
	CLASS_TYPE = 'chinese',
	ST_CAPTION = 'lesson1/text1',
	ST_T_C = 'lesson1/text3',
	ST_T_A = 'lesson1/text5',
	ST_T_T = 'lesson1/text7',
	ST_SCROLLVIEW = 'lesson_view',
	ST_MONTH = 'month',
	ST_DATE = 'years',
	ST_COUNT = 'text6',
	ST_AVERAGE='text2',
	ST_TIME='text4',
--	ST_COUNT_BAR='number_bar',
--	ST_AVERAGE_BAR='average_bar',
--	ST_TIME_BAR='time_bar',
	ST_COUNT_TEXT='text_no',
	ST_AVERAGE_TEXT='text_av',
	ST_TIME_TEXT='text_ti',
	
	student_view = 'haizi',
	per_student_view = 'haizi/hz1',
	student_name = 'mingzi',
	student_checkbox = 'CheckBox_22',
}
--[[ home_work_cache json
	{"uri","title","class","data","num","num2","num3","homework"}
--]]
local WorkList = class("WorkList")
WorkList.__index = WorkList

WorkList._laStats_Stu = {} --lly统计层

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

function WorkList:init_data_by_cache()
	local result
	if login.get_uid_type() == login.STUDENT then
		result = kits.read_cache(cache.get_name(worklist_url))
	else
		result = kits.read_cache(cache.get_name(worklist_url..'?uid='..login.get_subuid()))
	end
	if result then
		self._data = json.decode( result )
		self:init_data_list()
	else
		kits.log('error : WorkList:init_data_by_cache result = nil')
	end
end

function WorkList:get_page( i,func )
	local url
	if login.get_uid_type() == login.STUDENT then
		url = worklist_url..'?p='..i
	else
		url = worklist_url..'?p='..i..'&uid='..login.get_subuid()
		--result = kits.read_cache(cache.get_name(worklist_url..'?uid='.._G.hw_cur_child_id))
	end
	--先尝试下载
	cache.request(url,
		function(b)
			func( url,i,b )
		end)
end

local WEEK = 0--7*24*3600

function WorkList:add_page_from_cache( idx,last )
	local url
	if login.get_uid_type() == login.STUDENT then
		url = worklist_url..'?p='..idx
	else
		url = worklist_url..'?p='..idx..'&uid='..login.get_subuid()
	end
	--local url = worklist_url..'?p='..idx
	local result = cache.get_data( url )
	local need_continue = false
	if result then
		local data = kits.decode_json( result )
		if data and data.total and data.esi and type(data.esi)=='table' then
			self._total = data.total
			need_continue = idx < data.total
			for i,v in pairs(data.esi) do
				if v.finish_time then
					local t = kits.unix_date_by_string(v.finish_time)
					local dt = os.time() - t
					--kits.log( 'v.finish_time = '..t..' current='..os.time() )
					if not last then
						if dt < WEEK then --结束作业后+7天
						--	if dt > 0 then
						--		kits.log( '	add:+'..kits.time_to_string(dt) )
						--	else
						--		kits.log( '	add:-'..kits.time_to_string(-dt) )
						--	end
							self:add_item(v)
						else
							need_continue = false
						end
					else
						if dt > WEEK then
						--	if dt > 0 then
						--		kits.log( '	add:+'..kits.time_to_string(dt) )
						--	else
						--		kits.log( '	add:-'..kits.time_to_string(-dt) )
						--	end
							self:add_item(v)
						end
						--	if dt > 0 then
						--		kits.log( '	?:+'..kits.time_to_string(dt) )
						--	else
						--		kits.log( '	?:-'..kits.time_to_string(-dt) )
						--	end
					end
				else
					need_continue = false
				end
			end
		end
	end
	self:relayout()
	return need_continue
end

function WorkList:clear_all_item()
	if self._list then
		for i =1,#self._list do
			local u = uikits.child( self._list[i],ui.END_DATE )
			if u and u._scID then
				u:getScheduler():unscheduleScriptEntry(u._scID)
			end
			if i ~= 1 then
				self._list[i]:removeFromParent()
			else
				self._list[i]:setVisible(false) --第一个是模板
			end
		end
		self._list = {}
	end
end

local g_first = true

function WorkList:load_page( first,last )
	if not self._scID and not self._busy then--and not self._busy then
		self._busy = true
		cache.request_cancel()
		local scheduler = self:getScheduler()
		local idx = first
		local ding = false
		local err = false
		local quit = false
		self.request_cancel = true
		local loadbox
		local local_first = g_first
		if g_first then
			g_first = false
			loadbox = uikits.fromJson{file_9_16=ui.LOADING_FILE,file_3_4=ui.LOADING_FILE_3_4}
			self:addChild(loadbox)
		else
			loadbox = loadingbox.open( self )
		end
		local function close_scheduler()
			if local_first then
			--	cache.clear()
			end
			scheduler:unscheduleScriptEntry(self._scID)
			self._scID = nil
			self._busy = false
			loadbox:removeFromParent()
		end
		local function order_download() --顺序下载,知道大于WEEK,或者大于total
			if err == ERR_DATA then --下载中发生错误
				close_scheduler()
				return
			elseif err == ERR_NOTCONNECT then --没有网络
				close_scheduler()
				return
			end
			if quit then --正常退出
				self._first_idx = 1
				self._last_idx = idx
				close_scheduler()
				return
			end
			if not ding then --正在下载
				ding = true --正常开始下载
				self:get_page( idx,
						function(url,i,b)
							if b then --成功下载完成
								if self:add_page_from_cache( i,last ) then
									if last then
										if idx >= last then
											quit = true
										else
											idx = idx + 1 --继续下载
										end
									else
										idx = idx + 1 --继续下载
									end
								else
									quit = true
								end
							else --下载中发生错误
								err = ERR_NOTCONNECT
								kits.log( 'GET : "'..tostring(url)..'" error!' )
							end
							ding = false
						end )
			end
		end
		self._scID = scheduler:scheduleScriptFunc( order_download,0.1,false )
	end
end

function WorkList:refresh_list()
	if not self._busy then
		cache.request_cancel()
		self._scrollview:clear('slide')
		if self._mode == ui.NEW then
			self:load_page( 1 )
		elseif self._mode == ui.HISTORY then
			self:load_page( 1,5 )
		elseif self._mode == ui.STATIST then
			--self:load_statistics() --lly不会刷新
		end
	end
end

function WorkList:init_new_list()
	if self._busy then return end
	if self._scrollview:isAnimation() then return end
	cache.request_cancel()
	--self:SwapButton( ui.NEW )
	self._scrollview:setVisible(true)
	self._setting:setVisible(false)
	self._laStats_Stu:setVisible(false) --lly关闭统计层
	if not self._scID and not self._busy and self._mode ~= ui.NEW then -- and not self._busy then
		if self._new_list_done then
			self:Swap_list(ui.NEW)
			self._scrollview:relayout('slide')
		else
			--self:clear_all_item()
			self._scrollview:clear('slide')
			self._new_list_done = true
			self:load_page( 1 )
		end
		self._mode = ui.NEW		
	end
	return true
end

function WorkList:init_data()
	local loadbox = loadingbox.open( self )
	local send_url
	if login.get_uid_type() == login.STUDENT then
		send_url = worklist_url
	else
		send_url = worklist_url..'?uid='..login.get_subuid()
	end	
	cache.request( send_url,
		function(b)
			if b then
				self:init_data_by_cache()
			else
				kits.log('Connect faild : '..send_url )
			end
		end)
end

function WorkList:init()
	if not self._root then
		self:init_gui()
	end
	self._tab:set(1)
	self:init_new_list()	
end

function WorkList:init_data_list()
	if self._data and self._data.esi then
		for i,v in pairs(self._data.esi) do
			self:add_item(v)
		end
	end
	self:relayout()
end

function WorkList:clone_statistics_item(v)
	self._statistics_item:setVisible(false)
	local item = self._statistics_item:clone()
	if item then
		item:setVisible(true)
		if v.course and course_icon[v.course] then
			uikits.child(item,ui.ST_CAPTION):setString(course_icon[v.course].name )
		end
		uikits.child(item,ui.ST_T_C):setString(v.t_count)
		if v.t_score and v.t_score>0 then
			uikits.child(item,ui.ST_T_A):setString(v.t_score)
		else
			uikits.child(item,ui.ST_T_A):setString('-')
		end
		uikits.child(item,ui.ST_T_T):setString(v.t_times)
		local scrollview = uikits.child(item,ui.ST_SCROLLVIEW)
		local idx = 1
		local sitem
		local list = {}
		local size
		local ox,oy
		if v.pm and type(v.pm)=='table' then
			for i,t in pairs(v.pm) do
				if t and t.date then
					if idx == 1 then
						sitem = uikits.child(scrollview,ui.ST_MONTH)
						size = sitem:getContentSize()
						ox,oy = sitem:getPosition()
					else
						sitem = uikits.child(scrollview,ui.ST_MONTH):clone()
						scrollview:addChild(sitem)
					end
					--次数
					local ct = uikits.child(sitem,ui.ST_COUNT)
					ct:setString(tostring(t.count))
					--平均分
					local av = uikits.child(sitem,ui.ST_AVERAGE)
					av:setString(tostring(t.scroe))
					--用时
					local ti = uikits.child(sitem,ui.ST_TIME)
					ti:setString(tostring(t.time))
					
					table.insert(list,sitem)
					uikits.child(sitem,ui.ST_DATE):setString(t.date)
					idx = idx + 1
				end
			end
			--排列
			if size then
				scrollview:setInnerContainerSize(cc.size(size.width*#list,size.height))
				for i,t in pairs(list) do
					t:setPosition(cc.p(ox+size.width*(i-1),oy))
				end
			end
		end
		item:setVisible(true)
		self._scrollview._scrollview:addChild(item)
		table.insert( self._scrollview._list,item )
		--self._statistics_list = self._statistics_list or {}
		--table.insert(self._statistics_list,item)
	end
	return item
end

function WorkList:relayout_statistics()
	if self._scrollview._list then
		local height = self._statistics_item_height*(#self._scrollview._list)
		self._scrollview._scrollview:setInnerContainerSize(cc.size(self._statistics_item_width,height))
		local offy = 0
		local size = self._scrollview._scrollview:getContentSize()

		if height < size.height then
			offy = size.height - height --顶到顶
		end

		for i = 1,#self._scrollview._list do
			self._scrollview._list[#self._scrollview._list-i+1]:setPosition(cc.p(self._statistics_item_ox,self._statistics_item_height*(i-1)+offy))
		end
		self._scrollview:relayout_refresh()
	end
end

function WorkList:date_conv(d)
	if d and type(d)=='string' and string.len(d)==6 then
		if string.sub(d,5,5)~='0' then
			return string.sub(d,1,4)..'年'..string.sub(d,-2)..'月'
		else
			return string.sub(d,1,4)..'年'..string.sub(d,-1)..'月'
		end
	else
		return tostring(d)
	end
end
local function minsec(t)
	local mins = math.floor(t/60)
	local sec = t - mins*60
	local result = ''
	if mins ~= 0 then
		result = result..mins..'分'
	end
	if sec ~= 0 then
		result = result..sec..'秒'
	end
	if result == '' then
		result = '-'
	end
	return result
end
function WorkList:statistics_data(t)
	local idx = {}
	for i,v in pairs(t) do
		idx[v.course] = idx[v.course] or {}
		idx[v.course].course = v.course
		if not idx[v.course].t_times then
			idx[v.course].t_times = 0
		end
		idx[v.course].t_times = idx[v.course].t_times + v.cnt_times
		if not idx[v.course].t_count then
			idx[v.course].t_count = 0
		end
		idx[v.course].t_count = idx[v.course].t_count + v.cnt_home_work
		if not idx[v.course].t_score then
			idx[v.course].t_score = 0
		end		
		idx[v.course].t_score = idx[v.course].t_score + v.success_percent
		idx[v.course].pm = idx[v.course].pm or {}
		local score = v.success_percent
		if score and score == -1 then
			score = '-'
		end
		table.insert(idx[v.course].pm,1,
		{
			date=self:date_conv(v.year_month),
			count = v.cnt_home_work,
			time = minsec(v.cnt_times),
			scroe = tostring(score),
		})
	end
	local result = {}
	local i = 1
	for k,v in pairs(idx) do
		if v.pm and type(v.pm)=='table' and #v.pm>0 then
			if v.t_score and type(v.t_score)=='number' then
				v.t_score = v.t_score/#v.pm
			end
			v.t_times = minsec(v.t_times/#v.pm)
		end	
		result[i] = v
		i = i + 1
	end
	return result
end

function WorkList:clear_statistics()
	if self._statistics_list then
		for i ,v in pairs(self._statistics_list) do
			if v then
				v:removeFromParent()
			end
		end
		self._statistics_list = {}
	end
end

function WorkList:load_statistics()
	self._busy = true
	local loadbox = loadingbox.open(self)
	local url = 'http://new.www.lejiaolexue.com/paper/handler/GetStatisticsStudent.ashx'
	local send_url
	if login.get_uid_type() == login.STUDENT then
		send_url = url
	else
		send_url = url..'?uid='..login.get_subuid()
	end		
	cache.request_json( send_url,function(t)
		self._busy = false
		if not loadbox:removeFromParent() then
			return
		end
		if t and type(t)=='table' then
			self._statistics_data = WorkList:statistics_data(t)
			for i,v in pairs(self._statistics_data) do
				self:clone_statistics_item(v)
			end				
			self:relayout_statistics()
		end
	end)
end

function WorkList:init_statistics()
	if self._busy then return end
	--self:SwapButton( ui.STATIST )

	--[[原方法
	self._scrollview:setVisible(true)
	self._setting:setVisible(false)
	
	if self._mode ~= ui.STATIST then
		if self._statistics_list_done then
			self:Swap_list(ui.STATIST)
			self:relayout_statistics()
		else
			self._statistics_list_done = true
			self:Swap_list(ui.STATIST)
			self:load_statistics()
		end
		self._mode = ui.STATIST
	end
	--]]

	--开启统计层
	self._scrollview:setVisible(false) --关闭原有的列表，使用自定义的新层
	self._setting:setVisible(false) --关闭设置层
	self._laStats_Stu:setVisible(true) --开启统计层

	if self._mode ~= ui.STATIST then

		--读取数据
		self._laStats_Stu:enter()

		self._mode = ui.STATIST
	end

	return true
end

function WorkList:init_setting()
	if self._busy then return end
	cache.request_cancel()
	--self:SwapButton( ui.SETTING )
	if login.get_uid_type() == login.PARENT and self.has_download_children == false then
		self:getdatabyurl()	
	end
	self._scrollview:setVisible(false)
	self._setting:setVisible(true)
	self._laStats_Stu:setVisible(false) --lly关闭统计层

	--self._mode = ui.SETTING
	return true
end

function WorkList:SwapButton(s)
	if s == ui.NEW then
		self._redline:setPosition(cc.p(self._new_x,self._redline_y))
	elseif s == ui.HISTORY then
		self._redline:setPosition(cc.p(self._history_x,self._redline_y))
	elseif s == ui.STATIST then
		self._redline:setPosition(cc.p(self._statist_x,self._redline_y))
	elseif s == ui.SETTING then
		self._redline:setPosition(cc.p(self._setting_x,self._redline_y))
	end
end

local student_space = 40
local get_child_info_url = 'http://api.lejiaolexue.com/rest/user/current/closefriend/child'

function WorkList:getdatabyurl()
--[[	local result = kits.http_get(get_child_info_url,login.cookie(),1)
	print(result)
	local tb_result = json.decode(result)
	if 	tb_result.result ~= 0 then				
		print(tb_result.result.." : "..tb_result.message)			
	else
		--local tb_uig = json.decode(tb_result.uig)
		self.childinfo = tb_result.uis
	end	--]]
	local loadbox = loadingbox.open(self)
	cache.request_json( get_child_info_url,function(t)
			if t and type(t)=='table' then
				if t.result ~= 0 then
					loadbox:removeFromParent()
					return false
				else
					self.childinfo = t.uis
					self:show_children()
					self.has_download_children = true
				end
			else
				--既没有网络也没有缓冲
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:getdatabyurl()
					elseif e == messagebox.CLOSE then
						uikits.popScene()
					end
				end,messagebox.RETRY)	
			end
			loadbox:removeFromParent()
		end,'N')
	return true
end

function WorkList:show_children()
	--self:getdatabyurl()
	local student_view = uikits.child(self._setting,ui.student_view)
	student_view:setVisible(true)
	local src_student_view = uikits.child(self._setting,ui.per_student_view)
	src_student_view:setVisible(false)
	local size_student_view = student_view:getContentSize()
	local size_per_student_view = src_student_view:getContentSize()
	local all_student_width = (size_per_student_view.width * (#self.childinfo)) + (student_space*(#self.childinfo-1))
	local pos_x_start = (size_student_view.width - all_student_width)/2

	local function selectedEvent(sender,eventType)
		local checkBox = sender
		if eventType == ccui.CheckBoxEventType.selected then
			if login.get_subuid() == checkBox.uid then
				return
			end
			login.set_subuid(checkBox.uid)
			--_G.hw_cur_child_id = checkBox.uid			
			--local parent_view = checkBox:getParent()
			local parent_view = checkBox.parentview
			local tb_all_student = parent_view:getChildren()
			for i=1,#tb_all_student do 
				local checkBox_temp = uikits.child(tb_all_student[i],ui.student_checkbox)
				if checkBox.uid ~= checkBox_temp.uid then
					checkBox_temp:setSelectedState(false)
				end
			end
			self:init()				
		end
		if eventType == ccui.CheckBoxEventType.unselected then
			if login.get_subuid() == checkBox.uid	then
				checkBox:setSelectedState(true)
			end
		end
	end  

	for i = 1,#self.childinfo do 
		local cur_student_view = src_student_view:clone()
		cur_student_view:setVisible(true)
		student_view:addChild(cur_student_view)
		cur_student_view:setPositionX(pos_x_start)
		local student_name = uikits.child(cur_student_view,ui.student_name)
		local checkBox = uikits.child(cur_student_view,ui.student_checkbox)
		student_name:setString(self.childinfo[i].uname)
		if login.get_subuid() == self.childinfo[i].uid then
			checkBox:setSelectedState(true)
		else
			checkBox:setSelectedState(false)
		end
		checkBox.uid = self.childinfo[i].uid
		checkBox.parentview = student_view
		checkBox:addEventListener(selectedEvent)  
		pos_x_start = pos_x_start+size_per_student_view.width+student_space
	end			
end

function WorkList:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	
	self._statistics_root = uikits.fromJson{file_9_16=ui.STATISTICS_FILE,file_3_4=ui.STATISTICS_FILE_3_4}
	self:addChild(self._statistics_root)
	self._statistics_root:setVisible(false)
	if login.get_uid_type() == login.STUDENT then
		self._setting_root = uikits.fromJson{file_9_16=ui.MORE,file_3_4=ui.MORE_3_4}
		self._setting = uikits.child(self._setting_root,ui.MORE_VIEW):clone()
	else
		self._setting_root = uikits.fromJson{file_9_16=ui.MORE2,file_3_4=ui.MORE2_3_4}
		self._setting = uikits.child(self._setting_root,ui.MORE_VIEW):clone()
		--self:show_children()	
		self.has_download_children = false
	end
	
	local cs = uikits.child(self._setting,ui.MORE_SOUND)
	if cs then
		cs:setSelectedState (kits.config("mute","get"))
		uikits.event(cs,function(sender,b)
			kits.config("mute",b)
			uikits.muteSound(b)
		end)
	end
	local dbg = uikits.child(self._setting,ui.MORE_DEBUG)
	if dbg then
		dbg:setSelectedState (kits.config("debug","get"))
		uikits.event(dbg,function(sender,b)
			kits.config("debug",b)
			if _G.enableDebug then
				_G.enableDebug(b)
			end
		end)
	end
	
	self._root:addChild(self._setting)
	
	self:addChild(self._root)
	--self._scrollview = uikits.child(self._root,ui.LIST)
	--self._item = uikits.child(self._root,ui.ITEM)
	self._scrollview = uikits.scroll(self._root,ui.LIST,ui.ITEM)
	self._scrollview:refresh(
		function(state)
			self:refresh_list()
		end)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,
		function(sender)
			--if not self._busy then
				g_first = true
				uikits.popScene()
			--end
		end)
	--[[
	self._item:setVisible(false)
	local size = self._item:getContentSize()
	self._item_width = size.width
	self._item_height = size.height
	self._item_ox,self._item_oy = self._item:getPosition()
	--]]
	local statistics_item = uikits.child(self._statistics_root,ui.LESSON)
	self._statistics_item = statistics_item
	if statistics_item then
		size = statistics_item:getContentSize()
		self._statistics_item_width = size.width
		self._statistics_item_height = size.height
		self._statistics_item_ox,self._statistics_item_oy = statistics_item:getPosition()
	end

	self._tab = uikits.tab(self._root,ui.BUTTON_LINE,
		{
		[ui.NEW_BUTTON]=function(sender) return self:init_new_list() end,
		[ui.HISTORY_BUTTON]=function(sender) return self:init_history_list() end,
		[ui.STATIST_BUTTON]=function(sender) return self:init_statistics() end,
		[ui.SETTING_BUTTON]=function(sender) return self:init_setting() end,
		})
--[[
	uikits.event( self._scrollview,
		function(sender,t)
			if self._mode == ui.HISTORY then
				if t == ccui.ScrollviewEventType.scrollToTop then
					self:history_scroll( t )
				elseif t == ccui.ScrollviewEventType.scrollToBottom then
					self:history_scroll( t )
				end
			end
		end)
	self._list = {}
	--]]

	--lly添加统计层，并先隐藏
	self._laStats_Stu = moStats.Class:create()
	if self._laStats_Stu then
		self._root:addChild(self._laStats_Stu, 1)
		self._laStats_Stu:setVisible(false)
	end
end

function WorkList:Swap_list( new_mode )
	self._scrollview:swap_by_index( self._mode,new_mode )
end

function WorkList:init_history_list()
	if self._busy then return end
	if self._scrollview:isAnimation() then return end
	cache.request_cancel()
	--self:SwapButton( ui.HISTORY )
	self._scrollview:setVisible(true)
	self._setting:setVisible(false)
	self._laStats_Stu:setVisible(false) --lly关闭统计层

	if not self._scID and not self._busy and self._mode ~= ui.HISTORY then --and not self._busy then
		if self._history_list_done then
			self:Swap_list(ui.HISTORY)
			self._scrollview:relayout('slide')
		else
			self._history_list_done = true
			self:Swap_list(ui.HISTORY)
			self:load_page( 1,5 )	
		end
		self._mode = ui.HISTORY
	end
	return true
end

function WorkList:history_scroll( t )
	if t == ccui.ScrollviewEventType.scrollToTop then
		if self._first_idx and self._first_idx == 1 then
			self._scrollview:setBounceEnabled( true )
			return
		end
	elseif t == ccui.ScrollviewEventType.scrollToBottom then
		if self._last_idx and self._last_idx == self._total then
			self._scrollview:setBounceEnabled( true )
			return
		end
		--继续载入
		self._scrollview:setBounceEnabled( false )
		if self._last_idx then
			self:load_page( self._last_idx+1,self._last_idx+6 ) --一次最多装载5页
		else
			if not self._scID then --只有在没有下载的情况下才跟新
				self:clear_all_item()
				self:load_page( 1 )
			end
		end
	end
end

function WorkList:relayout()
	self._scrollview:relayout('slide')
end

function WorkList:add_item( t )
	local item = self._scrollview:additem()

	if t.exam_name then --作业名称
		uikits.child( item,ui.ITEM_TITLE):setString( t.exam_name )
	end
--	if t.course_name then --科目名称
--		uikits.child( item,ui.ITEM_CURSE):setString( t.course_name )
--	end
	if t.teacher_name then
		local item = uikits.child( item,ui.ITEM_TEACHER_NAME)
		item:setString( t.teacher_name )
	end
	if t.teacher_id then
		login.get_logo( t.teacher_id,
		function(name)
			if name then
				local item = uikits.child( item,ui.ITEM_TEACHER_LOGO)
				item:loadTexture( name )
			else
				kits.log("get logo fail"..tostring(t.teacher_id))
			end
		end,3)
	end
	if t.course and course_icon[t.course] and course_icon[t.course].logo then --类型
		local pic =  uikits.child(item,ui.CLASS_TYPE)
		pic:loadTexture(res_local..course_icon[t.course].logo)
		local size = pic:getContentSize()
	else
		--默认设置
	end
	if t.cnt_item and t.cnt_item_finish then --数量
		local text = uikits.child( item,ui.ITEM_COUNT)
		local b = text and text:setString( tostring(t.cnt_item) )
	end
	if t.cnt_item and t.cnt_item_finish then --数量
		local p = t.cnt_item_finish*100/t.cnt_item
		if p > 100 then p = 100 end
		uikits.child( item,ui.ITEM_PERCENT_TEXT):setString( tostring(math.floor(p))..'%' )
		uikits.child( item,ui.ITEM_BAR):setPercent( p )
	end
	
	local isc = uikits.child( item,ui.ISCOMMIT )
	local issee = uikits.child( item,ui.ISMARK )
	local marking = uikits.child( item,ui.MARKING )	
	if t.status then --提交状态,0未提交,10,11已经提交
		if isc and issee and marking then
			if t.status == 10 or  t.status == 11 then
				isc:setVisible( false )
				issee:setVisible( false )
				marking:setVisible( true )
			else
				isc:setVisible( true )
				issee:setVisible( false )
				marking:setVisible( false )
			end
		else
			kits.log("WARNING WorkList:add_item isc noc marking = nil")
		end
	else
		kits.log("WARNING WorkList:add_item t.status = nil")
	end
	--分数
	if t.real_score then
		uikits.child(item,ui.SCORE):setString( tostring(t.real_score) )
	end
	--已经批改标记
	if t.status and (t.status == 10 or  t.status == 11) then
		uikits.child(item,ui.COMMENT):setVisible(true)
	else
		uikits.child(item,ui.COMMENT):setVisible(false)
	end
	if t.finish_time then --结束日期
		local u = uikits.child( item,ui.END_DATE )
		u:setString('')
		t.finish_time_unix = kits.unix_date_by_string( t.finish_time )
		if t.finish_time_unix and os.time() < t.finish_time_unix then
			local scheduler = u:getScheduler()
			local end_time = t.finish_time_unix
			local dt = end_time - os.time()
			local txt = uikits.child( item,ui.TIMELABEL )
			if dt > 0 then
				if txt then txt:setString('剩余结束时间:') end
				u:setString(kits.time_to_string_simple(dt))
			else
				if txt then txt:setString('已过期:') end
			end
			local _scID
			local function timer_func()
				if not cc_isobj(item) or not cc_isobj(u) then 
					scheduler:unscheduleScriptEntry(_scID)
					_scID = nil
					return 
				end
				dt = end_time - os.time()
				local txt = uikits.child( item,ui.TIMELABEL )
				if dt > 0 then					
					if txt then txt:setString('剩余结束时间:') end
					u:setString(kits.time_to_string_simple(dt))
				else
					--过期
					if txt then txt:setString('已过期:') end
					u:setString(kits.time_to_string_simple(-dt))
					scheduler:unscheduleScriptEntry(_scID)
					_scID = nil
				end
			end
			_scID = scheduler:scheduleScriptFunc( timer_func,1,false )
		elseif  t.finish_time_unix then
			--过期
			local dt = t.finish_time_unix - os.time()
			local txt = uikits.child( item,ui.TIMELABEL )
			if txt then txt:setString('已过期:') end
			u:setString(kits.time_to_string_simple(-dt))		
		end
	end

	uikits.event(item,
			function(sender)
				--if not self._busy then
					if t.is_res and t.is_res == 1 then
						--一键导入题，提示不能做
						messagebox.open(self,function()end,
						messagebox.MESSAGE,"提示",'“一键导入作业”请到网站上作答！')
					else
						cache.request_cancel()
						uikits.pushScene(WorkCommit.create{
							pid=t.paper_id,
							tid=t.teacher_id,
							teacher_name = t.teacher_name,
							caption=t.exam_name,
							cnt_item = t.cnt_item,
							cnt_item_finish = t.cnt_item_finish,
							finish_time = t.finish_time,
							in_time = t.in_time,
							status = t.status,
							course_name = t.course_name,
							course_id = t.course,
							finish_time_unix = t.finish_time_unix,
							exam_id = t.exam_id,
							real_score = t.real_score,
							total_time = t.total_time,
							uid = login.uid(),
							parent = self,
							})
					end
				--end
			end,'click')

	return item
end

function WorkList:release()
	self:clear_all_item()
end

return WorkList

