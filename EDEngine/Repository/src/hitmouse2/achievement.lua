local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local login = require "login"
local global = require "hitmouse2/global"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/chengjiu.json',
	FILE_3_4 = 'hitmouse2/chengjiu43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	LIST = 'leib',
	TOP = 'suju',
	TOP_ACC_MATCH = 'zsai',
	TOP_ACC_LEVEL = 'guanc',
	TOP_ACC_ACHI = 'zjiang',
	TOP_ACC_FINAL = 'jues',
	TOP_ACC_LEVEL_RATE = 'cglu',
	TOP_ACC_GET_ACHI = 'weiling',
	ITEM = 'ji1',
	ITEM_CAPTION = 'saim',
	ITEM_DATE = 'shij',
	ITEM_RANK = 'mingc',
	ITEM_RANK_PREFIX = '',
	ITEM_RANK_SUFFIX = '',
	ITEM_BUY_PLANE = 'weiyou',
	ITEM_BUY_BUT = 'youji',
	ITEM_COST = 'qian',
	ITEM_MAILLING_PLANE = 'zhengzai',
	ITEM_MAILDONE_PLANE = 'yiyou',
	ITEM2 = 'leib/ji2',
	EXPRESS_COM = "kuaidi",
	EXPRESS_ID = "danhao",
	POST_process = "wuliu",
	
	EXPRESS_PLANE = 'youji',
	PHONE_PLANE = 'gaishouji',
	ADDRESS_PLANE = 'gaidizhi',
	USER_NAME = 'xinxi/mingz',
	USER_ADDRESS = 'xinxi/xxbj',
	USER_PHONE = 'xinxi/fmsj',
	MOTIFY_ADDRESS = 'xinxi/xiugai',
	MOTIFY_PHONE = 'xinxi/gaisj',
	
	CANCEL = 'qux',
	OK = 'quer',
	
	ADDRESS_INPUT = 'bai/mingz',
	PHONE_NUM = 's',
	PHONE_INPUT = 'bai/bai2/su',
	PHONE_BACKSPACE = 'tui',
	PHONE_DELETE = 'shanc',
	
	WEIXING_PAY = 'weix',
	ZHIFUBAO_PAY = 'zfb',
	PAY_COST = 'qian',
	
	LOGO = "toux",
	NAME = "toux/mingz",
}

local achievement = uikits.SceneClass("achievement",ui)
local _chi = "次"
function achievement:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		local item2 = uikits.child(self._root,ui.ITEM2)
		if item2 then
			item2:setVisible(false)
		end
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM},{ui.TOP})
		self._scrollview:clear()
		local address_plane = uikits.child(self._root,ui.ADDRESS_PLANE)
		address_plane:setVisible(false)
		local phone_plane = uikits.child(self._root,ui.PHONE_PLANE)
		phone_plane:setVisible(false)
		local plane = uikits.child(self._root,ui.EXPRESS_PLANE)
		plane:setVisible(false)
		local top = self._scrollview._tops[1]
		
		http.load_logo_pic(uikits.child(top,ui.LOGO),global.getAttachChildUID() or 0)
		uikits.child(top,ui.NAME):setString(state.get_name() or '-')
		
		local send_data = {}
		kits.log("do achievement:init...")
		http.post_data(self._root,'user_award',send_data,function(t,v)
			if t and t==200 and v then
				http.logTable(v,1)
				if v.v1 and v.v7 and type(v.v7)=='table' then
					local top = self._scrollview._tops[1]
					top:setVisible(true)
					uikits.child(top,ui.TOP_ACC_MATCH):setString((v.v1 or "-").._chi)
					uikits.child(top,ui.TOP_ACC_LEVEL):setString((v.v3 or "-").._chi)
					uikits.child(top,ui.TOP_ACC_ACHI):setString((v.v5 or "-").._chi)
					uikits.child(top,ui.TOP_ACC_FINAL):setString((v.v2 or "-").._chi)
					uikits.child(top,ui.TOP_ACC_LEVEL_RATE):setString((v.v4 or "-"))
					uikits.child(top,ui.TOP_ACC_GET_ACHI):setString((v.v6 or "-").._chi)

					for i,v in pairs(v.v7) do
						self:additem(v)
					end					
					self._scrollview:relayout()
				else
					http.messagebox(self,http.DIY_MSG,function(s)
						local Director = cc.Director:getInstance()
						Director:endToLua()
					end,"user_award return invalid value")
				end
			else
				kits.log("ERROR user_award failed!")
			end
		end,true)	
		self._scrollview._tops[1]:setVisible(false)
	end
end

local function pushWuliuScene(expressName,itemName,expressID,postOrder)
	local s
	
	if uikits.get_factor()==uikits.FACTOR_9_16 then
		s = 1
	else
		s = 2
	end
	if expressName and itemName and expressID and postOrder then
		require("wuliu/kuaidi100").showItemExpress(s,
			expressName,
			itemName,
			"hitmouse2/jiangz.png",
			expressID,
			postOrder,
			function()
			end)
	else
		kits.log("WARNING : pushWuliuScene "..tostring(expressName)..","..tostring(itemName)..","..tostring(expressID)..","..tostring(postOrder))
	end
end

function achievement:additem(v)
	if not v then
		kits.log("user_award v7 invalid")
		return
	end
	local item = self._scrollview:additem(1)
	local buy_plane = uikits.child(item,ui.ITEM_BUY_PLANE)
	local mailling_plane = uikits.child(item,ui.ITEM_MAILLING_PLANE)
	local maildone_plane = uikits.child(item,ui.ITEM_MAILDONE_PLANE)
	local pp_but = uikits.child(maildone_plane,ui.POST_process)
	
	pp_but:setVisible(false)
	buy_plane:setVisible(false)
	maildone_plane:setVisible(false)
	mailling_plane:setVisible(false)	
	if v.post and v.post==0 then
		--暂时关闭购买按键
		if v.pay==0 then
			--为付款
			local button = uikits.child(buy_plane,ui.ITEM_BUY_BUT)
			buy_plane:setVisible(true)
			button:setVisible(true)
			uikits.child(buy_plane,ui.ITEM_COST):setString((v.item_cost or "-").."乐币")
			uikits.event( button,function(sender)
				self:openMailUI( v,function(b,msg)
					if b then
						--支付成功
						buy_plane:setVisible(false)
						mailling_plane:setVisible(true)
						uikits.child(mailling_plane,"w1"):setString("订单正在处理...")
						uikits.child(mailling_plane,"w2"):setString("")						
					else
						--支付失败
					end
				end )
			end)
		else
			--已经付款待处理
			mailling_plane:setVisible(true)
			uikits.child(mailling_plane,"w1"):setString(v.paystate_title or "-")
			uikits.child(mailling_plane,"w2"):setString(v.paystate_desc or "-")
			if v.post_url and string.len(v.post_url) > 0 then
				pp_but:setVisible(true)
				uikits.event(pp_but,function(sender)
					--cc_openURL(v.post_url)
					pushWuliuScene(v.expressName,v.itemName,v.expressCode,v.postOrder)
				end)
			end
		end
	elseif v.post and v.post==1 then
		maildone_plane:setVisible(true)
		uikits.child(maildone_plane,ui.EXPRESS_COM):setString(v.express_com or "-")
		uikits.child(maildone_plane,ui.EXPRESS_ID):setString(v.express_id or "-")
		if v.post_url and string.len(v.post_url) > 0 then
			pp_but:setVisible(true)
			uikits.event(pp_but,function(sender)
				--cc_openURL(v.post_url)
				pushWuliuScene(v.expressName,v.itemName,v.expressCode,v.postOrder)
			end)
		end		
	elseif v.post and v.post==2 then
		mailling_plane:setVisible(true)	
	end
	uikits.child(item,ui.ITEM_CAPTION):setString(v.name or "-")
	uikits.child(item,ui.ITEM_DATE):setString(v.gettime or "-")
	uikits.child(item,ui.ITEM_RANK):setString(v.rank or "-")
end

function achievement:notify_paypay(ispay,order,item_id)
	local send_data = {v1=item_id,v2=order,v3=ispay}
	kits.log("do achievement:notify_paypay...")
	http.post_data(self._root,'notify_buy_result',send_data,function(t,v)
		http.logTable(v,1)
		if t and t==200 and v then
			if not v.v1 then
				kits.log("ERROR notify_buy_result return invalid result")
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
			   if e==http.RETRY then
					self:notify_paypay(ispay,order,item_id)
				else
					uikits.popScene()
				end
			end,v)		
		end		
	end,true)
end

function achievement:paypay(order,total_money,product_info,notify,payurl,item_id)
	local pay = require "pay"
	kits.log("do achievement:paypay...")
	if payurl then
		kits.log("paypay url "..tostring(payurl))
		local s,msg = pay.byurl(
			payurl,
			function(b,msg)
				kits.log("paypay b = "..tostring(b).." msg="..tostring(msg))
				if b and notify then
					notify(b,msg)
				end
				self:notify_paypay(b,order,item_id)
				--提示用户是否支付成功
				local errormsg
				if b then
					errormsg = "支付成功"
				else
					if msg and type(msg)=='string' and string.len(msg)>0 then
						errormsg = msg
					elseif not b then
						errormsg = "因为网络原因导致支付失败."
					else
						errormsg = "支付失败"
					end
				end
				http.messagebox(self._root,http.OK_MSG,function(e)
					end,tostring(errormsg))
			end
		)
		if not s then
			self:notify_paypay(false,order,item_id)
			http.messagebox(self._root,http.OK_MSG,function(e)
					end,tostring(msg))
		end
	end
end

function achievement:pay(type,vv,notify)
	local send_data = {v1=vv.item_id,v2=vv.address,v3=vv.phone,v4=type}
	kits.log("do achievement:pay...")
	http.logTable(vv,1)
	http.post_data(self._root,'buy_item',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			if v.v1 and notify then
				notify(v.v1,v.v2 or 'buy_item return v.v2 = nil')
			end			
			if v.v1 then
				--self:paypay(v.v3,vv.item_cost,vv.product_info,notify,v.v4,vv.item_id)
				--废弃以前的购买接口，这里已经成功付款
				--v2(string): 失败的原因描述
				--v3(int):如果是兑换操作返回要增加的银币数量
				http.messagebox(self._root,http.OK_MSG,function(e)
					end,"支付成功")
			else
				http.messagebox(self._root,http.OK_MSG,function(e)
				end,tostring(v.v2 or 'buy_item return v.v2 = nil'))			
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
			   if e==http.RETRY then
					self:pay(type,v,notify)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end,true)	
end

function achievement:openMailUI( v,notify )
	local plane = uikits.child(self._root,ui.EXPRESS_PLANE)
	plane:setVisible(true)
	plane:setZOrder(10)
	uikits.child(plane,ui.USER_NAME):setString(state.get_name() or '-')
	uikits.child(plane,ui.USER_ADDRESS):setString(v.address or '-')
	uikits.child(plane,ui.USER_PHONE):setString(v.phone or '-')
	uikits.child(plane,ui.PAY_COST):setString((v.item_cost or "-").."乐币")
	uikits.event(uikits.child(plane,ui.WEIXING_PAY),function(sender) --pay
		v.address = uikits.child(plane,ui.USER_ADDRESS):getString()
		v.phone = uikits.child(plane,ui.USER_PHONE):getString()
		if v.address and v.phone and string.len(v.address)>12 and string.len(v.phone)>6 then
			plane:setVisible(false)
			self:pay(1,v,notify)
		else
			local text
			if string.len(v.address)<=12 then
				text="请正确填写地址栏"
			else
				text="请正确填写手机号码"
			end
			http.messagebox(plane,http.OK_MSG,
				function()end,text)
		end
	end)
	uikits.event(uikits.child(plane,ui.ZHIFUBAO_PAY),function(sender) --cancel
		plane:setVisible(false)
	end)	
	uikits.event(uikits.child(plane,ui.MOTIFY_ADDRESS),function(sender)
		local address_plane = uikits.child(self._root,ui.ADDRESS_PLANE)	
		address_plane:setZOrder(20)
		address_plane:setVisible(true)
		local input = uikits.child(address_plane,ui.ADDRESS_INPUT)
		input:setText( v.address or '' )
		uikits.event(uikits.child(address_plane,ui.CANCEL),function(sender)
			address_plane:setVisible(false)
		end)
		uikits.event(uikits.child(address_plane,ui.OK),function(sender)
			address_plane:setVisible(false)
			v.address = input:getStringValue()
			uikits.child(plane,ui.USER_ADDRESS):setString(v.address or '-')
		end)		
	end)
	uikits.event(uikits.child(plane,ui.MOTIFY_PHONE),function(sender)
		local phone_plane = uikits.child(self._root,ui.PHONE_PLANE)	
		local number = uikits.child(phone_plane,ui.PHONE_INPUT)
		number:setString( v.phone or '' )
		phone_plane:setVisible(true)	
		phone_plane:setZOrder(20)
		uikits.event(uikits.child(phone_plane,ui.CANCEL),function(sender)
			phone_plane:setVisible(false)
		end)
		uikits.event(uikits.child(phone_plane,ui.OK),function(sender)
			phone_plane:setVisible(false)
			v.phone = number:getString()
			uikits.child(plane,ui.USER_PHONE):setString(v.phone or '-')
		end)				
		for i=0,9 do
			uikits.event( uikits.child(phone_plane,ui.PHONE_NUM..i),function(sender)
				local text = number:getString()
				number:setString( text..i )
			end)
		end
		uikits.event(uikits.child(phone_plane,ui.PHONE_BACKSPACE),function(sender)
			local text = number:getString()
			if string.len(text) > 0 then
				number:setString( string.sub(text,1,string.len(text)-1) )
			end
		end)
		uikits.event(uikits.child(phone_plane,ui.PHONE_DELETE),function(sender)
			number:setString('')
		end)		
	end)	
end

function achievement:release()
end

return achievement