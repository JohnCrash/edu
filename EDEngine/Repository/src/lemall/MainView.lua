local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local ljshell = require "ljshell"
local productinfoview = require 'lemall/ProductInfoView'
local mconfig = require 'lemall/MallConfig'
local forgetpwview = require 'lemall/ForgetPwView'
local mylistview = require 'lemall/MyListView'

local MainView = class("MainView")
MainView.__index = MainView
local ui = {
	MainView_FILE = 'lemall/shouye.json',
	MainView_FILE_3_4 = 'lemall/shouye43.json',
	CHECK_ALL = 'ba/quanbu',
	CHECK_CAN = 'ba/wode',
	CHECK_MINE = 'ba/gouwu',
	
	VIEW_ALL = 'quanbu',
	VIEW_HOT = 'quanbu/remen',
	VIEW_HOT_VIEW1 = 'quanbu/remen/bai/sp1',
	PIC_HOT_VIEW1 = 'quanbu/remen/bai/sp1/tu',
	BUTTON_HOT_VIEW1 = 'quanbu/remen/bai/sp1/but_tu',
	VIEW_HOT_VIEW2 = 'quanbu/remen/bai/sp2',
	PIC_HOT_VIEW2 = 'quanbu/remen/bai/sp2/tu',
	BUTTON_HOT_VIEW2 = 'quanbu/remen/bai/sp2/but_tu',
	VIEW_HOT_VIEW3 = 'quanbu/remen/bai/sp3',
	PIC_HOT_VIEW3 = 'quanbu/remen/bai/sp3/tu',
	BUTTON_HOT_VIEW3 = 'quanbu/remen/bai/sp3/but_tu',
	VIEW_PRO_ALL_SRC = 'quanbu/sp4',
	PIC_PRO_ALL = 'tu',
	TXT_PRO_ALL_NAME = 'mingz',
	TXT_PRO_ALL_DES = 'jies',
	TXT_PRO_ALL_PRICE = 'jiage',
	VIEW_PRO_ALL_DIS = 'zhekou',
	TXT_PRO_ALL_DIS = 'zhekou/chuxiao',
	BUTTON_PRO_ALL = 'but_pro',
	
	VIEW_CAN = 'keduihuan',
	VIEW_PRO_CAN_SRC = 'keduihuan/sp4',
	
	VIEW_MINE = 'wode',
	VIEW_MINE_REPW = 'wode/mima',
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
	VIEW_MINE_LIST = 'wode/qingdan',
	TXT_MINE_LIST_NUM = 'wode/qingdan/jian',
	
	BUT_QUIT = 'top/back',
	TXT_GOLD_NUM = 'top/yinbi',
}

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),MainView)		
	cur_layer.mall_type = 1
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
function MainView:load_logo_pic(handle,file_url,pid)

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

local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/current'
local get_child_info_url = 'http://api.lejiaolexue.com/rest/user/current/closefriend/child'
	
local pro_space_all = 10	
--[[	VIEW_MINE = 'wode',
	VIEW_MINE_REPW = 'wode/mima',
	BUTTON_MINE_REPW = 'wode/mima/but_pro',
	VIEW_MINE_LIST_INFO = 'wode/tu',
	TXT_MINE_LIST_NUM = 'wode/tu/jian',
	VIEW_MINE_PRO_SRC = 'wode/sp1',
	TXT_MINE_PRO_GOLD_PAY = 'jinbi',
	TXT_MINE_PRO_DATE = 'shijian',
	PIC_MINE_PRO = 'tu',
	TXT_MINE_PRO_NAME = 'ming',
	TXT_MINE_PRO_DES = 'jieshao',
	TXT_MINE_PRO_GOLD_SELL = 'ming_1',--]]
	
function MainView:show_mine_view(list_num)
	--[[local view_mine = uikits.child(self._MainView,ui.VIEW_MINE)
	for i=1,100 do
		local cur_view = view_mine:getChildByTag(10000+i)
		if not cur_view then
			print('111111111111')
			break
		end
		view_mine:removeChildByTag(10000+i)
	end
	
	cc.TextureCache:getInstance():removeUnusedTextures()
	local view_mine_repw = uikits.child(self._MainView,ui.VIEW_MINE_REPW)
	local view_mine_list_info = uikits.child(self._MainView,ui.VIEW_MINE_LIST_INFO)
	local view_mine_pro_src = uikits.child(self._MainView,ui.VIEW_MINE_PRO_SRC)
	
	local size_mine = view_mine:getContentSize()
	local size_mine_repw = view_mine_repw:getContentSize()
	local size_mine_list_info = view_mine_list_info:getContentSize()
	local size_mine_pro_src = view_mine_pro_src:getContentSize()
	local scroll_size = view_mine:getInnerContainerSize()
	
	if size_mine_repw.height + size_mine_list_info.height + pro_space_all+(size_mine_pro_src.height+pro_space_all)*(#self.pro_list_mine) > size_mine.height then
		scroll_size.height = size_mine_repw.height + size_mine_list_info.height+ pro_space_all + (size_mine_pro_src.height+pro_space_all)*#self.pro_list_mine
		view_mine_repw:setPositionY(scroll_size.height-size_mine_repw.height/2)
		view_mine_list_info:setPositionY(scroll_size.height-size_mine_repw.height-size_mine_list_info.height/2-pro_space_all)
	end
	view_mine:setInnerContainerSize(scroll_size)	
	local txt_pro_num = uikits.child(self._MainView,ui.TXT_MINE_LIST_NUM)
	txt_pro_num:setString(tostring(#self.pro_list_mine)..'件')
	
	local pos_y_start = scroll_size.height - size_mine_repw.height - size_mine_list_info.height-pro_space_all - size_mine_pro_src.height - pro_space_all
	view_mine_pro_src:setVisible(false)	
	for i=1 , #self.pro_list_mine do
		local cur_pro = view_mine_pro_src:clone()
		cur_pro:setVisible(true)
		cur_pro:setPositionY(pos_y_start-(i-1)*(size_mine_pro_src.height + pro_space_all))
		view_mine:addChild(cur_pro,1,10000+i)

		local pic_pro = uikits.child(cur_pro,ui.PIC_MINE_PRO)
		local txt_pro_name = uikits.child(cur_pro,ui.TXT_MINE_PRO_NAME)
		local txt_pro_des = uikits.child(cur_pro,ui.TXT_MINE_PRO_DES)
		local txt_pro_sell = uikits.child(cur_pro,ui.TXT_MINE_PRO_GOLD_SELL)
		local txt_pro_pay = uikits.child(cur_pro,ui.TXT_MINE_PRO_GOLD_PAY)
		local txt_pro_date = uikits.child(cur_pro,ui.TXT_MINE_PRO_DATE)
		
		txt_pro_date:setString(self.pro_list_mine[i].createtime)
		txt_pro_pay:setString(self.pro_list_mine[i].totalamount..'金币')

		local tab_price = self.pro_list_mine[i].prolist
		for j=1,#tab_price do
			self:load_logo_pic(pic_pro,tab_price[j].logimg,tab_price[j].pro_id)
			txt_pro_name:setString(tab_price[j].pro_name)
			txt_pro_des:setString(tab_price[j].remark)
			txt_pro_sell:setString(tab_price[j].totalamount..'金币')
		end
	end
	--]]
	local view_mine_list = uikits.child(self._MainView,ui.VIEW_MINE_LIST)
	uikits.event(view_mine_list,	
		function(sender,eventType)
			uikits.pushScene( mylistview.create(self.pro_list_mine,self.pro_list_num) )
	end)		
	
	local view_mine_repw = uikits.child(self._MainView,ui.VIEW_MINE_REPW)
	local txt_pro_num = uikits.child(self._MainView,ui.TXT_MINE_LIST_NUM)
	txt_pro_num:setString(tostring(list_num)..'件')
	--local but_mine_repw = uikits.child(self._MainView,ui.BUTTON_MINE_REPW)
	uikits.event(view_mine_repw,	
		function(sender,eventType)
			uikits.pushScene( forgetpwview.create() )
	end)	
end

function MainView:show_can_product()
	
	local pos_start,pos_end
	local function touchEventPic(sender,eventType)
		if eventType == ccui.TouchEventType.began then
			pos_start = sender:getTouchBeganPosition()
		elseif eventType == ccui.TouchEventType.ended then
			pos_end = sender:getTouchBeganPosition()
			if math.sqrt((pos_end.x-pos_start.x)*(pos_end.x-pos_start.x)+(pos_end.y-pos_start.y)*(pos_end.y-pos_start.y)) < 10 then
				uikits.pushScene( productinfoview.create(sender.pro_id) )
			end
		end
		
	end

	local view_all = uikits.child(self._MainView,ui.VIEW_CAN)
	local view_pro_all_src = uikits.child(self._MainView,ui.VIEW_PRO_CAN_SRC)
	
	local size_all = view_all:getContentSize()
	local size_pro_src = view_pro_all_src:getContentSize()
	local scroll_size = view_all:getInnerContainerSize()

	if (size_pro_src.height+pro_space_all)*(#self.pro_list_can) > size_all.height then
		scroll_size.height = (size_pro_src.height+pro_space_all)*#self.pro_list_can
	end

	view_all:setInnerContainerSize(scroll_size)
	
	local pos_y_start = scroll_size.height - size_pro_src.height - pro_space_all
	view_pro_all_src:setVisible(false)

	for i=1 , #self.pro_list_can do
	--for i=1 , 10 do
		local cur_pro = view_pro_all_src:clone()
		cur_pro:setVisible(true)
		cur_pro:setPositionY(pos_y_start-(i-1)*(size_pro_src.height + pro_space_all))
		view_all:addChild(cur_pro)
		local pic_pro = uikits.child(cur_pro,ui.PIC_PRO_ALL)
		local txt_pro_name = uikits.child(cur_pro,ui.TXT_PRO_ALL_NAME)
		local txt_pro_des = uikits.child(cur_pro,ui.TXT_PRO_ALL_DES)
		local txt_pro_price = uikits.child(cur_pro,ui.TXT_PRO_ALL_PRICE)
		local view_pro_dis = uikits.child(cur_pro,ui.VIEW_PRO_ALL_DIS)
		local txt_pro_dis = uikits.child(cur_pro,ui.TXT_PRO_ALL_DIS)
		self:load_logo_pic(pic_pro,self.pro_list_can[i].pro_img,self.pro_list_can[i].pro_id)
		txt_pro_name:setString(self.pro_list_can[i].pro_name)
		txt_pro_des:setString(self.pro_list_can[i].introduct)
		local tab_price = self.pro_list_can[i].sell_price
		for j=1,#tab_price do
			if tab_price[j].price_type == 3 then
				txt_pro_price:setString(tab_price[j].money..'金币')
				if self.pro_list_can[i].issales == 1 then
					view_pro_dis:setVisible(true)
					txt_pro_dis:setString(tostring(tonumber(self.pro_list_can[i].disvalue)*10)..'折')
				else
					view_pro_dis:setVisible(false)
				end
			end
		end
		local but_pro = uikits.child(cur_pro,ui.BUTTON_PRO_ALL)
		but_pro.pro_id = self.pro_list_can[i].pro_id
		but_pro:addTouchEventListener(touchEventPic)
	end

end

function MainView:show_all_product()
	
	local pos_start,pos_end
	local function touchEventPic(sender,eventType)
		if eventType == ccui.TouchEventType.began then
			pos_start = sender:getTouchBeganPosition()
		elseif eventType == ccui.TouchEventType.ended then
			pos_end = sender:getTouchBeganPosition()
			if math.sqrt((pos_end.x-pos_start.x)*(pos_end.x-pos_start.x)+(pos_end.y-pos_start.y)*(pos_end.y-pos_start.y)) < 10 then
				uikits.pushScene( productinfoview.create(sender.pro_id) )
			end
		end
		
	end
		
	local view_all = uikits.child(self._MainView,ui.VIEW_ALL)
	local view_hot = uikits.child(self._MainView,ui.VIEW_HOT)
	local view_pro_all_src = uikits.child(self._MainView,ui.VIEW_PRO_ALL_SRC)
	
	local size_all = view_all:getContentSize()
	local size_hot = view_hot:getContentSize()
	local size_pro_src = view_pro_all_src:getContentSize()
	local scroll_size = view_all:getInnerContainerSize()

	if size_hot.height+(size_pro_src.height+pro_space_all)*(#self.pro_list) > size_all.height then
	--if size_hot.height+(size_pro_src.height+pro_space_all)*10 > size_all.height then
		scroll_size.height = size_hot.height+(size_pro_src.height+pro_space_all)*#self.pro_list
		view_hot:setPositionY(scroll_size.height-size_hot.height)
	end

	view_all:setInnerContainerSize(scroll_size)
	
	local pos_y_start = scroll_size.height - size_hot.height - size_pro_src.height - pro_space_all
	view_pro_all_src:setVisible(false)

	for i=1 , #self.pro_list do
	--for i=1 , 10 do
		local cur_pro = view_pro_all_src:clone()
		cur_pro:setVisible(true)
		cur_pro:setPositionY(pos_y_start-(i-1)*(size_pro_src.height + pro_space_all))
		view_all:addChild(cur_pro)
		local pic_pro = uikits.child(cur_pro,ui.PIC_PRO_ALL)
		local txt_pro_name = uikits.child(cur_pro,ui.TXT_PRO_ALL_NAME)
		local txt_pro_des = uikits.child(cur_pro,ui.TXT_PRO_ALL_DES)
		local txt_pro_price = uikits.child(cur_pro,ui.TXT_PRO_ALL_PRICE)
		local view_pro_dis = uikits.child(cur_pro,ui.VIEW_PRO_ALL_DIS)
		local txt_pro_dis = uikits.child(cur_pro,ui.TXT_PRO_ALL_DIS)
		self:load_logo_pic(pic_pro,self.pro_list[i].pro_img,self.pro_list[i].pro_id)
		txt_pro_name:setString(self.pro_list[i].pro_name)
		txt_pro_des:setString(self.pro_list[i].introduct)
		local tab_price = self.pro_list[i].sell_price
		for j=1,#tab_price do
			if tab_price[j].price_type == 3 then
				txt_pro_price:setString(tab_price[j].money..'金币')
				if self.pro_list[i].issales == 1 then
					view_pro_dis:setVisible(true)
					txt_pro_dis:setString(tostring(tonumber(self.pro_list[i].disvalue)*10)..'折')
				else
					view_pro_dis:setVisible(false)
				end
			end
		end
		local but_pro = uikits.child(cur_pro,ui.BUTTON_PRO_ALL)
		but_pro.pro_id = self.pro_list[i].pro_id
		but_pro:addTouchEventListener(touchEventPic)
	end

end
	
function MainView:show_hot_product()
	local pic_hot1 = uikits.child(self._MainView,ui.PIC_HOT_VIEW1)
	local pic_hot2 = uikits.child(self._MainView,ui.PIC_HOT_VIEW2)
	local pic_hot3 = uikits.child(self._MainView,ui.PIC_HOT_VIEW3)
	local but_hot1 = uikits.child(self._MainView,ui.BUTTON_HOT_VIEW1)
	local but_hot2 = uikits.child(self._MainView,ui.BUTTON_HOT_VIEW2)
	local but_hot3 = uikits.child(self._MainView,ui.BUTTON_HOT_VIEW3)
	if self.hot_pro_list[1] then
		self:load_logo_pic(pic_hot1,self.hot_pro_list[1].pro_img,self.hot_pro_list[1].pro_id)
		but_hot1.pro_id = self.hot_pro_list[1].pro_id	
	else
		pic_hot1:setVisible(false)
		but_hot1:setVisible(false)
	end
	if self.hot_pro_list[2] then
		self:load_logo_pic(pic_hot2,self.hot_pro_list[2].pro_img,self.hot_pro_list[2].pro_id)
		but_hot2.pro_id = self.hot_pro_list[2].pro_id	
	else
		pic_hot2:setVisible(false)
		but_hot2:setVisible(false)
	end
	if self.hot_pro_list[3] then
		self:load_logo_pic(pic_hot3,self.hot_pro_list[3].pro_img,self.hot_pro_list[3].pro_id)
		but_hot3.pro_id = self.hot_pro_list[3].pro_id	
	else
		pic_hot3:setVisible(false)
		but_hot3:setVisible(false)
	end
	
	uikits.event(but_hot1,	
		function(sender,eventType)	
		uikits.pushScene( productinfoview.create(sender.pro_id) )
	end)	
	uikits.event(but_hot2,	
		function(sender,eventType)	
		uikits.pushScene( productinfoview.create(sender.pro_id) )
	end)	
	uikits.event(but_hot3,	
		function(sender,eventType)	
		uikits.pushScene( productinfoview.create(sender.pro_id) )
	end)		
end

--local get_product_list_url = 'http://shoping.lejiaolexue.com/productlist.ashx'
local get_product_list_url = 'http://app.lejiaolexue.com/shopping/productlist.ashx'
--local get_orderlist_url = 'http://shoping.lejiaolexue.com/orderlist.ashx'
local get_orderlist_url = 'http://app.lejiaolexue.com/shopping/orderlist.ashx'


--根据商城模式获取商品列表
function MainView:getdatabyurl()
	local view_all = uikits.child(self._MainView,ui.VIEW_ALL)
	local view_can = uikits.child(self._MainView,ui.VIEW_CAN)
	local view_mine = uikits.child(self._MainView,ui.VIEW_MINE)
	local str_send_data = ''
	--全部商品模式
	if self.mall_type == 1 then
		view_all:setVisible(true)
		--获取热卖物品前三位
		local send_data = {}

		send_data.page_size = 3
		send_data.page_index = 1
		send_data.cate_id = 2
		mconfig.post_data(self._MainView,'GetProductList',send_data,function(t,v)
			if t and t == 200 then
				self.hot_pro_list = v.product_list
				self:show_hot_product()		
			else
				mconfig.messagebox(self._MainView,mconfig.DIY_MSG,function(e)
					if e == mconfig.OK then
					end
				end,'提示',v)								
			end
		end)
		--获取全部物品，按推荐顺序
		send_data = {}
		send_data.page_size = 100
		send_data.page_index = 1
		--send_data.cate_id = 2
		mconfig.post_data(self._MainView,'GetProductList',send_data,function(t,v)
			if t and t == 200 then
				self.pro_list = v.product_list
				self:show_all_product()			
			else
				mconfig.messagebox(self._MainView,mconfig.DIY_MSG,function(e)
					if e == mconfig.OK then
					end
				end,'提示',v)								
			end
		end)
	
	elseif self.mall_type == 2 then
		view_can:setVisible(true)
		local send_data = {}
		send_data.page_size = 100
		send_data.page_index = 1
		send_data.cate_id = 4
		mconfig.post_data(self._MainView,'GetProductList',send_data,function(t,v)
			if t and t == 200 then
				self.pro_list_can = v.product_list
				self:show_can_product()		
			else
				mconfig.messagebox(self._MainView,mconfig.DIY_MSG,function(e)
					if e == mconfig.OK then
					end
				end,'提示',v)								
			end
		end)
	elseif self.mall_type == 3 then
		view_mine:setVisible(true)
		local send_data = {}
		send_data.page_size = 1
		send_data.page_index = 1
		send_data.order_status = -1
		mconfig.post_data(self._MainView,'GetOrderList',send_data,function(t,v)
			if t and t == 200 then
				self.pro_list_mine = v.order_list
				self.pro_list_num = v.totals
				self:show_mine_view(v.totals)	
			else
				mconfig.messagebox(self._MainView,mconfig.DIY_MSG,function(e)
					if e == mconfig.OK then
					end
				end,'提示',v)								
			end
		end)
		--[[local loading = mconfig.circle(self._MainView)
		str_send_data = 'page_size=100&page_index=1'
		cache.post(get_orderlist_url,str_send_data,function(t,d)
			if loading then
				loading:removeFromParent()
			end
		--	print('d::::'..d)
			if t then
				local tb_result = json.decode(d)
				if tb_result.result == 0 then
					self.pro_list_mine = tb_result.orderlist
					self:show_mine_view()						
				else
					mconfig.messagebox(self._MainView,mconfig.DIY_MSG,function(e)
						if e == true then
							self:getdatabyurl()
						end
					end,'提示',tb_result.msg)						
				end
			else
				mconfig.messagebox(self._MainView,mconfig.ERR_NETWORK,function(e)
					if e == true then
						self:getdatabyurl()
					else
						
					end
				end)		
			end
		end)			--]]
	end
end


--复位商城view，根据商城模式显示对应的view
function MainView:formatgui()
	local view_all = uikits.child(self._MainView,ui.VIEW_ALL)
	local view_can = uikits.child(self._MainView,ui.VIEW_CAN)
	local view_mine = uikits.child(self._MainView,ui.VIEW_MINE)
	view_all:setVisible(false)
	view_can:setVisible(false)
	view_mine:setVisible(false)	
	if self.mall_type == 1 then
		view_all:setVisible(true)
	elseif self.mall_type == 2 then
		view_can:setVisible(true)
	elseif self.mall_type == 3 then
		view_mine:setVisible(true)
	end
	
end

--初始化gui
function MainView:initgui()
	local check_all = uikits.child(self._MainView,ui.CHECK_ALL)
	local check_can = uikits.child(self._MainView,ui.CHECK_CAN)
	local check_mine = uikits.child(self._MainView,ui.CHECK_MINE)
	local txt_gold_num = uikits.child(self._MainView,ui.TXT_GOLD_NUM)
	local gold_num = mconfig.get_gold_num()
	txt_gold_num:setString(gold_num)
	
	--设置复选框，保持只有一个复选框被选中
	local function setcheckbox()
		if self.mall_type == 1 then
			check_all:setSelectedState(false)
		elseif self.mall_type == 2 then 
			check_can:setSelectedState(false)
		elseif self.mall_type == 3 then
			check_mine:setSelectedState(false)
		end
	end
	
	--全部按钮
	uikits.event(check_all,	
		function(sender,eventType)
		--当点选为当前高亮，则重置高亮，不做其它处理	
		if self.mall_type == 1 then
			check_all:setSelectedState(true)
			return
		end
		--设置商城模式，复位对应的view
		setcheckbox()
		self.mall_type = 1
		self:formatgui()
		if not self.pro_list then
			self:getdatabyurl()
		end 
	end)	
	--可购买按钮
	uikits.event(check_can,	
		function(sender,eventType)	
		if self.mall_type == 2 then
			check_can:setSelectedState(true)
			return
		end
		setcheckbox()
		self.mall_type = 2
		self:formatgui()
		if not self.pro_list_can then
			self:getdatabyurl()
		end 
	end)	
	--我的view按钮
	uikits.event(check_mine,	
		function(sender,eventType)	
		if self.mall_type == 3 then
			check_mine:setSelectedState(true)
			return
		end
		setcheckbox()
		self.mall_type = 3
		self:formatgui()
		self:getdatabyurl()
	end)	
	
	--初始按钮设置。
	if self.mall_type == 1 then
		check_all:setSelectedState(true)
	elseif self.mall_type == 2 then
		check_can:setSelectedState(true)
	elseif self.mall_type == 3 then
		check_mine:setSelectedState(true)
	end	
	self:formatgui()
	self:getdatabyurl()
end

function MainView:init()	
	if self._MainView then
		if self.mall_type == 3 then
			self:getdatabyurl()
		end
		local txt_gold_num = uikits.child(self._MainView,ui.TXT_GOLD_NUM)
		local gold_num = mconfig.get_gold_num()
		txt_gold_num:setString(gold_num)
		return
	end
	if cc.Application:getInstance():getTargetPlatform() == cc.PLATFORM_OS_WINDOWS then
		mconfig.initDR{width=1080,height=1920}
		self._MainView = mconfig.fromJson{file_9_16=ui.MainView_FILE,file_3_4=ui.MainView_FILE}
	else
		if mconfig.get_factor() == mconfig.FACTOR_9_16 then
			mconfig.initDR{width=1080,height=1920}
			--uikits.initDR{width=1080,height=1440}
		else
			mconfig.initDR{width=1080,height=1440}
			--uikits.initDR{width=1080,height=1920}
		end
		--self._MainView = uikits.fromJson{file_9_16=ui.MainView_FILE,file_3_4=ui.MainView_FILE_3_4}
		self._MainView = mconfig.fromJson{file_9_16=ui.MainView_FILE_3_4,file_3_4=ui.MainView_FILE}
	end
	
	self:addChild(self._MainView)
	self:initgui()
	--self:getdatabyurl()
--	self:getconfig()
	local but_quit = uikits.child(self._MainView,ui.BUT_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	

end

function MainView:release()

end
return {
create = create,
}