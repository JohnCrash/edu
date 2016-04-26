require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")

--购买会员有效期
local function expireTime(callback)
--	require("qwxt/popup").msgBox({title="温馨提示",text="测试期间，增加会员有效期功能暂时关闭！"},function(ok)
--		if callback then callback(false) end
--	end,true)
	if true then return	end

	local param=false

	local scene=cc.Director:getInstance():getRunningScene()
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(string.format("qwxt/ui/guoqi%s",globalSettings.uiName))
	layout:setTouchEnabled(true)
	ccui.Helper:seekWidgetByTag(layout,28060):setVisible(false)
	local cardPage=ccui.Helper:seekWidgetByTag(layout,24510)
	cardPage:setVisible(false)
	local buyPage=ccui.Helper:seekWidgetByTag(layout,26096)
	buyPage:setVisible(true)
	scene:addChild(layout)

	--关闭按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,26097),function(sender,event)
		public.safeClose(layout,callback,param)
	end)
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,25190),function(sender,event)
		buyPage:setVisible(true)
		cardPage:setVisible(false)
	end)
	--后退键
	local function onKey(key,event)
		if key==cc.KeyCode.KEY_BACK then
			music.playEffect("button")
			event:stopPropagation()
			if buyPage:isVisible() then
				public.safeClose(layout,callback,param)
			else
				buyPage:setVisible(true)
				cardPage:setVisible(false)
			end
		end
	end
	local listener=cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(onKey,cc.Handler.EVENT_KEYBOARD_RELEASED)
	local eventDispatcher=layout:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener,layout)
	--充值卡按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,28046),function(sender,event)
		buyPage:setVisible(false)
		cardPage:setVisible(true)
	end)

	--会员有效期价格
	local priceList=ccui.Helper:seekWidgetByTag(layout,26099)
	local item=ccui.Helper:seekWidgetByTag(priceList,26100)
	item:retain()
	priceList:removeAllChildren()
	priceList:setClippingEnabled(true)
	require("qwxt/protocol").getExpireTimePrice(function(success,obj)
		if success and obj then
			for k,v in ipairs(obj) do
				local newItem=item:clone()
				priceList:pushBackCustomItem(newItem)
				ccui.Helper:seekWidgetByTag(newItem,26102):setString(v.name)
				ccui.Helper:seekWidgetByTag(newItem,26105):setString(v.price.."元")
				local btn=ccui.Helper:seekWidgetByTag(newItem,26103)
				btn.priceId=k
				public.buttonEvent(btn,function(sender,event)
					--购买会员有效期
					require("qwxt/protocol").rechargeExpireTime(sender.priceId,function(success,obj)
						if success then
							if obj then
								--购买成功
								param=true
								userInfo.expireDays=obj.expireDays
								require("qwxt/popup").msgBox({title="购买成功",text="会员有效期还有"..userInfo.expireDays.."天\n\n继续购买会员有效期吗？"},function(ok)
									if not ok then public.safeClose(layout,callback,param) end
								end)
							else
							end
						end
					end,{node=layout})
				end)
			end
		end
	end,{node=layout,text="正在获取数据......."})
	priceList:registerScriptHandler(function(event)
		if event=="enterTransitionFinish" then
		elseif event=="cleanup" then
			item:release()
		end
	end)

	--充值卡
	local card=ccui.Helper:seekWidgetByTag(layout,24516)
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,24514),function(sender,event)
		local cardId=card:getStringValue()
		if cardId==nil or cardId=="" then return end
		--使用充值卡
		require("qwxt/protocol").rechargeByCard(cardId,function(success,obj)
			if success and obj then
				if obj.cardType then
					--充值成功
					param=true
					card:setText("")
					if obj.cardType==1 then
						userInfo.expireDays=obj.expireDays
						require("qwxt/popup").msgBox({title="充值成功",text="会员有效期还有"..userInfo.expireDays.."天\n\n继续使用充值卡吗？"},function(ok)
							if not ok then public.safeClose(layout,callback,param) end
						end)
					elseif obj.cardType==2 then
						userInfo.yinbi=obj.yinbi
						require("qwxt/popup").msgBox({title="充值成功",text="你现在拥有的银币数量为："..userInfo.yinbi.."\n\n继续使用充值卡吗？"},function(ok)
							if not ok then public.safeClose(layout,callback,param) end
						end)
					end
				else
					--充值失败
					require("qwxt/popup").msgBox({title="充值失败",text=obj.text},_,true)
				end
			end
		end,{node=layout})
	end)
end

--购买银币
local function yinbi(callback)
	local param=false

	local scene=cc.Director:getInstance():getRunningScene()
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(string.format("qwxt/ui/guoqi%s",globalSettings.uiName))
	layout:setTouchEnabled(true)
	ccui.Helper:seekWidgetByTag(layout,24510):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,26096):setVisible(false)
	ccui.Helper:seekWidgetByTag(layout,28060):setVisible(true)
	scene:addChild(layout)

	--关闭按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,28061),function(sender,event)
		public.safeClose(layout,callback,param)
	end)
	--后退键
	local function onKey(key,event)
		if key==cc.KeyCode.KEY_BACK then
			music.playEffect("button")
			event:stopPropagation()
			public.safeClose(layout,callback,param)
		end
	end
	local listener=cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(onKey,cc.Handler.EVENT_KEYBOARD_RELEASED)
	local eventDispatcher=layout:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener,layout)

	--银币价格
	local priceList=ccui.Helper:seekWidgetByTag(layout,28063)
	local item=ccui.Helper:seekWidgetByTag(priceList,28064)
	item:retain()
	priceList:removeAllChildren()
	priceList:setClippingEnabled(true)
	require("qwxt/protocol").getYinbiPrice(function(success,obj)
		if success and obj then
			for k,v in ipairs(obj) do
				local newItem=item:clone()
				priceList:pushBackCustomItem(newItem)
				ccui.Helper:seekWidgetByTag(newItem,28066):setString(v.name)
				ccui.Helper:seekWidgetByTag(newItem,28069):setString(v.price.."乐币")
				local btn=ccui.Helper:seekWidgetByTag(newItem,28067)
				btn.priceId=k
				public.buttonEvent(btn,function(sender,event)
					--购买银币
					require("qwxt/protocol").rechargeYinbi(sender.priceId,function(success,obj)
						if success and obj then
							--获得订单了，进行支付
							require("qwxt/protocol").pay(obj,function(success)
								if success then
									--支付成功
									param=true
									userInfo.yinbi=userInfo.yinbi+obj.product_count
									require("qwxt/popup").msgBox({title="购买成功",text="你现在拥有"..userInfo.yinbi.."银币\n\n继续购买银币吗？"},function(ok)
										if not ok then public.safeClose(layout,callback,param) end
									end)
								end
							end)
						end
					end,{node=layout})
				end)
			end
		end
	end,{node=layout,text="正在获取数据......."})
	priceList:registerScriptHandler(function(event)
		if event=="enterTransitionFinish" then
		elseif event=="cleanup" then
			item:release()
		end
	end)
end

return
{
	yinbi=yinbi,
	expireTime=expireTime,
}
