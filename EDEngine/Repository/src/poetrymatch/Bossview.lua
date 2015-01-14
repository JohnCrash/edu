local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"
local readytoboss = require "poetrymatch/Readytoboss"


local Bossview = class("Bossview")
Bossview.__index = Bossview
local ui = {
	Bossview_FILE = 'poetrymatch/gk.json',
	Bossview_FILE_3_4 = 'poetrymatch/gk.json',
	
	VIEW_ALL_BOSS = 'kapai',
	VIEW_PER_BOSS = 'kapai/kp1',
	TXT_BOSS_LVL = 'dengji',
	CHECK_STAR1 = 'xx1',
	CHECK_STAR2 = 'xx2',
	CHECK_STAR3 = 'xx3',
	PIC_BG = 'ditu',
	
	VIEW_BOSS_INFO = 'tan',
	BUTTON_START_BATTLE = 'tan/ok',
	BUTTON_HIDE_INFO = 'tan/no',	
	TXT_TILI_NUM = 'tan/tili',
	TXT_BOSS_NAME = 'tan/mz',
	PIC_PINZHI_GOLD = 'tan/jing',
	PIC_PINZHI_CU = 'tan/tong',
	PIC_PINZHI_SILVER = 'tan/yin',
	TXT_SHENLI_NUM = 'tan/shenli',
	TXT_HP_NUM = 'tan/xue',
	TXT_HP_EX_NUM = 'tan/jiax',
	TXT_AP_NUM = 'tan/gong',
	TXT_AP_EX_NUM = 'tan/jiag',
	TXT_MP_NUM = 'tan/zhili',
	TXT_MP_EX_NUM = 'tan/jiaz',
	TXT_STAR1_CONDITION = 'tan/x1/wen1',
	TXT_STAR2_CONDITION = 'tan/x2/wen1',
	TXT_STAR3_CONDITION = 'tan/x3/wen1',
	
	TXT_COUNTRY_NAME = 'xinxi/wen',
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(country_name,country_id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Bossview)		
	cur_layer.country_name = country_name
	cur_layer.country_id = country_id
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
local boss_info = {}
function Bossview:update_user_boss_info()
	local send_data = {}
	send_data.v1 = self.country_id
	person_info.post_data_by_new_form(self._Bossview,'load_user_attack_road_block_cardplate',send_data,function(t,v)
		if t and t == 200 then
			
--[[			for i=1,#v do
				local cur_section_info = {}
				--cur_section_info.id = v[i].road_block_id
				cur_section_info.id = 'fengyang'
				cur_section_info.name = v[i].road_block_name
				cur_section_info.star_all = 0
				if v[i].road_block_tot_star then
					cur_section_info.star_all = v[i].road_block_tot_star
				end
				cur_section_info.des = v[i].road_block_des
				section_info[#section_info+1] = cur_section_info
			end
			self:get_user_section_info()--]]
			if v then
				boss_info = v				
			end
			self:show_boss()
		else
			person_info.messagebox(self._Bossview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end		
	end)
end

function Bossview:getdatabyurl()
	local cache_data_boss_info = person_info.get_boss_info_by_id(self.country_id)
	if cache_data_boss_info then
		self:update_user_boss_info()
	else
		local file_data_boss_info = kits.read_local_file('poetrymatch/B'..self.country_id..'.json')
		if file_data_boss_info then
			local tb_file_data_boss_info = json.decode(file_data_boss_info)
			
			person_info.set_boss_info_by_id(self.country_id,tb_file_data_boss_info)	
			self:update_user_boss_info()
		else
			local send_data = {}
			send_data.v1 = self.country_id
			person_info.post_data_by_new_form(self._Bossview,'load_road_block_guard_card',send_data,function(t,v)
				if t and t == 200 then
					if v then
						local tb_file_data_boss_info = v
						local file_data_boss_info = json.encode(tb_file_data_boss_info)
						kits.write_local_file('poetrymatch/B'..self.country_id..'.json',file_data_boss_info)
						person_info.set_boss_info_by_id(self.country_id,v)				
					end
					self:update_user_boss_info()
				else
					person_info.messagebox(self._Bossview,person_info.NETWORK_ERROR,function(e)
						if e == person_info.OK then

						end
					end)
				end		
			end)			
		end
	end
end

function Bossview:save_innerpos()
	self.inner_posx,self.inner_posy = self.view_all_boss:getInnerContainer():getPosition()
end

function Bossview:set_innerpos()
	self.view_all_boss:getInnerContainer():setPosition(cc.p(self.inner_posx,self.inner_posy))
end

local boss_space = 50

function Bossview:show_boss_info(cur_boss_info,is_has_star)	
	self.view_boss_info:setVisible(true)
	local but_start_battle = uikits.child(self._Bossview,ui.BUTTON_START_BATTLE)
	local but_hide_info = uikits.child(self._Bossview,ui.BUTTON_HIDE_INFO)
	uikits.event(but_start_battle,	
	function(sender,eventType)	
	
--[[		local save_info = kits.config("tili_time",'get')
		local save_info_tb = json.decode(save_info)
		if save_info_tb.last_tili_num < cur_boss_info.need_physical_power then
			print('tili not enough!!!!')
		else
			save_info_tb.last_tili_num = save_info_tb.last_tili_num - cur_boss_info.need_physical_power
			save_info = json.encode(save_info_tb)
			kits.config("tili_time",save_info)
		end--]]

		local tili_num = person_info.get_user_tili()
		if tili_num < cur_boss_info.need_physical_power then
				person_info.messagebox(self._Bossview,person_info.NO_TILI,function(e)
					if e == person_info.OK then
						
					else
						
					end
				end)					
		else
			tili_num = tili_num - cur_boss_info.need_physical_power
			person_info.set_user_tili(tili_num)
			local send_data = {}
			send_data.v2 = cur_boss_info.card_plate_id
			send_data.v1 = self.country_id
			person_info.post_data_by_new_form(self._Bossview,'road_block_guard_card_physical_change',send_data,function(t,v)
				if t and t == 200 then
					self.view_boss_info:setVisible(false)
					self:save_innerpos()
					local scene_next = readytoboss.create(cur_boss_info,is_has_star,self.country_id,self.country_name)	
					uikits.replaceScene(scene_next)		
				else
					person_info.messagebox(self._Bossview,person_info.NETWORK_ERROR,function(e)
						if e == person_info.OK then
							
						else
							
						end
					end)				
				end
			end)		
		end
	end,"click")
	
	uikits.event(but_hide_info,	
	function(sender,eventType)	
		self.view_boss_info:setVisible(false)
	end,"click")
	print('cur_boss_info.need_physical_power::'..cur_boss_info.need_physical_power)
	local txt_tili_num = uikits.child(self._Bossview,ui.TXT_TILI_NUM)
	txt_tili_num:setString(cur_boss_info.need_physical_power)
	local txt_boss_name = uikits.child(self._Bossview,ui.TXT_BOSS_NAME)
	txt_boss_name:setString(cur_boss_info.card_plate_name)
	local pic_pz_gold = uikits.child(self._Bossview,ui.PIC_PINZHI_GOLD)
	local pic_pz_silver = uikits.child(self._Bossview,ui.PIC_PINZHI_SILVER)
	local pic_pz_cu = uikits.child(self._Bossview,ui.PIC_PINZHI_CU)
	pic_pz_gold:setVisible(false)
	pic_pz_silver:setVisible(false)
	pic_pz_cu:setVisible(false)
	if cur_boss_info.card_material == 3 then
		pic_pz_gold:setVisible(true)
	elseif cur_boss_info.card_material == 2 then
		pic_pz_silver:setVisible(true)
	elseif cur_boss_info.card_material == 1 then
		pic_pz_cu:setVisible(true)
	end
	local txt_shenli_num = uikits.child(self._Bossview,ui.TXT_SHENLI_NUM)
	txt_shenli_num:setString(cur_boss_info.card_plate_magic)

	local txt_hp_num = uikits.child(self._Bossview,ui.TXT_HP_NUM)
	txt_hp_num:setString(cur_boss_info.card_plate_blood)
	local txt_hp_ex_num = uikits.child(self._Bossview,ui.TXT_HP_EX_NUM)
	if cur_boss_info.card_plate_blood_added and cur_boss_info.card_plate_blood_added ~= 0 then
		txt_hp_ex_num:setString('+'..cur_boss_info.card_plate_blood_added)
		txt_hp_ex_num:setVisible(true)	
	else
		txt_hp_ex_num:setVisible(false)		
	end
	
	local txt_ap_num = uikits.child(self._Bossview,ui.TXT_AP_NUM)
	txt_ap_num:setString(cur_boss_info.card_plate_attack)
	local txt_ap_ex_num = uikits.child(self._Bossview,ui.TXT_AP_EX_NUM)
	if cur_boss_info.card_plate_attack_added and cur_boss_info.card_plate_attack_added ~= 0 then
		txt_ap_ex_num:setString('+'..cur_boss_info.card_plate_attack_added)
		txt_ap_ex_num:setVisible(true)	
	else
		txt_ap_ex_num:setVisible(false)		
	end
	
	local txt_mp_num = uikits.child(self._Bossview,ui.TXT_MP_NUM)
	txt_mp_num:setString(cur_boss_info.card_plate_wit)
	local txt_mp_ex_num = uikits.child(self._Bossview,ui.TXT_MP_EX_NUM)
	if cur_boss_info.card_plate_wit_added and cur_boss_info.card_plate_wit_added ~= 0 then
		txt_mp_ex_num:setString('+'..cur_boss_info.card_plate_wit_added)
		txt_mp_ex_num:setVisible(true)	
	else
		txt_mp_ex_num:setVisible(false)		
	end

	local txt_star1_condition = uikits.child(self._Bossview,ui.TXT_STAR1_CONDITION)
	local txt_star2_condition = uikits.child(self._Bossview,ui.TXT_STAR2_CONDITION)
	local txt_star3_condition = uikits.child(self._Bossview,ui.TXT_STAR3_CONDITION)
	txt_star1_condition:setString(cur_boss_info.star1_desc)
	txt_star2_condition:setString(cur_boss_info.star2_desc)
	txt_star3_condition:setString(cur_boss_info.star3_desc)
end

function Bossview:show_boss()	
	local all_boss_info = person_info.get_boss_info_by_id(self.country_id)
	local view_per_boss_src = uikits.child(self._Bossview,ui.VIEW_PER_BOSS)
	local size_all_view = self.view_all_boss:getContentSize()
	local size_per_view = view_per_boss_src:getContentSize()
	local size_scroll = self.view_all_boss:getInnerContainerSize()
	local pos_x = view_per_boss_src:getPositionX()

	local pos_x_src = pos_x+(size_per_view.width+boss_space)*(#all_boss_info)-size_per_view.width/2
	print('pos_x_src::'..pos_x_src..'::size_all_view.width::'..size_all_view.width)
	if pos_x_src > size_all_view.width then
		size_scroll.width = pos_x_src
	else
		size_scroll.width = size_all_view.width
	end
	print('size_scroll.width::'..size_scroll.width)
	self.view_all_boss:setInnerContainerSize(size_scroll)
	
	view_per_boss_src:setVisible(false)
	for i=1,#all_boss_info do
		local cur_boss = view_per_boss_src:clone()
		cur_boss:setVisible(true)
		self.view_all_boss:addChild(cur_boss)
		cur_boss.card_info = all_boss_info[i]
		cur_boss:setPositionX(pos_x+(size_per_view.width+boss_space)*(i-1))
		uikits.event(cur_boss,	
		function(sender,eventType)	
			self:show_boss_info(sender.card_info,sender.is_has_star)
		end,"click")
		local n_pic_name = all_boss_info[i].card_plate_id..'a.png'
		local c_pic_name = all_boss_info[i].card_plate_id..'d.png'
--[[		local n_pic_name = all_boss_info[i].card_plate_id..'.png'
		local c_pic_name = all_boss_info[i].card_plate_id..'4.png'--]]
		person_info.load_card_pic(cur_boss,n_pic_name,'',c_pic_name)
		local star1 = uikits.child(cur_boss,ui.CHECK_STAR1)
		local star2 = uikits.child(cur_boss,ui.CHECK_STAR2)
		local star3 = uikits.child(cur_boss,ui.CHECK_STAR3)
		star1:setSelectedState(false)
		star2:setSelectedState(false)
		star3:setSelectedState(false)
		if boss_info[i] and type(boss_info[i]) == 'table' then
			cur_boss:setEnabled(true)
			cur_boss:setBright(true)
			cur_boss:setTouchEnabled(true)	
			if boss_info[i].tot_gain_star >0 then
				star1:setSelectedState(true)
				if boss_info[i].tot_gain_star >1 then
					star2:setSelectedState(true)
					if boss_info[i].tot_gain_star >2 then
						star3:setSelectedState(true)
					end
				end
				cur_boss.is_has_star = true
			else
				cur_boss.is_has_star = false
			end
		else
			cur_boss.is_has_star = false
			cur_boss:setEnabled(false)
			cur_boss:setBright(false)
			cur_boss:setTouchEnabled(false)	
		end

		local txt_boss_lvl = uikits.child(cur_boss,ui.TXT_BOSS_LVL)
		txt_boss_lvl:setString(all_boss_info[i].card_plate_level)
	end
end

function Bossview:init_gui()	
	--self:show_boss()
	self:getdatabyurl()
end

function Bossview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Bossview = uikits.fromJson{file_9_16=ui.Bossview_FILE,file_3_4=ui.Bossview_FILE_3_4}
	self:addChild(self._Bossview)
	self.view_boss_info = uikits.child(self._Bossview,ui.VIEW_BOSS_INFO)
	self.view_boss_info:setVisible(false)
	
	local txt_country_name = uikits.child(self._Bossview,ui.TXT_COUNTRY_NAME)
	txt_country_name:setString(self.country_name)
	self.view_all_boss = uikits.child(self._Bossview,ui.VIEW_ALL_BOSS)

	local but_quit = uikits.child(self._Bossview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
	local pic_bg = uikits.child(self._Bossview,ui.PIC_BG)
	local pic_name = self.country_id..'a.png'
	person_info.load_section_pic(pic_bg,pic_name)
	
	self:init_gui()
end

function Bossview:release()

end
return {
create = create,
}