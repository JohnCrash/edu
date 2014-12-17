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

local moLaBattleResult = require "poetrymatch/BattleScene/LaBattleResult"

--题的类型
local QUSE_TYPE = {
	SINGLE_CHOICE = 1, --单选
	MULTIPLE_CHOICE = 2, --多选
	YES_OR_NO = 3, --对错
	FILL_IN_BLANK = 4, --填空
	MAX = 5,
}

lly.finalizeCurrentEnvironment()

local ui = lly.const{
	FILE = "poetrymatch/BattleScene/battle/zhandou.ExportJson",
	FILE_3_4 = "",

	--
	LAY_CENTER_UI = "zhandou/centerUI",

	TXT_PLYR_NAME = "zhandou/centerUI/womz",
	IMG_PLYR_PORTRAIT = "zhandou/wo",
	TXT_PLYR_LEVEL = "zhandou/wo/dj",
	BAR_PLYR_HP = "zhandou/centerUI/xuet/jd",

	TXT_ENEMY_NAME = "zhandou/centerUI/huih/duifmz",
	IMG_ENEMY_PORTRAIT = "zhandou/duif",
	TXT_ENEMY_LEVEL = "zhandou/duif/dj",
	BAR_ENEMY_HP = "zhandou/centerUI/xuetdf/jd",

	--上中回合数
	ATLAS_ROUNDS = "zhandou/centerUI/huih/huihes",

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

	LAY_SHIELD = "tiqu/sheild", --屏蔽层

	--卡牌改变区
	IMG_CARD_CHANGE_AREA = "huiheqian",

	CKB_CARD_1 = "huiheqian/ka1", --三项
	CKB_CARD_2 = "huiheqian/ka2", --三项
	CKB_CARD_3 = "huiheqian/ka3", --三项

	IMG_CARD_PORTRAIT_1 = "huiheqian/ka1/katu", --三项
	IMG_CARD_PORTRAIT_2 = "huiheqian/ka2/katu",
	IMG_CARD_PORTRAIT_3 = "huiheqian/ka3/katu",
	TXT_CARD_LEVEL_1 = "huiheqian/ka1/dengji",
	TXT_CARD_LEVEL_2 = "huiheqian/ka2/dengji",
	TXT_CARD_LEVEL_3 = "huiheqian/ka3/dengji",
	TXT_CARD_NAME_1 = "huiheqian/ka1/mz",
	TXT_CARD_NAME_2 = "huiheqian/ka2/mz",
	TXT_CARD_NAME_3 = "huiheqian/ka3/mz",
	TXT_CARD_VIT_1 = "huiheqian/ka1/cs",
	TXT_CARD_VIT_2 = "huiheqian/ka2/cs",
	TXT_CARD_VIT_3 = "huiheqian/ka3/cs",

	BTN_CONFIRM_CHANGE_CARD = "huiheqian/quer",

	TXT_COUNT_DOWN_IN_CARD_CHANGE = "huiheqian/jis/daojis",

	IMG_TIP = "wu",
	TXT_TIP = "wu/tis",
	BTN_CONFIRM = "wu/guanb",

	--对话
	IMG_PLYR_TALK = "talk/wos",
	IMG_ENEMY_TALK = "talk/dfs",

	--粒子层
	LAY_PARTICLE = "bjdh1",
}

local CONST = lly.const{
	CARD_MOVE_X = 450,
	CARD_MOVE_Y = 120,
	CARD_MOVE_TIME = 0.2,
	CARD_SCALE_FROM = 1.5, --卡牌来之前有点放大，显得像从上空扔下来

	CD_CHNG_MOVE_TIME = 0.4,
	TALK_MOVE_TIME = 0.2,
	TALK_DELAY_TIME = 0.7,
	QUES_MOVE_TIME = 0.5,
	QUES_FADE_TIME = 0.1,

	QUES_FADE = 200,
	QUES_COLOR = 150,

	--倒计时
	CHANGE_CARD_TIME = 5,
	ANSWER_TIME = 12,

	--粒子效果
	PARTICLE_WIND = "poetrymatch/BattleScene/Particles/hua.plist",
	PARTICLE_SNOW = "poetrymatch/BattleScene/Particles/xue.plist",

	--zorder
	Z_UI = 0,
	Z_RESULT = 100,

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
		_layCenterUI = Lnull,

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

		_layShield = Lnull, --屏蔽层

		--卡牌改变区
		_imgCardChangeArea = Lnull,

		_arckbCard = lly.array(3),
		_arimgCardPortrait = lly.array(3), --三项
		_artxtCardLevel = lly.array(3),
		_artxtCardName = lly.array(3),
		_artxtCardVIT = lly.array(3),

		_btnConfirmChangeCard = Lnull,

		_txtCountdownInCardChange = Lnull,

		--提示区
		_imgTip = Lnull,
		_txtTip = Lnull,
		_btnConfirm = Lnull,

		--对话
		_imgPlyrTalk = Lnull,
		_imgEnemyTalk = Lnull,

		_laResult = Lnull,

		--位置
		_posPlyrCard = Lnull, --玩家卡牌原始位置
		_posPlyrCardFrom = Lnull, --玩家需要此卡牌时从这个位置飞来
		_posPlyrCardTo = Lnull, --玩家不要卡牌时，飞到这个位置

		_posEnemyCard = Lnull,
		_posEnemyCardFrom = Lnull,
		_posEnemyCardTo = Lnull,

		_nDisAreaMoveY = 0, --动画时从下方上来的距离
		_nDisTalkMove = 0,

		_posQuestionArea = Lnull, --提问区域的原始位置
		_nDisQuestionAreaMoveX = 0, --区域从一边飞过来的距离

		_posEnemyAnswerToken = Lnull, --标识位置
		_posPlyrAnswerToken = Lnull,

		--离子
		_layParticle = Lnull, --粒子效果所在层
		_particle = Lnull,

		--下个状态
		_stateNext = Lnull, 

		--每个状态进入下个状态时要判断如下3点，
		--本状态是否结束，下个状态是否加载成功，是否禁用
		--每个状态进入时候如果把哪个设置为false，则直到变为true时才可以进入下个状态
		_bCurStateIsEnding = true, --本状态是否结束
		_bNextStateDataHasLoad = true, --下个状态是否加载成功
		_bForbidEnterNextState = false, --禁止进入下个状态

		--忙碌
		_bBuzyToChangeCard = false,
		_bBuzyToEndingState = false,

		--倒计时
		_nSecondLeft = 0, --剩余时间

		_fLastTime = 0, --上次时间
		_fCurrentTime = 0, --当前时间，用来和上次时间计算一秒钟时间

		--各种属性
		_nCurCardIndex = 1, --当前卡牌

		_nRoundsNumber = 0, --回合数

		_nPlyrHPCeiling = 0, --玩家HP上限
		_nEnemyHPCeiling = 0, --敌人HP上限
		_nPlyrCurrentHP = 0, --玩家当前HP
		_nEnemyCurrentHP = 0, --敌人当前HP

		_nCurQuesType = QUSE_TYPE.SINGLE_CHOICE, --当前题类型
		
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
		
		--初始化动画
		if not self:initAnim() then break end

		--初始化数据
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
				if self._fLastTime == 0 then 
					self._fLastTime = self._fCurrentTime
					self:onTimePass()
				end
				
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

		--self._nSecondLeft = 10
		self._stateNext = state.playEnterAnim

		return true
	until true

	return false
end

function LaBattle:initUI()
	repeat
		self._wiRoot = uikits.fromJson{file_9_16 = ui.FILE, file_3_4 = ui.FILE_3_4}

		if not self._wiRoot then break end
		self:addChild(self._wiRoot, CONST.Z_UI)

		--最上血条部分
		self._layCenterUI = self:setWidget(ui.LAY_CENTER_UI)

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
		self._btnGiveUp = self:setWidget(ui.BTN_GIVEUP)
		uikits.event(self._btnGiveUp, function (sender)
			
		end)

		--答题区域
		self._imgQuestionArea = self:setWidget(ui.IMG_QUESTION_AREA)
		self._txtCountdown = self:setWidget(ui.TXT_COUNT_DOWN)
		self._txtQuestionTitle = self:setWidget(ui.TXT_QUESTION_TITLE)
		self._txtQuestionContent = self:setWidget(ui.TXT_QUESTION_CONTENT)
		self._btnQuestionCommit = self:setWidget(ui.BTN_QUESTION_COMMIT)

		uikits.event(self._btnQuestionCommit, function (sender)
			if self._stateNext == state.attackByEnemy then
				self:endPlayerAnswer()
			elseif self._stateNext == state.attackByPlayer then
				self:endEnemyAnswer()
			end
		end)

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

		--uikits.event的回调
		local function onClickShortChoose(sender, eventType)
			self:onClickShortChoose(sender, eventType)			
		end

		for i = 1, 4 do
			uikits.event(self._arckbShortChoose[i], onClickShortChoose)
		end

		--长选择
		self._layLongChoose = self:setWidget(ui.LAY_LONG_CHOOSE)
		self._arckbLongChoose[1] = self:setWidget(ui.CKB_LONG_CHOOSE_1)
		self._arckbLongChoose[2] = self:setWidget(ui.CKB_LONG_CHOOSE_2)
		self._arckbLongChoose[3] = self:setWidget(ui.CKB_LONG_CHOOSE_3)
		self._arckbLongChoose[4] = self:setWidget(ui.CKB_LONG_CHOOSE_4)
		self._artxtLongChoose[1] = self:setWidget(ui.TXT_LONG_CHOOSE_1)
		self._artxtLongChoose[2] = self:setWidget(ui.TXT_LONG_CHOOSE_2)
		self._artxtLongChoose[3] = self:setWidget(ui.TXT_LONG_CHOOSE_3)
		self._artxtLongChoose[4] = self:setWidget(ui.TXT_LONG_CHOOSE_4)

		--uikits.event的回调
		local function onClickLongChoose(sender, eventType)
			self:onClickLongChoose(sender, eventType)			
		end

		for i = 1, 4 do
			uikits.event(self._arckbLongChoose[i], onClickLongChoose)
		end

		--对错
		self._layRightOrWrong = self:setWidget(ui.LAY_RIGHT_OR_WRONG)
		self._ckbLongRight = self:setWidget(ui.CKB_LONG_RIGHT)
		self._ckbLongWrong = self:setWidget(ui.CKB_LONG_WRONG)

		--uikits.event的回调
		local function onClickYesOrNo(sender, eventType)
			self:onClickYesOrNo(sender, eventType)			
		end

		uikits.event(self._ckbLongRight, onClickYesOrNo)
		uikits.event(self._ckbLongWrong, onClickYesOrNo)

		--填空
		self._layFillInBlank = self:setWidget(ui.LAY_FILL_IN_BLANK)
		self._iptFillInBlank = self:setWidget(ui.IPT_FILL_IN_BLANK)

		self._layShield = self:setWidget(ui.LAY_SHIELD)

		---[[
		self._layFillInBlank:setVisible(false)
		self._layShortChoose:setVisible(false)
		self._layLongChoose:setVisible(true)
		--]]

		--卡牌改变区
		self._imgCardChangeArea = self:setWidget(ui.IMG_CARD_CHANGE_AREA)

		self._arckbCard[1] = self:setWidget(ui.CKB_CARD_1)
		self._arckbCard[2] = self:setWidget(ui.CKB_CARD_2)
		self._arckbCard[3] = self:setWidget(ui.CKB_CARD_3)
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

		self._btnConfirmChangeCard = self:setWidget(ui.BTN_CONFIRM_CHANGE_CARD)

		self._txtCountdownInCardChange = self:setWidget(ui.TXT_COUNT_DOWN_IN_CARD_CHANGE)

		--uikits.event的回调
		local function onClickChangeCard(sender, eventType)
			self:onClickChangeCard(sender, eventType)			
		end

		for i = 1, 3 do
			uikits.event(self._arckbCard[i], onClickChangeCard)
		end

		local function onClickConfirmChangeCard(sender)
			--要是有特效等无法进入下个场景时点击无效
			if self._bForbidEnterNextState then return end

			--收起人物选择框后进入下个场景
			self:endPrepare()
		end
		
		uikits.event(self._btnConfirmChangeCard, onClickConfirmChangeCard)

		--提示区
		self._imgTip = self:setWidget(ui.IMG_TIP)
		self._txtTip = self:setWidget(ui.TXT_TIP)
		self._btnConfirm = self:setWidget(ui.BTN_CONFIRM)

		--对话
		self._imgPlyrTalk = self:setWidget(ui.IMG_PLYR_TALK)
		self._imgEnemyTalk = self:setWidget(ui.IMG_ENEMY_TALK)

		--离子效果 随机加载两种不同的效果
		self._layParticle = self:setWidget(ui.LAY_PARTICLE)

		math.randomseed(os.time())
		if math.random(2) == 1 then
			self._particle = cc.ParticleSystemQuad:create(CONST.PARTICLE_WIND)
			self._particle:setPosition(
				cc.Director:getInstance():getVisibleSize().width, 
				cc.Director:getInstance():getVisibleSize().height / 2)
			self._particle:setScale(3.0)
			self._layParticle:addChild(self._particle)
		else
			self._particle = cc.ParticleSystemQuad:create(CONST.PARTICLE_SNOW)
			self._particle:setPosition(
				cc.Director:getInstance():getVisibleSize().width / 2, 
				cc.Director:getInstance():getVisibleSize().height)
			self._particle:setScale(3.0)
			self._layParticle:addChild(self._particle)
		end

		--结束图层初始化
		self._laResult = moLaBattleResult.Class:create()
		if not self._laResult then break end

		self:addChild(self._laResult, CONST.Z_RESULT)
		self._laResult:setVisible(false)

		--结束图层的按钮的回调
		self._laResult:setWinBtnFunc(function ()
			lly.log("press win btn")
		end)

		self._laResult:setLoseBtnFunc(function ()
			lly.log("press lose btn")
		end)

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
	--卡牌位置
	self._posPlyrCard = cc.p(self._arimgPlyrCard[1]:getPosition())
	self._posPlyrCardFrom = cc.p(
		self._posPlyrCard.x - CONST.CARD_MOVE_X, self._posPlyrCard.y + CONST.CARD_MOVE_Y)
	self._posPlyrCardTo = cc.p(
		self._posPlyrCard.x - CONST.CARD_MOVE_X, self._posPlyrCard.y - CONST.CARD_MOVE_Y)

	self._posEnemyCard = cc.p(self._imgEnemyCard:getPosition())
	self._posEnemyCardFrom = cc.p(
		self._posEnemyCard.x + CONST.CARD_MOVE_X, self._posEnemyCard.y + CONST.CARD_MOVE_Y)
	self._posEnemyCardTo = cc.p(
		self._posEnemyCard.x + CONST.CARD_MOVE_X, self._posEnemyCard.y - CONST.CARD_MOVE_Y)

	--区域位置
	self._nDisAreaMoveY = 1000

	self._posQuestionArea = cc.p(self._imgQuestionArea:getPosition())
	self._nDisQuestionAreaMoveX = 2000

	self._nDisTalkMove = 190

	--记录标识位置
	self._posEnemyAnswerToken = cc.p(self._imgEnemyAnswerToken:getPosition())
	self._posPlyrAnswerToken = cc.p(self._imgPlyrAnswerToken:getPosition())

	return true

end

function LaBattle:initAnim()
	--透明上部UI
	self._layCenterUI:setOpacity(0)

	--卡牌，合适的位置和大小
	self._arimgPlyrCard[1]:setPosition(self._posPlyrCardFrom)
	self._arimgPlyrCard[1]:setScale(CONST.CARD_SCALE_FROM)
	self._imgEnemyCard:setPosition(self._posEnemyCardFrom)
	self._imgEnemyCard:setScale(CONST.CARD_SCALE_FROM)
	
	--隐藏技能
	for i = 1, 3 do
		self._arbtnPlyrSkill[i]:setOpacity(0)
		self._arbtnEnemySkill[i]:setOpacity(0)
	end
	
	--隐藏答题标识
	self._imgPlyrAnswerToken:setVisible(false)
	self._imgEnemyAnswerToken:setVisible(false)
	
	--各个区域的位置
	self._imgCardChangeArea:setVisible(true)
	self._imgCardChangeArea:setPositionY(
		self._imgCardChangeArea:getPositionY() - self._nDisAreaMoveY)

	self._imgTip:setVisible(true)
	self._imgTip:setPositionY(
		self._imgTip:getPositionY() - self._nDisAreaMoveY)
	
	self._imgQuestionArea:setVisible(true)
	self._imgQuestionArea:setPositionX(
		self._posQuestionArea.x + self._nDisQuestionAreaMoveX)

	--隐藏屏蔽层
	self._layShield:setVisible(false)

	--退出按钮
	self._btnGiveUp:setVisible(false)

	--对话的位置安放好
	self._imgPlyrTalk:setVisible(true)
	self._imgEnemyTalk:setVisible(true)
	self._imgPlyrTalk:setPositionY(self._imgPlyrTalk:getPositionY() - self._nDisTalkMove)
	self._imgEnemyTalk:setPositionY(self._imgEnemyTalk:getPositionY() - self._nDisTalkMove)

	--卡牌展示第一张
	self._nCurCardIndex = 1
	self._arckbCard[1]:setSelectedState(true)
	self._arckbCard[1]:setTouchEnabled(false)

	return true
end

function LaBattle:initData(data)
	
	--HP补满
	self._nPlyrHPCeiling = 100
	self._nEnemyHPCeiling = 100
	self._nPlyrCurrentHP = 100
	self._nEnemyCurrentHP = 100

	self._barPlyrHP:setPercent(100)
	self._barEnemyHP:setPercent(100)

	--设置回合数并展示
	self._nRoundsNumber = 2
	self._atlasRounds:setString(tostring(self._nRoundsNumber))

	return true
end

------------------------------------------------------
--【私有函数】，打印当前状态
local function printState(str)
	lly.log(str)
	
	--[[
	local socket = require("socket")
	socket.select(nil, nil, 1)
	--]]
end


-------------------------------------------------------
function LaBattle:setWidget(filename)
	local widget = uikits.child(self._wiRoot, filename)
	if not widget then
		lly.error("wrong widget filename", 3)
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
	--lly.log(os.time())

	--显示倒计时的数字
	if self._stateNext == state.askByEnemy then
		self._txtCountdownInCardChange:setString(tostring(self._nSecondLeft))
	elseif self._stateNext == state.attackByEnemy or
		self._stateNext == state.attackByPlayer then
		self._txtCountdown:setString(tostring(self._nSecondLeft))
	end
end

--计时结束的回调
function LaBattle:onTimeEnd()
	if self._stateNext == state.askByEnemy then
		self:endPrepare()
	elseif self._stateNext == state.attackByEnemy then
		self:endPlayerAnswer()
	elseif self._stateNext == state.attackByPlayer then
		self:endEnemyAnswer()
	end

end

--使用道具
function LaBattle:useItem()
	printState("use item")

	--禁止进入下个状态
	self._bForbidEnterNextState = true

	--进行动画（完成是检查请求是否完成，完成则取消禁止）

	--请求服务器（完成是检查动画是否完成，完成则取消禁止）

end

--检测血量，如果一方血量小于等于0，则下个状态为输赢状态
function LaBattle:checkHP()
	lly.log("check: player HP %d (%d), enemy HP %d (%d)", 
			self._nPlyrCurrentHP, self._barPlyrHP:getPercent(),
			self._nEnemyCurrentHP, self._barEnemyHP:getPercent())
end

---------------------------------------------------------
function LaBattle:downloadEnemyQuestions()
	self._bNextStateDataHasLoad = true
end

function LaBattle:checkPlayerAnswerAndDownloadPlayerQusetion()
	self._bNextStateDataHasLoad = true
end


----------------------------------------------------------
function LaBattle:onClickChangeCard(sender, eventType)
	lly.log("click change card %d", sender:getTag())

	if self._bBuzyToChangeCard then return end
	self._bBuzyToChangeCard = true

	--让自己不能点击，其他的复选框可以点击
	for i = 1, 3 do
		if self._arckbCard[i] == sender then
			sender:setTouchEnabled(false)
		else
			self._arckbCard[i]:setTouchEnabled(true)
			self._arckbCard[i]:setSelectedState(false)
		end
	end
	
	---[[
	self._bBuzyToChangeCard = false
	do return end
	--]]

	--得到下一张显示的卡牌，用按钮的tag值记录
	local nextCardIndex = sender:getTag()

	--不能是当前卡牌
	if nextCardIndex == self._nCurCardIndex then return end

	--下一张卡牌放好位置和缩放
	self._arimgPlyrCard[nextCardIndex]:setPosition(self._posPlyrCardFrom)
	self._arimgPlyrCard[nextCardIndex]:setScale(CONST.CARD_SCALE_FROM)

	--动画移动
	local acMovePC = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posPlyrCard)
	local acSaclePC = cc.ScaleTo:create(CONST.CARD_MOVE_TIME, 1.0)

	local acMovePCTo = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posPlyrCardTo)

	local callFunc = cc.CallFunc:create(function ()
		self._bBuzyToChangeCard = false
		self._nCurCardIndex = nextCardIndex
	end)

	self._arimgPlyrCard[self._nCurCardIndex]:runAction(acMovePCTo)
	self._arimgPlyrCard[nextCardIndex]:runAction(cc.Sequence:create(
		cc.Spawn:create(acMovePC, acSaclePC), callFunc))
end

function LaBattle:onClickShortChoose(sender, eventType)
	
	
end

function LaBattle:onClickLongChoose(sender, eventType)
	
	
end

function LaBattle:onClickYesOrNo(sender, eventType)
	
	
end

----------------------------------------------------------
--开场动画状态
function LaBattle:playEnterAnim_S()
	printState("play Enter Anim")

	--设置下个状态
	self._stateNext = state.prepare
	self._bCurStateIsEnding = false

	--执行动画，完成后ending为true
	--淡入
	local acUIFadeIn = cc.FadeIn:create(0.2)

	--移入卡牌，并缩放到合适的原大小
	local acMovePC = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posPlyrCard)
	local acMoveEC = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posEnemyCard)
	local acSaclePC = cc.ScaleTo:create(CONST.CARD_MOVE_TIME, 1.0)
	local acSacleEC = cc.ScaleTo:create(CONST.CARD_MOVE_TIME, 1.0)

	--显示技能
	local acSkFadeIn = cc.FadeIn:create(0.2)

	--结束，同时开启退出按钮
	local callFunc = cc.CallFunc:create(function ()
		self._btnGiveUp:setVisible(true)
		self._bCurStateIsEnding = true
	end)

	self._layCenterUI:runAction(acUIFadeIn:clone())
	self:runAction(cc.Sequence:create(
		cc.Spawn:create(
			cc.TargetedAction:create(self._arimgPlyrCard[1], cc.Spawn:create(acMovePC, acSaclePC)),
			cc.TargetedAction:create(self._imgEnemyCard, cc.Spawn:create(acMoveEC, acSacleEC))),
		cc.Spawn:create(
			cc.TargetedAction:create(self._arbtnPlyrSkill[1], acSkFadeIn),
			cc.TargetedAction:create(self._arbtnEnemySkill[1], acSkFadeIn:clone())),
		cc.Spawn:create(
			cc.TargetedAction:create(self._arbtnPlyrSkill[2], acSkFadeIn:clone()),
			cc.TargetedAction:create(self._arbtnEnemySkill[2], acSkFadeIn:clone())),
		cc.Spawn:create(
			cc.TargetedAction:create(self._arbtnPlyrSkill[3], acSkFadeIn:clone()),
			cc.TargetedAction:create(self._arbtnEnemySkill[3], acSkFadeIn:clone())),
		callFunc))
end

--玩家准备出题，选择人物，选择技能
function LaBattle:prepare_S()
	printState("prepare")

	--设置下个状态
	self._stateNext = state.askByEnemy
	self._bCurStateIsEnding = false
	self._bNextStateDataHasLoad = false

	--展示选择页面后开始倒计时
	local acMoveCC = cc.MoveBy:create(CONST.CD_CHNG_MOVE_TIME, 
		cc.p(0, self._nDisAreaMoveY))
	
	self._txtCountdownInCardChange:setString(tostring(CONST.CHANGE_CARD_TIME))

	local callfuncCountingdown = cc.CallFunc:create(function ()
		self:beginCountingdown(CONST.CHANGE_CARD_TIME)
	end)

	self._imgCardChangeArea:runAction(cc.Sequence:create(
		cc.EaseExponentialOut:create(acMoveCC), callfuncCountingdown)) 

	--同时下载敌方的题
	self:downloadEnemyQuestions()
end

--结束准备
function LaBattle:endPrepare()
	--防止重复点击
	if self._bBuzyToEndingState then return end
	self._bBuzyToEndingState = true

	--结束计时
	self:stopCountingdown()

	--收起
	local acMoveCC = cc.MoveBy:create(CONST.CD_CHNG_MOVE_TIME, 
		cc.p(0, -self._nDisAreaMoveY))

	local callfuncNextState = cc.CallFunc:create(function ()
		self._bBuzyToEndingState = false
		self._bCurStateIsEnding = true
	end)

	self._imgCardChangeArea:runAction(cc.Sequence:create(
		cc.EaseSineIn:create(acMoveCC), callfuncNextState)) 
end

--敌方出题
function LaBattle:askByEnemy_S()
	printState("ask by enemy")

	--设置下个状态
	self._stateNext = state.waitingForPlayerAnswer
	self._bCurStateIsEnding = false

	--防止错误操作
	self._btnQuestionCommit:setTouchEnabled(false)

	--初始化
	self._imgQuestionArea:setPositionX(
		self._posQuestionArea.x + self._nDisQuestionAreaMoveX)
	self._txtCountdown:setString(tostring(CONST.ANSWER_TIME))

	--展示敌方对话
	local acMoveTalkFrom = cc.MoveBy:create(CONST.TALK_MOVE_TIME, cc.p(0, self._nDisTalkMove))

	local delay = cc.DelayTime:create(CONST.TALK_DELAY_TIME)

	--收起敌方对话
	local acMoveTalkTo = cc.MoveBy:create(CONST.TALK_MOVE_TIME,  cc.p(0, self._nDisTalkMove))

	--从右边（敌人方向）飞出答题板后
	local acMoveQuseAreaFrom = cc.MoveBy:create(CONST.QUES_MOVE_TIME, cc.p(-self._nDisQuestionAreaMoveX, 0))

	--结束，完成后ending为true
	local callfunc = cc.CallFunc:create(function ()
		self._imgEnemyTalk:setPositionY(self._imgEnemyTalk:getPositionY() - 2 * self._nDisTalkMove)
		self._btnQuestionCommit:setTouchEnabled(true)
		self._bCurStateIsEnding = true
	end)

	self._imgEnemyTalk:runAction(cc.Sequence:create(
		acMoveTalkFrom,
		delay,
		acMoveTalkTo, 
		cc.TargetedAction:create(self._imgQuestionArea, 
			cc.EaseExponentialOut:create(acMoveQuseAreaFrom)),
		callfunc))

end

--等待玩家答题
--玩家可以使用道具，进入道具动画状态，进入时禁止点击提交
--等待玩家提交答案，或者倒计时结束
function LaBattle:waitingForPlayerAnswer_S()
	printState("waiting for player answer")

	--设置下个状态
	self._stateNext = state.attackByEnemy
	self._bCurStateIsEnding = false

	--开启玩家答题状态标识
	self._imgPlyrAnswerToken:setPosition(self._posPlyrAnswerToken)
	self._imgPlyrAnswerToken:setVisible(true)

	--标识晃动
	local move = cc.MoveBy:create(1, cc.p(0, 10))
	self._imgPlyrAnswerToken:runAction(cc.RepeatForever:create(
		cc.Sequence:create(move, move:reverse())))

	--开始倒计时
	self:beginCountingdown(CONST.ANSWER_TIME)

end

function LaBattle:endPlayerAnswer()
	lly.logCurLocAnd("end plyr anser")

	--所有按钮不可点击


	--防止重复点击
	if self._bBuzyToEndingState then return end
	self._bBuzyToEndingState = true

	--结束计时
	self:stopCountingdown()

	do return end

	--隐藏标识并结束动画
	self._imgPlyrAnswerToken:setVisible(false)
	self._imgPlyrAnswerToken:stopAllActions()

	--变成半透明
	local acFadeOut = cc.FadeTo:create(
		CONST.QUES_FADE_TIME, CONST.QUES_FADE)

	local callfuncNextState = cc.CallFunc:create(function ()
		self._bBuzyToEndingState = false
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		acFadeOut, callfuncNextState))

	--颜色变暗
	self._imgQuestionArea:setColor(
		cc.c3b(CONST.QUES_COLOR, CONST.QUES_COLOR, CONST.QUES_COLOR))

	--打开屏蔽层
	self._layShield:setVisible(true)
end

--敌人进攻
function LaBattle:attackByEnemy_S()
	printState("attack by Enemy")

	--设置下个状态
	self._stateNext = state.showResultOfPlayerAtk
	self._bCurStateIsEnding = false
	self._bNextStateDataHasLoad = false

	--答题动画
	self._bCurStateIsEnding = true

	--进行一部分动画，同时提交服务器答案等待验证，同时申请玩家出的题目
	self:checkPlayerAnswerAndDownloadPlayerQusetion()

end

--玩家进攻结果
function LaBattle:showResultOfPlayerAtk_S()
	printState("show Result Of Player Atk")

	--设置下个状态
	--查看是否还有剩余体力，没有的话直接进入下一次敌人进攻
	self._stateNext = state.endShowPlyrResult
	self._bCurStateIsEnding = false

	--根据结果展示谁减少HP，然后进入血量检测
	self:checkHP()
	self._bCurStateIsEnding = true

end

function LaBattle:endShowPlyrResult_S()
	printState("show Result Of Player Atk")

	self._stateNext = state.askByPlayer
	self._bCurStateIsEnding = false

	--收起 *2是为了移走的速度更舒服
	local acMoveCC = cc.MoveBy:create(
		CONST.QUES_MOVE_TIME, cc.p(self._nDisQuestionAreaMoveX * 2, 0))

	local callfuncNextState = cc.CallFunc:create(function ()
		self._imgQuestionArea:setOpacity(255) --恢复不透明
		self._imgQuestionArea:setColor(cc.c3b(255, 255, 255)) --恢复颜色
		self._layShield:setVisible(false) --关闭屏蔽层
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		cc.EaseSineIn:create(acMoveCC), callfuncNextState)) 

end

--玩家出题
function LaBattle:askByPlayer_S()
	printState("ask by player")

	--设置下个状态
	self._stateNext = state.waitingForEnemyAnswer
	self._bCurStateIsEnding = false

	--防止错误操作
	self._btnQuestionCommit:setTouchEnabled(false)

	--初始化
	self._imgQuestionArea:setPositionX(
		self._posQuestionArea.x - self._nDisQuestionAreaMoveX)
	self._txtCountdown:setString(tostring(CONST.ANSWER_TIME))

	--展示玩家对话
	local acMoveTalkFrom = cc.MoveBy:create(CONST.TALK_MOVE_TIME, cc.p(0, self._nDisTalkMove))

	local delay = cc.DelayTime:create(CONST.TALK_DELAY_TIME)

	--收起玩家对话
	local acMoveTalkTo = cc.MoveBy:create(CONST.TALK_MOVE_TIME,  cc.p(0, self._nDisTalkMove))

	--从左边（玩家方向）飞出答题板后
	local acMoveQuseAreaFrom = cc.MoveBy:create(CONST.QUES_MOVE_TIME, cc.p(self._nDisQuestionAreaMoveX, 0))

	--结束，完成后ending为true
	local callfunc = cc.CallFunc:create(function ()
		self._imgPlyrTalk:setPositionY(self._imgPlyrTalk:getPositionY() - 2 * self._nDisTalkMove)
		self._btnQuestionCommit:setTouchEnabled(true)
		self._bCurStateIsEnding = true
	end)

	self._imgPlyrTalk:runAction(cc.Sequence:create(
		acMoveTalkFrom,
		delay,
		acMoveTalkTo, 
		cc.TargetedAction:create(self._imgQuestionArea, 
			cc.EaseExponentialOut:create(acMoveQuseAreaFrom)),
		callfunc))

end

--等待敌人答题
function LaBattle:waitingForEnemyAnswer_S()
	printState("waiting for enemy answer")

	--设置下个状态
	self._stateNext = state.attackByPlayer
	self._bCurStateIsEnding = false

	--开启敌人答题状态标识
	self._imgEnemyAnswerToken:setPosition(self._posEnemyAnswerToken)
	self._imgEnemyAnswerToken:setVisible(true)

	--标识晃动
	local move = cc.MoveBy:create(1, cc.p(0, 10))
	self._imgEnemyAnswerToken:runAction(cc.RepeatForever:create(
		cc.Sequence:create(move, move:reverse())))

	--开始倒计时
	self:beginCountingdown(CONST.ANSWER_TIME)

	--根据服务器反馈的时间，时间到达后进入下个状态

end

function LaBattle:endEnemyAnswer()
	lly.logCurLocAnd("end enemy anser")

	--防止重复点击
	if self._bBuzyToEndingState then return end
	self._bBuzyToEndingState = true

	--结束计时
	self:stopCountingdown()

	--隐藏标识并结束动画
	self._imgEnemyAnswerToken:setVisible(false)
	self._imgEnemyAnswerToken:stopAllActions()

	--变成半透明
	local acFadeOut = cc.FadeTo:create(
		CONST.QUES_FADE_TIME, CONST.QUES_FADE)

	local callfuncNextState = cc.CallFunc:create(function ()
		self._bBuzyToEndingState = false
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		acFadeOut, callfuncNextState))

	--颜色变暗
	self._imgQuestionArea:setColor(
		cc.c3b(CONST.QUES_COLOR, CONST.QUES_COLOR, CONST.QUES_COLOR))

	--打开屏蔽层
	self._layShield:setVisible(true)
end

--玩家进攻
function LaBattle:attackByPlayer_S()
	printState("attack by player")

	--设置下个状态
	self._stateNext = state.showResultOfEnemyAtk
	self._bCurStateIsEnding = false
	--self._bNextStateDataHasLoad = false --敌人的答题结果已经加载

	--答题动画
	self._bCurStateIsEnding = true

end

--敌人进攻结果
function LaBattle:showResultOfEnemyAtk_S()
	printState("show Result Of Enemy Atk")

	--设置下个状态
	self._stateNext = state.checkRoundsNumber
	self._bCurStateIsEnding = false

	--根据结果展示谁减少HP，然后进入血量检测
	self:checkHP()
	self._bCurStateIsEnding = true

end

--回合数检测，在敌人进攻结果状态后检测
--计算回合数，如果回合数为1则进入结束判断，否则显示当前回合数后减少1
function LaBattle:checkRoundsNumber_S()
	printState("check Rounds Number")

	if self._nRoundsNumber <= 1 then
		--判断血量，玩家大算赢，小或者平算输
		--血量按照比例判断
		lly.log("player HP %d (%d), enemy HP %d (%d)", 
			self._nPlyrCurrentHP, self._barPlyrHP:getPercent(),
			self._nEnemyCurrentHP, self._barEnemyHP:getPercent())

		if self._barPlyrHP:getPercent() > self._barEnemyHP:getPercent() then
			self._stateNext = state.win
		else
			self._stateNext = state.lose
		end

	else
		self._nRoundsNumber = self._nRoundsNumber - 1
		self._atlasRounds:setString(tostring(self._nRoundsNumber))
		self._stateNext = state.endShowEnemyResult
	end
end

--结束动画
function LaBattle:endShowEnemyResult_S()
	printState("show Result Of Player Atk")

	self._stateNext = state.prepare
	self._bCurStateIsEnding = false

	--收起 *2是为了移走的速度更舒服
	local acMoveCC = cc.MoveBy:create(
		CONST.QUES_MOVE_TIME, cc.p(self._nDisQuestionAreaMoveX * -2, 0))

	local callfuncNextState = cc.CallFunc:create(function ()
		self._imgQuestionArea:setOpacity(255)
		self._imgQuestionArea:setColor(cc.c3b(255, 255, 255)) --恢复颜色
		self._layShield:setVisible(false) --关闭屏蔽层
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		cc.EaseSineIn:create(acMoveCC), callfuncNextState)) 
end

--胜利
function LaBattle:win_S()
	printState("win")
	self._bCurStateIsEnding = false

	--启动胜利页面
	self._laResult:setVisible(true)
	self._laResult:win()

end

--失败
function LaBattle:lose_S()
	printState("lose")
	self._bCurStateIsEnding = false

	--启动失败页面
	self._laResult:setVisible(true)
	self._laResult:lose()

end


state = lly.const{
	playEnterAnim = LaBattle.playEnterAnim_S,
	prepare = LaBattle.prepare_S,
	askByEnemy = LaBattle.askByEnemy_S,
	waitingForPlayerAnswer = LaBattle.waitingForPlayerAnswer_S,
	attackByEnemy = LaBattle.attackByEnemy_S,
	showResultOfPlayerAtk = LaBattle.showResultOfPlayerAtk_S,
	endShowPlyrResult = LaBattle.endShowPlyrResult_S,
	askByPlayer = LaBattle.askByPlayer_S,
	waitingForEnemyAnswer = LaBattle.waitingForEnemyAnswer_S,
	attackByPlayer = LaBattle.attackByPlayer_S,
	showResultOfEnemyAtk = LaBattle.showResultOfEnemyAtk_S,
	endShowEnemyResult = LaBattle.endShowEnemyResult_S,
	checkRoundsNumber = LaBattle.checkRoundsNumber_S,
	win = LaBattle.win_S,
	lose = LaBattle.lose_S,
}

return {
	Class = LaBattle,
}

