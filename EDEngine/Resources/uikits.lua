require "Cocos2d"
require "Cocos2dConstants"
require "Opengl"
require "OpenglConstants"
require "StudioConstants"
require "GuiConstants"

local defaultFont = "fonts/Marker Felt.ttf"
local defaultFontSize = 16

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
			tx:setAnchorPoint{x=t.anchorX or 0,y=t.anchorY or 0}
			tx:setPosition{x=t.x or 0,y=t.y or 0}
		else
			print('uikits.text create ccui.Text failed return nil')
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
		cb:setAnchorPoint{x=t.anchorX or 0,y=t.anchorY or 0}
		cb:setPosition{x=t.x or 0,y=t.y or 0}
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
		cb:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
		cb:setPosition{x=t.x or 0,y= t.y or 0}
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
		s:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
		s:setPosition{x=t.x or 0,y= t.y or 0}
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
		s:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
		s:setPosition{x=t.x or 0,y= t.y or 0}		
		s:setPercent(t.percent or 0)
	end
	return s
end

local function scrollview( t )
	local s
	if t and type(t)=='table' then
		s = ccui.ScrollView:create()
		s:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
		s:setPosition{x=t.x or 0,y= t.y or 0}	
		s:setSize{width=t.width or 320,height=t.height or 200 }
	end
	return s
end

local function editbox( t )
	local s
	if t and type(t)=='table' then
		s = ccui.TextField:create()
		s:setTouchEnabled(true)
		s:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
		s:setPosition{x=t.x or 0,y= t.y or 0}	
		s:setSize{width=t.width or 160,height=t.height or 32 }
		s:setFontSize( t.fontSize or defaultFontSize )
		s:setFontName( t.font or defaultFont)
		s:setPlaceHolder( t.caption or '' )
		if t.event and type(t.event)=='function' then
			slider:addEventListenerTextField(t.event)
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
		s:setAnchorPoint{x= t.anchorX or 0,y= t.anchorY or 0}
		s:setPosition{x=t.x or 0,y= t.y or 0}	
		if t.image then
			s:loadTexture(t.image)
		end
		s:setScale9Enabled( t.scale9 or false )
		s:setTouchEnabled( t.touch or false )
		if t.width and t.height then
			s:setSize{width=t.width,height=t.height}
		end
	end
	return s
end

local function test( layer )
	local ss = screenSize()
	InitDesignResolutionMode()
	
	local sv = scrollview{width=ss.width,height=ss.height}
	layer:addChild(sv)
	
	local h = 0
	for i = 1,32 do
		local t = text{caption="ccui.Text [ "..i.." ]",fontSize=30}
		local y =  (i-1)*t:getSize().height
		h = h + t:getSize().height
		t:setPosition{x=0,y=y}
		sv:addChild(t)
		--checkbox
		local c = checkbox{x=t:getSize().width,y=y,check=i%2==1 and true or false,
						eventSelect=function (sender,b) print(b) end}
		sv:addChild(c)
		--button
		local b = button{x=t:getSize().width+c:getSize().width,y=y,
											fontSize=32,width=320,height=c:getSize().height,
											caption="ccui.Button 中文"..i,
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
	sv:setInnerContainerSize{width=ss.width,height=h}
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
	test = test,
	screenSize = screenSize
}