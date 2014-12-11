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

lly.finalizeCurrentEnvironment()

--状态对应方法（见最下）
local state

local LaBattle = lly.class("LaBattle", function ()
	return cc.Node:create()
end)

function LaBattle:ctor()
	return {
		--UI
		_wiRoot = Lnull,

		_stateNext = Lnull, --当前状态

		--每个状态进入下个状态时要判断如下2点，
		--本状态是否结束，下个状态是否加载成功
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
					self._fLastTime = 0
					self:onTimeEnd()
				end
			end

		end, 0)

		self._nSecondLeft = 10

		return true
	until true

	return false
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
	self._stateNext = state.askByEnemy

	--执行动画，完成后ending为true

	--读取电脑出的题，完成后load为true

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
	self._stateNext = state.answerByPlayer

	--开始倒计时

end

--答题
function LaBattle:answerByPlayer_S()
	printState("answer by player")

	--设置下个状态
	self._stateNext = state.attackByPlayer

	--答题动画

	--进行一部分动画，同时提交服务器答案等待验证

end

--玩家进攻
function LaBattle:attackByPlayer_S()
	printState("attack by player")

	--设置下个状态
	self._stateNext = state.prepareForPlayerAsk

end

--玩家准备出题，选择人物，选择技能
function LaBattle:prepareForPlayerAsk_S()
	printState("prepare for player ask")

	--设置下个状态
	self._stateNext = state.askByPlayer

end

--玩家出题
function LaBattle:askByPlayer_S()
	printState("ask by player")

	--设置下个状态
	self._stateNext = state.waitingForEnemyAnswer

end

--等待敌人答题
function LaBattle:waitingForEnemyAnswer_S()
	printState("waiting for enemy answer")

	--设置下个状态
	self._stateNext = state.answerByEnemy

end

--敌人答题
function LaBattle:answerByEnemy_S()
	printState("answer by enemy")

	--设置下个状态
	self._stateNext = state.attackByEnemy

end

--敌人进攻
function LaBattle:attackByEnemy_S()
	printState("attack by enemy")

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
	askByEnemy = LaBattle.askByEnemy_S,
	waitingForPlayerAnswer = LaBattle.waitingForPlayerAnswer_S,
	answerByPlayer = LaBattle.answerByPlayer_S,
	attackByPlayer = LaBattle.attackByPlayer_S,
	prepareForPlayerAsk = LaBattle.prepareForPlayerAsk_S,
	askByPlayer = LaBattle.askByPlayer_S,
	waitingForEnemyAnswer = LaBattle.waitingForEnemyAnswer_S,
	answerByEnemy = LaBattle.answerByEnemy_S,
	attackByEnemy = LaBattle.attackByEnemy_S,
	win = LaBattle.win_S,
	lose = LaBattle.lose_S,
	enterEnding = LaBattle.enterEnding_S,
}

return {
	Class = LaBattle,
}

