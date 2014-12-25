local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
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
	PIC_USER = 'gushi/wo/nv',
	
	VIEW_BOT = 'gushi/duifang',
	TXT_BOT_NAME = 'gushi/duifang/duihua/mz',
	TXT_BOT_CONTENT = 'gushi/duifang/duihua/dh',
	BUTTON_BOT_NEXT = 'gushi/duifang/xyt',
	PIC_BOT = 'gushi/duifang/k2',
	
	VIEW_ZHUNBEI = 'zhunbei',	
	PIC_USER_ZHUNBEI = 'zhunbei/vs/toux',
	TXT_USER_LVL = 'zhunbei/vs/toux/jibie',
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

function create(bot_info)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Readytoboss)		
	cur_layer.bot_info = bot_info
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
	txt_bot_name:setString(self.bot_info.name)
	local txt_user_content = uikits.child(self._Readytoboss,ui.TXT_USER_CONTENT)
	local txt_bot_content = uikits.child(self._Readytoboss,ui.TXT_BOT_CONTENT)
	local but_user_next = uikits.child(self._Readytoboss,ui.BUTTON_USER_NEXT)
	local but_bot_next = uikits.child(self._Readytoboss,ui.BUTTON_BOT_NEXT)
	local content_index = 1

	local function turn_to_next()
		if content_index > #self.bot_info.content then
			self:show_zhunbei()
		end

		if self.bot_info.content[content_index].id == self.user_info.id then
			txt_user_content:setString(self.bot_info.content[content_index].data)
			view_user:setVisible(true)
			view_bot:setVisible(false)
		else
			txt_bot_content:setString(self.bot_info.content[content_index].data)
			view_user:setVisible(false)
			view_bot:setVisible(true)
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
	local txt_user_lvl = uikits.child(self._Readytoboss,ui.TXT_USER_LVL)
	local txt_bot_lvl = uikits.child(self._Readytoboss,ui.TXT_BOT_LVL)
	local txt_user_name = uikits.child(self._Readytoboss,ui.TXT_USER_NAME_ZHUNBEI)
	local txt_bot_name = uikits.child(self._Readytoboss,ui.TXT_BOT_NAME_ZHUNBEI)
	local txt_time = uikits.child(self._Readytoboss,ui.TXT_TIME)
	local choose_time = 5
	
	txt_user_lvl:setString(self.user_info.lvl)
	txt_bot_lvl:setString(self.bot_info.lvl)
	txt_user_name:setString(self.user_info.name)
	txt_bot_name:setString(self.bot_info.name)
	
	local function timer_update(time)
		txt_time:setString(choose_time)
		choose_time = choose_time -1
		if schedulerEntry and choose_time < 0 then
			scheduler:unscheduleScriptEntry(schedulerEntry)
			schedulerEntry = nil

			---[[ by luleyan! -------------------------	
			local sc = cc.Scene:create()
			local moLaBattle = require "poetrymatch/BattleScene/LaBattle"

			--传入战斗层的数据包
			local dataTable = {}
			--[[数据
			dataTable.battle_type = 1
			dataTable.rounds_number = 

			dataTable.plyr_hp =
			dataTable.enmey_hp = 
			dataTable.ar_vit = {1, 2, 3}
			dataTable.ar_card_id = {1, 2, 3}
			dataTable.ar_skill_id
			 = {1, 2, 3}
			--参数
			player_info = {}
			
			player_info.lvl = int
			player_info.img = path
			player_info.name = string

			card_list = {id,id,id}
			id lvl skill hp tili 



			dataTable.plyr_img_id = 
			dataTable.enemy_img_id =
			dataTable.plyr_name = 
			dataTable.enemy_name =
			dataTable.plyr_lv = 
			dataTable.enemy_lv = 
			dataTable.ar_card_img_id = {}
			dataTable.ar_card_lv = {}
			dataTable.ar_skill_img_id = {}
			--]]

			--生成战斗层场景
			local laBattle = moLaBattle.Class:create(dataTable)
			sc:addChild(laBattle)
			cc.Director:getInstance():pushScene(sc)
			--]]---------------------------------------

		end
	end	
		
	schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
	self._view_gushi:setVisible(false)
	self._view_zhunbei:setVisible(true)	
end

function Readytoboss:init_gui()	
	self.user_info = person_info.get_user_info()
	if self.bot_info.star_has == 0 then
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