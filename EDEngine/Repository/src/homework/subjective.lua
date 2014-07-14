local uikits = require "uikits"

local ui = {
	FILE = 'homework/z3_1/z3_1.json',
	BACK = 'white/back',
	HOME = 'Button_31',
	CAPTION = 'white/lesson_name',
	END_DATE = 'white/time_over',
	RANK = 'ranking',
	TOPICS = 'objective_no',
	TOPICS2 = 'subjective_no',
	USE_TIME = 'time',
	EXP = 'experience_no',
	SILVER = 'silver_no',
	GOLD = 'gold_no',
	LEVEL = 'level',
	ITEM = 'newview/subject1',
	GO_WRONG = 'wrong',
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
		
	end
end

function Subjective:release()
	
end

return Subjective