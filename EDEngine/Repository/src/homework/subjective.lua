local uikits = require "uikits"

local ui = {
	FILE = 'homework/z22_1/z22_1.json',
	BACK = 'milk_write/back',
}

local Subjective = class("Subjective")
Subjective.__index = Subjective

function Subjective.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Subjective)
	
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

function Subjective:init()
	if not self._root then
		self._root = uikits.fromJson{file=ui.FILE}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
		self:addChild(self._root)
	end
end

function Subjective:release()
	
end

return Subjective