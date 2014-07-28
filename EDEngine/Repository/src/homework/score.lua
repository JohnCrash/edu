local uikits = require "uikits"

local ui = {
	FILE = 'homework/result.json',
	BACK = 'white/back',
	HOME = 'home',
	CAPTION = 'white/lesson_name',
	END_DATE = 'white/time_over',
	TIMELABEL = 'white/text',
	RANK = 'ranking',
	OBJECTIVE_NUM = 'objective_no',
	SUBJECTIVE_NUM = 'subjective_no',
	USE_TIME = 'time',
	EXP = 'experience_no',
	SILVER = 'silver_no',
	GOLD = 'gold_no',
	LEVEL = 'level',
	ITEM = 'newview/subject1',
	GO_WRONG = 'wrong',
}

local Score = class("Score")
Score.__index = Score

function Score.create( t )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Score)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer._args = t
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function Score:init()
	if not self._root then
		self._root = uikits.fromJson{file=ui.FILE}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				uikits.popScene()
			end)
		self:addChild( self._root )
	end
	
	if self._args and type(self._args)=='table' then
		local caption = uikits.child(self._root,ui.CAPTION)
		if self._args.caption then
			caption:setString( self._args.caption )
		end
		
		local end_date = uikits.child(self._root,ui.END_DATE)
		if self._args.finish_time_unix then
			local scheduler = self:getScheduler()
			local end_time = self._args.finish_time_unix
			local dt = self._args.finish_time_unix - os.time()
			if dt > 0 then
				end_date:setString( kits.toDiffDateString(dt))
				local function timer_func()
					dt = end_time - os.time()
					if dt > 0 then
						end_date:setString(kits.toDiffDateString(dt))
					else
						--过期
						local txt = uikits.child( self._root,ui.TIMELABEL )
						if txt then txt:setString('已过期:') end
						end_date:setString(kits.toDiffDateString(-dt))
						scheduler:unscheduleScriptEntry(self._scID)
						self._scID = nil
					end		
				end
				self._scID = scheduler:scheduleScriptFunc( timer_func,1,false )					
			else
				--过期
				local txt = uikits.child( self._root,ui.TIMELABEL )
				if txt then txt:setString('已过期:') end
				end_date:setString(kits.toDiffDateString(-dt))				
			end
		end

		--主观题数
		local obj_num = uikits.child(self._root,ui.OBJECTIVE_NUM)
		if self._args.cnt_item then
			obj_num:setString(tostring(self._args.cnt_item))
		end	
		--客观题数

		local subj_num = uikits.child(self._root,ui.SUBJECTIVE_NUM)
		if self._args.subjective_num then
			subj_num:setString(tostring(self._args.subjective_num))
		end		
	
		local retbut = uikits.child(self._root,ui.HOME )
		if retbut then
			uikits.event( retbut,
				function(sender)
					uikits.popScene()
					uikits.popScene() --弹两次回列表?
				end )
		end
	end
end

function Score:release()
	if self._scID then
		self:getScheduler():unscheduleScriptEntry(self._scID)
		self._scID = nil
	end
end

return Score