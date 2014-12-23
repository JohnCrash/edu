---
--LaBattleResultStory.lua
--华夏诗魂的闯关战斗结束图层

--卢乐颜
--2014.12.15

local lly = require "poetrymatch/BattleScene/llyLuaBase2"
local uikits = require "uikits"

local moLaBattleResultBase = require "poetrymatch/BattleScene/LaBattleResultBase"

lly.finalizeCurrentEnvironment()

local ui = lly.const{
	FILE = "poetrymatch/BattleScene/result/jieguo.ExportJson",
	FILE_3_4 = "",

	--胜利层
	LAY_WIN = "shengli",
	IMG_SHOW_GET = "shengli/huode",

	IMG_STAR_1 = "shengli/huode/x1/xx",
	IMG_STAR_2 = "shengli/huode/x2/xx",
	IMG_STAR_3 = "shengli/huode/x3/xx",

	TXT_ACHIEVEMENT_1 = "shengli/huode/x1/wen1",
	TXT_ACHIEVEMENT_2 = "shengli/huode/x1/wen1",
	TXT_ACHIEVEMENT_3 = "shengli/huode/x1/wen1",

	TXT_GET_YINBI = "shengli/huode/hd1_0/yinbi",
	TXT_GET_LEBI = "shengli/huode/hd1/lebi",
	TXT_GET_CARD = "shengli/huode/hd1_1/kapai",
	IMG_GET_CARD = "shengli/huode/hd1_1/tu",

	IMG_PLYR_PORTRAIT = "shengli/huode/wo",
	TXT_PLYR_NAME = "shengli/huode/wo/mz",
	TXT_PLYR_LEVEL = "shengli/huode/wo/dj",
	BAR_PLYR_EXP = "shengli/huode/wo/dengji/jidu",

	IMG_CARD_1 = "shengli/huode/k1",
	TXT_CARD_NAME_1 = "shengli/huode/k1/Label_87",
	TXT_CARD_LEVEL_1 = "shengli/huode/k1/dj",
	BAR_CARD_EXP_1 = "shengli/huode/k1/k1dj/jidu",

	IMG_CARD_2 = "shengli/huode/k2",
	TXT_CARD_NAME_2 = "shengli/huode/k2/Label_87",
	TXT_CARD_LEVEL_2 = "shengli/huode/k2/dj",
	BAR_CARD_EXP_2 = "shengli/huode/k2/k1dj/jidu",

	IMG_CARD_3 = "shengli/huode/k3",
	TXT_CARD_NAME_3 = "shengli/huode/k3/Label_87",
	TXT_CARD_LEVEL_3 = "shengli/huode/k3/dj",
	BAR_CARD_EXP_3 = "shengli/huode/k3/k1dj/jidu",

	BTN_CONFIRM_WIN = "shengli/huode/Button_107",

	--失败层
	LAY_LOSE = "shibai",

	BTN_CONFIRM_LOSE = "shibai/fanh",

	--动画
	ANIM_WIN_PNG = "poetrymatch/BattleScene/anim_win/shengli0.png",
	ANIM_WIN_PLIST = "poetrymatch/BattleScene/anim_win/shengli0.plist",
	ANIM_WIN_JSON = "poetrymatch/BattleScene/anim_win/shengli.ExportJson",
	
	ANIM_LOSE_PNG = "poetrymatch/BattleScene/anim_lose/shibai0.png",
	ANIM_LOSE_PLIST = "poetrymatch/BattleScene/anim_lose/shibai0.plist",
	ANIM_LOSE_JSON = "poetrymatch/BattleScene/anim_lose/shibai.ExportJson",
}

local CONST = lly.const{
	SHOW_GET_AREA_MOVE_Y = 1000,

	SHOW_GET_MOVE_TIME = 0.4,
}

local LaBattleResultStory = lly.class("LaBattleResultStory", moLaBattleResultBase.Class)

function LaBattleResultStory:ctor()
	return {

		--胜利层
		_layWin = Lnull,
		_imgShowGet = Lnull,

		_arimgStar = lly.array(3),

		_artxtAchievement = lly.array(3),

		_artxtGet = lly.array(3),
		_imgGet = Lnull,

		_imgPlyrPortrait = Lnull,
		_txtPlyrName = Lnull,
		_txtPlyrLevel = Lnull,
		_barPlyrExp = Lnull,

		_arimgCard = lly.array(3),
		_artxtCardName = lly.array(3),
		_artxtCardLevel = lly.array(3),
		_arbarCardExp = lly.array(3),

		--失败层
		_layLose = Lnull,

		--动画
		_animWin = Lnull,
		_animLose = Lnull,
		
	}
end

function LaBattleResultStory:init(tab)
	return self.super.init(self, tab)
end

function LaBattleResultStory:initUI()
	repeat
		--UI
		self._wiRoot = uikits.fromJson{file_9_16 = ui.FILE, file_3_4 = ui.FILE_3_4}

		if not self._wiRoot then break end
		self:addChild(self._wiRoot)

		--胜利层
		self._layWin = self:setWidget(ui.LAY_WIN)
		self._imgShowGet = self:setWidget(ui.IMG_SHOW_GET)

		self._arimgStar[1] = self:setWidget(ui.IMG_STAR_1)
		self._arimgStar[2] = self:setWidget(ui.IMG_STAR_2)
		self._arimgStar[3] = self:setWidget(ui.IMG_STAR_3)

		self._artxtAchievement[1] = self:setWidget(ui.TXT_ACHIEVEMENT_1)
		self._artxtAchievement[2] = self:setWidget(ui.TXT_ACHIEVEMENT_2)
		self._artxtAchievement[3] = self:setWidget(ui.TXT_ACHIEVEMENT_3)

		self._artxtGet[1] = self:setWidget(ui.TXT_GET_YINBI)
		self._artxtGet[2] = self:setWidget(ui.TXT_GET_LEBI)
		self._artxtGet[3] = self:setWidget(ui.TXT_GET_CARD)
		self._imgGet = self:setWidget(ui.IMG_GET_CARD)

		self._imgPlyrPortrait = self:setWidget(ui.IMG_PLYR_PORTRAIT)
		self._txtPlyrName = self:setWidget(ui.TXT_PLYR_NAME)
		self._txtPlyrLevel = self:setWidget(ui.TXT_PLYR_LEVEL)
		self._barPlyrExp = self:setWidget(ui.BAR_PLYR_EXP)

		self._arimgCard[1] = self:setWidget(ui.IMG_CARD_1)
		self._arimgCard[2] = self:setWidget(ui.IMG_CARD_2)
		self._arimgCard[3] = self:setWidget(ui.IMG_CARD_3)

		self._artxtCardName[1] = self:setWidget(ui.TXT_CARD_LEVEL_1)
		self._artxtCardName[2] = self:setWidget(ui.TXT_CARD_LEVEL_2)
		self._artxtCardName[3] = self:setWidget(ui.TXT_CARD_LEVEL_3)

		self._artxtCardLevel[1] = self:setWidget(ui.TXT_CARD_NAME_1)
		self._artxtCardLevel[2] = self:setWidget(ui.TXT_CARD_NAME_2)
		self._artxtCardLevel[3] = self:setWidget(ui.TXT_CARD_NAME_3)

		self._arbarCardExp[1] = self:setWidget(ui.BAR_CARD_EXP_1)
		self._arbarCardExp[2] = self:setWidget(ui.BAR_CARD_EXP_2)
		self._arbarCardExp[3] = self:setWidget(ui.BAR_CARD_EXP_3)

		self._btnConfirmWin = self:setWidget(ui.BTN_CONFIRM_WIN)

		--失败层
		self._layLose = self:setWidget(ui.LAY_LOSE)
		self._btnConfirmLose = self:setWidget(ui.BTN_CONFIRM_LOSE)

		return true
	until true

	return false
end

function LaBattleResultStory:initAnim()
	--胜利动画
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(
		ui.ANIM_WIN_PNG, ui.ANIM_WIN_PLIST, ui.ANIM_WIN_JSON)
    self._animWin = ccs.Armature:create("shengli")
    self._animWin:setPosition(
    	self._wiRoot:getContentSize().width / 2,self._wiRoot:getContentSize().height / 2)
    self._wiRoot:addChild(self._animWin)

    --失败动画
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(
		ui.ANIM_LOSE_PNG, ui.ANIM_LOSE_PLIST, ui.ANIM_LOSE_JSON)
    self._animLose = ccs.Armature:create("shibai")
    self._animLose:setPosition(
    	self._wiRoot:getContentSize().width / 2,self._wiRoot:getContentSize().height / 2)
    self._wiRoot:addChild(self._animLose)

    --位置和显示的初始化
    self._imgShowGet:setPositionY(
		self._imgShowGet:getPositionY() - CONST.SHOW_GET_AREA_MOVE_Y)
	self._animWin:setVisible(false)

	self._layLose:setVisible(false)
	self._animLose:setVisible(false)

    return true
end

----------------------------------------------

--获取数据
function LaBattleResultStory:setData(table)

end

function LaBattleResultStory:win()
	--胜利动画回调
    self._animWin:getAnimation():setMovementEventCallFunc(
    	function (armature, movementType, movementID)
    		if movementType == ccs.MovementEventType.complete then
    			self:onWinAnimComplete()
    		end
    	end)

    self._animWin:setVisible(true)

	self._animWin:getAnimation():play("shengli", -1, 0)
end

function LaBattleResultStory:onWinAnimComplete()
	--延时
	local acDelay = cc.DelayTime:create(0.2)

	--飞入展示层
	local acMove = cc.MoveBy:create(CONST.SHOW_GET_MOVE_TIME, 
		cc.p(0, CONST.SHOW_GET_AREA_MOVE_Y))

	--点亮五星

	--增加经验

	--执行
	self._imgShowGet:runAction(cc.Sequence:create(
		acDelay,
		cc.EaseExponentialOut:create(acMove)))
end

function LaBattleResultStory:lose()
	self._animLose:getAnimation():setMovementEventCallFunc(
    	function (armature, movementType, movementID)
    		if movementType == ccs.MovementEventType.complete then
    			self:onLoseAnimComplete()
    		end
    	end)

	self._animLose:setVisible(true)

	self._animLose:getAnimation():play("shibai", -1, 0)
end

function LaBattleResultStory:onLoseAnimComplete()
	self._layLose:setVisible(true)
end

return {
	Class = LaBattleResultStory,

}


