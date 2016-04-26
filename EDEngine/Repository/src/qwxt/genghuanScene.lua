require "Cocos2d"
require "Cocos2dConstants"
require "qwxt/globalSettings"
require "qwxt/userInfo"
local public=require("qwxt/public")
local protocol=require("qwxt/protocol")

local GenghuanScene=public.newScene("GenghuanScene")

--加载UI
function GenghuanScene:loadUi(uiFileName)
	local layout=ccs.GUIReader:getInstance():widgetFromJsonFile(uiFileName)

	--响应后退按钮
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,373),function(sender,event)
		self:onKeyBack()
	end)
	--确认
	public.buttonEvent(ccui.Helper:seekWidgetByTag(layout,31793),function(sender,event)
		self:onOK()
	end)

	self.versionView=ccui.Helper:seekWidgetByTag(layout,402)
	self.versionItem=ccui.Helper:seekWidgetByTag(self.versionView,397)
	self.versionItem:retain()
	self.versionView:removeAllChildren()
	self.bookView=ccui.Helper:seekWidgetByTag(layout,4168)
	self.bookItem=ccui.Helper:seekWidgetByTag(self.bookView,381)
	self.bookItem:retain()
	self.bookView:removeAllChildren()

	--鼠标滚轮支持
	local targetPlatform=cc.Application:getInstance():getTargetPlatform()
	if targetPlatform==cc.PLATFORM_OS_WINDOWS or targetPlatform==cc.PLATFORM_OS_MAC then
		local focusView=self.versionView
		local height=self.versionItem:getContentSize().height
		local function moveContainer(line)
			if focusView then
				local container=focusView:getInnerContainer()
				local containerSize=container:getContentSize()
				local offset=cc.p(container:getPosition())
				local minOffset=cc.p(focusView:getContentSize().width-containerSize.width*container:getScaleX(),focusView:getContentSize().height-containerSize.height*container:getScaleY())
				local distance=line*height
				local newy=math.max(minOffset.y,math.min(offset.y+distance,0))
				if newy~=offset.y then
					offset.y=newy
					container:setPosition(offset)
				end
			end
		end
		local function onMouseScroll(event)
			local function PositionInNode(pos,node)
				local pt=cc.p(node:getPosition())
				pt=node:convertToWorldSpace(pt)
				local rect=cc.rect(pt.x,pt.y,node:getContentSize().width,node:getContentSize().height)
				return cc.rectContainsPoint(rect,pos)
			end
			--滚轮事件的坐标不是转换过的，要自己换算(好大一个坑)
			local scaleX=cc.Director:getInstance():getOpenGLView():getScaleX()
			local scaleY=cc.Director:getInstance():getOpenGLView():getScaleY()
			local pos=cc.p(event:getCursorX()/scaleX,event:getCursorY()/scaleY)
			if PositionInNode(pos,self.versionView) then
				focusView=self.versionView
			else
				if PositionInNode(pos,self.bookView) then
					focusView=self.bookView
				end
			end
			moveContainer(event:getScrollY())
			event:stopPropagation()
		end
		local listener=cc.EventListenerMouse:create() or cc.EventListenerMouse:create(nil)
		listener:registerScriptHandler(onMouseScroll,cc.Handler.EVENT_MOUSE_SCROLL)
		local eventDispatcher=layout:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,layout)
	end

	return layout
end

function GenghuanScene:showVersions()
	if userInfo.subjectData.versions==nill then
		--获取教材版本列表
		protocol.getVersions(userInfo.subjectData.id,function(success,obj)
			if success then
				userInfo.subjectData.versions=obj
			end
		end,{node=self.layout,text="正在获取教材版本列表.......",onFinished=function()
			if userInfo.subjectData.versions~=nill then
				self:showVersions()
			end
		end})
	else
		--显示教材版本列表
		local function onSelectVersion(sender,event)
			if event==ccui.CheckBoxEventType.selected then
				self:setSelectVersion(sender)
			end
		end
		public.addScrollViewItems(self.versionView,self.versionItem:getContentSize(),userInfo.subjectData.versions,function(data)
			local newVersion=self.versionItem:clone()
			ccui.Helper:seekWidgetByTag(newVersion,398):setString(data.name)
			newVersion.data=data
			public.selectEvent(newVersion,onSelectVersion)
			return newVersion
		end)
	end
end

--进入场景
function GenghuanScene:onEnter()
	self:showVersions()
end

--离开场景
function GenghuanScene:onExit()
	if self.versionItem then
		self.versionItem:release()
	end
	if self.bookItem then
		self.bookItem:release()
	end
end

--返回键和后退按钮
function GenghuanScene:onKeyBack()
	cc.Director:getInstance():popScene()
end

--确认按钮
function GenghuanScene:onOK()
	if self.selectedVersion and self.selectedBook and (userInfo.versionData==nil or userInfo.bookData==nil or self.selectedVersion.data.id~=userInfo.versionData.id or self.selectedBook.data.id~=userInfo.bookData.id) then
		protocol.setSelectedBook(userInfo.subjectData.id,self.selectedVersion.data.id,self.selectedBook.data.id,function(success,obj)
			if success then
				userInfo.versionData=self.selectedVersion.data
				userInfo.bookData=self.selectedBook.data
			end
		end,{node=self.layout,text="正在保存.......",onFinished=function()
			cc.Director:getInstance():popScene()
		end})
	else
		cc.Director:getInstance():popScene()
	end
end

--选择教材版本
function GenghuanScene:setSelectVersion(version)
	if version then
		if self.selectedVersion then
			self.selectedVersion:setSelectedState(false)
			self.selectedVersion:setEnabled(true)
		end

		self.selectedVersion=version
		version:setSelectedState(true)
		version:setEnabled(false)
		--显示可选择的年级
		self:showBooks(version)
	else
		self.selectedVersion=nil
	end
end

--显示教材
function GenghuanScene:showBooks(version)
	if version.data.books==nil then
		--从服务器获取教材列表
		protocol.getBooks(userInfo.subjectData.id,version.data.id,function(success,obj)
			if success and #obj>0 then
				version.data.books=obj
			end
		end,{node=self.layout,text="正在获取教材列表......",onFinished=function()
			if version.data.books~=nil then
				self:showBooks(version)
			end
		end})
	else
		--教材列表已存在
		self.bookView:removeAllChildren()
		self.selectedBook=nil
		local function onSelectBook(sender,event)
			if event==ccui.CheckBoxEventType.selected then
				self:setSelectBook(sender)
			end
		end
		public.addScrollViewItems(self.bookView,self.bookItem:getContentSize(),version.data.books,function(data)
			local newBook=self.bookItem:clone()
			ccui.Helper:seekWidgetByTag(newBook,382):setString(data.name)
			newBook.data=data
			public.selectEvent(newBook,onSelectBook)
			return newBook
		end)
	end
end

--选择教材
function GenghuanScene:setSelectBook(book)
	if book then
		if self.selectedBook then
			self.selectedBook:setSelectedState(false)
			self.selectedBook:setEnabled(true)
		end

		self.selectedBook=book
		book:setSelectedState(true)
		book:setEnabled(false)
	else
		self.selectedBook=nil
	end
end

return GenghuanScene