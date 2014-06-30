local uikits = require "uikits"
local kits = require "kits"
local WorkList = require "homework/worklist"
local WorkLoading = require "homework/workloading"
local WorkCommit = require "homework/commit"
local WorkFlow = require "homework/workflow"

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

	--uikits.pushScene( WorkLoading )
	local wk = {
		{text = '装载',scene=WorkLoading},
		{text = '作业列表',scene=WorkList},
		{text = '提交',scene=WorkCommit},
		{text = '做作业',scene=WorkFlow},
	}
	for i,v in pairs(wk) do
		self:addChild( uikits.button{caption=v.text,width = 240,height=48,fontSize=32,
					y = 48*i,
					eventClick=function(sender)
						uikits.pushScene( v.scene )
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