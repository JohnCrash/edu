local json = require "json"
local kits = require "kits"
local uikits = require "uikits"
local login = require 'login'
local mt = require "mt"
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
local function my_print( a )
	print( a )
end
local worklist_url = 'http://new.www.lejiaolexue.com/student/handler/WorkList.ashx'
local ERR_DATA = 1
local ERR_NOTCONNECT = 2
local HISTORY = 1
local ui = {
	FILE = 'homework/studenthomework_1/studenthomework_1.json',
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
	END_DATE = 'time',
	NEW_BUTTON = 'white/new2',
	HISTORY_BUTTON = 'white/history1',
	STATIST_BUTTON = 'white/statistical1',
	ISCOMMIT = 'hassubmitted',
}
--[[ home_work_cache json
	{"uri","title","class","data","num","num2","num3","homework"}
--]]
local WorkList = class("WorkList")
WorkList.__index = WorkList

--'/Date(1405425300000+0800)/'
local function unix_date_by_string( str )
	local t = string.match( str,"(%d+)%+0800" )
	if t then
		local d = tonumber( t )
		if d then
			return d/1000
		end
	end
end

local function toDiffDateString( d )
	local day = math.floor( d /(3600*24) )
	local hours = math.floor( (d - day*3600*24)/3600 )
	local mins = math.floor( (d - day*3600*24 - hours*3600)/60 )
	local sec = math.floor( d - day*3600*24 - hours*3600-mins*60 )
	local result = ''
	if day > 0 then
		result = result..day..'天'
	end
	if hours > 0 or day > 0 then
		result = result..hours..'时'
	end
	if mins > 0 or hours > 0 or day > 0 then
		result = result..mins..'分'
	end
	result = result..sec..'秒'
	return result
end

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
		my_print('error : WorkList:init_data_by_cache result = nil')
	end
end

function WorkList:get_page( i,func )
	local url = worklist_url..'?p='..i
	--先尝试下载
	local ret = mt.new('GET',url,login.cookie(),
						function(obj)
							if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
								if obj.state == 'OK' and obj.data then
									kits.write_cache( cache.get_name(url),obj.data)
									func( url,i,true )
								else
									func( url,i,false )
								end
							end
						end )
	if not ret then
		--没有网络
	end
	return ret
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
					local t = unix_date_by_string(v.finish_time)
					local dt = os.time() - t
					print( 'v.finish_time = '..t..' current='..os.time() )
					if not last then
						if dt < WEEK then --结束作业后+7天
							if dt > 0 then
								print( '	add:+'..toDiffDateString(dt) )
							else
								print( '	add:-'..toDiffDateString(-dt) )
							end
							self:add_item(v)
						else
							print( '	stop' )
							need_continue = false
						end
					else
						if dt > WEEK then
							if dt > 0 then
								print( '	add:+'..toDiffDateString(dt) )
							else
								print( '	add:-'..toDiffDateString(-dt) )
							end
							self:add_item(v)
						end
							if dt > 0 then
								print( '	?:+'..toDiffDateString(dt) )
							else
								print( '	?:-'..toDiffDateString(-dt) )
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
				local ret = self:get_page( idx,
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
								err = ERR_DATA
								my_print( 'GET : "'..tostring(url)..'" error!' )
							end
							ding = false
						end )
				if ret then
					ding = true --正常开始下载
				else
					err = ERR_NOTCONNECT
					my_print( 'GET : "'..idx..'" error!' )
				end
			end
		end
		self._scID = scheduler:scheduleScriptFunc( order_download,0.1,false )
	end
end

function WorkList:init_new_list()
	if not self._scID and not self._busy then
		self._mode = nil
		self:clear_all_item()
		self:load_page( 1 )
	end
end

function WorkList:init_data()
	local loadbox = loadingbox.open( self )
	--先尝试下载
	local ret = mt.new('GET',worklist_url,login.cookie(),
						function(obj)
							if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
								if obj.state == 'OK' and obj.data then
									kits.write_cache( cache.get_name(worklist_url),obj.data)
								end
								loadbox:removeFromParent()
								self:init_data_by_cache()
							end
						end )
	if not ret then
		--加载失败,无网络运行
		my_print('Connect faild : '..worklist_url )
		loadbox:removeFromParent()
		self:init_data_by_cache()
	end
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

function WorkList:init_gui()
	self._root = uikits.fromJson{file=ui.FILE}
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
	uikits.event( uikits.child(self._root,ui.NEW_BUTTON),
		function(sender)
			self:init_new_list()
		end)
	uikits.event( uikits.child(self._root,ui.HISTORY_BUTTON),
		function(sender)
			self:init_history_list()
		end)
	uikits.event( uikits.child(self._root,ui.STATIST_BUTTON),
		function(sender)
		end)

	uikits.event( self._scrollview,
		function(sender,t)
			if self._mode == HISTORY then
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
	if not self._scID and not self._busy then
		self._mode = HISTORY
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
		if isc then
			if t.status == 0 then
				isc:setVisible( true )
			else
				isc:setVisible( false )
			end
		end
	end
	if t.finish_time then --结束日期
		local u = uikits.child( item,ui.END_DATE )
		u:setString('')
		t.finish_time_unix = unix_date_by_string( t.finish_time )
		if t.finish_time_unix and os.time() < t.finish_time_unix then
			local scheduler = u:getScheduler()
			local end_time = t.finish_time_unix
			local dt = end_time - os.time()
			if dt > 0 then
				u:setString(toDiffDateString(dt))
			end
			local function timer_func()
				dt = end_time - os.time()
				if dt > 0 then
					u:setString(toDiffDateString(dt))
				else
					--过期
					u:setString('')
					scheduler:unscheduleScriptEntry(u._scID)
				end
			end
			u._scID = scheduler:scheduleScriptFunc( timer_func,1,false )
		end
	end

	uikits.event(item,
			function(sender)
				if not self._busy then
					uikits.pushScene(WorkCommit.create{
						pid=t.paper_id,
						uid=t.teacher_id,
						caption=t.exam_name,
						cnt_item = t.cnt_item,
						cnt_item_finish = t.cnt_item_finish,
						finish_time = t.finish_time,
						in_time = t.in_time,
						})
				end
			end,'click')

	return item
end

function WorkList:release()
	self:clear_all_item()
end

return WorkList

