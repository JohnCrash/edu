---
--LaBattleResultFight.lua
--华夏诗魂的对战战斗结束图层

--卢乐颜
--2014.12.15

local lly = require "poetrymatch/BattleScene/llyLuaBase2"
local uikits = require "uikits"

local moLaBattleResultBase = require "poetrymatch/BattleScene/LaBattleResultBase"
local moperson_info = require "poetrymatch/person_info"

lly.finalizeCurrentEnvironment()

local ui = lly.const{
	FILE = "poetrymatch/BattleScene/result_fight/dzjieguo.ExportJson",
	FILE_3_4 = "",

	--胜利层
	LAY_WIN = "shengli",

	IMG_PLYR_PORTRAIT = "shengli/wodetoux",
	TXT_PLYR_NAME = "shengli/wodetoux/mz",

	IMG_RANK = "shengli/tu",
	ATLAS_RANK = "shengli/tu/xianpm",

	IMG_ENEMY_PORTRAIT = "shengli/duif",
	TXT_ENEMY_NAME = "shengli/duif/mz",

	BTN_CONFIRM_WIN = "shengli/hui",

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
	WIN_AREA_MOVE_Y = 1000,

	WIN_MOVE_TIME = 0.4,

	RANK_MOVE_y = 30,

	RANK_MOVE_TIME = 0.8,
}

local LaBattleResultFight = lly.class("LaBattleResultFight", moLaBattleResultBase.Class)

function LaBattleResultFight:ctor()
	return {

		--胜利层
		_layWin = Lnull,

		_imgPlyrPortrait = Lnull,
		_txtPlyrName = Lnull,

		_imgRank = Lnull,
		_atlasRank = Lnull,

		_imgEnemyPortrait = Lnull,
		_txtEnemyName = Lnull,

		--失败层
		_layLose = Lnull,

		--动画
		_animWin = Lnull,
		_animLose = Lnull,
		
	}
end

function LaBattleResultFight:init(tab)
	return self.super.init(self, tab)
end

function LaBattleResultFight:initUI(tab)
	repeat
		--UI
		self._wiRoot = uikits.fromJson{file_9_16 = ui.FILE, file_3_4 = ui.FILE_3_4}

		if not self._wiRoot then break end
		self:addChild(self._wiRoot)

		--胜利层
		self._layWin = self:setWidget(ui.LAY_WIN)

		self._imgPlyrPortrait = self:setWidget(ui.IMG_PLYR_PORTRAIT)
		self._txtPlyrName = self:setWidget(ui.TXT_PLYR_NAME)
		
		self._imgRank = self:setWidget(ui.IMG_RANK)
		self._atlasRank = self:setWidget(ui.ATLAS_RANK)

		self._imgEnemyPortrait = self:setWidget(ui.IMG_ENEMY_PORTRAIT)
		self._txtEnemyName = self:setWidget(ui.TXT_ENEMY_NAME)

		self._btnConfirmWin = self:setWidget(ui.BTN_CONFIRM_WIN)

		--失败层
		self._layLose = self:setWidget(ui.LAY_LOSE)
		self._btnConfirmLose = self:setWidget(ui.BTN_CONFIRM_LOSE)

		--初始化
		--名字和头像
		self._txtPlyrName:setString(tab.name)
		self._txtEnemyName:setString(tab.enemy_name)

		moperson_info.load_logo_pic(self._imgPlyrPortrait, tab.plyr_id)
		moperson_info.load_logo_pic(self._imgEnemyPortrait, tab.enemy_id)

		return true
	until true

	return false
end

function LaBattleResultFight:initAnim()
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
    self._layWin:setPositionY(
		self._layWin:getPositionY() - CONST.WIN_AREA_MOVE_Y)
	self._animWin:setVisible(false)

	self._layLose:setVisible(false)
	self._animLose:setVisible(false)

    return true
end

----------------------------------------------

--获取数据
function LaBattleResultFight:setData(table)
	lly.logTable(table)
	self._atlasRank:setData(table.ranking)
end

function LaBattleResultFight:win()
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

function LaBattleResultFight:onWinAnimComplete()
	--延时
	local acDelay = cc.DelayTime:create(0.2)

	--飞入展示层
	local acMove = cc.MoveBy:create(CONST.WIN_MOVE_TIME, 
		cc.p(0, CONST.WIN_AREA_MOVE_Y))

	--执行
	self._layWin:runAction(cc.Sequence:create(
		acDelay,
		cc.EaseExponentialOut:create(acMove)))
	
end

function LaBattleResultFight:lose()
	lly.log("lose anim")

	self._animLose:getAnimation():setMovementEventCallFunc(
    	function (armature, movementType, movementID)
    		if movementType == ccs.MovementEventType.complete then
    			self:onLoseAnimComplete()
    		end
    	end)

	self._animLose:setVisible(true)

	self._animLose:getAnimation():play("shibai", -1, 0)
end

function LaBattleResultFight:onLoseAnimComplete()
	self._layLose:setVisible(true)
end

return {
	Class = LaBattleResultFight,

}


