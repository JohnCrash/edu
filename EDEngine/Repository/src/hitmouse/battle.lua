local uikits = require "uikits"

local ui = {
	FILE = 'hitmouse/zuoti.json',
	FILE_3_4 = 'hitmouse/zuoti.json',
	TOPBAR = 'ding',
	BACK = 'ding/hui',
	NUMBER = 'ding/tu/tishu',
	PROGRESS = 'ding/jindu',
	SCORE = 'ding/defen',
	ANIMATION_RGN = "ding/donghua",
	
	TIMEOVER_WINDOW = 'js1',
	SUCCESS_WINDOW = 'js2',
	FAILED_WINDOW = 'js3',
	
	ANIMATION_1 = "hitmouse/NewAnimation/NewAnimation.ExportJson",
	ANIMATION_2 = "hitmouse/chong_zi/chong_zi.ExportJson",
	ANIMATION_3 = "hitmouse/defen/defen.ExportJson",
}

local battle = class("battle")
battle.__index = battle

function battle.create(arg)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),battle)
	
	scene:addChild(layer)
	layer:initGame( arg )
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

function battle:initGame( arg )
	self._game_time = 0
	if arg and type(arg)=='table' then
		self._time_limit = arg.time_limit
	else
		self._time_limit = 30
	end
end

function battle:update_time_bar()
	if self._time_bar and self._time_limit and self._game_time 
		and self._time_limit >= 1 and  self._game_time<=self._time_limit then
		--设置进度条
		self._time_bar:setPercent( 100*self._game_time/self._time_limit)
		--设置小虫
		local x,y = self._time_bar:getPosition()
		local box = self._time_bar:getBoundingBox()
		x = box.x + box.width*self._game_time/self._time_limit
		self._worm:setPosition(cc.p(x,y))
	end
end

function battle:init_role()
	local arm = ccs.ArmatureDataManager:getInstance()
	if arm then
		arm:removeArmatureFileInfo(ui.ANIMATION_1)
		arm:addArmatureFileInfo(ui.ANIMATION_1)
		arm:removeArmatureFileInfo(ui.ANIMATION_2)
		arm:addArmatureFileInfo(ui.ANIMATION_2)
		arm:removeArmatureFileInfo(ui.ANIMATION_3)
		arm:addArmatureFileInfo(ui.ANIMATION_3)
	else
		kits.log("ERROR init_role ccs.ArmatureDataManager:getInstance() return nil")
	end
	self._worm = ccs.Armature:create("chong_zi")
	self._worm:getAnimation():playWithIndex(0)
	self._topbar:addChild(self._worm)
	self:update_time_bar()
end

function battle:init()
	uikits.initDR{width=1920,height=1080}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			uikits.popScene()
		end)
		self._topbar = uikits.child(self._root,ui.TOPBAR)
		self._time_bar = uikits.child(self._root,ui.PROGRESS)
		self._pnum_label = uikits.child(self._root,ui.NUMBER)
		self._fen_label = uikits.child(self._root,ui.SCORE)
		self:init_role()
	end
end

function battle:release()
	
end

return battle