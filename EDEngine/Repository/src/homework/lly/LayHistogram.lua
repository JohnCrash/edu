---
--LayHistogram.lua
--柱状图
--	可放置最少6个，最多12个项目，少于6个依然按照6个项目的位置排列
--	需要先录入每个项目，再使用show命令才会在图上显示柱子
--	每个项目可以带多个数据，按顺序为1、2、3组等，可以使用shift进行切换
--	show的时候会自动根据项目的最大最小值分成合适的多个段位，因此写出来的值会稍有修整
--卢乐颜
--2014.11.13

local lly = require "homework/lly/llyLuaBase"
local moWiHistogramBar = require "homework/lly/WiHistogramBar"

lly.finalizeCurrentEnvironment()

--项目的结构体，有名称和其带有的所有数据
local StruItem = lly.struct( function ()
	return {
	name = "none",
	values = {},
	index = 0,
	}
end)

--每种统计类别的属性的结构体
local StruCategoryAttr = lly.struct( function ()
	return {
		type = 1, --数值类型
		min = 99999999,
		max = -99999999,
	}
end)

--值的类型 枚举
local VALUE_TYPE = {
	INTEGER = 1, --整数
	FLOAT = 2, --浮点
	TIME = 3, --时间
	MAX = 4,
}

--常量
local CONST = lly.const{
	INDICATOR_COUNT = 6,
	MAX_ITEM_COUNT = 12,

	UI_FILE = "homework/lly/LayHistogram/zhu_zhuang_tu.ExportJson",
	TIME_BTN_NAME = "CheckBox_1",
	COUNT_BTN_NAME = "CheckBox_2",
	BG_NAME = "Image_BG",
}

local LayHistogram = lly.class("LayHistogram", function () 
    return ccui.Layout:create()
end)

function LayHistogram:ctor()
	--变量
	self._wiRoot = {} --根
	self._arlabIndicator = lly.array(CONST.INDICATOR_COUNT) --图标左侧的六个指标
	self._layBG = {} --底图,用于分配项目
	self._arwiItem = {} --项目，1到12个


	--按钮，切换不同统计类别
	self._arckb = {} --为了变成单选，所有的checkbox都要注册到一个列表里面
	self._ckbHomeworkCount = {} --作业次数
	self._ckbTimeCosting = {} --作业用时

	--属性
	self._arStruCategoryAttr = {}
	self._arStructItem = {}
	self._nCurrentCategory = 1 --当前类别

	--方法

	--设置多个类别的值类型，包括整数，浮点数和时间
	self.setValueType = function (type, ...) end

	--添加项目，可携带多个数据，反应不同的类别，index表示item的序号，序号小的在前面
	self.addItem = function (strItem, valueTable, index) end 

	--切换统计类别，如果在录入项目时候输入多个数值，则在此切换显示的类别，然后需要show
	self.shiftCategory = function (index) end

	--清空项目
	self.clearAllItems = function () end

	--显示
	self.show = function () end

	--选中时回调
	self.selectCategory_cb = function (sender, eventType) end

	--获得根节点
	self.getRootWidget = function () end

end

function LayHistogram:init( ... )
	repeat
		--读入原图root
		self._wiRoot = ccs.GUIReader:getInstance():widgetFromJsonFile(CONST.UI_FILE)
		if not self._wiRoot then break end
		self:addChild(self._wiRoot, 0)
		
		--数值标识
		local str = nil
		for i = 1, CONST.INDICATOR_COUNT do
			str = string.format("Label_%d", i)
			self._arlabIndicator[i] = self._wiRoot:getChildByName(str)
			if not self._arlabIndicator[i] then break end
		end

		--底图
		self._layBG = self._wiRoot:getChildByName(CONST.BG_NAME)
		if not self._layBG then break end

		--按钮
		self._ckbTimeCosting = self._wiRoot:getChildByName(CONST.TIME_BTN_NAME)
		if not self._ckbTimeCosting then break end
		self._ckbTimeCosting:addEventListener(self.selectCategory_cb)
		self._arckb[#self._arckb + 1] = self._ckbTimeCosting --注册	

		self._ckbHomeworkCount = self._wiRoot:getChildByName(CONST.COUNT_BTN_NAME)
		if not self._ckbHomeworkCount then break end
		self._ckbHomeworkCount:addEventListener(self.selectCategory_cb)
		self._arckb[#self._arckb + 1] = self._ckbHomeworkCount --注册
		
		lly.logCurLocAnd("right")
		return true
	until true

	lly.logCurLocAnd("wrong")
	return false
end

function LayHistogram:implementFunction()

	function self:setValueType(...)
		local arg = {...}
	
		for i = 1, #arg do
			lly.ensure(arg[i], "number") --检测
			if arg[i] <= 0 or arg[i] >= VALUE_TYPE.MAX then
				lly.error("wrong type", 2)
			end

			if self._arStruCategoryAttr[i] == nil then --生成新的结构体
				self._arStruCategoryAttr[i] = StruCategoryAttr:create()
			end

			self._arStruCategoryAttr[i].type = arg[i]
		end		
	end

	function self:addItem(strItem, valueTable, index)
		lly.ensure(strItem, "string")
		lly.ensure(valueTable, "table")
		lly.ensure(index, "number")

		--如果超出12项就不能再添加
		if #self._arStructItem >= CONST.MAX_ITEM_COUNT then
			lly.log("item is full")
			return
		end

		--录入
		local item = StruItem:create()
		item.name = strItem
		item.values = valueTable
		item.index = index

		--根据规则调整顺序
		local bIsInsert = false
		for i, v in ipairs(self._arStructItem) do
			if item.index < v.index then
				table.insert(self._arStructItem, i, item)
				bIsInsert = true
				break
			end
		end

		if bIsInsert == false then
			self._arStructItem[#self._arStructItem + 1] = item
		end

		--获得最大最小值
		for i = 1, #valueTable do
			if self._arStruCategoryAttr[i] == nil then --生成新的结构体
				self._arStruCategoryAttr[i] = StruCategoryAttr:create()
				self._arStruCategoryAttr[i].max = valueTable[i]
				self._arStruCategoryAttr[i].min = valueTable[i]
			else
				if valueTable[i] > self._arStruCategoryAttr[i].max then
					self._arStruCategoryAttr[i].max = valueTable[i]
				elseif valueTable[i] < self._arStruCategoryAttr[i].min then
					self._arStruCategoryAttr[i].min = valueTable[i]
				end
			end
		end

	end

	function self:shiftCategory(index)
		lly.ensure(index, "number")
		if index <= 0 or index > #self._arStruCategoryAttr then
			lly.error("wrong index", 2)
		end

		self._nCurrentCategory = index
	end

	function self:clearAllItems()
		self._arStruCategoryAttr = {}
		self._arStructItem = {}
		self._nCurrentCategory = 1
	end

	function self:show()
		--计算柱子的位置，根据项目数平均分配在底图上
		local nItemCount = #self._arStructItem
		if nItemCount < 6 then nItemCount = 6 end --最少按6个排列
		
		local nItemDistance = self._layBG:getContentSize().width / (nItemCount + 1)

		--把已有的柱子放对位置，录入名称，如果不够就生成，如果多余就隐藏
		for i = 1, #self._arStructItem do
			if self._arwiItem[i] == nil then --没有就生成
				self._arwiItem[i] = moWiHistogramBar.Class:create()
				if not self._arwiItem[i] then return end
				self._layBG:addChild(self._arwiItem[i], 2)
			else
				self._arwiItem[i]:setVisible(true)
			end

			self._arwiItem[i]:setPosition(cc.p(nItemDistance * i, 0))
			self._arwiItem[i]:setItemName(self._arStructItem[i].name)
		end

		for i = #self._arStructItem + 1, CONST.MAX_ITEM_COUNT do --剩下不用的就隐藏
			if self._arwiItem[i] == nil then break end
			self._arwiItem[i]:setVisible(false)
		end

		--计算柱子的最小值，最大值，并录入柱子的属性中
		--根据不同种类的值，设置自己和柱子的值
		local category = self._arStruCategoryAttr[self._nCurrentCategory]
		local min = category.min
		local max = category.max

		if min >= max and min > 0 then min = 0 end --如果只有一个月，则min，max会一样，此时把min变成0
		lly.logCurLocAnd("min %d, max %d", min, max)

		if category.type == VALUE_TYPE.INTEGER then
			lly.log("int")
			--整数
			local MIN_DIFFERENCE = 10 --指标之间的最小差

			min = min - (min % MIN_DIFFERENCE) -- 36 - (36 % 10) = 30
			max = max - (max % MIN_DIFFERENCE) + MIN_DIFFERENCE -- 36 - (36 % 10) + 10 = 40
			lly.log("real min %d, max %d", min, max)

			for i = 1, #self._arStructItem do --录入柱子，并设置格式
				self._arwiItem[i]:setMinAndMaxValue(min, max)
				self._arwiItem[i]:setStatusFormatType(moWiHistogramBar.FORMAT_TYPE.NORMAL)
			end
			
			for i = 1, CONST.INDICATOR_COUNT do --把最小值到最大值分成5份分配到6个指示中
				local str = string.format("%d", (min + (max - min) * (i - 1) * 0.2))
				self._arlabIndicator[i]:setString(str)
			end

		elseif category.type == VALUE_TYPE.FLOAT then
			--浮点

		elseif category.type == VALUE_TYPE.TIME then
			lly.log("time")
			--时间（多少分钟多少秒）录入时是纯秒数
			local MIN_DIFFERENCE = 150 --指标之间的最小差，一分钟

			min = min - (min % MIN_DIFFERENCE) -- 136 - (136 % 60) = 120 2分
			max = max - (max % MIN_DIFFERENCE) + MIN_DIFFERENCE -- 36 - (36 % 60) + 60 = 180 3分
			lly.log("real min %d, max %d", min, max)

			for i = 1, #self._arStructItem do --录入柱子，并设置格式
				self._arwiItem[i]:setMinAndMaxValue(min, max)
				self._arwiItem[i]:setStatusFormatType(moWiHistogramBar.FORMAT_TYPE.TIME)
			end

			local str = nil
			local nTime = nil
			local nSecond = nil
			
			for i = 1, CONST.INDICATOR_COUNT do --把最小值最大值分配到6个指示中
				nTime = min + (max - min) * (i - 1) * 0.2
				nSecond = nTime % 60
				str = string.format("%d\"%d", (nTime - nSecond) / 60, nSecond)
				self._arlabIndicator[i]:setString(str)
			end

		end

		--录入柱子的当前值，同时会进行动画
		for i = 1, #self._arStructItem do
			self._arwiItem[i]:setCurrentValue(self._arStructItem[i].values[self._nCurrentCategory])
			lly.log("set value " .. i .. " is " .. self._arStructItem[i].values[self._nCurrentCategory])
		end
	end

	function self.selectCategory_cb(sender, eventType)
		if eventType == nil then
			eventType = ccui.CheckBoxEventType.selected
		end

		if eventType == ccui.CheckBoxEventType.selected then
			lly.log("select")

			if sender == nil then
				sender = self._arckb[1]
				sender:setSelectedState(true)
			end
			
			--取消其他选中
			for i, v in ipairs(self._arckb) do
				if v ~= sender then
					v:setSelectedState(false)
					v:setTouchEnabled(true)
				end
			end

			--自己选中
			sender:setTouchEnabled(true)

			--自己不可以再被点击
			sender:setTouchEnabled(false) 

			--切换项
			self:shiftCategory(sender:getTag()) 
			self:show() --显示
		end
		
	end

	function self:getRootWidget()
		return self._wiRoot
	end
end

return {
	Class = LayHistogram,
	StruItem = StruItem,
	StruCategoryAttr = StruCategoryAttr,
	VALUE_TYPE = VALUE_TYPE,
}
