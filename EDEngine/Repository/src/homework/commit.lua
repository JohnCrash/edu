local uikits = require "uikits"
local WorkFlow = require "homework/workflow"

local ui = {
	FILE = 'homework/z2_1/z2_1.json',
	BACK = 'white/back',
	LIST = 'top_view',
	ITEM = 'top_view/top_1',
	WORKFLOW = 'objective_item/start_objective',
	WORKFLOW2 = 'subjective_item/completed_subjective',
}

local WorkCommit = class("WorkCommit")
WorkCommit.__index = WorkCommit

function WorkCommit.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkCommit)
	
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

function WorkCommit:init()
	if not self._root then
		self._root = uikits.fromJson{file=ui.FILE}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
		uikits.event(uikits.child(self._root,ui.WORKFLOW),
						function(sender)
							uikits.pushScene(WorkFlow)
						end,'click')
		uikits.event(uikits.child(self._root,ui.WORKFLOW2),
						function(sender)
							uikits.pushScene(WorkFlow)
						end,'click')						
		self:addChild(self._root)
	end
end

function WorkCommit:release()
end

return WorkCommit