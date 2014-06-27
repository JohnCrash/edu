local uikits = require "uikits"
local WorkCommit = require "homework/commit"

local ui = {
	FILE = 'homework/studenthomework_1/studenthomework_1.json',
	BACK = 'white/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
}

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
	self._list = {}
end

function WorkList:init()
	self:init_data()
	
	self._root = uikits.fromJson{file=ui.FILE}
	if self._root then
		self:addChild(self._root)
		self._scrollview = uikits.child(self._root,ui.LIST)
		self._item = uikits.child(self._root,ui.ITEM)
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)cc.Director:getInstance():popScene()end)
		self._item:setVisible(false)
		for i = 1,16 do
			self:add_item()
		end
	end
end

function WorkList:add_item()
	local x,w,h,item
	if #self._list == 0 then
		item = self._item
		item:setVisible(true)
		item:setAnchorPoint(cc.p(0,0))
		self._list[#self._list+1] = item
		x = item:getPosition()
		h = item:getSize().height
	else
		item = self._item:clone()
		x = item:getPosition()
		w = item:getSize().width
		h = item:getSize().height
		self._list[#self._list+1] = item
		self._scrollview:addChild(item)
		self._scrollview:setInnerContainerSize(cc.size(w,h*(#self._list)))
	end
	
	uikits.event(item,
			function(sender)
				cc.Director:getInstance():pushScene(cc.TransitionSlideInL:create(1,WorkCommit.create()))
			end,'click')
	for i = 1,#self._list do
		self._list[#self._list-i+1]:setPosition(cc.p(x,h*(i-1)))
	end
end

function WorkList:release()
end

return WorkList

