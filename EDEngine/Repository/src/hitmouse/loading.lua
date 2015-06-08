local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse/level"
local music = require "hitmouse/music"

local ui = {
	FILE = 'hitmouse/load.json',
	FILE_3_4 = 'hitmouse/load43.json',
	PROGRESS = "jindu",
}

local loading = class("loading")
loading.__index = loading

function loading.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),loading)
	
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

function loading:init()
	self._ss = cc.size(1920,1080);
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		self._progress = uikits.child(self._root,ui.PROGRESS)
		level.init()
		self._progress:setPercent(0)
	end
end

function loading:release()
	
end

return loading