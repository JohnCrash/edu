local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"
local countryview = require "poetrymatch/Countryview"
local battleview = require "poetrymatch/Battleview"


local Mainview = class("Mainview")
Mainview.__index = Mainview
local ui = {
	FILE = 'poetrymatch/shouye.json',
	FILE_3_4 = 'poetrymatch/shouye.json',

	TXT_TILI_TIME = 'xinxi/tili/shij',
	TXT_TILI_NUM = 'xinxi/tili/tis',
	PRO_TILI = 'xinxi/tili/jindu',
	BUTTON_TILI_ADD = 'xinxi/tili/jia',
	
	PRO_LEVEL = 'xinxi/dengji/jidu',
	TXT_LEVEL_NUM = 'xinxi/dengji/dengji',
	
	BUTTON_SILVER = 'xinxi/yibi/jia',
	TXT_SILVER_NUM = 'xinxi/yibi/zhi',
	
	BUTTON_LE = 'xinxi/lebi/jia',
	TXT_LE_NUM = 'xinxi/lebi/zhi',	
	
	CARD_VIEW = 'ka1',
	PIC_CARD = 'k1',
	TXT_CARD_LVL = 'dj',
	
	BUTTON_DUIZHAN = 'duizhan',
	BUTTON_CHUANGGUAN = 'chuangguan',
	BUTTON_LEITAI = 'leitai',
	BUTTON_QUIT = 'xinxi/fanhui',
}

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Mainview)		
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

function Mainview:getdatabyurl()

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
local schedulerEntry = nil
local per_tili_reset_time = 1*60

function Mainview:show_level()
	local lvl_table = person_info.get_user_lvl_info()
	local lvl_bar = uikits.child(self._Mainview,ui.PRO_LEVEL)
	local percent_lvl = (lvl_table.cur_exp/lvl_table.max_exp)*100
	lvl_bar:setPercent(percent_lvl)
	local txt_lvl = uikits.child(self._Mainview,ui.TXT_LEVEL_NUM)
	txt_lvl:setString(lvl_table.lvl)
end

function Mainview:show_tili_num()
	local tili_txt = self.tili_num..'/100'
	self._txt_tili_num:setString(tili_txt)
	local tili_bar = uikits.child(self._Mainview,ui.PRO_TILI)
	tili_bar:setPercent(self.tili_num)
end

function Mainview:show_silver()
	local silver_num = person_info.get_user_silver()
	local txt_silver = uikits.child(self._Mainview,ui.TXT_SILVER_NUM)
	txt_silver:setString(silver_num)
end

function Mainview:show_le_coin()
	local le_num = person_info.get_user_le_coin()
	local txt_le = uikits.child(self._Mainview,ui.TXT_LE_NUM)
	txt_le:setString(le_num)
end
local card_space = 1
function Mainview:show_cards()
	local card_view_src = uikits.child(self._Mainview,ui.CARD_VIEW)
	card_view_src:setVisible(false)
	local all_battle_list = person_info.get_all_card_in_battle()
	for i=1,#all_battle_list do
		local cur_card = card_view_src:clone()
		local pic_card = uikits.child(cur_card,ui.PIC_CARD)
		local pic_name = all_battle_list[i].id..'2.png'
		--pic_card:loadTexture(pic_path)
		person_info.load_card_pic(pic_card,pic_name)
		local txt_card_lvl = uikits.child(cur_card,ui.TXT_CARD_LVL)
		local pos_y = cur_card:getPositionY()
		local size_card = cur_card:getContentSize()
		pos_y = pos_y-(size_card.height+card_space)*(i-1)
		cur_card:setPositionY(pos_y)
		txt_card_lvl:setString(all_battle_list[i].lvl)
		cur_card:setVisible(true)
		self._Mainview:addChild(cur_card)
	end
end

function Mainview:init_gui()	
	self:show_tili_num()
	self:show_level()
	self:show_silver()
	self:show_le_coin()
	self:show_cards()
end

function Mainview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Mainview = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._Mainview)

	local but_quit = uikits.child(self._Mainview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
	
	local but_duizhan = uikits.child(self._Mainview,ui.BUTTON_DUIZHAN)
	uikits.event(but_duizhan,	
		function(sender,eventType)	
			local scene_next = battleview.create(self)
			uikits.pushScene(scene_next)	
		end,"click")	
		
	local but_chuangguan = uikits.child(self._Mainview,ui.BUTTON_CHUANGGUAN)
	uikits.event(but_chuangguan,	
		function(sender,eventType)	
			local scene_next = countryview.create(self)
			uikits.pushScene(scene_next)
		end,"click")	
		
	local but_leitai = uikits.child(self._Mainview,ui.BUTTON_LEITAI)
	uikits.event(but_leitai,	
		function(sender,eventType)	
			local scene_next = countryview.create(self)
			uikits.pushScene(scene_next)
		end,"click")	
	
	
	local scheduler = cc.Director:getInstance():getScheduler()
	--self._txt_tili_time = uikits.child(self._Mainview,ui.TXT_TILI_TIME)
	self._txt_tili_num = uikits.child(self._Mainview,ui.TXT_TILI_NUM)
	
	local but_tili_add = uikits.child(self._Mainview,ui.BUTTON_TILI_ADD)
	
	local function timer_update(time)
		self.last_time = self.last_time -1
		if self.last_time < 0 then
			self.last_time = per_tili_reset_time + self.last_time
			self.tili_num = self.tili_num +1
			--self._txt_tili_num:setString(self.tili_num)
			self:show_tili_num()
			if self.tili_num == 100 then
			--	self._txt_tili_time:setVisible(false)
				if schedulerEntry then
					scheduler:unscheduleScriptEntry(schedulerEntry)
					schedulerEntry = nil
				end
			end
		end
--[[		local txt_sec
		local txt_min
		txt_sec = self.last_time%60
		txt_min = (self.last_time-txt_sec)/60
		self._txt_tili_time:setString(txt_min..':'..txt_sec)--]]
	end
	
	uikits.event(but_tili_add,	
		function(sender,eventType)	
			self.tili_num = self.tili_num -1
			self:show_tili_num()
			--self._txt_tili_time:setVisible(true)
			if not schedulerEntry and self.tili_num < 100 then
				schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
			end
			
		end,"click")	
	
	local save_info = kits.config("tili_time",'get')
	if not save_info then
		self.tili_num = 100
		self.last_time = per_tili_reset_time -1
	else
		local save_info_tb = json.decode(save_info)
		if not save_info_tb.last_tili_num or not save_info_tb.last_tili_num or not save_info_tb.last_tili_num  then
			self.tili_num = 100
			self.last_time = per_tili_reset_time -1
		else
			self.tili_num = tonumber(save_info_tb.last_tili_num)
			self.last_time = tonumber(save_info_tb.last_time)
			local old_time = tonumber(save_info_tb.old_time)
			local cur_time = os.time()
			local save_sec
			local save_min
			
			if self.tili_num < 100 then
				local save_time = cur_time - old_time
				if save_time > self.last_time then
					save_time = save_time - self.last_time
					self.tili_num = self.tili_num+1
					save_sec = save_time%per_tili_reset_time
					save_min = (save_time-save_sec)/per_tili_reset_time
					if self.tili_num + save_min <100 then
						self.tili_num = self.tili_num +save_min
						self.last_time = save_sec
					else
						self.tili_num = 100
						self.last_time = per_tili_reset_time -1
					end
				else
					self.last_time = self.last_time - save_time
				end
			else
				self.tili_num = 100
				self.last_time = per_tili_reset_time -1			
			end		
		end
	end

	self:init_gui()
	if not schedulerEntry and self.tili_num < 100 then
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
	end
	
end

function Mainview:release()
	local save_info_tb = {}
	save_info_tb.last_time = self.last_time
	save_info_tb.old_time = os.time()
	save_info_tb.last_tili_num = self.tili_num
	local save_info = json.encode(save_info_tb)
	kits.config("tili_time",save_info)
	local scheduler = cc.Director:getInstance():getScheduler()
	if schedulerEntry then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end
return {
create = create,
}