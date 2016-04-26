local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local mconfig = require 'lemall/MallConfig'

local GetConfigView = class("GetConfigView")
GetConfigView.__index = GetConfigView
local ui = {
	GetConfigView_FILE = 'lemall/diyici.json',
	GetConfigView_FILE_3_4 = 'lemall/diyici43.json',
	TXT_INPUT_PASSWORD = 'bai/k1/mima',
	TXT_INPUT_VERIFY = 'bai/yan/yan',
	TXT_PHONE_NUM = 'bai/shouji',
	BUTTON_SMS = 'bai/fa',
	BUTTON_CANCEL = 'bai/qx',
	BUTTON_OK = 'bai/qr',
	TXT_JISHI = 'bai/jishi',
	
	BUT_QUIT = 'top/back',
}

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),GetConfigView)		
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

local schedulerEntry = nil
local scheduler = cc.Director:getInstance():getScheduler()

local init_password_url = 'http://api.lejiaolexue.com/rest/pay/setpaycode.ashx'
local get_sms_url = 'http://id.lejiaolexue.com/api/sendvericode.ashx'

function GetConfigView:initgui()
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		uikits.initDR{width=1080,height=1920}
		self._GetConfigView = uikits.fromJson{file=ui.GetConfigView_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--mconfig.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--mconfig.initDR{width=1080,height=1920}
		end
		--self._GetConfigView = uikits.fromJson{file_9_16=ui.GetConfigView_FILE,file_3_4=ui.GetConfigView_FILE_3_4}
		self._GetConfigView = mconfig.fromJson{file_9_16=ui.GetConfigView_FILE_3_4,file_3_4=ui.GetConfigView_FILE}
	end

	self:addChild(self._GetConfigView)
	
	local function set_but_enabel(but_handle,is_show)
		if is_show == true then
			but_handle:setEnabled(true)
			but_handle:setBright(true)
			but_handle:setTouchEnabled(true)
		else
			but_handle:setEnabled(false)
			but_handle:setBright(false)
			but_handle:setTouchEnabled(false)	
		end	
	end

	self.txt_jishi = uikits.child(self._GetConfigView,ui.TXT_JISHI)
	local but_sms = uikits.child(self._GetConfigView,ui.BUTTON_SMS)
	self.txt_jishi:setVisible(false)
	local function timer_update(time)
		self.last_time = self.last_time -1
		--print('self.last_time:::::::'..self.last_time)
		if self.last_time < 0 then
			set_but_enabel(but_sms,true)
			self.txt_jishi:setVisible(false)
			if schedulerEntry then
				scheduler:unscheduleScriptEntry(schedulerEntry)
				schedulerEntry = nil
			end
		else
			self.txt_jishi:setString(self.last_time)
		end
	end	

	local phone_num = uikits.child(self._GetConfigView,ui.TXT_PHONE_NUM)
	phone_num:setString(mconfig.get_phone_num())
--	self:get_userinfo()
--	local but_sms = uikits.child(self._GetConfigView,ui.BUTTON_SMS)
	uikits.event(but_sms,	
		function(sender,eventType)	
			local loading = mconfig.circle(self._GetConfigView)
			set_but_enabel(but_sms,false)
			local str_send_data = ''
			str_send_data = str_send_data..'phone='..mconfig.get_phone_num()
			cache.post(get_sms_url,str_send_data,function(t,d)
				if loading then
					loading:removeFromParent()
				end
				if t then
					local tb_result = json.decode(d)
					if tb_result.result == 0 then
						if not schedulerEntry then
							self.last_time = 60
							self.txt_jishi:setVisible(true)
							self.txt_jishi:setString(self.last_time)
							schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
						end						
					else
						mconfig.messagebox(self._GetConfigView,mconfig.DIY_MSG,function(e)
							if e == true then
							--	self:get_userinfo()
							set_but_enabel(sender,true)
							end
						end,'提示',tb_result.msg)							
					end
				else
					mconfig.messagebox(self._GetConfigView,mconfig.ERR_NETWORK,function(e)
						if e == true then
							set_but_enabel(sender,true)
						else
							
						end
					end)					
				end
			end)
		end,"click")
	local but_ok = uikits.child(self._GetConfigView,ui.BUTTON_OK)
	uikits.event(but_ok,	
		function(sender,eventType)	
			local str_send_data = ''
			local txt_pw = uikits.child(self._GetConfigView,ui.TXT_INPUT_PASSWORD)
			local txt_verify = uikits.child(self._GetConfigView,ui.TXT_INPUT_VERIFY)
			local str_pw = txt_pw:getStringValue()
			local str_verify = txt_verify:getStringValue()
			if not str_pw or string.len(str_pw) < 6 then
				mconfig.messagebox(self._GetConfigView,mconfig.DIY_MSG,function(e)

				end,'提示','新密码填写错误')
				return
			end
			if not str_verify or string.len(str_verify) == 0 then
				mconfig.messagebox(self._GetConfigView,mconfig.DIY_MSG,function(e)

				end,'提示','验证码不能为空')
				return
			end
			if not tonumber(str_pw) then
				mconfig.messagebox(self._GetConfigView,mconfig.DIY_MSG,function(e)

				end,'提示','新密码必须为数字')
				return			
			end
			str_send_data = str_send_data..'newpwd='..str_pw..'&vcode='..str_verify
			print('str_send_data:::::::'..str_send_data)
			set_but_enabel(but_ok,false)
			local loading = mconfig.circle(self._GetConfigView)
			cache.post(init_password_url,str_send_data,function(t,d)
				if loading then
					loading:removeFromParent()
				end			
				if t then
					print('tb_result:::::::'..d)
					local tb_result = json.decode(d)
					if tb_result.result == 0 then
						kits.config("has_pay_pw"..login.uid(),1)
						--uikits.replaceScene( mainview.create() )
						uikits.popScene()
					else
						mconfig.messagebox(self._GetConfigView,mconfig.DIY_MSG,function(e)
							if e == true then
							--	self:get_userinfo()
							set_but_enabel(sender,true)
							end
						end,'提示',tb_result.msg)							
					end
				else
					mconfig.messagebox(self._GetConfigView,mconfig.ERR_NETWORK,function(e)
						if e == true then
							set_but_enabel(sender,true)
						else
							
						end
					end)					
				end
			end)				
		end,"click")
		
	local but_cancel = uikits.child(self._GetConfigView,ui.BUTTON_CANCEL)
	uikits.event(but_cancel,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")

	local but_quit = uikits.child(self._GetConfigView,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function GetConfigView:init()	
	self:initgui()
end

function GetConfigView:release()

end
return {
create = create,
}