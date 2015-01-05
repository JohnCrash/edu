local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Mallview = class("Mallview")
Mallview.__index = Mallview
local ui = {
	Mallview_FILE = 'poetrymatch/shangcheng.json',
	Mallview_FILE_3_4 = 'poetrymatch/shangcheng.json',
	VIEW_ALL_CARD = 'gun',
	BUTTON_CU = 'tong',
	BUTTON_GOLD = 'jin',
	BUTTON_SILVER = 'yin',
	TXT_WEN = 'wen',
	VIEW_CARD_SRC = 'sp1',
	BUTTON_BUY = 'mail',
	TXT_CARD_NAME = 'mz',
	TXT_CARD_PRICE = 'qian',
	TXT_CARD_LVL = 'kp/dj',
	PIC_CARD = 'kp',
	
	VIEW_CARD_INFO = 'xiangq',
	PIC_CARD_INFO = 'kp',
	TXT_CARD_INFO_LVL = 'kp/dj',
	TXT_CARD_INFO_NAME = 'mz',	
	TXT_CARD_INFO_DES = 'jianjie/wen',	
	PIC_CARD_INFO_CU = 'tong',
	PIC_CARD_INFO_SILVER = 'yin',
	PIC_CARD_INFO_GOLD = 'jing',
	BUTTON_CARD_INFO_BUY = 'mail',
	TXT_CARD_INFO_AP = 'gongj',	
	TXT_CARD_INFO_MP = 'zhili',
	TXT_CARD_INFO_HP = 'shengm',
	TXT_CARD_INFO_SP = 'shenl',
	TXT_CARD_INFO_PP = 'shij',
	TXT_CARD_INFO_PAY = 'qian',
	
	BUTTON_SILVER_ADD = 'xinxi/yibi/jia',
	TXT_SILVER_NUM = 'xinxi/yibi/zhi',	
	BUTTON_LE = 'xinxi/lebi/jia',
	TXT_LE_NUM = 'xinxi/lebi/zhi',		
	BUTTON_QUIT = 'xinxi/fanhui',
}

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerEntry

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Mallview)		
	cur_layer.sel_pinzhi = 0
	scene:addChild(cur_layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			cur_layer:init()
		elseif "exit" == event then			
			cur_layer:release()
		end
	end	
	cur_layer:registerScriptHandler(onNodeEvent)
	return scene	
end


function Mallview:show_silver()
	local silver_num = person_info.get_user_silver()
	local txt_silver = uikits.child(self._Mallview,ui.TXT_SILVER_NUM)
	txt_silver:setString(silver_num)
	
	local but_silver = uikits.child(self._Mallview,ui.BUTTON_SILVER_ADD)
--	but_silver:setVisible(false)
	uikits.event(but_silver,	
		function(sender,eventType)	
			self._Mallview:setEnabled(false)
			self._Mallview:setTouchEnabled(false)
			local le_num = person_info.get_user_le_coin()
			if le_num < 10 then
				person_info.messagebox(self,person_info.NO_LE,function(e)
					if e == person_info.OK then
						print('aaaaaaaaaaaa')
					else
						print('bbbbbbbbbbbb')
					end
					self._Mallview:setEnabled(true)
					self._Mallview:setTouchEnabled(true)	
				end)
			else
				le_num = le_num -10 
				silver_num = silver_num + 1000
				local txt_le = uikits.child(self._Mallview,ui.TXT_LE_NUM)
				txt_le:setString(le_num)
				txt_silver:setString(silver_num)
				person_info.set_user_silver(silver_num)
				person_info.set_user_le_coin(le_num)
			end
	
		end,"click")
end

function Mallview:show_le_coin()
	local le_num = person_info.get_user_le_coin()
	local txt_le = uikits.child(self._Mallview,ui.TXT_LE_NUM)
	txt_le:setString(le_num)
	
	local but_le = uikits.child(self._Mallview,ui.BUTTON_LE)
	but_le:setVisible(false)
	uikits.event(but_le,	
		function(sender,eventType)	
			
		end,"click")
end

function Mallview:show_card_info(id)
	local cur_card_info = self.card_info[id]
	self:resetgui()
	self.temp_view = self.card_info_view:clone()
	self.temp_view:setVisible(true)
	self._Mallview:addChild(self.temp_view,0,10000)
	local id
	local func
	local function timer_update(time)
		func(self,id)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	
	local pic_card = uikits.child(self.temp_view,ui.PIC_CARD_INFO)
	local txt_card_lvl = uikits.child(self.temp_view,ui.TXT_CARD_INFO_LVL)
	local txt_card_name = uikits.child(self.temp_view,ui.TXT_CARD_INFO_NAME)
	local txt_card_des = uikits.child(self.temp_view,ui.TXT_CARD_INFO_DES)	
	local pic_card_cu = uikits.child(self.temp_view,ui.PIC_CARD_INFO_CU)	
	local pic_card_silver = uikits.child(self.temp_view,ui.PIC_CARD_INFO_SILVER)	
	local pic_card_gold = uikits.child(self.temp_view,ui.PIC_CARD_INFO_GOLD)	
	local txt_card_ap = uikits.child(self.temp_view,ui.TXT_CARD_INFO_AP)
	local txt_card_mp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_MP)
	local txt_card_hp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_HP)	
	local txt_card_sp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_SP)
	local txt_card_pp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_PP)
	local txt_card_pay = uikits.child(self.temp_view,ui.TXT_CARD_INFO_PAY)	
	local but_card_buy = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_BUY)	
	local n_pic_name = cur_card_info.card_plate_id..'a.png'
	person_info.load_card_pic(pic_card,n_pic_name)
	txt_card_lvl:setString(cur_card_info.card_plate_level)
	txt_card_name:setString(cur_card_info.pro_name)
	txt_card_des:setString(cur_card_info.description)
	txt_card_ap:setString(cur_card_info.card_plate_attack)
	txt_card_sp:setString(cur_card_info.card_plate_magic)
	txt_card_hp:setString(cur_card_info.card_plate_blood)
	txt_card_mp:setString(cur_card_info.card_plate_wit)
	txt_card_pp:setString(cur_card_info.card_plate_pomes)
	txt_card_pay:setString(cur_card_info.price)
	
	pic_card_gold:setVisible(false)
	pic_card_silver:setVisible(false)
	pic_card_cu:setVisible(false)
	if cur_card_info.card_material == 3 then
		pic_card_gold:setVisible(true)
	elseif cur_card_info.card_material == 2 then
		pic_card_silver:setVisible(true)
	elseif cur_card_info.card_material == 1 then
		pic_card_cu:setVisible(true)
	end		
	but_card_buy.cur_info = cur_card_info
	uikits.event(but_card_buy,	
		function(sender,eventType)	
			local silver_num = person_info.get_user_silver()
			if silver_num < sender.cur_info.price then
				person_info.messagebox(self,person_info.NO_SILVER,function(e)
					if e == person_info.OK then
					end
				end)	
			else
				silver_num = silver_num-sender.card_info.price
				person_info.set_user_silver(silver_num)
				self:show_silver()
				uikits.popScene()
			end								
		end,"click")		
	self.but_quit.func = self.show_mall_card
end

function Mallview:show_all_card()
	
	local function cleartitle()
		local titleview = self.temp_view:getChildren()
		for i,obj in pairs(titleview) do
			if obj:getTag() >100000 then
				obj:removeFromParent()
			end
		end
		self.temp_view:setInnerContainerSize(self.temp_view:getContentSize())
	end
	local id
	local func
	local function timer_update(time)
		func(self,id)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	
	cleartitle()	
	local card_space_heng = 100
	local card_space_shu = 20
	local card_num = 0

	local view_card_src = uikits.child(self.temp_view,ui.VIEW_CARD_SRC)
	local txt_wen = uikits.child(self.temp_view,ui.TXT_WEN)
	local but_cu = uikits.child(self.temp_view,ui.BUTTON_CU)
	local but_gold = uikits.child(self.temp_view,ui.BUTTON_GOLD)
	local but_silver = uikits.child(self.temp_view,ui.BUTTON_SILVER)
	for i=1,#self.card_info do
		local bag_card_info = person_info.get_card_in_bag_by_id(self.card_info[i].card_plate_id)
		if bag_card_info then
			card_num = card_num +1
		end
	end
	local row_num = card_num/5	
	row_num = math.ceil(row_num)
	
	local pos_wen_x,pos_wen_y = txt_wen:getPosition()
	local pos_cu_y = but_cu:getPositionY()
	local pos_silver_y = but_gold:getPositionY()
	local pos_gold_y = but_silver:getPositionY()
	
	view_card_src:setVisible(false)
	local size_scroll = self.temp_view:getInnerContainerSize()
	local size_card_src = view_card_src:getContentSize()
	local pos_card_src_x,pos_card_src_y = view_card_src:getPosition()
	local size_view = self.temp_view:getContentSize()	
	local pos_card_y_start = size_view.height - pos_card_src_y	
	local pos_card_x_start = pos_card_src_x	
	local pos_wen_y_start = size_view.height - pos_wen_y
	local pos_cu_y_start = size_view.height - pos_cu_y
	local pos_silver_y_start = size_view.height - pos_silver_y
	local pos_gold_y_start = size_view.height - pos_gold_y
	if size_scroll.height < (pos_card_y_start + row_num*(size_card_src.height+card_space_shu)- size_card_src.height) then
		size_scroll.height = pos_card_y_start + row_num*(size_card_src.height+card_space_shu) - size_card_src.height
		self.temp_view:setInnerContainerSize(size_scroll)
		txt_wen:setPosition(cc.p(pos_wen_x,size_scroll.height-pos_wen_y_start))	
		but_cu:setPositionY(pos_cu_y_start)
		but_gold:setPositionY(pos_gold_y_start)
		but_silver:setPositionY(pos_silver_y_start)
		pos_card_y_start = size_scroll.height-pos_card_y_start
	else
		pos_card_y_start = pos_card_src_y
	end
	local cur_row = 0
	local cur_line = 5
	for i=1,#self.card_info do
		local bag_card_info = person_info.get_card_in_bag_by_id(self.card_info[i].card_plate_id)
		if not bag_card_info then
			local cur_card = view_card_src:clone()
			cur_card:setVisible(true)
			self.temp_view:addChild(cur_card,0,100000+i)			
			if cur_line == 5 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_card_x_start +(size_card_src.width+card_space_heng)*(cur_line-1)
			local cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row-1)
			cur_card:setPosition(cc.p(cur_pos_x,cur_pos_y))

			local pic_card = uikits.child(cur_card,ui.PIC_CARD)
			local txt_card_name = uikits.child(cur_card,ui.TXT_CARD_NAME)			
			local but_card_pay = uikits.child(cur_card,ui.BUTTON_BUY)
			local txt_card_pay = uikits.child(cur_card,ui.TXT_CARD_PRICE)	
			local txt_card_lvl = uikits.child(cur_card,ui.TXT_CARD_LVL)	
			txt_card_name:setString(self.card_info[i].pro_name)		
			txt_card_pay:setString(self.card_info[i].price)		
			txt_card_lvl:setString(self.card_info[i].card_plate_level)		
			local n_pic_name = self.card_info[i].card_plate_id..'a.png'

			person_info.load_card_pic(pic_card,n_pic_name)
			pic_card.id = i
			but_card_pay.cur_info = self.card_info[i]
			uikits.event(pic_card,	
				function(sender,eventType)	
					id = sender.id
					func = self.show_card_info
					schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)										
				end,"click")	
			uikits.event(but_card_pay,	
				function(sender,eventType)	
					local silver_num = person_info.get_user_silver()
					if silver_num < sender.cur_info.price then
						person_info.messagebox(self,person_info.NO_SILVER,function(e)
							if e == person_info.OK then
							end
						end)	
					else
						silver_num = silver_num-sender.card_info.price
						person_info.set_user_silver(silver_num)
						self:show_silver()
						uikits.popScene()
					end
					--schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)									
				end,"click")				
		end
		
	end	
end

function Mallview:show_mall_card()
	self:resetgui()
	self.temp_view = self.all_card_view:clone()
	self.temp_view:setVisible(true)
	self._Mallview:addChild(self.temp_view,0,10000)
			
	local but_cu = uikits.child(self.temp_view,ui.BUTTON_CU)
	local but_gold = uikits.child(self.temp_view,ui.BUTTON_GOLD)
	local but_silver = uikits.child(self.temp_view,ui.BUTTON_SILVER)
	--self.sel_pinzhi = 1
	
	but_cu:setSelectedState(false)
	but_cu.index = 1
	but_gold:setSelectedState(false)
	but_gold.index = 3
	but_silver:setSelectedState(false)
	but_silver.index = 2
	if self.sel_pinzhi == 1 then
		but_cu:setSelectedState(true)
	elseif self.sel_pinzhi == 2 then
		but_silver:setSelectedState(true)
	elseif self.sel_pinzhi == 3 then
		but_gold:setSelectedState(true)
	end
	
	local function set_checkbox_pinzhi(cur_but,is_sel)
		if is_sel == true then
			if self.sel_pinzhi == 1 then
				but_cu:setSelectedState(false)
			elseif self.sel_pinzhi == 2 then
				but_silver:setSelectedState(false)
			elseif self.sel_pinzhi == 3 then
				but_gold:setSelectedState(false)
			end
			self.sel_pinzhi = cur_but.index
			self:getdatabyurl()
		else
			if cur_but.index == self.sel_pinzhi then
				cur_but:setSelectedState(true)
			end
		end
	end
	
	uikits.event(but_cu,	
		function(sender,eventType)	
			set_checkbox_pinzhi(sender,eventType)
	end)		
	uikits.event(but_gold,	
		function(sender,eventType)	
			set_checkbox_pinzhi(sender,eventType)
	end)	
	uikits.event(but_silver,	
		function(sender,eventType)	
			set_checkbox_pinzhi(sender,eventType)
	end)	
	self:getdatabyurl()
	self.but_quit.func = uikits.popScene
end

function Mallview:getdatabyurl()
	local send_data = {}
	send_data.v1 = self.sel_pinzhi
	person_info.post_data_by_new_form('get_product_cards',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				self.card_info = v
				self:show_all_card()			
			end
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:getdatabyurl()
				else
					self:getdatabyurl()
				end
			end)
		end
	end)
end

function Mallview:resetgui()
	if self.temp_view then
		self._Mallview:removeChildByTag(10000)	
		self.temp_view = nil
	end
	cc.TextureCache:getInstance():removeUnusedTextures()
end	

function Mallview:gui_init()	
	self.all_card_view = uikits.child(self._Mallview,ui.VIEW_ALL_CARD)
	self.card_info_view = uikits.child(self._Mallview,ui.VIEW_CARD_INFO)
	self.all_card_view:setVisible(false)
	self.card_info_view:setVisible(false)
	self:show_silver()
	self:show_le_coin()
	self:show_mall_card()
end	

function Mallview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Mallview = uikits.fromJson{file_9_16=ui.Mallview_FILE,file_3_4=ui.Mallview_FILE_3_4}
	self:addChild(self._Mallview)

	--self:getdatabyurl()	
	self.but_quit = uikits.child(self._Mallview,ui.BUTTON_QUIT)
	uikits.event(self.but_quit,	
		function(sender,eventType)	
			self.but_quit.func(self);
		end,"click")	
	self:gui_init()	
--	local loadbox = Mallviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Mallview:release()

end
return {
create = create,
}