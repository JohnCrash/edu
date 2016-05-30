require "Cocos2d"
require "qwxt/globalSettings"
require "qwxt/music"

local function copyTable(st)
	local t={}
	for k,v in pairs(st or {}) do
		if type(v)~="table" then
			t[k]=v
		else
			t[k]=copyTable(v)
		end
	end
	return t
end

local function buttonEvent(btn,callback)
	btn:addTouchEventListener(function(sender,event)
		if event~=ccui.TouchEventType.ended then return end
		music.playEffect("button")
		--关闭输入法
		cc.Director:getInstance():getOpenGLView():setIMEKeyboardState(false)
		callback(sender,event)
	end)
end

local function selectEvent(btn,callback)
	btn:addEventListener(function(sender,event)
		music.playEffect("button")
		--关闭输入法
		cc.Director:getInstance():getOpenGLView():setIMEKeyboardState(false)
		callback(sender,event)
	end)
end

local function safeClose(node,callback,param)
	node:setVisible(false)
	node:retain()
	performWithDelay(node,function()
		node:removeFromParent()
		node:release()
		if callback then callback(param) end
	end,0)
end

local function safeExit()
	require("ffplayer").stopAllGroup()
	performWithDelay(cc.Director:getInstance():getRunningScene(),function()
		cc.Director:getInstance():endToLua()
	end,0)
end

local function getBigLogo(uid,callback)
	require("login").get_logo(uid,callback,99)
end

local function newScene(name)
	local myScene=class(name,function()
		return cc.Scene:create()
	end)
	myScene.__index=myScene

	function myScene.create(uiFileName)
		local scene=myScene.new()
		if scene.loadUi then
			local ui=scene:loadUi(uiFileName)
			if ui then
				scene:addChild(ui)
				scene.layout=ui
			end
		end

		--键盘支持
		local function onKeyReleased(key,event)
			if key==cc.KeyCode.KEY_MENU and scene.onKeyMenu then
				music.playEffect("button")
				scene:onKeyMenu()
				event:stopPropagation()
			elseif key==cc.KeyCode.KEY_ESCAPE and scene.onKeyBack then
				music.playEffect("button")
				scene:onKeyBack()
				event:stopPropagation()
			end
		end
		local listener=cc.EventListenerKeyboard:create()
		listener:registerScriptHandler(onKeyReleased,cc.Handler.EVENT_KEYBOARD_RELEASED)
		local eventDispatcher=scene:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,scene)

		--事件监听
		local function sceneEventHandler(event)
			if event=="enter" and scene.onEnter then
				scene:onEnter()
			elseif event=="enterTransitionFinish" then
				music.playBackground()
				if scene.onEnterTransitionFinish then
					scene:onEnterTransitionFinish()
				end
			elseif event=="exitTransitionStart" and scene.onExitTransitionStart then
				scene:onExitTransitionStart()
			elseif event=="exit" and scene.onExit then
				scene:onExit()
				--关闭输入法
				cc.Director:getInstance():getOpenGLView():setIMEKeyboardState(false)
			elseif event=="cleanup" and scene.onCleanUp then
				scene:onCleanUp()
			end
		end
		scene:registerScriptHandler(sceneEventHandler)

		return scene
	end

	return myScene
end

local function createScene(sceneName)
	return require("qwxt/"..sceneName.."Scene").create(string.format("qwxt/ui/%s%s",sceneName,globalSettings.uiName))
end

local function showLoading(load,callback)
	local loadingScene=createScene("loading")
	loadingScene:setLoading(load,callback)
	
	return loadingScene
end

local function showWaiting(node,doWaiting,callback,text)
	node=node or cc.Director:getInstance():getRunningScene()

	local layout=ccui.Layout:create()
	layout:setContentSize(node:getContentSize())
	layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
	layout:setBackGroundColor(cc.c3b(0,0,0))
	layout:setBackGroundColorOpacity(150)
	layout:setTouchEnabled(true)
	cc.Director:getInstance():getEventDispatcher():pauseEventListenersForTarget(node,true)

	local img=ccui.ImageView:create("qwxt/loading2.png")
	if text then
		local tip=cc.Label:createWithSystemFont(text,"fonts/Marker Felt.ttf",40)
		local box=ccui.Layout:create()
		box:setContentSize(cc.size(img:getContentSize().width+tip:getContentSize().width,math.max(img:getContentSize().height,tip:getContentSize().height)))
		img:setAnchorPoint(cc.p(0,0.5))
		img:setPosition(0,box:getContentSize().height/2)
		tip:setAnchorPoint(cc.p(0,0.5))
		tip:setPosition(img:getContentSize().width,box:getContentSize().height/2)
		box:addChild(img)
		box:addChild(tip)
		box:setAnchorPoint(cc.p(0.5,0.5))
		box:setPosition(layout:getContentSize().width/2,layout:getContentSize().height/2)
		layout:addChild(box)
	else
		img:setPosition(layout:getContentSize().width/2,layout:getContentSize().height/2)
		layout:addChild(img)
	end
	local action1=cc.RotateBy:create(1,360)
	img:setAnchorPoint(cc.p(0.5,0.5))
	img:runAction(cc.RepeatForever:create(action1))
	node:addChild(layout)

	local co=(doWaiting and coroutine.create(doWaiting)) or nil
	local id=nil
	local function tick()
		if not co or not coroutine.resume(co) then
			cc.Director:getInstance():getScheduler():unscheduleScriptEntry(id)
			id=nil
			cc.Director:getInstance():getEventDispatcher():resumeEventListenersForTarget(node,true)
			layout:removeFromParent()
			if callback then callback() end
		end
	end
	id=cc.Director:getInstance():getScheduler():scheduleScriptFunc(tick,0,false)

	local function eventHandler(event)
		if event=="exitTransitionStart" and id then
			--等待还没有结束，强行终止
			cc.Director:getInstance():getEventDispatcher():resumeEventListenersForTarget(node,true)
			cc.Director:getInstance():getScheduler():unscheduleScriptEntry(id)
			id=nil
		elseif event=="enterTransitionFinish" and id==nil then
			performWithDelay(layout:getParent(),function()
				layout:removeFromParent()
			end,0)
		end
	end
	layout:registerScriptHandler(eventHandler)
end

--设置背景
local function safeSetBackground(layout,background)
	if cc.FileUtils:getInstance():isFileExist(background) then
		layout:setBackGroundImage(background)
	end
end

--创建动画
local function safeCreateArmature(armatureName,callback)
	if ccs.ArmatureDataManager:getInstance():getArmatureData(armatureName) then
		local armature=ccs.Armature:create(armatureName)
		if callback then callback(armature) end
		return armature
	end
end

--为PageView添加页指示
local function addPageControl(pageView,parent)
	local pageCount=#pageView:getPages()
	if pageCount>1 then
		local control=ccui.Layout:create()
		control:setLayoutType(ccui.LayoutType.HORIZONTAL)
		local curPageId=nil
		local function setCurrentPage(pageId)
			local curPage=control:getChildByTag(pageId)
			if curPage then
				if curPageId then
					local lastPage=control:getChildByTag(curPageId)
					lastPage:loadTextureNormal("qwxt/page_normal.png")
				end
				curPage:loadTextureNormal("qwxt/page_selected.png")
				curPageId=pageId
			end
		end
		local function onSetPage(sender,event)
			local index=sender:getTag()
			if index~=curPageId then
				pageView:scrollToPage(index)
				setCurrentPage(index)
			end
		end
		local btnSize=0
		local margin=nil
		for i=0,pageCount-1 do
			local btn=ccui.Button:create()
			btn:loadTextureNormal("qwxt/page_normal.png")
			btn:setTitleFontSize(20)
			btn:setTitleColor(cc.c3b(0,0,0))
			btn:setTitleText(i+1)
			btn:setTag(i)
			btn:setTouchEnabled(true)
			local lp=ccui.LinearLayoutParameter:create()
			lp:setGravity(ccui.LinearGravity.centerVertical)
			if i~=0 then
				lp:setMargin(margin)
			else
				btnSize=btn:getContentSize()
				margin={left=btnSize.width,top=0,right=0,bottom=0}
			end
			btn:setLayoutParameter(lp)
			buttonEvent(btn,onSetPage)
			control:addChild(btn)
		end
		control:setContentSize(cc.size(btnSize.width*(2*pageCount-1),btnSize.height))
		local controlSize=parent:getContentSize()
		control:setAnchorPoint(0.5,0)
		control:setPosition(controlSize.width/2,0)
		if parent.setLayoutType~=nil then
			parent:setLayoutType(ccui.LayoutType.ABSOLUTE)
		end
		parent:addChild(control)
		--监听翻页事件
		local function onPageViewEvent(sender,event)
			if event==ccui.PageViewEventType.turning then
				local curPageId=sender:getCurPageIndex()
				setCurrentPage(curPageId)
			end
		end
		pageView:addEventListener(onPageViewEvent)
		setCurrentPage(0)
	end
end

local function dateTimeFromString(fmt,s)
	local year,month,day,hour,minute,second=s:match(fmt)
	return os.time{year=year,month=month,day=day,hour=hour,min=minute,sec=second}
end

--添加鼠标滚轮和键盘支持
local function addMouseScrollAndKeyboard(view,moveContainer,onKeyHome,onKeyEnd)
	--鼠标滚轮
	local function onMouseScroll(event)
		if view:isVisible() then
			moveContainer(event:getScrollY())
			event:stopPropagation()
		end
	end
	local listenerMouse=cc.EventListenerMouse:create() or cc.EventListenerMouse:create(nil)
	listenerMouse:registerScriptHandler(onMouseScroll,cc.Handler.EVENT_MOUSE_SCROLL)

	--键盘
	local line=nil
	local page=nil
	local function processKey()
		moveContainer(line,page)
	end
	local sid=nil
	local function stopKeySchedule()
		if sid then
			view:getScheduler():unscheduleScriptEntry(sid)
			sid=nil
		end
	end
	local function onKeyPressed(key,event)
		if not view:isVisible() then return end

		local keySpeed=0.05
		stopKeySchedule()
		if key==cc.KeyCode.KEY_PG_UP or key==cc.KeyCode.KEY_KP_PG_UP then
			--上翻页
			line,page=nil,-1
			moveContainer(line,page)
			--连续按键支持
			sid=view:getScheduler():scheduleScriptFunc(processKey,keySpeed,false)
			event:stopPropagation()
		elseif key==cc.KeyCode.KEY_PG_DOWN or key==cc.KeyCode.KEY_KP_PG_DOWN then
			--下翻页
			line,page=nil,1
			moveContainer(line,page)
			--连续按键支持
			sid=view:getScheduler():scheduleScriptFunc(processKey,keySpeed,false)
			event:stopPropagation()
		elseif key==cc.KeyCode.KEY_UP_ARROW or key==cc.KeyCode.KEY_KP_UP then
			--上箭头
			line,page=-1,nil
			moveContainer(line,page)
			sid=view:getScheduler():scheduleScriptFunc(processKey,keySpeed,false)
			event:stopPropagation()
		elseif key==cc.KeyCode.KEY_DOWN_ARROW or key==cc.KeyCode.KEY_KP_DOWN then
			--下箭头
			line,page=1,nil
			moveContainer(line,page)
			sid=view:getScheduler():scheduleScriptFunc(processKey,keySpeed,false)
			event:stopPropagation()
		elseif key==cc.KeyCode.KEY_HOME or key==cc.KeyCode.KEY_KP_HOME then
			if onKeyHome then
				onKeyHome()
				event:stopPropagation()
			end
		elseif key==cc.KeyCode.KEY_END or key==cc.KeyCode.KEY_KP_END then
			if onKeyEnd then
				onKeyEnd()
				event:stopPropagation()
			end
		end
	end
	local function onKeyReleased(key,event)
		stopKeySchedule()
	end
	local listenerKeyboard=cc.EventListenerKeyboard:create()
	listenerKeyboard:registerScriptHandler(onKeyPressed,cc.Handler.EVENT_KEYBOARD_PRESSED)
	listenerKeyboard:registerScriptHandler(onKeyReleased,cc.Handler.EVENT_KEYBOARD_RELEASED)
	local eventDispatcher=view:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listenerMouse,view)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listenerKeyboard,view)

	cc.Node.registerScriptHandler(view,function(event)
		if event=="enter" and view.onEnter then
			view:onEnter()
		elseif event=="enterTransitionFinish" and view.onEnterTransitionFinish then
			view:onEnterTransitionFinish()
		elseif event=="exitTransitionStart" and view.onExitTransitionStart then
			view:onExitTransitionStart()
		elseif event=="exit" and view.stopKeySchedule then
			--终止连续按键
			stopKeySchedule()
			if view.onExit then
				view:onExit()
			end
		elseif event=="cleanup" and view.onCleanup then
			view:onCleanup()
		end
	end)
end

local function addScrollViewItems(view,itemSize,dataList,createItem)
	local viewSize=view:getContentSize()
	local row=math.max(1,math.modf(viewSize.width/itemSize.width)-1)
	local line,tmp=math.modf(#dataList/row)
	if tmp>0 then line=line+1 end
	local rowSpace=(viewSize.width-itemSize.width*row)/(row+1)
	local lineSpace=itemSize.height/3
	local width,height=itemSize.width+rowSpace,itemSize.height+lineSpace
	local scrollSize=cc.size(viewSize.width,line*height+lineSpace)
	view:setInnerContainerSize(scrollSize)
	scrollSize=view:getInnerContainerSize()
	local x,y=rowSpace,scrollSize.height-height
	local t=0
	for k,v in ipairs(dataList) do
		local newItem=createItem(v)
		if newItem~=nil then
			newItem:setAnchorPoint(cc.p(0,0))
			newItem:setPosition(x,y)
			newItem:setContentSize(itemSize)
			view:addChild(newItem)
			t=t+1
			if t==row then
				t=0
				x=rowSpace
				y=y-height
			else
				x=x+width
			end
		end
	end
end

return
{
	copyTable=copyTable,
	buttonEvent=buttonEvent,
	selectEvent=selectEvent,
	safeClose=safeClose,
	safeExit=safeExit,
	getBigLogo=getBigLogo,
	getBookVersions=getBookVersions,
	getUnits=getUnits,
	newScene=newScene,
	createScene=createScene,
	showLoading=showLoading,
	showWaiting=showWaiting,
	safeSetBackground=safeSetBackground,
	safeCreateArmature=safeCreateArmature,
	addPageControl=addPageControl,
	dateTimeFromString=dateTimeFromString,
	addMouseScrollAndKeyboard=addMouseScrollAndKeyboard,
	addScrollViewItems=addScrollViewItems,
}
