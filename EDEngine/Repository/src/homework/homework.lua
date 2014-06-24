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
	self._ss = cc.Director:getInstance():getVisibleSize()
	
	self:addChild(sv)
	sv:setPosition{x=0,y=0}
	sv:setAnchorPoint{x=0,y=0}
	sv:setSize{width=self._ss.width,height=self._ss.height}
	
	local h = 0
	for i = 1,32 do
		--text
		local t = ccui.Text:create("[ "..i.." ","fonts/Marker Felt.ttf",30)
		t:setAnchorPoint{x=0.5,y=0}
		h = h + t:getSize().height
		t:setPosition{x=self._ss.width/3,y = i*t:getSize().height }
		sv:addChild(t)
		--checkbox
		local c = ccui.CheckBox:create()
		c:setTouchEnabled(true)
		c:loadTextures("cocosui/check_box_normal.png",
								   "cocosui/check_box_normal_press.png",
								   "cocosui/check_box_active.png",
								   "cocosui/check_box_normal_disable.png",
								   "cocosui/check_box_active_disable.png")
		c:setAnchorPoint{x=0.5,y=0}
		c:setPosition{x=self._ss.width/1.5,y = i*t:getSize().height }
		sv:addChild(c)
		--image
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