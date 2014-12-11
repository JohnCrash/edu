local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Mainview = class("Mainview")
Mainview.__index = Mainview
local ui = {
	FILE = 'poetrymatch/shouye.json',
	FILE_3_4 = 'poetrymatch/shouye.json',

	TXT_TILI_TIME = 'xinxi/tili/shij',
	TXT_TILI_NUM = 'xinxi/tili/tis',
	PRO_TILI = 'xinxi/tili/jindu',
	BUTTON_TILI_ADD = 'xinxi/tili/jia',
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

function Mainview:show_tili_num()
	local tili_txt = self.tili_num..'/100'
	self._txt_tili_num:setString(tili_txt)
	local tili_bar = uikits.child(self._Mainview,ui.PRO_TILI)
	tili_bar:setPercent(self.tili_num)
end

function Mainview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Mainview = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._Mainview)

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
--[[	local txt_sec
	local txt_min
	txt_sec = self.last_time%60
	txt_min = (self.last_time-txt_sec)/60
	self._txt_tili_time:setString(txt_min..':'..txt_sec)
	if self.tili_num <100 then
		self._txt_tili_time:setVisible(true)
	else
		self._txt_tili_time:setVisible(false)
	end--]]
	self:show_tili_num()
	
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
	if schedulerEntry then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end
return {
create = create,
}