local uikits = require "uikits"

local ui = {
	FILE = 'homework/z21_1/z21_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	PAGE_VIEW = 'questions_view',
	NEXT_BUTTON = 'milk_write/next_problem',
	ITEM_CURRENT = 'state_past',
	ITEM_FINISHED = 'state_now',
	ITEM_UNFINISHED = 'state_future',
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,
	ANSWER_FIELD = 'milk_side',
	TYPE_IMG = 'item',
	OPTION_A = 'option_a',
	OPTION_B = 'option_b',
	OPTION_C = 'option_c',
	OPTION_D = 'option_d',
	OPTION_E = 'option_e',
	OPTION_F = 'option_f',
	OPTION_G = 'option_g',
	OPTION_H = 'option_h',
	OPTION_YES = 'option_right',
	OPTION_NO = 'option_wrong',
	EDIT_1 = 'option_write_1',
	EDIT_2 = 'option_write_2',
	EDIT_3 = 'option_write_3',
	EDIT_4 = 'option_write_4',
	LINK_TEXT = 'option_connection',
	DRAG_TEXT = 'option_drag',
	POSITION_TEXT = 'option_position',
	POSITION_SORT = 'option_sort',
}

--[[
item
{
	image,
	isload, --图片已经存在
	item_type, --题型
	isdone,
}
--]]
local WorkFlow = class("WorkFlow")
WorkFlow.__index = WorkFlow

function WorkFlow.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkFlow)
	
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

function WorkFlow:init_data()
	local reslut = kits.read_cache("job1.json")
	if reslut then
		self._data = json.decode(reslut)
		for i,v in ipairs(self._data) do
			--test
			if not v.state then
				v.state = ui.STATE_UNFINISHED
			end
			if not v.isload then
				v.isload = true
			end
		end
	end
end

function WorkFlow:init_gui()
	self._root = uikits.fromJson{file=ui.FILE}
	self:addChild(self._root)
	uikits.event(uikits.child(self._root,ui.BACK),function(sender)
		uikits.popScene()
		end)
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._pageview = uikits.child(self._root,ui.PAGE_VIEW)
	self._pageview_size = self._pageview:getSize()
	uikits.event(self._pageview,
			function(sender,eventType)
				if eventType == ccui.PageViewEventType.turning then
					local i = sender:getCurPageIndex()
					self:set_current( i+1 )
				end				
			end)
	self._item_current = uikits.child(self._scrollview,ui.ITEM_CURRENT)
	self._item_finished = uikits.child(self._scrollview,ui.ITEM_FINISHED)
	self._item_unfinished = uikits.child(self._scrollview,ui.ITEM_UNFINISHED)
	
	self._item_current:setVisible(false)
	self._item_finished:setVisible(false)
	self._item_unfinished:setVisible(false)

	self._item_size = self._item_current:getSize()
	
	self._next_button = uikits.child(self._root,ui.NEXT_BUTTON )
	uikits.event( self._next_button,
				function(sender)
					self:next_item()
				end,'click')
				
	self:init_anser_gui()
	
	local x
	x,self._item_y = self._item_current:getPosition()
	for i,v in pairs(self._data) do
		self:add_item( v )
	end
	self:set_current(1)
	self:relayout()
end

function WorkFlow:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width,self._item_size.height*(#self._list)))
		for i,v in ipairs(self._list) do
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
		end
	end
end

function WorkFlow:set_item_state( i,ste )
	if self._list[i] then
		local item = self._list[i]
		local num = uikits.child(item,ui.ITEM_NUM)
		local s = num:getString()
		local x,y = item:getPosition()
		item:removeFromParent()
		item = self:clone_item(ste)
		local n = uikits.child(item,ui.ITEM_NUM )
		n:setString( s )
		item:setPosition( cc.p(x,y) )
		item:setVisible(true)
		self._list[i] = item
		self._scrollview:addChild(item)	
		local index = i
		uikits.event(item,function(sender) self:set_current( index ) end,'click')		
	end
end

function WorkFlow:clone_item( state )
	if state == ui.STATE_CURRENT then
		return self._item_current:clone()
	elseif state == ui.STATE_FINISHED then
		return self._item_finished:clone()
	elseif state == ui.STATE_UNFINISHED then
		return self._item_unfinished:clone()
	end
end

function WorkFlow:next_item()
	if self._current and self._current < #self._list then
		self:set_current( self._current+1 )
	end
end

function WorkFlow:set_current( i )
	if self._current ~= i then
		self:set_item_state( i,ui.STATE_CURRENT )
		if self._current then
				self:set_item_state(self._current,self._data[self._current].state)
		end
		self._current = i
		local ps = self._pageview:getCurPageIndex()+1
		if ps ~= i then
			self._pageview:scrollToPage(i-1)
		end
	end
end

function WorkFlow:set_image( i )
	if not self._data[i].isset and self._data[i].isload then
		local layout = self._pageview:getPage( i-1 )
		if layout then
			local img = uikits.image{image=self._data[i].image,x=self._pageview_size.width/2,y=self._pageview_size.height/2,anchorX=0.5,anchorY=0.5}
			img:setScaleX(2)
			img:setScaleY(2)
			layout:addChild(img)
			self._data[i].isset = true
		end
	elseif not self._data[i].isload then
		--download?
	end
end

function WorkFlow:add_item( t )
	local item = self:clone_item( t.state )
	if item then
		local n = uikits.child(item,ui.ITEM_NUM)
		n:setString( tostring(#self._list + 1) )
		self._list[#self._list+1] = item
		item:setVisible(true)
		self._scrollview:addChild(item)
		local index = #self._list
		uikits.event(item,function(sender) self:set_current( index ) end,'click')
		--add page
		local layout = uikits.layout{bgcolor=cc.c3b(255,255,255)}
		layout:addChild(uikits.text{caption='Page'..#self._list,fontSize=32})
		self._pageview:addPage( layout )
		self:set_image( #self._list )
	end
end

function WorkFlow:init_anser_gui()
	local a = uikits.child(self._root,ui.ANSWER_FIELD)
	self._answer_field = a
	self._answer_type = uikits.child(a,ui.TYPE_IMG)
	print("_answer_type = "..cc_type(self._answer_type))
end

local anwser_type = {
	[1] = {name='判断',img='true_or_false_item.png'},
	[2] = {name='单选',img='single_item.png'},
	[3] = {name='多选',img='multiple_item.png'},
	[4] = {name='连线',img='connection_item.png'},
	[11] = {name='单拖放',img='drag_item.png'},
	[12] = {name='多拖放',img='drag_item.png'},
}
function WorkFlow:set_anwser_type( t )
	if anwser_type[t] then
		self._answer_type:loadTexture(anwser_type[t].img)
	end
end

function WorkFlow:set_anwser_field( i )
	if self._data[i] then
		set_anwser_type( self._data[i].item_type )
	end
end

function WorkFlow:init()
	if not self._root then
		self:init_data()
		
		self._list = {}
		self:init_gui()
	end
end

function WorkFlow:release()
end

return WorkFlow