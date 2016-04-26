require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/userInfo"
local public=require("qwxt/public")
local protocol=require("qwxt/protocol")

local BaozangScene=public.newScene("BaozangScene")

--加载UI
function BaozangScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,8106),function(sender,event)
		self:onKeyBack()
	end)
	ccui.Helper:seekWidgetByTag(layout,18063):setVisible(true)

	--宝藏提示
	self.detail=ccui.Helper:seekWidgetByTag(layout,8687)
	self.detail.img=ccui.Helper:seekWidgetByTag(self.detail,8688)
	self.detail.text=ccui.Helper:seekWidgetByTag(self.detail,8691)
	self.detail.exp=ccui.Helper:seekWidgetByTag(self.detail,8694)
	self.detail.yinbi=ccui.Helper:seekWidgetByTag(self.detail,8696)
	self.detail.day=ccui.Helper:seekWidgetByTag(self.detail,8698)
	self.detail.got=ccui.Helper:seekWidgetByTag(self.detail,8699)
	self.detail:setVisible(false)
	public.buttonEvent(self.detail,function(sender,event)
		self.detail:setVisible(false)
	end)

	return layout
end

--进入场景
function BaozangScene:onEnterTransitionFinish()
	--添加点击监听
	local pageView=ccui.Helper:seekWidgetByTag(self.layout,9875)
	local pages=pageView:getPages()
	local baozangList=public.copyTable(globalSettings.baozangList)
	public.showWaiting(self.layout,function()
		for _,v in pairs(pages) do
			local items=v:getChildren()
			for k,v1 in pairs(items) do
				if baozangList[v1:getName()] then
					baozangList[v1:getName()].control=v1
					local img=v1:getChildByName("thd")
					public.buttonEvent(img,function(sender,event)
						--点击图标显示详细内容
						self.detail.text:setString(baozangList[sender:getParent():getName()].detail)
						self.detail.exp:setString(baozangList[sender:getParent():getName()].exp)
						self.detail.yinbi:setString(baozangList[sender:getParent():getName()].yinbi)
						self.detail.day:setString(tostring(baozangList[sender:getParent():getName()].day).."天")
						self.detail.got:setVisible(sender.got)
						self.detail.img:removeAllChildren()
						local newImg=sender:getParent():clone()
						newImg:setAnchorPoint(cc.p(0,0))
						newImg:setPosition(cc.p(0,0))
						newImg:setTouchEnabled(false)
						public.safeCreateArmature("baozang",function(armature)
							local img1=newImg:getChildByName("thd")
							armature:setAnchorPoint(img1:getAnchorPoint())
							armature:setPosition(img1:getPosition())
							armature:setContentSize(img1:getContentSize())
							armature:setScale(img1:getScale())
							armature:getAnimation():play(newImg:getName())
							newImg:addChild(armature)
							img1:removeFromParent()
						end)
						self.detail.img:addChild(newImg)
						self.detail:setVisible(true)
					end)
				end
				if k%3==0 then coroutine.yield() end
			end
		end
	end,function()
		public.addPageControl(pageView,pageView)

		--从服务器获取已获得宝藏数据
		protocol.getUserBaozang(function(success,obj)
			if success then
				--显示已获得宝藏的动画
				for _,baozang in pairs(obj) do
					local v=baozangList["s"..baozang.baozang_id]
					if v and v.control then
						v.exp=baozang.exp
						v.yinbi=baozang.yinbi
						v.day=baozang.day
						local img=v.control:getChildByName("thd")
						public.safeCreateArmature("baozang",function(armature)
							armature:setAnchorPoint(img:getAnchorPoint())
							armature:setPosition(img:getPosition())
							armature:setContentSize(img:getContentSize())
							armature:setScale(img:getScale())
							armature:getAnimation():play(v.control:getName())
							v.control:addChild(armature)
						end)
						img.got=true
					end
				end
			end
		end,{node=self.layout,text="正在获取宝藏数据......"})
	end,"正在加载......")
end

--返回键
function BaozangScene:onKeyBack()
	if self.detail:isVisible() then
		self.detail:setVisible(false)
	else
		cc.Director:getInstance():popScene()
	end
end

return BaozangScene