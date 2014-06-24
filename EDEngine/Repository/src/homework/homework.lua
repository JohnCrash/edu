local uikits = require "uikits"
local kits = require "kits"

print("------------------HomeWork----------------------")
local HomeWork = class("HomeWork")
HomeWork.__index = HomeWork
HomeWork._uiLayer= nil
HomeWork._widget = nil
HomeWork._sceneTitle = nil

function HomeWork.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, HomeWork)
    return target
end

function HomeWork.create()
	local scene = cc.Scene:create()
	local layer = HomeWork.extend(cc.Layer:create())
	
	scene:addChild(layer)
	
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

function HomeWork:init()
	local sv = ccui.ScrollView:create()
	--local ss = cc.Director:getInstance():getVisibleSize()
	local director = cc.Director:getInstance()
	local glview = director:getOpenGLView()
	local ss = glview:getFrameSize()
	--print( "getVisibleSize :"..ss.width.." , "..ss.height )
	InitDesignResolutionMode()
	self._ss = ss
	
	self:addChild(sv)
	sv:setPosition{x=0,y=0}
	sv:setAnchorPoint{x=0,y=0}
	sv:setSize{width=self._ss.width,height=self._ss.height}
	
	local h = 0
	for i = 1,32 do
		--text
		local t = ccui.Text:create("ccui.Text [ "..i.." ]","fonts/Marker Felt.ttf",30)
		local y =  (i-1)*t:getSize().height
		t:setAnchorPoint{x=0,y=0}
		h = h + t:getSize().height
		t:setPosition{x=0,y = y }
		sv:addChild(t)
		--checkbox
		local c = ccui.CheckBox:create()
		c:setTouchEnabled(true)
		c:loadTextures("cocosui/check_box_normal.png",
								   "cocosui/check_box_normal_press.png",
								   "cocosui/check_box_active.png",
								   "cocosui/check_box_normal_disable.png",
								   "cocosui/check_box_active_disable.png")
		c:setAnchorPoint{x=0,y=0}
		c:setPosition{x=t:getSize().width,y = y }
		sv:addChild(c)
		--button
		local b = ccui.Button:create()
		b:setScale9Enabled(true)
		b:loadTextures("cocosui/button.png", "cocosui/buttonHighlighted.png", "")
		b:setAnchorPoint{x=0,y=0}
		b:setPosition{x=t:getSize().width+c:getSize().width,y= y }
		b:setSize{ width = 320,height = c:getSize().height }
		b:setTitleFontSize( 32 )
		b:setTitleFontName("fonts/Marker Felt.ttf")
		b:setTitleText( "ccui.Button 中文"..i )
		sv:addChild(b)
		--progress
		local s = ccui.Slider:create()
		s:setAnchorPoint{x=0,y=0}
		s:loadBarTexture("cocosui/sliderTrack.png")
		s:loadSlidBallTextures("cocosui/sliderThumb.png", "cocosui/sliderThumb.png", "")
		s:loadProgressBarTexture("cocosui/sliderProgress.png")		
		s:setPosition{x=b:getPosition()+b:getSize().width,y= y }
		s:setSize{width=320,height=c:getSize().height }
		s:setPercent(i*100/32)
		sv:addChild(s)
		--edit
		--local e = ccui.Edit:create()
	end
	sv:setInnerContainerSize{width=self._ss.width,height=h}
end

function HomeWork:release()
end

function HomeWorkMain()
	cclog("HomeWork launch!")
	--require("mobdebug").start("192.168.2.182")
	local scene = HomeWork.create()
	return scene
end