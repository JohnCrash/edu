local uikits = require "uikits"
local kits = require "kits"
local WorkList = require "homework/worklist"

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
	--uikits.test( self )
	--require('src/test').scroll( self )
	uikits.initDR{width=1920,height=1080}
	--simple ui
	self:addChild( uikits.button{caption='作业列表',width=240,height=64,fontSize=32,
				eventClick=function(sender)
					cc.Director:getInstance():pushScene( cc.TransitionSlideInL:create(0.2,WorkList.create()) )
				end} )
	print(get_cocos2d_type(self))
end

function HomeWork:release()
end

function HomeWorkMain()
	cclog("HomeWork launch!")
	--require("mobdebug").start("192.168.2.182")
	local scene =HomeWork.create()
	return scene
end