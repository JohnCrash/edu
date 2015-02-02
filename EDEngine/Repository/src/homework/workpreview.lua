local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"
local mt = require "mt"
local json = require "json-c"

local res_root = 'homework/'
local ui = {
	FILE = res_root..'styulan.json',
	FILE_3_4 = res_root..'styulan43.json',
	BACK = 'ding/back',
	LIST = 'ding/state_view',
	ARROW = 'arrow',
	ARROW_UP = 'up',
	PAGE_VIEW = 'questions_view',
	NEXT_BUTTON = 'next_problem',
	ITEM_CURRENT = 'state_now',
	ITEM_UNFINISHED = 'state_future',
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_UNFINISHED = 2,
}

local Workpreview = class("Workpreview")
Workpreview.__index = Workpreview

function Workpreview.create( tb_parent_view )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Workpreview)
	layer.tb_parent_view = tb_parent_view
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


function Workpreview:init_ui_from_data()
	local x
	x,self._item_y = self._item_current:getPosition()
	if self._data then
		kits.log('	load_original_data_from_string success')
		for i,v in pairs(self._data) do
			self:add_item( v )
		end
		self:relayout()
		self:set_current(1)
	end
end

function Workpreview:init_data( )
	self._data = self:load_original_data_from_table(self.tb_parent_view.temp_items)
	self:init_ui_from_data()
end

function Workpreview:load_original_data_from_table( data )
	local res = {}
	if data then
		local ds = data

		kits.log('	type(ds)='..type(ds)..',#ds='..table.maxn(ds))
		for i,v in pairs(ds) do
			kits.log('	key='..tostring(i))
			kits.log('	value='..tostring(v))
		end
		for i,v in pairs(ds) do
			if v.item_type ~= nil then
				local __data = {}
				local scrollView = ccui.ScrollView:create()
				scrollView:setTouchEnabled(true)
				scrollView:setContentSize(self._pageview_size)        
				scrollView:setPosition(cc.p(0,0))
				kits.log('v.item_type;;'..v.item_type)

				if v.item_type > 0 and v.item_type < 13 then
			--		print(topics.types[item_data.item_type])
					if topics.types[v.item_type].conv(v,__data) then
						__data.eventInitComplate = function(layout,__data)
							local arraychildren = scrollView:getChildren()
							for i=1,#arraychildren do 
								arraychildren[i]:setEnabled(false)
							end
						end
						topics.types[v.item_type].init(scrollView,__data)
					end		
				end	
				scrollView.state = ui.STATE_UNFINISHED
				res[#res+1] = scrollView			
			end
		end
		--[[
		if b then
			self._next_button:setVisible(false)
			self._finish_button:setVisible(true)
		end
		]]--
	else
		kits.log('	load_original_data_from_table decode_json faild')
	end
	return res
end

function Workpreview:optimization_scrollview()
	local function optimization_scroll()
		if self._scrollview then
			local childs = self._scrollview:getChildren()
			local inner = self._scrollview:getInnerContainer()
			local inner_x,inner_y = inner:getPosition()
			local size = self._scrollview:getContentSize()
			for i,v in pairs(childs) do
				if v ~= self._item_current and v ~= self._item_unfinished then
					local x,y = v:getPosition()
					if x+inner_x < 0 or x+inner_x > size.width then
						v:setVisible(false)
					else
						v:setVisible(true)
					end
				end
			end
		end
	end
	optimization_scroll()
	uikits.event( self._scrollview,function(sender,eventType)
			optimization_scroll()
		end)
end

function Workpreview:optimization_pageview()
	local function optimization_page(idx)
		local idx = self._pageview:getCurPageIndex()
		local pages = self._pageview:getPages()
		for i,v in pairs(pages) do
			if i-1<=idx+1 and i-1>= idx-1 then
				v:setVisible(true)
			else
				v:setVisible(false)
			end
		end
	end
	optimization_page()
	uikits.event( self._pageview,function(sender,eventType)
			if eventType == ccui.PageViewEventType.turning then
				local i = sender:getCurPageIndex()
				optimization_page()
				self:set_current( i+1 )
			end					
		end)
end

function Workpreview:init_gui()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		Workpreview.scale = uikits.initDR{width=1920,height=1080}
	else
		Workpreview.scale = uikits.initDR{width=1440,height=1080}
	end
	
	Workpreview.space = 16*Workpreview.scale
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	uikits.event(uikits.child(self._root,ui.BACK),function(sender)
		uikits.popScene()
		end,'click')
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._pageview = uikits.child(self._root,ui.PAGE_VIEW)
	self._pageview_size = self._pageview:getContentSize()
	
	self._arrow = uikits.child(self._root,ui.ARROW)
	self._arrow_up = uikits.child(self._root,ui.ARROW_UP)
	
	uikits.event(self._pageview,
			function(sender,eventType)
				if eventType == ccui.PageViewEventType.turning then
					local i = sender:getCurPageIndex()
					self:set_current( i+1 )
				end				
			end)
	self._item_current = uikits.child(self._scrollview,ui.ITEM_CURRENT)
	self._item_unfinished = uikits.child(self._scrollview,ui.ITEM_UNFINISHED)
	
	self._item_current:setVisible(false)
	self._item_unfinished:setVisible(false)

	self._item_size = self._item_current:getContentSize()
	
	
--[[	local x
	x,self._item_y = self._item_current:getPosition()
	if self._data then
		for i,v in pairs(self._data) do
			self:add_item( v )
		end
		self:set_current(1)
		self:relayout()
	end--]]
	self._pageview:setTouchEnabled(false)
end

function Workpreview:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width*(#self._list+1),self._item_size.height))
		for i,v in ipairs(self._list) do
			print("iiii;;;"..i)
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
		end
	end
end

function Workpreview:set_item_state( i,ste )
	print("set_item_state::")
	if self._list[i] then
		local item = self._list[i]
		local num = uikits.child(item,ui.ITEM_NUM)
		local s = num:getString()
		local x,y = item:getPosition()

		item:setVisible(false)
		
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

function Workpreview:clone_item( state )
	print('	zy: clone_item state = '..tostring(state))
	if state == ui.STATE_CURRENT then
		return self._item_current:clone()
	elseif state == ui.STATE_UNFINISHED then
		return self._item_unfinished:clone()
	else
		kits.log( '	ERROR: clone_item state = '..tostring(state) )
		return self._item_unfinished:clone()
	end
end

function Workpreview:next_item()
	if self._current and self._current < #self._list then
		self:set_current( self._current+1 )
	end
end

function Workpreview:set_current( i )
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

function Workpreview:add_item( t )
	print("add_item::")
	t.state = t.state or ui.STATE_UNFINISHED
	local item = self:clone_item( t.state )
	if item then
		local n = uikits.child(item,ui.ITEM_NUM)
		n:setString( tostring(#self._list + 1) )
		self._list[#self._list+1] = item
		item:setVisible(true)
		self._scrollview:addChild(item)
		local index = #self._list
		uikits.event(item,function(sender) self:set_current( index ) end,'began')
		self._pageview:addPage( t )
	else
		kits.log( '	ERROR: clone_item() return nil' )
	end
end

function Workpreview:init()

	self._list = {}
	self:init_gui()
	self:init_data()
		self:optimization_scrollview()
		self:optimization_pageview()

end

function Workpreview:release()

end

return Workpreview