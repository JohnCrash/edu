require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")
local protocol=require("qwxt/protocol")
local popup=require("qwxt/popup")

local JiangzhuangScene=public.newScene("JiangzhuangScene")

local mailPrice=2000

--加载UI
function JiangzhuangScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--用tableview速度快很多
	local jiangzhuangView=ccui.Helper:seekWidgetByTag(layout,15163)
	local item=ccui.Helper:seekWidgetByTag(jiangzhuangView,15164)
	item:retain()
	self.jiangzhuangView=require("qwxt/rank").createTableView(jiangzhuangView:getParent(),cc.p(jiangzhuangView:getPosition()),jiangzhuangView:getContentSize(),item,function(item,data,index)
		--奖状名
		ccui.Helper:seekWidgetByTag(item,15165):setString(data.name)
		--获得条件
		ccui.Helper:seekWidgetByTag(item,15185):setString(data.condition)
		--邮寄按扭
		local btn=ccui.Helper:seekWidgetByTag(item,15172)
		public.buttonEvent(btn,function(sender,event)
			self.currentData=data
			self.currentIndex=index
			ccui.Helper:seekWidgetByTag(self.mailInfo,32700):setString(mailPrice.."乐币")
			self.mailInfo:setVisible(true)
		end)
		btn:setVisible(false)
		--查看物流按钮
		ccui.Helper:seekWidgetByTag(item,33221):setTouchEnabled(true)
		public.buttonEvent(ccui.Helper:seekWidgetByTag(item,33221),function(sender,event)
			local function showExpressInfo(expressInfo)
				if expressInfo==null then return end
				local waiting=true
				public.showWaiting(nil,function()
					while waiting do
						coroutine.yield()
					end
				end,_,"正在查询快递......")
				require("wuliu/kuaidi100").showItemExpress((globalSettings.wideScreen and 1) or 2,expressInfo.express_name,data.name,data.image,expressInfo.express_code,expressInfo.express_order,function()
					waiting=false
				end)
			end
			if data.expressInfo==nil then
				protocol.getExpressInfo(data.id,function(success,obj)
					if success and obj then
						data.expressInfo=obj
					end
				end,{node=self,onFinished=function()
					showExpressInfo(data.expressInfo)
				end,text="正在查询快递......"})
			else
				showExpressInfo(data.expressInfo)
			end
		end)
		ccui.Helper:seekWidgetByTag(item,15202):setVisible(false)
		ccui.Helper:seekWidgetByTag(item,15206):setVisible(false)
		ccui.Helper:seekWidgetByTag(item,15170):setVisible(false)
		ccui.Helper:seekWidgetByTag(item,15171):setVisible(false)
		ccui.Helper:seekWidgetByTag(item,20466):setVisible(false)
		ccui.Helper:seekWidgetByTag(item,33221):setVisible(false)
		ccui.Helper:seekWidgetByTag(item,33752):setVisible(false)
		if data.userData==nil then
			--奖状图片
			ccui.Helper:seekWidgetByTag(item,15168):loadTexture(data.image1)
		else
			--奖状图片
			ccui.Helper:seekWidgetByTag(item,15168):loadTexture(data.image)
			--获得时间
			ccui.Helper:seekWidgetByTag(item,20466):setVisible(false)
			ccui.Helper:seekWidgetByTag(item,15170):setVisible(true)
			ccui.Helper:seekWidgetByTag(item,15171):setVisible(true)
			local t=os.date("*t",public.dateTimeFromString("(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)",data.userData.get_time))
			ccui.Helper:seekWidgetByTag(item,15171):setString(string.format("%d年%d月%d日",t.year,t.month,t.day))
			--邮寄状态
			if data.userData.mail_state==0 then
				--未申请
				btn:setVisible(true)
				btn:setTouchEnabled(true)
			elseif data.userData.mail_state==1 then
				--支付成功，等待邮寄
				ccui.Helper:seekWidgetByTag(item,15206):setVisible(true)
			elseif data.userData.mail_state==2 then
				--已寄出
				ccui.Helper:seekWidgetByTag(item,15202):setVisible(true)
				ccui.Helper:seekWidgetByTag(item,33221):setVisible(true)
			elseif data.userData.mail_state==3 then
				--邮寄完成
				ccui.Helper:seekWidgetByTag(item,33752):setVisible(true)
			end
		end
	end)
	item:release()
	jiangzhuangView:removeFromParent()
	self.jiangzhuangView:setData(globalSettings.jiangzhuangList)

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,12004),function(sender,event)
		self:onKeyBack()
	end)

	--邮寄信息
	self.mailInfo=ccui.Helper:seekWidgetByTag(layout,29272)
	self.mailInfo:setTouchEnabled(true)
	self.mailInfo:setVisible(false)
	self.mailReceiver=ccui.Helper:seekWidgetByTag(self.mailInfo,29803)
	self.mailReceiver:setPlaceHolder("请输入收件人姓名")
	self.mailAddress=ccui.Helper:seekWidgetByTag(self.mailInfo,29284)
	self.mailAddress:setPlaceHolder("请输入详细邮寄地址")
	self.mailPhoneNumber=ccui.Helper:seekWidgetByTag(self.mailInfo,29288)
	self.mailPhoneNumber:setPlaceHolder("请输入联系手机号码")
	public.buttonEvent(ccui.Helper:seekWidgetByTag(self.mailInfo,29290),function(sender,event)
		self.mailInfo:setVisible(false)
	end)
	public.buttonEvent(ccui.Helper:seekWidgetByTag(self.mailInfo,29289),function(sender,event)
		local receiver=self.mailReceiver:getStringValue()
		if receiver==nil or receiver=="" then
			popup.tip("请输入收件人姓名")
			return
		end
		local address=self.mailAddress:getStringValue()
		if address==nil or address=="" then
			popup.tip("请输入详细邮寄地址")
			return
		end
		local phoneNumber=self.mailPhoneNumber:getStringValue()
		if phoneNumber==nil or phoneNumber=="" then
			popup.tip("请输入联系手机号码")
			return
		end
		self.mailInfo:setVisible(false)
		self:mailJiangzhuang(self.currentData,self.currentIndex,receiver,address,phoneNumber)
	end)
	return layout
end

--进入场景
function JiangzhuangScene:onEnterTransitionFinish()
	--从服务器获取已获得奖状数据
	protocol.getUserJiangzhuang(function(success,obj)
		if success and obj then
			if obj.jiangzhuangList and #obj.jiangzhuangList>0 then
				local jiangzhuangList=public.copyTable(globalSettings.jiangzhuangList)
				for _,v in ipairs(obj.jiangzhuangList) do
					local data=jiangzhuangList[v.jiangzhuang_id]
					if data~=nil then
						data.userData=v
					end
				end
				table.sort(jiangzhuangList,function(e1,e2)
					if e1.userData==nil and e2.userData then
						return false
					elseif e1.userData and e2.userData==nil then
						return true
					end
					return e1.id<e2.id
				end)
				self.jiangzhuangView:setData(jiangzhuangList)
			end
			self.mailReceiver:setText(obj.lastReceiver or userInfo.name)
			self.mailAddress:setText(obj.lastAddress or "")
			self.mailPhoneNumber:setText(obj.lastPhoneNumber or "")
			mailPrice=obj.mailPrice or mailPrice
		end
	end,{node=self.layout,text="正在获取奖状数据......"})
end

--返回键
function JiangzhuangScene:onKeyBack()
	if self.mailInfo:isVisible() then
		self.mailInfo:setVisible(false)
	else
		cc.Director:getInstance():popScene()
	end
end

--申请邮寄奖状
function JiangzhuangScene:mailJiangzhuang(data,index,receiver,address,phoneNumber)
	protocol.mailJiangzhuang(data.id,receiver,address,phoneNumber,function(success,obj)
		if success and obj then
			--进行支付
			protocol.pay(obj,function(success)
				if success then
					--支付成功
					data.userData.mail_state=1
					self.jiangzhuangView:updateCellAtIndex(index-1)
				end
			end)
		end
	end,{node=self})
end

return JiangzhuangScene