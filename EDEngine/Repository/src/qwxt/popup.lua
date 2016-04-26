require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")

--弹出消息框
local function msgBox(content,callback,forceOk,image,modeless,node)
	node=node or cc.Director:getInstance():getRunningScene()
	forceOk=forceOk or false

	local box=ccs.GUIReader:getInstance():widgetFromJsonFile("qwxt/ui/tank1.json")
	box:setContentSize(globalSettings.designResolution.width,globalSettings.designResolution.height)
	local dialog=ccui.Helper:seekWidgetByTag(box,4893)
	dialog:setAnchorPoint(cc.p(0.5,0.5))
	dialog:setPosition(globalSettings.designResolution.width/2,globalSettings.designResolution.height/2)

	if content.title then
		ccui.Helper:seekWidgetByTag(dialog,4896):setString(content.title)
	else
		ccui.Helper:seekWidgetByTag(dialog,4896):setVisible(false)
	end
	if content.text then
		ccui.Helper:seekWidgetByTag(dialog,4897):setString(content.text)
	else
		ccui.Helper:seekWidgetByTag(dialog,4897):setVisible(false)
	end

	--取消按钮
	local cancelBtn=ccui.Helper:seekWidgetByTag(box,14349)
	if image and image.cancel then
		cancelBtn:loadTextureNormal(image.cancel)
	end
	public.buttonEvent(cancelBtn,function(sender,event)
		public.safeClose(box,callback,forceOk)
	end)

	--确认按钮
	local okBtn=ccui.Helper:seekWidgetByTag(box,4898)
	if image and image.ok then
		okBtn:loadTextureNormal(image.ok)
	end
	public.buttonEvent(okBtn,function(sender,event)
		public.safeClose(box,callback,true)
	end)
	if forceOk then
		cancelBtn:setVisible(false)
		okBtn:setAnchorPoint(cc.p(0.5,0.5))
		local _,height=okBtn:getPosition()
		okBtn:setPosition(cc.p(okBtn:getParent():getContentSize().width/2,height))
	end

	--后退键
	local function onKey(key,event)
		if key==cc.KeyCode.KEY_BACK then
			music.playEffect("button")
			--不要往下传播这个事件
			event:stopPropagation()
			public.safeClose(box,callback,forceOk)
		end
	end
	local listener=cc.EventListenerKeyboard:create()
	listener:registerScriptHandler(onKey,cc.Handler.EVENT_KEYBOARD_RELEASED)
	local eventDispatcher=box:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener,box)
	
	if not modeless then
		if node._pauseCount and node._pauseCount>0 then
			node._pauseCount=node._pauseCount+1
		else
			cc.Director:getInstance():getEventDispatcher():pauseEventListenersForTarget(node,true)
			node._pauseCount=1
		end
		local function eventHandler(event)
			if event=="exit" then
				node._pauseCount=node._pauseCount-1
				if node._pauseCount<=0 then
					node._pauseCount=nil
					cc.Director:getInstance():getEventDispatcher():resumeEventListenersForTarget(node,true)
				end
			end
		end
		box:registerScriptHandler(eventHandler)
	end

	node:addChild(box)
end

--弹出动画
local function showAnimation(node,armatureName,animationName,callback)
	node=node or cc.Director:getInstance():getRunningScene()

	public.safeCreateArmature(armatureName,function(armature)
		if not armature:getAnimation():getAnimationData():getMovement(animationName) then return end
		
		armature:setAnchorPoint(cc.p(0.5,0.5))
		armature:setPosition(node:getContentSize().width/2,node:getContentSize().height/2)
		armature:getAnimation():setMovementEventCallFunc(function(sender,type,name)
			if type==ccs.MovementEventType.complete or type==ccs.MovementEventType.loopComplete then
				sender:getAnimation():stop()
				sender:removeFromParent()
				if callback then callback() end
			end
		end)
		armature:getAnimation():play(animationName)
		node:addChild(armature)
	end)
end

--提示
local function tip(text,callback,node,second)
	node=node or cc.Director:getInstance():getRunningScene()
	second=second or 3

	local tipBox=cc.Label:createWithSystemFont(text,"fonts/Marker Felt.ttf",30)
	local layout=ccui.Layout:create()

	layout:setContentSize(cc.size(tipBox:getContentSize().width+60,tipBox:getContentSize().height+60))
	layout:setColor(cc.c3b(0,255,0))
	layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	layout:setBackGroundColor(cc.c3b(0,0,128))
	layout:setBackGroundColorOpacity(200)
	layout:setTouchEnabled(true)
	layout:setAnchorPoint(0.5,0)
	layout:setPosition(node:getContentSize().width/2,0)
	node:addChild(layout)

	tipBox:setAnchorPoint(0.5,0.5)
	tipBox:setPosition(layout:getContentSize().width/2,layout:getContentSize().height/2)
	layout:addChild(tipBox)

	layout:retain()
	performWithDelay(node,function()
		layout:removeFromParent()
		layout:release()
		if callback then callback() end
	end,second)
end

--同学信息
local function classmateInfo(userId,userName)
	local scene=cc.Director:getInstance():getRunningScene()
	local function showClassmateInfo(layout)
		if scene._classmateData==nil or scene._classmateData.userId~=userId then
			layout.baozangView:removeAllChildren()
			layout.jiangzhuangView:removeAllChildren()
			layout.userName:setString("")
			layout.expBar:setPercent(0)
			layout.level:setString("")
			layout.yinbi:setString("")
			layout.schoolClassName:setString("")

			local data=nil
			require("qwxt/protocol").getClassmateInfo(userId,function(success,obj)
				if success and obj then
					data=obj
				end
			end,{node=layout,text="正在获取数据......",onFinished=function()
				if data~=nil then
					scene._classmateData=data
					scene._classmateData.userId=userId
					showClassmateInfo(layout)
				end
			end})
		else
			public.getBigLogo(userId,function(fileName)
				ccui.Helper:seekWidgetByTag(layout,22183):loadTexture(fileName)
			end)
			layout.userName:setString(userName)
			layout.expBar:setPercent(globalSettings.level.calcPercent(scene._classmateData.level,scene._classmateData.exp))
			layout.level:setString(scene._classmateData.level.."级")
			layout.yinbi:setString(scene._classmateData.yinbi)
			layout.schoolClassName:setString(scene._classmateData.schoolClassName)
			layout.vip:setSelectedState(scene._classmateData.isVip)

			--宝藏
			if scene._classmateData.baozangList~=nil and #scene._classmateData.baozangList>0 then
				public.addScrollViewItems(layout.baozangView,layout.baozangSize,scene._classmateData.baozangList,function(data)
					return public.safeCreateArmature("baozang",function(armature)
						armature:getAnimation():play("s"..data)
					end)
				end)
			end
			layout.baozangView:jumpToTop()
			--奖状
			local jiangzhuangList=globalSettings.jiangzhuangList
			if scene._classmateData.jiangzhuangList~=nil and #scene._classmateData.jiangzhuangList>0 then
				public.addScrollViewItems(layout.jiangzhuangView,layout.jiangzhuangSize,scene._classmateData.jiangzhuangList,function(data)
					local img=ccui.ImageView:create(jiangzhuangList[data].image)
					img:ignoreContentAdaptWithSize(false)
					return img
				end)
			end
			layout.jiangzhuangView:jumpToTop()
		end
		cc.Director:getInstance():getEventDispatcher():pauseEventListenersForTarget(scene.layout,true)
	end
	local function closeClassmatInfo(layout)
		layout:setVisible(false)
		cc.Director:getInstance():getEventDispatcher():resumeEventListenersForTarget(scene.layout,true)
	end

	if scene._classmateInfo==nil then
		local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(string.format("qwxt/ui/tongxue%s",globalSettings.uiName))
		layout:setTouchEnabled(true)
		layout.baozangView=ccui.Helper:seekWidgetByTag(layout,14958)
		layout.jiangzhuangView=ccui.Helper:seekWidgetByTag(layout,14963)
		layout.baozangSize=ccui.Helper:seekWidgetByTag(layout,11905):getContentSize()
		layout.jiangzhuangSize=ccui.Helper:seekWidgetByTag(layout,15205):getContentSize()
		layout.baozangView:setClippingEnabled(true)
		layout.jiangzhuangView:setClippingEnabled(true)
		layout.userName=ccui.Helper:seekWidgetByTag(layout,10580)
		layout.expBar=ccui.Helper:seekWidgetByTag(layout,14972)
		layout.level=ccui.Helper:seekWidgetByTag(layout,14973)
		layout.yinbi=ccui.Helper:seekWidgetByTag(layout,10585)
		layout.schoolClassName=ccui.Helper:seekWidgetByTag(layout,10582)
		layout.vip=ccui.Helper:seekWidgetByTag(layout,31808)

		--关闭按钮
		public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,21036),function(sender,event)
			closeClassmatInfo(layout)
		end)
		--后退键
		local function onKey(key,event)
			if key==cc.KeyCode.KEY_BACK and layout:isVisible() then
				music.playEffect("button")
				event:stopPropagation()
				closeClassmatInfo(layout)
			end
		end
		local listener=cc.EventListenerKeyboard:create()
		listener:registerScriptHandler(onKey,cc.Handler.EVENT_KEYBOARD_RELEASED)
		local eventDispatcher=layout:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,layout)

		scene:addChild(layout)
		scene._classmateInfo=layout
		showClassmateInfo(layout)
	else
		scene._classmateInfo:setVisible(true)
		showClassmateInfo(scene._classmateInfo)
	end
end

return
{
	msgBox=msgBox,
	showAnimation=showAnimation,
	tip=tip,
	classmateInfo=classmateInfo,
}
