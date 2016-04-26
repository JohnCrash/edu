require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")
local rank=require("qwxt/rank")
local popup=require("qwxt/popup")
local protocol=require("qwxt/protocol")

local DanyuanScene=public.newScene("DanyuanScene")

--加载UI
function DanyuanScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--文字
	ccui.Helper:seekWidgetByTag(layout,662):setString(string.format("%s %s %s",userInfo.subjectData.name,userInfo.bookData.name,userInfo.unitData.name))
	--背景
	public.safeSetBackground(layout,"qwxt/background/danyuan/"..math.random(1,12)..".jpg")

	self.problemCount=ccui.Helper:seekWidgetByTag(layout,710)
	self.correctRate=ccui.Helper:seekWidgetByTag(layout,714)
	self.progressBar=ccui.Helper:seekWidgetByTag(layout,720)
	self.progressPercent=ccui.Helper:seekWidgetByTag(layout,731)
	
	--单元过关排行榜
	local rankItem=ccui.Helper:seekWidgetByTag(layout,690)
	rankItem:retain()
	local rankView=ccui.Helper:seekWidgetByTag(layout,1936)
	local viewSize=rankView:getContentSize()
	local viewPosition=cc.p(rankView:getPosition())
	local viewParent=rankView:getParent()
	rankView:removeFromParent()
	local param={userInfo.subjectData.id,userInfo.versionData.id,userInfo.bookData.id,userInfo.unitData.id}
	rankView=rank.createRankView(viewParent,viewPosition,viewSize,rankItem,5,param,function(item,data,index)
		ccui.Helper:seekWidgetByTag(item,701):setString(index)
		ccui.Helper:seekWidgetByTag(item,692):setString(data.user_name)
		if data.progress>=100 then
			local t=os.date("*t",data.timestamp)
			ccui.Helper:seekWidgetByTag(item,697):setString(string.format("过关时间：%d.%d.%d %02d:%02d",t.year,t.month,t.day,t.hour,t.min))
		else
			ccui.Helper:seekWidgetByTag(item,697):setString(string.format("过关进度：%d%%",math.modf(data.progress)))
		end
		rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,700),ccui.Helper:seekWidgetByTag(item,701))
		rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,702))
		ccui.Helper:seekWidgetByTag(item,31801):setSelectedState(data.isVip)
	end,function(e1,e2)
		if e1.progress~=e2.progress then
			return e1.progress>e2.progress
		elseif e1.timestamp~=e2.timestamp then
			return e1.timestamp<e2.timestamp
		else
			return e1.user_id<e2.user_id
		end
	end,function(data)
		local fmt="(%d+)-(%d+)-(%d+).(%d+):(%d+):(%d+)"
		for _,v in ipairs(data) do
			v.timestamp=public.dateTimeFromString(fmt,v.update_time)
		end
	end)
	rankItem:release()

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,661),function(sender,event)
		self:onKeyBack()
	end)

	--响应开始练习按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,738),function(sender,event)
		self:onStart()
	end)
	
	return layout
end

function DanyuanScene:onEnterTransitionFinish()
	--设置个人信息
	self.problemCount:setString(userInfo.unitData.totalCount)
	if userInfo.unitData.totalCount>0 then
		self.correctRate:setString(string.format("%.0f%%",userInfo.unitData.rightCount*100/userInfo.unitData.totalCount))
	else
		self.correctRate:setString("100%")
	end
	self.progressBar:setPercent(userInfo.unitData.progress)
	self.progressPercent:setString(string.format("%d%%",math.modf(userInfo.unitData.progress)))
end

--返回键
function DanyuanScene:onKeyBack()
	cc.Director:getInstance():popScene()
end

--显示课信息
function DanyuanScene:showClasses(xuanke,classView,classItem)
	if userInfo.unitData.classes==nil then
		--获取课数据以及完成度信息
		protocol.getClasses(userInfo.subjectData.id,userInfo.versionData.id,userInfo.bookData.id,userInfo.unitData.id,function(success,obj)
			if success and #obj>0 then
				userInfo.unitData.classes=obj
				self:showClasses(xuanke,classView,classItem)
			end
		end,{node=classView:getParent(),text="正在获取数据......"})
	else
		--显示课列表
		classView:removeAllChildren()
		local mijingData=nil
		for k,v in ipairs(userInfo.unitData.classes) do
			if v.id==userInfo.unitData.id then
				mijingData=v
			else
				local newClass=classItem:clone()
				classView:pushBackCustomItem(newClass)
				ccui.Helper:seekWidgetByTag(newClass,834):setString(v.name)
				ccui.Helper:seekWidgetByTag(newClass,835):setString(string.format("%d%%",math.modf(v.progress)))
				ccui.Helper:seekWidgetByTag(newClass,831):setPercent(v.progress)
				local btn=ccui.Helper:seekWidgetByTag(newClass,19564)
				btn.data=v
				public.buttonEvent(btn,function(sender,event)
					userInfo.classData=sender.data
					cc.Director:getInstance():pushScene(public.createScene("zuoti"))
				end)
			end
		end

		--秘境探险
		public.safeCreateArmature("mijing",function(armature)
			local newClass=classItem:clone()
			classView:pushBackCustomItem(newClass)
			ccui.Helper:seekWidgetByTag(newClass,834):setString("秘境探险")
			ccui.Helper:seekWidgetByTag(newClass,831):removeFromParent()
			local img=ccui.Helper:seekWidgetByTag(newClass,828)
			armature:setAnchorPoint(img:getAnchorPoint())
			armature:setPosition(cc.p(img:getPosition()))
			local scale=img:getScale()
			armature:setScale(scale)
			newClass:addChild(armature)
			ccui.Helper:seekWidgetByTag(newClass,835):removeFromParent()
			if mijingData==nil then
				armature:getAnimation():play("1")
			elseif mijingData.progress<100 then
				armature:getAnimation():play("2")
			else
				armature:getAnimation():play("3")
			end
			local btn=ccui.Helper:seekWidgetByTag(newClass,19564)
			btn.data=mijingData
			public.buttonEvent(btn,function(sender,event)
				if sender.data~=nil then
					local content=nil
					if sender.data.progress<100 then
						content={text=string.format("努力吧！奋斗吧！宝藏就在眼前！\n\n我的进度：%d%%",math.modf(sender.data.progress)),title="探索秘境"}
					else
						content={text="太棒了，宝藏已被你取走。",title="探索秘境"}
					end
					popup.msgBox(content,function(ok)
						if ok then
							userInfo.classData=sender.data
							cc.Director:getInstance():pushScene(public.createScene("zuoti"))
						end
					end)
				else
					popup.msgBox({text="亲亲，你还没有达到开启条件。\n\n开启条件——所有课文完成度达到100%！",title="探索秘境"},_,true)
				end
			end)
		end)
	end
end

--选课
function DanyuanScene:onStart()
	if self.xuanke==nil then
		local xuanke=ccs.GUIReader:getInstance():widgetFromJsonFile(string.format("qwxt/ui/xuanke%s",globalSettings.uiName))

		local classView=ccui.Helper:seekWidgetByTag(xuanke,6071)
		local classItem=ccui.Helper:seekWidgetByTag(classView,850)
		classItem:retain()
		classView:removeAllChildren()
		classView:setClippingEnabled(true)

		--关闭按钮
		public.buttonEvent(ccui.Helper:seekWidgetByTag(xuanke,6661),function(sender,event)
			xuanke:setVisible(false)
		end)

		--后退键
		local function onKey(key,event)
			if key==cc.KeyCode.KEY_BACK and xuanke:isVisible() then
				xuanke:setVisible(false)
				--不要往下传播这个事件
				event:stopPropagation()
			end
		end
		local listener=cc.EventListenerKeyboard:create()
		listener:registerScriptHandler(onKey,cc.Handler.EVENT_KEYBOARD_RELEASED)
		local eventDispatcher=xuanke:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,xuanke)

		xuanke:registerScriptHandler(function(event)
			if event=="enterTransitionFinish" then
				self:showClasses(xuanke,classView,classItem)
			elseif event=="cleanup" then
				classItem:release()
			end
		end)

		self:addChild(xuanke)
		self.xuanke=xuanke
	else
		self.xuanke:setVisible(true)
	end
end

return DanyuanScene