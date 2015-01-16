---
--LaBattleResultBase.lua
--华夏诗魂的战斗结束图层的基类
--	实际只是一个节点，里面包含UI层
--	抽象类，必须继承

--卢乐颜
--2014.12.15

local lly = require "poetrymatch/BattleScene/llyLuaBase2"
local uikits = require "uikits"

lly.finalizeCurrentEnvironment()

local LaBattleResultBase = lly.class("LaBattleResultBase", function ()
	return cc.Node:create()
end)

function LaBattleResultBase:ctor()
	return {
		--UI
		_wiRoot = Lnull,

		--结束按钮
		_btnConfirmWin = Lnull,
		_btnConfirmLose = Lnull,
		
	}
end

function LaBattleResultBase:init(tab)
	repeat
		if not self:initUI(tab) then break end
		if not self:initAnim() then break end

		return true
	until true

	return false
end

lly.set_pure_virtual_function(LaBattleResultBase, "initUI")

lly.set_pure_virtual_function(LaBattleResultBase, "initAnim")

----------------------------------------------
function LaBattleResultBase:setWidget(filename)
	local widget = uikits.child(self._wiRoot, filename)
	if not widget then
		lly.error("wrong widget filename", 3)
	end

	return widget
end
------------------------------------------------
--获取数据
lly.set_pure_virtual_function(LaBattleResultBase, "setData")

--胜利时调用
lly.set_pure_virtual_function(LaBattleResultBase, "win")

--失败时调用
lly.set_pure_virtual_function(LaBattleResultBase, "lose")

--设置胜利后的按钮的回调
function LaBattleResultBase:setEndFunc(func)
	if self._btnConfirmWin then
		uikits.event(self._btnConfirmWin, func)
	end

	if self._btnConfirmLose then
		uikits.event(self._btnConfirmLose, func)
	end
end

return {
	Class = LaBattleResultBase,

}


