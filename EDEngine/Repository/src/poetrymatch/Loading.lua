local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local Mainview = require "poetrymatch/Mainview"
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
--[[{id='caoz',name='caoz',lvl=5,cur_exp=10,max_exp=100,in_battle_list = 1,}
{"user_id":149527,"card_plate_id":1,"card_material":1,"card_plate_name":"дам╞","is_main_card_plate":1,
"card_plate_level":1,"card_plate_exper_curr":0,"card_plate_exper_max":50,"card_plate_exper":0,"card_plate_attack":7,
"card_plate_magic":0,"card_plate_wit":8,"card_plate_pomes":3,"card_plate_blood":0,"description":"433",
"attack_max":8,"blood_max":99,"magic_max":0,"wit_max":9,"pomes_max":3,"skill_max":3,"attack_coin":[2,10],
"blood_coin":[2,10],"magic_coin":[1,10],"wit_coin":[2,10],"pomes_coin":[2,10],"relearn_coin":[2,10000]}--]]
function Loading:update_card_info()
	local send_data
	person_info.post_data_by_new_form('load_user_card_plate',send_data,function(t,v)
		if t and t == true then
			local all_card_info = {}
			for i=1,#v do
				local cur_card_info = {}
				cur_card_info.id = v[i].card_plate_id
				cur_card_info.name = v[i].card_plate_name
				cur_card_info.in_battle_list = v[i].is_main_card_plate  
				cur_card_info.lvl = v[i].card_plate_level  
				cur_card_info.cur_exp = v[i].card_plate_exper_curr
				cur_card_info.max_exp = v[i].card_plate_exper_max
				cur_card_info.pinzhi = v[i].card_material
				cur_card_info.ap = v[i].card_plate_attack
				cur_card_info.ap_ex = v[i].attack_max
				cur_card_info.ap_pay = v[i].attack_coin[2]
				cur_card_info.mp = v[i].card_plate_magic
				cur_card_info.mp_ex = v[i].magic_max
				cur_card_info.mp_pay = v[i].magic_coin[2]
				cur_card_info.hp = v[i].card_plate_blood
				cur_card_info.hp_ex = v[i].blood_max
				cur_card_info.hp_pay = v[i].blood_coin[2]
				cur_card_info.sp = v[i].card_plate_wit
				cur_card_info.sp_ex = v[i].wit_max
				cur_card_info.sp_pay = v[i].wit_coin[2]
				cur_card_info.pp = v[i].card_plate_pomes
				cur_card_info.pp_ex = v[i].pomes_max
				cur_card_info.pp_pay = v[i].pomes_coin[2]	
				cur_card_info.skill_max = v[i].skill_max
				cur_card_info.skills = {}
				if v[i].skills then
					cur_card_info.skils = v[i].skills	
				end			
				all_card_info[#all_card_info+1] = cur_card_info
			end
			person_info.set_all_card_to_bag(all_card_info)
			local scene_next = Mainview.create()        
			cc.Director:getInstance():replaceScene(scene_next)   			
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
				self:update_user_info()
			else
				local scene_next = Mainview.create()        
				cc.Director:getInstance():replaceScene(scene_next)   
			end
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