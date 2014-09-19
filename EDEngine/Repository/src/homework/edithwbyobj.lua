local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"

local topics_course = topics.course_icon

--crash.open("teacher",1)
local collect_space = 20
local ui = {
	FILE = 'homework/laoshizuoye/kgbianji.json',
	FILE_3_4 = 'homework/laoshizuoye/kgbianji43.json',
	BUTTON_BACK = 'ding/back',
	BUTTON_CONFIRM = 'ding/qr',
	LABEL_NUM = 'ding/sl',
	QUESTION_VIEW = 'ti1',
	PER_QUESTION_VIEW = 'ti1/ti1',
	ITEM_TYPE = 'ys/lx',
	ITEM_DIFF = 'ys/nd',
	ITEM_PER_WRONG = 'ys/cwl',
	ITEM_CHECKBOX_CONFIRM = 'ys/shancu',
	ITEM_QUESTION_VIEW = 'tu',
	ITEM_NO_FOUND = 'nofound',
--[[	
	BUTTON_PREVIEW = 'ding/yl',--]]
	}

local Edithwbyobj = class("Edithwbyobj")
Edithwbyobj.__index = Edithwbyobj

function Edithwbyobj.create(tb_parent_view)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Edithwbyobj)
	layer.collect_items = tb_parent_view._confirm_item
	layer.confirm_count = 0
	for i,obj in pairs(layer.collect_items) do
		layer.confirm_count = layer.confirm_count +1
	end
	--layer.confirm_count = #layer.collect_items
	layer.parentview = tb_parent_view
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

function Edithwbyobj:addcollectitem(index,collectitem,page,src_collect_view)

	local row_num 
	local pos_x
	local pos_y		

	local collect_view = src_collect_view:clone()
	local size  = collect_view:getContentSize()

	row_num = index
	pos_x = src_collect_view:getPositionX()	

	collect_view:setVisible(true)						
	pos_y = page:getInnerContainerSize().height-(size.height+ collect_space)*row_num	
	collect_view:setPosition(cc.p(pos_x,pos_y))	
	local label_item_name = uikits.child(collect_view,ui.ITEM_TYPE)
	local wrong_per = uikits.child(collect_view,ui.ITEM_PER_WRONG)
	local label_difficulty = uikits.child(collect_view,ui.ITEM_DIFF)
	local but_confirm = uikits.child(collect_view,ui.ITEM_CHECKBOX_CONFIRM)
	local questions_view = uikits.child(collect_view,ui.ITEM_QUESTION_VIEW)
	
--[[	uikits.event(but_confirm,
		function(sender,eventType)
			local label_num = uikits.child(self._widget,ui.LABEL_NUM)
			if eventType == false then
				self.confirm_count = self.confirm_count-1
				self.parentview.temp_items[collectitem.item_id_num] = collectitem
			else
				self.confirm_count = self.confirm_count+1
				self.parentview.temp_items[collectitem.item_id_num] = {}
			end
			label_num:setString(self.confirm_count)
	end)	--]]
	
	uikits.event(but_confirm,
		function(sender,eventType)
			print("collectitem.item_id_num::"..collectitem.item_id_num)
			self.confirm_count = self.confirm_count-1
			self.parentview.temp_items[collectitem.item_id_num] = collectitem
			local label_num = uikits.child(self._widget,ui.LABEL_NUM)
			label_num:setString(self.confirm_count)
			self:removeitem()
	end,"click")	
	
	local size_questions_view = questions_view:getContentSize()

	label_item_name:setString(collectitem.item_name)
	label_difficulty:setString(collectitem.difficulty)				
	--wrong_per:setString(collectitem.perwrong.."%")	
	
	local scrollView = ccui.ScrollView:create()
    scrollView:setTouchEnabled(true)
    scrollView:setContentSize(size_questions_view)        
    scrollView:setPosition(cc.p(0,0))
	
    questions_view:addChild(scrollView)
	local data = {}

	if collectitem.item_type > 0 and collectitem.item_type < 13 then
--		print(topics.types[item_data.item_type])
		if topics.types[collectitem.item_type].conv(collectitem,data) then
			data.eventInitComplate = function(layout,data)
				local arraychildren = scrollView:getChildren()
				for i=1,#arraychildren do 
					arraychildren[i]:setEnabled(false)
				end
			end
			questions_view:setEnabled(false)
			topics.types[collectitem.item_type].init(scrollView,data)
		end		
	end	
	scrollView:addTouchEventListener(				
					function(sender,eventType)
						if eventType == ccui.TouchEventType.began then
							page:setEnabled(false)
						elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
							page:setEnabled(true)	
						end
					end)
					
	page:addChild(collect_view,1,1000+collectitem.item_id_num)		
end

function Edithwbyobj:removeitem()
	local page_data = uikits.child(self._widget,ui.QUESTION_VIEW)				
	local per_collectview = uikits.child(self._widget,ui.PER_QUESTION_VIEW)
	
	local collectview = page_data:getChildren()
	for i,obj in pairs(collectview) do
		for j,v in pairs(self.parentview.temp_items) do
			if v.item_id_num+1000 == obj:getTag() then
				obj:setVisible(false)
			end
		end
	end
	local row_num = self.confirm_count
	local size  = per_collectview:getContentSize()	
	local size_win = self._widget:getContentSize()
	page_data:setInnerContainerSize(cc.size(size_win.width,(size.height+collect_space)*row_num))
	local index = 0
	for i,obj in pairs(collectview) do
		local is_show = obj:isVisible()
		if is_show == true then
			index = index+1
			pos_y = page_data:getInnerContainerSize().height-(size.height+ collect_space)*index	
			obj:setPositionY(pos_y)	
		end		
	end				
end

function Edithwbyobj:updatepage()
	local page_data = uikits.child(self._widget,ui.QUESTION_VIEW)				
	local per_collectview = uikits.child(self._widget,ui.PER_QUESTION_VIEW)
	
--[[	print(#self.parentview.temp_items)
	--计算行数，设置滚动层长度
	if #self.parentview.temp_items ~= 0 then
		for i,obj in pairs(self.collect_items) do
			page_data:removeChildByTag(1000+obj.item_id_num)
		end
	end--]]
	local row_num = self.confirm_count
	
	local size  = per_collectview:getContentSize()	
	local size_win = self._widget:getContentSize()
	page_data:setInnerContainerSize(cc.size(size_win.width,(size.height+collect_space)*row_num))
	local index = 0
	for i,obj in pairs(self.collect_items) do
		index = index+1
		self:addcollectitem(index,obj,page_data,per_collectview)			
	end			
end

function Edithwbyobj:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		topics.set_scale(1.2)
		uikits.initDR{width=1920,height=1080}
	else
		topics.set_scale(1)
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)

	local but_back = uikits.child(self._widget,ui.BUTTON_BACK)
	local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
	local label_num = uikits.child(self._widget,ui.LABEL_NUM)
	
	label_num:setString(self.confirm_count)
	uikits.event(but_back,
		function(sender,eventType)
		self.parentview.temp_items = {}
		uikits.popScene()
	end,"click")

	uikits.event(but_confirm,
		function(sender,eventType)
		uikits.popScene()
	end,"click")
	
	local page_data = uikits.child(self._widget,ui.QUESTION_VIEW)
	local per_item_view = uikits.child(self._widget,ui.PER_QUESTION_VIEW)
	page_data:setBounceEnabled(false)
	per_item_view:setVisible(false)
	local but_confirm = uikits.child(per_item_view,ui.ITEM_CHECKBOX_CONFIRM)
	--but_confirm:setSelectedState(true)
	self:updatepage()
--	self:getdatabyurl()
end

function Edithwbyobj:release()
	self.pageindex =1
	local default_scale = topics.get_default_scale()
	topics.set_scale(default_scale)
end

return Edithwbyobj