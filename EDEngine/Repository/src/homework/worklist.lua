local json = require "json"
local kits = require "kits"
local uikits = require "uikits"
local login = require 'login'
local WorkCommit = require "homework/commit"

--[[
argument
status:-1
course:-1
timer:-1
type:-1
p:1
--]]
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
	ITEM_COUNT = 'questionsnumbe'
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

function WorkList:init_data()
	local reslut = kits.read_cache("homework.json")
	if reslut then
		self._data = json.decode(reslut)
	end
end

function WorkList:init()
	if not self._root then
		self:init_data()
		self:init_gui()
	end
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
	if self._data and self._data.esi then
		for i,v in pairs(self._data.esi) do
			self:add_item(v)
		end
	end
	self:relayout()
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
		uikits.child( item,ui.ITEM_PERCENT_TEXT):setString( tostring(math.floor(p))..'%' )
		uikits.child( item,ui.ITEM_BAR):setPercent( p )
	end
	
	uikits.event(item,
			function(sender)
				uikits.pushScene(WorkCommit)
			end,'click')
	return item
end

function WorkList:release()
end

return WorkList

