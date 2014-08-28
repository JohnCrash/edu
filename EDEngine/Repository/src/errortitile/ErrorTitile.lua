local uikits = require "uikits"
local Loading = require "src/errortitile/Loading"
--local WrongSubjectList = require "src/errortitile/WrongSubjectList"
screen_type = 1
	
local ErrorTitile = class("ErrorTitile")
ErrorTitile.__index = ErrorTitile

local local_dir = cc.FileUtils:getInstance():getWritablePath()..'res/errortitile/'

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function ErrorTitile.create()
	--local scene = WrongSubjectList.create()					
	local scene = Loading.create()					
	return scene
end



function ErrorTitile:init()
--[[	loadArmature("errortitile/DemoPlayer/DemoPlayer.ExportJson")
	local schedulerEntry
	local hunter = ccs.Armature:create("DemoPlayer")
	hunter:setAnchorPoint(cc.p(0,0))
	hunter:setPosition(cc.p(100,100))
	hunter:setScale(0.5)
			
	local num = hunter:getAnimation():getMovementCount()
	local index = 0	
	hunter:getAnimation():playWithIndex(0)
	function changeaction(time)
		index = index +1
		if index>6 then
			index = 0
		end
		hunter:getAnimation():playWithIndex(index)
	end
		
	schedulerEntry = cc.Director:getInstance():getScheduler():scheduleScriptFunc(changeaction,2,false)		
	self:addChild(hunter)	--]]
end

function ErrorTitile:release()
--[[	if schedulerEntry then
		cc.Director:getInstance():getScheduler():unscheduleScriptEntry(schedulerEntry)
	end--]]
end

function ErrorTitileMain()
	cclog("ErrorTitile launch!")
	--require("mobdebug").start("192.168.2.182")
	local scene =ErrorTitile.create()		
	return scene
end