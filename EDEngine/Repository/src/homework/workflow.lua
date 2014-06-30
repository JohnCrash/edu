local uikits = require "uikits"

local ui = {
	FILE = 'homework/z21_1/z21_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	NEXT_BUTTON = 'milk_write/next_problem',
	ITEM_CURRENT = 'state_past',
	ITEM_FINISHED = 'state_now',
	ITEM_UNFINISHED = 'state_future',
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,
}

--[[
item
{
	id,
	image,
	url,
	type,
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
			v.state = ui.STATE_UNFINISHED
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
		if ste == ui.STATE_CURRENT then
			item = self._item_current:clone()
		elseif ste == ui.STATE_FINISHED then
			item = self._item_finished:clone()
		elseif ste == ui.STATE_UNFINISHED then
			item = self._item_unfinished:clone()
		else
			return
		end
		local n = uikits.child(item,ui.ITEM_NUM )
		n:setString( s )
		item:setPosition( cc.p(x,y) )
		item:setVisible(true)
		self._list[i] = item
		self._scrollview:addChild(item)	
		uikits.event(item,function(sender) self:set_current( i ) end,'click')		
	end
end

function WorkFlow:next_item()
	if self._current and self._current < #self._list then
		self:set_current( self._current+1 )
	end
end

function WorkFlow:set_current( i )
	self:set_item_state( i,ui.STATE_CURRENT )
	if self._current then
			self:set_item_state(self._current,self._data[self._current].state)
	end
	self._current = i
end

function WorkFlow:add_item( t )
	local item = self._item_unfinished:clone()
	local n = uikits.child(item,ui.ITEM_NUM)
	n:setString( tostring(#self._list + 1) )
	self._list[#self._list+1] = item
	item:setVisible(true)
	self._scrollview:addChild(item)
	local index = #self._list
	uikits.event(item,function(sender) self:set_current( index ) end,'click')
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