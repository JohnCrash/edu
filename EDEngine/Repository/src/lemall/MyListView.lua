local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local mconfig = require 'lemall/MallConfig'
--local paysucview = require 'lemall/PaySucView'

local MyListView = class("MyListView")
MyListView.__index = MyListView
local ui = {
	MyListView_FILE = 'lemall/qingdan.json',
	MyListView_FILE_3_4 = 'lemall/qingdan43.json',
	
--[[	BUTTON_MINE_REPW = 'wode/mima/but_pro',
	VIEW_MINE_LIST_INFO = 'wode/tu',
	TXT_MINE_LIST_NUM = 'wode/tu/jian',
	VIEW_MINE_PRO_SRC = 'wode/sp1',
	TXT_MINE_PRO_GOLD_PAY = 'jinbi',
	TXT_MINE_PRO_DATE = 'shijian',
	PIC_MINE_PRO = 'tu',
	TXT_MINE_PRO_NAME = 'ming',
	TXT_MINE_PRO_DES = 'jieshao',
	TXT_MINE_PRO_GOLD_SELL = 'ming_1',--]]
	
	VIEW_MINE_LIST = 'gun',
	VIEW_MINE_PRO_SRC = 'gun/sp1',
	TXT_MINE_PRO_GOLD_PAY = 'jinbi',
	TXT_MINE_PRO_DATE = 'shijian',
	PIC_MINE_PRO = 'tu',
	TXT_MINE_PRO_NAME = 'ming',
	TXT_MINE_PRO_DES = 'jieshao',
	TXT_MINE_PRO_GOLD_SELL = 'jiage',
	TXT_MINE_PRO_NO_PAY = 'z1',
	TXT_MINE_PRO_PAY_OK = 'z2',
	TXT_MINE_PRO_SENDING = 'z3',
	TXT_MINE_PRO_OK = 'z4',
	
	BUTTON_PAY = 'zhifu',
	BUTTON_CANCEL = 'shanc',
	BUTTON_DETAIL = 'xiangqing',

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
	
	VIEW_DETAIL_ONLINE = 'dd1',
	TXT_ONLINE_NAME = 'dd1/zaixian/mz',
	TXT_ONLINE_TEL = 'dd1/zaixian/hao',
	TXT_ONLINE_NUM = 'dd1/zaixian/su',
	
	PIC_PROCESS1 = 'dd1/zaixian/z1',
	PIC_PROCESS2 = 'dd1/zaixian/z2',
	PIC_PROCESS3 = 'dd1/zaixian/z3',
	PIC_PROCESS4 = 'dd1/zaixian/z4',
	BUTTON_CLOSE = 'dd1/zaixian/guan',
	
	VIEW_DETAIL_GOODS = 'xianxia',
	
	BUTTON_ZHIFU_C = 'zhifu/bai/xc',
	BUTTON_ZHIFU_B = 'zhifu/bai/xa',
		
	TXT_MINE_LIST_NUM = 'top/sl',
	BUT_QUIT = 'top/back',
}

function create(pro_info,pro_num)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),MyListView)		
	--cur_layer.pro_info = pro_info
	cur_layer.pro_num = pro_num
	cur_layer.tb_pw_show = {}
	cur_layer.inner_pos = nil
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

--获取logo缩略图
function MyListView:load_logo_pic(handle,file_url,pid)

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

function MyListView:set_but_enabel(but_handle,is_show)
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

function MyListView:set_keyboard()
	
	local but_zhifu_c = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_C)
	local but_zhifu_b = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_B)
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

function MyListView:format_keyboard()
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
		keyboard_map[i].but_handle = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_SRC..i)
		keyboard_map[i].txt_handle = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_SRC..i..'/su')
		
		keyboard_map[i].txt_handle:setEnabled(false)
		keyboard_map[i].txt_handle:setBright(false)
		keyboard_map[i].txt_handle:setTouchEnabled(false)	
		
		keyboard_map[i].txt_handle:setString(keyboard_map[i].txt_buf)

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


function MyListView:pay_for_pro()
	local but_zhifu_ok = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_OK)
	local send_data = {}
	send_data.order_no = tostring(self.order_no)
	send_data.token = self.token
	send_data.pay_type = 3
	print('send_data.order_no::::::::'..send_data.order_no)
	mconfig.post_data(self._MyListView,'PayOrder',send_data,function(t,v)
		if t and t == 200 then
			mconfig.remove_gold_num(self.pro_price)
			local view_zhifu = uikits.child(self._MyListView,ui.VIEW_ZHIFU)
			view_zhifu:setVisible(false)
			self:set_but_enabel(but_zhifu_ok,true)
			self:resetview()
		else
			mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
				if e == mconfig.OK then
					self:set_but_enabel(but_zhifu_ok,true)
				end
			end,'提示',v)								
		end
	end)	
end


local verify_pw_url = 'http://api.lejiaolexue.com/rest/pay/readpaycode.ashx'

function MyListView:show_pay_view()

	local txt_pw1 = uikits.child(self._MyListView,ui.TXT_ZHIFU_PW1)
	self.tb_pw_show[1] = txt_pw1
	local txt_pw2 = uikits.child(self._MyListView,ui.TXT_ZHIFU_PW2)
	self.tb_pw_show[2] = txt_pw2
	local txt_pw3 = uikits.child(self._MyListView,ui.TXT_ZHIFU_PW3)
	self.tb_pw_show[3] = txt_pw3
	local txt_pw4 = uikits.child(self._MyListView,ui.TXT_ZHIFU_PW4)
	self.tb_pw_show[4] = txt_pw4
	local txt_pw5 = uikits.child(self._MyListView,ui.TXT_ZHIFU_PW5)
	self.tb_pw_show[5] = txt_pw5
	local txt_pw6 = uikits.child(self._MyListView,ui.TXT_ZHIFU_PW6)
	self.tb_pw_show[6] = txt_pw6
	
	txt_pw1:setString('')
	txt_pw2:setString('')
	txt_pw3:setString('')
	txt_pw4:setString('')
	txt_pw5:setString('')
	txt_pw6:setString('')
	self.pw_index = 1
	
	local view_zhifu = uikits.child(self._MyListView,ui.VIEW_ZHIFU)
	view_zhifu:setVisible(true)
	
	self:set_keyboard()
	local but_zhifu_cancel = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_CANCEL)
	local but_zhifu_ok = uikits.child(self._MyListView,ui.BUTTON_ZHIFU_OK)
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
							mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
								self:set_but_enabel(but_zhifu_ok,true)
							end,'提示',tb_result.msg)			
						end
					else
						mconfig.messagebox(self._MyListView,mconfig.ERR_NETWORK,function(e)
							self:set_but_enabel(but_zhifu_ok,true)
						end)	
					end
					self:set_but_enabel(but_zhifu_ok,true)
				end)
	end)		
end
	
function MyListView:show_order_info(order_detail,tag)
	local view_detail
	
--[[	if order_detail.order_pros[1].tag_svc == 100 then
		view_detail = uikits.child(self._MyListView,ui.VIEW_DETAIL_ONLINE)
		view_detail:setVisible(true)
		local txt_ol_name = uikits.child(self._MyListView,ui.TXT_ONLINE_NAME)
		local txt_ol_tel = uikits.child(self._MyListView,ui.TXT_ONLINE_TEL)
		local txt_ol_num = uikits.child(self._MyListView,ui.TXT_ONLINE_NUM)
		txt_ol_name:setString(login.get_name())
		txt_ol_tel:setString(order_detail.order.orderextend)
		txt_ol_num:setString('1')
	else
		
	end--]]
		view_detail = uikits.child(self._MyListView,ui.VIEW_DETAIL_ONLINE)
		view_detail:setVisible(true)
		local txt_ol_name = uikits.child(self._MyListView,ui.TXT_ONLINE_NAME)
		local txt_ol_tel = uikits.child(self._MyListView,ui.TXT_ONLINE_TEL)
		local txt_ol_num = uikits.child(self._MyListView,ui.TXT_ONLINE_NUM)
		txt_ol_name:setString(order_detail.order.buyusername)
		txt_ol_tel:setString(order_detail.order.orderextend)
		txt_ol_num:setString('1')
	local pic_process1 = uikits.child(self._MyListView,ui.PIC_PROCESS1)
	local pic_process2 = uikits.child(self._MyListView,ui.PIC_PROCESS2)
	local pic_process3 = uikits.child(self._MyListView,ui.PIC_PROCESS3)
	local pic_process4 = uikits.child(self._MyListView,ui.PIC_PROCESS4)
	pic_process1:setVisible(false)
	pic_process2:setVisible(false)
	pic_process3:setVisible(false)
	pic_process4:setVisible(false)
	if tag >= 0 and tag < 100 then
		pic_process1:setVisible(true)
	elseif tag >= 100 and tag < 200 then
		pic_process2:setVisible(true)
	elseif tag >= 200 and tag < 300 then
		pic_process4:setVisible(true)
	elseif tag >= 300 and tag < 400 then
		pic_process3:setVisible(true)
	elseif tag >= 400 and tag < 500 then
		pic_process4:setVisible(true)
	end
	local but_close = uikits.child(self._MyListView,ui.BUTTON_CLOSE)
	uikits.event(but_close,	
		function(sender,eventType)	
			view_detail:setVisible(false)
		end,"click")	
end

function MyListView:show_list()
	local view_title_list = uikits.child(self._MyListView,ui.VIEW_MINE_LIST)
	local view_title_src = uikits.child(self._MyListView,ui.VIEW_MINE_PRO_SRC)
	local viewSize=view_title_list:getContentSize()
	local viewPosition=cc.p(view_title_list:getPosition())
	local viewParent=view_title_list:getParent()
	view_title_list:setVisible(false)	
	if self.pro_info and type(self.pro_info) == 'table' and #self.pro_info>0 then
		self.view_order_list = mconfig.createRankView(viewParent,viewPosition,viewSize,view_title_src,function(item,data)
			item:setVisible(true)	
			local txt_mine_pro_gold_pay = uikits.child(item,ui.TXT_MINE_PRO_GOLD_PAY)
			local txt_mine_pro_date = uikits.child(item,ui.TXT_MINE_PRO_DATE)
			local pic_mine_pro = uikits.child(item,ui.PIC_MINE_PRO)
			local txt_mine_pro_name = uikits.child(item,ui.TXT_MINE_PRO_NAME)
			local txt_mine_pro_des = uikits.child(item,ui.TXT_MINE_PRO_DES)
			local txt_mine_pro_gold_sell = uikits.child(item,ui.TXT_MINE_PRO_GOLD_SELL)
			local but_pay = uikits.child(item,ui.BUTTON_PAY)
			local but_cancel = uikits.child(item,ui.BUTTON_CANCEL)
			local but_detail = uikits.child(item,ui.BUTTON_DETAIL)
			but_pay.order_id = data.ordernumber
			but_cancel.order_id = data.ordernumber
			but_detail.order_id = data.ordernumber
			but_detail.tag = data.orderstatus
			but_pay:setVisible(false)
			but_cancel:setVisible(false)
			
			local txt_mine_pro_no_pay = uikits.child(item,ui.TXT_MINE_PRO_NO_PAY)
			local txt_mine_pro_pay_ok = uikits.child(item,ui.TXT_MINE_PRO_PAY_OK)
			local txt_mine_pro_sending = uikits.child(item,ui.TXT_MINE_PRO_SENDING)
			local txt_mine_pro_ok = uikits.child(item,ui.TXT_MINE_PRO_OK)
			txt_mine_pro_no_pay:setVisible(false)
			txt_mine_pro_pay_ok:setVisible(false)
			txt_mine_pro_sending:setVisible(false)
			txt_mine_pro_ok:setVisible(false)

			txt_mine_pro_date:setString(data.createtime)
			txt_mine_pro_gold_pay:setString(data.totalamount..'金币')
			local orderstatus = tonumber(data.orderstatus)
			if orderstatus >= 0 and orderstatus < 100 then
				txt_mine_pro_no_pay:setVisible(true)
				but_pay:setVisible(true)
				but_cancel:setVisible(true)
			elseif orderstatus >= 100 and orderstatus < 200 then
				txt_mine_pro_pay_ok:setVisible(true)
			elseif orderstatus >= 200 and orderstatus < 300 then
				txt_mine_pro_ok:setVisible(true)
			elseif orderstatus >= 300 and orderstatus < 400 then
				txt_mine_pro_sending:setVisible(true)
			elseif orderstatus >= 400 and orderstatus < 500 then
				txt_mine_pro_ok:setVisible(true)
			end
			
			local tab_price = data.pro_list
			for j=1,#tab_price do
				if j == 1 then
					self:load_logo_pic(pic_mine_pro,tab_price[j].pro_img.img_url,tab_price[j].pro_id)
					txt_mine_pro_name:setString(tab_price[j].pro_name)
					txt_mine_pro_des:setString(tab_price[j].introduct)
					local price = tab_price[j].price 
					for i = 1, #price do
						if price[i].price_type == 3 then
							txt_mine_pro_gold_sell:setString(price[i].money..'金币')	
						end
					end
				end
			end			


			uikits.event(but_pay,	
				function(sender,eventType)
					self.order_no = sender.order_id
					self:show_pay_view()
				end,"click")	

			uikits.event(but_cancel,	
				function(sender,eventType)	
					send_data = {}
					send_data.v1 = sender.order_id

					mconfig.post_data(self._MyListView,'cancelorder',send_data,function(t,v)
						if t and t == 200 then
							self:resetview()
						else
							mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
								if e == mconfig.OK then
								end
							end,'提示',v)								
						end
					end)					
				end,"click")

			uikits.event(but_detail,	
				function(sender,eventType)	
					send_data = {}
					send_data.v1 = sender.order_id

					mconfig.post_data(self._MyListView,'GetOrderDetail',send_data,function(t,v)
						if t and t == 200 then
							self:show_order_info(v,sender.tag)
						else
							mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
								if e == mconfig.OK then
								end
							end,'提示',v)								
						end
					end)	
				end,"click")
					
			end,function(waitingNode,afterReflash)
			print('#self.pro_info:::::::'..#self.pro_info)
			print('self.pro_num:::::::'..self.pro_num)
			if #self.pro_info <self.pro_num and self.is_first == false then
				self.page_index = self.page_index +1
				local send_data = {}
				send_data.page_size = 50
				send_data.page_index = self.page_index
				send_data.order_status = -1
				mconfig.post_data(self._MyListView,'GetOrderList',send_data,function(t,v)
					if t and t == 200 then
						--self.pro_info = v.order_list
						for i=1,#v.order_list do
							self.pro_info[#self.pro_info+1] = v.order_list[i]
						end			
						afterReflash(self.pro_info)	
					else
						mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
							if e == mconfig.OK then
							end
						end,'提示',v)								
					end
				end)
			elseif self.is_first == true then
				self.is_first = false
				afterReflash(self.pro_info)	
			end
		end)		
	else

	end		
	--print('self.inner_pos333333333333::::::'..self.inner_pos.y)
	if self.inner_pos then
		self:set_innerpos()
	end	
end	

function MyListView:save_innerpos()
	self.inner_pos = self.view_order_list:getContentOffset()
end

function MyListView:set_innerpos()
	local allsize = self.view_order_list:getContentSize()
	local viewParent = self.view_order_list:getParent()
	--[[print('allsize11111111::::::'..viewParent:getContentSize().height-self.view_order_list:getContentSize().height)
	print('allsize222222222::::::'..self.inner_pos.y)
	print('allsize333333333::::::'..viewParent:getContentSize().height)
	print('allsize444444444::::::'..self.view_order_list:getContentSize().height)--]]
	self.inner_pos.y = math.max(viewParent:getContentSize().height-self.view_order_list:getContentSize().height,self.inner_pos.y)

	self.view_order_list:setContentOffset(self.inner_pos)
	self.inner_pos = nil
end

function MyListView:resetview()
	self:save_innerpos()
	self.view_order_list:removeFromParent()
	self.page_index = 1
	self.is_first = true
	local send_data = {}
	send_data.page_size = 50
	send_data.page_index = self.page_index
	send_data.order_status = -1
	mconfig.post_data(self._MyListView,'GetOrderList',send_data,function(t,v)
		if t and t == 200 then
			self.pro_info = v.order_list
			self.pro_num = v.totals
			local txt_pro_num = uikits.child(self._MyListView,ui.TXT_MINE_LIST_NUM)
			txt_pro_num:setString(self.pro_num..'件')
			self:show_list()	
		else
			mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
				if e == mconfig.OK then
				end
			end,'提示',v)								
		end
	end)
end

function MyListView:getdatabyurl()
	self.page_index = 1
	self.is_first = true
	local send_data = {}
	send_data.page_size = 50
	send_data.page_index = self.page_index
	send_data.order_status = -1
	mconfig.post_data(self._MyListView,'GetOrderList',send_data,function(t,v)
		if t and t == 200 then
			self.pro_info = v.order_list
			self.pro_num = v.totals
			self:show_list()	
		else
			mconfig.messagebox(self._MyListView,mconfig.DIY_MSG,function(e)
				if e == mconfig.OK then
				end
			end,'提示',v)								
		end
	end)	
end

function MyListView:init()	
	cc_setUIOrientation(2)
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		uikits.initDR{width=1080,height=1920}
		self._MyListView = uikits.fromJson{file=ui.MyListView_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--mconfig.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--mconfig.initDR{width=1080,height=1920}
		end
		--self._MyListView = uikits.fromJson{file_9_16=ui.MyListView_FILE,file_3_4=ui.MyListView_FILE_3_4}
		self._MyListView = mconfig.fromJson{file_9_16=ui.MyListView_FILE_3_4,file_3_4=ui.MyListView_FILE}	
	end

	self:addChild(self._MyListView)
	--self:show_list()
	self:getdatabyurl()
	local txt_pro_num = uikits.child(self._MyListView,ui.TXT_MINE_LIST_NUM)
	txt_pro_num:setString(self.pro_num..'件')
	
	local but_quit = uikits.child(self._MyListView,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function MyListView:release()

end
return {
create = create,
}