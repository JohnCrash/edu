local uikits = require "uikits"
local kits = require "kits"
local portrait = require "test/portrait"

local ui = {
	FILE = 'test/TestApplet_1.json',
	--FILE = 'test/NewUi_1.json',
	BACK = 'Button_13',
	NETWORK_SATE = 'Button_3',
	ORIENTATION = 'Button_5',
	PORTRAIT = 'Button_6',
	SHOCK = 'Button_14',
	OK = 'Button_1',
	TEXT = 'Label_4',
	INPUT = 'TextField_2',
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
	uikits.initDR{width=960,height=540}
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE}
	self:addChild(self._root)
	self._back = uikits.child(self._root,ui.BACK)
	self._text = uikits.child(self._root,ui.TEXT)
	self._input = uikits.child(self._root,ui.INPUT)
	kits.log("type = "..cc_type(self._back))
	uikits.event(self._back,function()
		uikits.popScene()
	end,"click")
	self._netstate = uikits.child(self._root,ui.NETWORK_SATE)
	uikits.event(self._netstate,function()
		local state = cc_getNetworkState()
		self._text:setString( "network state "..tostring(state))
	end,"click")
	self._orientation = uikits.child(self._root,ui.ORIENTATION)
	uikits.event(self._orientation,function()
		self._text:setString( "ui orientation "..tostring(cc_getUIOrientation()))
	end,"click")
	self._portrait = uikits.child(self._root,ui.PORTRAIT)
	uikits.event(self._portrait,function()
		kits.log("portrait...")
		uikits.pushScene( portrait.create() )
	end,"click")
	self._shock = uikits.child(self._root,ui.SHOCK)
	uikits.event(self._shock,function()
		cc_shock(1)
	end)
	self._ok = uikits.child(self._root,ui.OK)
	uikits.event(self._ok,function()
		--self._text:setString( self._input:getStringValue() )
		--cc_openURL( self._input:getStringValue() )
		uikits.pushScene(require "test/test2".create())
	end)
end

function test:release()
	
end

return test