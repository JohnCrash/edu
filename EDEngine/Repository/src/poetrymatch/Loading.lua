local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local Mainview = require "poetrymatch/Mainview"
local Guideview = require "poetrymatch/Guideview"
local person_info = require "poetrymatch/Person_info"

local Loading = class("Loading")
Loading.__index = Loading
local ui = {
	LOADING_FILE = 'poetrymatch/loading.json',
	LOADING_FILE_3_4 = 'poetrymatch/loading.json',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Loading)		
	
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

function Loading:update_skill_list()
	local send_data
	person_info.post_data_by_new_form('get_skills',send_data,function(t,v)
		if t and t == true then
			if v and v.list and type(v.list) == 'table' then
				person_info.set_skill_list(v.list)
			end
			if self.is_need_guide == true then
				local scene_next = Guideview.create()        
				cc.Director:getInstance():replaceScene(scene_next)  				
			else
				local scene_next = Mainview.create()        
				cc.Director:getInstance():replaceScene(scene_next)  
			end

		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:update_user_info()
				else
					self:update_user_info()
				end
			end)
		end
	end)
end

function Loading:update_card_info()
	local send_data
	person_info.post_data_by_new_form('load_user_card_plate',send_data,function(t,v)
		if t and t == true then
			local all_card_info = {}
			local all_battle_list = {}
			for i=1,#v do
				local cur_card_info = {}
				cur_card_info.id = v[i].card_plate_id
				cur_card_info.name = v[i].card_plate_name
				cur_card_info.in_battle_list = v[i].is_main_card_plate  
				cur_card_info.lvl = v[i].card_plate_level  
				cur_card_info.cur_exp = v[i].card_plate_exper_curr
				cur_card_info.max_exp = v[i].card_plate_exper_max
				cur_card_info.pinzhi = v[i].card_material
				cur_card_info.ap = v[i].card_plate_attack.basic_val
				cur_card_info.ap_ex = v[i].card_plate_attack.added_val
				cur_card_info.ap_ex_max = v[i].card_plate_attack.can_be_val
				cur_card_info.ap_pay = v[i].attack_coin.coin_val
				cur_card_info.mp = v[i].card_plate_magic.basic_val
				cur_card_info.mp_ex = v[i].card_plate_magic.added_val
				cur_card_info.mp_ex_max = v[i].card_plate_magic.can_be_val
				cur_card_info.mp_pay = v[i].magic_coin.coin_val
				cur_card_info.hp = v[i].card_plate_blood.basic_val
				cur_card_info.hp_ex = v[i].card_plate_blood.added_val
				cur_card_info.hp_ex_max = v[i].card_plate_blood.can_be_val
				cur_card_info.hp_pay = v[i].blood_coin.coin_val
				cur_card_info.sp = v[i].card_plate_wit.basic_val
				cur_card_info.sp_ex = v[i].card_plate_wit.added_val
				cur_card_info.sp_ex_max = v[i].card_plate_wit.can_be_val
				cur_card_info.sp_pay = v[i].wit_coin.coin_val
				cur_card_info.pp = v[i].card_plate_pomes.basic_val
				cur_card_info.pp_ex = v[i].card_plate_pomes.added_val
				cur_card_info.pp_ex_max = v[i].card_plate_pomes.can_be_val
				cur_card_info.pp_pay = v[i].pomes_coin.coin_val	
				cur_card_info.skill_reset_pay = v[i].relearn_coin.coin_val
				cur_card_info.skill_max = v[i].skill_max
				cur_card_info.skills = {}
				if v[i].skills then
					cur_card_info.skils = v[i].skills	
				end			
				if cur_card_info.in_battle_list == 1 then
					all_battle_list[#all_battle_list+1] = cur_card_info.id
				end
				all_card_info[#all_card_info+1] = cur_card_info
			end
			person_info.set_all_card_to_bag(all_card_info)
			for i=1,#all_battle_list do
				person_info.add_card_to_battle_by_index(all_battle_list[i],i)
			end
			person_info.set_all_card_to_bag(all_card_info)
 			self:update_skill_list()
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:update_user_info()
				else
					self:update_user_info()
				end
			end)			
		end
	end)
end

function Loading:update_user_info()
	local send_data
	person_info.post_data_by_new_form('load_user_info_wealth',send_data,function(t,v)
		if t and t == true then
			--local res = json.decode(v)
			local user_info = {}
			user_info.id = v.user_id
			user_info.name = v.user_name
			user_info.sex = v.sex
			user_info.school_name = v.province_name..v.city_name..v.area_name..v.sch_name
			user_info.has_msg = v.has_msg
			user_info.has_sign = v.has_sign
			user_info.has_product = v.new_product
			person_info.set_user_info(user_info)
			local lvl_info = {}
			lvl_info.lvl = v.level
			lvl_info.cur_exp = v.exper
			lvl_info.max_exp = v.max_exper
			person_info.set_user_lvl_info(lvl_info)
			person_info.set_user_le_coin(v.hcoin)
			person_info.set_user_silver(v.scoin)
			self:update_card_info()
			--[[local scene_next = Mainview.create()        
			cc.Director:getInstance():replaceScene(scene_next)   --]]
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:update_user_info()
				else
					self:update_user_info()
				end
			end)
		end
	end)
end

function Loading:getdatabyurl()
	local send_data
	person_info.post_data_by_new_form('login',send_data,function(t,v)
		if t and t == true then
			--local res = json.decode(v)
			if v.v1 == true then
				self.is_need_guide = false
			else
				self.is_need_guide = true
			end
			self:update_user_info()
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					uikits.popScene()
				else
					uikits.popScene()
				end
			end)
		end
	end)
end

function Loading:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._loading = uikits.fromJson{file_9_16=ui.LOADING_FILE,file_3_4=ui.LOADING_FILE_3_4}
	self:addChild(self._loading)

	self:getdatabyurl()
--	local loadbox = loadingbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Loading:release()

end
return {
create = create,
}