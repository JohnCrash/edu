local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Readytoboss = class("Readytoboss")
Readytoboss.__index = Readytoboss
local ui = {
	Readytoboss_FILE = 'poetrymatch/gushi.json',
	Readytoboss_FILE_3_4 = 'poetrymatch/gushi.json',
	
	VIEW_GUSHI = 'gushi',
	VIEW_USER = 'gushi/wo',
	TXT_USER_NAME = 'gushi/wo/duihua/mz',
	TXT_USER_CONTENT = 'gushi/wo/duihua/dh',
	BUTTON_USER_NEXT = 'gushi/wo/xyt',
	PIC_USER_MAN = 'gushi/wo/nan',
	PIC_USER_WOMAN = 'gushi/wo/nv',
	
	VIEW_BOT = 'gushi/duifang',
	TXT_BOT_NAME = 'gushi/duifang/duihua/mz',
	TXT_BOT_CONTENT = 'gushi/duifang/duihua/dh',
	BUTTON_BOT_NEXT = 'gushi/duifang/xyt',
	PIC_BOT = 'gushi/duifang/k2',
	
	VIEW_ZHUNBEI = 'zhunbei',	
	PIC_USER_ZHUNBEI_WOMAN = 'zhunbei/vs/toux',
	PIC_USER_ZHUNBEI_MAN = 'zhunbei/vs/toux2',
	TXT_USER_WOMAN_LVL = 'zhunbei/vs/toux/jibie',
	PIC_USER_MAN_LVL = 'zhunbei/vs/toux2/jibie',
	TXT_USER_NAME_ZHUNBEI = 'zhunbei/vs/womz',
	PIC_BOT_ZHUNBEI = 'zhunbei/vs/duifang',
	TXT_BOT_LVL = 'zhunbei/vs/duifang/jiebie',
	TXT_BOT_NAME_ZHUNBEI = 'zhunbei/vs/dfmz',
	
	TXT_TIME = 'zhunbei/dhjs/5s',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(bot_info,is_has_star,country_id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Readytoboss)		
	cur_layer.bot_info = bot_info
	cur_layer.is_has_star = is_has_star
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

function Readytoboss:show_gushi()	
	local view_user = uikits.child(self._Readytoboss,ui.VIEW_USER)
	local view_bot = uikits.child(self._Readytoboss,ui.VIEW_BOT)
	local txt_user_name = uikits.child(self._Readytoboss,ui.TXT_USER_NAME)
	local txt_bot_name = uikits.child(self._Readytoboss,ui.TXT_BOT_NAME)
	txt_user_name:setString(self.user_info.name)
	--txt_bot_name:setString(self.bot_info.name)
	local txt_user_content = uikits.child(self._Readytoboss,ui.TXT_USER_CONTENT)
	local txt_bot_content = uikits.child(self._Readytoboss,ui.TXT_BOT_CONTENT)
	local but_user_next = uikits.child(self._Readytoboss,ui.BUTTON_USER_NEXT)
	local but_bot_next = uikits.child(self._Readytoboss,ui.BUTTON_BOT_NEXT)
	local pic_user_man = uikits.child(self._Readytoboss,ui.PIC_USER_MAN)
	local pic_user_woman = uikits.child(self._Readytoboss,ui.PIC_USER_WOMAN)
	if self.user_info.sex == 1 then
		pic_user_man:setVisible(true)
		pic_user_woman:setVisible(false)
	else
		pic_user_man:setVisible(false)
		pic_user_woman:setVisible(true)	
	end
	local pic_bot = uikits.child(self._Readytoboss,ui.PIC_BOT)
	local content_index = 1

	local function turn_to_next()
		if content_index > #self.bot_info.dialog then
			self:show_zhunbei()
			return
		end
		if self.bot_info.dialog[content_index].dialogue_role == 2 then
			txt_user_content:setString(self.bot_info.dialog[content_index].dialogue_content)
			view_user:setVisible(true)
			view_bot:setVisible(false)
		else
			txt_bot_content:setString(self.bot_info.dialog[content_index].dialogue_content)
			view_user:setVisible(false)
			view_bot:setVisible(true)
			txt_bot_name:setString(self.bot_info.dialog[content_index].card_plate_name)
			local pic_name = self.bot_info.dialog[content_index].card_plate_id..'c.png'
			person_info.load_card_pic(pic_bot,pic_name)
		end	
		content_index = content_index+1
	end
	
	uikits.event(but_user_next,	
		function(sender,eventType)	
			turn_to_next()
		end,"click")

	uikits.event(but_bot_next,	
		function(sender,eventType)	
			turn_to_next()
		end,"click")

	turn_to_next()
	self._view_gushi:setVisible(true)
	self._view_zhunbei:setVisible(false)
end

local schedulerEntry
local scheduler = cc.Director:getInstance():getScheduler()

function Readytoboss:show_zhunbei()	
	local pic_user_man = uikits.child(self._Readytoboss,ui.PIC_USER_ZHUNBEI_MAN)
	local pic_user_woman = uikits.child(self._Readytoboss,ui.PIC_USER_ZHUNBEI_WOMAN)
	local pic_bot_zhunbei = uikits.child(self._Readytoboss,ui.PIC_BOT_ZHUNBEI)
	
	if self.user_info.sex == 1 then
		pic_user_man:setVisible(true)
		local txt_user_man_lvl = uikits.child(self._Readytoboss,ui.PIC_USER_MAN_LVL)
		txt_user_man_lvl:setString(self.user_info.lvl)
		pic_user_woman:setVisible(false)
	else
		pic_user_man:setVisible(false)
		pic_user_woman:setVisible(true)	
		local txt_user_woman_lvl = uikits.child(self._Readytoboss,ui.TXT_USER_WOMAN_LVL)
		txt_user_woman_lvl:setString(self.user_info.lvl)
	end
	local pic_name = self.bot_info.card_plate_id..'b.png'
	person_info.load_card_pic(pic_bot_zhunbei,pic_name)
	
	local txt_bot_lvl = uikits.child(self._Readytoboss,ui.TXT_BOT_LVL)
	local txt_user_name = uikits.child(self._Readytoboss,ui.TXT_USER_NAME_ZHUNBEI)
	local txt_bot_name = uikits.child(self._Readytoboss,ui.TXT_BOT_NAME_ZHUNBEI)
	local txt_time = uikits.child(self._Readytoboss,ui.TXT_TIME)
	local choose_time = 5

	txt_bot_lvl:setString(self.bot_info.card_plate_level)
	txt_user_name:setString(self.user_info.name)
	txt_bot_name:setString(self.bot_info.card_plate_name)
	
	local function timer_update(time)
		txt_time:setString(choose_time)
		choose_time = choose_time -1
		if schedulerEntry and choose_time < 0 then
			scheduler:unscheduleScriptEntry(schedulerEntry)
			schedulerEntry = nil			
			
		end
	end	
		
	schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
	self._view_gushi:setVisible(false)
	self._view_zhunbei:setVisible(true)	
end

function Readytoboss:init_gui()	
	self.user_info = person_info.get_user_info()
	if self.is_has_star == false and self.bot_info.dialog then
		self:show_gushi()
	else
		self:show_zhunbei()
	end
end

function Readytoboss:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Readytoboss = uikits.fromJson{file_9_16=ui.Readytoboss_FILE,file_3_4=ui.Readytoboss_FILE_3_4}
	self:addChild(self._Readytoboss)
	
	self._view_gushi = uikits.child(self._Readytoboss,ui.VIEW_GUSHI)
	self._view_zhunbei = uikits.child(self._Readytoboss,ui.VIEW_ZHUNBEI)
	self._view_gushi:setVisible(false)
	self._view_zhunbei:setVisible(false)
	self:init_gui()
--	self:getdatabyurl()
--	local loadbox = Readytobossbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Readytoboss:release()

end
return {
create = create,
}