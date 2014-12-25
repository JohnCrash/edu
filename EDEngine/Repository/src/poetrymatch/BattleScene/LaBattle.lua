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
local moperson_info = require "poetrymatch/person_info"

--战斗类型
local BATTLE_TYPE = {
	STORY = 1, --故事模式（闯关）
	FIGHT = 2, --对战模式
	CHALLENGE = 3, --挑战模式（擂台）
}

--阵营类型
local CAMP_TYPE = {
	PLAYER = 1,
	ENEMY = 2,
	MAX = 3,
}

--题的类型
local QUES_TYPE = {
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
	IMG_BG = "beij",

	LAY_BATTLE = "zhandou",

	LAY_CENTER_UI = "zhandou/centerUI",

	TXT_PLYR_NAME = "zhandou/centerUI/womz",
	IMG_PLYR_PORTRAIT = "zhandou/wo",
	TXT_PLYR_LEVEL = "zhandou/wo/dj",
	BAR_PLYR_HP = "zhandou/centerUI/xuet/jd",

	TXT_ENEMY_NAME = "zhandou/centerUI/duifmz",
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

	--费血
	LAY_DEC_HP = "diaoxie",
	ATLAS_DEC_HP = "diaoxie/zhi",

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
	CKB_RIGHT = "tiqu/panduan/dui",
	CKB_WRONG = "tiqu/panduan/cuo",

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
	LAY_TALK = "talk",
	IMG_PLYR_TALK = "talk/wos",
	IMG_ENEMY_TALK = "talk/dfs",
	IMG_PLYR_TALK_AFTER = "talk/wos2",
	IMG_ENEMY_TALK_AFTER = "talk/dfs2",

	--粒子层
	LAY_PARTICLE = "bjdh1",

	--攻击动画
	ANIM_ATK_PNG1 = "poetrymatch/BattleScene/anim_atk/gongji0.png",
	ANIM_ATK_PLIST1 = "poetrymatch/BattleScene/anim_atk/gongji0.plist",
	ANIM_ATK_PNG2 = "poetrymatch/BattleScene/anim_atk/gongji1.png",
	ANIM_ATK_PLIST2 = "poetrymatch/BattleScene/anim_atk/gongji1.plist",
	ANIM_ATK_PNG3 = "poetrymatch/BattleScene/anim_atk/gongji2.png",
	ANIM_ATK_PLIST3 = "poetrymatch/BattleScene/anim_atk/gongji2.plist",
	ANIM_ATK_PNG4 = "poetrymatch/BattleScene/anim_atk/gongji3.png",
	ANIM_ATK_PLIST4 = "poetrymatch/BattleScene/anim_atk/gongji3.plist",
	ANIM_ATK_PNG5 = "poetrymatch/BattleScene/anim_atk/gongji4.png",
	ANIM_ATK_PLIST5 = "poetrymatch/BattleScene/anim_atk/gongji4.plist",

	ANIM_ATK_JSON = "poetrymatch/BattleScene/anim_atk/gongji.ExportJson",

	--判断对错动画
	ANIM_JUDGE_PNG1 = "poetrymatch/BattleScene/anim_judge/success0.png",
	ANIM_JUDGE_PLIST1 = "poetrymatch/BattleScene/anim_judge/success0.plist",
	ANIM_JUDGE_PNG2 = "poetrymatch/BattleScene/anim_judge/success1.png",
	ANIM_JUDGE_PLIST2 = "poetrymatch/BattleScene/anim_judge/success1.plist",
	ANIM_JUDGE_PNG3 = "poetrymatch/BattleScene/anim_judge/success2.png",
	ANIM_JUDGE_PLIST3 = "poetrymatch/BattleScene/anim_judge/success2.plist",

	ANIM_JUDGE_JSON = "poetrymatch/BattleScene/anim_judge/success.ExportJson",
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
	CHANGE_CARD_TIME = 18,
	ANSWER_TIME = 10,

	--粒子效果
	PARTICLE_WIND = "poetrymatch/BattleScene/Particles/hua.plist",
	PARTICLE_SNOW = "poetrymatch/BattleScene/Particles/xue.plist",

	--
	FIGHT_ANIM_RATE = 2.5,

	--zorder
	Z_UI = 0,
	Z_RESULT = 100,
	Z_CARD_NORMAL = 10, --普通状态下牌的zorder
	Z_CARD_COME = 11, --飞来是牌的zorder

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
		_imgBG = Lnull, --背景

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

		--技能，三张卡牌分别有三个技能
		_ararbtnPlyrSkill = lly.array(3, lly.array(3)), --三项

		--敌方卡牌
		_imgEnemyCard = Lnull,
		_txtEnemyCardLevel = Lnull,
		_imgEnemyAnswerToken = Lnull,
		_arbtnEnemySkill = lly.array(3), --三项

		--认输按钮
		_btnGiveUp = Lnull,

		--费血标识
		_layDecHP = Lnull,
		_atlasDecHP = Lnull,

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
		_ckbRight = Lnull,
		_ckbWrong = Lnull,

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
		_layTalk = Lnull,
		_imgPlyrTalk = Lnull,
		_imgEnemyTalk = Lnull,
		_imgPlyrTalkAfter = Lnull,
		_imgEnemyTalkAfter = Lnull,

		_laResult = Lnull, --三种不同的战斗给予不同的结果画面

		--离子--------------------------------------------------
		_layParticle = Lnull, --粒子效果所在层
		_particle = Lnull,

		--动画----------------------------------------------------
		_anim = Lnull,
		_animJudge = Lnull,

		--位置--------------------------------------------------
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

		_posPlyrDecreaseHP = Lnull,
		_posEnemyDecreaseHP = Lnull,
		_nDisDecHPMoveY = 0,

		--状态-------------------------------------------------
		_stateCurrent = Lnull,
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

		--是否还有体力
		_bHasVIT = true,

		--倒计时-----------------------------------------------
		_nSecondLeft = 0, --剩余时间

		_fLastTime = 0, --上次时间
		_fCurrentTime = 0, --当前时间，用来和上次时间计算一秒钟时间

		--各种属性-----------------------------------------------
		_nCurBattleType = BATTLE_TYPE.STORY, --战斗类型
		_nCurStageID = 0, --关卡/擂台id

		_nRoundsNumber = 0, --回合数

		--人物属性
		_nPlyrHPCeiling = 0, --玩家HP上限
		_nPlyrCurrentHP = 0, --玩家当前HP
		
		_arnPlyrCardID = lly.array(3, 0), --卡牌

		_arnPlyrCardVIT = lly.array(3), --体力
		_arnPlyrCardVITMax = lly.array(3),

		--技能
		_ararnPlyrSkillID = lly.array(3, lly.array(3)),

		--敌人属性
		_nEnemyHPCeiling = 0, --敌人HP上限
		_nEnemyCurrentHP = 0, --敌人当前HP

		_nEnemyCardID = 0, --卡牌
		_arnEnemySkillID = 0, --技能

		--当前-------------------------------------------------------
		_nCurCardIndex = 1, --当前卡牌
		_nCurQuesType = QUES_TYPE.SINGLE_CHOICE, --当前题类型
		_nCurQuesID = 0,

		--当前问题
		_strQuesTitle = "",
		_strQuesContent = "",
		_arstrQuesChoose = lly.array(4),

		--选择题答案
		_arbChoise = lly.array(4),
		_strAnswer = "", --填空题答案

		--电脑的答题时间
		_nCOMAnswerSpendTime = 3,

		_bComputerBeginThink = false, --电脑开始思考
		_nThkBgnTime = 0, --开始思考的时间
		
	}
end

--私有函数
local private = {}

--------------------------------------------------------
--传入一个初始化数据
function LaBattle:init(tab)
	repeat
		--初始化数据
		if not self:initData() then break end

		--UI
		if not self:initUI() then break end
		if not self:initUIWithData() then break end
		
		--初始化基本位置
		if not self:initPosition() then break end
		
		--初始化动画
		if not self:initAnim() then break end
		
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

			--电脑思考
			self:excuteComputerThinking()

		end, 0)

		--self._nSecondLeft = 10
		self._stateNext = state.playEnterAnim

		return true
	until true

	return false
end

--需要战斗类型，关卡id, 回合数，最大血量，卡牌体力最大数，卡牌id，技能id
function LaBattle:initData(data)
	
	self._nCurBattleType = BATTLE_TYPE.STORY

	--设置回合数并展示
	self._nRoundsNumber = 5

	--设置各种读秒数

	--HP补满
	self._nPlyrHPCeiling = 100
	self._nEnemyHPCeiling = 50
	self._nPlyrCurrentHP = self._nPlyrHPCeiling
	self._nEnemyCurrentHP = self._nEnemyHPCeiling

	--体力
	for i = 1, 3 do
		self._arnPlyrCardVIT[i] = 1
		self._arnPlyrCardVITMax[i] = 6
	end

	--技能

	return true
end

function LaBattle:initUI()
	repeat
		self._wiRoot = uikits.fromJson{file_9_16 = ui.FILE, file_3_4 = ui.FILE_3_4}

		if not self._wiRoot then break end
		self:addChild(self._wiRoot, CONST.Z_UI)

		--背景
		self._imgBG = self:setWidget(ui.IMG_BG)

		--最上血条部分
		self._layCenterUI = self:setWidget(ui.LAY_CENTER_UI)

		self._txtPlyrName = self:setWidget(ui.TXT_PLYR_NAME)
		self._txtPlyrLevel = self:setWidget(ui.TXT_PLYR_LEVEL)
		self._barPlyrHP = self:setWidget(ui.BAR_PLYR_HP)

		self._txtEnemyName = self:setWidget(ui.TXT_ENEMY_NAME)
		self._txtEnemyLevel = self:setWidget(ui.TXT_ENEMY_LEVEL)
		self._barEnemyHP = self:setWidget(ui.BAR_ENEMY_HP)

		--上中回合数
		self._atlasRounds = self:setWidget(ui.ATLAS_ROUNDS)

		--头像
		self._imgPlyrPortrait = self:setWidget(ui.IMG_PLYR_PORTRAIT)
		self._imgEnemyPortrait = self:setWidget(ui.IMG_ENEMY_PORTRAIT)

		--玩家
		self._arimgPlyrCard[1] = self:setWidget(ui.IMG_PLYR_CARD)

		self._artxtPlyrCardLevel[1] = self:setWidget(ui.TXT_PLYR_CARD_LEVEL)
		
		self._ararbtnPlyrSkill[1][1] = self:setWidget(ui.BTN_PLYR_SKILL_1)
		self._ararbtnPlyrSkill[1][2] = self:setWidget(ui.BTN_PLYR_SKILL_2)
		self._ararbtnPlyrSkill[1][3] = self:setWidget(ui.BTN_PLYR_SKILL_3)

		for i = 1, 3 do
			uikits.event(self._ararbtnPlyrSkill[1][i], function (sender)
				self:onClickSkill(CAMP_TYPE.PLAYER, i)
			end)
		end
		
		--敌人
		self._imgEnemyCard = self:setWidget(ui.IMG_ENEMY_CARD)
		self._txtEnemyCardLevel = self:setWidget(ui.TXT_ENEMY_CARD_LEVEL)

		self._arbtnEnemySkill[1] = self:setWidget(ui.BTN_ENEMY_SKILL_1)
		self._arbtnEnemySkill[2] = self:setWidget(ui.BTN_ENEMY_SKILL_2)
		self._arbtnEnemySkill[3] = self:setWidget(ui.BTN_ENEMY_SKILL_3)

		for i = 1, 3 do
			uikits.event(self._arbtnEnemySkill[i], function (sender)
				self:onClickSkill(CAMP_TYPE.ENEMY, i)
			end)
		end

		--玩家卡牌
		self._imgPlyrAnswerToken = self:setWidget(ui.IMG_PLYR_ANSWER_TOKEN)

		--敌方卡牌
		self._imgEnemyAnswerToken = self:setWidget(ui.IMG_ENEMY_ANSWER_TOKEN)
		
		--认输按钮
		self._btnGiveUp = self:setWidget(ui.BTN_GIVEUP)
		uikits.event(self._btnGiveUp, function (sender)
			self:onClickGiveUp()
		end)

		--费血标识
		self._layDecHP = self:setWidget(ui.LAY_DEC_HP)
		self._atlasDecHP = self:setWidget(ui.ATLAS_DEC_HP)

		--答题区域
		self._imgQuestionArea = self:setWidget(ui.IMG_QUESTION_AREA)
		self._txtCountdown = self:setWidget(ui.TXT_COUNT_DOWN)
		self._txtQuestionTitle = self:setWidget(ui.TXT_QUESTION_TITLE)
		self._txtQuestionContent = self:setWidget(ui.TXT_QUESTION_CONTENT)
		self._btnQuestionCommit = self:setWidget(ui.BTN_QUESTION_COMMIT)

		uikits.event(self._btnQuestionCommit, function (sender)
			if self._stateCurrent == state.waitingForPlayerAnswer then
				self:endPlayerAnswer()
			elseif self._stateCurrent == state.waitingForEnemyAnswer then
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
		self._ckbRight = self:setWidget(ui.CKB_RIGHT)
		self._ckbWrong = self:setWidget(ui.CKB_WRONG)

		--uikits.event的回调
		local function onClickYesOrNo(sender, eventType)
			self:onClickYesOrNo(sender, eventType)			
		end

		uikits.event(self._ckbRight, onClickYesOrNo)
		uikits.event(self._ckbWrong, onClickYesOrNo)

		--填空
		self._layFillInBlank = self:setWidget(ui.LAY_FILL_IN_BLANK)
		self._iptFillInBlank = self:setWidget(ui.IPT_FILL_IN_BLANK)

		self._layShield = self:setWidget(ui.LAY_SHIELD)

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

		uikits.event(self._btnConfirm, function () 
			self:endPrepareWhenNoVIT()
		end)

		--对话
		self._layTalk = self:setWidget(ui.LAY_TALK)
		self._imgPlyrTalk = self:setWidget(ui.IMG_PLYR_TALK)
		self._imgEnemyTalk = self:setWidget(ui.IMG_ENEMY_TALK)

		self._imgPlyrTalkAfter = self:setWidget(ui.IMG_PLYR_TALK_AFTER)
		self._imgEnemyTalkAfter = self:setWidget(ui.IMG_ENEMY_TALK_AFTER)

		--离子效果 随机加载两种不同的效果
		self._layParticle = self:setWidget(ui.LAY_PARTICLE)

		math.randomseed(os.time())
		if math.random(2) == 2 then
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

		return true
	until true

	return false
end

--需要头像，名称，等级，卡牌图片，卡牌等级，技能图片
function LaBattle:initUIWithData()
	repeat
		--血量和回合数
		self._barPlyrHP:setPercent(100 * self._nPlyrCurrentHP / self._nPlyrHPCeiling)
		self._barEnemyHP:setPercent(100 * self._nEnemyCurrentHP / self._nEnemyHPCeiling)

		self._atlasRounds:setString(tostring(self._nRoundsNumber))

		--头像

		--新建另两张卡牌，由第一张复制
		local layBattle = self:setWidget(ui.LAY_BATTLE)

		for i = 2, 3 do
			self._arimgPlyrCard[i] = self._arimgPlyrCard[1]:clone()
			self._arimgPlyrCard[i]:setPosition(cc.p(-1000, -1000))
			layBattle:addChild(self._arimgPlyrCard[i])
		end

		--卡牌的等级和图片
		
		--新建另两张卡牌的技能，由第一张复制，并先隐藏
		for i = 1, 3 do
			self._ararbtnPlyrSkill[2][i] = self._ararbtnPlyrSkill[1][i]:clone()
			layBattle:addChild(self._ararbtnPlyrSkill[2][i])
			self._ararbtnPlyrSkill[2][i]:setVisible(false)

			self._ararbtnPlyrSkill[3][i] = self._ararbtnPlyrSkill[1][i]:clone()
			layBattle:addChild(self._ararbtnPlyrSkill[3][i])
			self._ararbtnPlyrSkill[3][i]:setVisible(false)
		end

		--玩家技能

		--敌人卡牌和其等级

		--敌人技能

		--背景 根据战斗类型和关卡不同而不同
		local strBGName = "poetrymatch/BattleScene/BG/"
		if self._nCurBattleType == BATTLE_TYPE.STORY then
			--根据关卡获得背景图片名称
			strBGName = strBGName .. "duiz1.jpg"
		elseif self._nCurBattleType == BATTLE_TYPE.FIGHT then
			strBGName = strBGName .. "duiz1.jpg"
		elseif self._nCurBattleType == BATTLE_TYPE.CHALLENGE then
			strBGName = strBGName .. "leitzhandou.jpg"
		else
			lly.error("wrong BATTLE_TYPE")
		end

		self._imgBG:loadTexture(strBGName)

		--结束图层初始化 根据战斗类型不同而不同
		if self._nCurBattleType == BATTLE_TYPE.STORY then
			local moLaBattleResultStory = require "poetrymatch/BattleScene/LaBattleResultStory"
			self._laResult = moLaBattleResultStory.Class:create()

		elseif self._nCurBattleType == BATTLE_TYPE.FIGHT then
			local moLaBattleResultFight = require "poetrymatch/BattleScene/LaBattleResultFight"
			self._laResult = moLaBattleResultFight.Class:create()

		elseif self._nCurBattleType == BATTLE_TYPE.CHALLENGE then
			local moLaBattleResultChallenge = require "poetrymatch/BattleScene/LaBattleResultChallenge"
			self._laResult = moLaBattleResultChallenge.Class:create()

		else
			lly.error("wrong BATTLE_TYPE")
		end

		if not self._laResult then break end

		self:addChild(self._laResult, CONST.Z_RESULT)
		self._laResult:setVisible(false)

		--结束图层的按钮的回调
		self._laResult:setEndFunc(function ()
			lly.log("press win btn")
		end)

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
		self._posPlyrCard.x - CONST.CARD_MOVE_X, self._posPlyrCard.y)

	self._posEnemyCard = cc.p(self._imgEnemyCard:getPosition())
	self._posEnemyCardFrom = cc.p(
		self._posEnemyCard.x + CONST.CARD_MOVE_X, self._posEnemyCard.y + CONST.CARD_MOVE_Y)
	self._posEnemyCardTo = cc.p(
		self._posEnemyCard.x + CONST.CARD_MOVE_X, self._posEnemyCard.y)

	--区域位置
	self._nDisAreaMoveY = 1000

	self._posQuestionArea = cc.p(self._imgQuestionArea:getPosition())
	self._nDisQuestionAreaMoveX = 2000

	self._nDisTalkMove = 190

	--记录标识位置
	self._posEnemyAnswerToken = cc.p(self._imgEnemyAnswerToken:getPosition())
	self._posPlyrAnswerToken = cc.p(self._imgPlyrAnswerToken:getPosition())

	--费血标识的位置
	local offsetDecHP = cc.p(130, 190)
	self._posPlyrDecreaseHP = cc.pSub(self._posPlyrCard, offsetDecHP)
	self._posEnemyDecreaseHP = cc.pSub(self._posEnemyCard, offsetDecHP)

	self._nDisDecHPMoveY = 190

	return true

end

function LaBattle:initAnim()
	--帧动画 攻击
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_ATK_PLIST1, ui.ANIM_ATK_PNG1)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_ATK_PLIST2, ui.ANIM_ATK_PNG2)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_ATK_PLIST3, ui.ANIM_ATK_PNG3)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_ATK_PLIST4, ui.ANIM_ATK_PNG4)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_ATK_PLIST5, ui.ANIM_ATK_PNG5)

	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.ANIM_ATK_JSON)
    self._anim = ccs.Armature:create("gongji")
    self._wiRoot:addChild(self._anim, 100) --在减血后面，在其他前面
    self._anim:setVisible(false)

    self._anim:setScaleY(CONST.FIGHT_ANIM_RATE)

    --判断
    ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_JUDGE_PLIST1, ui.ANIM_JUDGE_PNG1)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_JUDGE_PLIST2, ui.ANIM_JUDGE_PNG2)
	ccs.ArmatureDataManager:getInstance():addSpriteFrameFromFile(
		ui.ANIM_JUDGE_PLIST3, ui.ANIM_JUDGE_PNG3)

	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.ANIM_JUDGE_JSON)
    self._animJudge = ccs.Armature:create("success")
    self._wiRoot:addChild(self._animJudge, 100) --在减血后面，在其他前面
    self._animJudge:setPosition(
    	self._wiRoot:getContentSize().width / 2,self._wiRoot:getContentSize().height / 4)
    self._animJudge:setVisible(false)

	--动作初始化
	--透明上部UI
	self._layCenterUI:setOpacity(0)

	--卡牌，合适的位置和大小
	self._arimgPlyrCard[1]:setPosition(self._posPlyrCardFrom)
	self._arimgPlyrCard[1]:setScale(CONST.CARD_SCALE_FROM)
	self._imgEnemyCard:setPosition(self._posEnemyCardFrom)
	self._imgEnemyCard:setScale(CONST.CARD_SCALE_FROM)
	
	--隐藏技能
	for i = 1, 3 do
		self._ararbtnPlyrSkill[1][i]:setOpacity(0)
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

	--隐藏费血标识
	self._layDecHP:setVisible(false)

	--对话的位置安放好
	self._layTalk:setVisible(true)
	self._imgPlyrTalk:setVisible(true)
	self._imgEnemyTalk:setVisible(true)
	self._imgPlyrTalkAfter:setVisible(true)
	self._imgEnemyTalkAfter:setVisible(true)

	self._imgPlyrTalk:setPositionY(self._imgPlyrTalk:getPositionY() - self._nDisTalkMove)
	self._imgEnemyTalk:setPositionY(self._imgEnemyTalk:getPositionY() - self._nDisTalkMove)
	self._imgPlyrTalkAfter:setPositionY(self._imgPlyrTalkAfter:getPositionY() - self._nDisTalkMove)
	self._imgEnemyTalkAfter:setPositionY(self._imgEnemyTalkAfter:getPositionY() - self._nDisTalkMove)

	--卡牌展示第一张
	self._nCurCardIndex = 1
	self._arckbCard[1]:setSelectedState(true)
	self._arckbCard[1]:setTouchEnabled(false)

	return true
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
	private.printState("begin counting down")

	self._nSecondLeft = second
	self._fLastTime = 0
end

--停止倒计时
function LaBattle:stopCountingdown(second)
	private.printState("stop counting down")

	self._nSecondLeft = 0
end

--计时器每过一秒的回调
function LaBattle:onTimePass()
	--lly.log(os.time())

	--显示倒计时的数字
	if self._stateCurrent == state.prepare then
		self._txtCountdownInCardChange:setString(tostring(self._nSecondLeft))
	elseif self._stateCurrent == state.waitingForPlayerAnswer or
		self._stateCurrent == state.waitingForEnemyAnswer then
		self._txtCountdown:setString(tostring(self._nSecondLeft))
	end
end

--计时结束的回调
function LaBattle:onTimeEnd()
	if self._stateCurrent == state.prepare then
		if self._bHasVIT then
			self:endPrepare()
		else
			self:endPrepareWhenNoVIT()
		end
	elseif self._stateCurrent == state.waitingForPlayerAnswer then
		self:endPlayerAnswer()
	elseif self._stateCurrent == state.waitingForEnemyAnswer then
		self:endEnemyAnswer()
	end

end

--电脑思考中
function LaBattle:excuteComputerThinking()
	if not self._bComputerBeginThink then return end

	if self._nSecondLeft == 0 then --要求在倒计时中
		self._bComputerBeginThink = false
		return
	end

	if self._nThkBgnTime == 0 then --初始化
		self._nThkBgnTime = self._nSecondLeft
		return
	end

	if self._nThkBgnTime - self._nSecondLeft >= self._nCOMAnswerSpendTime then
		self:onComputerThinkingEnd()

		self._bComputerBeginThink = false
		self._nThkBgnTime = 0
	end
end

--执行判断对错的动画
--参数：谁回答的问题，最后回调的函数
--返回：谁减少HP，减少了多少
function LaBattle:doCheckAnswerAnim(camp_type, func)
	lly.ensure(camp_type, "number")
	if camp_type and camp_type <= 0 or camp_type >= CAMP_TYPE.MAX then 
		lly.error("wrong type")
	end

	local bRight = true
	local nHPdecrease = 0
	local nextState

	--获取服务器中本题是否正确，谁减少多少血，转到什么状态


	--判断回合数
	local isEnd = false
	if not nextState and self._nRoundsNumber <= 1 then		
		isEnd = true
		print(self._barPlyrHP:getPercent(), self._barEnemyHP:getPercent())
		if self._barPlyrHP:getPercent() < self._barEnemyHP:getPercent() then
			nextState = state.win
		else
			nextState = state.lose
		end
	end

	--如果正确，则对方掉血，否则自己
	if bRight then
		if camp_type == CAMP_TYPE.PLAYER then
			camp_type = CAMP_TYPE.ENEMY
		else
			camp_type = CAMP_TYPE.PLAYER
		end
	end

	--如果结束就不执行endShowPlyrResult
	if nextState then
		func = function (self) self._bCurStateIsEnding = true end
	end

	--动画
	self._animJudge:setVisible(true)
	if bRight then
		self._animJudge:getAnimation():play("success", -1, 0)
	else
		self._animJudge:getAnimation():play("fail", -1, 0)
	end

	--回调	
	self._animJudge:getAnimation():setMovementEventCallFunc(
	function (armature, movementType, movementID)
		if movementType == ccs.MovementEventType.complete then
			self._animJudge:setVisible(false)
			self:doHPDecreseAnim(camp_type, nHPdecrease, func)
		end
	end)

	return nextState, isEnd
end

--执行HP减少动画
function LaBattle:doHPDecreseAnim(camp_type, nHP, func)
	lly.ensure(camp_type, "number")
	lly.ensure(nHP, "number")
	lly.ensure(func, "function")
	if camp_type and camp_type <= 0 or camp_type >= CAMP_TYPE.MAX then 
		lly.error("wrong type")
	end

	local posAnimFrom
	local posAnimTo
	local posAnimSlowTo

	local decreaseHPCard
	local posDereaseHPToken
	local decreaseHPBar

	local HPDifference
	local persent

	--动画是玩家指向敌人的，如果是玩家费血，要反转动画
	if camp_type == CAMP_TYPE.PLAYER then
		self._anim:setScaleX(-CONST.FIGHT_ANIM_RATE)

		posAnimFrom = cc.pSub(self._posEnemyCard, cc.p(160, 0))
		posAnimTo = cc.pAdd(self._posPlyrCard, cc.p(160, 0))
		posAnimSlowTo = cc.pSub(self._posPlyrCard, cc.p(80, 0))

		decreaseHPCard = self._arimgPlyrCard[self._nCurCardIndex]
		posDereaseHPToken = self._posPlyrDecreaseHP

		decreaseHPBar = self._barPlyrHP
		HPDifference = self._nPlyrCurrentHP - nHP
		persent = 100 * nHP / self._nPlyrHPCeiling

		self._nPlyrCurrentHP = nHP

	else
		self._anim:setScaleX(CONST.FIGHT_ANIM_RATE)

		posAnimFrom = cc.pAdd(self._posPlyrCard, cc.p(160, 0))
		posAnimTo = cc.pSub(self._posEnemyCard, cc.p(160, 0))
		posAnimSlowTo = cc.pAdd(self._posEnemyCard, cc.p(80, 0))

		decreaseHPCard = self._imgEnemyCard
		posDereaseHPToken = self._posEnemyDecreaseHP

		decreaseHPBar = self._barEnemyHP
		HPDifference = self._nEnemyCurrentHP - nHP
		persent = 100 * nHP / self._nEnemyHPCeiling

		self._nEnemyCurrentHP = nHP
	end

	--初始化
	self._anim:setPosition(posAnimFrom)
	self._anim:setVisible(true)

	self._layDecHP:setPosition(posDereaseHPToken)
	self._atlasDecHP:setString(tostring(HPDifference))

	--飞出武器
	local rAtk = math.random(3)
	local atk_anim_name_tab = {"hj", "lj", "bj"}
	self._anim:getAnimation():play(atk_anim_name_tab[rAtk], -1, 0)

	--同时移动武器（加速）
	local acMoveFast = cc.EaseExponentialIn:create(
		cc.MoveTo:create(0.8, posAnimTo))

	--然后回调
	local callfunc = cc.CallFunc:create(function ()

		--爆炸
		local expl_anim_name_tab = {"g1", "g2", "g4"}
		self._anim:getAnimation():play(expl_anim_name_tab[rAtk], -1, 0) 

		--显示
		decreaseHPBar:setPercent(persent)
		self._layDecHP:setVisible(true)
	end)

	--同时爆炸的惯性移动
	local acMoveSlow = cc.EaseSineOut:create(
		cc.MoveTo:create(1.0, posAnimSlowTo))

	--同时显示费血
	local acMoveHPShow = cc.MoveBy:create(0.5, cc.p(0, self._nDisDecHPMoveY))

	--同时晃动
	local acMoveLeft = cc.MoveBy:create(0.05, cc.p(-10, 0))
	local acMoveRight = cc.MoveBy:create(0.05, cc.p(20, 0))
	local acShake = cc.Sequence:create(
		acMoveLeft, acMoveRight, acMoveLeft:clone())

	--然后结束
	local callfuncEnd = cc.CallFunc:create(function ()
		self._anim:setVisible(false)
		self._layDecHP:setVisible(false)
		func(self)
	end)

	--移动到敌人身上后减速，同时执行效果，同时显示费血，同时晃动
	self:runAction(
		cc.Sequence:create(
			cc.TargetedAction:create(self._anim, acMoveFast),
			callfunc,
			cc.Spawn:create(
				cc.TargetedAction:create(self._anim, acMoveSlow),
				cc.TargetedAction:create(self._layDecHP, acMoveHPShow),
				cc.TargetedAction:create(decreaseHPCard, acShake)
			),
			callfuncEnd
		)
	)
	
end

---------------------------------------------------------
function LaBattle:downloadQuestion(camp_type, callback)
	lly.ensure(camp_type, "number")
	if camp_type <= 0 or camp_type >= CAMP_TYPE.MAX then lly.error("wrong type") end

	--[[
	local r = math.random(4)

	if r == 1 then self._nCurQuesType = QUES_TYPE.SINGLE_CHOICE
	elseif r == 2 then self._nCurQuesType = QUES_TYPE.MULTIPLE_CHOICE
	elseif r == 3 then self._nCurQuesType = QUES_TYPE.YES_OR_NO
	else  self._nCurQuesType = QUES_TYPE.FILL_IN_BLANK
	end
	--]]

	--制作数据结构
	local sendedTable = {}
	sendedTable.game_range = self._nCurBattleType --战斗类型
	sendedTable.road_block_id = self._nCurStageID --关卡/擂台id
	sendedTable.camp_type = camp_type

	if camp_type == CAMP_TYPE.PLAYER then
		sendedTable.attack_card_plate_id = self._nEnemyCardID --对方卡牌id
		sendedTable.card_plate_id = self._arnPlyrCardID[self._nCurCardIndex] --自己卡牌的id	
	else
		sendedTable.attack_card_plate_id = self._arnPlyrCardID[self._nCurCardIndex] --对方卡牌id
		sendedTable.card_plate_id = self._nEnemyCardID--自己卡牌的id
	end
	
	---[[发送数据，_nCurBattleType, camp_type, cardID, otherCardID, skill
	moperson_info.post_data_by_new_form(
		"get_question", --业务名
		sendedTable, --数据
		function (bSuc, result) --结果回调
			if not bSuc then lly.log(result) end

			lly.logTable(result)

			--解析获得的table
			--当前题的id
			self._nCurQuesID = result.question_bank_id

			--当前题类型
			if result.question_type >= 4 then --4以上全是填空题
				result.question_type = 4
			end
			
			self._nCurQuesType = result.question_type

			--标题
			--内容
			--选项
			--电脑的答案
			self._arbChoise = 0

			--电脑答题的时间
			self._nCOMAnswerSpendTime = 0


			--执行回调
			--callback()
		end
	)
	--]]
	
end

function LaBattle:checkAnswer()
	self._bNextStateDataHasLoad = true
end

---------------------------------------------------------
--清空题板
function LaBattle:clearQuestionArea()
	--清空题目
	self._txtQuestionTitle:setString("")

	--清空题干
	self._txtQuestionContent:setString("")

	--不显示答题区
	self._layFillInBlank:setVisible(false)
	self._layShortChoose:setVisible(false)
	self._layLongChoose:setVisible(false)
	self._layRightOrWrong:setVisible(false)

	--清空答案
	for i = 1, 4 do self._arbChoise[i] = false end
end

--写入题板
function LaBattle:writeInQuestionArea()
	local fadeIn = cc.fadeIn:create(0.2)

	--写入题目
	self._txtQuestionTitle:setString("这个是标题")
	self._txtQuestionTitle:setOpacity(0)
	self._txtQuestionTitle:runAction(fadeIn:clone())

	--写入题干
	self._txtQuestionContent:setString("这个是内容啊这个是内容")
	self._txtQuestionContent:setOpacity(0)
	self._txtQuestionContent:runAction(fadeIn:clone())
	
	--显示相应答题区，清空题板上点击
	if self._nCurQuesType == QUES_TYPE.SINGLE_CHOICE
		or self._nCurQuesType == QUES_TYPE.MULTIPLE_CHOICE then
		--判断答案长度，5个汉字或以下用短选择
		if true then --短
			self._layShortChoose:setVisible(true)

			--写入选项

			--清空
			for i = 1, 4 do
				self._arckbShortChoose[i]:setSelectedState(false)
			end

			--动作
			for i = 1, 4 do
				self._arckbShortChoose[i]:setOpacity(0)
				self._arckbShortChoose[i]:runAction(fadeIn:clone())
			end
		else
			self._layLongChoose:setVisible(true)

			--写入选项

			--清空
			for i = 1, 4 do
				self._arckbLongChoose[i]:setSelectedState(false)
			end

			--动作
			for i = 1, 4 do
				self._arckbLongChoose[i]:setOpacity(0)
				self._arckbLongChoose[i]:runAction(fadeIn:clone())
			end
		end

	elseif self._nCurQuesType == QUES_TYPE.YES_OR_NO then
		self._layRightOrWrong:setVisible(true)
		self._ckbRight:setSelectedState(false)
		self._ckbWrong:setSelectedState(false)

		--动作
		self._ckbRight:setOpacity(0)
		self._ckbRight:runAction(fadeIn:clone())
		self._ckbWrong:setOpacity(0)
		self._ckbWrong:runAction(fadeIn:clone())

	elseif self._nCurQuesType == QUES_TYPE.FILL_IN_BLANK then
		self._layFillInBlank:setVisible(true)
		self._iptFillInBlank:setText("")

		--动作
		self._layFillInBlank:setOpacity(0)
		self._layFillInBlank:runAction(fadeIn:clone())
	else
		lly.error("wrong ques type")
	end
end

function LaBattle:getTalkAction()
	local acMoveTalkFrom = cc.MoveBy:create(CONST.TALK_MOVE_TIME, cc.p(0, self._nDisTalkMove))
	local delay = cc.DelayTime:create(CONST.TALK_DELAY_TIME)
	local acMoveTalkTo = cc.MoveBy:create(CONST.TALK_MOVE_TIME,  cc.p(0, self._nDisTalkMove))

	return cc.Sequence:create(acMoveTalkFrom, delay, acMoveTalkTo)
end
----------------------------------------------------------
--点击换牌按钮时
function LaBattle:onClickChangeCard(sender, eventType)
	lly.log("click change card %d", sender:getTag())

	if self._bBuzyToChangeCard then return end
	self._bBuzyToChangeCard = true
	self._bForbidEnterNextState = true

	--让自己不能点击，其他的复选框可以点击
	for i = 1, 3 do
		if self._arckbCard[i] == sender then
			sender:setTouchEnabled(false)
		else
			self._arckbCard[i]:setSelectedState(false)
			if self._arnPlyrCardVIT[i] ~= 0 then
				self._arckbCard[i]:setTouchEnabled(true)
			end
		end
	end
	
	--[[
	self._bBuzyToChangeCard = false
	self._nCurCardIndex = sender:getTag()
	
	do return end
	--]]

	--得到下一张显示的卡牌，用按钮的tag值记录，tag与ckb在ar里的顺序一致
	local nextCardIndex = sender:getTag()

	--下一张卡牌放好位置和缩放
	self._arimgPlyrCard[nextCardIndex]:setPosition(self._posPlyrCardFrom)
	self._arimgPlyrCard[nextCardIndex]:setScale(CONST.CARD_SCALE_FROM)
	self._arimgPlyrCard[nextCardIndex]:setLocalZOrder(CONST.Z_CARD_COME)

	--动画移动
	local acMovePC = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posPlyrCard)
	local acSaclePC = cc.ScaleTo:create(CONST.CARD_MOVE_TIME, 1.0)

	local acMovePCTo = cc.MoveTo:create(CONST.CARD_MOVE_TIME, self._posPlyrCardTo)

	local callFunc = cc.CallFunc:create(function ()
		self._arimgPlyrCard[self._nCurCardIndex]:setLocalZOrder(CONST.Z_CARD_NORMAL)

		--更换技能，隐藏以前的，显示现在的
		for i = 1, 3 do
			self._ararbtnPlyrSkill[self._nCurCardIndex][i]:setVisible(false)
			self._ararbtnPlyrSkill[nextCardIndex][i]:setVisible(true)
		end

		--当前卡牌
		self._nCurCardIndex = nextCardIndex

		--恢复状态
		self._bBuzyToChangeCard = false
		self._bForbidEnterNextState = false
	end)

	--执行
	self._arimgPlyrCard[self._nCurCardIndex]:runAction(acMovePCTo)
	self._arimgPlyrCard[nextCardIndex]:runAction(cc.Sequence:create(
		cc.Spawn:create(
			acMovePC, 
			acSaclePC
		), 
		callFunc
	))
end

--点击技能按钮时
function LaBattle:onClickSkill(camp_type, skillIndex)
	--是否在点击时，需要对技能进行注解呢

	--只有在非禁用状态下，才执行以下代码
	if not self._arbtnEnemySkill[skillIndex]:isBright() then return end

	--只有在等待状态并且玩家自己的技能才可以使用
	if self._stateCurrent ~= state.waitingForPlayerAnswer and
		self._stateCurrent ~= state.waitingForEnemyAnswer or
		camp_type ~= CAMP_TYPE.PLAYER then
		lly.log("can not use skill")
		return
	end

	lly.log("click %d ==> %d ==> %d", 
		camp_type, self._nCurCardIndex, skillIndex)

	--根据索引获得技能

	--使用技能

end

--使用技能
function LaBattle:useSkill()
	private.printState("use Skill")

	--禁止进入下个状态
	self._bForbidEnterNextState = true

	--进行动画（完成是检查请求是否完成，完成则取消禁止）

	--请求服务器（完成是检查动画是否完成，完成则取消禁止）

end

--点击放弃按钮时
function LaBattle:onClickGiveUp()

	--进入确认对话框
	moperson_info.messagebox(self._wiRoot, moperson_info.BATTLE_GIVEUP, 
		function (msgType)
			--进入失败画面
			if msgType == moperson_info.OK then
				--然后发送失败消息给服务器
				self:onGiveUp()
			end		
		end)
end

function LaBattle:onGiveUp()
	self._stateNext = function () end
	self:lose_S()
end

--点击短选项时
function LaBattle:onClickShortChoose(sender, eventType)
	--判断是单选还是多选
	if self._nCurQuesType == QUES_TYPE.SINGLE_CHOICE then
		for i = 1, 4 do
			if sender ~= self._arckbShortChoose[i] then
				self._arckbShortChoose[i]:setSelectedState(false)
				self._arckbShortChoose[i]:setTouchEnabled(true)
				self._arbChoise[i] = false
			else
				self._arckbShortChoose[i]:setTouchEnabled(false)
				self._arbChoise[i] = true
			end
		end
	elseif self._nCurQuesType == QUES_TYPE.MULTIPLE_CHOICE then
		for i = 1, 4 do
			if sender ~= self._arckbShortChoose[i] then
				self._arbChoise[i] = self._arckbShortChoose[i]:getSelectedState()
			else
				--此时eventtype为boolean值，选择为true，取消为false			
				self._arbChoise[i] = eventType 
			end
		end
	else
		lly.error("wrong question type in short")
	end
end

--点击长选项时
function LaBattle:onClickLongChoose(sender, eventType)
	--判断是单选还是多选
	if self._nCurQuesType == QUES_TYPE.SINGLE_CHOICE then
		for i = 1, 4 do
			if sender ~= self._arckbLongChoose[i] then
				self._arckbLongChoose[i]:setSelectedState(false)
				self._arckbLongChoose[i]:setTouchEnabled(true)
				self._arbChoise[i] = false
			else
				self._arckbLongChoose[i]:setTouchEnabled(false)
				self._arbChoise[i] = true
			end
		end
	elseif self._nCurQuesType == QUES_TYPE.MULTIPLE_CHOICE then
		for i = 1, 4 do
			if sender ~= self._arckbLongChoose[i] then
				self._arbChoise[i] = self._arckbLongChoose[i]:getSelectedState()
			else
				--此时eventtype为boolean值，选择为true，取消为false			
				self._arbChoise[i] = eventType 
			end
		end
	else
		lly.error("wrong question type in long")
	end	
end

--点击对错时
function LaBattle:onClickYesOrNo(sender, eventType)
	if sender == self._ckbRight then
		self._ckbRight:setTouchEnabled(false)
		self._arbChoise[1] = true

		self._ckbWrong:setSelectedState(false)
		self._ckbWrong:setTouchEnabled(true)
		self._arbChoise[2] = false
	else
		self._ckbRight:setSelectedState(false)
		self._ckbRight:setTouchEnabled(true)
		self._arbChoise[1] = false

		self._ckbWrong:setTouchEnabled(false)
		self._arbChoise[2] = true
	end
	
end

----------------------------------------------------------
--开场动画状态
function LaBattle:playEnterAnim_S()
	private.printState("play Enter Anim")
	self._stateCurrent = self._stateNext

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
			cc.TargetedAction:create(self._ararbtnPlyrSkill[1][1], acSkFadeIn),
			cc.TargetedAction:create(self._arbtnEnemySkill[1], acSkFadeIn:clone())),
		cc.Spawn:create(
			cc.TargetedAction:create(self._ararbtnPlyrSkill[1][2], acSkFadeIn:clone()),
			cc.TargetedAction:create(self._arbtnEnemySkill[2], acSkFadeIn:clone())),
		cc.Spawn:create(
			cc.TargetedAction:create(self._ararbtnPlyrSkill[1][3], acSkFadeIn:clone()),
			cc.TargetedAction:create(self._arbtnEnemySkill[3], acSkFadeIn:clone())),
		callFunc))
end

--玩家准备出题，选择人物，选择技能
function LaBattle:prepare_S()
	private.printState("prepare")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.askByEnemy
	self._bCurStateIsEnding = false

	--展示回合数
	self._atlasRounds:setString(tostring(self._nRoundsNumber))

	--查看是否还有剩余体力，没有的话直接进入提示
	if self._bHasVIT then
		self._bHasVIT = false
		for i = 1, 3 do
			if self._arnPlyrCardVIT[i] ~= 0 then
				self._bHasVIT = true
				break
			end
		end

		local acMoveCC = cc.MoveBy:create(CONST.CD_CHNG_MOVE_TIME, 
			cc.p(0, self._nDisAreaMoveY))

		if not self._bHasVIT then --第一次发现没体力，进行提示
			self._imgTip:runAction(cc.EaseExponentialOut:create(acMoveCC))
			self:beginCountingdown(CONST.CHANGE_CARD_TIME) --在后台倒计时

		else
			--展示体力
			for i = 1, 3 do
				self._artxtCardVIT[i]:setString(
					string.format("%d/%d", self._arnPlyrCardVIT[i], self._arnPlyrCardVITMax[i]))
			end

			self._txtCountdownInCardChange:setString(tostring(CONST.CHANGE_CARD_TIME))

			local callfuncCountingdown = cc.CallFunc:create(function ()
				self._bBuzyToChangeCard = false --恢复可点击

				self:beginCountingdown(CONST.CHANGE_CARD_TIME) --开启倒计时

				--如果体力不够则不可再点击头像
				local nIndexHasVIT
				local bCurrentNotHaveVIT = false
				for i = 3, 1, -1 do --倒着循环是为了下一个控件能在上一个右边
					if self._arnPlyrCardVIT[i] == 0 then
						self._arckbCard[i]:setTouchEnabled(false) --禁止点击
						self._arckbCard[i]:setOpacity(120) --变虚
						if i == self._nCurCardIndex then
							bCurrentNotHaveVIT = true
						end
					else
						nIndexHasVIT = i
					end
				end

				--如果被禁止的是当前选则，则把当前选则移到有的
				if bCurrentNotHaveVIT then
					self._arckbCard[nIndexHasVIT]:setSelectedState(true)
					self:onClickChangeCard(self._arckbCard[nIndexHasVIT])
				end
			end)

			--执行期间不能点击头像
			self._bBuzyToChangeCard = true

			--执行
			self._imgCardChangeArea:runAction(cc.Sequence:create(
				cc.EaseExponentialOut:create(acMoveCC), callfuncCountingdown))
		end
	else --第二次发现没体力则直接进行下面敌人的发问
		self._bCurStateIsEnding = true
	end
end

--结束准备，调用于倒计时结束和点击按钮后
function LaBattle:endPrepare()
	--防止重复点击
	if self._bBuzyToEndingState then return end
	self._bBuzyToEndingState = true

	--结束计时
	self:stopCountingdown()

	--当前卡牌体力减少1
	self._arnPlyrCardVIT[self._nCurCardIndex] = self._arnPlyrCardVIT[self._nCurCardIndex] - 1

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

--没体力后
function LaBattle:endPrepareWhenNoVIT()
	--防止重复点击
	self._btnConfirm:setTouchEnabled(false)

	--结束计时
	self:stopCountingdown()

	--收起提示后，进入下个状态
	local acMoveCC = cc.MoveBy:create(CONST.CD_CHNG_MOVE_TIME, 
		cc.p(0, -self._nDisAreaMoveY))

	local callfuncNextState = cc.CallFunc:create(function ()
		self._bCurStateIsEnding = true
	end)

	self._imgTip:runAction(cc.Sequence:create(
		cc.EaseSineIn:create(acMoveCC), callfuncNextState))
end

--敌方出题
function LaBattle:askByEnemy_S()
	private.printState("ask by enemy")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.waitingForPlayerAnswer
	self._bCurStateIsEnding = false
	self._bNextStateDataHasLoad = false

	--防止错误操作
	self._btnQuestionCommit:setTouchEnabled(false)

	--初始化
	self._imgQuestionArea:setPositionX(
		self._posQuestionArea.x + self._nDisQuestionAreaMoveX)
	self._txtCountdown:setString(tostring(CONST.ANSWER_TIME))

	--清空题板
	self:clearQuestionArea()

	--展示敌方对话
	local acTalkMove = self:getTalkAction()

	--从右边（敌人方向）飞出答题板后
	local acMoveQuseAreaFrom = cc.MoveBy:create(CONST.QUES_MOVE_TIME, cc.p(-self._nDisQuestionAreaMoveX, 0))

	--结束，完成后ending为true
	local callfunc = cc.CallFunc:create(function ()
		self._imgEnemyTalk:setPositionY(self._imgEnemyTalk:getPositionY() - 2 * self._nDisTalkMove)
		self._btnQuestionCommit:setTouchEnabled(true)
		self._bCurStateIsEnding = true
	end)

	self._imgEnemyTalk:runAction(cc.Sequence:create(
		acTalkMove, 
		cc.TargetedAction:create(self._imgQuestionArea, 
			cc.EaseExponentialOut:create(acMoveQuseAreaFrom)),
		callfunc))

	--获取题目，获取后执行回调
	self:downloadQuestion(CAMP_TYPE.ENEMY, function ()
		self:writeInQuestionArea()
		self._bNextStateDataHasLoad = true
	end)

end

--等待玩家答题
--玩家可以使用道具，进入道具动画状态，进入时禁止点击提交
--等待玩家提交答案，或者倒计时结束
function LaBattle:waitingForPlayerAnswer_S()
	private.printState("waiting for player answer")
	self._stateCurrent = self._stateNext

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

	--结束计时
	self:stopCountingdown()

	--隐藏标识并结束动画
	self._imgPlyrAnswerToken:setVisible(false)
	self._imgPlyrAnswerToken:stopAllActions()

	--颜色变暗
	self._imgQuestionArea:setColor(
		cc.c3b(CONST.QUES_COLOR, CONST.QUES_COLOR, CONST.QUES_COLOR))

	--打开屏蔽层
	self._layShield:setVisible(true)

	self._bCurStateIsEnding = true
end

--敌人进攻，同时提交答案，获得结果
function LaBattle:attackByEnemy_S()
	private.printState("attack by Enemy")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.showResultOfEnemyAtk
	self._bCurStateIsEnding = false
	self._bNextStateDataHasLoad = false

	--答题动画
	--变成半透明
	local acFadeOut = cc.FadeTo:create(
		CONST.QUES_FADE_TIME, CONST.QUES_FADE)

	--对话
	local acTalkMove = self:getTalkAction()

	--结束回调
	local callfuncNextState = cc.CallFunc:create(function ()
		self._imgPlyrTalkAfter:setPositionY(
			self._imgPlyrTalkAfter:getPositionY() - 2 * self._nDisTalkMove)
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		acFadeOut, 
		cc.TargetedAction:create(self._imgPlyrTalkAfter, acTalkMove), 
		callfuncNextState
	))

	--提交服务器答案等待验证
	self:checkAnswer()

end

--玩家进攻结果
function LaBattle:showResultOfEnemyAtk_S()
	private.printState("show Result Of enemy Atk")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.askByPlayer
	
	--状态
	self._bCurStateIsEnding = false

	--输入谁回答的题，根据服务器返回，判断对错，然后执行减少HP的动画
	--如果得到的是结束，就返回结束状态，否则返回空
	local nextState, isEnd = self:doCheckAnswerAnim(CAMP_TYPE.PLAYER, self.endShowEnemyResult)

	if nextState then 
		self._stateNext = nextState
		return
	end

	--如果没有体力了，则直接跳到玩家准备界面，在此处检测是否回合结束
	if self._bHasVIT == false then
		if not isEnd then
			self._nRoundsNumber = self._nRoundsNumber - 1
			self._stateNext = state.prepare
		end

		return
	end
end

function LaBattle:endShowEnemyResult()

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
	private.printState("ask by player")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.waitingForEnemyAnswer
	self._bCurStateIsEnding = false
	self._bNextStateDataHasLoad = false

	--防止错误操作
	self._btnQuestionCommit:setTouchEnabled(false)

	--初始化
	self._imgQuestionArea:setPositionX(
		self._posQuestionArea.x - self._nDisQuestionAreaMoveX)
	self._txtCountdown:setString(tostring(CONST.ANSWER_TIME))

	--打开屏蔽层
	self._layShield:setVisible(true)

	--隐藏确认按钮
	self._btnQuestionCommit:setVisible(false)

	--写入题板
	self:clearQuestionArea()

	--对话
	local acTalkMove = self:getTalkAction()

	--从左边（玩家方向）飞出答题板后
	local acMoveQuseAreaFrom = cc.MoveBy:create(CONST.QUES_MOVE_TIME, cc.p(self._nDisQuestionAreaMoveX, 0))

	--结束，完成后ending为true
	local callfunc = cc.CallFunc:create(function ()
		self._imgPlyrTalk:setPositionY(self._imgPlyrTalk:getPositionY() - 2 * self._nDisTalkMove)
		self._btnQuestionCommit:setTouchEnabled(true)
		self._bCurStateIsEnding = true
	end)

	self._imgPlyrTalk:runAction(cc.Sequence:create(
		acTalkMove, 
		cc.TargetedAction:create(self._imgQuestionArea, 
			cc.EaseExponentialOut:create(acMoveQuseAreaFrom)),
		callfunc))

	--获取问题，获取后把题目显示在答题板上，然后hasload为true
	self:downloadQuestion(CAMP_TYPE.PLAYER, function ()
		self:writeInQuestionArea()
		self._bNextStateDataHasLoad = true
	end)

end

--等待敌人答题
function LaBattle:waitingForEnemyAnswer_S()
	private.printState("waiting for enemy answer")
	self._stateCurrent = self._stateNext

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

	--根据服务器反馈的时间，时间到达后显示其答案，并进入下个状态
	self:beginComputerAnswer()
end

--开始电脑思考
function LaBattle:beginComputerAnswer()
	self._bComputerBeginThink = true
end

--电脑思考后显示结果
function LaBattle:onComputerThinkingEnd()
	lly.log("onComputerThinkingEnd")

	--显示结果
	if self._nCurQuesType == QUES_TYPE.FILL_IN_BLANK then
		self._iptFillInBlank:setText(self._strAnswer)
	elseif self._nCurQuesType == QUES_TYPE.YES_OR_NO then
		if lly._arbChoise[1] == true then
			self._ckbRight:setSelectedState(true)
		end

		if lly._arbChoise[2] == true then
			self._ckbWrong:setSelectedState(true)
		end
	else
		for k, v in pairs(lly._arbChoise) do
			self._arckbShortChoose[k]:setSelectedState(v)
			self._arckbLongChoose[k]:setSelectedState(v)
		end
	end

	--结束
	self:endEnemyAnswer()
end

function LaBattle:endEnemyAnswer()
	lly.logCurLocAnd("end enemy anser")

	--结束计时
	self:stopCountingdown()

	--隐藏标识并结束动画
	self._imgEnemyAnswerToken:setVisible(false)
	self._imgEnemyAnswerToken:stopAllActions()

	--颜色变暗
	self._imgQuestionArea:setColor(
		cc.c3b(CONST.QUES_COLOR, CONST.QUES_COLOR, CONST.QUES_COLOR))

	--
	self._bCurStateIsEnding = true
end

--玩家进攻
function LaBattle:attackByPlayer_S()
	private.printState("attack by player")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.showResultOfPlayerAtk
	self._bCurStateIsEnding = false
	self._bNextStateDataHasLoad = false

	--答题动画
	--变成半透明
	local acFadeOut = cc.FadeTo:create(
		CONST.QUES_FADE_TIME, CONST.QUES_FADE)

	--对话
	local acTalkMove = self:getTalkAction()

	--结束回调
	local callfuncNextState = cc.CallFunc:create(function ()
		self._imgEnemyTalkAfter:setPositionY(
			self._imgEnemyTalkAfter:getPositionY() - 2 * self._nDisTalkMove)
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		acFadeOut, 
		cc.TargetedAction:create(self._imgEnemyTalkAfter, acTalkMove),
		callfuncNextState))

	--提交服务器答案等待验证
	self:checkAnswer()

end

--玩家进攻结果
function LaBattle:showResultOfPlayerAtk_S()
	private.printState("show Result Of player Atk")
	self._stateCurrent = self._stateNext

	--设置下个状态
	self._stateNext = state.prepare

	--状态
	self._bCurStateIsEnding = false

	--输入谁回答的题，根据服务器返回，判断对错，然后执行减少HP的动画
	--如果得到的是结束，就返回结束状态，否则返回空
	--返回值isEnd，表示是否因为没有回合数而结束
	local nextState, isEnd = self:doCheckAnswerAnim(CAMP_TYPE.ENEMY, self.endShowPlayerResult)

	if nextState then self._stateNext = nextState end

	if not isEnd then self._nRoundsNumber = self._nRoundsNumber - 1 end
end

--结束动画
function LaBattle:endShowPlayerResult()

	--收起 *2是为了移走的速度更舒服
	local acMoveCC = cc.MoveBy:create(
		CONST.QUES_MOVE_TIME, cc.p(self._nDisQuestionAreaMoveX * -2, 0))

	local callfuncNextState = cc.CallFunc:create(function ()
		self._imgQuestionArea:setOpacity(255)
		self._imgQuestionArea:setColor(cc.c3b(255, 255, 255)) --恢复颜色
		self._layShield:setVisible(false) --关闭屏蔽层
		self._btnQuestionCommit:setVisible(true) --显示按钮
		self._bCurStateIsEnding = true
	end)

	self._imgQuestionArea:runAction(cc.Sequence:create(
		cc.EaseSineIn:create(acMoveCC), callfuncNextState)) 
end

--胜利
function LaBattle:win_S()
	private.printState("win")
	self._stateCurrent = self._stateNext

	self._bCurStateIsEnding = false

	--启动胜利页面
	self._laResult:setVisible(true)
	self._laResult:win()

end

--失败
function LaBattle:lose_S()
	private.printState("lose")
	self._stateCurrent = self._stateNext

	self._bCurStateIsEnding = false

	--启动失败页面
	self._laResult:setVisible(true)
	self._laResult:lose()

end

------------------------------------------------------
--【私有函数】，打印当前状态
function private.printState(str)
	lly.log(str)
	
	--[[
	local socket = require("socket")
	socket.select(nil, nil, 1)
	--]]
end

state = lly.const{
	playEnterAnim = LaBattle.playEnterAnim_S,
	prepare = LaBattle.prepare_S,
	askByEnemy = LaBattle.askByEnemy_S,
	waitingForPlayerAnswer = LaBattle.waitingForPlayerAnswer_S,
	attackByEnemy = LaBattle.attackByEnemy_S,
	showResultOfEnemyAtk = LaBattle.showResultOfEnemyAtk_S,
	askByPlayer = LaBattle.askByPlayer_S,
	waitingForEnemyAnswer = LaBattle.waitingForEnemyAnswer_S,
	attackByPlayer = LaBattle.attackByPlayer_S,
	showResultOfPlayerAtk = LaBattle.showResultOfPlayerAtk_S,
	win = LaBattle.win_S,
	lose = LaBattle.lose_S,
}

return {
	Class = LaBattle,
}

