local kits = require "kits"
local music = require "hitmouse/music"
local uikits = require "uikits"

local ui = {
	FILE = 'hitmouse/shouye.json',
	FILE_3_4 = 'hitmouse/shouye43.json',
	BACK = 'ding/fan',
	LEVEL_BUT = 'cg',
	TOP_BUT = 'ph',
	MATCH_BUT = 'bs',
	MATCH_NEW = 'bs/tixing',
	SETTING_BUT = 'ding/sez',
}

local main = class("main")
main.__index = main

function main.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),main)
	
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

function main:init()
	self._ss = cc.size(1920,1080);
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			music.stop()
			uikits.popScene()
		end)
		uikits.event(uikits.child(self._root,ui.TOP_BUT),function(sender)
			local tops = require "hitmouse/tops"
			uikits.pushScene(tops.create())
		end)
		uikits.event(uikits.child(self._root,ui.MATCH_BUT),function(sender)
			local tops = require "hitmouse/matchview"
			uikits.pushScene(tops.create())		
		end)
		uikits.event(uikits.child(self._root,ui.SETTING_BUT),function(sender)
			local tops = require "hitmouse/setting"
			uikits.pushScene(tops.create())		
		end)		
		uikits.event(uikits.child(self._root,ui.LEVEL_BUT),function(sender)
			local tops = require "hitmouse/levelScene"
			uikits.pushScene(tops.create())		
		end)	
		self._mut = kits.config("hitmouse_mute","get")
		if not self._mut then
			math.randomseed(os.time())
			music.play()
		end
	end
end

function main:release()
end

return main