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

return {
	text = text,
	checkbox = checkbox,
	button = button,
	slider = slider,
	progress = progress
}