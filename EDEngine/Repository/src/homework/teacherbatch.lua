local uikits = require "uikits"

local ui = {
	FILE = 'laoshizuoye/jinruzuoye.json',
	FILE_3_4 = 'laoshizuoye/jinruzuoye43.json',
	BACK = 'ding/back',
	LIST = 'newview',
	ITEM = 'newview/subject1',
}

local Batch = class("Batch")
Batch.__index = Batch

function Batch.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Batch)
	
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

function Batch:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)uikits.popScene()end)	
end

function Batch:init()
	if not self._root then
		self:init_gui()
	end
end

function Batch:release()
	
end

return Batch