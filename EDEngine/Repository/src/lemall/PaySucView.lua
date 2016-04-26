local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local mconfig = require 'lemall/MallConfig'

local PaySucView = class("PaySucView")
PaySucView.__index = PaySucView
local ui = {
	PaySucView_FILE = 'lemall/chenggong.json',
	PaySucView_FILE_3_4 = 'lemall/chenggong43.json',
	
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

function create(pro_info)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),PaySucView)		
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

--禄驁牞ogo痰脭图
function PaySucView:load_logo_pic(handle,file_url,pid)

	local function showLogoPic(logo_handle,logo_pic_path)
		if cc_type(logo_handle) == 'ccui.Button' then
			logo_handle:loadTextures(logo_pic_path,'')
		elseif cc_type(logo_handle) == 'ccui.ImageView' then
			logo_handle:loadTexture(logo_pic_path)
		end
	end
	
	local local_dir = ljshell.getDirectory(ljshell.AppDir)
	local file_path = local_dir.."cache/"..pid..'.jpg'
	if kits.exist_file(file_path) then
		showLogoPic(handle,file_path)
	else
	--	local loadbox = put_lading_circle(handle)
		local send_url = file_url
		cache.request_nc(send_url,
		function(b,t)
				if b then
					showLogoPic(handle,file_path)
					--handle:loadTexture(file_path)
				else
					kits.log("ERROR :  download_pic_url failed")
				end
				--loadbox:removeFromParent()
			end,pid..'.jpg')			
	end
end

function PaySucView:initgui()
	local pic_pro = uikits.child(self._PaySucView,ui.PIC_PRO_ALL)
	local txt_pro_name = uikits.child(self._PaySucView,ui.TXT_PRO_ALL_NAME)
	local txt_pro_des = uikits.child(self._PaySucView,ui.TXT_PRO_ALL_DES)
	local txt_pro_price = uikits.child(self._PaySucView,ui.TXT_PRO_ALL_PRICE)
	local view_pro_dis = uikits.child(self._PaySucView,ui.VIEW_PRO_ALL_DIS)
	local txt_pro_dis = uikits.child(self._PaySucView,ui.TXT_PRO_ALL_DIS)
	self:load_logo_pic(pic_pro,self.pro_info.pro_img,self.pro_info.pro_id)
	txt_pro_name:setString(self.pro_info.pro_name)
	txt_pro_des:setString(self.pro_info.introduct)
	local tab_price = self.pro_info.sale_price
	for j=1,#tab_price do
		if tab_price[j].price_type == 3 then
			txt_pro_price:setString(tab_price[j].money..'金币' )
			if self.pro_info.issales == 1 then
				view_pro_dis:setVisible(true)
				txt_pro_dis:setString(tostring(tonumber(self.pro_info.disvalue)*10)..'折' )
			else
				view_pro_dis:setVisible(false)
			end
		end
	end
end

function PaySucView:init()	
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		uikits.initDR{width=1080,height=1920}
		self._PaySucView = uikits.fromJson{file=ui.PaySucView_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--mconfig.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--mconfig.initDR{width=1080,height=1920}
		end
		--self._PaySucView = uikits.fromJson{file_9_16=ui.PaySucView_FILE,file_3_4=ui.PaySucView_FILE_3_4}
		self._PaySucView = mconfig.fromJson{file_9_16=ui.PaySucView_FILE_3_4,file_3_4=ui.PaySucView_FILE}
	end

	self:addChild(self._PaySucView)
	self:initgui()
	local but_ok = uikits.child(self._PaySucView,ui.BUTTON_OK)
	uikits.event(but_ok,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")

	local but_quit = uikits.child(self._PaySucView,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function PaySucView:release()

end
return {
create = create,
}