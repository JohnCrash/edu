local uikits = require "uikits"

local ui = {
	FILE = "homework/imagepreview.json",
	FILE_3_4 = "homework/imagepreview43.json",
	IMAGEVIEW = "scrollview/image",
	SCROLLVIEW = "scrollview",
	PAGEVIEW = "pageview",
	TEXT = "top/text",
	CLOSE = "top/exit",
	LAYOUT = "pageview/layout",
}

local ImagePreview = class("ImagePreview")
ImagePreview.__index = ImagePreview

function ImagePreview.create(index,images)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),ImagePreview)
	
	scene:addChild(layer)
	layer._imgs = images
	layer._current = index
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function ImagePreview:init()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	self._imageview = uikits.child(self._root,ui.IMAGEVIEW)
	self._scrollview = uikits.child(self._root,ui.SCROLLVIEW)
	self._pageview = uikits.child(self._root,ui.PAGEVIEW)
	self._layout = uikits.child(self._root,ui.LAYOUT)
	self._close = uikits.child(self._root,ui.CLOSE)
	uikits.event(self._close,function(sender)
		uikits.popScene()
	end)
	self._text = uikits.child(self._root,ui.TEXT)
	
	local cs = self._pageview:getContentSize()
	
	for i,v in pairs(self._imgs) do
		local layout
		if i == 1 then
			layout = self._pageview:getPage(0)
		else
			layout = self._layout:clone()
			self._pageview:addPage( layout )
		end
		local img = uikits.child(layout,ui.IMAGEVIEW)
		img:loadTexture(v)
		local size = img:getContentSize()
		local masize = {}
		masize.width = math.max(cs.width,size.width)
		masize.height = math.max(cs.height,size.height)
		img:setPosition(cc.p(masize.width/2,masize.height/2))
		layout._scale = 1	
	end
	
	uikits.event(self._pageview,function(sender,eventType)
		if eventType == ccui.PageViewEventType.turning then
			local i = sender:getCurPageIndex()
			self._text:setString(tostring(i+1).."/"..(#self._imgs))
		end
	end)
	
	self._pageview:scrollToPage(self._current-1)
	
	--注册滚动事件
	local function onTouchMoved(touches, event)
		local count = table.getn(touches)	
		kits.log("Number of touches: ",count)
		for i,v in pairs(touches) do
			kits.log("Touch #"..i)
			kits.log("getLocation : "..v:getLocation().x..v:getLocation().y)
			kits.log("getStartLocation : "..v:getStartLocation().x..v:getStartLocation().y)
			kits.log("getDelta : "..v:getDelta().x..v:getDelta().y)
		end
	end
	local function onTouchBegan(touches, event)
		onTouchMoved(touches, event)
	end	
	local listener = cc.EventListenerTouchAllAtOnce:create()
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )	
	local eventDispatcher=self._pageview:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener,self._pageview)		
end

function ImagePreview:release()
	
end

return ImagePreview