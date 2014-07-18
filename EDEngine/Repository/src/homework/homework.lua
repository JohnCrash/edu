local uikits = require "uikits"
local kits = require "kits"
local WorkList = require "homework/worklist"
local WorkLoading = require "homework/workloading"
local WorkCommit = require "homework/commit"
local WorkFlow = require "homework/workflow"

--str = "<img src=\"http://www.lexuelejiao.com/92342.png\" \\>"
--print("============================")
--print(str)
--print( string.match(str,'<img%s+src="(.+)"') )

--str = "A . \"219,92,938,298\""
--print(str)
--s1,s2,s3,s4 = string.match(str,'\"(%d+),(%d+),(%d+),(%d+)\"')
--print(s1.."-"..s2.."-"..s3.."-"..s4)

--str = "<span> <p> <spanstyle='font-size: 22.0pt '> Hello World </p></span>"
--print(str)
--s = string.gsub(str,'<.->','')
--print(s)

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

local args = 
{
--	pid='93ca856727be4c09b8658935e81db8b8',
	pid='15f4383c2ca948498de13a6933c9445b',
	uid='122097',
}

function HomeWork:init()
	--uikits.test( self )
	--require('src/test').scroll( self )
	uikits.initDR{width=1920,height=1080}
	--simple ui

	--uikits.pushScene( WorkLoading )
	local wk = {
		{text = '装载',scene=WorkLoading},
		{text = '作业列表',scene=WorkList},
		{text = '提交',scene=WorkCommit,arg=args},
		{text = '做作业',scene=WorkFlow,arg=args},
	}
	for i,v in pairs(wk) do
		self:addChild( uikits.button{caption=v.text,width = 240,height=48,fontSize=32,
					y = 48*i,
					eventClick=function(sender)
						uikits.pushScene( v.scene.create(v.arg) )
					end} )
	end
end

function HomeWork:release()
end

function HomeWorkMain()
	cclog("HomeWork launch!")
	--require("mobdebug").start("192.168.2.182")
	local scene =HomeWork.create()
	return scene
end