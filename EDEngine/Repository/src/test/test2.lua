local uikits = require "uikits"
local kits = require "kits"
local portrait = require "test/portrait"

local ui = {
	FILE = 'test/NewUi_1.json',
}

local test = class("test")
test.__index = test

function test.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),test)
	
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

function test:init()
	kits.log("test : init")
	cc_setUIOrientation(1)
	local s = uikits.screenSize()
	uikits.initDR{width=s.width,height=s.height}
	--uikits.initDR{width=320,height=480}
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE}
	self:addChild(self._root)
	
	print("w="..s.width.." h="..s.height)
	self._root:setContentSize(s)
end

function test:release()
	
end

return test