local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Bagview = class("Bagview")
Bagview.__index = Bagview
local ui = {
	Bagview_FILE = 'poetrymatch/beibao.json',
	Bagview_FILE_3_4 = 'poetrymatch/beibao.json',
	
	VIEW_BAG = 'gun',
	VIEW_BATTLE_LIST = 'czk',
	PIC_CARD_BATTLE = 'czk/kp1',
	BUTTON_CARD_EXCHANGE = 'g1',
	TXT_CARD_BATTLE_LVL = 'dj',
	PIC_CARD_BATTLE_UPLVL = 'sjl',
	VIEW_CARD_BAG = 'k1',
	PIC_CARD_BAG = 'kp',
	TXT_CARD_BAG_LVL = 'kp/dj',
	PIC_CARD_BAG_UPLVL = 'sjl',
	VIEW_BUY_STORE = 'zhenjia',
	
	VIEW_CARD_INFO = 'kpxiangq',
	PIC_CARD_INFO = 'kp',
	TXT_CARD_INFO_LVL = 'kp/dj',
	TXT_CARD_INFO_NAME = 'mz',
	PIC_CARD_INFO_GOLD = 'jing',
	PIC_CARD_INFO_SILVER = 'yin',
	PIC_CARD_INFO_CU = 'tong',
	BUTTON_CARD_INFO_SHOW_SHI = 'ksj',
	BUTTON_CARD_INFO_DEL = 'diuq',
	PRO_CARD_INFO_AP = 'gongj/jd',
	TXT_CARD_INFO_AP = 'gongj/shuz',
	PIC_CARD_INFO_AP = 't1',
	BUTTON_CARD_INFO_AP_EX = 'bugj',
	TXT_CARD_INFO_AP_EX = 'yb1',
	PRO_CARD_INFO_HP = 'shengm/jd',
	TXT_CARD_INFO_HP = 'shengm/shuz',
	PIC_CARD_INFO_HP = 't2',
	BUTTON_CARD_INFO_HP_EX = 'busm',
	TXT_CARD_INFO_HP_EX = 'yb2',
	PRO_CARD_INFO_MP = 'zhili/jd',
	TXT_CARD_INFO_MP = 'zhili/shuz',
	PIC_CARD_INFO_MP = 't3',
	BUTTON_CARD_INFO_MP_EX = 'buzl',
	TXT_CARD_INFO_MP_EX = 'yb3',
	PRO_CARD_INFO_PP = 'shij/jd',
	TXT_CARD_INFO_PP = 'shij/shuz',
	PIC_CARD_INFO_PP = 't4',
	BUTTON_CARD_INFO_PP_EX = 'busj',
	TXT_CARD_INFO_PP_EX = 'yb4',
	PRO_CARD_INFO_SP = 'shengli/jd',
	TXT_CARD_INFO_SP = 'shengli/shuz',	
	PIC_CARD_INFO_SP = 't5',
	BUTTON_CARD_INFO_SP_EX = 'busl',
	TXT_CARD_INFO_SP_EX = 'leb',
	BUTTON_CARD_INFO_SKILL = 's1',
	BUTTON_CARD_INFO_SKILL_EMPTY = 'jn0',
	BUTTON_CARD_INFO_SKILL_RESET = 'chongxjn',
	TXT_CARD_INFO_SKILL_RESET = 'qian6',
	
	VIEW_SHI_LIST = 'shiji',
	VIEW_SHI_DES = 'jianjie',
	TXT_SHI_DES = 'jianjie/wen',
	BUTTON_SHI_NAME = 'si1',
	TXT_SHI_NAME = 'mz',
	
	VIEW_SHI_INFO = 'shi',
	VIEW_SHI_INFO_SRC = 'shi1',
	VIEW_SHI_INFO_TITLE = 'shim',
	VIEW_SHI_INFO_CONTENT = 'shiju',
	VIEW_SHI_INFO_NAME = 'zuoz',
	TXT_SHI_INFO_AUT_NAME = 'zuoz/zuoz',
	TXT_SHI_INFO_NAME = 'shim/sm',
	TXT_SHI_INFO_YEARS = 'zuoz/caod',
	TXT_SHI_INFO_DATA = 'shiju/sj',
--	VIEW_SHI_INFO_DES = 'yiwen',
--	TXT_SHI_INFO_DES = 'yiwen/wen',
	
	VIEW_CARD_EXCHANGE = 'gengh',
	TXT_CARD_EXCHANGE_WEN = 'wen',
	VIEW_CARD_EXCHANGE_INFO = 'kp1',
	TXT_CARD_EXCHANGE_LVL = 'dj',
	TXT_CARD_EXCHANGE_NAME = 'mz',
	
	VIEW_SKILL_INFO = 'jnxiangq',
	PIC_SKILL_INFO = 'tu',
	TXT_SKILL_INFO_NAME = 'mz',
	TXT_SKILL_INFO_DES = 'jies',
	
	VIEW_LEARN_SKILL = 'xuexijn',
	TXT_LEARN_SKILL_WEN = 'wen',
	VIEW_LEARN_SKILL_SRC = 'jn1',
	PIC_LEARN_SKILL = 'jn',
	TXT_LEARN_SKILL_NAME = 'jn/mz',
	BUTTON_LEARN_SKILL_PAY = 'mail',
	TXT_LEARN_SKILL_PAY = 'qian',
	
	
	VIEW_NO_CARD = 'meiyyougenghuan',
	PIC_SEX_MAN = 'xingbie2',
	PIC_SEX_WOMAN = 'xingbie',

	BUTTON_SILVER = 'xinxi/yibi/jia',
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

function create(card_id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Bagview)		
	if card_id then
		cur_layer.card_id = card_id 	
	end
	
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

function Bagview:show_silver()
	local silver_num = person_info.get_user_silver()
	local txt_silver = uikits.child(self._Bagview,ui.TXT_SILVER_NUM)
	txt_silver:setString(silver_num)
	
	local but_silver = uikits.child(self._Bagview,ui.BUTTON_SILVER)
--	but_silver:setVisible(false)
	uikits.event(but_silver,	
		function(sender,eventType)	
			local le_num = person_info.get_user_le_coin()
			if le_num < 10 then
				person_info.messagebox(self._Bagview,person_info.NO_LE,function(e)
					if e == person_info.OK then
						print('aaaaaaaaaaaa')
					else
						print('bbbbbbbbbbbb')
					end
				end)
			else
				local send_data = {}
				send_data.v1 = 36
				person_info.post_data_by_new_form(self._Bagview,'buy_products',send_data,function(t,v)
					if t and t == 200 then
						le_num = le_num -10 
						silver_num = silver_num + 1000
						local txt_le = uikits.child(self._Bagview,ui.TXT_LE_NUM)
						txt_le:setString(le_num)
						txt_silver:setString(silver_num)
						person_info.set_user_silver(silver_num)
						person_info.set_user_le_coin(le_num)
					else
						person_info.messagebox(self._Bagview,person_info.NETWORK_ERROR,function(e)
							if e == person_info.OK then
								
							else
								
							end
						end)							
					end
				end)
			end	
		end,"click")
end

function Bagview:show_le_coin()
	local le_num = person_info.get_user_le_coin()
	local txt_le = uikits.child(self._Bagview,ui.TXT_LE_NUM)
	txt_le:setString(le_num)
	
	local but_le = uikits.child(self._Bagview,ui.BUTTON_LE)
	but_le:setVisible(false)
	uikits.event(but_le,	
		function(sender,eventType)	
			
		end,"click")
end

local card_space_shu = 42
local card_space_heng = 94
local card_battle_space = 188
local card_space_shu_exchange = 60	
	
function Bagview:show_exchange_card(id)	
	self:resetgui()
	--self.view_bag:setVisible(true)
	local all_card_info = person_info.get_all_card_in_bag()
	local battle_cards = person_info.get_all_card_in_battle()
	if #battle_cards == #all_card_info then
		self.temp_view = self.view_no_card:clone()
		self.temp_view:setVisible(true)
		self._Bagview:addChild(self.temp_view,0,10000)	
		local pic_sex_man = uikits.child(self.temp_view,ui.PIC_SEX_MAN)
		local pic_sex_woman = uikits.child(self.temp_view,ui.PIC_SEX_WOMAN)
		pic_sex_man:setVisible(false)
		pic_sex_woman:setVisible(false)
		local user_info = person_info.get_user_info()
		if user_info.sex == 1 then
			pic_sex_man:setVisible(true)
		else 
			pic_sex_woman:setVisible(true)
		end
		self.but_quit.func = self.show_bag_view
		return
	end
	
	self.temp_view = self.view_card_exchange:clone()
	self.temp_view:setVisible(true)
	self._Bagview:addChild(self.temp_view,0,10000)

	local func
	local function timer_update(time)
		func(self)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	

	local view_card_bag_src = uikits.child(self.temp_view,ui.VIEW_CARD_EXCHANGE_INFO)
	local txt_card_wen = uikits.child(self.temp_view,ui.TXT_CARD_EXCHANGE_WEN)
	local row_num = #all_card_info/5	
	--local row_num = 18/5	
	row_num = math.ceil(row_num)
	
	local pos_wen_x,pos_wen_y = txt_card_wen:getPosition()
	view_card_bag_src:setVisible(false)
	local size_scroll = self.temp_view:getInnerContainerSize()
	local size_card_src = view_card_bag_src:getContentSize()
	local pos_card_src_x,pos_card_src_y = view_card_bag_src:getPosition()
	local size_exchange_view = self.temp_view:getContentSize()	
	local pos_card_y_start = size_exchange_view.height - pos_card_src_y	
	local pos_card_x_start = pos_card_src_x	
	local pos_wen_y_start = size_exchange_view.height - pos_wen_y
	if size_scroll.height < (pos_card_y_start + row_num*(size_card_src.height+card_space_shu_exchange) - size_card_src.height/2) then
		size_scroll.height = pos_card_y_start + row_num*(size_card_src.height+card_space_shu_exchange) - size_card_src.height/2
		self.temp_view:setInnerContainerSize(size_scroll)
		txt_card_wen:setPosition(cc.p(pos_wen_x,size_scroll.height-pos_wen_y_start))	
		pos_card_y_start = size_scroll.height-pos_card_y_start
	else
		pos_card_y_start = pos_card_src_y
	end

	local cur_row = 0
	local cur_line = 5
	for i=1,#all_card_info do
--[[	for j=1,18 do
		local i = 2--]]
		if all_card_info[i].in_battle_list == 0 then
			local cur_card = view_card_bag_src:clone()
			cur_card:setVisible(true)
			self.temp_view:addChild(cur_card)
		
			local txt_card_lvl = uikits.child(cur_card,ui.TXT_CARD_EXCHANGE_LVL)
			local txt_card_name = uikits.child(cur_card,ui.TXT_CARD_EXCHANGE_NAME)
			txt_card_name:setString(all_card_info[i].name)
			if cur_line == 5 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_card_x_start +(size_card_src.width+card_space_heng)*(cur_line-1)
			local cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu_exchange)*(cur_row-1)
			cur_card:setPosition(cc.p(cur_pos_x,cur_pos_y))
			
			local pic_name = all_card_info[i].id..'b.png'
			person_info.load_card_pic(cur_card,pic_name)
			txt_card_lvl:setString(all_card_info[i].lvl)
			cur_card.in_id = all_card_info[i].id
			cur_card.out_id = id
			uikits.event(cur_card,	
				function(sender,eventType)	
					local send_data = {}
					local battle_list = person_info.get_battle_list()
					for j=1,#battle_list do
						if battle_list[j] == sender.out_id then
							battle_list[j] = sender.in_id
						end
					end
					send_data.v1 = battle_list
					person_info.post_data_by_new_form(self._Bagview,'set_main_cardplate',send_data,function(t,v)
							if t and t == 200 then
								person_info.exchange_card_in_battle_by_id(sender.in_id,sender.out_id)
								func = self.show_bag_view
								schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)	
							else
								person_info.messagebox(self._Bagview,person_info.NETWORK_ERROR,function(e)
									if e == person_info.OK then
									end
								end)
							end		
						end)							
				end,"click")
			txt_card_lvl:setVisible(true)
		end		
	end
	self.but_quit.func = self.show_bag_view
end
	
function Bagview:buy_store()	
	local le_num = person_info.get_user_le_coin()
	if le_num < 5 then	
		person_info.messagebox(self._Bagview,person_info.NO_LE,function(e)
			if e == person_info.OK then
				print('aaaaaaaaaaaa')
			else
				print('bbbbbbbbbbbb')
			end
		end)
	else
		local store_num = person_info.get_max_store_num()
		if store_num then
			store_num = store_num +5
			person_info.set_max_store_num(store_num)
		end
		le_num = le_num -5 
		local txt_le = uikits.child(self._Bagview,ui.TXT_LE_NUM)
		txt_le:setString(le_num)
		person_info.set_user_le_coin(le_num)
		self:show_bag_view()	
	end
end

function Bagview:show_shi_des(id)
	
	local function show_shi_des_gui(shi_des)
		self:resetgui()
		self.temp_view = self.view_shi_info:clone()
		self.temp_view:setVisible(true)
		self._Bagview:addChild(self.temp_view,0,10000)		
			
		--local view_shi_info = uikits.child(self.temp_view,ui.VIEW_SHI_INFO)
		local view_shi_info_src = uikits.child(self.temp_view,ui.VIEW_SHI_INFO_SRC)
		local viewSize=self.temp_view:getContentSize()
		local viewPosition=cc.p(self.temp_view:getPosition())
		local viewParent=self.temp_view:getParent()

		view_shi_info_src:setVisible(false)	
		if shi_des and type(shi_des) == 'table' then
			local view_person_rank1=person_info.createRankView(self.temp_view,viewPosition,viewSize,view_shi_info_src,function(item,data)
				item:setVisible(true)	
				local view_title = uikits.child(item,ui.VIEW_SHI_INFO_TITLE)	
				local view_content = uikits.child(item,ui.VIEW_SHI_INFO_CONTENT)
				local view_name = uikits.child(item,ui.VIEW_SHI_INFO_NAME)
				view_name:setVisible(false)
				view_title:setVisible(false)
				view_content:setVisible(false)		
				if data.poem_auther then
					view_name:setVisible(true)
					local txt_aut_name = uikits.child(item,ui.TXT_SHI_INFO_AUT_NAME)	
					local txt_years = uikits.child(item,ui.TXT_SHI_INFO_YEARS)	
					txt_aut_name:setString(data.poem_auther)
					txt_years:setString(data.poem_dynasty)	
					txt_aut_name:setPositionY(40)
				elseif data.poem_title then		
					view_title:setVisible(true)
					local txt_shi_name = uikits.child(item,ui.TXT_SHI_INFO_NAME)	
					txt_shi_name:setString(data.poem_title)
				else
					view_content:setVisible(true)
					local txt_data = uikits.child(item,ui.TXT_SHI_INFO_DATA)	
					txt_data:setString(data)
				end		
				end,function(waitingNode,afterReflash)
				local data = {}
				data[1] = {}
				data[1].poem_title = shi_des.poem_title
				data[2] = {}
				data[2].poem_auther = shi_des.poem_auther
				data[2].poem_dynasty = shi_des.poem_dynasty

				for i=1,#shi_des.poem_body do
					data[i+2] = shi_des.poem_body[i]
				end
				afterReflash(data)
			end)		
		end		
		self.but_quit.func = self.show_shi_list	
	end
	
	local send_data = {}
	send_data.v1 = id
	person_info.post_data_by_new_form(self._Bagview,'poems_detail',send_data,function(t,v)
		if t and t == 200 then
			show_shi_des_gui(v)
		else
			person_info.messagebox(self._Bagview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)	
end

function Bagview:show_shi_list()	

	local shi_spcae_heng = 20
	local shi_spcae_shu = 20
	
	local func
	local id
	local function timer_update(time)
		func(self,id)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end		
	
	local function show_shi(shi_info)
		self:resetgui()
		self.temp_view = self.view_shi_list:clone()
		self.temp_view:setVisible(true)
		self._Bagview:addChild(self.temp_view,0,10000)		
		local view_des = uikits.child(self.temp_view,ui.VIEW_SHI_DES)
		local txt_shi_des = uikits.child(self.temp_view,ui.TXT_SHI_DES)	
		txt_shi_des:setString(shi_info.auther_introduction)
		local shi_name_src = uikits.child(self.temp_view,ui.BUTTON_SHI_NAME)	
		shi_name_src:setVisible(false)
		
		if shi_info.list and type(shi_info.list) == 'table' then
			local shi_name_list = shi_info.list
			local row_num = #shi_name_list/3	
			row_num = math.ceil(row_num)

			local size_scroll = self.temp_view:getInnerContainerSize()
			local size_name_src = shi_name_src:getContentSize()
			local pos_name_src_x,pos_name_src_y = shi_name_src:getPosition()
			local size_shi_view = self.temp_view:getContentSize()	
			local pos_name_y_start = size_shi_view.height - pos_name_src_y	
			local pos_name_x_start = pos_name_src_x	
			local pos_des_y = view_des:getPositionY()
			local pos_des_y_start = size_shi_view.height - pos_des_y
			if size_scroll.height < (pos_name_y_start + row_num*(size_name_src.height+shi_spcae_shu)- size_name_src.height) then
				size_scroll.height = pos_name_y_start + row_num*(size_name_src.height+shi_spcae_shu) - size_name_src.height
				self.temp_view:setInnerContainerSize(size_scroll)
				view_des:setPositionY(size_scroll.height-pos_des_y_start)	
				pos_name_y_start = size_scroll.height-pos_name_y_start
			else
				pos_name_y_start = pos_name_src_y
			end			
			local cur_row = 0
			local cur_line = 3
			for i=1,#shi_name_list do
				local cur_shi = shi_name_src:clone()
				cur_shi:setVisible(true)
				self.temp_view:addChild(cur_shi)			
				if cur_line == 3 then
					cur_line = 1
					cur_row = cur_row + 1 
				else
					cur_line = cur_line + 1 
				end		
				local cur_pos_x = pos_name_x_start +(size_name_src.width+shi_spcae_heng)*(cur_line-1)
				local cur_pos_y = pos_name_y_start -(size_name_src.height+shi_spcae_shu)*(cur_row-1)
				cur_shi:setPosition(cc.p(cur_pos_x,cur_pos_y))	
				local txt_cur_shi_name = uikits.child(cur_shi,ui.TXT_SHI_NAME)	
				txt_cur_shi_name:setString(shi_name_list[i].poems_title)
				cur_shi.id = shi_name_list[i].poems_id
				uikits.event(cur_shi,	
					function(sender,eventType)	
						id = sender.id
						func = self.show_shi_des
						schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)										
					end,"click")	
			end
		end
		self.but_quit.func = self.show_card_info
	end		
	
	local send_data = {}
	send_data.v1 = self.card_id
	person_info.post_data_by_new_form(self._Bagview,'get_user_card_plate_poems',send_data,function(t,v)
		if t and t == 200 then
			show_shi(v)
		else
			person_info.messagebox(self._Bagview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)	
end

function Bagview:show_skill_info(id,back_type)		
	self:resetgui()
	self.temp_view = self.view_skill_info:clone()
	self.temp_view:setVisible(true)
	self._Bagview:addChild(self.temp_view,0,10000)	
	local pic_skill = uikits.child(self.temp_view,ui.PIC_SKILL_INFO)	
	local txt_skill_name = uikits.child(self.temp_view,ui.TXT_SKILL_INFO_NAME)
	local txt_skill_des = uikits.child(self.temp_view,ui.TXT_SKILL_INFO_DES)
	local skill_info = person_info.get_skill_info_by_id(id)

	local n_pic_name = skill_info.sub_id..'a.png'
	local d_pic_name = skill_info.sub_id..'b.png'
--[[			local n_pic_name = '1a.png'
	local d_pic_name = '1b.png'--]]
	person_info.load_skill_pic(pic_skill,n_pic_name,n_pic_name,d_pic_name)
	txt_skill_name:setString(skill_info.pro_name)
	txt_skill_des:setString(skill_info.pro_desc)
	if back_type == 1 then
		self.but_quit.func = self.show_card_info
	elseif back_type == 2 then
		self.but_quit.func = self.show_skill_mall
	end
end

function Bagview:show_skill_mall()		
	local skill_spcae_heng = 95
	local skill_spcae_shu = 50
	self:resetgui()
	self.temp_view = self.view_learn_skill:clone()
	self.temp_view:setVisible(true)
	self._Bagview:addChild(self.temp_view,0,10000)
	
	local func
	local callback_type = 2
	local callback_id
	local function timer_update(time)
		func(self,callback_id,callback_type)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end		
	
	local skill_list = person_info.get_skill_list()
	local skill_num = #skill_list
	if self.card_info.skill_max then
		skill_num = skill_num - #self.card_info.skills
	end
	
	local view_skill_src = uikits.child(self.temp_view,ui.VIEW_LEARN_SKILL_SRC)
	local txt_skill_wen = uikits.child(self.temp_view,ui.TXT_LEARN_SKILL_WEN)
	local row_num = skill_num/6	
	row_num = math.ceil(row_num)
	
	local pos_wen_x,pos_wen_y = txt_skill_wen:getPosition()
	view_skill_src:setVisible(false)
	local size_scroll = self.temp_view:getInnerContainerSize()
	local size_skill_src = view_skill_src:getContentSize()
	local pos_skill_src_x,pos_skill_src_y = view_skill_src:getPosition()
	local size_skill_learn_view = self.temp_view:getContentSize()	
	local pos_skill_y_start = size_skill_learn_view.height - pos_skill_src_y	
	local pos_skill_x_start = pos_skill_src_x	
	local pos_wen_y_start = size_skill_learn_view.height - pos_wen_y
	if size_scroll.height < (pos_skill_y_start + row_num*(size_skill_src.height+skill_spcae_shu)- size_skill_src.height) then
		size_scroll.height = pos_skill_y_start + row_num*(size_skill_src.height+skill_spcae_shu) - size_skill_src.height
		self.temp_view:setInnerContainerSize(size_scroll)
		txt_skill_wen:setPosition(cc.p(pos_wen_x,size_scroll.height-pos_wen_y_start))	
		pos_skill_y_start = size_scroll.height-pos_skill_y_start
	else
		pos_skill_y_start = pos_skill_src_y
	end
	local cur_row = 0
	local cur_line = 6
	for i=1,#skill_list do
		local is_has_skill = false
		for j=1 ,#self.card_info.skills do
			if skill_list[i].sub_id == self.card_info.skills[j].skill_id then
				is_has_skill = true
				break
			end
		end
		if is_has_skill == false then
			local cur_skill = view_skill_src:clone()
			cur_skill:setVisible(true)
			self.temp_view:addChild(cur_skill)			
			if cur_line == 6 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_skill_x_start +(size_skill_src.width+skill_spcae_heng)*(cur_line-1)
			local cur_pos_y = pos_skill_y_start -(size_skill_src.height+skill_spcae_shu)*(cur_row-1)
			cur_skill:setPosition(cc.p(cur_pos_x,cur_pos_y))
			local pic_skill = uikits.child(cur_skill,ui.PIC_LEARN_SKILL)
			local txt_skill_name = uikits.child(cur_skill,ui.TXT_LEARN_SKILL_NAME)			
			local but_skill_pay = uikits.child(cur_skill,ui.BUTTON_LEARN_SKILL_PAY)
			local txt_skill_pay = uikits.child(cur_skill,ui.TXT_LEARN_SKILL_PAY)	
			txt_skill_name:setString(skill_list[i].pro_name)		
			txt_skill_pay:setString(skill_list[i].price)		
			local n_pic_name = skill_list[i].sub_id..'a.png'
			local d_pic_name = skill_list[i].sub_id..'b.png'
--[[			local n_pic_name = '1a.png'
			local d_pic_name = '1b.png'--]]
			person_info.load_skill_pic(pic_skill,n_pic_name,n_pic_name,d_pic_name)
			pic_skill.id = skill_list[i].sub_id
			but_skill_pay.id = skill_list[i].sub_id
			uikits.event(pic_skill,	
				function(sender,eventType)	
					callback_id = sender.id
					func = self.show_skill_info
					schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)										
				end,"click")	
			uikits.event(but_skill_pay,	
				function(sender,eventType)	
					local sel_skill_info = person_info.get_skill_info_by_id(sender.id)
					local new_skill_info = {}
					new_skill_info.skill_id = sel_skill_info.sub_id
					new_skill_info.skill_name = sel_skill_info.pro_name
					new_skill_info.skill_desc = sel_skill_info.pro_desc
					self.card_info.skills[#self.card_info.skills+1] = new_skill_info
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					func = self.show_card_info
					schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)									
				end,"click")	
			
		end
	end
	self.but_quit.func = self.show_card_info
end

function Bagview:show_card_info(id)	
	self.card_id = id
	self:resetgui()
	self.temp_view = self.view_card_info:clone()
	self.temp_view:setVisible(true)
	self._Bagview:addChild(self.temp_view,0,10000)
	local func
	local callback_type = 1
	local callback_id
	local function timer_update(time)
		func(self,callback_id,callback_type)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	
	local function cost_thing(id)
		local send_data = {}
		send_data.v1 = self.card_id
		send_data.v2 = id
		person_info.post_data_by_new_form(self._Bagview,'user_cardplate_oper',send_data,function(t,v)
			if t and t == 200 then
				if id == 6 then
					self.card_info.skills={}
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					local silver_num = person_info.get_user_silver()
					silver_num = silver_num-self.card_info.skill_reset_pay
					person_info.set_user_silver(silver_num)
					self:show_silver()
					func = self.show_card_info
				elseif id == 1 then
					self.card_info.ap_ex = self.card_info.ap_ex_max
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					local silver_num = person_info.get_user_silver()
					silver_num = silver_num-self.card_info.ap_pay
					person_info.set_user_silver(silver_num)
					self:show_silver()
					func = self.show_card_info
				elseif id == 2 then
					self.card_info.hp_ex = self.card_info.hp_ex_max
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					local silver_num = person_info.get_user_silver()
					silver_num = silver_num-self.card_info.hp_pay
					person_info.set_user_silver(silver_num)
					self:show_silver()
					func = self.show_card_info
				elseif id == 3 then
					self.card_info.mp_ex = self.card_info.mp_ex_max
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					local silver_num = person_info.get_user_silver()
					silver_num = silver_num-self.card_info.mp_pay
					person_info.set_user_silver(silver_num)
					self:show_silver()
					func = self.show_card_info
				elseif id == 4 then
					self.card_info.pp_ex = self.card_info.pp_ex_max
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					local silver_num = person_info.get_user_silver()
					silver_num = silver_num-self.card_info.pp_pay
					person_info.set_user_silver(silver_num)
					self:show_silver()
					func = self.show_card_info		
				elseif id == 5 then
					self.card_info.sp_ex = self.card_info.sp_ex_max
					person_info.update_card_in_bag_by_id(self.card_id,0,self.card_info)
					callback_id = self.card_id 
					local le_num = person_info.get_user_le_coin()
					le_num = le_num-self.card_info.sp_pay
					person_info.set_user_le_coin(le_num)
					self:show_le_coin()
					func = self.show_card_info						
				elseif id == 7 then
					if self.card_info.in_battle_list == 1 then
						person_info.exchange_card_in_battle_by_id(0,self.card_id)
					end
					person_info.del_card_in_bag_by_id(self.card_id)	
					func = self.show_bag_view
				end
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)	
			else
				person_info.messagebox(self._Bagview,person_info.NETWORK_ERROR,function(e)
					if e == person_info.OK then

					end
				end)
			end
		end)
	end		
	
	local card_info = person_info.get_card_in_bag_by_id(id)
	self.card_info = card_info
	local pic_card_info = uikits.child(self.temp_view,ui.PIC_CARD_INFO)
	local txt_card_info_lvl = uikits.child(self.temp_view,ui.TXT_CARD_INFO_LVL)
	local txt_card_info_name = uikits.child(self.temp_view,ui.TXT_CARD_INFO_NAME)
	local pic_card_info_gold = uikits.child(self.temp_view,ui.PIC_CARD_INFO_GOLD)
	local pic_card_info_silver = uikits.child(self.temp_view,ui.PIC_CARD_INFO_SILVER)
	local pic_card_info_cu = uikits.child(self.temp_view,ui.PIC_CARD_INFO_CU)
	local pic_name = card_info.id..'a.png'
	person_info.load_card_pic(pic_card_info,pic_name)
	txt_card_info_lvl:setString(card_info.lvl)
	txt_card_info_name:setString(card_info.name)
	pic_card_info_gold:setVisible(false)
	pic_card_info_silver:setVisible(false)
	pic_card_info_cu:setVisible(false)
	if card_info.pinzhi == 3 then
		pic_card_info_gold:setVisible(true)
	elseif card_info.pinzhi == 2 then
		pic_card_info_silver:setVisible(true)
	elseif card_info.pinzhi == 1 then
		pic_card_info_cu:setVisible(true)
	end	

	local but_card_info_show_shi = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_SHOW_SHI)
	but_card_info_show_shi.id = card_info.id
	local but_card_info_del = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_DEL)
	but_card_info_del.id = card_info.id
	uikits.event(but_card_info_show_shi,	
		function(sender,eventType)	
			func = self.show_shi_list
			schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
		end,"click")		
	uikits.event(but_card_info_del,	
		function(sender,eventType)	
			local silver_num = person_info.get_user_silver()
				person_info.messagebox(self._Bagview,person_info.DEL_CARD,function(e)
					if e == person_info.OK then
						cost_thing(7)
					else
						
					end
				end)
		end,"click")	

	local pro_card_info_ap = uikits.child(self.temp_view,ui.PRO_CARD_INFO_AP)
	local txt_card_info_ap = uikits.child(self.temp_view,ui.TXT_CARD_INFO_AP)
	local but_card_info_ap_ex = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_AP_EX)
	local txt_card_info_ap_ex = uikits.child(self.temp_view,ui.TXT_CARD_INFO_AP_EX)	
	local pic_card_info_ap = uikits.child(self.temp_view,ui.PIC_CARD_INFO_AP)
	local percent_ap = ((card_info.ap+card_info.ap_ex)/(card_info.ap+card_info.ap_ex_max))*100
	pro_card_info_ap:setPercent(percent_ap)
	if percent_ap == 100 then
		pic_card_info_ap:setVisible(false)
		but_card_info_ap_ex:setVisible(false)
		txt_card_info_ap_ex:setVisible(false)
	else
		pic_card_info_ap:setVisible(true)
		but_card_info_ap_ex:setVisible(true)
		txt_card_info_ap_ex:setVisible(true)		
	end
	txt_card_info_ap:setString(card_info.ap+card_info.ap_ex)
	txt_card_info_ap_ex:setString(card_info.ap_pay)
	uikits.event(but_card_info_ap_ex,	
		function(sender,eventType)	
			local silver_num = person_info.get_user_silver()
			if silver_num < card_info.ap_pay then
				person_info.messagebox(self._Bagview,person_info.NO_SILVER,function(e)
					if e == person_info.OK then
					end
				end)	
			else
				cost_thing(1)
			end
		end,"click")

	local pro_card_info_hp = uikits.child(self.temp_view,ui.PRO_CARD_INFO_HP)
	local txt_card_info_hp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_HP)
	local but_card_info_hp_ex = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_HP_EX)
	local txt_card_info_hp_ex = uikits.child(self.temp_view,ui.TXT_CARD_INFO_HP_EX)	
	local pic_card_info_hp = uikits.child(self.temp_view,ui.PIC_CARD_INFO_HP)
	local percent_hp = ((card_info.hp+card_info.hp_ex)/(card_info.hp+card_info.hp_ex_max))*100
	pro_card_info_hp:setPercent(percent_hp)
	txt_card_info_hp:setString(card_info.hp+card_info.hp_ex)
	txt_card_info_hp_ex:setString(card_info.hp_pay)
	if percent_hp == 100 then
		pic_card_info_hp:setVisible(false)
		but_card_info_hp_ex:setVisible(false)
		txt_card_info_hp_ex:setVisible(false)
	else
		pic_card_info_hp:setVisible(true)
		but_card_info_hp_ex:setVisible(true)
		txt_card_info_hp_ex:setVisible(true)		
	end
	uikits.event(but_card_info_hp_ex,	
		function(sender,eventType)	
			local silver_num = person_info.get_user_silver()
			if silver_num < card_info.hp_pay then
				person_info.messagebox(self._Bagview,person_info.NO_SILVER,function(e)
					if e == person_info.OK then
					end
				end)	
			else
				cost_thing(2)
			end
		end,"click")	

	local pro_card_info_mp = uikits.child(self.temp_view,ui.PRO_CARD_INFO_MP)
	local txt_card_info_mp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_MP)
	local but_card_info_mp_ex = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_MP_EX)
	local txt_card_info_mp_ex = uikits.child(self.temp_view,ui.TXT_CARD_INFO_MP_EX)
	local pic_card_info_mp = uikits.child(self.temp_view,ui.PIC_CARD_INFO_MP)
	local percent_mp = ((card_info.mp+card_info.mp_ex)/(card_info.mp+card_info.mp_ex_max))*100
	pro_card_info_mp:setPercent(percent_mp)
	if percent_mp == 100 then
		pic_card_info_mp:setVisible(false)
		but_card_info_mp_ex:setVisible(false)
		txt_card_info_mp_ex:setVisible(false)
	else
		pic_card_info_mp:setVisible(true)
		but_card_info_mp_ex:setVisible(true)
		txt_card_info_mp_ex:setVisible(true)		
	end
	txt_card_info_mp:setString(card_info.mp+card_info.mp_ex)
	txt_card_info_mp_ex:setString(card_info.mp_pay)
	uikits.event(but_card_info_mp_ex,	
		function(sender,eventType)	
			local silver_num = person_info.get_user_silver()
			if silver_num < card_info.mp_pay then
				person_info.messagebox(self._Bagview,person_info.NO_SILVER,function(e)
					if e == person_info.OK then
					end
				end)	
			else
				cost_thing(3)
			end
		end,"click")	

	local pro_card_info_pp = uikits.child(self.temp_view,ui.PRO_CARD_INFO_PP)
	local txt_card_info_pp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_PP)
	local but_card_info_pp_ex = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_PP_EX)
	local txt_card_info_pp_ex = uikits.child(self.temp_view,ui.TXT_CARD_INFO_PP_EX)
	local pic_card_info_pp = uikits.child(self.temp_view,ui.PIC_CARD_INFO_PP)
	local percent_pp = ((card_info.pp+card_info.pp_ex)/(card_info.pp+card_info.pp_ex_max))*100
	if percent_pp == 100 then
		pic_card_info_pp:setVisible(false)
		but_card_info_pp_ex:setVisible(false)
		txt_card_info_pp_ex:setVisible(false)
	else
		pic_card_info_pp:setVisible(true)
		but_card_info_pp_ex:setVisible(true)
		txt_card_info_pp_ex:setVisible(true)		
	end
	pro_card_info_pp:setPercent(percent_pp)
	txt_card_info_pp:setString(card_info.pp+card_info.pp_ex)
	txt_card_info_pp_ex:setString(card_info.pp_pay)
	uikits.event(but_card_info_pp_ex,	
		function(sender,eventType)	
			local silver_num = person_info.get_user_silver()
			if silver_num < card_info.pp_pay then
				person_info.messagebox(self._Bagview,person_info.NO_SILVER,function(e)
					if e == person_info.OK then
					end
				end)	
			else
				cost_thing(4)
			end
		end,"click")	

	local pro_card_info_sp = uikits.child(self.temp_view,ui.PRO_CARD_INFO_SP)
	local txt_card_info_sp = uikits.child(self.temp_view,ui.TXT_CARD_INFO_SP)
	local but_card_info_sp_ex = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_SP_EX)
	local txt_card_info_sp_ex = uikits.child(self.temp_view,ui.TXT_CARD_INFO_SP_EX)
	local pic_card_info_sp = uikits.child(self.temp_view,ui.PIC_CARD_INFO_SP)
	local percent_sp = ((card_info.sp+card_info.sp_ex)/(card_info.sp+card_info.sp_ex_max))*100
	if percent_sp == 100 then
		pic_card_info_sp:setVisible(false)
		but_card_info_sp_ex:setVisible(false)
		txt_card_info_sp_ex:setVisible(false)
	else
		pic_card_info_sp:setVisible(true)
		but_card_info_sp_ex:setVisible(true)
		txt_card_info_sp_ex:setVisible(true)		
	end
	pro_card_info_sp:setPercent(percent_sp)
	txt_card_info_sp:setString(card_info.sp+card_info.sp_ex)
	txt_card_info_sp_ex:setString(card_info.sp_pay)
	uikits.event(but_card_info_sp_ex,	
		function(sender,eventType)	
			local le_num = person_info.get_user_le_coin()
			if le_num < card_info.sp_pay then
				person_info.messagebox(self._Bagview,person_info.NO_LE,function(e)
					if e == person_info.OK then
					end
				end)	
			else
				cost_thing(5)
			end
		end,"click")	
		
	local but_card_info_skill_src = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_SKILL)
	local but_card_info_skill_empty_src = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_SKILL_EMPTY)
	local but_card_info_skill_reset = uikits.child(self.temp_view,ui.BUTTON_CARD_INFO_SKILL_RESET)
	local txt_card_info_skill_reset = uikits.child(self.temp_view,ui.TXT_CARD_INFO_SKILL_RESET)
	txt_card_info_skill_reset:setString(card_info.skill_reset_pay)
	uikits.event(but_card_info_skill_reset,	
		function(sender,eventType)	
			person_info.messagebox(self._Bagview,person_info.RESET_SKILL,function(e)
				if e == person_info.OK then
					local silver_num = person_info.get_user_silver()
					if silver_num < card_info.skill_reset_pay then
						person_info.messagebox(self._Bagview,person_info.NO_SILVER,function(e)
							if e == person_info.OK then
							end
						end)	
					else
						cost_thing(6)
					end
				else

				end
			end)
		
		end,"click")		
	but_card_info_skill_src:setVisible(false)
	but_card_info_skill_empty_src:setVisible(false)	
	local skill_spcae = 20
	local pos_x_start = but_card_info_skill_src:getPositionX()
	local size_skill = but_card_info_skill_src:getContentSize()
	for i=1,card_info.skill_max do
		local but_skill
		if card_info.skills[i] then
			but_skill = but_card_info_skill_src:clone()
			but_skill.id = card_info.skills[i].skill_id
			local n_pic_name = card_info.skills[i].skill_id..'a.png'
			local d_pic_name = card_info.skills[i].skill_id..'b.png'
--[[			local n_pic_name = '1a.png'
			local d_pic_name = '1b.png'--]]
			person_info.load_skill_pic(but_skill,n_pic_name,n_pic_name,d_pic_name)
			uikits.event(but_skill,	
				function(sender,eventType)	
					callback_id = sender.id
					print('callback_id::'..callback_id)
					func = self.show_skill_info
					schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)					
				end,"click")	
		else
			but_skill = but_card_info_skill_empty_src:clone()
			uikits.event(but_skill,	
				function(sender,eventType)	
					func = self.show_skill_mall
					schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)										
				end,"click")	
		end
		but_skill:setPositionX(pos_x_start+(i-1)*(skill_spcae+size_skill.width))
		but_skill:setVisible(true)
		self.temp_view:addChild(but_skill)	
	end
	self.but_quit.func = self.show_bag_view
end

function Bagview:show_bag_view()	
	self:resetgui()
	--self.view_bag:setVisible(true)
	self.temp_view = self.view_bag:clone()
	self.temp_view:setVisible(true)
	self._Bagview:addChild(self.temp_view,0,10000)
	local id
	local func
	local function timer_update(time)
		func(self,id)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	
	
	local all_card_info,max_store_num = person_info.get_all_card_in_bag()
	local battle_cards = person_info.get_all_card_in_battle()
	local view_card_bag_src = uikits.child(self.temp_view,ui.VIEW_CARD_BAG)
	local view_battle_list = uikits.child(self.temp_view,ui.VIEW_BATTLE_LIST)
	--local size_battle_list = view_battle_list:getContentSize()
	local size_scroll = self.temp_view:getInnerContainerSize()
	local size_bag_view = self.temp_view:getContentSize()
	local size_card_src = view_card_bag_src:getContentSize()
	local pos_battle_list_x,pos_battle_list_y = view_battle_list:getPosition()
	local pos_card_src_x,pos_card_src_y = view_card_bag_src:getPosition()
	local row_num = max_store_num/5+1
	local pos_card_y_start = size_bag_view.height - pos_card_src_y
	local pos_battle_y_start = size_bag_view.height - pos_battle_list_y
	
	size_scroll.height = pos_card_y_start + row_num*(size_card_src.height+card_space_shu) - size_card_src.height/2
	self.temp_view:setInnerContainerSize(size_scroll)
	view_battle_list:setPosition(cc.p(pos_battle_list_x,size_scroll.height-pos_battle_y_start))
	
	pos_card_y_start = size_scroll.height-pos_card_y_start
	local pos_card_x_start = pos_card_src_x
	local cur_row = 0
	local cur_line = 5
	view_card_bag_src:setVisible(false)
	for i=1,max_store_num+#battle_cards do
		if i>#all_card_info then
			local cur_card = view_card_bag_src:clone()
			cur_card:setVisible(true)
			self.temp_view:addChild(cur_card)
			local pic_card_bag = uikits.child(cur_card,ui.PIC_CARD_BAG)
			local txt_card_bag_lvl = uikits.child(cur_card,ui.TXT_CARD_BAG_LVL)
			local pic_card_bag_uplvl = uikits.child(cur_card,ui.PIC_CARD_BAG_UPLVL)
			if cur_line == 5 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_card_x_start +(size_card_src.width+card_space_heng)*(cur_line-1)
			local cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row-1)
			cur_card:setPosition(cc.p(cur_pos_x,cur_pos_y))
			
			if i>#all_card_info then
				pic_card_bag:setVisible(false)
				txt_card_bag_lvl:setVisible(false)
				pic_card_bag_uplvl:setVisible(false)
			end		
			if i == max_store_num+#battle_cards then
				cur_pos_x = pos_card_x_start
				cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row)
				local view_buy_store = uikits.child(self.temp_view,ui.VIEW_BUY_STORE)
				view_buy_store:setPosition(cc.p(cur_pos_x,cur_pos_y))
				uikits.event(view_buy_store,	
					function(sender,eventType)	
						func = self.buy_store
						schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
					end,"click")			
			end
		elseif all_card_info[i].in_battle_list == 0 then
			local cur_card = view_card_bag_src:clone()
			cur_card:setVisible(true)
			self.temp_view:addChild(cur_card)
			local pic_card_bag = uikits.child(cur_card,ui.PIC_CARD_BAG)
			local txt_card_bag_lvl = uikits.child(cur_card,ui.TXT_CARD_BAG_LVL)
			local pic_card_bag_uplvl = uikits.child(cur_card,ui.PIC_CARD_BAG_UPLVL)
			if cur_line == 5 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_card_x_start +(size_card_src.width+card_space_heng)*(cur_line-1)
			local cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row-1)
			cur_card:setPosition(cc.p(cur_pos_x,cur_pos_y))
			
			local pic_name = all_card_info[i].id..'a.png'
			person_info.load_card_pic(pic_card_bag,pic_name)
			txt_card_bag_lvl:setString(all_card_info[i].lvl)
			pic_card_bag.id = all_card_info[i].id
			print('all_card_info[i].lvl::'..all_card_info[i].lvl)
			uikits.event(pic_card_bag,	
				function(sender,eventType)	
					--self:show_card_info(sender.id)
					id = sender.id
					func = self.show_card_info
					schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
				end,"click")
			pic_card_bag:setVisible(true)
			txt_card_bag_lvl:setVisible(true)
			pic_card_bag_uplvl:setVisible(true)
		end
	end

	local card_battle_src = uikits.child(self.temp_view,ui.PIC_CARD_BATTLE)
	card_battle_src:setVisible(false)

	for i=1,#battle_cards do
		local cur_card = card_battle_src:clone()
		local pic_name = battle_cards[i].id..'b.png'
		person_info.load_card_pic(cur_card,pic_name)
		local txt_card_lvl = uikits.child(cur_card,ui.TXT_CARD_BATTLE_LVL)
		local pos_x = cur_card:getPositionX()
		local size_card = cur_card:getContentSize()
		pos_x = pos_x+(size_card.width+card_battle_space)*(i-1)
		cur_card:setPositionX(pos_x)
		txt_card_lvl:setString(battle_cards[i].lvl)
		local but_card_exchange = uikits.child(cur_card,ui.BUTTON_CARD_EXCHANGE)
		but_card_exchange.id = battle_cards[i].id
		cur_card.id = battle_cards[i].id
		uikits.event(but_card_exchange,	
			function(sender,eventType)	
				--self:show_exchange_card(sender.id)
				id = sender.id
				func = self.show_exchange_card
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
			end,"click")
		uikits.event(cur_card,	
			function(sender,eventType)	
				id = sender.id
				func = self.show_card_info
				--self:show_card_info(sender.id)
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)
			end,"click")
		cur_card:setVisible(true)
		view_battle_list:addChild(cur_card)
	end	
	self.but_quit.func = uikits.popScene
end

function Bagview:resetgui()
	if self.temp_view then
		self._Bagview:removeChildByTag(10000)	
		self.temp_view = nil
	end
	cc.TextureCache:getInstance():removeUnusedTextures()
end	

function Bagview:initgui()	
	self.view_bag = uikits.child(self._Bagview,ui.VIEW_BAG)
	self.view_card_info = uikits.child(self._Bagview,ui.VIEW_CARD_INFO)
	self.view_shi_info = uikits.child(self._Bagview,ui.VIEW_SHI_INFO)
	self.view_card_exchange = uikits.child(self._Bagview,ui.VIEW_CARD_EXCHANGE)
	self.view_skill_info = uikits.child(self._Bagview,ui.VIEW_SKILL_INFO)
	self.view_learn_skill = uikits.child(self._Bagview,ui.VIEW_LEARN_SKILL)
	self.view_no_card = uikits.child(self._Bagview,ui.VIEW_NO_CARD)
	self.view_shi_list = uikits.child(self._Bagview,ui.VIEW_SHI_LIST)
	

	self.view_bag:setVisible(false)
	self.view_card_info:setVisible(false)
	self.view_shi_info:setVisible(false)
	self.view_card_exchange:setVisible(false)
	self.view_skill_info:setVisible(false)
	self.view_learn_skill:setVisible(false)
	self.view_no_card:setVisible(false)
	self.view_shi_list:setVisible(false)
		
	self:show_silver()
	self:show_le_coin()
	if self.card_id then
		self:show_card_info(self.card_id)
	else
		self:show_bag_view()
	end
end

function Bagview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Bagview = uikits.fromJson{file_9_16=ui.Bagview_FILE,file_3_4=ui.Bagview_FILE_3_4}
	self:addChild(self._Bagview)
	
	self.but_quit = uikits.child(self._Bagview,ui.BUTTON_QUIT)
	uikits.event(self.but_quit,	
		function(sender,eventType)	
			--sender.func(sender)
			self.but_quit.func(self,self.card_id)
			--uikits.popScene()
		end,"click")
		
	self:initgui()
--	self:getdatabyurl()
--	local loadbox = Bagviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Bagview:release()

end
return {
create = create,
}