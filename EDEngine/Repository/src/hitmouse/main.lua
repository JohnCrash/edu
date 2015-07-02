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
	NOTICE_BUT = 'ding/xiaoxi',
	NOTICE_BOBO = 'ding/xiaoxi/hong',
}

local main = uikits.SceneClass("main")
--[[
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
--]]
function main:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
	else
		self._ss = cc.size(1440,1080)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			music.stop()
			uikits.popScene()
		end)
		self._bobo = uikits.child(self._root,ui.NOTICE_BOBO)
		if self._arg and self._arg.hasMsg then
			self._bobo:setVisible(true)		
		else
			self._bobo:setVisible(false)		
		end
	--	local match_news = uikits.child(self._root,ui.MATCH_NEW)
	--	match_news:setVisible(false)
		uikits.event(uikits.child(self._root,ui.TOP_BUT),function(sender)
			local scene = require "hitmouse/tops"
			uikits.pushScene(scene.create())
		end)
		uikits.event(uikits.child(self._root,ui.MATCH_BUT),function(sender)
			local scene = require "hitmouse/matchview"
			uikits.pushScene(scene.create())		
		end)
		uikits.event(uikits.child(self._root,ui.SETTING_BUT),function(sender)
			local scene = require "hitmouse/setting"
			uikits.pushScene(scene.create())		
		end)		
		uikits.event(uikits.child(self._root,ui.LEVEL_BUT),function(sender)
			local scene = require "hitmouse/levelScene"
			uikits.pushScene(scene.create())		
		end)	
		uikits.event(uikits.child(self._root,ui.NOTICE_BUT),function(sender)
			local scene = require "hitmouse/notice"
			uikits.pushScene(scene.create())
		end)
		self._mut = kits.config("hitmouse_mute","get")
		if not self._mut then
			math.randomseed(os.time())
			music.play()
		end
	else
		if self._bobo then
			self._bobo:setVisible(false)
		end
	end
end

function main:release()
end

return main