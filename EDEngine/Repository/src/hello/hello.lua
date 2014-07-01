local uikits = require "uikits"

local ui = {
	FILE = 'homework/studenthomework_1/studenthomework_1.json',
	BACK = 'white/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
}

local HelloWorld = class("HelloWorld")
HelloWorld.__index = HelloWorld

function HelloWorld.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),HelloWorld)
	
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

function HelloWorld:init()
	print( "HelloWorld")
end

function HelloWorld:release()
	
end

function HelloWorldMain()
	cclog("HomeWork launch!")
	--require("mobdebug").start("192.168.2.182")
	local scene =HelloWorld.create()
	return scene
end