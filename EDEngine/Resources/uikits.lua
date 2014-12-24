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

local function playSound( file,ismusic )
	if kits.exist_file(file) or kits.exist_cache(file) or FileUtils:isFileExist(file) then
		local suffix = string.sub(file,-4)
		if string.lower(suffix) == '.amr' then
			if kits.exist_cache(file) then
				return cc_playVoice(kits.get_cache_path()..file)
			else
				return cc_playVoice(file)
			end
		else
			if ismusic then
				return AudioEngine.playMusic( file )
			else
				return AudioEngine.playEffect( file )
			end
		end
	else
		kits.log('ERROR playSound file not exist '..tostring(file))
	end
end

local function voiceLength( file )
	if kits.exist_file(file) or kits.exist_cache(file)  then
		local suffix = string.sub(file,-4)
		if string.lower(suffix) == '.amr' then
			if kits.exist_cache(file) then
				return cc_getVoiceLength(kits.get_cache_path()..file)
			else
				return cc_getVoiceLength(file)
			end			
		end
	else
		kits.log('ERROR voiceLength file not exist '..tostring(file))
	end
	return 0
end

local function pauseSound( id )
	AudioEngine.pauseEffect( id )
end

local function isSoundPlaying( id )
	--cocos2d-x not support isPlaying?
end

local function stopAllSound()
	AudioEngine.stopAllEffects()
	cc_stopVoice()
end

local ismute

local function muteSound( b )
	ismute = b
end

local click_sounds = {
	'audio/click.mp3',
	'audio/scroll.mp3',
	'audio/select.mp3',
	'audio/right.mp3',
	'audio/error.mp3',
}

local function playClickSound( idx )
	if not ismute then
		if idx and type(idx)=='number' and idx<=#click_sounds and idx>0 then
			playSound( click_sounds[idx] )
		else
			playSound( click_sounds[1] )
		end
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

local design = {width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
local scale = 1
local function getDesignResolution()
	return {width=design.width,height=design.height,mode=design.mode}
end
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
		design.width = t.width
		design.height = t.height
		design.mode = t.mode
		glview:setDesignResolutionSize(t.width or ss.width,t.height or ss.height,t.mode or cc.ResolutionPolicy.SHOW_ALL)
		scale = t.width/ss.width
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
				if not wt then
					local d = tonumber(v)
					if d then
						wt = w:getChildByTag( d ) 
					end
				end
				w = wt
			end
		end
		if w == root then
			--打印调用者信息
			kits.log('ERROR: uikits.child return nil, '..tostring(path))
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
				if cc_type(obj)=='ccui.CheckBox' then
					obj:addEventListener(
						function(sender,eventType)
							if eventType == ccui.CheckBoxEventType.selected then
								playClickSound()
								func(sender,true)
							elseif eventType == ccui.CheckBoxEventType.unselected then
								func(sender,false)
							end
						end)					
				else
					obj:addTouchEventListener( 
					function(sender,eventType) 
						if eventType == ccui.TouchEventType.began then
							playClickSound()
							func( sender,x,y )
						end
					end)			
				end
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
	if obj and func then
		 local scheduler = obj:getScheduler()
		 local schedulerID
		 local function delay_call_func()
			if not schedulerID then return end
			if not func(param1,param2,param3) then
				scheduler:unscheduleScriptEntry(schedulerID)
				schedulerID = nil					
			end
		end
		schedulerID = scheduler:scheduleScriptFunc(delay_call_func,delay or 0.01,false)	
	end
end

--[[
	sequence_call 
]]--
local FAIL = 0
local OK = 1
local RUN = 2
local STATE = 3
local BEGIN = 4
local END = 5
local NEXT = 6
local function sequence_call( t )
	local seqs = {}
	seqs._obj = cc.Director:getInstance() --如果没有对象，使用全局对象
	if seqs._obj and t then
		seqs._funcs = t
		 seqs._scheduler = seqs._obj:getScheduler()
		 local i = 1
		 local state
		 local function close_func()
		 	seqs._scheduler:unscheduleScriptEntry(seqs._schedulerID)	
			seqs._schedulerID = nil
		 end
		 local ispause
		 seqs.pause=function()
			ispause = true
		 end
		 seqs.continue=function()
			ispause=nil
		 end
		 local function event_func(s)
			if t.event then
				if not t.event(seqs,s) then
					close_func()
				end
			elseif s == FAIL then
				close_func()
			end
		 end
		 seqs.close=function()
			event_func(END)
			close_func()
		 end
		 local function sequence_call_func()
			if ispause then return end
			if t[i] then
				if not state then
					state = t[i](RUN)
				else
					local s = t[i](STATE)
					if s == OK then
						i = i + 1
						state = nil
						event_func(NEXT)
					elseif s == FAIL then
						state =  nil
						event_func(FAIL)
					end
				end
			else
				event_func(END)
				close_func()
			end
		end
		event_func(BEGIN)
		seqs._schedulerID = seqs._scheduler:scheduleScriptFunc(sequence_call_func,t.delay or 0.01,false)	
	end
	return seqs
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
local function relayout_v( items,space,scale )
	space = space or 0
	local x,y,w,h = 0,0,0,space
	for i,v in pairs(items) do
		local size = v:getContentSize()
		if scale then
			size.width = size.width*scale
			size.height = size.height*scale
			v:setScaleX(scale)
			v:setScaleY(scale)
		end
		v:setAnchorPoint(cc.p(0,0))
		v:setPosition(cc.p(x,y))
		y = y + size.height + space
		if size.width > w then
			w = size.width
		end
	end
	return {x=0,y=0,width=w+2*space,height = y}
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

local _pushNum = 0
local function pushScene( scene,transition,t )
	if transition then
		Director:pushScene( transition:create(t or 0.2,scene) )
	else
		Director:pushScene( scene )
	end
	cc.TextureCache:getInstance():removeUnusedTextures();
	_pushNum = _pushNum + 1
end

local function popScene()
	if _pushNum and _pushNum > 0 then
		local glview = Director:getOpenGLView()
		glview:setIMEKeyboardState(false) 
		Director:popScene()
		--[[
		popScene并不会马上释放场景，因此下面的调用并不会释放被弹出场景的材质内存
		--]]
		cc.TextureCache:getInstance():removeUnusedTextures();
		--cc.TextureCache:getInstance():removeAllTextures();
		_pushNum = _pushNum - 1
	else
		kits.log("ERROR popScene")
		Director:endToLua()
	end
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
local function scroll(root,scrollID,itemID,horiz,space,itemID2,item_min_height)
	local t = {_root = root}
	if scrollID then
		t._scrollview = child(root,scrollID)
	else
		t._scrollview = root
	end
	t._item = child(t._scrollview,itemID)
	if not t._scrollview or not t._item then
		kits.log('ERROR : scroll resource not exist')
		if not t._scrollview then
			kits.log('	resource not exit'..tostring(scrollID))
		end
		if not t._item then
			kits.log('	resource not exit : '..tostring(itemID))
		end		
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
	local function relayout_refresh(self)
		if self._scrollview and self._refresh_arrow then
			--local cs = self._scrollview:getContentSize()
			local inner = self._scrollview:getInnerContainer()
			--local x,y = inner:getPosition()
			local size = inner:getContentSize()
			local arrow_size = self._refresh_arrow:getContentSize()
			local text_size = self._refresh_text:getContentSize()
			local H = math.max(arrow_size.height,text_size.height)
			local W = arrow_size.width + text_size.width + 1
			local xx = (size.width-W)/2 + arrow_size.width/2
			local yy = size.height + H/2 + 1
			self._refresh_arrow:setPosition( xx,yy )
			xx = xx + 1 + arrow_size.width/2
			self._refresh_text:setPosition( xx,yy )
		end
	end
	t.relayout_refresh = relayout_refresh
	t.refresh = function(self,func) --设置一个回弹刷新函数
		if not self._refresh_arrow and self._scrollview then
			self._refresh_arrow = imageview{image="Images/arrow.png",anchorX = 0.5,anchorY=0.5}
			self._refresh_text = text{caption="下拉刷新",fontSize=38,color=cc.c3b(0,0,0),anchorX = 0,anchorY=0.5}
			--self._refresh_circle = imageview{}
			self._refresh_arrow:setRotation(90)
			self._refresh_arrow:setScaleX(0.7)
			self._refresh_arrow:setScaleY(0.7)
			self._scrollview:addChild(self._refresh_arrow)
			self._scrollview:addChild(self._refresh_text)
			self._refresh_func = func
			relayout_refresh(self)
			--self._scrollview:addChild(self._refresh_circle)
		end
		local flag
		local done
		t.drap_refresh_func=function(sender,state)
			if self:isAnimation() then return end
			
			local cs = sender:getContentSize()
			local inner = sender:getInnerContainer()
			local size = inner:getContentSize()
			local x,y = inner:getPosition()
			local arrow = self._refresh_arrow
			local text = self._refresh_text
			local drap_text = "下拉刷新"
			if state == ccui.ScrollviewEventType.scrolling then
				yy = cs.height - (size.height+y)
				local actionTo2 = cc.RotateTo:create( 0.2, 90)
				local actionTo = cc.RotateTo:create( 0.2, 90-180)		
				if yy > 1 then
					if not self._refreshBeginTime then
						self._refreshBeginTime = os.clock()
					end
				else
					self._refreshBeginTime = nil
				end
				if yy>200 then
					if self._refresh_flag == 0 then
						self._refresh_flag = 1
						done = 1
						text:setString("松开刷新")
						arrow:runAction( cc.Sequence:create(actionTo2,actionTo) )
					end
				else
					if not self._refresh_flag  then
						self._refresh_flag = 0
						text:setString(drap_text)
						if done == 1 then
							arrow:runAction( cc.Sequence:create(actionTo,actionTo2) )
						end
					end
				end
			elseif state == ccui.ScrollviewEventType.bounceTop then
				arrow:setRotation(90)
				text:setString(drap_text)		
				if self._refresh_func and done == 1 then
					if self._refreshBeginTime and os.clock()-self._refreshBeginTime>0.6 then
						self._refresh_func()
					end
					done = 0
				end
				done = 0
				self._refresh_flag = nil						
			end		
		end
		event(self._scrollview,t.drap_refresh_func)
	end
	local function relayout_imp(self)
		if horiz == true then --横向
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
				self._list[#self._list-i+1]:setVisible(true)
				item_width = item_width + self._list[#self._list-i+1]:getContentSize().width + space
			end
		elseif horiz == "mix" then --特定排列方式
			local cs = self._scrollview:getContentSize()
			local height = self._tops_space or 0
			local function calc_col_height( list,m )
				if list and #list > 0 then
					local s = list[1]:getContentSize()
					local col = #list/m
					local n = math.floor(col) 
					if col > n then
						n = n + 1
					end
					height = height + n * s.height + space
				end			
			end
			calc_col_height(self._list,4)
			calc_col_height(self._list2,4)
			local is_abs
			local tops_offy = 0
			local offy = 0
			if self._scrollview.setInnerContainerSize  then
				if height > cs.height then
					tops_offy = height - cs.height
				end			
				self._scrollview:setInnerContainerSize(cc.size(cs.width,height))
				is_abs = false
			elseif self._scrollview.setContentSize  then
				if height > cs.height then
					self._scrollview:setContentSize(cc.size(cs.width,height))
					tops_offy = height - cs.height
				end
				is_abs = true
			end
			if height < size.height then
				offy = size.height - height --顶到顶
			end
			
			local item_height = space
			local function raw_list( list,m )
				if list then
					local x = self._item_ox
					local cs = {width=0,height=0}
					for i=1,#list do
						local item = list[#list-i+1]
						local size = item:getContentSize()
						cs.width = math.max(cs.width,size.width)
						cs.height = math.max(cs.height,size.height)
						item:setPosition(cc.p(x,item_height))
						item:setVisible(true)
						if i~=1 and i%m == 1 then
							item_height = item_height + size.height + space
							x = self._item_ox
						else
							x = x + size.width + space
						end
					end
					if cs.height > 0 then item_height = item_height + cs.height + space end
				end
			end
			raw_list( self._list,4 )
			raw_list( self._list2,4 )
			--放置置顶元件
			if self._tops_space then
				item_height = item_height + self._tops_space--起始阶段置顶元件和item的间隔
				if is_abs then
					for i = 1,#self._tops do
						local x,y = self._tops[i]:getPosition()
						self._tops[i]:setPosition(cc.p(x,y+tops_offy))
						self._tops[i]:setVisible(true)
					end
				else
					for i = 1,#self._tops do
						self._tops[i]:setPosition(cc.p(self._tops[i]._ox,item_height+offy))
						self._tops[i]:setVisible(true)
					end				
				end
			end			
			relayout_refresh(self)
		else --纵向
			local cs = self._scrollview:getContentSize()
			local height = self._tops_space or space
			if not self._item2 then
				height = cs.height-self._item_oy-self._item_height --self._item_height*(#self._list)
			end
			for i=1,#self._list do
				if not self._list[i]._isHidden then
					local size = self._list[i]:getContentSize()
					if item_min_height then --有最小item_height
						if size.height < item_min_height then
							size.height = item_min_height
						end
					end				
					height = height + size.height + space
				end
			end
			local offy = 0
			local tops_offy = 0
			local is_abs
			if self._scrollview.setInnerContainerSize  then
				self._scrollview:setInnerContainerSize(cc.size(cs.width,height))
				if height > cs.height then
					tops_offy = height - cs.height
				end
				is_abs = false
			elseif self._scrollview.setContentSize  then
				if height > cs.height then
					self._scrollview:setContentSize(cc.size(cs.width,height))
					tops_offy = height - cs.height
				end
				is_abs = true
			end
			local size = self._scrollview:getContentSize()
			
			if height < size.height then
				offy = size.height - height --顶到顶
			end
			local item_height = 0
			for i = 1,#self._list do
				local item = self._list[#self._list-i+1]
				if not item._isHidden then
					local ox,oy = item:getPosition()
					--self._list[#self._list-i+1]:setPosition(cc.p(self._item_ox,item_height+offy))
					local size = item:getContentSize()
					if item_min_height and size.height < item_min_height then --有最小item_height
						local dh = item_min_height - size.height
						item:setPosition(cc.p(ox,item_height+offy+dh))
						size.height = item_min_height
					else
						item:setPosition(cc.p(ox,item_height+offy))
					end				
					item:setVisible(true)
					item_height = item_height + size.height + space
				end
			end
			--放置置顶元件
			if self._tops_space then
				item_height = item_height + self._tops_space--起始阶段置顶元件和item的间隔
				if is_abs then
					for i = 1,#self._tops do
						local x,y = self._tops[i]:getPosition()
						self._tops[i]:setPosition(cc.p(x,y+tops_offy))
						self._tops[i]:setVisible(true)
					end
				else
					for i = 1,#self._tops do
						self._tops[i]:setPosition(cc.p(self._tops[i]._ox,item_height+offy))
						self._tops[i]:setVisible(true)
					end				
				end
			end
		end
		relayout_refresh(self)	
	end
	
	local function animations(self,list,animation,slide_time,slide_delay,over_func)
		local size = self._scrollview:getContentSize()
		if #list == 0 then return end
		slide_time = slide_time or 0.2 --一条的滑动时间
		slide_delay = slide_delay or 0.2 --总延时
		local dt = slide_delay / #list
		local t = slide_delay
		self._animation_begin_time = os.clock()
		self._animation_duration = 2*(slide_time+slide_delay)	
		local suffix = string.sub(animation,-2)
		if suffix == 'in' then
			t = 0
		end
		for i,v in pairs(list) do
			if v:getNumberOfRunningActions() > 0 then
				kits.log("WARNING : scroll animation running yet")
				return
			end
		end
		for i,v in pairs(list) do
			local x,y = v:getPosition()
			if animation == 'slide_out' then
				v:runAction( cc.Sequence:create(cc.DelayTime:create(t) ,cc.MoveTo:create(slide_time,cc.p(size.width,y))) )
			elseif animation == 'fall_out' then
				local s = v:getContentSize()
				v:runAction( cc.Sequence:create(cc.DelayTime:create(t) ,cc.MoveTo:create(slide_time,cc.p(x,-size.height-s.height))) )
			elseif animation == 'slide_in' then
				v:setPosition(cc.p(-size.width,y))
				v:runAction( cc.Sequence:create(cc.DelayTime:create(t) ,cc.MoveTo:create(slide_time,cc.p(x,y))) )
			elseif animation == 'fall_in' then
				local s = v:getContentSize()
				v:setPosition(cc.p(x,-size.height-s.height))
				v:runAction( cc.Sequence:create(cc.DelayTime:create(t) ,cc.MoveTo:create(slide_time,cc.p(x,y))) )			
			end
			if suffix == 'in' then
				t = t + dt
			else
				t = t - dt
			end
		end
		delay_call( self._scrollview,function(d)
				self._animation_begin_time = nil
				self._animation_duration = nil
				if over_func then
					over_func()
				end
			end,2*(slide_time+slide_delay) )
	end
	
	local function animation_relayout(self,animation,slide_time,slide_delay)
		if animation == 'slide' or animation == 'fall' then
			for i,v in pairs(self._list) do
				v:setVisible(true)
			end
			local list = self:visibles()
			animations(self,list,animation..'_in',
				slide_time,slide_delay)		
		end
	end
	t.relayout = function(self,animation)
		animation = nil --暂时屏蔽动画
		if self._animation_begin_time then
			local ct = os.clock()-self._animation_begin_time
			if ct >= self._animation_duration then --动画结束
				self._animation_begin_time = nil
				self._animation_duration = nil			
				relayout_imp(self)
				animation_relayout(self,animation)
				kits.log("--------------------------------------------------")
				kits.log("relayout animation end "..tostring(os.clock()))
			else		--动画还在播放	
				kits.log("--------------------------------------------------")
				kits.log("animation playing,wait"..tostring(os.clock()))	
				kits.log("dt="..(self._animation_duration-ct))
				delay_call( nil,function()
					if self._animation_begin_time then --延迟到动画播放结束
						local cct = os.clock()-self._animation_begin_time
						if cct >= self._animation_duration then
							self._animation_begin_time = nil
							self._animation_duration = nil
							kits.log("--------------------------------------------------")
							kits.log("delay relayout call"..tostring(os.clock()))							
							relayout_imp(self)
							return false
						end
						kits.log("--------------------------------------------------")
						kits.log("relayout animation playing yet..."..tostring(os.clock()))		
						return true --继续循环
					end					
					relayout_imp(self)
					--animation_relayout(self,animation)
					kits.log("--------------------------------------------------")
					kits.log("relayout animation playing ,delay relayout "..tostring(os.clock()))
				end,(self._animation_duration-ct))
			end
		else
			relayout_imp(self)
			animation_relayout(self,animation)
			kits.log("--------------------------------------------------")
			kits.log("not animation relayout immediate "..tostring(os.clock()))
		end
	end
	t.setVisible = function(self,b)
		self._scrollview:setVisible(b)
	end
	local function additem_imp(self,data,index)
		local item
		if index == 2 then
			item = self._item2:clone()
		else
			item = self._item:clone()
		end
		if item then
			if horiz == 'mix' then
				if index == nil or index == 1 then
					self._list[#self._list+1] = item
					item:setVisible(true)
					item:setAnchorPoint(cc.p(0,0))
					self._scrollview:addChild(item)				
				else
					self._list2 = self._list2 or {}
					self._list2[#self._list2+1] = item
					item:setVisible(true)
					item:setAnchorPoint(cc.p(0,0))
					self._scrollview:addChild(item)									
				end
			else
				self._list[#self._list+1] = item
				item:setVisible(true)
				item:setAnchorPoint(cc.p(0,0))
				self._scrollview:addChild(item)
			end
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
	t.additem = function(self,data,index)
		local item = additem_imp(self,data,index)
		item:setVisible(false)
		return item
	end
	t.visibles= function(self)
		local list = {}
		local cs = self._scrollview:getContentSize()
		local inner = self._scrollview:getInnerContainer()
		local x,y = inner:getPosition()
		local size = inner:getContentSize()
		
		for i,v in pairs(self._list) do
			local xx,yy = v:getPosition()
			local s = v:getContentSize()
			if not ((yy < -y and yy + s.height < -y) or (yy > -y+cs.height)) then
				if v:isVisible() then
					table.insert(list,v)
				end
			end
		end
		return list
	end
	t.isAnimation = function(self)
		if self._animation_begin_time then
			if os.clock()-self._animation_begin_time >= self._animation_duration then
				return false
			else
				return true
			end
		end
		return false
	end
	t.clear = function(self,animation,slide_time,slide_delay)
		local function do_clear(list,list2)
			for i=1,#list do
				list[i]:removeFromParent()
			end
			if list2 then
				for i=1,#list2 do
					list2[i]:removeFromParent()
				end
			end	
		end
		animation = nil --暂时屏蔽
		if animation == 'slide' or animation == 'fall' then
			if self:isAnimation() then return end
			local list_visible = self:visibles()
			local list = self._list
			local list2 = self._list2
			self._list = {}
			self._list2 = {}				
			animations(self,list_visible,animation..'_out',
				slide_time,slide_delay,
				function()
					do_clear(list,list2)
				end)
		else
			do_clear(self._list,self._list2)
			self._list = {}
			self._list2 = {}
		end
	end
	t.swap = function(self) --交换当前列表中的项到后缓
		if self:isAnimation() then return end
		if self._scrollview and self._list then
			local temp_list = self._back_list or {}
			
			for i,v in pairs(self._list) do
				if cc_isobj(v) then
					v:setVisible(false)
				end
			end
			for i,v in pairs(temp_list) do
				if cc_isobj(v) then
					v:setVisible(true)
				end
			end
			self._back_list = self._list
			self._list = temp_list			
		end
	end
	t.swap_by_index = function(self,i,j) --将当前列表总得放入i,取出j
		if self:isAnimation() then return end
		if self._scrollview and self._list then
			self._back_lists = self._back_lists or {}

			for i,v in pairs(self._list) do
				if cc_isobj(v) then
					v:setVisible(false)
				end
			end
			self._back_lists[i] = self._list
			
			self._back_lists[j] = self._back_lists[j] or {}
			for i,v in pairs(self._back_lists[j]) do
				if cc_isobj(v) then
					v:setVisible(true)
				end
			end
			self._list = self._back_lists[j]
		end
	end
	return t
end

--scroll 的改进版本
--[[
overlapping  tops 和 items可以有重叠区
]]--
local function scrollex(root,scrollID,itemIDs,topIDs,bottomIDs,horz,m,overlapping)
	local t = {_root = root}
	if scrollID then
		t._scrollview = child(root,scrollID)
	else
		t._scrollview = root
	end
	if not t._scrollview then 
		kits.log('ERROR : scrollex resource not exist')
		log_caller()
		return
	end
	local function init_items( ids,b )
		local items = {}
		if not ids then return end
		for i, v in pairs(ids) do
			items[i] = child(t._scrollview,v)
			if not items[i] then
				kits.log('ERROR : scrollex child resource not exist "'..tostring(v)..'"')
				log_caller()
			elseif b == false then
				items[i]:setVisible(false)
			end
		end
		return items
	end
	local function calc_space_y( tops )
		if not tops then return 0 end
		local miny = math.huge
		local maxy = 0
		for i, v in pairs(tops) do
			local x,y = v:getPosition()
			local anchor = v:getAnchorPoint()
			local size = v:getContentSize()
			local miy = y - anchor.y*size.height
			local may = miy + size.height
			miny = math.min(miy,miny)
			maxy = math.max(may,maxy)
		end
		if miny == math.huge then
			return 0
		else
			return maxy - miny
		end
	end
	t._items = init_items( itemIDs,false )
	t._tops = init_items( topIDs,true )
	t._bottoms = init_items( bottomIDs,true )
	t._list = {}
	t._tops_lists = t._tops
	t._bottoms_lists = t._bottoms
	t._tops_space = calc_space_y( t._tops )
	t._bottoms_space = calc_space_y( t._bottoms_lists )
	--布局函数
	t.relayout = function(self,space)
		space = space or 16
		local cs = self._scrollview:getContentSize()
		local height = 0
		local function relayout_list( lists )
			for i,v in pairs(lists) do
				local size = v:getContentSize()
				local x,y = v:getPosition()
				local anchor = v:getAnchorPoint()
				v:setPosition( cc.p(x+anchor.x*size.width,height+anchor.y*size.height) )
				height = height + size.height + space
			end		
		end
		local function calc_col_height( list,m )
			if list and #list > 0 then
				local s = list[1]:getContentSize()
				local col = #list/m
				local n = math.floor(col) 
				if col > n then
					n = n + 1
				end
				return n * (s.height + space) + space
			end			
			return 0
		end		
		local function relayout_mix( lists,m )
			if not lists then return end
			if not lists[1] then return end
			local ox,oy = lists[1]:getPosition()
			local col_height = calc_col_height(lists,m or 6)
			local h = height + col_height
			local xx = ox
			for i,v in pairs(lists) do
				local size = v:getContentSize()
				local x,y = v:getPosition()
				local anchor = v:getAnchorPoint()
				if i == 1 then
					h = h - size.height
				elseif i ~= 1 and i%m==1 then					
					xx = ox
					h = h - size.height - space
				end
				v:setPosition( cc.p(xx+anchor.x*size.width,h+anchor.y*size.height) )
				xx = xx + size.width + space
			end		
			height = height + col_height
		end
		--bottom
		local tops = {}
		local lists = {}
		for i,v in pairs(self._list) do
			if v._placeType == 'top' then
				table.insert(tops,v)
			else
				table.insert(lists,v)
			end
		end
		height = height + t._bottoms_space
		if horz then
			relayout_mix( lists,m )
		else
			relayout_list( lists )
		end
		relayout_list( tops )
		height = height + self._tops_space - t._bottoms_space - (overlapping or 0)
		local tops_offy = height - cs.height

		--tops 要做特殊处理
		for i,v in pairs(self._tops_lists) do
			local x,y = v:getPosition()
			v:setPosition(cc.p(x,y+tops_offy))
		end
		if self._scrollview.setInnerContainerSize then
			self._scrollview:setInnerContainerSize(cc.size(cs.width,height))
		elseif self._scrollview.setContentSize then
			self._scrollview:setContentSize(cc.size(cs.width,height))
		end
	end
	--添加函数
	t.additem = function(self,key,sector,place_type)
		local item
		local items
		local lists
		if sector == 0 then --itemIDs
			items = self._items
			lists = self._list
		elseif sector == 1 then --topIDs
			items = self._tops
			lists = self._tops_lists
		elseif sector == 2 then --bottomIDs
			items = self._bottoms
			lists = self._bottoms_lists
		else
			items = self._items
			lists = self._list
		end
		if items[key] then
			item = items[key]:clone()
		else
			kits.log('ERROR : scrollex additem not exist key "'..tostring(key)..'"')
			log_caller()
			return 
		end
		if item then
			item._placeType = place_type
			table.insert( lists,item )
			item:setVisible( true )
			self._scrollview:addChild(item)
			return item
		else
			kits.log('ERROR : scrollex item not exist')
			log_caller()
			return 			
		end
	end
	--清除
	t.clear = function(self,sector)
		local lists
		if sector == 0 then --itemIDs
			lists = self._list
			self._list = {}
		elseif sector == 1 then --topIDs
			lists = self._tops_lists
			self._tops_lists = {}
		elseif sector == 2 then --bottomIDs
			lists = self._bottoms_lists
			self._bottoms_lists = {}
		else
			lists = self._list
			self._list = {}
		end
		for i,v in pairs(lists) do
			v:removeFromParent()
		end
	end
	t.remove = function(self,item )
		local pos
		for i,v in pairs(self._list) do
			if v == item then
				pos = i
				break
			end
		end
		if pos then
			table.remove(self._list,pos)
		end
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

local function scrollview_step_add(scroll,t,n,add_func,sstate)
	local scrollview
	local refresh_func
	if scroll._scrollview then
		scrollview = scroll._scrollview
		refresh_func = scroll.drap_refresh_func
	else
		scrollview = scroll
	end
	if t and type(t)=='table' and scrollview and n and add_func 
	and type(add_func)=='function' then
		sstate = sstate or ccui.ScrollviewEventType.scrollToBottom
		local count = table.maxn(t)
		local offset = 1
		local function add_n_item(s,n)
			for i=s,s+n do
				if t[i] then
					add_func(t[i])
				end
			end			
			add_func() --重新布局
		end
--		if n < count then --只有在还有没添加的才关闭回弹
--			scrollview:setBounceEnabled(false)
--		end
		add_n_item(offset,n)
		offset = offset + n + 1
		event( scrollview,function(sender,state)
				if refresh_func then
					refresh_func(sender,state)
				end
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

local function animationFormJson( filename,name )
	local arm = ccs.ArmatureDataManager:getInstance()
	if arm then
		arm:removeArmatureFileInfo(filename)
		arm:addArmatureFileInfo(filename)	
		return ccs.Armature:create(name)
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
	getDR = getDesignResolution,
	line = line,
	rect = rect,
	move = move,
	scale = get_scale,
	isSoundPlaying = isSoundPlaying,
	pauseSound = pauseSound,
	playSound = playSound,
	voiceLength = voiceLength,
	stopAllSound = stopAllSound,
	log_caller = log_caller,
	FACTOR_3_4 = FACTOR_3_4,
	FACTOR_9_16 = FACTOR_9_16,
	get_factor = get_factor,
	scroll = scroll,
	scrollex = scrollex,
	tab = tab,
	set = set,
	set_item = set_item,
	fitsize = fitsize,
	scrollview_step_add = scrollview_step_add,
	muteSound = muteSound,
	playClickSound = playClickSound,
	animationFormJson = animationFormJson,
	sequence_call = sequence_call,
	FAIL = FAIL,
	OK = OK,
	RUN = RUN,
	STATE = STATE,
	BEGIN = BEGIN,
	END = END,
	NEXT = NEXT,
}
