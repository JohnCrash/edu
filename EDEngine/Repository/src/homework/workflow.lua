local uikits = require "uikits"

local ui = {
	FILE = 'homework/z21_1/z21_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	ITEM_CURRENT = 'state_past',
	ITEM_FINISHED = 'state_now',
	ITEM_UNFINISHED = 'state_future'
}

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
	
	for i,v in pairs(self._data) do
		self:add_item( v )
	end
	self:relayout()
end

function WorkFlow:relayout()
	if self._scrollview then
		self._scrollview:setInnerContainerSize(cc.size(self._item_width,self._item_height*(#self._list)))
		for i,v in ipairs(self._list) do
			
		end
	end
end

function WorkFlow:add_item( t )
	local item
	item = self._item_finished:clone()
	self._list[#self._list+1] = item
	self._scrollview:addChild(item)
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