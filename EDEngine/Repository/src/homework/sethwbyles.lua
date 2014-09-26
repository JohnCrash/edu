local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"
local Workpreview = require "homework/workpreview"

local is_need_update
local is_loading
local collect_space = 20

local ui = {
	FILE = 'homework/laoshizuoye/tongbust.json',
	FILE_3_4 = 'homework/laoshizuoye/tongbust43.json',
	BUTTON_BACK = 'ding/back',
	BUTTON_PREVIEW = 'ding/yl',
	BUTTON_CONFIRM = 'ding/qr',
	LABEL_NUM = 'ding/sl',
	QUESTION_VIEW = 'ti1',
	PER_QUESTION_VIEW = 'ti1/ti1',
	ITEM_TYPE = 'ys/lx',
	ITEM_DIFF = 'ys/nd',
	ITEM_PER_WRONG = 'ys/cwl',
	ITEM_CHECKBOX_CONFIRM = 'ys/xz',
	ITEM_QUESTION_VIEW = 'tu',
--	ITEM_NO_FOUND = 'nofound',
}

local Sethwbyles = class("Sethwbyles")
Sethwbyles.__index = Sethwbyles

function Sethwbyles.create(tb_parent_view)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Sethwbyles)
	layer.collect_items = {}
	layer.pageindex = 1
	layer.loaded_item_num = 0
	layer.itemcount = 0
	layer.confirm_count = 0
	layer.parentview = tb_parent_view
	layer.selector = tb_parent_view._selector
	kits.log(tostring(tb_parent_view._selector))
	is_loading = false
	is_need_update = true
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

function Sethwbyles:SetButtonEnabled()
	local but_preview = uikits.child(self._widget,ui.BUTTON_PREVIEW)
	local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
	if self.confirm_count  ~= 0 then
		but_preview:setEnabled(true)
		but_preview:setBright(true)
		but_preview:setTouchEnabled(true)
		but_confirm:setEnabled(true)
		but_confirm:setBright(true)
		but_confirm:setTouchEnabled(true)
	else
		but_preview:setEnabled(false)
		but_preview:setBright(false)
		but_preview:setTouchEnabled(false)	
		but_confirm:setEnabled(false)
		but_confirm:setBright(false)
		but_confirm:setTouchEnabled(false)	
	end
end

function Sethwbyles:getdatabyurl()
	local base_url =  'http://new.www.lejiaolexue.com/paper/handler/GetOfficialItem.ashx?paperId=0'
	local send_course_data = '&course='..self.selector[1].id
	local send_bv_data = ''
	local send_vol_data = ''
	local send_unit_data = ''
	local send_section_data = ''
	if self.selector[2] then
		send_bv_data = '&bv='..self.selector[2].id
	end
	if self.selector[3] then
		send_vol_data = '&vol='..self.selector[3].id
	end
	if self.selector[4] then
		send_unit_data = '&unit='..self.selector[4].id
	end
	if self.selector[5] then
		send_section_data = '&section='..self.selector[5].id
	end	
	local send_page_data = '&p='..self.pageindex
	
	local send_url = base_url..send_course_data..send_bv_data..send_vol_data..send_unit_data..send_section_data..send_page_data
	
	print('send_url::'..send_url)
--[[	local base_url = 'http://new.www.lejiaolexue.com/paper/handler/GetOfficialItem.ashx?course=10001&bv=0&vol=0&unit=0&section=0&type=0&diff=0&paperId=6d34229c768a4c7b87511b29a6b8c77f'
	local send_page_data = '&p='..self.pageindex 
	local send_url = base_url..send_page_data--]]
	
	local loadbox = loadingbox.open(self)
	is_loading = true
	cache.request_json( send_url,function(t)
			if t and type(t)=='table' then
				if t.t == 0 then
					loadbox:removeFromParent()
					return
				end
				for i,obj in pairs(t.item) do
					local is_exist = false
					for j,v in pairs(self.parentview._confirm_item) do 
						if v.item_id_num == obj.item_id_num then
							is_exist = true
						end
					end
					if is_exist == false then
						self.collect_items[#self.collect_items+1] = t.item[i]
					end
				end		
				self.loaded_item_num = self.loaded_item_num + #t.item
				self.itemcount = t.t
				print("self.itemcount::"..self.itemcount)
				self:updatepage()
			else
				messagebox.open(self,function(e)
					if e == messagebox.TRY then
						self:init()
					elseif e == messagebox.CLOSE then
						uikits.popScene()
					end
				end,messagebox.RETRY)	
			end
			is_loading = false
			loadbox:removeFromParent()
		end,'N')
end


function Sethwbyles:addcollectitem(index,collectitem,page,src_collect_view)

	local row_num 
	local pos_x
	local pos_y		
	
	print("collectitem.item_id_num::"..collectitem.item_id_num)
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
	
	uikits.event(but_confirm,
		function(sender,eventType)
			local label_num = uikits.child(self._widget,ui.LABEL_NUM)
			if eventType == true then
				self.confirm_count = self.confirm_count+1
				self.parentview.temp_items[collectitem.item_id_num] = collectitem
			else
				self.confirm_count = self.confirm_count-1
				self.parentview.temp_items[collectitem.item_id_num] = {}
			end
			self:SetButtonEnabled()
			label_num:setString(self.confirm_count)
	end)	
	
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
					
	page:addChild(collect_view,1,1000+index)		
end

function Sethwbyles:updatepage()
	local page_data = uikits.child(self._widget,ui.QUESTION_VIEW)				
	local per_collectview = uikits.child(self._widget,ui.PER_QUESTION_VIEW)
		
	if self.pageindex == 1 then
		local collect_title_num = table.getn(self.collect_items)
		--print(collect_title_num)
		local row_num

		row_num = collect_title_num

		local size  = per_collectview:getContentSize()	
		local size_win = self._widget:getContentSize()
		page_data:setInnerContainerSize(cc.size(size_win.width,(size.height+collect_space)*row_num))

		for i,obj in pairs(self.collect_items) do
			self:addcollectitem(i,self.collect_items[i],page_data,per_collectview)
		end				
	else
		local collect_title_num = table.getn(self.collect_items)
		local row_num
		row_num = collect_title_num	
		
		local size  = per_collectview:getContentSize()	
		
		local size_old = page_data:getInnerContainerSize()
		local count_old = page_data:getChildrenCount()-1
		page_data:setInnerContainerSize(cc.size(size_old.width,size_old.height+(size.height+collect_space)*row_num))
		
		local collectview = page_data:getChildren()
		for i,obj in pairs(collectview) do
			local per_size_old_x = collectview[i]:getPositionX()
			local per_size_old_y = collectview[i]:getPositionY()+(size.height+collect_space)*row_num
			collectview[i]:setPosition(cc.p(per_size_old_x,per_size_old_y))
		end
		
		for i,obj in pairs(self.collect_items) do
			self:addcollectitem(i+count_old,self.collect_items[i],page_data,per_collectview)
		end					
	end
end

function Sethwbyles:init()
	if is_need_update == false then
		is_need_update = true
		return
	end
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		topics.set_scale(1.2)
		uikits.initDR{width=1920,height=1080}
	else
		topics.set_scale(1)
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
	--local label_item_nofound = uikits.child(self._widget,ui.ITEM_NO_FOUND)
	local but_back = uikits.child(self._widget,ui.BUTTON_BACK)
	local but_preview = uikits.child(self._widget,ui.BUTTON_PREVIEW)
	local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
	local label_num = uikits.child(self._widget,ui.LABEL_NUM)
	
	--label_item_nofound:setVisible(false)
	label_num:setString(self.confirm_count)
	uikits.event(but_back,
		function(sender,eventType)
		self.parentview.temp_items = {}
		uikits.popScene()
	end,"click")
	uikits.event(but_preview,
		function(sender,eventType)
		is_need_update = false
		uikits.pushScene(Workpreview.create(self.parentview))
	end,"click")
	uikits.event(but_confirm,
		function(sender,eventType)
		uikits.popScene()
	end,"click")
	self:SetButtonEnabled()
	local page_data = uikits.child(self._widget,ui.QUESTION_VIEW)
	local per_item_view = uikits.child(self._widget,ui.PER_QUESTION_VIEW)
	page_data:setBounceEnabled(false)
	per_item_view:setVisible(false)
	uikits.event(page_data,
		function(sender,eventType)
			if eventType == ccui.ScrollviewEventType.scrollToBottom then
				if is_loading == false then
					self:updatecollectview()				
				end
			end
		end)	
	self:getdatabyurl()
end

function Sethwbyles:updatecollectview()
	
	if self.loaded_item_num == self.itemcount then
		return
	end
	self.pageindex = self.pageindex+1
	
	local ret = self:getdatabyurl()
	if ret == false then
		print("Sethwbyles get error!")
		return
	end
end	

function Sethwbyles:release()
	self.pageindex =1
	local default_scale = topics.get_default_scale()
	topics.set_scale(default_scale)
end

return Sethwbyles