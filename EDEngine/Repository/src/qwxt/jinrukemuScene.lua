require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")
local rank=require("qwxt/rank")
local popup=require("qwxt/popup")
local protocol=require("qwxt/protocol")

local JinrukemuScene=public.newScene("JinrukemuScene")

--加载UI
function JinrukemuScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--科目名称
	ccui.Helper:seekWidgetByTag(layout,72):setString(userInfo.subjectData.name)
	--背景
	public.safeSetBackground(layout,"qwxt/background/kemu/"..math.random(1,12)..".jpg")

	self.bookVersion=ccui.Helper:seekWidgetByTag(layout,1895)

	self.image=ccui.Helper:seekWidgetByTag(layout,99)
	self.rank=ccui.Helper:seekWidgetByTag(layout,14342)
	self.rank:setString("无")
	self.yinbi=ccui.Helper:seekWidgetByTag(layout,114)
	self.level=ccui.Helper:seekWidgetByTag(layout,14340)
	self.exp=ccui.Helper:seekWidgetByTag(layout,14339)
	self.baozang=ccui.Helper:seekWidgetByTag(layout,116)
	self.jiangzhuang=ccui.Helper:seekWidgetByTag(layout,119)
	self.vip=ccui.Helper:seekWidgetByTag(layout,31797)
	
	--充值按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,3564),function(sender,event)
		--充银币
		require("qwxt/recharge").yinbi(function(success)
			if success then
				self.yinbi:setString(userInfo.yinbi)
			end
		end)
	end)

	--排行榜
	local rankItem=ccui.Helper:seekWidgetByTag(layout,78)
	rankItem:retain()
	local rankView=ccui.Helper:seekWidgetByTag(layout,1893)
	local viewSize=rankView:getContentSize()
	local viewPosition=cc.p(rankView:getPosition())
	local viewParent=rankView:getParent()
	rankView:removeFromParent()
	rankView=rank.createRankView(viewParent,viewPosition,viewSize,rankItem,6,{userInfo.subjectData.id},function(item,data,index)
		ccui.Helper:seekWidgetByTag(item,94):setString(index)
		ccui.Helper:seekWidgetByTag(item,81):setString(data.user_name)
		ccui.Helper:seekWidgetByTag(item,85):setString(data.baozang_count)
		ccui.Helper:seekWidgetByTag(item,88):setString(data.jiangzhuang_count)
		ccui.Helper:seekWidgetByTag(item,90):setString(data.score)
		rank.setRankItemImage(index,ccui.Helper:seekWidgetByTag(item,93),ccui.Helper:seekWidgetByTag(item,94))
		rank.setRankUserImage(data.user_id,data.user_name,ccui.Helper:seekWidgetByTag(item,98))
		ccui.Helper:seekWidgetByTag(item,31798):setSelectedState(data.isVip)
	end,function(e1,e2)
		if e1.score~=e2.score then
			return e1.score>e2.score
		elseif e1.baozang_count~=e2.baozang_count then
			return e1.baozang_count>e2.baozang_count
		elseif e1.jiangzhuang_count~=e2.jiangzhuang_count then
			return e1.jiangzhuang_count>e2.jiangzhuang_count
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
	end,function(data)
		--查找自己的本周排名
		if data==nil or #data<=0 then return end
		for i=1,#data do
			if data[i].user_id==userInfo.uid then
				self.rank:setString(i)
				return
			end
		end
	end)
	rankItem:release()

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,71),function(sender,event)
		self:onKeyBack()
	end)

	--响应更换按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,311),function(sender,event)
		self:onKeyMenu()
	end)

	--响应开始练习按钮
	self.startButton=ccui.Helper:seekWidgetByTag(layout,121)
	public.buttonEvent(self.startButton,function(sender,event)
		if userInfo.subjectData==nil or userInfo.bookData==nil then
			--选择教材
			self.start=true
			self:onKeyMenu()
		else
			self:startTraining()
		end
	end)

	return layout
end

--菜单键和更换按钮
function JinrukemuScene:onKeyMenu()
	cc.Director:getInstance():pushScene(public.createScene("genghuan"))
end

--后退键
function JinrukemuScene:onKeyBack()
	cc.Director:getInstance():popScene()
end

--进入场景
function JinrukemuScene:onEnterTransitionFinish()
	--设置个人信息
	if userInfo.image and cc.FileUtils:getInstance():isFileExist(userInfo.image) then
		self.image:loadTexture(userInfo.image)
	else
		public.getBigLogo(userInfo.uid,function(fileName)
			userInfo.image=fileName
			self.image:loadTexture(userInfo.image)
		end)
	end
	self.yinbi:setString(userInfo.yinbi)
	self.level:setString(userInfo.level.."级")
	self.exp:setPercent(globalSettings.level.calcPercent(userInfo.level,userInfo.exp))
	self.baozang:setString(userInfo.baozangCount)
	self.jiangzhuang:setString(userInfo.jiangzhuangCount)
	self.vip:setSelectedState(userInfo.expireDays>0)

	--设置选择的教材信息
	if userInfo.versionData==nil or userInfo.bookData==nil then
		--从服务器获取数据
		self.bookVersion:setString("")
		self.startButton:setVisible(false)
		protocol.getSelectedBook(userInfo.subjectData.id,function(success,obj)
			if success and obj then
				userInfo.subjectData.liandui=obj.liandui
				userInfo.versionData={ id=obj.versionId,name=obj.versionName }
				userInfo.bookData={ id=obj.bookId,name=obj.bookName,expired=obj.expired }
				self.bookVersion:setString(userInfo.versionData.name.." "..userInfo.bookData.name)
			else
				userInfo.subjectData.versions=nil
			end
			self.startButton:setVisible(true)
		end)
	else
		self.bookVersion:setString(userInfo.versionData.name.." "..userInfo.bookData.name)
	end

	if self.start then
		self.start=false
		if userInfo.subjectData~=nil and userInfo.bookData~=nil then
			self:startTraining()
		end
	end
end

--显示单元信息
function JinrukemuScene:showUnits(xuandanyuan,unitView,unitItem)
	if userInfo.bookData.units==nil then
		--获取单元数据以及完成度信息
		protocol.getUnits(userInfo.subjectData.id,userInfo.versionData.id,userInfo.bookData.id,function(success,obj)
			if success and #obj>0 then
				userInfo.bookData.units=obj
				self:showUnits(xuandanyuan,unitView,unitItem)
			end
		end,{node=unitView:getParent(),text="正在获取数据......"})
	else
		--显示单元列表
		unitView:removeAllChildren()
		local baowuData=nil
		for k,v in ipairs(userInfo.bookData.units) do
			if v.id==userInfo.bookData.id then
				--宝屋
				baowuData=v
			else
				local newUnit=unitItem:clone()
				unitView:pushBackCustomItem(newUnit)
				ccui.Helper:seekWidgetByTag(newUnit,16204):setString(v.name)
				ccui.Helper:seekWidgetByTag(newUnit,16209):setString(v.passCount.."人")
				ccui.Helper:seekWidgetByTag(newUnit,16206):setPercent(v.progress)
				ccui.Helper:seekWidgetByTag(newUnit,16207):setString(string.format("%d%%",math.modf(v.progress)))
				local btn=ccui.Helper:seekWidgetByTag(newUnit,16210)
				btn.data=v
				public.buttonEvent(btn,function(sender,event)
					userInfo.unitData=sender.data
					cc.Director:getInstance():pushScene(public.createScene("danyuan"))
				end)
			end
		end

		--神秘宝屋
		public.safeCreateArmature("zuihou",function(armature)
			local newUnit=unitItem:clone()
			unitView:pushBackCustomItem(newUnit)
			ccui.Helper:seekWidgetByTag(newUnit,16204):setString("神秘宝屋")
			ccui.Helper:seekWidgetByTag(newUnit,16206):removeFromParent()
			ccui.Helper:seekWidgetByTag(newUnit,16208):removeFromParent()
			ccui.Helper:seekWidgetByTag(newUnit,16209):removeFromParent()
			local img=ccui.Helper:seekWidgetByTag(newUnit,16205)
			armature:setAnchorPoint(img:getAnchorPoint())
			armature:setPosition(cc.p(img:getPosition()))
			local scale=img:getScale()
			armature:setScale(scale)
			armature:setName("smbw")
			newUnit:addChild(armature)
			ccui.Helper:seekWidgetByTag(newUnit,16207):removeFromParent()
			if baowuData==nil then
				armature:getAnimation():play("zuihou1")
			elseif baowuData.progress<100 then
				armature:getAnimation():play("zuihou2")
			else
				armature:getAnimation():play("zuihou3")
			end
			local btn=ccui.Helper:seekWidgetByTag(newUnit,16210)
			btn.data=baowuData
			public.buttonEvent(btn,function(sender,event)
				if sender.data~=nil then
					local content=nil
					if sender.data.progress<100 then
						content={text=string.format("加油吧，神秘宝屋就快要打开了。\n\n我的进度：%d%%",sender.data.progress),title="神秘宝屋"}
					else
						content={text="太棒了，宝屋已被你打开。",title="神秘宝屋"}
					end
					popup.msgBox(content,function(ok)
						if ok then
							userInfo.unitData=sender.data
							userInfo.classData=sender.data
							cc.Director:getInstance():pushScene(public.createScene("zuoti"))
						end
					end)
				else
					popup.msgBox({text="亲亲，你还没有达到开启条件。\n\n开启条件——所有单元完成度达到100%！",title="神秘宝屋"},_,true)
				end
			end)
		end)
		if self.oldPosition then unitView:getInnerContainer():setPosition(self.oldPosition) end
	end
end

--开始练习
function JinrukemuScene:startTraining()
	if self.xuandanyuan==nil then
		local xuandanyuan=ccs.GUIReader:getInstance():widgetFromJsonFile(string.format("qwxt/ui/xuandanyuan%s",globalSettings.uiName))

		local unitView=ccui.Helper:seekWidgetByTag(xuandanyuan,17918)
		local unitItem=ccui.Helper:seekWidgetByTag(unitView,16203)
		unitItem:retain()
		unitView:removeAllChildren()
		unitView:setClippingEnabled(true)

		--关闭按钮
		public.buttonEvent(ccui.Helper:seekWidgetByTag(xuandanyuan,16179),function(sender,event)
			xuandanyuan:setVisible(false)
		end)

		--后退键
		local function onKey(key,event)
			if key==cc.KeyCode.KEY_BACK and xuandanyuan:isVisible() then
				music.playEffect("button")
				xuandanyuan:setVisible(false)
				--不要往下传播这个事件
				event:stopPropagation()
			end
		end
		local listener=cc.EventListenerKeyboard:create()
		listener:registerScriptHandler(onKey,cc.Handler.EVENT_KEYBOARD_RELEASED)
		local eventDispatcher=xuandanyuan:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,xuandanyuan)

		xuandanyuan:registerScriptHandler(function(event)
			if event=="enterTransitionFinish" then
				self:showUnits(xuandanyuan,unitView,unitItem)
			elseif event=="exit" then
				self.oldPosition=cc.p(unitView:getInnerContainer():getPosition())
			elseif event=="cleanup" then
				unitItem:release()
			end
		end)

		self:addChild(xuandanyuan)
		self.xuandanyuan=xuandanyuan
	else
		self.xuandanyuan:setVisible(true)
	end
end

return JinrukemuScene
