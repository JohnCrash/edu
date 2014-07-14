require "Cocos2d"
require "Cocos2dConstants"
require "Opengl"
require "OpenglConstants"
require "StudioConstants"
require "GuiConstants"

local Director = cc.Director:getInstance()
local defaultFont = "fonts/Marker Felt.ttf"
local defaultFontSize = 16

local function init_layout( s,t )
	local ss = s:getSize()
	s:setSize{width=t.width or ss.width,height=t.height or ss.height}
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
		scale = t.width/ss.width
		return scale
	end
	return 1
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
			cb:addEventListenerCheckBox(t.event)
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
					t.eventSelect(sender,true)
				elseif eventType == ccui.CheckBoxEventType.unselected then
					t.eventSelect(sender,false)
				end
			end
			cb:addEventListenerCheckBox(event_select)
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
		cb:setSize{width = t.width or 64,height = t.height or 32}
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
		s:setSize{width=t.width or 160,height=t.height or 32 }
		s:setPercent( t.percent or 0 )
		if t.event and type(t.event)=='function' then
			slider:addEventListenerSlider(t.event)
		end
		if t.eventPercent and not t.event and type(t.eventPercent) == 'function' then
			s:addEventListenerSlider(function (sender,eventType)
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
		s:setSize{width=t.width or 320,height=t.height or 200 }
		if t.event and type(t.event)=='function' then
			s:addEventListenerScrollView(t.event)
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
		s:setSize{width=t.width or 160,height=t.height or 32 }
		s:setFontSize( t.fontSize or defaultFontSize )
		s:setFontName( t.font or defaultFont)
		s:setPlaceHolder( t.caption or '' )
		if t.event and type(t.event)=='function' then
			s:addEventListenerTextField(t.event)
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
		init_node( s,t )
		if t.image then
			s:loadTexture(t.image)
		end
		local ss = s:getSize()
		s:setSize{width=t.width or ss.width,height=t.height or ss.height}		
		s:setScale9Enabled( t.scale9 or false )
		s:setTouchEnabled( t.touch or false )
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
			s:addEventListenerPageView(t.event)
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
		end
	end
	return s
end

--root is ui.Widget
--path 'root/brach/child'
local function child( root,path )
	local c={}
	local i = 1
	local j
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
		return nil
	else
		return w
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
						func( sender,x,y )
					end
				end)				
			end
		elseif isTouchEvent[cc_type(obj)] then
			obj:addTouchEventListener( 
				function(sender,eventType) 
					if eventType == ccui.TouchEventType.ended then
						func( sender )
					end
				end)
		elseif cc_type(obj) == 'ccui.CheckBox' then
			obj:addEventListenerCheckBox(
				function(sender,eventType)
					if eventType == ccui.CheckBoxEventType.selected then
						func(sender,true)
					elseif eventType == ccui.CheckBoxEventType.unselected then
						func(sender,false)
					end
				end)
		elseif cc_type(obj)=='ccui.Slider' then
			obj:addEventListenerSlider(func)
		elseif cc_type(obj)=='ccui.ScrollView' then
			obj:addEventListenerScrollView(func)
		elseif cc_type(obj)=='ccui.PageView' then
			obj:addEventListenerPageView(func)
		elseif cc_type(obj)=='ccui.TextField' then
			obj:addEventListenerTextField(func)
		elseif cc_type(obj)=='cc.MenuItemFont' then
			obj:registerScriptTapHandler(func)
		else
			error('uikits.event not support type:'..cc_type(obj))
		end
	end
end

local function delay_call( obj,func,delay,param1,param2,param3)
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
			local size = v:getSize()
			
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
			local size = v:getSize()
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
}