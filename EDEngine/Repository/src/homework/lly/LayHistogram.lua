---
--LayHistogram.lua
--柱状图
--	可放置最少6个，最多12个项目，少于6个依然按照6个项目的位置排列
--	需要先录入每个项目，再使用show命令才会在图上显示柱子
--	每个项目可以带多个数据，按顺序为1、2、3组等，可以使用shift进行切换
--	show的时候会自动根据项目的最大最小值分成合适的多个段位，因此写出来的值会稍有修整
--卢乐颜
--2014.11.13

local lly = require "llyLuaBase"
local moWiHistogramBar = require "homework/lly/WiHistogramBar"

lly.finalizeCurrentEnvironment()

--项目的结构体，有名称和其带有的所有数据
local StruItem = lly.struct( function ()
	return {
	name = "none",
	values = {},
	}
end)

--每种统计类别的属性的结构体
local StruCategoryAttr = lly.struct( function ()
	return {
		type = 1, --数值类型
		min = 1,
		max = 100,
	}
end)

--值的类型 枚举
local VALUE_TYPE = {
	INTEGER = 1, --整数
	FLOAT = 2, --浮点
	TIME = 3, --时间
	MAX = 4,
}

local LayHistogram = lly.class("LayHistogram", function () 
    return ccui.Layout:create()
end)

function LayHistogram:ctor()
	--常量
	self.INDICATOR_COUNT = 6
	self.MAX_ITEM_COUNT = 12

	self.UI_FILE = "homework/lly/LayHistogram/zhu_zhuang_tu.ExportJson"
	self.TIME_BTN_NAME = "CheckBox_1"
	self.COUNT_BTN_NAME = "CheckBox_2"
	self.BG_NAME = "Image_BG"

	--变量
	self._wiRoot = {} --根
	self._arlabIndicator = lly.array(self.INDICATOR_COUNT) --图标左侧的六个指标
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

	--添加项目，可携带多个数据，反应不同的类别
	self.addItem = function (strItem, value, ...) end 

	--切换统计类别，如果在录入项目时候输入多个数值，则在此切换显示的类别，然后需要show
	self.shiftCategory = function (index) end

	--清空项目
	self.clearAllItems = function () end

	--显示
	self.show = function () end

	--选中时回调
	self.selectCategory_cb = function (sender, eventType) end

end

function LayHistogram:init( ... )
	repeat
		--读入原图root
		self._wiRoot = ccs.GUIReader:getInstance():widgetFromJsonFile(self.UI_FILE)
		if not self._wiRoot then break end
		self:addChild(self._wiRoot, 0)
		
		--数值标识
		for i = 1, self.INDICATOR_COUNT do
			self._arlabIndicator[i] = self._wiRoot:getChildByTag(i)
			if not self._arlabIndicator[i] then break end
		end

		--底图
		self._layBG = self._wiRoot:getChildByName(self.BG_NAME)
		if not self._layBG then break end

		--按钮
		self._ckbHomeworkCount = self._wiRoot:getChildByName(self.COUNT_BTN_NAME)
		if not self._ckbHomeworkCount then break end
		self._ckbHomeworkCount:addEventListener(self.selectCategory_cb)
		self._arckb[#self._arckb + 1] = self._ckbHomeworkCount --注册

		self._ckbTimeCosting = self._wiRoot:getChildByName(self.TIME_BTN_NAME)
		if not self._ckbTimeCosting then break end
		self._ckbTimeCosting:addEventListener(self.selectCategory_cb)
		self._arckb[#self._arckb + 1] = self._ckbTimeCosting --注册	
		
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
				error("wrong type", 2)
			end

			if self._arStruCategoryAttr[i] == nil then --生成新的结构体
				self._arStruCategoryAttr[i] = StruCategoryAttr:create()
			end

			self._arStruCategoryAttr[i].type = arg[i]
		end

		
	end

	function self:addItem(strItem, ...)
		lly.ensure(strItem, "string")
		local arg = {...}
		for i = 1, #arg do
			lly.ensure(arg[i], "number")
		end

		--如果超出12项就不能再添加
		if #self._arStructItem >= self.MAX_ITEM_COUNT then
			lly.log("item is full")
			return
		end

		--录入
		self._arStructItem[#self._arStructItem + 1] = StruItem:create()
		self._arStructItem[#self._arStructItem].name = strItem
		self._arStructItem[#self._arStructItem].values = arg

		--获得最大最小值
		for i = 1, #arg do
			if self._arStruCategoryAttr[i] == nil then --生成新的结构体
				self._arStruCategoryAttr[i] = StruCategoryAttr:create()
			end

			if arg[i] > self._arStruCategoryAttr[i].max then
				self._arStruCategoryAttr[i].max = arg[i]
			elseif arg[i] < self._arStruCategoryAttr[i].min then
				self._arStruCategoryAttr[i].min = arg[i]
			end
		end

	end

	function self:shiftCategory(index)
		lly.ensure(index, "number")
		if index <= 0 or index >= #self._arStruCategoryAttr then
			error("wrong index", 2)
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
		
		local nItemDistance = self._layBG:getContentSize() / (nItemCount + 1)

		--把已有的柱子放对位置，录入名称，如果不够就生成，如果多余就隐藏
		for i = 1, #self._arStructItem do

			if self._arwiItem[i] == nil then --没有就生成
				self._arwiItem[i] = moWiHistogramBar.Class:create()
				if not self._arwiItem[i] then return end
			else
				self._arwiItem[i]:setVisible(true)
			end

			self._arwiItem[i]:setPosition(cc.p(0, nItemDistance * i))
			self._arwiItem[i]:setItemName(self._arStructItem[i].name)
		end

		for i = #self._arStructItem + 1, self.MAX_ITEM_COUNT do --剩下不用的就隐藏
			if self._arwiItem[i] == nil then break end
			self._arwiItem[i]:setVisible(false)
		end

		--计算柱子的最小值，最大值，并录入柱子的属性中
		--根据不同种类的值，设置自己和柱子的值
		local category = self._arStruCategoryAttr[self._nCurrentCategory]
		local min = category.min
		local max = category.max

		if category.type == VALUE_TYPE.INTEGER then
			--整数
			local MIN_DIFFERENCE = 10 --指标之间的最小差

			min = min - (min % MIN_DIFFERENCE) -- 36 - (36 % 10) = 30
			max = max - (max % MIN_DIFFERENCE) + MIN_DIFFERENCE -- 36 - (36 % 10) + 10 = 40

			for i = 1, #self._arStructItem do --录入柱子，并设置格式
				self._arwiItem[i]:setMinAndMaxValue(min, max)
				self._arwiItem[i]:setStatusFormatType(moWiHistogramBar.FORMAT_TYPE.NORMAL)
			end
			
			for i = 1, self.INDICATOR_COUNT do --把最小值最大值分配到6个指示中
				local str = string.format("%d", (min + (max - min) * (i - 1)))
				self._arlabIndicator:setString(str)
			end

		elseif category.type == VALUE_TYPE.FLOAT then
			--浮点

		elseif category.type == VALUE_TYPE.TIME then
			--时间（多少分钟多少秒）录入时是纯秒数
			local MIN_DIFFERENCE = 60 --指标之间的最小差，一分钟

			min = min - (min % MIN_DIFFERENCE) -- 136 - (136 % 60) = 120 2分
			max = max - (max % MIN_DIFFERENCE) + MIN_DIFFERENCE -- 36 - (36 % 60) + 60 = 180 3分

			for i = 1, #self._arStructItem do --录入柱子，并设置格式
				self._arwiItem[i]:setMinAndMaxValue(min, max)
				self._arwiItem[i]:setStatusFormatType(moWiHistogramBar.FORMAT_TYPE.TIME)
			end

			local str = nil
			local nTime = nil
			local nSecond = nil
			
			for i = 1, self.INDICATOR_COUNT do --把最小值最大值分配到6个指示中
				nTime = min + (max - min) * (i - 1)
				nSecond = nTime % 60
				str = string.format("%d\"%d", (nTime - nSecond) / 60, nSecond)
				self._arlabIndicator:setString(str)
			end

		end

		--录入柱子的当前值，同时会进行动画
		for i = 1, #self._arStructItem do
			self._arwiItem[i]:setCurrentValue(self._arStructItem.values[self._nCurrentCategory])
		end
	end

	function self.selectCategory_cb(sender, eventType)
		if eventType == ccui.CheckBoxEventType.selected then
			lly.log("select")
			
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
			--self:shiftCategory(sender:getTag()) 
			--self:show() --显示
		end
		
	end

end

return {
	Class = LayHistogram,
	StruItem = StruItem,
	StruCategoryAttr = StruCategoryAttr,
	VALUE_TYPE = VALUE_TYPE,
}
