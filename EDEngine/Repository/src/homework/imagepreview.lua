local kits = require "kits"
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
	self._pageview = uikits.child(self._root,ui.PAGEVIEW)
	self._layout = uikits.child(self._root,ui.LAYOUT)
	self._close = uikits.child(self._root,ui.CLOSE)
	uikits.event(self._close,function(sender)
		--self:runAction(cc.ScaleTo:create(0.1,0.01) )
		--uikits.delay_call( self,function()
		--	uikits.popScene() end,0.1 )
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
	end
	
	uikits.event(self._pageview,function(sender,eventType)
		if eventType == ccui.PageViewEventType.turning then
			local i = sender:getCurPageIndex()
			self._text:setString(tostring(i+1).."/"..(#self._imgs))
		end
	end)
	
	self._pageview:scrollToPage(self._current-1)
	
	--提示到顶了
	local function text_tips()
		local action1 = cc.ScaleTo:create(0.2,2)
		local action2 = cc.ScaleTo:create(0.1,1)
		self._text:runAction( cc.Sequence:create(action1,action2) )
	end
	--注册滚动事件
	local newTouch
	local touchAction
	local oldx,oldy,oldscale
	local function onTouchMoved(touches, event)
		local count = #touches
		
		if count == 1 then
			if not newTouch then return end
			local idx = self._pageview:getCurPageIndex()
			local layout = self._pageview:getPage(idx)
			local img = uikits.child(layout,ui.IMAGEVIEW)
			local scale = img:getScaleX()
			local size = img:getContentSize()
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()			
			if scale == 1 then
				--原图没有缩放,翻页
				local dx = p.x-sp.x
				if dx > 100 then
					local idx = self._pageview:getCurPageIndex()
					if idx - 1 >= 0 then
						self._pageview:scrollToPage(idx-1)
						newTouch = nil
					else
						text_tips()
					end
				elseif dx < -100 then
					local idx = self._pageview:getCurPageIndex()
					local layouts = self._pageview:getPages()
					if idx + 1 < #layouts then
						self._pageview:scrollToPage(idx+1)
						newTouch = nil
					else
						text_tips()
					end			
				end
			elseif touchAction == 1 or  touchAction == 3 then
				--偏移
				img:setPosition(cc.p(oldx+(p.x-sp.x),oldy+(p.y-sp.y)))
				touchAction = 3
			end
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
		
			if scale*oldscale < 4 and scale*oldscale > 0.3 then
				if newTouch then
					--定位缩放中心
					local cx = (p1.x+p2.x)/2
					local cy = (p1.y+p2.y)/2
					local p = img:convertToNodeSpace(cc.p(cx,cy))
					local scale = img:getScaleX()
					local size = img:getContentSize()
					 
					local ap = cc.p(p.x/(size.width),p.y/(size.height))
					local oldap = img:getAnchorPoint()
					local oldx,oldy = img:getPosition()
					local delta = {}
					delta.x = oldx + (ap.x - oldap.x)*size.width
					delta.y = oldy + (ap.y - oldap.y)*size.height
					img:setPosition( delta )
					img:setAnchorPoint(ap)
					newTouch=nil --双手缩放
				end
				touchAction = 2
				img:setScaleX(scale*oldscale)
				img:setScaleY(scale*oldscale)
			end
		end
	end
	local function onTouchBegan(touches, event)
		newTouch = true
		touchAction = 1
		local idx = self._pageview:getCurPageIndex()
		local layout = self._pageview:getPage(idx)
		local img = uikits.child(layout,ui.IMAGEVIEW)
		oldx,oldy = img:getPosition()
		oldscale = img:getScaleX()
		onTouchMoved(touches, event)
	end	
	local function onTouchEnded(touches, event)
		if #touches == 1 and (touchAction==1 or touchAction==3 ) then
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()
			if math.sqrt((p.x-sp.x)*(p.x-sp.x)+(p.y-sp.y)*(p.y-sp.y)) < 20 then
				--回归原点
				local idx = self._pageview:getCurPageIndex()
				local layout = self._pageview:getPage(idx)
				local img = uikits.child(layout,ui.IMAGEVIEW)			
				img:setScaleX(1)
				img:setScaleY(1)
				img:setAnchorPoint(cc.p(0.5,0.5))
				img:setPosition(cc.p(cs.width/2,cs.height/2))
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
	
	--做动作
	self:setScaleX(0.2)
	self:setScaleY(0.2)
	self:runAction(cc.ScaleTo:create(0.1,1) )
end

function ImagePreview:release()
	
end

return ImagePreview