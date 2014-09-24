lxp = require "lom"
kits = require "kits"

require "AudioEngine"

local local_dir = kits.get_local_directory()..'res/'

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

local function ACatcherMainLayer()
	local layer = cc.Layer:create()
	local ss = cc.Director:getInstance():getVisibleSize()
	local scheduler = cc.Director:getInstance():getScheduler()
	local schedulerEntry
	
	local function onEnter()
	--背景
		loadArmature("acatcher/chang_jing/chang_jing.ExportJson")
		loadArmature("acatcher/001.ExportJson")
		local bg = ccs.Armature:create("chang_jing")
   --地平线
		local yy = ss.height/4
--		bg:setAnchorPoint(cc.p(0.5,0.5))
--		bg:setPosition(cc.p(ss.width/2,ss.height/2))
		bg:setAnchorPoint(cc.p(0,0))
		bg:setPosition(cc.p(0,0))
		bg:getAnimation():playWithIndex(0)
		layer:addChild(bg)
	--角色
		local mm = ccs.Armature:create("001")
		mm:setAnchorPoint(cc.p(0,0))
		mm:setPosition(cc.p(0,yy))
		mm:getAnimation():playWithIndex(0)
		layer:addChild(mm)
	--Dog
		local dog = ccs.Armature:create("001")
		dog:setAnchorPoint(cc.p(0,0))
		dog:setPosition(cc.p(200,yy))
		dog:getAnimation():playWithIndex(1)
		layer:addChild(dog)
	--Thief
		local thief = ccs.Armature:create("001")
		thief:setAnchorPoint(cc.p(0,0))
		thief:setPosition(cc.p(ss.width*5/6,yy))
		thief:getAnimation():playWithIndex(2)
		layer:addChild(thief)
   --狗和贼之间的距离差值差值函数,0-1
		local function difference_dog( d )
			local D = ss.width*3/8
			dog:setPosition(cc.p(D*d+200,yy))
		end
		local dt = 0
		local bf = true
		local function timer_update(time)
			if not bf then return end
			if dt > 1 then
				dog:setVisible(false)
				thief:getAnimation():playWithIndex(7)
				bf = false
				return
				--dt = 0
			end
			difference_dog( dt )
			dt = dt + 0.02
		end
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,0.1,false)
		
	end
	
	local function onExit()
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end	
	end
	
	local function onNodeEvent(event)
        if "enter" == event then
            onEnter()
        elseif "exit" == event then
            onExit()
        end	
	end

	layer:registerScriptHandler(onNodeEvent)
	
	return layer
end

function ACatcherMain()
	cclog("A catcher hello!")
	require("mobdebug").start("192.168.2.182")
	local scene = cc.Scene:create()
	scene:addChild(ACatcherMainLayer())
	scene:addChild(CreateBackMenuItem())
	return scene
end