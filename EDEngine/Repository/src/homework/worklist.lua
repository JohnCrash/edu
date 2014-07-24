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

local ui = {
	FILE = 'homework/studenthomework_1/studenthomework_1.json',
	STATISTICS_FILE = 'homework/statistics_1/statistics_1.json',
	MORE = 'homework/more_1/more_1.json',
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
	NEW_HOT_BUTTON = 'white/new2',
	HISTORY_BUTTON = 'white/history1',
	HISTORY_HOT_BUTTON = 'white/history2',
	STATIST_BUTTON = 'white/statistical1',
	STATIST_HOT_BUTTON = 'white/statistical2',
	SETTING_BUTTON = 'white/more1',
	SETTING_HOT_BUTTON = 'white/more2',
	ISCOMMIT = 'hassubmitted',
	NOCOMMIT = 'not_submitted',
	TIMELABEL = 'time_text',
	COMMENT = 'comment',
	HISTORY = 1,
	NEW = 2,
	STATIST = 3,
	SETTING = 4,
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
	self._scrollview:setVisible(true)
	self._statistics:setVisible(false)
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

function WorkList:init_statistics()
	self:SwapButton( ui.STATIST )
	self._scrollview:setVisible(false)
	self._statistics:setVisible(true)
	self._setting:setVisible(false)
end

function WorkList:init_setting()
	self:SwapButton( ui.SETTING )
	self._scrollview:setVisible(false)
	self._statistics:setVisible(false)	
	self._setting:setVisible(true)
end

function WorkList:SwapButton(s)
	if s == ui.NEW then
		self._new_button:setVisible(false)
		self._new_button2:setVisible(true)
	else
		self._new_button:setVisible(true)
		self._new_button2:setVisible(false)	
	end
	if s == ui.HISTORY then
		self._history_button:setVisible(false)
		self._history_button2:setVisible(true)	
	else
		self._history_button:setVisible(true)
		self._history_button2:setVisible(false)		
	end
	if s == ui.STATIST then
		self._statist_button:setVisible(false)
		self._statist_button2:setVisible(true)	
	else
		self._statist_button:setVisible(true)
		self._statist_button2:setVisible(false)	
	end
	if s == ui.SETTING then
		self._setting_button:setVisible(false)
		self._setting_button2:setVisible(true)		
	else
		self._setting_button:setVisible(true)
		self._setting_button2:setVisible(false)		
	end
end

function WorkList:init_gui()
	self._root = uikits.fromJson{file=ui.FILE}
	
	self._statistics_root = uikits.fromJson{file=ui.STATISTICS_FILE}
	self._statistics = uikits.child(self._statistics_root,ui.LESSON):clone()
	
	self._setting_root = uikits.fromJson{file=ui.MORE}
	self._setting = uikits.child(self._setting_root,ui.MORE_VIEW):clone()
	
	self._root:addChild(self._statistics)
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
	local size = self._item:getSize()
	self._item_width = size.width
	self._item_height = size.height
	self._item_ox,self._item_oy = self._item:getPosition()
	
	self._new_button = uikits.child(self._root,ui.NEW_BUTTON)
	uikits.event( self._new_button,
		function(sender)
			self:init_new_list()
		end)
	self._new_button2 = uikits.child(self._root,ui.NEW_HOT_BUTTON)
	uikits.event( self._new_button2,
		function(sender)
			self:init_new_list()
		end)
	
	self._history_button = uikits.child(self._root,ui.HISTORY_BUTTON)
	uikits.event( self._history_button,
		function(sender)
			self:init_history_list()
		end)
	self._history_button2 = uikits.child(self._root,ui.HISTORY_HOT_BUTTON)
	uikits.event( self._history_button2,
		function(sender)
			self:init_history_list()
		end)
		
	self._statist_button = uikits.child(self._root,ui.STATIST_BUTTON)
	uikits.event( self._statist_button,
		function(sender)
			self:init_statistics()
		end)
	self._statist_button2 = uikits.child(self._root,ui.STATIST_HOT_BUTTON)
	uikits.event( self._statist_button2,
		function(sender)
			self:init_statistics()
		end)
		
	self._setting_button = uikits.child(self._root,ui.SETTING_BUTTON)
	uikits.event( self._setting_button,
		function(sender)
			self:init_setting()
		end)
	self._setting_button2 = uikits.child(self._root,ui.SETTING_HOT_BUTTON)
	uikits.event( self._setting_button2,
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
	self._scrollview:setVisible(true)
	self._statistics:setVisible(false)
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
	local size = self._scrollview:getSize()
	
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

