local uikits = require "uikits"

local ui = {
	FILE = 'homework/z22_1/z22_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	ITEM_CURRENT = 'state_now',
	ITEM_FINISHED = 'state_past',
	ITEM_UNFINISHED = 'state_future',
	NEXT_BUTTON = 'milk_write/next_problem', 
	FINISH_BUTTON = 'milk_write/finish_5',
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,	
	PAGE_VIEW = 'homework_view',
}

local Subjective = class("Subjective")
Subjective.__index = Subjective

function Subjective.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Subjective)
	
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

function Subjective:clone_item( state )
	if state == ui.STATE_CURRENT then
		return self._item_current:clone()
	elseif state == ui.STATE_FINISHED then
		return self._item_finished:clone()
	elseif state == ui.STATE_UNFINISHED then
		return self._item_unfinished:clone()
	else
		kits.log( '	ERROR: clone_item state = '..tostring(state) )
	end
end

function Subjective:set_item_state( i,ste )
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

function Subjective:set_current( i )
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
		self:set_anwser_field(i)
	end
end

function Subjective:add_item( t )
	t.state = t.state or ui.STATE_UNFINISHED
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
		local layout = uikits.scrollview{bgcolor=cc.c3b(255,255,255)}
		--layout:addChild(uikits.text{caption='Page'..#self._list,fontSize=32})
		self._pageview:addPage( layout )
		--layout:setTouchEnabled(false)
		--self:set_image( #self._list )
	else
		kits.log( '	ERROR: clone_item() return nil' )
	end
end

function Subjective:next_item()
	if self._current and self._current < #self._list then
		self:set_current( self._current+1 )
	end
end

function Subjective:save()
end

function Subjective:init()
	if not self._root then
		self._list = {}
		self._root = uikits.fromJson{file=ui.FILE}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
		self:addChild(self._root)
		
		self._scrollview = uikits.child(self._root,ui.LIST)
		self._contentview = uikits.child(self._root,ui.PAGE_VIEW)
		self._contentview_size = self._contentview:getSize()
		local x_,y_ = self._contentview:getPosition()
		local anp = self._contentview:getAnchorPoint()
		self._pageview = uikits.pageview{
			bgcolor=cc.c3b(128,128,128),
			x = x_,
			y = y_,
			anchorX = anp.x,
			anchorY = anp.y,
			width=self._contentview_size.width,
			height=self._contentview_size.height}
		self._contentview:setVisible(false)
		self._root:addChild( self._pageview )
		
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
		self._finish_button = uikits.child(self._root,ui.FINISH_BUTTON )
		self._next_button:setVisible(true)
		self._finish_button:setVisible(false)
		uikits.event( self._next_button,
					function(sender)
						self:next_item()
					end,'click')
		uikits.event( self._finish_button,
					function(sender)
						--保存
						self:save()
						uikits.popScene()
					end,'click')		
		local x
		x,self._item_y = self._item_current:getPosition()				
	end
end

function Subjective:release()
	
end

return Subjective