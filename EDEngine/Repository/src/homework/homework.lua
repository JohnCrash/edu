local uikits = require "uikits"
local kits = require "kits"
local WorkList = require "homework/worklist"
local WorkLoading = require "homework/workloading"
local WorkCommit = require "homework/commit"
local WorkFlow = require "homework/workflow"
local Subjective = require "homework/subjective"
local TeacherList = require "homework/teacher"
local TeacherBatch = require "homework/teacherbatch"
local StudentList = require "homework/studentlist"
local TeacherSubjective = require "homework/teachersubjective"

local login = require "login"
local sc = require "homework/search"
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
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	--simple ui

	--uikits.pushScene( WorkLoading )
	--simple login ui
	local yy = 1
	for i,v in pairs(login.test_login) do
		self:addChild( uikits.checkbox{caption=v.name,width=32,height=48,fontSize=32,
			y = yy,eventSelect=function(sender,b)
				if b then
					login.set_selector( i )
				end
			end})
		self:addChild( uikits.text{caption=v.name,width=240,height=48,fontSize=32,y = yy,font='fonts/simsun.ttc',x=32,
			eventClick=function(sender)end} )
		yy = yy + 48
	end
	local wk = {
		{text = '装载',scene=WorkLoading},
		{text = '作业列表',scene=WorkList},
		{text = '提交',scene=WorkCommit,arg=args},
		{text = '做作业',scene=WorkFlow,arg=args},
		{text = '主观题',scene=Subjective},
		{text = '老师列表',scene=TeacherList},
		{text = '老师批改',scene=TeacherBatch},
		{text = '学生列表',scene=StudentList},
		{text = '老师端主观题',scene=TeacherSubjective},
	}
	for i,v in pairs(wk) do
		self:addChild( uikits.button{caption=v.text,width = 240,height=48,fontSize=32,
					y = yy,
					eventClick=function(sender)
						uikits.pushScene( v.scene.create(v.arg) )
					end} )
		yy = yy + 48
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