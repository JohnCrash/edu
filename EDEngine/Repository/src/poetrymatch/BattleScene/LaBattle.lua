---
--LaBattle.lua
--华夏诗魂的战斗图层
--实际只是一个节点，里面包含UI层
--里面利用消息在update中实现大循环，
--包括
--	进入，开场动画（请求问题），敌人出题，玩家答题，
--	准备战斗动画（给结果），战斗动画，玩家出题，
--	电脑答题（请求问题并给结果），战斗动画（请求问题），
--	胜利，失败，结果展示和处理，退出	
--_S表示此方法为状态
--卢乐颜
--2014.12.10

local lly = require "poetrymatch/BattleScene/llyLuaBase2"
local uikits = require "uikits"

lly.finalizeCurrentEnvironment()

local ui = lly.const{
	FILE = "poetrymatch/BattleScene/zhandou.ExportJson",
	FILE_3_4 = "",

	--
	TXT_PLYR_NAME = "zhandou/womz",
	IMG_PLYR_PORTRAIT = "zhandou/wo",
	TXT_PLYR_LEVEL = "zhandou/wo/dj",
	BAR_PLYR_HP = "zhandou/xuet/jd",

	TXT_ENEMY_NAME = false,
	IMG_ENEMY_PORTRAIT = "zhandou/duif",
	TXT_ENEMY_LEVEL = "zhandou/duif/dj",
	BAR_ENEMY_HP = "zhandou/xuetdf/jd",

	--上中回合数
	ATLAS_ROUNDS = "zhandou/huih/huihes",

	--玩家卡牌
	IMG_PLYR_CARD = "zhandou/wokp",
	IMG_PLYR_ANSWER_TOKEN = "zhandou/wod",
	TXT_PLYR_CARD_LEVEL = "zhandou/wokp/dj",
	BTN_PLYR_SKILL_1 = "zhandou/jns2",
	BTN_PLYR_SKILL_2 = "zhandou/jns1",
	BTN_PLYR_SKILL_3 = "zhandou/jns3",

	--敌方卡牌
	IMG_ENEMY_CARD = "zhandou/kpduif",
	IMG_ENEMY_ANSWER_TOKEN = "zhandou/duifd",
	TXT_ENEMY_CARD_LEVEL = "zhandou/kpduif/Label_71",
	BTN_ENEMY_SKILL_1 = "zhandou/dfjn1",
	BTN_ENEMY_SKILL_2 = "zhandou/dfjn2",
	BTN_ENEMY_SKILL_3 = "zhandou/dfjn3",

	--认输按钮
	BTN_GIVEUP = "zhandou/tuic",

	--答题区域
	IMG_QUESTION_AREA = "tiqu",
	TXT_COUNT_DOWN = "tiqu/daojis", --倒计时
	TXT_QUESTION_TITLE = "tiqu/went",
	TXT_QUESTION_CONTENT = "tiqu/leir",
	BTN_QUESTION_COMMIT = "tiqu/tijiao",

	--答题区
	LAY_SHORT_CHOOSE = "tiqu/renm", --短选择题
	CKB_SHORT_CHOOSE_1 = "tiqu/renm/4z1",
	CKB_SHORT_CHOOSE_2 = "tiqu/renm/4z3",
	CKB_SHORT_CHOOSE_3 = "tiqu/renm/4z2",
	CKB_SHORT_CHOOSE_4 = "tiqu/renm/4z4",
	TXT_SHORT_CHOOSE_1 = "tiqu/renm/4z1/wen",
	TXT_SHORT_CHOOSE_2 = "tiqu/renm/4z3/wen",
	TXT_SHORT_CHOOSE_3 = "tiqu/renm/4z2/wen",
	TXT_SHORT_CHOOSE_4 = "tiqu/renm/4z4/wen",

	LAY_LONG_CHOOSE = "tiqu/shiju", --长选择题
	CKB_LONG_CHOOSE_1 = "tiqu/shiju/s1",
	CKB_LONG_CHOOSE_2 = "tiqu/shiju/s2",
	CKB_LONG_CHOOSE_3 = "tiqu/shiju/s3",
	CKB_LONG_CHOOSE_4 = "tiqu/shiju/s4",
	TXT_LONG_CHOOSE_1 = "tiqu/shiju/s1/wen",
	TXT_LONG_CHOOSE_2 = "tiqu/shiju/s2/wen",
	TXT_LONG_CHOOSE_3 = "tiqu/shiju/s3/wen",
	TXT_LONG_CHOOSE_4 = "tiqu/shiju/s4/wen",

	LAY_RIGHT_OR_WRONG = "tiqu/panduan", --对错题
	CKB_LONG_RIGHT = "tiqu/panduan/dui",
	CKB_LONG_WRONG = "tiqu/panduan/cuo",

	LAY_FILL_IN_BLANK = "tiqu/tiankong", --填空题
	IPT_FILL_IN_BLANK = "tiqu/tiankong/tk/wen",

	--卡牌改变区
	IMG_CARD_CHANGE_AREA = "huiheqian",

	IMG_CARD_PORTRAIT_1 = "huiheqian/ka1", --三项
	IMG_CARD_PORTRAIT_2 = "huiheqian/k2",
	IMG_CARD_PORTRAIT_3 = "huiheqian/k3",
	TXT_CARD_LEVEL_1 = "huiheqian/ka1/dengj",
	TXT_CARD_LEVEL_2 = "huiheqian/k2/dengj",
	TXT_CARD_LEVEL_3 = "huiheqian/k3/dengj",
	TXT_CARD_NAME_1 = "huiheqian/ka1/k1mz",
	TXT_CARD_NAME_2 = "huiheqian/k2/k1mz",
	TXT_CARD_NAME_3 = "huiheqian/k3/k1mz",
	TXT_CARD_VIT_1 = "huiheqian/ka1/chis",
	TXT_CARD_VIT_2 = "huiheqian/k2/chis",
	TXT_CARD_VIT_3 = "huiheqian/k3/chis",

	TXT_COUNT_DOWN_IN_CARD_CHANGE = "huiheqian/jis/daojis",

	IMG_TIP = "wu",
	TXT_TIP = "wu/tis",
	BTN_CONFIRM = "wu/guanb",
}

local CONST = lly.const{
	CARD_MOVE_TIME = 0.3,
	CD_CHNG_MOVE_TIME = 0.7

}

--状态对应方法（见最下）
local state

local LaBattle = lly.class("LaBattle", function ()
	return cc.Node:create()
end)

function LaBattle:ctor()
	return {
		--UI
		_wiRoot = Lnull,

		--最上血条部分
		_txtPlyrName = Lnull,
		_imgPlyrPortrait = Lnull,
		_txtPlyrLevel = Lnull,
		_barPlyrHP = Lnull,

		_txtEnemyName = Lnull,
		_imgEnemyPortrait = Lnull,
		_txtEnemyLevel = Lnull,
		_barEnemyHP = Lnull,

		--上中回合数
		_atlasRounds = Lnull,

		--玩家卡牌
		_arimgPlyrCard = lly.array(3),
		_artxtPlyrCardLevel = lly.array(3),
		_imgPlyrAnswerToken = Lnull,
		_arbtnPlyrSkill = lly.array(3), --三项

		--敌方卡牌
		_imgEnemyCard = Lnull,
		_txtEnemyCardLevel = Lnull,
		_imgEnemyAnswerToken = Lnull,
		_arbtnEnemySkill = lly.array(3), --三项

		--认输按钮
		_btnGiveUp = Lnull,

		--答题区域
		_imgQuestionArea = Lnull,
		_txtCountdown = Lnull, --倒计时
		_txtQuestionTitle = Lnull,
		_txtQuestionContent = Lnull,
		_btnQuestionCommit = Lnull,

		--答题区
		_layShortChoose = Lnull, --短选择题
		_arckbShortChoose = lly.array(4), --4项
		_artxtShortChoose = lly.array(4), --4项

		_layLongChoose = Lnull, --长选择题
		_arckbLongChoose = lly.array(4), --4项
		_artxtLongChoose = lly.array(4), --4项

		_layRightOrWrong = Lnull, --对错题
		_ckbLongRight = Lnull,
		_ckbLongWrong = Lnull,

		_layFillInBlank = Lnull, --填空题
		_iptFillInBlank = Lnull,

		--卡牌改变区
		_imgCardChangeArea = Lnull,

		_arimgCardPortrait = lly.array(3), --三项
		_artxtCardLevel = lly.array(3),
		_artxtCardName = lly.array(3),
		_artxtCardVIT = lly.array(3),

		_txtCountdownInCardChange = Lnull,

		--提示区
		_imgTip = Lnull,
		_txtTip = Lnull,
		_btnConfirm = Lnull,

		--位置
		_posPlyrCard = Lnull, --玩家卡牌原始位置
		_posPlyrCardFrom = Lnull, --玩家需要此卡牌时从这个位置飞来
		_posPlyrCardTo = Lnull, --玩家不要卡牌时，飞到这个位置

		_posEnemyCard = Lnull,
		_posEnemyCardFrom = Lnull,
		_posEnemyCardTo = Lnull,

		_nDisAreaMoveY = 0, --动画时从下方上来的距离

		_posQuestionArea = Lnull, --提问区域的原始位置
		_nDisQuestionAreaMoveX = 0, --区域从一边飞过来的距离

		--当前状态
		_stateNext = Lnull, 

		--每个状态进入下个状态时要判断如下3点，
		--本状态是否结束，下个状态是否加载成功，是否禁用
		--每个状态进入时候如果把哪个设置为false，则直到变为true时才可以进入下个状态
		_bCurStateIsEnding = true, --本状态是否结束
		_bNextStateDataHasLoad = true, --下个状态是否加载成功
		_bForbidEnterNextState = false, --禁止进入下个状态

		_nSecondLeft = 0, --剩余时间

		_fLastTime = 0, --上次时间
		_fCurrentTime = 0, --当前时间，用来和上次时间计算一秒钟时间
		
	}
end

--传入一个初始化数据
function LaBattle:init(tab)
	repeat
		--UI
		if not self:initUI() then break end
		if not self:initUIWithData() then break end

		--初始化基本位置
		if not self:initPosition() then break end

		--初始化
		if not self:initData() then break end
		
		--开启更新函数
		self:scheduleUpdateWithPriorityLua(function ()
			--更换状态
			if self._bCurStateIsEnding and 
				self._bNextStateDataHasLoad and
				not self._bForbidEnterNextState and
				self._stateNext then
				self:_stateNext()
			end

			--倒计时
			if self._nSecondLeft > 0 then
				self._fCurrentTime = os.clock()

				--第一次进入时把lastTime设为0，可以在此先读入一个时间
				if self._fLastTime == 0 then self._fLastTime = self._fCurrentTime end
				
				--时间差不过1秒，则不执行以后的内容
				if self._fCurrentTime - self._fLastTime < 1 then return end

				self._nSecondLeft = self._nSecondLeft - 1

				--检查是否计时结束
				if self._nSecondLeft > 0 then
					self._fLastTime = self._fCurrentTime
					self:onTimePass()
				else
					self:onTimeEnd()
				end
			end

		end, 0)

		self._nSecondLeft = 10
		--self._stateNext = state.playEnterAnim

		return true
	until true

	return false
end

function LaBattle:initUI()
	repeat
		self._wiRoot = uikits.fromJson{file_9_16 = ui.FILE, file_3_4 = ui.FILE_3_4}

		if not self._wiRoot then break end
		self:addChild(self._wiRoot)

		--最上血条部分
		self._txtPlyrName = self:setWidget(ui.TXT_PLYR_NAME)
		self._txtPlyrLevel = self:setWidget(ui.TXT_PLYR_LEVEL)
		self._barPlyrHP = self:setWidget(ui.BAR_PLYR_HP)

		--self._txtEnemyName = self:setWidget(ui.TXT_ENEMY_NAME)
		self._txtEnemyLevel = self:setWidget(ui.TXT_ENEMY_LEVEL)
		self._barEnemyHP = self:setWidget(ui.BAR_ENEMY_HP)

		--上中回合数
		self._atlasRounds = self:setWidget(ui.ATLAS_ROUNDS)

		--玩家卡牌
		self._imgPlyrAnswerToken = self:setWidget(ui.IMG_PLYR_ANSWER_TOKEN)

		--敌方卡牌
		self._imgEnemyAnswerToken = self:setWidget(ui.IMG_ENEMY_ANSWER_TOKEN)
		
		--认输按钮
		self._btnGiveUp= self:setWidget(ui.BTN_GIVEUP)

		--答题区域
		self._imgQuestionArea = self:setWidget(ui.IMG_QUESTION_AREA)
		self._txtCountdown = self:setWidget(ui.TXT_COUNT_DOWN)
		self._txtQuestionTitle = self:setWidget(ui.TXT_QUESTION_TITLE)
		self._txtQuestionContent = self:setWidget(ui.TXT_QUESTION_CONTENT)
		self._btnQuestionCommit = self:setWidget(ui.BTN_QUESTION_COMMIT)

		--答题区
		self._layShortChoose = self:setWidget(ui.LAY_SHORT_CHOOSE)
		self._arckbShortChoose[1] = self:setWidget(ui.CKB_SHORT_CHOOSE_1)
		self._arckbShortChoose[2] = self:setWidget(ui.CKB_SHORT_CHOOSE_2)
		self._arckbShortChoose[3] = self:setWidget(ui.CKB_SHORT_CHOOSE_3)
		self._arckbShortChoose[4] = self:setWidget(ui.CKB_SHORT_CHOOSE_4)
		self._artxtShortChoose[1] = self:setWidget(ui.TXT_SHORT_CHOOSE_1)
		self._artxtShortChoose[2] = self:setWidget(ui.TXT_SHORT_CHOOSE_2)
		self._artxtShortChoose[3] = self:setWidget(ui.TXT_SHORT_CHOOSE_3)
		self._artxtShortChoose[4] = self:setWidget(ui.TXT_SHORT_CHOOSE_4)

		self._layLongChoose = self:setWidget(ui.LAY_LONG_CHOOSE)
		self._arckbLongChoose[1] = self:setWidget(ui.CKB_LONG_CHOOSE_1)
		self._arckbLongChoose[2] = self:setWidget(ui.CKB_LONG_CHOOSE_2)
		self._arckbLongChoose[3] = self:setWidget(ui.CKB_LONG_CHOOSE_3)
		self._arckbLongChoose[4] = self:setWidget(ui.CKB_LONG_CHOOSE_4)
		self._artxtLongChoose[1] = self:setWidget(ui.TXT_LONG_CHOOSE_1)
		self._artxtLongChoose[2] = self:setWidget(ui.TXT_LONG_CHOOSE_2)
		self._artxtLongChoose[3] = self:setWidget(ui.TXT_LONG_CHOOSE_3)
		self._artxtLongChoose[4] = self:setWidget(ui.TXT_LONG_CHOOSE_4)

		self._layRightOrWrong = self:setWidget(ui.LAY_RIGHT_OR_WRONG)
		self._ckbLongRight = self:setWidget(ui.CKB_LONG_RIGHT)
		self._ckbLongWrong = self:setWidget(ui.CKB_LONG_WRONG)

		self._layFillInBlank = self:setWidget(ui.LAY_FILL_IN_BLANK)
		self._iptFillInBlank = self:setWidget(ui.IPT_FILL_IN_BLANK)

		--卡牌改变区
		self._imgCardChangeArea = self:setWidget(ui.IMG_CARD_CHANGE_AREA)

		self._arimgCardPortrait[1] = self:setWidget(ui.IMG_CARD_PORTRAIT_1)
		self._arimgCardPortrait[2] = self:setWidget(ui.IMG_CARD_PORTRAIT_2)
		self._arimgCardPortrait[3] = self:setWidget(ui.IMG_CARD_PORTRAIT_3)
		self._artxtCardLevel[1] = self:setWidget(ui.TXT_CARD_LEVEL_1)
		self._artxtCardLevel[2] = self:setWidget(ui.TXT_CARD_LEVEL_2)
		self._artxtCardLevel[3] = self:setWidget(ui.TXT_CARD_LEVEL_3)
		self._artxtCardName[1] = self:setWidget(ui.TXT_CARD_NAME_1)
		self._artxtCardName[2] = self:setWidget(ui.TXT_CARD_NAME_2)
		self._artxtCardName[3] = self:setWidget(ui.TXT_CARD_NAME_3)
		self._artxtCardVIT[1] = self:setWidget(ui.TXT_CARD_VIT_1)
		self._artxtCardVIT[2] = self:setWidget(ui.TXT_CARD_VIT_2)
		self._artxtCardVIT[3] = self:setWidget(ui.TXT_CARD_VIT_3)

		self._txtCountdownInCardChange = self:setWidget(ui.TXT_COUNT_DOWN_IN_CARD_CHANGE)

		--提示区
		self._imgTip = self:setWidget(ui.IMG_TIP)
		self._txtTip = self:setWidget(ui.TXT_TIP)
		self._btnConfirm = self:setWidget(ui.BTN_CONFIRM)

		return true
	until true

	return false
end

function LaBattle:initUIWithData()
	repeat
		--头像
		self._imgPlyrPortrait = self:setWidget(ui.IMG_PLYR_PORTRAIT)
		self._imgEnemyPortrait = self:setWidget(ui.IMG_ENEMY_PORTRAIT)

		--玩家
		self._arimgPlyrCard[1] = self:setWidget(ui.IMG_PLYR_CARD)
		self._artxtPlyrCardLevel[1] = self:setWidget(ui.TXT_PLYR_CARD_LEVEL)
		
		self._arbtnPlyrSkill[1] = self:setWidget(ui.BTN_PLYR_SKILL_1)
		self._arbtnPlyrSkill[2] = self:setWidget(ui.BTN_PLYR_SKILL_2)
		self._arbtnPlyrSkill[3] = self:setWidget(ui.BTN_PLYR_SKILL_3)

		--敌人
		self._imgEnemyCard = self:setWidget(ui.IMG_ENEMY_CARD)
		self._txtEnemyCardLevel = self:setWidget(ui.TXT_ENEMY_CARD_LEVEL)
		self._arbtnEnemySkill[1] = self:setWidget(ui.BTN_ENEMY_SKILL_1)
		self._arbtnEnemySkill[2] = self:setWidget(ui.BTN_ENEMY_SKILL_2)
		self._arbtnEnemySkill[3] = self:setWidget(ui.BTN_ENEMY_SKILL_3)

		return true
	until true

	return false
end	

function LaBattle:initPosition()
	self._posPlyrCard = cc.p(self._arimgPlyrCard[1]:getPosition())
	self._posPlyrCardFrom = cc.p(self._posPlyrCard.x - 340, self._posPlyrCard.y + 100)
	self._posPlyrCardTo = cc.p(self._posPlyrCard.x - 340, self._posPlyrCard.y - 100)

	self._posEnemyCard = cc.p(self._imgEnemyCard:getPosition())
	self._posEnemyCardFrom = cc.p(self._posEnemyCard.x + 340, self._posEnemyCard.y + 100)
	self._posEnemyCardTo = cc.p(self._posEnemyCard.x + 340, self._posEnemyCard.y - 100)

	self._nDisAreaMoveY = 1000

	self._posQuestionArea = cc.p(self._imgQuestionArea:getPosition())
	self._nDisQuestionAreaMoveX = 2000


	return true

end

function LaBattle:initData()
	--卡牌
	self._arimgPlyrCard[1]:setPosition(self._posPlyrCardFrom)
	self._imgEnemyCard:setPosition(self._posEnemyCardFrom)

	--隐藏技能
	for i = 1, 3 do
		self._arbtnPlyrSkill[i]:setVisible(false)
		self._arbtnEnemySkill[i]:setVisible(false)
	end

	--隐藏答题标识
	self._imgPlyrAnswerToken:setVisible(false)
	self._imgEnemyAnswerToken:setVisible(false)
	
	--各个区域的位置
	self._imgCardChangeArea:setPositionY(
		self._imgCardChangeArea:getPositionY() - self._nDisAreaMoveY)

	self._imgTip:setPositionY(
		self._imgTip:getPositionY() - self._nDisAreaMoveY)

	self._imgQuestionArea:setPositionX(
		self._posQuestionArea.x + self._nDisQuestionAreaMoveX)
end

------------------------------------------------------
--【私有函数】，打印当前状态
local function printState(str)
	lly.log(str)
	
	---[[
	local socket = require("socket")
	socket.select(nil, nil, 1)
	--]]
end


-------------------------------------------------------
function LaBattle:setWidget(filename)
	local widget = uikits.child(self._wiRoot, filename)
	if not widget then
		lly.error("wrong widget filename")
	end

	return widget
end

--倒计时
function LaBattle:beginCountingdown(second)
	printState("begin counting down")

	self._nSecondLeft = second
	self._fLastTime = 0
end

--停止倒计时
function LaBattle:stopCountingdown(second)
	printState("stop counting down")

	self._nSecondLeft = 0
end

--计时器每过一秒的回调
function LaBattle:onTimePass()
	lly.log(os.time())
end

--计时结束的回调
function LaBattle:onTimeEnd()
	lly.log("time is up")
end

--使用道具
function LaBattle:useItem()
	printState("use item")

	--禁止进入下个状态
	self._bForbidEnterNextState = true

	--进行动画（完成是检查请求是否完成，完成则取消禁止）

	--请求服务器（完成是检查动画是否完成，完成则取消禁止）

end


----------------------------------------------------------
--开场动画状态
function LaBattle:playEnterAnim_S()
	printState("play Enter Anim")

	--设置下个状态
	self._stateNext = state.prepare
	self._bCurStateIsEnding = false

	--执行动画，完成后ending为true
	local acMovePC = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posPlyrCard)
	local acMoveEC = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posEnemyCard)
	local callFunc = cc.CallFunc:create(function ()
		self._bCurStateIsEnding = true
	end)

	self._imgPlyrCard:runAction(cc.EaseExponentialOut:create(acMovePC))
	self._imgEnemyCard:runAction(
		cc.Sequence:create(cc.EaseExponentialOut:create(acMovePC), callFunc))

end

--玩家准备出题，选择人物，选择技能
function LaBattle:prepare_S()
	printState("prepare")

	--设置下个状态
	self._stateNext = state.askByEnemy

	--展示选择页面
	local acMoveCC = cc.MoveBy:create(CONST.CD_CHNG_MOVE_TIME, 
		cc.p(0, self._nDisAreaMoveY))

	self._imgCardChangeArea:runAction(cc.EaseExponentialOut:create(acMoveCC))

	--同时下载敌方的题

end

--敌方出题
function LaBattle:askByEnemy_S()
	printState("ask by enemy")

	--设置下个状态
	self._stateNext = state.waitingForPlayerAnswer

	--load为true

	--地方试题展示动画，完成后ending为true

end

--等待玩家答题
--玩家可以使用道具，进入道具动画状态，进入时禁止点击提交
--等待玩家提交答案，或者倒计时结束
function LaBattle:waitingForPlayerAnswer_S()
	printState("waiting for player answer")

	--设置下个状态
	self._stateNext = state.attackByPlayer

	--开始倒计时

end

--玩家进攻
function LaBattle:attackByPlayer_S()
	printState("attack by player")

	--设置下个状态
	self._stateNext = state.showResultOfPlayerAtk

	--答题动画

	--进行一部分动画，同时提交服务器答案等待验证，同时申请玩家出的题目

end

--玩家进攻结果
function LaBattle:showResultOfPlayerAtk_S()
	printState("show Result Of Player Atk")

	--设置下个状态
	self._stateNext = state.askByPlayer

	--根据结果展示谁减少HP

end

--玩家出题
function LaBattle:askByPlayer_S()
	printState("ask by player")

	--设置下个状态
	self._stateNext = state.waitingForEnemyAnswer

	--玩家出题展示动画

end

--等待敌人答题
function LaBattle:waitingForEnemyAnswer_S()
	printState("waiting for enemy answer")

	--设置下个状态
	self._stateNext = state.attackByEnemy

	--开始倒计时

	--根据服务器反馈的时间，时间到达后进入下个状态

end

--敌人进攻
function LaBattle:attackByEnemy_S()
	printState("attack by enemy")

	--设置下个状态
	self._stateNext = state.showResultOfEnemyAtk

end

--敌人进攻结果
function LaBattle:showResultOfEnemyAtk_S()
	printState("show Result Of Enemy Atk")

	--设置下个状态
	self._stateNext = state.askByEnemy

end

--胜利
function LaBattle:win_S()
	printState("win")

	--设置下个状态
	self._stateNext = state.enterEnding

end

--失败
function LaBattle:lose_S()
	printState("lose")

	--设置下个状态
	self._stateNext = state.enterEnding

end

--进入结束画面
function LaBattle:enterEnding_S()
	printState("enter ending")

end


state = lly.const{
	playEnterAnim = LaBattle.playEnterAnim_S,
	prepare = LaBattle.prepare_S,
	askByEnemy = LaBattle.askByEnemy_S,
	waitingForPlayerAnswer = LaBattle.waitingForPlayerAnswer_S,
	attackByPlayer = LaBattle.attackByPlayer_S,
	showResultOfPlayerAtk = LaBattle.showResultOfPlayerAtk_S,
	askByPlayer = LaBattle.askByPlayer_S,
	waitingForEnemyAnswer = LaBattle.waitingForEnemyAnswer_S,
	attackByEnemy = LaBattle.attackByEnemy_S,
	showResultOfEnemyAtk = LaBattle.showResultOfEnemyAtk_S,
	win = LaBattle.win_S,
	lose = LaBattle.lose_S,
	enterEnding = LaBattle.enterEnding_S,
}

return {
	Class = LaBattle,
}

