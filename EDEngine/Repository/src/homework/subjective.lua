local kits = require "kits"
local uikits = require "uikits"
local json = require "json-c"
local loadingbox = require "loadingbox"
local cache = require "cache"

local ui = {
	FILE = 'homework/subjective.json',
	FILE_3_4 = 'homework/subjective43.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	ITEM_CURRENT = 'state_now',
	ITEM_FINISHED = 'state_past',
	ITEM_UNFINISHED = 'state_future',
	NEXT_BUTTON = 'next_problem', 
	FINISH_BUTTON = 'finish_5',
	TEACHER_VIEW = 'teacher_view',
	TOPICS = 'teacher_view/homework_text',
	RECORD_BUTTON = 'write_view/white_3/recording',
	CAM_BUTTON = 'write_view/white_3/photograph',
	PHOTO_BUTTON = 'write_view/white_3/photo',
	
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

function Subjective.create( args )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Subjective)
	
	scene:addChild(layer)
	layer._args = args
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
	local item
	if state == ui.STATE_CURRENT then
		item = self._item_current:clone()
		item._isclone = true
		return item
	elseif state == ui.STATE_FINISHED then
		item = self._item_finished:clone()
		item._isclone = true
		return item
	elseif state == ui.STATE_UNFINISHED then
		item = self._item_unfinished:clone()
		item._isclone = true
		return item
	else
		kits.log( '	ERROR: clone_item state = '..tostring(state) )
		return self._item_unfinished:clone()
	end
end

function Subjective:init_delay_release()
	local scheduler = self:getScheduler()
	local function timer_func()
		if self._remove_items and #self._remove_items>0 then
			for i,v in pairs(self._remove_items) do
				v:removeFromParent()
			end
			self._remove_items = nil
		end
	end
	self._scID = scheduler:scheduleScriptFunc( timer_func,1,false )
end

function Subjective:set_item_state( i,ste )
	if self._list[i] then
		local item = self._list[i]
		local num = uikits.child(item,ui.ITEM_NUM)
		local s = num:getString()
		local x,y = item:getPosition()
		--3.2不能再其方法内部释放对象
		--item:removeFromParent()
		--延迟释放
		item:setVisible(false)
		self._remove_items = self._remove_items or {}
		table.insert(self._remove_items,item)
		
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
		local layout = self._scroll:clone()

		layout:setVisible(true)
		local topics = uikits.child(layout,ui.TOPICS)
		topics:setString( t.content )
		
		local audio_view = uikits.child(layout,ui.AUDIO_VIEW)
		audio_view:setVisible(false)
		
		local picture_view = uikits.child(layout,ui.PICTURE_VIEW)
		picture_view:setVisible(false)
		--add loading circle
		--load attachments
		local rtable = {}
		rtable.urls = {}
		if t.attachment then
			local atts = json.decode(t.attachment)
			if atts and atts.attachments then
				for i,v in pairs(atts.attachments) do
					if v.value then
						table.insert(rtable.urls,{url=v.value,filename=v.name})
					end
				end
			end
		end
		local n = 0
		self._pageview:addPage( layout )
		rtable.loading = loadingbox.circle(layout)
		cache.request_resources( rtable,
			function(rs,i,b)
				n = n + 1
				if b and rs.urls[i] then
					kits.log('download -> '..rs.urls[i].url )
					kits.log('cahce ->' ..rs.urls[i].filename)
					kits.log('file is '..tostring(kits.exist_cache(rs.urls[i].filename )))
				end
				if n >= #rs.urls then --complete
					if rs.loading and cc_isobj(rs.loading) then
						rs.loading:removeFromParent() 
					else
						return
					end
					--done
					kits.log('DONE')
				end
			end)
	else
		kits.log( '	ERROR: clone_item() return nil' )
	end
end

function Subjective:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width*(#self._list+1),self._item_size.height))
		for i,v in ipairs(self._list) do
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
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
	self:init_gui()
	self:init_delay_release()
	self:init_data()
end

local loadpaper_url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx"
local loadextam_url = "http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx"

function Subjective:init_data()
	if self._args then
		local url_topics
		if self._args.exam_id then
			--取作业
			url_topics = loadextam_url..'?examId='..self._args.exam_id..'&teacherId='..self._args.tid
			--取得以前做的答案
			--self._topics_table = topics.read( self._args.exam_id ) or {}
		elseif self._args.pid then
			--取卷面
			url_topics = loadpaper_url..'?pid='..self._args.pid..'&uid='..self._args.uid
			--取得以前做的答案
			--self._topics_table = topics.read( self._args.pid ) or {}
		else
			--self._topics_table = {}
			kits.log('error : Subjective:init_data exam_id=nil and pid=nil')
			return
		end
		kits.log('Subjective:init_data request :'..url_topics )
		local loadbox = loadingbox.open(self)
		cache.request_json( url_topics,function(t)
				loadbox:removeFromParent()
				if t then
					self:load_subjective_from_table(t)
				else
					kits.log('ERROR Subjective:init_data request failed')
				end			
		end)
	else
		local res = kits.read_cache('sujective.json')
		if res then
			local t = json.decode(res)
			if t and type(t)=='table' then
				for i,v in pairs(t) do
					print( v.topics )
				end
				self._data = t
			end
		end
		kits.log('载入模拟数据..')
	end
end

function Subjective:load_subjective_from_table(data)
	if data then
		local ds
		if data.item and type(data.item)=='table' then
			ds = data.item
		else
			ds = data
		end
		self._data = ds --保存副本
		for i,v in ipairs(ds) do
			if v.item_type==93 then --自定义题
				self:add_item( v )
			end
		end	
		self:set_current(1)
		self:relayout()
	end
end

function Subjective:scroll_relayout()
	--计算高度
	local uis = {}
	local ts = self._tops:getContentSize()
	local cs = self._scroll:getContentSize()
	local ds = {height=0,width=0}--self._delete_button:getContentSize()
	local x,y = 0,0 --self._delete_button:getPosition()
	y = self._space
	--self._delete_button:setPosition(cc.p(x,y))
	y = y + ds.height + self._space
	for i,v in pairs(self._items) do
		if v:isVisible() then
			local xx,yy = v:getPosition()
			v:setPosition( cc.p(xx,y) )
			y = y + v:getContentSize().height*v:getScaleY() + self._space
			table.insert(uis,v)
		end
	end
	local xx,yy = self._tops:getPosition()
	self._tops:setPosition(cc.p(xx,y))
	y = y + ts.height + self._space
	self._scroll:setInnerContainerSize(cc.size(cs.width,y))
	table.insert(uis,self._tops)
	--table.insert(uis,self._delete_button)
	if y < cs.height then
		uikits.move( uis,0,cs.height-y)
	end
end

function Subjective:init_gui()
	if not self._root then
		self._list = {}
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
		self:addChild(self._root)
		
		self._scrollview = uikits.child(self._root,ui.LIST)
		self._scroll = uikits.child(self._root,ui.PAGE_VIEW)
		self._scroll_size = self._scroll:getContentSize()
		
		self._tops = uikits.child(self._scroll,ui.TEACHER_VIEW)
		local cs = self._scroll:getContentSize()
		local ts = self._tops:getContentSize()
		local tx,ty = self._tops:getPosition()
		self._space = cs.height-ty-ts.height
		self._input_text = uikits.child(self._tops,ui.INPUT_TEXT)
		local x,y = self._tops:getPosition()
		self._tops_space = y-self._tops:getContentSize().height
		self._tops_ox = x
	
		self._record_button = uikits.child(self._tops,ui.RECORD_BUTTON)
		self._cam_button = uikits.child(self._tops,ui.CAM_BUTTON)
		self._photo_button = uikits.child(self._tops,ui.PHOTO_BUTTON)

		self._audio_item = uikits.child(self._scroll,ui.AUDIO_VIEW)
		self._img_item = uikits.child(self._scroll,ui.PICTURE_VIEW)
		self._audio_item:setVisible(false)
		self._img_item:setVisible(false)
		self._scroll_list = {}
		self._items = {}
		self._remove_items = {}
		
		local x_,y_ = self._scroll:getPosition()
		local anp = self._scroll:getAnchorPoint()
		self._pageview = uikits.pageview{
			bgcolor=self._root:getBackGroundColor(),
			x = x_,
			y = y_,
			anchorX = anp.x,
			anchorY = anp.y,
			width=self._scroll_size.width,
			height=self._scroll_size.height}	
		self._scroll:setVisible(false)
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
		self._item_size = self._item_current:getContentSize()

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
	if self._scID then
		self:getScheduler():unscheduleScriptEntry(self._scID)
		self._scID = nil
	end
end

return Subjective