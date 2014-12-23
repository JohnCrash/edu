---
--LaBattleResultChallenge.lua
--华夏诗魂的擂台战斗结束图层
--

--卢乐颜
--2014.12.15

local lly = require "poetrymatch/BattleScene/llyLuaBase2"
local uikits = require "uikits"

local moLaBattleResultBase = require "poetrymatch/BattleScene/LaBattleResultBase"

lly.finalizeCurrentEnvironment()

local ui = lly.const{
	FILE = "poetrymatch/BattleScene/result_challenge/ltjieguo.ExportJson",
	FILE_3_4 = "",

	--胜利层
	LAY_SHOW = "defen",

	IMG_PLYR_PORTRAIT = "defen/wodetoux",
	TXT_PLYR_NAME = "defen/wodetoux/mz",

	TXT_SCORE = "defen/df",
	TXT_RANK = "defen/pm",
	TXT_CONTRIBUTION = "defen/gongx",
	TXT_ROUND_NUM = "defen/huih",
	TXT_CORRECT_NUM = "defen/zq",
	TXT_TIME_USED = "defen/sj",

	BTN_CONFIRM = "defen/hui",

	--动画
	ANIM_END_PNG1 = "poetrymatch/BattleScene/anim_end/jieshu0.png",
	ANIM_END_PLIST1 = "poetrymatch/BattleScene/anim_end/jieshu0.plist",
	ANIM_END_PNG2 = "poetrymatch/BattleScene/anim_end/jieshu1.png",
	ANIM_END_PLIST2 = "poetrymatch/BattleScene/anim_end/jieshu1.plist",
	ANIM_END_JSON = "poetrymatch/BattleScene/anim_end/jieshu.ExportJson",
}

local CONST = lly.const{
	WIN_AREA_MOVE_Y = 1000,

	WIN_MOVE_TIME = 0.4,
}

local LaBattleResultChallenge = lly.class("LaBattleResultChallenge", moLaBattleResultBase.Class)

function LaBattleResultChallenge:ctor()
	return {

		--胜利层
		_layShow = Lnull,

		_imgPlyrPortrait = Lnull,
		_txtPlyrName = Lnull,

		_txtScore = Lnull,
		_txtRank = Lnull,
		_txtContribution = Lnull,
		_txtRoundNum = Lnull,
		_txtCorrectNum = Lnull,
		_txtTimeUsed = Lnull,

		--动画
		_animEnd = Lnull,
		
	}
end

function LaBattleResultChallenge:init(tab)
	return self.super.init(self, tab)
end

function LaBattleResultChallenge:initUI()
	repeat
		--UI
		self._wiRoot = uikits.fromJson{file_9_16 = ui.FILE, file_3_4 = ui.FILE_3_4}

		if not self._wiRoot then break end
		self:addChild(self._wiRoot)

		--胜利层
		self._layShow = self:setWidget(ui.LAY_SHOW)

		self._imgPlyrPortrait = self:setWidget(ui.IMG_PLYR_PORTRAIT)
		self._txtPlyrName = self:setWidget(ui.TXT_PLYR_NAME)

		self._txtScore = self:setWidget(ui.TXT_SCORE)
		self._txtRank = self:setWidget(ui.TXT_RANK)
		self._txtContribution = self:setWidget(ui.TXT_CONTRIBUTION)
		self._txtRoundNum = self:setWidget(ui.TXT_ROUND_NUM)
		self._txtCorrectNum = self:setWidget(ui.TXT_CORRECT_NUM)
		self._txtTimeUsed = self:setWidget(ui.TXT_TIME_USED)

		self._btnConfirmWin = self:setWidget(ui.BTN_CONFIRM)

		return true
	until true

	return false
end

function LaBattleResultChallenge:initAnim()
	--胜利动画
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_END_PLIST1, ui.ANIM_END_PNG1)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_END_PLIST2, ui.ANIM_END_PNG2)
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.ANIM_END_JSON)
    self._animEnd = ccs.Armature:create("jieshu")
    self._animEnd:setPosition(
    	self._wiRoot:getContentSize().width / 2,self._wiRoot:getContentSize().height / 2)
    self._wiRoot:addChild(self._animEnd)

    --位置和显示的初始化
    self._layShow:setPositionY(
		self._layShow:getPositionY() - CONST.WIN_AREA_MOVE_Y)
	self._animEnd:setVisible(false)

    return true
end

----------------------------------------------

--获取数据
function LaBattleResultChallenge:setData(table)

end

function LaBattleResultChallenge:win()
	--胜利动画回调
    self._animEnd:getAnimation():setMovementEventCallFunc(
    	function (armature, movementType, movementID)
    		if movementType == ccs.MovementEventType.complete then
    			self:onWinAnimComplete()
    		end
    	end)

    self._animEnd:setVisible(true)

	self._animEnd:getAnimation():play("Animation1", -1, 0)
end

function LaBattleResultChallenge:onWinAnimComplete()
	--延时
	local acDelay = cc.DelayTime:create(0.2)

	--飞入展示层
	local acMove = cc.MoveBy:create(CONST.WIN_MOVE_TIME, 
		cc.p(0, CONST.WIN_AREA_MOVE_Y))

	--执行
	self._layShow:runAction(cc.Sequence:create(
		acDelay,
		cc.EaseExponentialOut:create(acMove)))
	
end

function LaBattleResultChallenge:lose()
	self:win()
end

return {
	Class = LaBattleResultChallenge,

}


