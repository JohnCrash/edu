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
local cookie_student = 'sc1=5B6A71FC333621695A285AC22CEDBF378D849D96ak96OwHoBYOcj3sCd0E24kV%2fbAusZhjjsUzUhMKTulZwFkjPwGhmamK%2b8VOQqknvELD2mN0fxGHdiCYZ%2fXdbaewnwrbp3A%3d%3d'
local worklist_url = 'http://new.www.lejiaolexue.com/student/handler/WorkList.ashx'

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

function WorkList:get_page( i )
	local loadbox = loadingbox.open( self )
	local url = worklist_url..'?p='..i
	--先尝试下载
	local ret = mt.new('GET',url,login.cookie(),
						function(obj)
							if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
								if obj.state == 'OK' and obj.data then
									kits.write_cache( cache.get_name(url),obj.data)
								end
								loadbox:removeFromParent()
							end
						end )
end

function WorkList:init_new_list()
	self:get_page( 0 )
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



function WorkList:init_history_list()
end

function WorkList:init()
	if not self._root then
		self:init_gui()
		self:init_data()
	end
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
	uikits.event(back,function(sender)uikits.popScene()end)
	self._item:setVisible(false)
	local size = self._item:getSize()
	self._item_width = size.width
	self._item_height = size.height
	self._item_ox,self._item_oy = self._item:getPosition()
	
	self._list = {}
end

function WorkList:relayout()
	self._scrollview:setInnerContainerSize(cc.size(self._item_width,self._item_height*(#self._list)))
	for i = 1,#self._list do
		self._list[#self._list-i+1]:setPosition(cc.p(self._item_ox,self._item_height*(i-1)))
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
		local b = text and text:setString( t.cnt_item )
	end
	if t.cnt_item_finish then --完成数量
		local text = uikits.child( item,ui.ITEM_FINISH)
		local b = text and text:setString( t.cnt_item_finish )
	end	
	if t.cnt_item and t.cnt_item_finish then --数量
		local p = t.cnt_item_finish*100/t.cnt_item
		if p > 100 then p = 100 end
		uikits.child( item,ui.ITEM_PERCENT_TEXT):setString( tostring(math.floor(p))..'%' )
		uikits.child( item,ui.ITEM_BAR):setPercent( p )
	end

	if t.finish_time then --结束日期
		local u = uikits.child( item,ui.END_DATE )
		u:setString('')
		t.finish_time_unix = unix_date_by_string( t.finish_time )
		if t.finish_time_unix and os.time() < t.finish_time_unix then
			local scheduler = u:getScheduler()
			local scID
			local end_time = t.finish_time_unix
			local dt = end_time - os.time()
			if dt > 0 then
				u:setString(toDiffDateString(dt))
			end
			local function timer_func()
				dt = end_time - os.time()
				if dt > 0 then
					u:setString(toDiffDateString(dt..'结束'))
				else
					--过期
					u:setString('')
					scheduler:unscheduleScriptEntry(scID)
				end
			end
			scID = scheduler:scheduleScriptFunc( timer_func,1,false )
		end
	end

	uikits.event(item,
			function(sender)
				uikits.pushScene(WorkCommit.create{
					pid=t.paper_id,
					uid=t.teacher_id,
					caption=t.exam_name,
					cnt_item = t.cnt_item,
					cnt_item_finish = t.cnt_item_finish,
					finish_time = t.finish_time,
					in_time = t.in_time,
					})
			end,'click')

	return item
end

function WorkList:release()
end

return WorkList

