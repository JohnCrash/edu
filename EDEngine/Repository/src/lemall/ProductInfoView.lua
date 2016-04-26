local uikits = require "uikits"
local kits = require "kits"
local json = require "json"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local paysucview = require 'lemall/PaySucView'
local mconfig = require 'lemall/MallConfig'
local getconfigview = require "lemall/GetConfigView"

local ProductInfoView = class("ProductInfoView")
ProductInfoView.__index = ProductInfoView
local ui = {
	ProductInfoView_FILE = 'lemall/shangping.json',
	ProductInfoView_FILE_3_4 = 'lemall/shangping43.json',

	VIEW_ZHIFU = 'zhifu',
	TXT_ZHIFU_PW1 = 'zhifu/bai/k1/su',
	TXT_ZHIFU_PW2 = 'zhifu/bai/k2/su',
	TXT_ZHIFU_PW3 = 'zhifu/bai/k3/su',
	TXT_ZHIFU_PW4 = 'zhifu/bai/k4/su',
	TXT_ZHIFU_PW5 = 'zhifu/bai/k5/su',
	TXT_ZHIFU_PW6 = 'zhifu/bai/k6/su',
	BUTTON_ZHIFU_CANCEL = 'zhifu/bai/qx',
	BUTTON_ZHIFU_OK = 'zhifu/bai/qr',
	
	BUTTON_ZHIFU_SRC = 'zhifu/bai/x',
	BUTTON_ZHIFU_1 = 'zhifu/bai/x1',
	BUTTON_ZHIFU_2 = 'zhifu/bai/x2',
	BUTTON_ZHIFU_3 = 'zhifu/bai/x3',
	BUTTON_ZHIFU_4 = 'zhifu/bai/x4',
	BUTTON_ZHIFU_5 = 'zhifu/bai/x5',
	BUTTON_ZHIFU_6 = 'zhifu/bai/x6',
	BUTTON_ZHIFU_7 = 'zhifu/bai/x7',
	BUTTON_ZHIFU_8 = 'zhifu/bai/x8',
	BUTTON_ZHIFU_9 = 'zhifu/bai/x9',
	BUTTON_ZHIFU_0 = 'zhifu/bai/x0',
	TXT_ZHIFU_1 = 'zhifu/bai/x1/su',
	TXT_ZHIFU_2 = 'zhifu/bai/x2/su',
	TXT_ZHIFU_3 = 'zhifu/bai/x3/su',
	TXT_ZHIFU_4 = 'zhifu/bai/x4/su',
	TXT_ZHIFU_5 = 'zhifu/bai/x5/su',
	TXT_ZHIFU_6 = 'zhifu/bai/x6/su',
	TXT_ZHIFU_7 = 'zhifu/bai/x7/su',
	TXT_ZHIFU_8 = 'zhifu/bai/x8/su',
	TXT_ZHIFU_9 = 'zhifu/bai/x9/su',
	TXT_ZHIFU_0 = 'zhifu/bai/x0/su',
	
	BUTTON_ZHIFU_C = 'zhifu/bai/xc',
	BUTTON_ZHIFU_B = 'zhifu/bai/xa',
	
--[[	VIEW_ERROR = 'cuow',
	TXT_ERR_PW1 = 'cuow/bai/k1/su',
	TXT_ERR_PW2 = 'cuow/bai/k2/su',
	TXT_ERR_PW3 = 'cuow/bai/k3/su',
	TXT_ERR_PW4 = 'cuow/bai/k4/su',
	TXT_ERR_PW5 = 'cuow/bai/k5/su',
	TXT_ERR_PW6 = 'cuow/bai/k6/su',
	BUTTON_ERR_CANCEL = 'cuow/bai/qx',
	BUTTON_ERR_OK = 'cuow/bai/qr',--]]
		
	PAGEVIEW_PRO = 'xiangqing/pic_pageview',	
	CUR_VIEW_PRO = 'xiangqing/pic_pageview/pic_view',	
	PIC_PRO = 'img_pro',
	VIEW_CHECK = 'xiangqing/dian',
	CHECK_SRC = 'xiangqing/dian/tu1',
	
	TXT_PRO_NAME = 'top/mingcheng',
	TXT_PRO_DES = 'xiangqing/xiangqiang/wen',
	TXT_SELLED = 'xiangqing/qingjia/jingbi',
	VIEW_DIS = 'xiangqing/qingjia/view_dis',
	TXT_LEFT_NUM = 'xiangqing/qingjia/liang',
	TXT_DIS_PRICE = 'xiangqing/qingjia/view_dis/jiesheng',
	TXT_DIS = 'xiangqing/qingjia/view_dis/zhekou/chuxiao',
	
	VIEW_PHONE_NUM = 'xiangqing/qingjia/shouji',	
	TXT_OLD_PHONE_NUM = 'xiangqing/qingjia/shouji/bai/hao',
	TXT_NEW_PHONE_NUM = 'xiangqing/qingjia/shouji/bai/xinde',
	BUTTON_CHANGE_NUM = 'xiangqing/qingjia/shouji/bai/gai',
		
	BUTTON_TIJIAO = 'baitiao/mai',
	TXT_ERR_MSG = 'baitiao/wen',
	BUT_QUIT = 'top/back',
}

function create(pro_id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),ProductInfoView)		
	cur_layer.pro_id = pro_id
	cur_layer.pw_index = 1
	cur_layer.tb_pw_show = {}
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

--local buy_product_url = 'http://shoping.lejiaolexue.com/ordertion.ashx'
local buy_product_url = 'http://app.lejiaolexue.com/shopping/ordertion.ashx'

local str_platform = 0
if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
	str_platform = 0
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_MAC then
	str_platform = 2
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_IPHONE then
	str_platform = 2
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_IPAD then
	str_platform = 2
elseif cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_ANDROID then
	str_platform = 1
end

function ProductInfoView:load_logo_pic(handle,file_url,pid)

	local function showLogoPic(logo_handle,logo_pic_path)
		if cc_type(logo_handle) == 'ccui.Button' then
			logo_handle:loadTextures(logo_pic_path,'')
		elseif cc_type(logo_handle) == 'ccui.ImageView' then
			logo_handle:loadTexture(logo_pic_path)
		end
	end
	
	local local_dir = ljshell.getDirectory(ljshell.AppDir)
	local file_path = local_dir.."cache/"..self.pro_id..'__'..pid..'.jpg'
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
			end,self.pro_id..'__'..pid..'.jpg')			
	end
end

function ProductInfoView:set_but_enabel(but_handle,is_show)
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



function ProductInfoView:set_keyboard()
	
	local but_zhifu_c = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_C)
	local but_zhifu_b = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_B)
	uikits.event(but_zhifu_c,	
		function(sender,eventType)	
			if self.pw_index == 1 then
				return
			end
			for i=1,self.pw_index-1 do
				self.tb_pw_show[i]:setString('')
			end		
			self.pw_index = 1
	end,'click')		
	uikits.event(but_zhifu_b,	
		function(sender,eventType)	
			if self.pw_index == 1 then
				return
			end
			self.pw_index = self.pw_index - 1
			self.tb_pw_show[self.pw_index]:setString('')
			
	end,'click')	
	self:format_keyboard()

end

local keyboard_map = {{txt_buf=1},{txt_buf=2},{txt_buf=3},{txt_buf=4},{txt_buf=5},{txt_buf=6},{txt_buf=7},{txt_buf=8},{txt_buf=9},{txt_buf=0}}

function ProductInfoView:format_keyboard()
	local function random_num()
		math.randomseed(os.time())
		for j=1 ,10 do
			local randomnum = math.random(10)
			local temp
			temp = keyboard_map[j].txt_buf
			keyboard_map[j].txt_buf = keyboard_map[randomnum].txt_buf
			keyboard_map[randomnum].txt_buf = temp
		end
	end
	random_num()
	for i=1,10 do
		keyboard_map[i].but_handle = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_SRC..i)
		keyboard_map[i].txt_handle = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_SRC..i..'/su')
		
		keyboard_map[i].txt_handle:setEnabled(false)
		keyboard_map[i].txt_handle:setBright(false)
		keyboard_map[i].txt_handle:setTouchEnabled(false)	
		
		keyboard_map[i].txt_handle:setString(keyboard_map[i].txt_buf)
--[[		if i == 10 then
			keyboard_map[i].but_handle.index = tonumber(keyboard_map[i].txt_buf)		
		else
			keyboard_map[i].but_handle.index = i		
		end--]]
		keyboard_map[i].but_handle.index = tonumber(keyboard_map[i].txt_buf)	
		uikits.event(keyboard_map[i].but_handle,	
			function(sender,eventType)	
				if self.pw_index > #self.tb_pw_show then
					return
				end
				self.tb_pw_show[self.pw_index]:setString(tostring(sender.index))
				self.pw_index = self.pw_index + 1
		end,'click')	
	end
end

function ProductInfoView:send_order()
	local tb_pro_info = {}
	tb_pro_info.product_id = self.pro_id
	tb_pro_info.buy_count = 1
	send_data = {}
	send_data.products = {}
	send_data.products[1] = tb_pro_info
	send_data.remark = 1

	if self.pro_info.tag_svc == 100 then
		local txt_new_phone_num = uikits.child(self._ProductInfoView,ui.TXT_NEW_PHONE_NUM)
		local phone_num
		if txt_new_phone_num:isVisible() == true then
			phone_num = txt_new_phone_num:getStringValue()
		else
			phone_num = mconfig.get_phone_num()
		end
		send_data.extend = phone_num
	end
	
	mconfig.post_data(self._ProductInfoView,'Order',send_data,function(t,v)
		if t and t == 200 then
			if v.order_no then
				self.order_no = tostring(v.order_no)
				self:show_pay_view()
			end
		else
			mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)
				if e == mconfig.OK then
				end
			end,'提示',v)								
		end
	end)
end

function ProductInfoView:pay_for_pro()
	local but_zhifu_ok = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_OK)
	local send_data = {}
	send_data.order_no = tostring(self.order_no)
	send_data.token = self.token
	send_data.pay_type = 3
	print('send_data.order_no::::::::'..send_data.order_no)
	mconfig.post_data(self._ProductInfoView,'PayOrder',send_data,function(t,v)
		if t and t == 200 then
			mconfig.remove_gold_num(self.pro_price)
			uikits.replaceScene( paysucview.create(self.pro_info) )
		else
			mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)
				if e == mconfig.OK then
					self:set_but_enabel(but_zhifu_ok,true)
				end
			end,'提示',v)								
		end
	end)	
end

local verify_pw_url = 'http://api.lejiaolexue.com/rest/pay/readpaycode.ashx'

function ProductInfoView:show_pay_view()

	local txt_pw1 = uikits.child(self._ProductInfoView,ui.TXT_ZHIFU_PW1)
	self.tb_pw_show[1] = txt_pw1
	local txt_pw2 = uikits.child(self._ProductInfoView,ui.TXT_ZHIFU_PW2)
	self.tb_pw_show[2] = txt_pw2
	local txt_pw3 = uikits.child(self._ProductInfoView,ui.TXT_ZHIFU_PW3)
	self.tb_pw_show[3] = txt_pw3
	local txt_pw4 = uikits.child(self._ProductInfoView,ui.TXT_ZHIFU_PW4)
	self.tb_pw_show[4] = txt_pw4
	local txt_pw5 = uikits.child(self._ProductInfoView,ui.TXT_ZHIFU_PW5)
	self.tb_pw_show[5] = txt_pw5
	local txt_pw6 = uikits.child(self._ProductInfoView,ui.TXT_ZHIFU_PW6)
	self.tb_pw_show[6] = txt_pw6
	
	txt_pw1:setString('')
	txt_pw2:setString('')
	txt_pw3:setString('')
	txt_pw4:setString('')
	txt_pw5:setString('')
	txt_pw6:setString('')
	self.pw_index = 1
	
	local view_zhifu = uikits.child(self._ProductInfoView,ui.VIEW_ZHIFU)
	view_zhifu:setVisible(true)
	
	self:set_keyboard()
	local but_zhifu_cancel = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_CANCEL)
	local but_zhifu_ok = uikits.child(self._ProductInfoView,ui.BUTTON_ZHIFU_OK)
	uikits.event(but_zhifu_cancel,	
		function(sender,eventType)	
			view_zhifu:setVisible(false)
	end,'click')	
	uikits.event(but_zhifu_ok,	
		function(sender,eventType)	
			local str_pw1 = txt_pw1:getStringValue()
			local str_pw2 = txt_pw2:getStringValue()
			local str_pw3 = txt_pw3:getStringValue()
			local str_pw4 = txt_pw4:getStringValue()
			local str_pw5 = txt_pw5:getStringValue()
			local str_pw6 = txt_pw6:getStringValue()
			--if string.len(str_pw1)>0 and string.len(str_pw2)>0 and string.len(str_pw3)>0 and string.len(str_pw4)>0 and string.len(str_pw5)>0 and string.len(str_pw6)>0 then
				local str_pw = str_pw1..str_pw2..str_pw3..str_pw4..str_pw5..str_pw6
				self:set_but_enabel(but_zhifu_ok,false)
				
				local str_send_data = 'pwd='..str_pw..'&app_id=1049'
				cache.post(verify_pw_url,str_send_data,function(t,d)
					if loading then
						loading:removeFromParent()
					end
					if t then
						print('tb_result:::::::'..d)
						local tb_result = json.decode(d)
						if tb_result.result == 0 then
							--mconfig.remove_gold_num(self.pro_price)
							--uikits.replaceScene( paysucview.create(self.pro_info) )
							--print('tb_result.msg::::'..tb_result.msg)
							if tb_result.msg then
								self.token = tb_result.msg
								self:pay_for_pro()							
							end
						else
							mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)
								self:set_but_enabel(but_zhifu_ok,true)
							end,'͡ʾ',tb_result.msg)			
						end
					else
						mconfig.messagebox(self._ProductInfoView,mconfig.ERR_NETWORK,function(e)
							self:set_but_enabel(but_zhifu_ok,true)
						end)	
					end
					self:set_but_enabel(but_zhifu_ok,true)
				end)
				--[[local tb_pro_info = {}
				tb_pro_info.pro_id = self.pro_id
				tb_pro_info.buynumber = 1
				local str_pro_info = json.encode(tb_pro_info)
				local str_send_data = 'projson='..str_pro_info..'&client_type='..str_platform..'&payment=1'..'&paypassword='..str_pw
				if tonumber(self.pro_info.tag_svc) == 100 then
					local txt_new_phone_num = uikits.child(self._ProductInfoView,ui.TXT_NEW_PHONE_NUM)
					local phone_num
					if txt_new_phone_num:isVisible() == true then
						phone_num = txt_new_phone_num:getStringValue()
					else
						phone_num = mconfig.get_phone_num()
					end
					str_send_data = str_send_data..'&tel='..phone_num
				end
				
				local loading = mconfig.circle(self._ProductInfoView)
				print('str_send_data::::'..str_send_data)
				cache.post(buy_product_url,str_send_data,function(t,d)
					if loading then
						loading:removeFromParent()
					end
					if t then
						print('tb_result:::::::'..d)
						local tb_result = json.decode(d)
						if tb_result.result == 0 then
							mconfig.remove_gold_num(self.pro_price)
							uikits.replaceScene( paysucview.create(self.pro_info) )
						else
							mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)
								self:set_but_enabel(but_zhifu_ok,true)
							end,'鎻愮⿿,tb_result.msg)			
						end
					else
						mconfig.messagebox(self._ProductInfoView,mconfig.ERR_NETWORK,function(e)
							self:set_but_enabel(but_zhifu_ok,true)
						end)	
					end
				end)	--]]
			--else
				
			--end
	end)		
end

local check_space = 50
function ProductInfoView:show_pro_info()
	local pageview_pro = uikits.child(self._ProductInfoView,ui.PAGEVIEW_PRO)
	local cur_view_pro = uikits.child(self._ProductInfoView,ui.CUR_VIEW_PRO)
	local cs = pageview_pro:getContentSize()
	
	local check_src = uikits.child(self._ProductInfoView,ui.CHECK_SRC)
	check_src:setVisible(false)
	local pos_src_x = check_src:getPositionX()
	pos_src_x = pos_src_x-(check_space * #self.pro_info.detail_img/2)
	self.check_tab = {}
	
	for i=1,#self.pro_info.detail_img do
		local layout
		if i == 1 then	
			layout = pageview_pro:getPage(0)
		else
			layout = cur_view_pro:clone()
			pageview_pro:addPage( layout )
		end
		local img = uikits.child(layout,ui.PIC_PRO)
		--img:loadTexture(v)
		self:load_logo_pic(img,self.pro_info.detail_img[i].img_url,i)
	
		local size = img:getContentSize()
		local masize = {}
		masize.width = math.max(cs.width,size.width)
		masize.height = math.max(cs.height,size.height)
		img:setPosition(cc.p(masize.width/2,masize.height/2))		
		
		local view_check = uikits.child(self._ProductInfoView,ui.VIEW_CHECK)

		local cur_check = check_src:clone()
		cur_check:setVisible(true)
		
		self.check_tab[i] = cur_check
		if i == 1 then
			cur_check:setSelectedState(true)
		else
			cur_check:setSelectedState(false)
		end
		
		local cur_pos_src_x = pos_src_x+check_space*(i-1)
		cur_check:setPositionX(cur_pos_src_x)
		
		view_check:addChild(cur_check)
	end
	
	uikits.event(pageview_pro,function(sender,eventType)
		if eventType == ccui.PageViewEventType.turning then
			local i = sender:getCurPageIndex()
			for j=1 ,#self.check_tab do
				if j == i+1 then
					self.check_tab[j]:setSelectedState(true)
				else
					self.check_tab[j]:setSelectedState(false)
				end
			end
		end
	end)

	local view_phone_num = uikits.child(self._ProductInfoView,ui.VIEW_PHONE_NUM)
	if self.pro_info.tag_svc == 100 then
		view_phone_num:setVisible(true)
	else
		view_phone_num:setVisible(false)
	end
	local txt_old_phone_num = uikits.child(self._ProductInfoView,ui.TXT_OLD_PHONE_NUM)
	local txt_new_phone_num = uikits.child(self._ProductInfoView,ui.TXT_NEW_PHONE_NUM)
	local but_change_num = uikits.child(self._ProductInfoView,ui.BUTTON_CHANGE_NUM)
	txt_new_phone_num:setText('')
	txt_old_phone_num:setString(mconfig.get_phone_num())
	txt_new_phone_num:setVisible(false)
	txt_old_phone_num:setVisible(true)
	but_change_num:setVisible(true)
	uikits.event(but_change_num,function(sender,eventType)
		but_change_num:setVisible(false)
		txt_old_phone_num:setVisible(false)
		txt_new_phone_num:setVisible(true)
	end)	
	
	
	local txt_pro_name = uikits.child(self._ProductInfoView,ui.TXT_PRO_NAME)
	txt_pro_name:setString(self.pro_info.pro_name)
		
	local txt_pro_des = uikits.child(self._ProductInfoView,ui.TXT_PRO_DES)	
	if self.pro_info.introduct then
		txt_pro_des:setString(self.pro_info.introduct)
	end
	local txt_pro_price = uikits.child(self._ProductInfoView,ui.TXT_SELLED)
	local txt_left_num = uikits.child(self._ProductInfoView,ui.TXT_LEFT_NUM)
	local view_pro_dis = uikits.child(self._ProductInfoView,ui.VIEW_DIS)
	local txt_pro_dis = uikits.child(self._ProductInfoView,ui.TXT_DIS)
	local txt_pro_dis_price = uikits.child(self._ProductInfoView,ui.TXT_DIS_PRICE)
	txt_left_num:setString(tostring(self.pro_info.proquanumber))

	local tab_price = self.pro_info.sell_price
	for j=1,#tab_price do
		if tab_price[j].price_type == 3 then
			self.pro_price = tab_price[j].money
			txt_pro_price:setString(tostring(tab_price[j].money)..'金币')
			if self.pro_info.issales == 1 then
				view_pro_dis:setVisible(true)
				txt_pro_dis:setString(tostring(tonumber(self.pro_info.disvalue)*10)..'折')
	txt_pro_dis_price:setString(self.pro_info.sale_price[j].money - self.pro_info.sell_price[j].money..'金币')
			else
				view_pro_dis:setVisible(false)
			end
		end
	end	

	local txt_err_msg = uikits.child(self._ProductInfoView,ui.TXT_ERR_MSG)
	local but_tijiao = uikits.child(self._ProductInfoView,ui.BUTTON_TIJIAO)
	uikits.event(but_tijiao,	
		function(sender,eventType)	
			local txt_new_phone_num = uikits.child(self._ProductInfoView,ui.TXT_NEW_PHONE_NUM)
			local phone_num
			if txt_new_phone_num:isVisible() == true then
				phone_num = txt_new_phone_num:getStringValue()
				if tonumber(phone_num) and string.len(phone_num) == 11 then
					
				else
					mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)

					end,'提示','请正确输入手机号')
					return								
				end 
			end

			local is_has_pay_pw = kits.config("has_pay_pw"..login.uid(),"get")
			if is_has_pay_pw and is_has_pay_pw == 1 then
				self:send_order()
				--self:show_pay_view()
			else
				uikits.replaceScene( getconfigview.create() )
			end
			
	end)	
	local gold_num  = mconfig.get_gold_num()
	if gold_num < self.pro_price then
		txt_err_msg:setVisible(true)
		self:set_but_enabel(but_tijiao,false)
	else
		txt_err_msg:setVisible(false)
		self:set_but_enabel(but_tijiao,true)
	end
end

--local get_product_info_url = 'http://shoping.lejiaolexue.com/productinfo.ashx'
local get_product_info_url = 'http://app.lejiaolexue.com/shopping/productinfo.ashx'

function ProductInfoView:getdatabyurl()
	
	local send_data = {}

	send_data.product_id = self.pro_id
	send_data.show_field = 3
	mconfig.post_data(self._ProductInfoView,'GetProductDetail',send_data,function(t,v)
		if t and t == 200 then
			self.pro_info = v
			self:show_pro_info()
		else
			mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)
				if e == mconfig.OK then
				end
			end,'提示',v)								
		end
	end)
--[[			
	local loading = mconfig.circle(self._ProductInfoView)
	local str_send_data = ''
	str_send_data = str_send_data..'pro_id='..self.pro_id
	cache.post(get_product_info_url,str_send_data,function(t,d)
		print('d::'..d)
		if loading then
			loading:removeFromParent()
		end
		if t then
			local tb_result = json.decode(d)
			if tb_result.result == 0 then
				self.pro_info = tb_result.pro_info
				self:show_pro_info()
			else
				mconfig.messagebox(self._ProductInfoView,mconfig.DIY_MSG,function(e)
					if e == true then
						self:getdatabyurl()
					end
				end,'鎻愮⿿,tb_result.msg)						
			end
		else
			mconfig.messagebox(self._ProductInfoView,mconfig.ERR_NETWORK,function(e)
				if e == true then
					self:getdatabyurl()
				else
					
				end
			end)			
		end
	end)--]]
end

function ProductInfoView:initgui()
	local view_zhifu = uikits.child(self._ProductInfoView,ui.VIEW_ZHIFU)
	view_zhifu:setVisible(false)
	local view_pro_dis = uikits.child(self._ProductInfoView,ui.VIEW_DIS)
	view_pro_dis:setVisible(false)
end

function ProductInfoView:init()	
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		uikits.initDR{width=1080,height=1920}
		self._ProductInfoView = uikits.fromJson{file=ui.ProductInfoView_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--mconfig.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--mconfig.initDR{width=1080,height=1920}
		end
		--self._ProductInfoView = uikits.fromJson{file_9_16=ui.ProductInfoView_FILE,file_3_4=ui.ProductInfoView_FILE_3_4}
		self._ProductInfoView = mconfig.fromJson{file_9_16=ui.ProductInfoView_FILE_3_4,file_3_4=ui.ProductInfoView_FILE}
	end
	self:addChild(self._ProductInfoView)
	self:initgui()
	self:getdatabyurl()
	local but_quit = uikits.child(self._ProductInfoView,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	

end

function ProductInfoView:release()

end
return {
create = create,
}