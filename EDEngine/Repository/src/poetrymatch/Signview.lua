local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Signview = class("Signview")
Signview.__index = Signview
local ui = {
	Signview_FILE = 'poetrymatch/qiandao.json',
	Signview_FILE_3_4 = 'poetrymatch/qiandao.json',
	TXT_SIGN_DAYS = 'ts',
	TXT_SIGN_RANK = 'pm',
	TXT_SILVER_NUM = 'hd2/yinbi',
	TXT_LE_NUM = 'hd1/lebi',
	PIC_USER_MAN = 'xingbie2',
	PIC_USER_WOMAN = 'xingbie',
	BUTTON_SIGN = 'lingqu',
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Signview)		
	
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

function Signview:sign()
	local send_data
	person_info.post_data_by_new_form(self._Signview,'sign_submit',send_data,function(t,v)
		if t and t == 200 then
			if v.scoin then
				person_info.add_user_silver(v.scoin)
			end
			if v.hcoin then
				person_info.add_user_le_coin(v.scoin)
			end
			local user_info = person_info.get_user_info()
			if user_info.has_sign == 1 then
				user_info.has_sign = 0 
				person_info.set_user_info(user_info)
			end
			uikits.popScene()
		else
			person_info.messagebox(self._Signview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
				end
			end)
		end
	end)
end

function Signview:show_info(sign_info)
	local txt_days = uikits.child(self._Signview,ui.TXT_SIGN_DAYS)
	local txt_rank = uikits.child(self._Signview,ui.TXT_SIGN_RANK)
	local txt_silver_num = uikits.child(self._Signview,ui.TXT_SILVER_NUM)
	local txt_le_num = uikits.child(self._Signview,ui.TXT_LE_NUM)
	txt_days:setString(sign_info.days)
	txt_rank:setString(sign_info.rank)
	txt_silver_num:setString(sign_info.scoin)
	txt_le_num:setString(sign_info.hcoin)
	local but_sign = uikits.child(self._Signview,ui.BUTTON_SIGN)
	if sign_info.can_sign == 0 then
		but_sign:setEnabled(false)
		but_sign:setBright(false)
		but_sign:setTouchEnabled(false)
	else
		but_sign:setEnabled(true)
		but_sign:setBright(true)
		but_sign:setTouchEnabled(true)	
	end
	
	uikits.event(but_sign,	
		function(sender,eventType)	
			self:sign()
		end,"click")	
		
end

function Signview:getdatabyurl()
	local send_data
	person_info.post_data_by_new_form(self._Signview,'sign_detail',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				self:show_info(v)
			end
		else
			person_info.messagebox(self._Signview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Signview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Signview = uikits.fromJson{file_9_16=ui.Signview_FILE,file_3_4=ui.Signview_FILE_3_4}
	self:addChild(self._Signview)
	self:getdatabyurl()

	local pic_user_woman = uikits.child(self._Signview,ui.PIC_USER_WOMAN)
	local pic_user_man = uikits.child(self._Signview,ui.PIC_USER_MAN)
	self.user_info = person_info.get_user_info()
	if self.user_info.sex == 1 then
		pic_user_man:setVisible(true)
		pic_user_woman:setVisible(false)
	else
		pic_user_man:setVisible(false)
		pic_user_woman:setVisible(true)	
	end	
	local but_quit = uikits.child(self._Signview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function Signview:release()

end
return {
create = create,
}