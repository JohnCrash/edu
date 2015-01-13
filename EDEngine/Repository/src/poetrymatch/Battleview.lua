local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"
local battlereward = require "poetrymatch/Battlereward"


local Battleview = class("Battleview")
Battleview.__index = Battleview
local ui = {
	Battleview_FILE = 'poetrymatch/duizhan.json',
	Battleview_FILE_3_4 = 'poetrymatch/duizhan.json',
	
	BUTTON_SEARCH = 'pipei',
	VIEW_SEARCH_RES = 'duis',
	BUTTON_RESEARCH = 'duis/huan',
	TXT_TIME = 'duis/20s',
	
	PIC_BOT1 = 'duis/ren2',
	TXT_BOT_NAME1 = 'duis/ren2/mz',
	TXT_BOT_RANK1 = 'duis/ren2/mc',
	PIC_BOT2 = 'duis/ren1',
	TXT_BOT_NAME2 = 'duis/ren1/mz',
	TXT_BOT_RANK2 = 'duis/ren1/mc',
	PIC_BOT3 = 'duis/ren3',
	TXT_BOT_NAME3 = 'duis/ren3/mz',
	TXT_BOT_RANK3 = 'duis/ren3/mc',
	
	VIEW_PERSON_RANK = 'geren/xial',
	VIEW_PERSON_SRC = 'geren/xial/xs1',
	TXT_RANK = 'quan/AtlasLabel_15',
	PIC_USER = 'toux',
	TXT_NAME = 'mz',
	TXT_WIN_NUM = 'shengli',
	TXT_SCHOOL_NAME = 'xuexiao',
	
	VIEW_SCHOOL_RANK = 'xues/xuexiao',
	VIEW_SCHOOL_SRC = 'xues/xuexiao/xx1',	
	TXT_SCHOOL_RANK = 'pm/paim',
	TXT_SCHOOL_RANK_NAME = 'mchen',
	TXT_SCHOOL_RANK_SCORE = 'wen_0',
	
	TXT_USER_WIN_NUM = 'wod/shengli',
	TXT_USER_LOSE_NUM = 'wod/shib',
	TXT_USER_RANK = 'wod/paim',
	TXT_USER_CON = 'wod/gongx',
	TXT_USER_SCHOOL_RANK = 'wod/xxpm',
	
	BUTTON_QUIT = 'xinxi/fanhui',
	BUTTON_JIANG = 'xinxi/jiang',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Battleview)		
	
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

local schedulerEntry
local scheduler = cc.Director:getInstance():getScheduler()

function Battleview:show_search_res()	
	local send_data = {}
	if self.bot_id then
		send_data.v1 = self.bot_id
	else
		send_data.v1 = {}
	end
	person_info.post_data_by_new_form(self._Battleview,'select_opponent',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				local pic_bot1 = uikits.child(self._Battleview,ui.PIC_BOT1)
				local pic_bot2 = uikits.child(self._Battleview,ui.PIC_BOT2)
				local pic_bot3 = uikits.child(self._Battleview,ui.PIC_BOT3)
				local txt_bot_name1 = uikits.child(self._Battleview,ui.TXT_BOT_NAME1)
				local txt_bot_name2 = uikits.child(self._Battleview,ui.TXT_BOT_NAME2)
				local txt_bot_name3 = uikits.child(self._Battleview,ui.TXT_BOT_NAME3)
				local txt_bot_rank1 = uikits.child(self._Battleview,ui.TXT_BOT_RANK1)
				local txt_bot_rank2 = uikits.child(self._Battleview,ui.TXT_BOT_RANK2)
				local txt_bot_rank3 = uikits.child(self._Battleview,ui.TXT_BOT_RANK3)
				self.bot_id = {}
				local function goto_battle(id) --Ω¯»Î’Ω∂∑
					if id then
						local send_data = {}
						if self.bot_id then
							send_data.v1 = self.bot_id
						end
						send_data.v2 = id
						person_info.post_data_by_new_form(self._Battleview,'select_opponent_confirm',send_data,function(t,v)
							if t and t == 200 then
								if v and type(v) == 'table' and v.v1 then
								
								end
							else
								person_info.messagebox(self._Battleview,person_info.NETWORK_ERROR,function(e)
									if e == person_info.OK then

									end
								end)	
							end
						end)
					end
				end
				
				uikits.event(pic_bot1,	
				function(sender,eventType)	
					goto_battle(sender.id)
				end,"click")
				uikits.event(pic_bot2,	
				function(sender,eventType)	
					goto_battle(sender.id)
				end,"click")
				uikits.event(pic_bot3,	
				function(sender,eventType)	
					goto_battle(sender.id)
				end,"click")
				if v[1] then
					txt_bot_name1:setString(v[1].uname)
					txt_bot_rank1:setString(v[1].user_rank)
					pic_bot1.id = v[1].user_id
					person_info.load_logo_pic(pic_bot1,v[1].user_id)
					self.bot_id[1] = v[1].user_id
				else
					self.bot_id = nil
					pic_bot1:setVisible(false)
					person_info.messagebox(self._Battleview,person_info.BATTLE_SEARCH_ERROR,function(e)
						if e == person_info.OK then
							local view_search_res = uikits.child(self._Battleview,ui.VIEW_SEARCH_RES)
							local but_search = uikits.child(self._Battleview,ui.BUTTON_SEARCH)								
							view_search_res:setVisible(false)
							but_search:setVisible(true)			
							if schedulerEntry then
								scheduler:unscheduleScriptEntry(schedulerEntry)
								schedulerEntry = nil								
							end
						end
					end)				
				end
				if v[2] then
					txt_bot_name2:setString(v[2].uname)
					txt_bot_rank2:setString(v[2].user_rank)	
					pic_bot2.id = v[2].user_id	
					pic_bot2:setVisible(true)
					person_info.load_logo_pic(pic_bot2,v[2].user_id)
					self.bot_id[2] = v[2].user_id
				else
					pic_bot2:setVisible(false)
				end		
				
				if v[3] then
					txt_bot_name3:setString(v[3].uname)
					txt_bot_rank3:setString(v[3].user_rank)				
					pic_bot3.id = v[3].user_id
					pic_bot3:setVisible(true)
					person_info.load_logo_pic(pic_bot3,v[3].user_id)
					self.bot_id[3] = v[3].user_id
				else
					pic_bot3:setVisible(false)				
				end
			end
		else
			person_info.messagebox(self._Battleview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)	
end

function Battleview:show_person_rank()
	local send_data = {}
	person_info.post_data_by_new_form(self._Battleview,'get_batter_world_heroes',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				local view_person_rank = uikits.child(self._Battleview,ui.VIEW_PERSON_RANK)
				local view_person_src = uikits.child(self._Battleview,ui.VIEW_PERSON_SRC)
				
				local viewSize=view_person_rank:getContentSize()
				local viewPosition=cc.p(view_person_rank:getPosition())
				local viewParent=view_person_rank:getParent()
				view_person_rank:setVisible(false)

				local view_person_rank1=person_info.createRankView(viewParent,viewPosition,viewSize,view_person_src,function(item,data)
				
					local pic_user = uikits.child(item,ui.PIC_USER)	
					local txt_rank = uikits.child(item,ui.TXT_RANK)	
					local txt_name = uikits.child(item,ui.TXT_NAME)	
					local txt_win_num = uikits.child(item,ui.TXT_WIN_NUM)	
					local txt_school_name = uikits.child(item,ui.TXT_SCHOOL_NAME)	
					person_info.load_logo_pic(pic_user,data.user_id)
					txt_rank:setString(data.rank)
					txt_name:setString(data.uname)
					txt_win_num:setString(data.win)
					txt_school_name:setString(data.sch_name)
					
					end,function(waitingNode,afterReflash)
					local data=v.list
					afterReflash(data)
				end)			
				--view_person_rank:removeFromParent()	
			end
		else
			person_info.messagebox(self._Battleview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Battleview:show_school_rank()
	local send_data = {}
	person_info.post_data_by_new_form(self._Battleview,'get_batter_sch_heroes',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
				local view_school_rank = uikits.child(self._Battleview,ui.VIEW_SCHOOL_RANK)
				local view_school_src = uikits.child(self._Battleview,ui.VIEW_SCHOOL_SRC)
				
				local viewSize=view_school_rank:getContentSize()
				local viewPosition=cc.p(view_school_rank:getPosition())
				local viewParent=view_school_rank:getParent()
				view_school_rank:setVisible(false)
				
				local view_person_rank1=person_info.createRankView(viewParent,viewPosition,viewSize,view_school_src,function(item,data)
					local txt_rank = uikits.child(item,ui.TXT_SCHOOL_RANK)	
					local txt_name = uikits.child(item,ui.TXT_SCHOOL_RANK_NAME)	
					local txt_score = uikits.child(item,ui.TXT_SCHOOL_RANK_SCORE)	
					txt_rank:setString(data.rank)
					txt_name:setString(data.sch_name)
					txt_score:setString(data.score)
											
					end,function(waitingNode,afterReflash)
					local data=v.list
					afterReflash(data)
				end)			
				--view_school_rank:removeFromParent()	
			end
		else
			person_info.messagebox(self._Battleview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Battleview:show_personal_info()
	local send_data = {}
	person_info.post_data_by_new_form(self._Battleview,'get_battle_week_user',send_data,function(t,v)
		if t and t == 200 then
			if v and type(v) == 'table' then
					local txt_win_num = uikits.child(self._Battleview,ui.TXT_USER_WIN_NUM)	
					local txt_lose_num = uikits.child(self._Battleview,ui.TXT_USER_LOSE_NUM)	
					local txt_contribution = uikits.child(self._Battleview,ui.TXT_USER_CON)	
					local txt_sch_rank = uikits.child(self._Battleview,ui.TXT_USER_SCHOOL_RANK)	
					local txt_user_rank = uikits.child(self._Battleview,ui.TXT_USER_RANK)	
					txt_win_num:setString(v.win)
					txt_lose_num:setString(v.lost)
					txt_contribution:setString(v.contribution)
					txt_sch_rank:setString(v.sch_rank)
					txt_user_rank:setString(v.user_rank)
			end
		else
			person_info.messagebox(self._Battleview,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)	
end	

function Battleview:init_gui()	
	local view_search_res = uikits.child(self._Battleview,ui.VIEW_SEARCH_RES)
	view_search_res:setVisible(false)
	local but_re_search = uikits.child(self._Battleview,ui.BUTTON_RESEARCH)	
	local txt_time = uikits.child(self._Battleview,ui.TXT_TIME)	
	local choose_time
	local but_search = uikits.child(self._Battleview,ui.BUTTON_SEARCH)	
	but_search:setVisible(true)
	
	local function timer_update(time)
		txt_time:setString(choose_time)
		choose_time = choose_time -1
		if schedulerEntry and choose_time < 0 then
			view_search_res:setVisible(false)
			but_search:setVisible(true)			
			scheduler:unscheduleScriptEntry(schedulerEntry)
			schedulerEntry = nil
		end
	end	
	
	uikits.event(but_re_search,	
		function(sender,eventType)	
			self:show_search_res()
			choose_time = 10
			txt_time:setString(choose_time)
			choose_time = choose_time -1
			if not schedulerEntry then
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
			end
		end,"click")	
		
	uikits.event(but_search,	
		function(sender,eventType)	
			self:show_search_res()
			view_search_res:setVisible(true)
			sender:setVisible(false)
			choose_time = 10
			txt_time:setString(choose_time)
			choose_time = choose_time -1
			if not schedulerEntry then
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
			end
		end,"click")	
	self:show_personal_info()
	self:show_person_rank()
	self:show_school_rank()
end

function Battleview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Battleview = uikits.fromJson{file_9_16=ui.Battleview_FILE,file_3_4=ui.Battleview_FILE_3_4}
	self:addChild(self._Battleview)
	
	local but_quit = uikits.child(self._Battleview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
		
	local but_jiang = uikits.child(self._Battleview,ui.BUTTON_JIANG)
	uikits.event(but_jiang,	
		function(sender,eventType)				
			local scene_next = battlereward.create()	
			uikits.pushScene(scene_next)	
		end,"click")
--	self:getdatabyurl()
--	local loadbox = Battleviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	
	self:init_gui()
end

function Battleview:release()
	if schedulerEntry then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil		
	end
end
return {
create = create,
}