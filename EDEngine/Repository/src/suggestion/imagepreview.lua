local kits = require "kits"
local uikits = require "uikits"

local ui = {
	FILE = "errortitlenew/imagepreview.json",
	FILE_3_4 = "errortitlenew/imagepreview43.json",
	IMAGEVIEW = "scrollview/image",
	SCROLLVIEW = "scrollview",
	PAGEVIEW = "pageview",
	TEXT = "top/text",
	CLOSE = "top/exit",
	LAYOUT = "pageview/layout",
}

local ImagePreview = class("ImagePreview")
ImagePreview.__index = ImagePreview

function ImagePreview.create(index,images,parent_view)
--function ImagePreview.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),ImagePreview)
	
	scene:addChild(layer)
	layer._imgs = images
	layer._current = index
	layer._parent_view = parent_view
	layer._parent_view.isneedupdate = false
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
--	self._imageview = uikits.child(self._root,ui.IMAGEVIEW)
	self._pageview = uikits.child(self._root,ui.PAGEVIEW)
	self._layout = uikits.child(self._root,ui.LAYOUT)
	self._close = uikits.child(self._root,ui.CLOSE)
	self._close:setVisible(false)
	uikits.event(self._close,function(sender)
		uikits.popScene()
	end)
	self._text = uikits.child(self._root,ui.TEXT)
	self._text:setVisible(false)
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
	end
	
	uikits.event(self._pageview,function(sender,eventType)
		if eventType == ccui.PageViewEventType.turning then
			local i = sender:getCurPageIndex()
			self._text:setString(tostring(i+1).."/"..(#self._imgs))
		end
	end)
	
	self._pageview:scrollToPage(self._current-1)
	
	--注册滚动事件
	local newTouch
	local oldx,oldy,oldscale
	local function onTouchMoved(touches, event)
		local count = #touches
		print('count::::'..count)
		if not newTouch then return end
		if count == 1 then
			local idx = self._pageview:getCurPageIndex()
			local layout = self._pageview:getPage(idx)
			local img = uikits.child(layout,ui.IMAGEVIEW)
			local scale = img:getScaleX()
			local size = img:getContentSize()
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()			
			img:setPosition(cc.p(oldx+(p.x-sp.x),oldy+(p.y-sp.y)))
		elseif count == 2 then
			local p1 = touches[1]:getLocation()
			local sp1 = touches[1]:getStartLocation()
			local p2 = touches[2]:getLocation()
			local sp2 = touches[2]:getStartLocation()		
			local sd = math.sqrt((sp1.x-sp2.x)*(sp1.x-sp2.x) + (sp1.y-sp2.y)*(sp1.y-sp2.y))
			local d = math.sqrt((p1.x-p2.x)*(p1.x-p2.x) + (p1.y-p2.y)*(p1.y-p2.y))
			local idx = self._pageview:getCurPageIndex()
			local layout = self._pageview:getPage(idx)
			local img = uikits.child(layout,ui.IMAGEVIEW)
			local scale = d/sd
			img:setScaleX(scale*oldscale)
			img:setScaleY(scale*oldscale)
		end
	end
	local function onTouchBegan(touches, event)
		print('1111111111')
		newTouch = true
		local idx = self._pageview:getCurPageIndex()
		local layout = self._pageview:getPage(idx)
		local img = uikits.child(layout,ui.IMAGEVIEW)
		oldx,oldy = img:getPosition()
		oldscale = img:getScaleX()
		onTouchMoved(touches, event)
	end	
	local function onTouchEnded(touches, event)
		if #touches == 1 then
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()
			if math.sqrt((p.x-sp.x)*(p.x-sp.x)+(p.y-sp.y)*(p.y-sp.y)) < 20 then
				uikits.popScene()
			end
		end
	end
	
	local listener = cc.EventListenerTouchAllAtOnce:create()
	listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )	
	listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCHES_ENDED )	
	local eventDispatcher=self:getEventDispatcher()
	self:setTouchEnabled(true)
	self._pageview:setTouchEnabled(false)
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener,self)		
end

function ImagePreview:release()
	
end

return ImagePreview