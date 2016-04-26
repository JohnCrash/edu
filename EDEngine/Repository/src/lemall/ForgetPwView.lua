local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local mconfig = require 'lemall/MallConfig'

local ForgetPwView = class("ForgetPwView")
ForgetPwView.__index = ForgetPwView
local ui = {
	ForgetPwView_FILE = 'lemall/wangji.json',
	ForgetPwView_FILE_3_4 = 'lemall/wangji43.json',
	
	TXT_INPUT_PASSWORD1 = 'bai/m1/mi',
	TXT_INPUT_PASSWORD2 = 'bai/m2/mi',
	TXT_INPUT_VERIFY = 'bai/yan/yan',
	TXT_PHONE_NUM = 'bai/shouji',
	BUTTON_SMS = 'bai/fa',
	BUTTON_CANCEL = 'bai/qx',
	BUTTON_OK = 'bai/qr',	
	TXT_JISHI = 'bai/jishi',
	
	BUT_QUIT = 'top/back',
}

function create(pro_info)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),ForgetPwView)		
	cur_layer.pro_info = pro_info
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

local reset_pw_url = 'http://api.lejiaolexue.com/rest/pay/resetpwd.ashx'

local get_userinfo_url = 'http://api.lejiaolexue.com/rest/userinfo/full/current'
local get_sms_url = 'http://id.lejiaolexue.com/api/sendvericode.ashx'
--[[
function ForgetPwView:get_userinfo()
	local str_send_data = ''
	local loading = mconfig.circle(self._ForgetPwView)
	cache.post(get_userinfo_url,str_send_data,function(t,d)
		if loading then
			loading:removeFromParent()
		end
		if t then
			print('d:::::'..d)
			local tb_result = json.decode(d)
			if tb_result.result == 0 then
				if tb_result.uig and type(tb_result.uig) and tb_result.uig[1] and tb_result.uig[1].phoneno then
					self.phone_num = tb_result.uig[1].phoneno
					local phone_num = uikits.child(self._ForgetPwView,ui.TXT_PHONE_NUM)
					phone_num:setString(tb_result.uig[1].phoneno)
				end
			else
				mconfig.messagebox(self._ForgetPwView,mconfig.DIY_MSG,function(e)
					if e == true then
						self:get_userinfo()
					end
				end,'提示',tb_result.msg)						
			end
		else
			mconfig.messagebox(self._ForgetPwView,mconfig.ERR_NETWORK,function(e)
				if e == true then
					self:get_userinfo()
				else
					
				end
			end)			
		end
	end)	
end--]]
local schedulerEntry = nil
local scheduler = cc.Director:getInstance():getScheduler()
function ForgetPwView:initgui()
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
	self.txt_jishi = uikits.child(self._ForgetPwView,ui.TXT_JISHI)
	local but_sms = uikits.child(self._ForgetPwView,ui.BUTTON_SMS)
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
	--self:get_userinfo()
	local phone_num = uikits.child(self._ForgetPwView,ui.TXT_PHONE_NUM)
	phone_num:setString(mconfig.get_phone_num())	
	

	uikits.event(but_sms,	
		function(sender,eventType)	
			set_but_enabel(but_sms,false)
			local loading = mconfig.circle(self._ForgetPwView)
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
							self.last_time = 10
							self.txt_jishi:setVisible(true)
							self.txt_jishi:setString(self.last_time)
							schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1,false)
						end
					else
						mconfig.messagebox(self._ForgetPwView,mconfig.DIY_MSG,function(e)
							if e == true then
							--	self:get_userinfo()
							set_but_enabel(sender,true)
							end
						end,'提示',tb_result.msg)							
					end
				else
					mconfig.messagebox(self._ForgetPwView,mconfig.ERR_NETWORK,function(e)
						if e == true then
							set_but_enabel(sender,true)
						else
							
						end
					end)						
				end
			end)
		end,"click")
	local but_ok = uikits.child(self._ForgetPwView,ui.BUTTON_OK)
	uikits.event(but_ok,	
		function(sender,eventType)	
			local str_send_data = ''
			local txt_pw1 = uikits.child(self._ForgetPwView,ui.TXT_INPUT_PASSWORD1)
			local txt_pw2 = uikits.child(self._ForgetPwView,ui.TXT_INPUT_PASSWORD2)
			local txt_verify = uikits.child(self._ForgetPwView,ui.TXT_INPUT_VERIFY)
			local str_pw1 = txt_pw1:getStringValue()
			local str_pw2 = txt_pw2:getStringValue()
			local str_verify = txt_verify:getStringValue()
			if not str_pw1 or string.len(str_pw1) < 6 or not str_pw2 or string.len(str_pw2) < 6 or string.len(str_pw1) ~= string.len(str_pw2) then
				mconfig.messagebox(self._ForgetPwView,mconfig.DIY_MSG,function(e)

				end,'提示','新密码填写错误')
				return
			end
			if not str_verify or string.len(str_verify) == 0 then
				mconfig.messagebox(self._ForgetPwView,mconfig.DIY_MSG,function(e)

				end,'提示','验证码不能为空')
				return
			end
			if not tonumber(str_pw1) then
				mconfig.messagebox(self._ForgetPwView,mconfig.DIY_MSG,function(e)

				end,'提示','新密码必须为数字')
				return			
			end
			
			local loading = mconfig.circle(self._ForgetPwView)			
			str_send_data = str_send_data..'pwd='..str_pw1..'&vcode='..str_verify
			print('str_send_data:::::::'..str_send_data)
			set_but_enabel(but_ok,false)
			cache.post(reset_pw_url,str_send_data,function(t,d)
				if loading then
					loading:removeFromParent()
				end
				if t then
					print('tb_result:::::::'..d)
					local tb_result = json.decode(d)
					if tb_result.result == 0 then
						mconfig.messagebox(self._ForgetPwView,mconfig.PW_MODIFY_OK,function(e)
							uikits.popScene()
						end)		
					else
						mconfig.messagebox(self._ForgetPwView,mconfig.DIY_MSG,function(e)
							if e == true then
							--	self:get_userinfo()
							set_but_enabel(sender,true)
							end
						end,'提示',tb_result.msg)	
					end
				else
					mconfig.messagebox(self._ForgetPwView,mconfig.ERR_NETWORK,function(e)
						if e == true then
							set_but_enabel(sender,true)
						else
							
						end
					end)		
				end
			end)				
		end,"click")
		
	local but_cancel = uikits.child(self._ForgetPwView,ui.BUTTON_CANCEL)
	uikits.event(but_cancel,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
end

function ForgetPwView:init()	
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		uikits.initDR{width=1080,height=1920}
		self._ForgetPwView = uikits.fromJson{file=ui.ForgetPwView_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--mconfig.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--mconfig.initDR{width=1080,height=1920}
		end
		--self._ForgetPwView = uikits.fromJson{file_9_16=ui.ForgetPwView_FILE,file_3_4=ui.ForgetPwView_FILE_3_4}
		self._ForgetPwView = mconfig.fromJson{file_9_16=ui.ForgetPwView_FILE_3_4,file_3_4=ui.ForgetPwView_FILE}
	end

	self:addChild(self._ForgetPwView)
	self:initgui()

	local but_quit = uikits.child(self._ForgetPwView,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function ForgetPwView:release()
	if schedulerEntry then
		scheduler:unscheduleScriptEntry(schedulerEntry)
		schedulerEntry = nil
	end
end
return {
create = create,
}