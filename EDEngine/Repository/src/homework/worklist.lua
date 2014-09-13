local crash = require "crash"
local json = require "json-c"
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local WorkCommit = require "homework/commit"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"

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
local worklist_url = 'http://new.www.lejiaolexue.com/student/handler/WorkList.ashx'
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
	MORE_VIEW = 'more_view',
	MORE_SOUND = 'sound',
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
	cache.request(url,
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
	if not self._scID then--and not self._busy then
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
				cache.clear()
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

function WorkList:init_new_list()
	--if self._busy then return end
	cache.request_cancel()
	--self:SwapButton( ui.NEW )
	self:show_statistics(false)
	self:show_list(true)
	self._setting:setVisible(false)
	
	if not self._scID then -- and not self._busy then
		self._mode = nil
		self:clear_all_item()
		self:load_page( 1 )
	end
	return true
end

function WorkList:init_data()
	local loadbox = loadingbox.open( self )
	cache.request( worklist_url,
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
	local item = self._statistics_item:clone()
	if item then
		if v.course and course_icon[v.course] then
			uikits.child(item,ui.ST_CAPTION):setString(course_icon[v.course].name )
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
	--if self._busy then return end
	cache.request_cancel()
	--self:SwapButton( ui.STATIST )
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
	return true
end

function WorkList:init_setting()
	--if self._busy then return end
	cache.request_cancel()
	--self:SwapButton( ui.SETTING )
	self:show_statistics(false)
	self:show_list(false)
	self._setting:setVisible(true)
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

function WorkList:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	
	self._statistics_root = uikits.fromJson{file_9_16=ui.STATISTICS_FILE,file_3_4=ui.STATISTICS_FILE_3_4}
	self:addChild(self._statistics_root)
	self._statistics_root:setVisible(false)
	
	self._setting_root = uikits.fromJson{file_9_16=ui.MORE,file_3_4=ui.MORE_3_4}
	self._setting = uikits.child(self._setting_root,ui.MORE_VIEW):clone()
	
	local cs = uikits.child(self._setting,ui.MORE_SOUND)
	if cs then
		cs:setSelectedState (kits.config("mute","get"))
		uikits.event(cs,function(sender,b)
			kits.config("mute",b)
			uikits.muteSound(b)
		end)
	end
	self._root:addChild(self._setting)
	
	self:addChild(self._root)
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._item = uikits.child(self._root,ui.ITEM)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,
		function(sender)
			--if not self._busy then
				g_first = true
				uikits.popScene()
			--end
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
	
	self._tab = uikits.tab(self._root,ui.BUTTON_LINE,
		{
		[ui.NEW_BUTTON]=function(sender) return self:init_new_list() end,
		[ui.HISTORY_BUTTON]=function(sender) return self:init_history_list() end,
		[ui.STATIST_BUTTON]=function(sender) return self:init_statistics() end,
		[ui.SETTING_BUTTON]=function(sender) return self:init_setting() end,
		})

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
	--if self._busy then return end
	cache.request_cancel()
	--self:SwapButton( ui.HISTORY )
	self:show_statistics(false)
	self:show_list(true)
	self._setting:setVisible(false)
	
	if not self._scID then --and not self._busy then
		self._mode = ui.HISTORY
		self:clear_all_item()
		self:load_page( 1,5 )
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
--	if t.course_name then --科目名称
--		uikits.child( item,ui.ITEM_CURSE):setString( t.course_name )
--	end
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
			if dt > 0 then
				u:setString(kits.time_to_string(dt))
			end
			local function timer_func()
				dt = end_time - os.time()
				if dt > 0 then
					u:setString(kits.time_to_string(dt))
				else
					--过期
					local txt = uikits.child( item,ui.TIMELABEL )
					if txt then txt:setString('已过期:') end
					u:setString(kits.time_to_string(-dt))
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
			u:setString(kits.time_to_string(-dt))		
		end
	end

	uikits.event(item,
			function(sender)
				--if not self._busy then
					cache.request_cancel()
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
						course_id = t.course,
						finish_time_unix = t.finish_time_unix,
						exam_id = t.exam_id,
						real_score = t.real_score,
						total_time = t.total_time,
						uid = login.uid(),
						})
				--end
			end,'click')

	return item
end

function WorkList:release()
	self:clear_all_item()
end

return WorkList

