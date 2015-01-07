local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Battlereward = class("Battlereward")
Battlereward.__index = Battlereward
local ui = {
	Battlereward_FILE = 'poetrymatch/jiebangjl.json',
	Battlereward_FILE_3_4 = 'poetrymatch/jiebangjl.json',
	REWARD_PERSON = 'gun/w3',
	REWARD_SCHOOL = 'gun/w5',
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Battlereward)		
	
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

function Battlereward:sign()
	local send_data
	person_info.post_data_by_new_form(self._Battlereward,'sign_submit',send_data,function(t,v)
		if t and t == 200 then
			uikits.popScene()
		else
			person_info.messagebox(self._Battlereward,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Battlereward:show_info(reward_info)
	local txt_reward_person = uikits.child(self._Battlereward,ui.REWARD_PERSON)
	local txt_reward_school = uikits.child(self._Battlereward,ui.REWARD_SCHOOL)
	for i=1,#reward_info do
		if reward_info[i].act_id == 2 then
			txt_reward_person:setString(reward_info[i].prize_rules)
		elseif reward_info[i].act_id == 3 then 
			txt_reward_school:setString(reward_info[i].prize_rules)
		end 
	end
	
end

function Battlereward:getdatabyurl()
	local send_data = {}
	send_data.v1 = {'2','3'}
	
	person_info.post_data_by_new_form(self._Battlereward,'get_prize_rule',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				self:show_info(v)
			end
		else
			person_info.messagebox(self._Battlereward,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Battlereward:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Battlereward = uikits.fromJson{file_9_16=ui.Battlereward_FILE,file_3_4=ui.Battlereward_FILE_3_4}
	self:addChild(self._Battlereward)
	self:getdatabyurl()

	local but_quit = uikits.child(self._Battlereward,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function Battlereward:release()

end
return {
create = create,
}