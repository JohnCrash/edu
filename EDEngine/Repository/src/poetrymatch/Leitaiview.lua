local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"
local leitaiperrank = require "poetrymatch/Leitaiperrank"
local leitaischrank = require "poetrymatch/Leitaischrank"
local leitaihistory = require "poetrymatch/Leitaihistory"


local Leitaiview = class("Leitaiview")
Leitaiview.__index = Leitaiview
local ui = {
	Leitaiview_FILE = 'poetrymatch/leitai.json',
	Leitaiview_FILE_3_4 = 'poetrymatch/leitai.json',
	
	VIEW_NO = 'meiyou',
	VIEW_ALL = 'you',
	VIEW_LEI_CARD_SRC = 'lt1',
	TXT_LEI_TITLE = 'bt',
	TXT_LEI_LVL = 'kp2/dj',
	PIC_LEI = 'kp2',
	TXT_LEI_WEN = 'wen',
	TXT_LEI_WEN2 = 'wen2',
	TXT_LEI_RANK = 'pm',
	
	VIEW_PER_LEI = 'jr',
	VIEW_PER_LEI_INFO = 'lei',
	PIC_PER_LEI = 'lei/kp',
	TXT_PER_LEI_LVL = 'lei/kp/dj',
	TXT_PER_LEI_TITLE = 'lei/bt',
	TXT_PER_LEI_TIME = 'lei/shij',
	TXT_PER_LEI_USER_RANK = 'lei/wpm',
	TXT_PER_LEI_SCH_RANK = 'lei/xxpm',
	TXT_PER_LEI_SCORE = 'lei/wodefen',
	BUTTON_PER_LEI_USER = 'lei/geren',
	BUTTON_PER_LEI_SCH = 'lei/xuexiao',
	BUTTON_PER_LEI_BAT = 'lei/gl',
	TXT_PER_LEI_BAT_PAY = 'lei/bmf',
	TXT_PER_LEI_ALL_NUM = 'lei/bmr',
	TXT_PER_LEI_SCH_NUM = 'lei/bxr',
	VIEW_PER_LEI_REWARD = 'j1',
	TXT_PER_LEI_REWARD_NAME = 'wen3',
	TXT_PER_LEI_REWARD_NUM = 'm1',
	VIEW_PER_LEI_REWARD_SIL = 'jp1',
	VIEW_PER_LEI_REWARD_LE = 'jp2',
	VIEW_PER_LEI_REWARD_CARD = 'jp3',
	VIEW_PER_LEI_REWARD_GOODS = 'jp4',
	TXT_PER_LEI_REWARD_SIL_NUM = 'jp1/yinbi',
	TXT_PER_LEI_REWARD_LE_NUM = 'jp2/lebi',
	TXT_PER_LEI_REWARD_CARD_NAME = 'jp3/kapai',
	
	VIEW_BOSS_INFO = 'kpxinxi',
	TXT_BOSS_INFO_NAME = 'mz',
	PIC_BOSS_INFO_GOLD = 'jing',
	PIC_BOSS_INFO_SILVER = 'yin',
	PIC_BOSS_INFO_CU = 'tong',
	TXT_BOSS_INFO_SHENLI = 'shenli',
	TXT_BOSS_INFO_HP = 'xue',
	TXT_BOSS_INFO_HP_EX = 'jiax',
	TXT_BOSS_INFO_AP = 'gong',
	TXT_BOSS_INFO_AP_EX = 'jiag',
	TXT_BOSS_INFO_MP = 'zhili',
	TXT_BOSS_INFO_MP_EX = 'jiaz',
	BUTTON_BOSS_INFO_CLOSE = 'guan',
	VIEW_BOSS_INFO_CLASSMATE_1 = 'tx1',
	VIEW_BOSS_INFO_CLASSMATE_2 = 'tx2',
	VIEW_BOSS_INFO_CLASSMATE_3 = 'tx3',
	VIEW_BOSS_INFO_CLASSMATE_4 = 'tx4',
	VIEW_BOSS_INFO_CLASSMATE_5 = 'tx5',
	TXT_BOSS_INFO_CLASSMATE_NAME = 'xm',
	TXT_BOSS_INFO_CLASSMATE_CLASS = 'bj',	
	TXT_BOSS_INFO_CLASSMATE_SCORE = 'defen',
	PIC_BOSS_INFO_CLASSMATE = 'toux',

	BUTTON_QUIT = 'xinxi/fanhui',
	BUTTON_REVIEW = 'xinxi/wangqi',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Leitaiview)		
	
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

local scheduler = cc.Director:getInstance():getScheduler()
local schedulerEntry	

function Leitaiview:show_card_info()
	local txt_boss_name = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_NAME)
	local txt_boss_shenli = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_SHENLI)
	local txt_boss_hp = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_HP)
	local txt_boss_hp_ex = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_HP_EX)
	local txt_boss_ap = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_AP)
	local txt_boss_ap_ex = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_AP_EX)
	local txt_boss_mp = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_MP)
	local txt_boss_mp_ex = uikits.child(self.view_boss_info,ui.TXT_BOSS_INFO_MP_EX)
	local but_boss_close = uikits.child(self.view_boss_info,ui.BUTTON_BOSS_INFO_CLOSE) 
	local pic_card_info_gold = uikits.child(self.view_boss_info,ui.PIC_BOSS_INFO_GOLD)
	local pic_card_info_silver = uikits.child(self.view_boss_info,ui.PIC_BOSS_INFO_SILVER)
	local pic_card_info_cu = uikits.child(self.view_boss_info,ui.PIC_BOSS_INFO_CU) 	

	txt_boss_hp:setString(self.lei_info.card_plate_blood.basic_val)
	if self.lei_info.card_plate_blood.added_val and self.lei_info.card_plate_blood.added_val >0 then
		txt_boss_hp_ex:setString('+'..self.lei_info.card_plate_blood.added_val)	
	end
	txt_boss_ap:setString(self.lei_info.card_plate_attack.basic_val)
	if self.lei_info.card_plate_attack.added_val and self.lei_info.card_plate_attack.added_val >0 then
		txt_boss_ap_ex:setString('+'..self.lei_info.card_plate_attack.added_val)	
	end
	txt_boss_mp:setString(self.lei_info.card_plate_wit.basic_val)
	if self.lei_info.card_plate_wit.added_val and self.lei_info.card_plate_wit.added_val >0 then
		txt_boss_mp_ex:setString('+'..self.lei_info.card_plate_wit.added_val)	
	end
	
	txt_boss_name:setString(self.lei_info.card_plate_name)
	txt_boss_shenli:setString(self.lei_info.card_plate_magic)

	pic_card_info_gold:setVisible(false)
	pic_card_info_silver:setVisible(false)
	pic_card_info_cu:setVisible(false)
	if self.lei_info.card_material == 3 then
		pic_card_info_gold:setVisible(true)
	elseif self.lei_info.card_material == 2 then
		pic_card_info_silver:setVisible(true)
	elseif self.lei_info.card_material == 1 then
		pic_card_info_cu:setVisible(true)
	end	
	uikits.event(but_boss_close,	
		function(sender,eventType)	
			self.view_boss_info:setVisible(false)		
		end,"click")		
	local view_classmate1 = uikits.child(self.view_boss_info,ui.VIEW_BOSS_INFO_CLASSMATE_1) 
	local view_classmate2 = uikits.child(self.view_boss_info,ui.VIEW_BOSS_INFO_CLASSMATE_2) 
	local view_classmate3 = uikits.child(self.view_boss_info,ui.VIEW_BOSS_INFO_CLASSMATE_3) 
	local view_classmate4 = uikits.child(self.view_boss_info,ui.VIEW_BOSS_INFO_CLASSMATE_4) 
	local view_classmate5 = uikits.child(self.view_boss_info,ui.VIEW_BOSS_INFO_CLASSMATE_5) 	
	view_classmate1:setVisible(false)
	view_classmate2:setVisible(false)
	view_classmate3:setVisible(false)
	view_classmate4:setVisible(false)
	view_classmate5:setVisible(false)
			
	self.view_boss_info:setVisible(true)

	local function show_classmate(classmate_list)
		for i=1,#classmate_list do
			
		end
		if classmate_list[1] then
			local txt_classmate_name = uikits.child(view_classmate1,ui.TXT_BOSS_INFO_CLASSMATE_NAME) 
			local txt_classmate_class = uikits.child(view_classmate1,ui.TXT_BOSS_INFO_CLASSMATE_CLASS) 
			local txt_classmate_score = uikits.child(view_classmate1,ui.TXT_BOSS_INFO_CLASSMATE_SCORE) 
			local pic_classmate = uikits.child(view_classmate1,ui.PIC_BOSS_INFO_CLASSMATE) 
			txt_classmate_name:setString(classmate_list[1].uname)
			txt_classmate_class:setString(classmate_list[1].class_name)
			txt_classmate_score:setString(classmate_list[1].score)
			person_info.load_logo_pic(pic_classmate,classmate_list[1].user_id)
			view_classmate1:setVisible(true)
		end
		if classmate_list[2] then
			local txt_classmate_name = uikits.child(view_classmate2,ui.TXT_BOSS_INFO_CLASSMATE_NAME) 
			local txt_classmate_class = uikits.child(view_classmate2,ui.TXT_BOSS_INFO_CLASSMATE_CLASS) 
			local txt_classmate_score = uikits.child(view_classmate2,ui.TXT_BOSS_INFO_CLASSMATE_SCORE) 
			local pic_classmate = uikits.child(view_classmate2,ui.PIC_BOSS_INFO_CLASSMATE) 
			txt_classmate_name:setString(classmate_list[2].uname)
			txt_classmate_class:setString(classmate_list[2].class_name)
			txt_classmate_score:setString(classmate_list[2].score)
			person_info.load_logo_pic(pic_classmate,classmate_list[2].user_id)
			view_classmate2:setVisible(true)
		end 
		if classmate_list[3] then
			local txt_classmate_name = uikits.child(view_classmate3,ui.TXT_BOSS_INFO_CLASSMATE_NAME) 
			local txt_classmate_class = uikits.child(view_classmate3,ui.TXT_BOSS_INFO_CLASSMATE_CLASS) 
			local txt_classmate_score = uikits.child(view_classmate3,ui.TXT_BOSS_INFO_CLASSMATE_SCORE) 
			local pic_classmate = uikits.child(view_classmate3,ui.PIC_BOSS_INFO_CLASSMATE) 
			txt_classmate_name:setString(classmate_list[3].uname)
			txt_classmate_class:setString(classmate_list[3].class_name)
			txt_classmate_score:setString(classmate_list[3].score)
			person_info.load_logo_pic(pic_classmate,classmate_list[3].user_id)
			view_classmate3:setVisible(true)
		end 
		if classmate_list[4] then
			local txt_classmate_name = uikits.child(view_classmate4,ui.TXT_BOSS_INFO_CLASSMATE_NAME) 
			local txt_classmate_class = uikits.child(view_classmate4,ui.TXT_BOSS_INFO_CLASSMATE_CLASS) 
			local txt_classmate_score = uikits.child(view_classmate4,ui.TXT_BOSS_INFO_CLASSMATE_SCORE) 
			local pic_classmate = uikits.child(view_classmate4,ui.PIC_BOSS_INFO_CLASSMATE) 
			txt_classmate_name:setString(classmate_list[4].uname)
			txt_classmate_class:setString(classmate_list[4].class_name)
			txt_classmate_score:setString(classmate_list[4].score)
			person_info.load_logo_pic(pic_classmate,classmate_list[4].user_id)
			view_classmate4:setVisible(true)
		end 
		if classmate_list[5] then
			local txt_classmate_name = uikits.child(view_classmate5,ui.TXT_BOSS_INFO_CLASSMATE_NAME) 
			local txt_classmate_class = uikits.child(view_classmate5,ui.TXT_BOSS_INFO_CLASSMATE_CLASS) 
			local txt_classmate_score = uikits.child(view_classmate5,ui.TXT_BOSS_INFO_CLASSMATE_SCORE) 
			local pic_classmate = uikits.child(view_classmate5,ui.PIC_BOSS_INFO_CLASSMATE) 
			txt_classmate_name:setString(classmate_list[5].uname)
			txt_classmate_class:setString(classmate_list[5].class_name)
			txt_classmate_score:setString(classmate_list[5].score)
			person_info.load_logo_pic(pic_classmate,classmate_list[5].user_id)
			view_classmate5:setVisible(true)
		end 
	end	
	
	person_info.post_data_by_new_form(self._Leitaiview,'defense_most_students',send_data,function(t,v)
		if t and t == 200 then
			if v then
				show_classmate(v)
			end
		else
			person_info.messagebox(self._Leitaiview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Leitaiview:show_user_rank()
	local scene_next = leitaiperrank.create(self.lei_info.defense_name,self.lei_info.defense_id)
	uikits.pushScene(scene_next)
end

function Leitaiview:show_sch_rank()
	local scene_next = leitaischrank.create(self.lei_info.defense_name,self.lei_info.defense_id)
	uikits.pushScene(scene_next)
end

function Leitaiview:goto_battle()

end

function Leitaiview:show_lei_info()
	self:resetgui()
	self.temp_view = self.view_per_lei:clone()
	self.temp_view:setVisible(true)
	self._Leitaiview:addChild(self.temp_view,0,10000)

	local id
	local func
	local function timer_update(time)
		func(self)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	

	local pic_lei = uikits.child(self.temp_view,ui.PIC_PER_LEI)
	local txt_lvl = uikits.child(self.temp_view,ui.TXT_PER_LEI_LVL)
	local txt_title = uikits.child(self.temp_view,ui.TXT_PER_LEI_TITLE)
	local txt_time = uikits.child(self.temp_view,ui.TXT_PER_LEI_TIME)
	local txt_user_rank = uikits.child(self.temp_view,ui.TXT_PER_LEI_USER_RANK)
	local txt_sch_rank = uikits.child(self.temp_view,ui.TXT_PER_LEI_SCH_RANK)
	local txt_user_score = uikits.child(self.temp_view,ui.TXT_PER_LEI_SCORE)
	local txt_bat_pay = uikits.child(self.temp_view,ui.TXT_PER_LEI_BAT_PAY)
	local txt_all_num = uikits.child(self.temp_view,ui.TXT_PER_LEI_ALL_NUM)
	local txt_sch_num = uikits.child(self.temp_view,ui.TXT_PER_LEI_SCH_NUM)
	txt_lvl:setString(self.lei_info.card_plate_level)	
	txt_title:setString(self.lei_info.defense_name)	
	txt_time:setString(self.lei_info.time_remaining)	
	txt_user_rank:setString(self.lei_info.my_rank)	
	txt_sch_rank:setString(self.lei_info.sch_rank)	
	txt_user_score:setString(self.lei_info.my_score)	
	txt_bat_pay:setString(self.lei_info.consume_num)	
	txt_all_num:setString(self.lei_info.user_cnt)	
	txt_sch_num:setString(self.lei_info.my_sch_cnt)	
	local pic_name = self.lei_info.card_plate_id..'a.png'
	person_info.load_card_pic(pic_lei,pic_name,'')
	
	local but_user_rank = uikits.child(self.temp_view,ui.BUTTON_PER_LEI_USER)
	local but_sch_rank = uikits.child(self.temp_view,ui.BUTTON_PER_LEI_SCH)
	local but_battle = uikits.child(self.temp_view,ui.BUTTON_PER_LEI_BAT)
	
	uikits.event(pic_lei,	
	function(sender,eventType)	
		func = self.show_card_info
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)				
	end,"click")	
	uikits.event(but_user_rank,	
		function(sender,eventType)	
			func = self.show_user_rank
			schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)				
		end,"click")	
	uikits.event(but_sch_rank,	
		function(sender,eventType)	
			func = self.show_sch_rank
			schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)				
		end,"click")	
	uikits.event(but_battle,	
		function(sender,eventType)	
			func = self.goto_battle
			schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)				
		end,"click")	

	local reward_info = self.lei_info.prize_list
	local row_num = #reward_info
	local view_card_info = uikits.child(self.temp_view,ui.VIEW_PER_LEI_INFO)
	local pos_card_y = view_card_info:getPositionY()
	local view_reward_src = uikits.child(self.temp_view,ui.VIEW_PER_LEI_REWARD)
	view_reward_src:setVisible(false)
	local size_scroll = self.temp_view:getInnerContainerSize()
	local size_reward_src = view_reward_src:getContentSize()
	local pos_reward_src_y = view_reward_src:getPositionY()
	local size_view = self.temp_view:getContentSize()	
	local pos_reward_y_start = size_view.height - pos_reward_src_y	
	local pos_card_y_start = size_view.height - pos_card_y
	if size_scroll.height < (pos_reward_y_start + (row_num-1)*(size_reward_src.height)) then
		size_scroll.height = pos_reward_y_start + (row_num-1)*(size_reward_src.height)
		self.temp_view:setInnerContainerSize(size_scroll)
		view_card_info:setPositionY(size_scroll.height-pos_card_y_start)	
		pos_reward_y_start = size_scroll.height-pos_reward_y_start
	else
		pos_reward_y_start = pos_reward_src_y
	end	
	local reward_space = 20
	for i=1,#reward_info do
		local cur_reward = view_reward_src:clone()
		cur_reward:setVisible(true)
		self.temp_view:addChild(cur_reward)
		local pos_y =  pos_reward_y_start -(size_reward_src.height)*(i-1)
		cur_reward:setPositionY(pos_y)
		local txt_reward_name = uikits.child(cur_reward,ui.TXT_PER_LEI_REWARD_NAME)
		local txt_reward_num = uikits.child(cur_reward,ui.TXT_PER_LEI_REWARD_NUM)
		txt_reward_name:setString(reward_info[i].prize_order)	
		txt_reward_num:setString(reward_info[i].prize_count..'名')	
		
		local reward_silver = uikits.child(cur_reward,ui.VIEW_PER_LEI_REWARD_SIL)
		local reward_le = uikits.child(cur_reward,ui.VIEW_PER_LEI_REWARD_LE)
		local reward_card = uikits.child(cur_reward,ui.VIEW_PER_LEI_REWARD_CARD)
		local reward_goods = uikits.child(cur_reward,ui.VIEW_PER_LEI_REWARD_GOODS)
		local pos_x_start = reward_silver:getPositionX()
		local size_reward = reward_silver:getContentSize()
		reward_silver:setVisible(false)
		reward_le:setVisible(false)
		reward_card:setVisible(false)
		reward_goods:setVisible(false)
		local reward_list
		if reward_info[i].prize_order_list then
			reward_list = reward_info[i].prize_order_list
			for j=1,#reward_list do
				if reward_list[j].prize_type == 2 then
					reward_silver:setVisible(true)
					reward_silver:setPositionX(pos_x_start+(j-1)*(size_reward.width+reward_space))
					local txt_sil_num = uikits.child(cur_reward,ui.TXT_PER_LEI_REWARD_SIL_NUM)
					txt_sil_num:setString(reward_list[j].num)
				elseif reward_list[j].prize_type == 1 then
					reward_le:setVisible(true)
					reward_le:setPositionX(pos_x_start+(j-1)*(size_reward.width+reward_space))
					local txt_le_num = uikits.child(cur_reward,ui.TXT_PER_LEI_REWARD_LE_NUM)
					txt_le_num:setString(reward_list[j].num)
				elseif reward_list[j].prize_type == 3 then
					reward_card:setVisible(true)
					reward_card:setPositionX(pos_x_start+(j-1)*(size_reward.width+reward_space))
					local txt_card_name = uikits.child(cur_reward,ui.TXT_PER_LEI_REWARD_CARD_NAME)
					txt_card_name:setString(reward_list[j].name)
				elseif reward_list[j].prize_type == 99 then
				end
			end
		end

	end
	self.but_quit.func = self.getdatabyurl		
end

function Leitaiview:get_lei_info(lei_id)
	local send_data = {}
	send_data.v1 = lei_id
	person_info.post_data_by_new_form(self._Leitaiview,'load_defense_card_plate',send_data,function(t,v)
		if t and t == 200 then
			if v then
				self.lei_info = v[1]
				self:show_lei_info()
			end
		else
			person_info.messagebox(self._Leitaiview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end
	
function Leitaiview:show_leitai(leitai_info)
	local lei_space = 40
	self:resetgui()
	self.temp_view = self.view_all:clone()
	self.temp_view:setVisible(true)
	self._Leitaiview:addChild(self.temp_view,0,10000)
	
	local id
	local func
	local function timer_update(time)
		func(self,id)
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
	end	
		
	local lei_card_view_src = uikits.child(self.temp_view,ui.VIEW_LEI_CARD_SRC)
	lei_card_view_src:setVisible(false)
	local size_scroll = self.temp_view:getInnerContainerSize()
	local size_all_view = self.temp_view:getContentSize()
	local size_lei_src = lei_card_view_src:getContentSize()	
	local pos_x_src = lei_card_view_src:getPositionX()
	if pos_x_src+(#leitai_info-1)*(size_lei_src.width+lei_space) > size_scroll.width then
		size_scroll.width = pos_x_src+(#leitai_info-1)*(size_lei_src.width+lei_space)
		self.temp_view:setInnerContainerSize(size_scroll)
	end

	for i=1,#leitai_info do
		local cur_lei = lei_card_view_src:clone()
		cur_lei:setVisible(true)
		self.temp_view:addChild(cur_lei)
		local pos_x = pos_x_src +(i-1)*(size_lei_src.width+lei_space)
		cur_lei:setPositionX(pos_x)
		cur_lei.id = leitai_info[i].defense_id
		local txt_lei_title = uikits.child(cur_lei,ui.TXT_LEI_TITLE)
		local txt_lei_lvl = uikits.child(cur_lei,ui.TXT_LEI_LVL)
		local pic_lei = uikits.child(cur_lei,ui.PIC_LEI)
		local txt_lei_wen = uikits.child(cur_lei,ui.TXT_LEI_WEN)
		local txt_lei_wen2 = uikits.child(cur_lei,ui.TXT_LEI_WEN2)
		local txt_lei_rank = uikits.child(cur_lei,ui.TXT_LEI_RANK)
		txt_lei_title:setString(leitai_info[i].defense_name)
		txt_lei_lvl:setString(leitai_info[i].level)
		if leitai_info[i].user_rank then
			txt_lei_wen:setVisible(false)
			txt_lei_wen2:setVisible(true)
			txt_lei_rank:setVisible(true)		
			txt_lei_rank:setString(leitai_info[i].user_rank)	
		else
			txt_lei_wen:setVisible(true)
			txt_lei_wen2:setVisible(false)
			txt_lei_rank:setVisible(false)
		end
		local pic_name = leitai_info[i].card_plate_id..'a.png'
		person_info.load_card_pic(pic_lei,pic_name,'')
		uikits.event(cur_lei,	
			function(sender,eventType)	
				id = sender.id
				func = self.get_lei_info
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.01,false)				
			end,"click")		
	end
	
	self.but_quit.func = uikits.popScene
end

function Leitaiview:getdatabyurl()
	local send_data = {}
	send_data.v1 = '1'
	person_info.post_data_by_new_form(self._Leitaiview,'load_defense_possy',send_data,function(t,v)
		if t and t == 200 then
			if v then
				self.all_info = v
				self:show_leitai(v)
			else
				self.view_no:setVisible(true)
			end
		else
			person_info.messagebox(self._Leitaiview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Leitaiview:init_gui()
	self.view_no = uikits.child(self._Leitaiview,ui.VIEW_NO)
	self.view_all = uikits.child(self._Leitaiview,ui.VIEW_ALL)
	self.view_per_lei = uikits.child(self._Leitaiview,ui.VIEW_PER_LEI)
	self.view_boss_info = uikits.child(self._Leitaiview,ui.VIEW_BOSS_INFO)
	
	self.view_no:setVisible(false)
	self.view_all:setVisible(false)
	self.view_per_lei:setVisible(false)
	self.view_boss_info:setVisible(false)
	self.but_quit.func = uikits.popScene
end

function Leitaiview:resetgui()
	if self.temp_view then
		self._Leitaiview:removeChildByTag(10000)	
		self.temp_view = nil
	end
	cc.TextureCache:getInstance():removeUnusedTextures()
end	

function Leitaiview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	if self._Leitaiview then
		return
	end
	self._Leitaiview = uikits.fromJson{file_9_16=ui.Leitaiview_FILE,file_3_4=ui.Leitaiview_FILE_3_4}
	self:addChild(self._Leitaiview)
	
	self.but_quit = uikits.child(self._Leitaiview,ui.BUTTON_QUIT)
	uikits.event(self.but_quit,	
		function(sender,eventType)	
			self.but_quit.func(self)
		end,"click")
	local but_review = uikits.child(self._Leitaiview,ui.BUTTON_REVIEW)
	uikits.event(but_review,	
		function(sender,eventType)	
			local scene_next = leitaihistory.create()
			uikits.pushScene(scene_next)
		end,"click")
	self:init_gui()	
	self:getdatabyurl()
--	local loadbox = Leitaiviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Leitaiview:release()

end
return {
create = create,
}