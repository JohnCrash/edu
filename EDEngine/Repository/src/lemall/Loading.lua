local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local mainview = require "lemall/MainView"
local mconfig = require 'lemall/MallConfig'

local Loading = class("Loading")
Loading.__index = Loading
local ui = {
	Loading_FILE = 'lemall/loading.json',
	Loading_FILE_3_4 = 'lemall/loading43.json',
	
	VIEW_PRO_ALL_SRC = 'sp',
	PIC_PRO_ALL = 'sp/tu',
	TXT_PRO_ALL_NAME = 'sp/mingz',
	TXT_PRO_ALL_DES = 'sp/jies',
	TXT_PRO_ALL_PRICE = 'sp/jiage',
	VIEW_PRO_ALL_DIS = 'sp/zhekou',
	TXT_PRO_ALL_DIS = 'sp/zhekou/chuxiao',
	
	BUTTON_OK = 'qr',
	
	BUT_QUIT = 'top/back',
}

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

local get_userinfo_url = 'http://api.lejiaolexue.com/rest/userinfo/full/current'
local get_gold_url = 'http://api.lejiaolexue.com/rest/asset/userasset.ashx'

function Loading:get_gold()
	local str_send_data = 'currecy=3'
	kits.log('str_send_data:::::::'..str_send_data)
	--local loading = mconfig.circle(self._Loading)
	cache.post(get_gold_url,str_send_data,function(t,d)
--[[		if loading then
			loading:removeFromParent()
		end--]]
		if t then
			kits.log('d:::::'..d)
			local tb_result = json.decode(d)
			if tb_result.result == 0 then
				if tb_result.data and type(tb_result.data) == 'table' and tb_result.data[1] then
					kits.log('tb_result.data[1].amount:::::'..tb_result.data[1].amount)
					mconfig.set_gold_num(tonumber(tb_result.data[1].amount))
				else
					mconfig.set_gold_num(0)
				end
				self:getconfig()
			else
				mconfig.messagebox(self._Loading,mconfig.DIY_MSG,function(e)
					if e == true then
						self:get_gold()
					end
				end,'提示',tb_result.msg)						
			end
		else
			mconfig.messagebox(self._Loading,mconfig.ERR_NETWORK,function(e)
				if e == true then
					self:get_gold()
				else
					
				end
			end)				
		end
	end)		
end

function Loading:get_userinfo()
	local str_send_data = ''
	--local loading = mconfig.circle(self._Loading)
	
	cache.post(get_userinfo_url,str_send_data,function(t,d)
--[[		if loading then
			loading:removeFromParent()
		end--]]
		
		if t then
			kits.log('d:::::'..d)
			local tb_result = json.decode(d)
			if tb_result.result == 0 then
				if tb_result.uig and type(tb_result.uig) and tb_result.uig[1] and tb_result.uig[1].phoneno then
--[[					self.phone_num = tb_result.uig[1].phoneno
					local phone_num = uikits.child(self._Loading,ui.TXT_PHONE_NUM)
					phone_num:setString(tb_result.uig[1].phoneno)--]]
					if tb_result.uig[1].user_role < 3 then
						mconfig.messagebox(self._Loading,mconfig.DIY_MSG,function(e)
							if e == true then
								uikits.popScene()
							end
						end,'提示','商城需老师身份才能进入')		
						return					
					end
					mconfig.set_phone_num(tb_result.uig[1].phoneno)
					mconfig.set_name(tb_result.uig[1].uname)
					self:get_gold()
				end
			else
				mconfig.messagebox(self._Loading,mconfig.DIY_MSG,function(e)
					if e == true then
						self:get_userinfo()
					end
				end,'提示',tb_result.msg)						
			end
		else
			mconfig.messagebox(self._Loading,mconfig.ERR_NETWORK,function(e)
				if e == true then
					self:get_userinfo()
				else
					
				end
			end)				
		end
	end)	
end


--鑾峰彇閰嶇疆椤癸紝鏄惁宸茬粡鏈夋敮浠樺瘑鐮併€?
local get_paycode_url = 'http://api.lejiaolexue.com/rest/pay/initpaycode.ashx'

function Loading:getconfig()
	--鍒ゆ柇鏈湴閰嶇疆鏂囦欢涓槸鍚﹀凡缁忔湁閫夐」銆?
	--濡傛灉閰嶇疆鏂囦欢涓湁锛屽苟涓旈厤缃」涓哄凡缁忔湁鏀粯瀵嗙爜锛屽垯鐩存帴鑾峰彇鍟嗗搧鍒楄〃
	--濡傛灉閰嶇疆鏂囦欢涓病鏈夛紝鎴栬€呮樉绀烘病鏈夋敮浠樺瘑鐮侊紝鍒欎粠鏈嶅姟鍣ㄨ幏鍙栧綋鍓嶇姸鎬侊紝骞朵笖璁剧疆閰嶇疆鏂囦欢
	local is_has_pay_pw = kits.config("has_pay_pw"..login.uid(),"get")
	if is_has_pay_pw and is_has_pay_pw == 1 then
		uikits.replaceScene( mainview.create() )
	else
		--local loading = mconfig.circle(self._Loading)
		local str_send_data = ''
		cache.post(get_paycode_url,str_send_data,function(t,d)
--[[			if loading then
				loading:removeFromParent()
			end--]]
			if t then
				kits.log('d::'..d)
				local tb_result = json.decode(d)
				if tb_result.result == 0 then
					kits.config("has_pay_pw"..login.uid(),1)
				--	uikits.replaceScene( mainview.create() )

				else
					--self:initgui()
					kits.config("has_pay_pw"..login.uid(),0)
				--	uikits.replaceScene( getconsigview.create() )
				end
				uikits.replaceScene( mainview.create() )
			else
				mconfig.messagebox(self._Loading,mconfig.ERR_NETWORK,function(e)
					if e == true then
						self:getconfig()
					else
						
					end
				end)					
			end
		end)	
	end
	
end

function Loading:init()	
	cc_setUIOrientation(2)
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		uikits.initDR{width=1080,height=1920}
		self._Loading = uikits.fromJson{file=ui.Loading_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--mconfig.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--mconfig.initDR{width=1080,height=1920}
		end
		--self._Loading = uikits.fromJson{file_9_16=ui.Loading_FILE,file_3_4=ui.Loading_FILE_3_4}
		self._Loading = mconfig.fromJson{file_9_16=ui.Loading_FILE_3_4,file_3_4=ui.Loading_FILE}	
	end

	self:addChild(self._Loading)
	mconfig.set_base_rid()
	self:get_userinfo()
--[[	local but_ok = uikits.child(self._Loading,ui.BUTTON_OK)
	uikits.event(but_ok,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")

	local but_quit = uikits.child(self._Loading,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	--]]
end

function Loading:release()

end
return {
create = create,
}