---
--WiHistogramBar.lua
--柱状图中间柱子的控件
--	可设定柱子的最高值，最低值和当前值，控件自动显示柱子的百分比位置
--	可以用动画的方式生成，展示柱子
--	默认柱子墨绿色，可改变
--卢乐颜
--2014.11.18

local lly = require "homework/lly/llyLuaBase"

lly.finalizeCurrentEnvironment()

local FORMAT_TYPE = { 
	NORMAL = 1, --普通格式%d
	TIME = 2, --时间格式%d分%d秒
	MAX = 3,
}

--常量
local CONST = lly.const{
	UI_FILE = "homework/lly/wiHistogramBar/zhu_zhuang_shu_ju_1.ExportJson",
	BAR_NAME = "layout_bar",
	STATUS_LAB_NAME = "Label_status",
	ITEM_LAB_NAME = "Label_item",

	STATUS_LABEL_HEIGHT = 30, --柱子上文字高出柱子的高度
	HISTOGRAM_BAR_HEIGHT = 540, --柱子总高度
	ACTION_MOVE_TIME = 0.4,
	SPEED_RATE = 0.3,
	ACTION_SHOW_TIME = 0.1,	
}

local WiHistogramBar = lly.class("WiHistogramBar", function () 
    return cc.Node:create()
end)

function WiHistogramBar:ctor()	
	--变量
	self._layRoot = {} --背景颜色
	self._layBar = {} --柱子
	self._labStatus = {} --柱子头部显示具体数值的文本
	self._labItem = {} --柱子下面显示项目的文本

	self._fMinValue = 0 --柱子能标识的最小值
	self._fMaxValue = 100 --柱子能标识的最大值
	self._fCurrentValue = 0 --柱子当前值
	
	self._bIsAnimationEnabled = true --是否有动画

	self._nStatusFormatType = 1 --数值的格式

	--方法
	self.setItemName = function (str) end
	self.setAnimationEnabled = function (b) end
	self.setStatusFormatType = function (str) end
	
	--设置最大，最小值，同时会清空当前值
	self.setMinAndMaxValue = function (min, max) end
	
	--设定当前值，不会超出最大最小值，如果开启了动画，此时会显示动画
	self.setCurrentValue = function (float) end
	
	--返回三个number，获取当前值，最小值，最大值
	self.getValue = function () end

end

function WiHistogramBar:init( ... )
	repeat
		--读入原图root，也就是背景
		self._layRoot = ccs.GUIReader:getInstance():widgetFromJsonFile(CONST.UI_FILE)
		if not self._layRoot then break end
		self:addChild(self._layRoot, 0)
		
		--柱子
		self._layBar = self._layRoot:getChildByName(CONST.BAR_NAME)
		if not self._layBar then break end
		
		--数值
		self._labStatus = self._layRoot:getChildByName(CONST.STATUS_LAB_NAME)
		if not self._labStatus then break end
		
		--项目
		self._labItem = self._layRoot:getChildByName(CONST.ITEM_LAB_NAME)
		if not self._labItem then break end
		
		lly.logCurLocAnd("right")
		return true
	until true

	lly.logCurLocAnd("wrong")
	return false
end

function WiHistogramBar:implementFunction()
	
	--设置项目名称
	function self:setItemName(str)
		lly.ensure(str, "string")
		
		if str == nil then return end
		
		self._labItem:setString(str)
	end
	
	--动画开启关闭
	function self:setAnimationEnabled(bAnim)
		lly.ensure(bAnim, "boolean")
		
		lly._bIsAnimationEnabled = bAnim
	end

	--设置数值格式类型：1为普通，2为分秒
	function self:setStatusFormatType(nType)
		lly.ensure(nType, "number")
		if nType <= 0 or nType >= FORMAT_TYPE.MAX then
			error("wrong type")
		end

		self._nStatusFormatType = nType
	end
	
	--最大最小值
	function self:setMinAndMaxValue(fMin, fMax)
		lly.ensure(fMin, "number")
		lly.ensure(fMax, "number")
		
		if fMin >= fMax then
			error("min must less than max", 2)
		end
		
		self._fMinValue = fMin
		self._fMaxValue = fMax
	end
	
	--当前值
	function self:setCurrentValue(fCur)
		lly.ensure(fCur, "number")
		
		--确保在最大最小值以内
		if fCur < self._fMinValue then
			fCur = self._fMinValue
		elseif fCur > self._fMaxValue then
			fCur = self._fMaxValue
		end
		
		self._fCurrentValue = fCur

		--设置柱子上的文字
		if self._nStatusFormatType == FORMAT_TYPE.NORMAL then
			self._labStatus:setString(string.format("%d", self._fCurrentValue))

		elseif self._nStatusFormatType == FORMAT_TYPE.TIME then
			local minutes = math.floor(self._fCurrentValue / 60)
			local second = self._fCurrentValue % 60
			self._labStatus:setString(string.format("%d分%d秒", minutes, second))
		end
		
		
		--计算柱子的高度与总高度比例
		local fBarHeightRate = (self._fCurrentValue - self._fMinValue) / (self._fMaxValue - self._fMinValue)

		--计算当前柱子上面文字的实际高度
		local fCurHeight = fBarHeightRate * CONST.HISTOGRAM_BAR_HEIGHT + CONST.STATUS_LABEL_HEIGHT
		
		--有动画则显示动画，否则直接把柱子高度设定完成
		if self._bIsAnimationEnabled then
			--先把高度设为0，并文字隐藏后设置位置
			self._layBar:setScaleY(0)
			self._labStatus:setOpacity(0)
			self._labStatus:setPositionY(fCurHeight)
			
			--通过动画，把bar的高度变成实际的高度
			local acAddBarHeight = cc.ScaleTo:create(CONST.ACTION_MOVE_TIME, 1, fBarHeightRate)
			local acEaseIn = cc.EaseIn:create(acAddBarHeight, CONST.SPEED_RATE)
			
			--显示文字
			local acShowLabel = cc.FadeIn:create(CONST.ACTION_SHOW_TIME)
			local acT = cc.TargetedAction:create(self._labStatus, acShowLabel)

			self._layBar:runAction(cc.Sequence:create(acEaseIn, acT))
			
		else
			self._layBar:setScaleY(fBarHeightRate)
			self._labStatus:setPositionY(fCurHeight)
		end
		
	end
	
	--获得值
	function self:getValue()
		return self._fCurrentValue, self._fMinValue, self._fMaxValue
	end
end


return {
	Class = WiHistogramBar,
	FORMAT_TYPE = FORMAT_TYPE,
}