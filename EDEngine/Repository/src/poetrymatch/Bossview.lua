local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

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
	CHECK_STAR3 = 'xx2',
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

function Bossview:getdatabyurl()

	cache.request_json( get_uesr_info_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				if t.uig[1].user_role == 1 then	--xuesheng
					login.set_uid_type(login.STUDENT)
					local scene_next = errortitleview.create(t.uig[1].uname)		
					--uikits.pushScene(scene_next)						
					cc.Director:getInstance():replaceScene(scene_next)	
				elseif t.uig[1].user_role == 2 then	--jiazhang
					login.set_uid_type(login.PARENT)
					self:getdatabyparent()
				elseif t.uig[1].user_role == 3 then	--laoshi
					login.set_uid_type(login.TEACHER)
					self:showteacherview()		
				end
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:init()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')
end

local boss_space = 50

function Bossview:show_boss_info(cur_boss_info)	
	self.view_boss_info:setVisible(true)
	local but_start_battle = uikits.child(self._Bossview,ui.BUTTON_START_BATTLE)
	local but_hide_info = uikits.child(self._Bossview,ui.BUTTON_HIDE_INFO)
	uikits.event(but_start_battle,	
	function(sender,eventType)	
	
		local save_info = kits.config("tili_time",'get')
		local save_info_tb = json.decode(save_info)
		if save_info_tb.last_tili_num < cur_boss_info.tili then
			print('tili not enough!!!!')
		else
			save_info_tb.last_tili_num = save_info_tb.last_tili_num - cur_boss_info.tili
			save_info = json.encode(save_info_tb)
			kits.config("tili_time",save_info)
		end
		
		self.view_boss_info:setVisible(false)
	end,"click")
	
	uikits.event(but_hide_info,	
	function(sender,eventType)	
		self.view_boss_info:setVisible(false)
	end,"click")
	
	local txt_tili_num = uikits.child(self._Bossview,ui.TXT_TILI_NUM)
	txt_tili_num:setString(cur_boss_info.tili)
	local txt_boss_name = uikits.child(self._Bossview,ui.TXT_BOSS_NAME)
	txt_boss_name:setString(cur_boss_info.name)
	local pic_pz_gold = uikits.child(self._Bossview,ui.PIC_PINZHI_GOLD)
	local pic_pz_silver = uikits.child(self._Bossview,ui.PIC_PINZHI_SILVER)
	local pic_pz_cu = uikits.child(self._Bossview,ui.PIC_PINZHI_CU)
	pic_pz_gold:setVisible(false)
	pic_pz_silver:setVisible(false)
	pic_pz_cu:setVisible(false)
	if cur_boss_info.pinzhi == 3 then
		pic_pz_gold:setVisible(true)
	elseif cur_boss_info.pinzhi == 2 then
		pic_pz_silver:setVisible(true)
	elseif cur_boss_info.pinzhi == 1 then
		pic_pz_cu:setVisible(true)
	end
	local txt_shenli_num = uikits.child(self._Bossview,ui.TXT_SHENLI_NUM)
	txt_shenli_num:setString(cur_boss_info.shenli)

	local txt_hp_num = uikits.child(self._Bossview,ui.TXT_HP_NUM)
	txt_hp_num:setString(cur_boss_info.hp)
	local txt_hp_ex_num = uikits.child(self._Bossview,ui.TXT_HP_EX_NUM)
	if cur_boss_info.hp_ex ~= 0 then
		txt_hp_ex_num:setString('+'..cur_boss_info.hp_ex)
		txt_hp_ex_num:setVisible(true)	
	else
		txt_hp_ex_num:setVisible(false)		
	end
	
	local txt_ap_num = uikits.child(self._Bossview,ui.TXT_AP_NUM)
	txt_ap_num:setString(cur_boss_info.ap)
	local txt_ap_ex_num = uikits.child(self._Bossview,ui.TXT_AP_EX_NUM)
	if cur_boss_info.ap_ex ~= 0 then
		txt_ap_ex_num:setString('+'..cur_boss_info.ap_ex)
		txt_ap_ex_num:setVisible(true)	
	else
		txt_ap_ex_num:setVisible(false)		
	end
	
	local txt_mp_num = uikits.child(self._Bossview,ui.TXT_MP_NUM)
	txt_mp_num:setString(cur_boss_info.mp)
	local txt_mp_ex_num = uikits.child(self._Bossview,ui.TXT_MP_EX_NUM)
	if cur_boss_info.mp_ex ~= 0 then
		txt_mp_ex_num:setString('+'..cur_boss_info.mp_ex)
		txt_mp_ex_num:setVisible(true)	
	else
		txt_mp_ex_num:setVisible(false)		
	end

	local txt_star1_condition = uikits.child(self._Bossview,ui.TXT_STAR1_CONDITION)
	local txt_star2_condition = uikits.child(self._Bossview,ui.TXT_STAR2_CONDITION)
	local txt_star3_condition = uikits.child(self._Bossview,ui.TXT_STAR3_CONDITION)
	txt_star1_condition:setString(cur_boss_info.star1)
	txt_star2_condition:setString(cur_boss_info.star2)
	txt_star3_condition:setString(cur_boss_info.star3)
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
		cur_boss.boos_info = all_boss_info[i]
		cur_boss:setPositionX(pos_x+(size_per_view.width+boss_space)*(i-1))
		uikits.event(cur_boss,	
		function(sender,eventType)	
			self:show_boss_info(sender.boos_info)
		end,"click")

		local n_pic_name = all_boss_info[i].id..'.png'
		local c_pic_name = all_boss_info[i].id..'4.png'
		person_info.load_card_pic(cur_boss,n_pic_name,n_pic_name,c_pic_name)
		if all_boss_info[i].is_admit == 1 then
			cur_boss:setEnabled(true)
			cur_boss:setBright(true)
			cur_boss:setTouchEnabled(true)	
		else
			cur_boss:setEnabled(false)
			cur_boss:setBright(false)
			cur_boss:setTouchEnabled(false)	
		end

		local star1 = uikits.child(cur_boss,ui.CHECK_STAR1)
		local star2 = uikits.child(cur_boss,ui.CHECK_STAR2)
		local star3 = uikits.child(cur_boss,ui.CHECK_STAR3)
		star1:setSelectedState(false)
		star2:setSelectedState(false)
		star3:setSelectedState(false)
		if all_boss_info[i].star_has >0 then
			star1:setSelectedState(true)
			if all_boss_info[i].star_has >1 then
				star2:setSelectedState(true)
				if all_boss_info[i].star_has >2 then
					star3:setSelectedState(true)
				end
			end
		end
		
		local txt_boss_lvl = uikits.child(cur_boss,ui.TXT_BOSS_LVL)
		txt_boss_lvl:setString(all_boss_info[i].lvl)
	end
end

function Bossview:init_gui()	
	self:show_boss()
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
	local pic_name = self.country_id..'_bg.jpg'
	person_info.load_section_pic(pic_bg,pic_name)
	
	self:init_gui()
end

function Bossview:release()

end
return {
create = create,
}