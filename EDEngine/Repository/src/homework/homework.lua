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
		local t = uikits.text{caption="ccui.Text [ "..i.." ]",fontSize=30}
		local y =  (i-1)*t:getSize().height
		h = h + t:getSize().height
		t:setPosition{x=0,y=y}
		sv:addChild(t)
		--checkbox
		local c = uikits.checkbox{x=t:getSize().width,y=y,check=i%2==1 and true or false}
		sv:addChild(c)
		--button
		local b = uikits.button{x=t:getSize().width+c:getSize().width,y=y,
											fontSize=32,width=320,height=c:getSize().height,
											caption="ccui.Button 中文"..i }
		sv:addChild(b)
		--slider
		local s = uikits.progress{width=320,height=c:getSize().height,
										x=b:getPosition()+b:getSize().width,y= y,percent=i*100/32}
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