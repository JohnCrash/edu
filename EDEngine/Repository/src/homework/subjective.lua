local kits = require "kits"
local uikits = require "uikits"
local json = require "json-c"

local ui = {
	FILE = 'homework/z22_1/z22_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	ITEM_CURRENT = 'state_now',
	ITEM_FINISHED = 'state_past',
	ITEM_UNFINISHED = 'state_future',
	NEXT_BUTTON = 'milk_write/next_problem', 
	FINISH_BUTTON = 'milk_write/finish_5',
	TEACHER_VIEW = 'teacher_view',
	TOPICS = 'teacher_view/homework_text',
	RECORD_BUTTON = 'white_3/recording',
	CAM_BUTTON = 'white_3/photograph',
	PHOTO_BUTTON = 'white_3/photo',
	
	AUDIO_VIEW = 'chat_view',
	AUDIO_BUTTON = 'chat',
	AUDIO_TIME = 'chat_time',
	AUDIO_DELETE_BUTTON = 'delete',
	
	PICTURE_VIEW = 'picture_view',
	PICTURE_PIC = 'picture',
	PICTURE_DELETE_BUTTON = 'delete',
	
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
		--self:set_anwser_field(i)
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
		local layout = self._contentview:clone()

		layout:setVisible(true)
		local topics = uikits.child(layout,ui.TOPICS)
		topics:setString( t.topics )
		
		local audio_view = uikits.child(layout,ui.AUDIO_VIEW)
		audio_view:setVisible(false)
		
		local picture_view = uikits.child(layout,ui.PICTURE_VIEW)
		picture_view:setVisible(false)
		
		self._pageview:addPage( layout )
	else
		kits.log( '	ERROR: clone_item() return nil' )
	end
end

function Subjective:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width*(#self._list+1),self._item_size.height))
		local b = true
		for i,v in ipairs(self._list) do
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
			if v.state == ui.STATE_UNFINISHED then
				b = false
			end
		end
		if b then
			self._next_button:setVisible(false)
			self._finish_button:setVisible(true)
		else
			self._next_button:setVisible(true)
			self._finish_button:setVisible(false)		
		end		
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
	self:init_data()
	self:init_gui()
end

function Subjective:init_data()
	if self._args and self._args.pid then
	else
		local res = kits.read_cache('sujective.json')
		if res then
			print( res )
			local t = json.decode(res)
			if t and type(t)=='table' then
				print( 'decode ok' )
				for i,v in pairs(t) do
					print( v.topics )
				end
				self._data = t
			end
		end
		kits.log('载入模拟数据..')
	end
end

function Subjective:init_gui()
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
		self._teacher_view = uikits.child(self._contentview,ui.TEACHER_VIEW)
		self._teacher_view:setEnabled(false) --有点印象翻页,关闭它
		
		self._record_but = uikits.child(self._contentview,ui.RECORD_BUTTON)
		self._cam_but = uikits.child(self._contentview,ui.CAM_BUTTON)
		self._photo_but = uikits.child(self._contentview,ui.PHOT_BUTTON)
		uikits.event( self._record_but,
			function(sender)
				print('record audio')
			end)
		uikits.event( self._cam_but,
			function(sender)
				print('open camer')
			end)
		uikits.event( self._photo_but,
			function(sender)
				print('open photo directory' )
			end)
			
		local x_,y_ = self._contentview:getPosition()
		local anp = self._contentview:getAnchorPoint()
		self._pageview = uikits.pageview{
			bgcolor=self._root:getBackGroundColor(),
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
		---装入数据
		if self._data then
			for i,v in pairs(self._data) do
				self:add_item( v )
			end
			self:set_current(1)
			self:relayout()
		end
	end
end

function Subjective:release()
	
end

return Subjective