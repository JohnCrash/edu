require "Cocos2d"
require "Cocos2dConstants"
require "Opengl"
require "OpenglConstants"
require "StudioConstants"
require "GuiConstants"
require "AudioEngine" 
local kits = require "kits"

local Director = cc.Director:getInstance()
local FileUtils = cc.FileUtils:getInstance()

--local defaultFont="fonts/simfang.ttf"
local defaultFont="Marker Felt"
local defaultFontSize = 32

local function log_caller()
	local caller = debug.getinfo(3,'nSl')
	local func = debug.getinfo(2,'n')
	if caller and func then
		kits.log('	call from '..caller.source..':'..caller.currentline )
		kits.log('		function:'..func.name )
	else
		kits.log("ERROR: log_caller debug.getinfo return nil.")
	end
end

local function playSound( file )
	if FileUtils:isFileExist(file) then
		return AudioEngine.playEffect( file )
	else
		kits.log('ERROR playSound file not exist '..tostring(file))
	end
end

local function pauseSound( id )
	AudioEngine.pauseEffect( id )
end

local function isSoundPlaying( id )
	--cocos2d-x not support isPlaying?
end

local function stopAllSound()
	AudioEngine.stopAllEffects()
end

local ismute

local function muteSound( b )
	ismute = b
end

local function playClickSound()
	if not ismute then
		playSound( 'audio/button_press.mp3' )
	end
end

local function init_layout( s,t )
	local ss = s:getContentSize()
	s:setContentSize{width=t.width or ss.width,height=t.height or ss.height}
	if t.bgcolor and t.bgcolor2 then
		s:setBackGroundColorType(LAYOUT_COLOR_GRADIENT)
		s:setBackGroundColor(t.bgcolor,t.bgcolor2)
	elseif t.bgcolor then
		s:setBackGroundColorType(LAYOUT_COLOR_SOLID)
		s:setBackGroundColor(t.bgcolor)
	end
	if t.bgscale9 then
		s:setBackGroundImageScale9Enabled(t.bgscale9)
	end
	if t.bgimage then
		s:setBackGroundImage(t.bgimage,UI_TEX_TYPE_LOCAL)
	end
end

local function init_node( s,t )
	s:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
	s:setPosition{x=t.x or 0,y= t.y or 0}	
end

local design = {width=1024,height=768}
local scale = 1
local function InitDesignResolutionMode(t)
	local glview = Director:getOpenGLView()
	local ss = glview:getFrameSize()

	if t and type(t)=='table' then
		Director:setContentScaleFactor( t.scale or 1 )
		--[[
				cc.ResolutionPolicy = 
				{
					EXACT_FIT = 0,
					NO_BORDER = 1,
					SHOW_ALL  = 2,
					FIXED_HEIGHT  = 3,
					FIXED_WIDTH  = 4,
					UNKNOWN  = 5,
				}		
		--]]
		glview:setDesignResolutionSize(t.width or ss.width,t.height or ss.height,t.mode or cc.ResolutionPolicy.SHOW_ALL)
		return scale
	end
	return 1
end
local FACTOR_3_4 = 1
local FACTOR_9_16 = 2
local function get_factor()
	local glview = Director:getOpenGLView()
	local ss = glview:getFrameSize()
	local factor = ss.height/ss.width
	if factor > (3/4+9/16)/2 then --更接近3/4
		return FACTOR_3_4,factor
	else --更接近9/16
		return FACTOR_9_16,factor
	end
end

local function get_scale()
	return scale
end

local function screenSize()
	local glview = Director:getOpenGLView()
	return glview:getFrameSize()
end

local function pixelWidth()
	return design.width/screenSize().width
end

local function text( t )
	local tx
	if t and type(t)=='table' then
		tx = ccui.Text:create( t.caption or '',t.font or defaultFont,t.fontSize or defaultFontSize )
		if tx then
			init_node(tx,t)
			tx:setColor( t.color or cc.c3b(255,255,255) )
		else
			print('uikits.text create ccui.Text failed return nil')
		end
		if t.event then
			tx:addTouchEventListener(t.event)
			--[[ Event function prototype
				local function touchEvent(sender, eventType)
					if eventType == ccui.TouchEventType.began then
					elseif eventType == ccui.TouchEventType.ended then
					end
				end			
			--]]
		end	
		if t.eventClick and not t.event and type(t.eventClick) == 'function' then
			tx:addTouchEventListener(
				function (sender,eventType) 
					if eventType == ccui.TouchEventType.ended then
						t.eventClick( sender )
					end
				end)
		end		
	end
	return tx
end

local function textbmfont( t )
	local tx
	if t and type(t)=='table' then
		tx = ccui.TextBMFont:create()
		
		if tx then
			init_node(tx,t)
			tx:setString( t.caption or '' )
			tx:setFntFile( t.font or defaultFont )
			tx:setColor( t.color or cc.c3b(255,255,255) )
		else
			print('uikits.text create ccui.Text failed return nil')
		end
		if t.event then
			tx:addTouchEventListener(t.event)
			--[[ Event function prototype
				local function touchEvent(sender, eventType)
					if eventType == ccui.TouchEventType.began then
					elseif eventType == ccui.TouchEventType.ended then
					end
				end			
			--]]
		end	
		if t.eventClick and not t.event and type(t.eventClick) == 'function' then
			tx:addTouchEventListener(
				function (sender,eventType) 
					if eventType == ccui.TouchEventType.ended then
						t.eventClick( sender )
					end
				end)
		end		
	end
	return tx
end

local function checkbox( t )
	local cb
	if t and type(t)=='table' then
		cb = ccui.CheckBox:create()
		cb:setTouchEnabled(true)
		cb:loadTextures(t.normal or "cocosui/check_box_normal.png",
									t.press or "cocosui/check_box_normal_press.png",
								   t.active or "cocosui/check_box_active.png",
								   t.disable or "cocosui/check_box_normal_disable.png",
								   t.active_disable or "cocosui/check_box_active_disable.png")
		init_node(cb,t)
		if t.check then
			cb:setSelectedState( t.check )
		end
		if t.event and type(t.event) == 'function' then
			cb:addEventListener(t.event)
			--[[ Event function prototype
				local function selectedEvent(sender,eventType)
				if eventType == ccui.CheckBoxEventType.selected then
					print("Selected")
				elseif eventType == ccui.CheckBoxEventType.unselected then
					print("Unselected")
				end
				end 
			--]]		
		end
		if t.eventSelect and not t.event and type(t.eventSelect) == 'function' then
			local function event_select(sender,eventType)
				if eventType == ccui.CheckBoxEventType.selected then
					playClickSound()
					t.eventSelect(sender,true)
				elseif eventType == ccui.CheckBoxEventType.unselected then
					t.eventSelect(sender,false)
				end
			end
			cb:addEventListener(event_select)
		end
	end
	return cb
end

local function button( t )
	local cb
	if t and type(t)=='table' then
		cb = ccui.Button:create()
		cb:setScale9Enabled(true)
		cb:loadTextures(t.normal or "cocosui/button.png", 
					t.press or "cocosui/buttonHighlighted.png", 
					t.disable or "")
		init_node(cb,t)
		cb:setContentSize{width = t.width or 64,height = t.height or 32}
		cb:setTitleFontSize( t.fontSize or defaultFontSize )
		cb:setTitleFontName( t.font or defaultFont)
		cb:setTitleText( t.caption or '' )
		if t.event then
			cb:addTouchEventListener(t.event)
			--[[ Event function prototype
				local function touchEvent(sender, eventType)
					if eventType == ccui.TouchEventType.began then
					elseif eventType == ccui.TouchEventType.ended then
					end
				end			
			--]]
		end	
		if t.eventClick and not t.event and type(t.eventClick) == 'function' then
			cb:addTouchEventListener(
				function (sender,eventType) 
					if eventType == ccui.TouchEventType.ended then
						playClickSound()
						t.eventClick( sender )
					end
				end)
		end
	end
	return cb
end

local function slider( t )
	local s
	if t and type(t)=='table' then
		s = ccui.Slider:create()
		s:loadBarTexture( t.loadBar or "cocosui/sliderTrack.png")
		s:loadSlidBallTextures( t.slidBall or "cocosui/sliderThumb.png", "cocosui/sliderThumb.png", "")
		s:loadProgressBarTexture(t.progressBar or "cocosui/sliderProgress.png")
		init_node(s,t)
		s:setContentSize{width=t.width or 160,height=t.height or 32 }
		s:setPercent( t.percent or 0 )
		if t.event and type(t.event)=='function' then
			slider:addEventListener(t.event)
		end
		if t.eventPercent and not t.event and type(t.eventPercent) == 'function' then
			s:addEventListener(function (sender,eventType)
															if eventType == ccui.SliderEventType.percentChanged then
																t.eventPercent(sender,sender:getPercent())
															end
														end)
		end
	end
	return s
end

local function progress( t )
	local s
	if t and type(t)=='table' then
		s = ccui.LoadingBar:create()
		s:loadTexture(t.progress or "cocosui/sliderProgress.png")
		init_node(s,t)
		s:setPercent(t.percent or 0)
	end
	return s
end

local function scrollview( t )
	local s
	if t and type(t)=='table' then
		s = ccui.ScrollView:create()
		init_node(s,t)
		s:setContentSize{width=t.width or 320,height=t.height or 200 }
		if t.event and type(t.event)=='function' then
			s:addEventListener(t.event)
			--[[ Event function prototype
				local function scrollEvent(sender, eventType)
					if eventType == SCROLLVIEW_EVENT_SCROLLING  then
					end
				end			
			--]]			
		end
		init_layout(s,t)
	end
	return s
end

local function editbox( t )
	local s
	if t and type(t)=='table' then
		s = ccui.TextField:create()
		s:setTouchEnabled(true)
		init_node(s,t)
		s:setContentSize{width=t.width or 160,height=t.height or 32 }
		s:setFontSize( t.fontSize or defaultFontSize )
		s:setFontName( t.font or defaultFont)
		s:setPlaceHolder( t.caption or '' )
		if t.event and type(t.event)=='function' then
			s:addEventListener(t.event)
			--[[ Event function prototype
					local function textFieldEvent(sender, eventType)
						if eventType == ccui.TextFiledEventType.attach_with_ime then
						elseif eventType == ccui.TextFiledEventType.detach_with_ime then
						elseif eventType == ccui.TextFiledEventType.insert_text then
						elseif eventType == ccui.TextFiledEventType.delete_backward then
						end
					end
			--]]
		end
	end
	return s
end

local function imageview( t )
	local s
	if t and type(t)=='table' then
		s = ccui.ImageView:create()
		
		if t.image and FileUtils:isFileExist(t.image) then
			kits.log('imageview loadTexture '..t.image)
			s:loadTexture(t.image)
		end
		--local ss = s:getContentSize()
		--s:setContentSize{width=t.width or 16,height=t.height or 16}		
		s:setScale9Enabled( t.scale9 or false )
		s:setTouchEnabled( t.touch or false )
		init_node( s,t )
	end
	return s
end

local function layout( t )
	local s
	if t and type(t)=='table' then
		s = ccui.Layout:create()
		init_node( s,t )
		init_layout( s,t )
	end
	return s
end

local function pageview( t )
	local s
	if t and type(t)=='table' then
		s = ccui.PageView:create()
		init_node(s,t)
		init_layout(s,t)
		s:setTouchEnabled(true)
		if t.event then
			s:addEventListener(t.event)
			--[[ Event function prototype
			local function pageViewEvent(sender, eventType)
				if eventType == ccui.PageViewEventType.turning then
				end
			end 			
			]]--
		end
	end
	return s
end

local function menu( t )
	local s
	if t and type(t)=='table' then
		if t.items and type(t.items)=='table' then
			s = cc.Menu:create( unpack(t.items) )
		else
			s = cc.Menu:create()
		end
		--init_node(s,t)
		if t.alignV then
			s:alignItemsVertically()
		end
	end
	return s
end

local function init_menuitem( s,t )
	if t.event then
		s:registerScriptTapHandler(t.event)
		--[[ Event function prototype
			local function (tag, sender)
			end
		--]]
	end
end

local function menuItemLabel( t )
	local s
	if t and type(t)=='table' then
		s = cc.MenuItemLabel:create(t.caption or '')
		init_node(s,t)
		init_menuitem(s,t)
	end
	return s
end

local function menuItemFont( t )
	local s
	if t and type(t)=='table' then
		s = cc.MenuItemFont:create(t.caption or '')
		init_node(s,t)
		--cocos2d lua BUG
		--s:setFontName(t.font or defaultFont)
		--s:setFontSize(t.fontSize or defaultFontSize)
		init_menuitem(s,t)
	end
	return s
end

local function extend(target,_class)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, _class)
    return target
end

local function fromJson( t )
	local s
	if t and type(t)=='table' then
		if t.file and type(t.file)=='string' then
			s = ccs.GUIReader:getInstance():widgetFromJsonFile(t.file)
		elseif t.file_9_16 and t.file_3_4 then
			--根据不同的分辨率加载文件
			if get_factor() == FACTOR_3_4 then
				s = ccs.GUIReader:getInstance():widgetFromJsonFile(t.file_3_4)
			else
				s = ccs.GUIReader:getInstance():widgetFromJsonFile(t.file_9_16)
			end
		end
	end
	if not s then
		kits.log('uikits.fromJson return nil')
		log_caller()
	end
	return s
end

--root is ui.Widget
--path 'root/brach/child'
local function child( root,path )
	local c={}
	local i = 1
	local j
	if path and type(path)=='string' and string.len(path)>0 then
		while true do
			j = string.find(path,'/',i)
			if j then
				c[#c+1] = string.sub(path,i,j-1)
			else
				c[#c+1] = string.sub(path,i)
				break
			end
			i = j + 1
		end
		local w = root
		for i,v in ipairs(c) do
			if w then
				local wt
				wt = w:getChildByName( v )
				if not wt then wt = w:getChildByTag( v ) end
				w = wt
			end
		end
		if w == root then
			--打印调用者信息
			kits.log('ERROR: uikits.child return nil')
			log_caller()
		else
			return w
		end
	else
			--打印调用者信息
			kits.log('ERROR: uikits.child return nil')
			log_caller()
	end
end

local isTouchEvent = {
	['ccui.Button'] = true,
	['ccui.Text'] = true
}

local function event( obj,func,eventType )
	if obj and func then
		obj:setTouchEnabled(true)
		if eventType then
			if eventType == 'click' then
				obj:addTouchEventListener( 
				function(sender,eventType) 
					if eventType == ccui.TouchEventType.ended then
						playClickSound()
						func( sender,x,y )
					end
				end)				
			elseif eventType == 'began' then
				obj:addTouchEventListener( 
				function(sender,eventType) 
					if eventType == ccui.TouchEventType.began then
						playClickSound()
						func( sender,x,y )
					end
				end)			
			end
		elseif isTouchEvent[cc_type(obj)] then
			obj:addTouchEventListener( 
				function(sender,eventType) 
					if eventType == ccui.TouchEventType.ended then
						playClickSound()
						func( sender )
					end
				end)
		elseif cc_type(obj) == 'ccui.CheckBox' then
			obj:addEventListener(
				function(sender,eventType)
					if eventType == ccui.CheckBoxEventType.selected then
						playClickSound()
						func(sender,true)
					elseif eventType == ccui.CheckBoxEventType.unselected then
						func(sender,false)
					end
				end)
		elseif cc_type(obj)=='ccui.Slider' then
			obj:addEventListener(func)
		elseif cc_type(obj)=='ccui.ScrollView' then
			obj:addEventListener(func)
		elseif cc_type(obj)=='ccui.PageView' then
			obj:addEventListener(func)
		elseif cc_type(obj)=='ccui.TextField' then
			obj:addEventListener(func)
		elseif cc_type(obj)=='cc.MenuItemFont' then
			obj:registerScriptTapHandler(func)
		else
			error('uikits.event not support type:'..cc_type(obj))
		end
	end
end

local function delay_call( target,func,delay,param1,param2,param3 )
	local obj = target
	if not target then
		obj = cc.Director:getInstance() --如果没有对象，使用全局对象
	end
	if obj and func and delay then
		 local scheduler = obj:getScheduler()
		 local schedulerID
		 local function delay_call_func()
			scheduler:unscheduleScriptEntry(schedulerID)
			schedulerID = nil		
			func(param1,param2,param3)
		end
		schedulerID = scheduler:scheduleScriptFunc(delay_call_func,delay,false)	
	end
end

local function timer( obj,func,delay,param1,param2,param3)
	if obj and func and delay then
		 local scheduler = obj:getScheduler()
		 local schedulerID
		 local function delay_call_func()
			scheduler:unscheduleScriptEntry(schedulerID)
			schedulerID = nil		
			func(obj,param1,param2,param3)
		end
		schedulerID = scheduler:scheduleScriptFunc(delay_call_func,delay,false)		 
	end
end

local function pushScene( scene,transition,t )
	if transition then
		Director:pushScene( transition:create(t or 1,scene) )
	else
		Director:pushScene( scene )
	end
end

--横向布局,
local function relayout_h( items,xx,y,width,space,scale,expet )
	local w
	local h
	if space then
		w = space
	else
		w = 0
	end
	h = w
	if items and type(items)=='table' then
		for i,v in pairs(items) do
			local size = v:getContentSize()
			
			if scale then
				size.width = size.width*scale
				size.height = size.height*scale
				v:setScaleX(scale)
				v:setScaleY(scale)
			end
			
			if space then
				w = w + size.width + space
			else
				w = w + size.width + space
			end
			h = size.height > h and size.height or h
		end
		--居中
		local x = (width-w)/2 + xx
		for i,v in pairs(items) do
			local size = v:getContentSize()
			if scale then
				size.width = size.width*scale
				size.height = size.height*scale			
			end
			if v ~= expet then
				v:setPosition{x=x,y=y}
			end
			if space then
				x = x + size.width + space
			else
				x = x + size.width
			end
		end
	end
	return {x=(width-w)/2,y=y,width=w,height=h}
end

--纵向布局
local function relayout_v( items,x,space,scale )
	for i,v in pairs(items) do
	end
end

local function move( items,dx,dy )
	if items and type(items)=='table' then
		for i,v in pairs(items) do
			local x,y = v:getPosition()
			x = dx and x + dx or x
			y = dy and y + dy or y
			v:setPosition(cc.p(x,y))
		end
	end
end

local function line(t)
	if t and type(t)=='table' then
		local glNode = gl.glNodeCreate()
		glNode:setContentSize(cc.size(math.abs(t.x2-t.x1),math.abs(t.y2-t.y1)))
		glNode:setAnchorPoint{x=t.anchorX or 0,y=t.anchorY or 0}
		local function primitivesDraw(transform, transformUpdated)
		   kmGLPushMatrix()
         kmGLLoadMatrix(transform)
		 
			gl.lineWidth(t.linewidth or 1)
			if t.color then
				cc.DrawPrimitives.drawColor4B(t.color.r or 0,t.color.g or 0,t.color.b or 0,t.color.a or 255)
			else
				cc.DrawPrimitives.drawColor4B(0,0,0,255)
			end
			cc.DrawPrimitives.drawLine( cc.p(t.x1,t.y1),cc.p(t.x2,t.y2) )
			
			kmGLPopMatrix()
		end
		glNode:registerScriptDrawHandler(primitivesDraw)
		return glNode
	end
end

local function rect(t)
	if t and type(t)=='table' then
		local glNode = gl.glNodeCreate()
		glNode:setContentSize(cc.size(math.abs(t.x2-t.x1),math.abs(t.y2-t.y1)))
		glNode:setAnchorPoint{x=t.anchorX or 0,y=t.anchorY or 0}
		local function primitivesDraw(transform, transformUpdated)
		   kmGLPushMatrix()
         kmGLLoadMatrix(transform)
		 
			gl.lineWidth(t.linewidth or 1)
			if t.color then
				cc.DrawPrimitives.drawColor4B(t.color.r or 0,t.color.g or 0,t.color.b or 0,t.color.a or 255)
			else
				cc.DrawPrimitives.drawColor4B(0,0,0,255)
			end
			local pts = {cc.p(t.x1,t.y1),cc.p(t.x1,t.y2),cc.p(t.x2,t.y2),cc.p(t.x2,t.y1)}
			if t.fillColor then
				cc.DrawPrimitives.drawSolidPoly(pts,4,t.fillColor)
				if t.color then
					cc.DrawPrimitives.drawPoly(pts,4,true)
				end
			else
				cc.DrawPrimitives.drawPoly(pts,4,true)
			end
			
			kmGLPopMatrix()
		end
		glNode:registerScriptDrawHandler(primitivesDraw)
		return glNode
	end
end

local function popScene()
	Director:popScene()
end

local function set_item(c,v)
	if c then
		if c and (cc_type(c)=='ccui.TextField' or cc_type(c)=='ccui.Text' or
					cc_type(c)=='ccui.Button') then
			if cc_type(c)=='ccui.Button' then
				c:setTitleText( tostring(v) )
			else
				c:setString( tostring(v) )
			end
		elseif c and cc_type(c)=='ccui.Slider' then
			if type(v) == 'number' then
				c:setPercent( v )
			end
		else
			kits.log('ERROR set_item unknow set type')
			log_caller()
		end
	else
		kits.log('ERROR set_item item = nil')
		log_caller()
	end
end

--itemID2 代表可能的第二类item
local function scroll(root,scrollID,itemID,horiz,space,itemID2)
	local t = {_root = root}
	if scrollID then
		t._scrollview = child(root,scrollID)
	else
		t._scrollview = root
	end
	t._item = child(t._scrollview,itemID)
	if not t._scrollview or not t._item then
		kits.log('ERROR : scroll resource not exist')
		log_caller()
		return
	end
	if itemID2 then
		t._item2 = child(t._scrollview,itemID2)
		if t._item2 then t._item2:setVisible(false) end
	end
	local space = space or 0
	t._list = {}
	t._item:setVisible(false)
	local size = t._item:getContentSize()
	t._item:setAnchorPoint(cc.p(0,0))
	t._item_width = size.width
	t._item_height = size.height
	t._item_ox,t._item_oy = t._item:getPosition()

		--将不是_item的子节点都视为tops，tops在滚动布局中保持顶部位置
		local nodes = t._scrollview:getChildren()
		t._tops = {}
		for i,v in pairs(nodes) do
			if v ~= t._item and v~= t._item2 then
				--v:setAnchorPoint(cc.p(0,0))
				v._ox,v._oy = v:getPosition()
				if v._oy > t._item_oy then
					if not t._tops_space then
						t._tops_space = v._oy - t._item_oy - t._item_height
					end
					table.insert(t._tops,v)
				end
			end
		end

	t.relayout = function(self)
		if horiz then --横向
			local width = 0
			local item_max_height = 0
			for i=1,#self._list do
				local size = self._list[i]:getContentSize()
				width = width + size.width + space
				item_max_height = math.max(item_max_height,size.height)
			end
			if self._scrollview.setInnerContainerSize then
				self._scrollview:setInnerContainerSize(cc.size(width,_item_height))
			else
				local size = self._scrollview:getContentSize()
				local dh = item_max_height - self._item_height
				if dh > 0 then
					self._scrollview:setContentSize(cc.size(size.width,size.height+dh))
					move( self._tops,0,dh)
				end
			end

			local item_width = self._item_ox
			for i = 1,#self._list do
				self._list[#self._list-i+1]:setPosition(cc.p(item_width,self._item_oy))
				item_width = item_width + self._list[#self._list-i+1]:getContentSize().width + space
			end
		else --纵向
			local cs = self._scrollview:getContentSize()
			local height = 0
			if not self._item2 then
				height = cs.height-self._item_oy-self._item_height --self._item_height*(#self._list)
			end
			for i=1,#self._list do
				height = height + self._list[i]:getContentSize().height + space
			end
			if self._scrollview.setInnerContainerSize then
				self._scrollview:setInnerContainerSize(cc.size(self._item_width,height))
			end
			local offy = 0
			local size = self._scrollview:getContentSize()
			
			if height < size.height then
				offy = size.height - height --顶到顶
			end
			local item_height = 0
			for i = 1,#self._list do
				self._list[#self._list-i+1]:setPosition(cc.p(self._item_ox,item_height+offy))
				item_height = item_height + self._list[#self._list-i+1]:getContentSize().height + space
			end
			--放置置顶元件
			if self._tops_space then
				item_height = item_height + self._tops_space--起始阶段置顶元件和item的间隔
				for i = 1,#self._tops do
					self._tops[i]:setPosition(cc.p(self._tops[i]._ox,item_height+offy))
				end
			end
		end
	end
	t.setVisible = function(self,b)
		self._scrollview:setVisible(b)
	end
	t.additem = function(self,data,index)
		local item
		if index == 2 then
			item = self._item2:clone()
		else
			item = self._item:clone()
		end
		if item then
			self._list[#self._list+1] = item
			item:setVisible(true)
			item:setAnchorPoint(cc.p(0,0))
			self._scrollview:addChild(item)
		end
		if item and data and type(data)=='table' then
			for k,v in pairs(data) do
				if k and type(k)=='string' and v and type(v)=='function' then
					local c = child(item,k)
					if c then
						v(c,item)
					end
				elseif k and v then
					local c = child(item,k)
					set_item(c,v)
				end
			end
		end
		return item
	end
	t.clear = function(self)
		for i=1,#self._list do
			self._list[i]:removeFromParent()
		end
		self._list = {}
	end
	return t
end

local function tab(root,LineID,butTable)
	local t = {_root = root}
	t._line = child(root,LineID)
	if not t._line then
		kits.log('ERROR tab _line = nil at '..tostring(LineID))
		log_caller()
		return
	end
	t._line_x,t._line_y = t._line:getPosition()
	t._line_size = t._line:getContentSize()
	t._line_anchor_pt = t._line:getAnchorPoint()
	t._buts = {}
	t.set = function( self,i )
		if self._buts and type(self._buts)=='table' and self._buts[i] then
			local sender = t._buts[i]
			local x,y = sender:getPosition()
			local pt = sender:getAnchorPoint()
			local size = sender:getContentSize()
			local xx = x-pt.x*size.width+t._line_anchor_pt.x*t._line_size.width
			t._line:setPosition(cc.p(xx,t._line_y))			
		else
			kits.log('ERROR uikits tab but = nil at '..tostring(i))
		end
	end
	if butTable and type(butTable)=='table' then
		for i,v in pairs(butTable) do
			local but = child(root,i)
			if but and cc_type(but) =='ccui.Button' and v and type(v)=='function' then
				event(but,function(sender)
						if v(sender) then
							local x,y = sender:getPosition()
							local pt = sender:getAnchorPoint()
							local size = sender:getContentSize()
							local xx = x-pt.x*size.width+t._line_anchor_pt.x*t._line_size.width
							t._line:setPosition(cc.p(xx,t._line_y))
						end
					end)
				table.insert(t._buts,but)
			else
				kits.log('ERROR tab but = nil at '..tostring(v))
				log_caller()
			end
		end
	else
		kits.log('ERROR tab butTable=nil or not table')
		log_caller()
		return
	end
	return t
end

local function set(root,t)
	if t and type(t)=='table' then
		for k,v in pairs(t) do
			local item = child(root,k)
			if item then
				set_item(item,v)
			else
				kits.log('ERROR set '..tostring(k)..' cant found tag on root' )
				log_caller()
			end
		end
	else
		kits.log('ERROR set invalid paramter')
		log_caller()
	end
end

local function fitsize(child,w,h)
	local size = child:getContentSize()
	child:setScaleX(w/size.width/get_scale())
	child:setScaleY(h/size.height/get_scale())
end

local function scrollview_step_add(scrollview,t,n,add_func,sstate)
	if t and type(t)=='table' and scrollview and n and add_func 
	and type(add_func)=='function' then
		sstate = sstate or ccui.ScrollviewEventType.scrollToBottom
		local count = table.maxn(t)
		local offset = 1
		local function add_n_item(s,n)
			for i=s,s+n do
				add_func(t[i])
			end			
			add_func() --重新布局
		end
		if n < count then --只有在还有没添加的才关闭回弹
			scrollview:setBounceEnabled(false)
		end
		add_n_item(offset,n)
		offset = offset + n + 1
		event( scrollview,function(sender,state)
				if state == sstate then
					if offset <= count then
						add_n_item( offset,n )
						offset = offset + n + 1
					else
						scrollview:setBounceEnabled(true)
					end
				end
			end)
	else
		kits.log('ERROR uikits.scrollview_step_add invalid argument')
	end
end

return {
	text = text,
	textbmfont = textbmfont,
	checkbox = checkbox,
	button = button,
	slider = slider,
	progress = progress,
	scrollview = scrollview,
	pageview = pageview,
	layout = layout,
	editbox = editbox,
	image = imageview,
	menu = menu,
	menuItemFont = menuItemFont,
	menuItemLabel = menuItemLabel,
	fromJson = fromJson,
	extend = extend,
	child = child,
	event = event,
	screenSize = screenSize,
	pixelWidth = pixelWidth,
	delay_call = delay_call,
	pushScene = pushScene,
	popScene = popScene,
	relayout_h = relayout_h,
	relayout_v = relayout_v,
	initDR = InitDesignResolutionMode,
	line = line,
	rect = rect,
	move = move,
	scale = get_scale,
	isSoundPlaying = isSoundPlaying,
	pauseSound = pauseSound,
	playSound = playSound,
	stopAllSound = stopAllSound,
	log_caller = log_caller,
	FACTOR_3_4 = FACTOR_3_4,
	FACTOR_9_16 = FACTOR_9_16,
	get_factor = get_factor,
	scroll = scroll,
	tab = tab,
	set = set,
	set_item = set_item,
	fitsize = fitsize,
	scrollview_step_add = scrollview_step_add,
	muteSound = muteSound,
	playClickSound = playClickSound,
}
