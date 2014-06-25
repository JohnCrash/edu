require "Cocos2d"
require "Cocos2dConstants"
require "Opengl"
require "OpenglConstants"
require "StudioConstants"
require "GuiConstants"

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

function InitDesignResolutionMode()
	local director = cc.Director:getInstance()
	local glview = director:getOpenGLView()
	local ss = glview:getFrameSize()
	--print( "GLView FrameSize :"..ss.width.." , "..ss.height )
	director:setContentScaleFactor(1)
	glview:setDesignResolutionSize(ss.width,ss.height,cc.ResolutionPolicy.SHOW_ALL)
end

local function screenSize()
	local director = cc.Director:getInstance()
	local glview = director:getOpenGLView()
	return glview:getFrameSize()
end

local function text( t )
	local tx
	if t and type(t)=='table' then
		tx = ccui.Text:create( t.caption or '',t.font or defaultFont,t.fontSize or defaultFontSize )
		if tx then
			init_node(tx,t)
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
		s = cc.Menu:create()
		init_node(s,t)
		if t.alignV then
			s:alignItemsVertically()
		end
		if t.items and type(t.items)=='table' then
			for k,v in pairs( t.items ) do
				print( k )
				s:addChild( v )
			end
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
		--s:setFontName(t.font or defaultFont)
		--s:setFontSize(t.fontSize or defaultFontSize)
		init_menuitem(s,t)
	end
	return s
end

local function test_menu( layer )
	local item1 = menuItemFont{caption='Quit',fontSize=32}
	local item2 = menuItemFont{caption='Test pushScene',fontSize=32}
	local item2 = menuItemFont{caption='Test pushScene w/transition',fontSize=32}
	local m = cc.Menu:create( item1,item2,item3)
	m:alignItemsVertically()
	--local m = menu{items={item1,item2,item3},alignV=true}
	layer:addChild( m )
end

local function test_page( layer )
	local ss = screenSize()
	InitDesignResolutionMode()
	local sp = pageview{bgcolor=cc.c3b(128,128,128),
									x = 32,y=32,width=ss.width-64,height=ss.height-64,
									event=function(sender,eventType)
										if eventType == ccui.PageViewEventType.turning then
											print( 'page '..sender:getCurPageIndex() + 1 )
										end
									end}
	math.randomseed(os.time())
	for i = 1,32 do
		local lay1 = layout{bgcolor=cc.c3b(math.random(0,255),math.random(0,255),math.random(0,255)),
		bgcolor2=cc.c3b(math.random(0,255),math.random(0,255),math.random(0,255))}
		lay1:addChild(text{caption='Page '..i,fontSize=32})
		sp:addPage(lay1)
	end
	layer:addChild(sp)
end

local function test( layer )
	local ss = screenSize()
	InitDesignResolutionMode()
	
	local sv = scrollview{width=ss.width,height=ss.height,
	event=function(sender,type)
		if type == SCROLLVIEW_EVENT_SCROLLING then
			print( "SCROLLVIEW_EVENT_SCROLLING")
		elseif type == SCROLLVIEW_EVENT_SCROLL_TO_TOP then
			print('SCROLLVIEW_EVENT_SCROLL_TO_TOP')
		elseif type == SCROLLVIEW_EVENT_SCROLL_TO_BOTTOM then
			print('SCROLLVIEW_EVENT_SCROLL_TO_BOTTOM')
		end
	end
	}
	layer:addChild(sv)
	
	local h = 0
	for i = 1,32 do
		local ox,oy = 32,32
		local t = text{caption="Text"..i,fontSize=30,eventClick=function(sender) print("text click")end}
		local y = oy + (i-1)*t:getSize().height
		h = h + t:getSize().height
		t:setPosition{x=ox,y=y}
		sv:addChild(t)
		--checkbox
		local c = checkbox{x=ox+t:getSize().width,y=y,check=i%2==1 and true or false,
						eventSelect=function (sender,b) print(b) end}
		sv:addChild(c)
		--button
		local b = button{x=ox+t:getSize().width+c:getSize().width,y=y,
											fontSize=32,width=320,height=c:getSize().height,
											caption="Button 中文"..i,
											eventClick=function (sender) print('click') end}
		sv:addChild(b)
		--slider
		local s = slider{width=320,height=c:getSize().height,
										x=b:getPosition()+b:getSize().width,y= y,percent=i*100/32,
										eventPercent=function (sender,percent) print(percent) end}
		sv:addChild(s)
		--edit
		local e = editbox{caption='Input here:',
			x=s:getPosition()+s:getSize().width,y= y}
		sv:addChild(e)
		--image
		local img = imageview{image='cocosui/sliderballnormal.png',x=e:getPosition()+e:getSize().width,y=y}
		sv:addChild(img)
		local img2 = imageview{image='cocosui/button.png',x=img:getPosition()+img:getSize().width,y=y,
		scale9=true,width=64,height=32,touch=true}
		sv:addChild(img2)
	end
	sv:setInnerContainerSize{width=ss.width+64,height=h+64}
end

return {
	text = text,
	checkbox = checkbox,
	button = button,
	slider = slider,
	progress = progress,
	scrollview = scrollview,
	editbox = editbox,
	image = imageview,
	menu = menu,
	menuItemFont = menuItemFont,
	menuItemLabel = menuItemLabel,
	test = test,
	test_page = test_page,
	test_menu = test_menu,
	screenSize = screenSize
}