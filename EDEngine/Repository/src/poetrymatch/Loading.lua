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

function Loading:update_card_info()
	local send_data
	person_info.post_data_by_new_form('load_user_card_plate',send_data,function(t,v)
		if t and t == true then
			
			
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