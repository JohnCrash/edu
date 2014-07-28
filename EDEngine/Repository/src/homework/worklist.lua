local json = require "json-c"
local kits = require "kits"
local uikits = require "uikits"
local login = require 'login'
local cache = require "cache"
local WorkCommit = require "homework/commit"
local loadingbox = require "homework/loadingbox"
local topics = require "homework/topics"

--[[
argument
status:-1
course:-1
timer:-1
type:-1
p:1
--]]
local worklist_url = 'http://new.www.lejiaolexue.com/student/handler/WorkList.ashx'
local ERR_DATA = 1
local ERR_NOTCONNECT = 2

local res_local = "homework/studenthomework_1/"
local course={
	[101]={name="综合科目",logo=""},
	[10001]={name="小学语文",logo="chinese1"},
	[10002]={name="小学数学",logo="math"},
	[10003]={name="小学英语",logo="english"},
	[10005]={name="小学英语笔试",logo="english"},
	[10009]={name="(小学)信息技术",logo="infomation"},
	[10010]={name="(小学)安全知识",logo=""},
	[10011]={name="(小学)智力百科",logo=""},
	[11005]={name="小学英语听力",logo="english"},
	[20001]={name="初中语文",logo="chinese1"},
	[20002]={name="初中数学",logo="math"},
	[20003]={name="初中英语",logo="english"},
	[20004]={name="初中物理",logo="physics"},
	[20005]={name="初中化学",logo="chemistry"},
	[20006]={name="初中政治",logo="politics"},
	[20007]={name="初中生物",logo="biolody"},
	[20008]={name="初中地理",logo="geography"},
	[20009]={name="初中历史",logo="history"},
	[30001]={name="高中语文",logo="chinese1"},
	[30002]={name="高中数学",logo="math"},
	[30003]={name="高中英语",logo="english"},
	[30004]={name="高中物理",logo="physics"},
	[30005]={name="高中化学",logo="chemistry"},
	[30006]={name="高中政治",logo="politics"},
	[30007]={name="高中生物",logo="biolody"},
	[30008]={name="高中地理",logo="geography"},
	[30009]={name="高中历史",logo="history"},
}

local ui = {
	FILE = 'homework/studenthomework_1.json',
	FILE_3_4 = 'homework/studenthomework43.json',
	STATISTICS_FILE = 'homework/statistics.json',
	STATISTICS_FILE_3_4 = 'homework/statistics43.json',
	MORE = 'homework/more.json',
	MORE_3_4 = 'homework/more43.json',
	MORE_VIEW = 'more_view',
	LESSON = 'lesson',
	BACK = 'white/back',
	LIST = 'newview',
	ITEM = 'newview/subject_1',
	ITEM_TITLE = 'textname',
	ITEM_CURSE = 'subjectbox/subjecttext',
	ITEM_BAR = 'finish2',
	ITEM_PERCENT_TEXT = 'finishtext',
	ITEM_FINISH = 'questionsnumber',
	ITEM_COUNT = 'questions_number1',
	ITEM_COUNT2 = 'questions_number2', --主观题数量
	END_DATE = 'Label_34',
	SCORE = 'Label_37',
	NEW_BUTTON = 'white/new1',
	HISTORY_BUTTON = 'white/history1',
	STATIST_BUTTON = 'white/statistical1',
	SETTING_BUTTON = 'white/more1',
	BUTTON_LINE = 'white/redline',
	ISCOMMIT = 'hassubmitted',
	NOCOMMIT = 'not_submitted',
	TIMELABEL = 'time_text',
	COMMENT = 'comment',
	HISTORY = 1,
	NEW = 2,
	STATIST = 3,
	SETTING = 4,
	CLASS_TYPE = 'chinese',
	ST_CAPTION = 'lesson1/text1',
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
}
--[[ home_work_cache json
	{"uri","title","class","data","num","num2","num3","homework"}
--]]
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

function WorkList:init_data_by_cache()
	local result = kits.read_cache(cache.get_name(worklist_url))
	if result then
		self._data = json.decode( result )
		self:init_data_list()
	else
		kits.log('error : WorkList:init_data_by_cache result = nil')
	end
end

function WorkList:get_page( i,func )
	local url = worklist_url..'?p='..i
	--先尝试下载
	cache.download(url,login.cookie(),
		function(b)
			func( url,i,b )
		end)
end

local WEEK = 0--7*24*3600

function WorkList:add_page_from_cache( idx,last )
	local url = worklist_url..'?p='..idx
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
					kits.log( 'v.finish_time = '..t..' current='..os.time() )
					if not last then
						if dt < WEEK then --结束作业后+7天
							if dt > 0 then
								kits.log( '	add:+'..kits.toDiffDateString(dt) )
							else
								kits.log( '	add:-'..kits.toDiffDateString(-dt) )
							end
							self:add_item(v)
						else
							kits.log( '	stop' )
							need_continue = false
						end
					else
						if dt > WEEK then
							if dt > 0 then
								kits.log( '	add:+'..kits.toDiffDateString(dt) )
							else
								kits.log( '	add:-'..kits.toDiffDateString(-dt) )
							end
							self:add_item(v)
						end
							if dt > 0 then
								kits.log( '	?:+'..kits.toDiffDateString(dt) )
							else
								kits.log( '	?:-'..kits.toDiffDateString(-dt) )
							end
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

function WorkList:load_page( first,last )
	if not self._scID and not self._busy then
		local loadbox = loadingbox.open( self )
		local scheduler = self:getScheduler()
		local idx = first
		local ding = false
		local err = false
		local quit = false
		self._busy = true
		local function close_scheduler()
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
							else --现在中发生错误
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

function WorkList:init_new_list()
	self:SwapButton( ui.NEW )
	self:show_statistics(false)
	self:show_list(true)
	self._setting:setVisible(false)
	
	if not self._scID and not self._busy then
		self._mode = nil
		self:clear_all_item()
		self:load_page( 1 )
	end
end

function WorkList:init_data()
	local loadbox = loadingbox.open( self )
	cache.download( worklist_url,login.cookie(),
		function(b)
			if b then
				self:init_data_by_cache()
			else
				kits.log('Connect faild : '..worklist_url )
			end
		end)
end

function WorkList:init()
	if not self._root then
		self:init_gui()
	end
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
	local item = self._statistics_item:clone()
	if item then
		if v.course and course[v.course] then
			uikits.child(item,ui.ST_CAPTION):setString(course[v.course].name )
		end
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
			scrollview:setInnerContainerSize(cc.size(size.width*#list,size.height))
			for i,t in pairs(list) do
				t:setPosition(cc.p(ox+size.width*(i-1),oy))
			end
		end
		item:setVisible(true)
		self._scrollview:addChild(item)
		self._statistics_list = self._statistics_list or {}
		table.insert(self._statistics_list,item)
	end
	return item
end

function WorkList:show_statistics(b)
	if self._statistics_list then
		for i,v in pairs(self._statistics_list) do
			v:setVisible(b)
		end
	end
end

function WorkList:show_list(b)
	if self._list then
		for i,v in pairs(self._list) do
			v:setVisible(b)
		end
	end
end

function WorkList:relayout_statistics()
	if self._statistics_list then
		local height = self._statistics_item_height*(#self._statistics_list)
		self._scrollview:setInnerContainerSize(cc.size(self._statistics_item_width,height))
		local offy = 0
		local size = self._scrollview:getContentSize()
		print( 'height = '..height )
		print( '_statistics_item_width = '..self._statistics_item_width )
		if height < size.height then
			offy = size.height - height --顶到顶
		end

		for i = 1,#self._statistics_list do
			self._statistics_list[#self._statistics_list-i+1]:setPosition(cc.p(self._statistics_item_ox,self._statistics_item_height*(i-1)+offy))
		end
	end
end

function WorkList:init_statistics()
	self:SwapButton( ui.STATIST )
	self:show_statistics(true)
	self:show_list(false)
	self._setting:setVisible(false)
	if not self._statistics_data then
		local result = kits.read_cache('statatics.json')
		local msg
		if result then
			self._statistics_data,msg = json.decode(result)
		end
		if self._statistics_data and type(self._statistics_data)=='table' then
			for i,v in pairs(self._statistics_data) do
				self:clone_statistics_item(v)
			end
		else
			kits.log('decode json error:'..tostring(msg))
		end		
	end
	self:relayout_statistics()
end

function WorkList:init_setting()
	self:SwapButton( ui.SETTING )
	self:show_statistics(false)
	self:show_list(false)
	self._setting:setVisible(true)
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

function WorkList:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	
	self._statistics_root = uikits.fromJson{file_9_16=ui.STATISTICS_FILE,file_3_4=ui.STATISTICS_FILE_3_4}
	self:addChild(self._statistics_root)
	self._statistics_root:setVisible(false)
	
	self._setting_root = uikits.fromJson{file_9_16=ui.MORE,file_3_4=ui.MORE_3_4}
	self._setting = uikits.child(self._setting_root,ui.MORE_VIEW):clone()
	
	self._root:addChild(self._setting)
	
	self:addChild(self._root)
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._item = uikits.child(self._root,ui.ITEM)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,
		function(sender)
			if not self._busy then
				uikits.popScene()
			end
		end)
	self._item:setVisible(false)
	local size = self._item:getContentSize()
	self._item_width = size.width
	self._item_height = size.height
	self._item_ox,self._item_oy = self._item:getPosition()
	local statistics_item = uikits.child(self._statistics_root,ui.LESSON)
	self._statistics_item = statistics_item
	if statistics_item then
		size = statistics_item:getContentSize()
		self._statistics_item_width = size.width
		self._statistics_item_height = size.height
		self._statistics_item_ox,self._statistics_item_oy = statistics_item:getPosition()
	end
	
	self._new_button = uikits.child(self._root,ui.NEW_BUTTON)
	uikits.event( self._new_button,
		function(sender)
			self:init_new_list()
		end)
	
	self._redline = uikits.child(self._root,ui.BUTTON_LINE)
	
	self._new_x,self._redline_y = self._redline:getPosition()
	self._history_button = uikits.child(self._root,ui.HISTORY_BUTTON)
	self._history_x = self._new_x + self._history_button:getContentSize().width
	
	uikits.event( self._history_button,
		function(sender)
			self:init_history_list()
		end)
	self._statist_button = uikits.child(self._root,ui.STATIST_BUTTON)
	self._statist_x = self._history_x + self._statist_button:getContentSize().width
	
	uikits.event( self._statist_button,
		function(sender)
			self:init_statistics()
		end)
		
	self._setting_button = uikits.child(self._root,ui.SETTING_BUTTON)
	self._setting_x = self._statist_x + self._setting_button:getContentSize().width
	
	uikits.event( self._setting_button,
		function(sender)
			self:init_setting()
		end)
	
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
end

function WorkList:init_history_list()
	self:SwapButton( ui.HISTORY )
	self:show_statistics(false)
	self:show_list(true)
	self._setting:setVisible(false)
	
	if not self._scID and not self._busy then
		self._mode = ui.HISTORY
		self:clear_all_item()
		self:load_page( 1,5 )
	end
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
			self:load_page( self._last+1,self._last+6 ) --一次最多装载5页
		else
			self:clear_all_item()
			self:load_page( 1 )
		end
	end
end

function WorkList:relayout()
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

function WorkList:add_item( t )
	local item
	if #self._list == 0 then
		item = self._item
		item:setVisible(true)
		item:setAnchorPoint(cc.p(0,0))
		self._list[#self._list+1] = item
	else
		item = self._item:clone()
		self._list[#self._list+1] = item
		self._scrollview:addChild(item)
	end

	if t.exam_name then --作业名称
		uikits.child( item,ui.ITEM_TITLE):setString( t.exam_name )
	end
	if t.course_name then --科目名称
		uikits.child( item,ui.ITEM_CURSE):setString( t.course_name )
	end
	if t.course and course[t.course] and course[t.course].logo then --类型
		uikits.child(item,ui.CLASS_TYPE):loadTexture(res_local..course[t.class_id].logo..'.jpg')
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
	if t.status then --提交状态,0未提交,10,11已经提交
		local isc = uikits.child( item,ui.ISCOMMIT )
		local noc = uikits.child( item,ui.NOCOMMIT )
		if isc and noc then
			if t.status ~= 0 then
				isc:setVisible( true )
				noc:setVisible( false )
			else
				isc:setVisible( false )
				noc:setVisible( true )
			end
		end
	end
	--分数
	if t.real_score then
		uikits.child(item,ui.SCORE):setString( tostring(t.real_score) )
	end
	--已经批改标记
	if false then
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
			if dt > 0 then
				u:setString(kits.toDiffDateString(dt))
			end
			local function timer_func()
				dt = end_time - os.time()
				if dt > 0 then
					u:setString(kits.toDiffDateString(dt))
				else
					--过期
					local txt = uikits.child( item,ui.TIMELABEL )
					if txt then txt:setString('已过期:') end
					u:setString(kits.toDiffDateString(-dt))
					scheduler:unscheduleScriptEntry(u._scID)
					u._scID = nil
				end
			end
			u._scID = scheduler:scheduleScriptFunc( timer_func,1,false )
		elseif  t.finish_time_unix then
			--过期
			local dt = t.finish_time_unix - os.time()
			local txt = uikits.child( item,ui.TIMELABEL )
			if txt then txt:setString('已过期:') end
			u:setString(kits.toDiffDateString(-dt))		
		end
	end

	uikits.event(item,
			function(sender)
				if not self._busy then
					uikits.pushScene(WorkCommit.create{
						pid=t.paper_id,
						tid=t.teacher_id,
						caption=t.exam_name,
						cnt_item = t.cnt_item,
						cnt_item_finish = t.cnt_item_finish,
						finish_time = t.finish_time,
						in_time = t.in_time,
						status = t.status,
						course_name = t.course_name,
						finish_time_unix = t.finish_time_unix,
						exam_id = t.exam_id,
						uid = login.uid(),
						})
				end
			end,'click')

	return item
end

function WorkList:release()
	self:clear_all_item()
end

return WorkList

