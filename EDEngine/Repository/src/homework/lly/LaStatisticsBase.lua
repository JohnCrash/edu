---
--LaStatisticsBase.lua
--考试作业的统计层的基类
--	包括学生，家长，老师的统计层，
--	家长和学生的是同一个，学生和老师同时继承于基础层，但学生的就是基础层，老师的多了班级的选择
--卢乐颜
--2014.11.13

local lly = require "llyLuaBase"
local moLayHistogram = require "homework/lly/LayHistogram"

local moUIKits = require "uikits"
local moLoadingbox = require "loadingbox"
local moCache = require "cache"
local moTopics = require "homework/topics"

lly.finalizeCurrentEnvironment()

local LaStatisticsBase = lly.class("LaStatisticsBase", function () 
    return cc.Layer:create()
end)

function LaStatisticsBase:ctor()
	--常量
	self.UI_FILE = "homework/lly/LaStatus/statistics.ExportJson"

	self.BTN_CLASS = "Panel_27"
	self.LAB_CLASS = "Label_banji_xiala"
	self.LIST_CLASS = "ListView_banji"

	self.LEFT_TOKEN = "Button_zuo"
	self.RIGHT_TOKEN = "Button_you"

	self.LIST_COURSE = "ListView_kemu"
	self.COURSE_MODEL = "Panel_course"
	self.COURSE_MODEL_LABEL = "Label_15"
	self.COURSE_TOKEN = "Image_xuanzhong"

	self.REFRESH_BTN = "Button_95"

	self.UI_WIDTH_OF_3_4 = 1440 --4:3时是1440
	self.UI_WIDTH_OF_16_9 = 1920 --16:9时的宽度是1920

	self.BTN_COLOR_PRESS = cc.c3b(200, 200, 200)
	self.BTN_COLOR_NORMAL = cc.c3b(255, 255, 255)

	--变量
	self._wiRoot = {} --根

	self._layClassBtn = {} -- 用做班级选择按钮的层
	self._labClassInBtn = {} --按钮上的文字
	self._listClass = {} --班级选择列表

	self._imageLeft = {} --表示左边还有控件的标识
	self._imageRight = {} --表示右边还有控件的标识

	self._listCourse = {} --科目列表
	self._layCourseModel = {} --科目的模型
	self._labCourse = {} --科目的文字
	self._laySelected = {} --表示此科目已经被选择上的标识

	self._btnRefresh = {} --刷新按钮

	self._layHistogram = {} --柱状图

	--数据
	self._bIsFirstEnter = true --是否是第一次进入
	self._bBusyToRefresh = false --是否正在刷新，而不能做别的事情或再次刷新

	self._nCurrentBtnTag = 0 --当前激活了的课程按钮的tag

	--从服务器读取的json解析出来的table
	self._tabData = {} 

	--方法
	self.refresh = function () end --刷新，进入，切换班级和点刷新按钮时调用

	self.processStatusData = function (t) end --处理网上发来并解析出的数据

	self.activeCourseBtn = function (btn) end --激活科目按钮

	self.setHistogram = function (number) end --根据科目编号生成柱状图

	self.enter = function () end --进入统计层，第一次时会调用refresh

	self.getFinalURL = function () error("need inherit")end --得到最终的URL
end

function LaStatisticsBase:init( ... )
	repeat
		--读入原图root
		self._wiRoot = ccs.GUIReader:getInstance():widgetFromJsonFile(self.UI_FILE)

		if not self._wiRoot then break end
		self:addChild(self._wiRoot, 0)

		--根据不同的屏幕比例，调整原图 16:9为原图不用调整
		local factor = moUIKits.get_factor()
		if factor == moUIKits.FACTOR_3_4 then --3：4
			self._wiRoot:setContentSize(
				cc.size(self.UI_WIDTH_OF_3_4, self._wiRoot:getContentSize().height))

			lly.log("4:3")
		end

		--控件
		self._layClassBtn = self._wiRoot:getChildByName(self.BTN_CLASS)
		if not self._layClassBtn then break end

		self._labClassInBtn = self._layClassBtn:getChildByName(self.LAB_CLASS)
		if not self._labClassInBtn then break end

		self._listClass = self._wiRoot:getChildByName(self.LIST_CLASS)
		if not self._listClass then break end

		---
		self._imageLeft = self._wiRoot:getChildByName(self.LEFT_TOKEN)
		if not self._imageLeft then break end

		self._imageRight = self._wiRoot:getChildByName(self.RIGHT_TOKEN)
		if not self._imageRight then break end

		self._listCourse = self._wiRoot:getChildByName(self.LIST_COURSE)
		if not self._listCourse then break end

		--实现列表控制左右指示
		self._listCourse:addScrollViewEventListener(function (sender, srollEventType)
			--移动时显示两个指示，到最左面了就把表示左面还有的标志隐藏，右边同理
			if srollEventType == ccui.ScrollviewEventType.scrolling then
				self._imageLeft:setVisible(true)
				self._imageRight:setVisible(true)

			elseif srollEventType == ccui.ScrollviewEventType.scrollToLeft then
				lly.logCurLocAnd("left")
				self._imageLeft:setVisible(false)

			elseif srollEventType == ccui.ScrollviewEventType.scrollToRight then
				lly.logCurLocAnd("right")
				self._imageRight:setVisible(false)
			end
		end)

		--列表内控件和控件激活指示
		self._layCourseModel = self._wiRoot:getChildByName(self.COURSE_MODEL)
		if not self._layCourseModel then break end

		--点击，变色，激活当前按钮
		self._layCourseModel:addTouchEventListener(function (sender, eventType)

			if touchType == ccui.TouchEventType.ended then
				sender:setBackGroundColor(self.BTN_COLOR_PRESS)

			elseif touchType == ccui.TouchEventType.ended then
				lly.logCurLocAnd("touch")
				sender:setBackGroundColor(self.BTN_COLOR_NORMAL)
				self:activeCourseBtn(sender)
				
			elseif touchType == ccui.TouchEventType.canceled then
				sender:setBackGroundColor(self.BTN_COLOR_NORMAL)
			end
		end)

		self._labCourse = self._layCourseModel:getChildByName(self.COURSE_MODEL_LABEL)
		if not self._labCourse then break end

		self._laySelected = self._wiRoot:getChildByName(self.COURSE_TOKEN)
		if not self._laySelected then break end

		---
		self._btnRefresh = self._wiRoot:getChildByName(self.REFRESH_BTN)
		if not self._btnRefresh then break end

		--刷新按钮的功能
		self._btnRefresh:addTouchEventListener(function (sender, touchType)
			if touchType == ccui.TouchEventType.ended then
				lly.logCurLocAnd("touch")
				self.refresh()
			end
		end)

		--载入柱状图层
		self._layHistogram = moLayHistogram.Class:create()
		if not self._layHistogram then break end

		--根据不同的长宽比，确定柱状图的位置和缩放
		local scale = nil
		local height = nil
		if factor == moUIKits.FACTOR_3_4 then --3：4
			scale = self.UI_WIDTH_OF_3_4 / self.UI_WIDTH_OF_16_9
			height = self._layHistogram:getContentSize().width * (1 - scale) / 2
		else
			scale = 1
			height = 0
		end

		self._layHistogram:setScale(scale)
		self._layHistogram:setPosition(cc.p(0, height))

		--设置柱状图每个类别的数据类型（1整数 2时间）
		self._layHistogram:setValueType(
			moLayHistogram.VALUE_TYPE.INTEGER,
			moLayHistogram.VALUE_TYPE.TIME)

		self:addChild(self._layHistogram, 10) --班级列表为20，其他为0，放在两个中间
			
		
		lly.logCurLocAnd("right")
		return true
	until true

	lly.logCurLocAnd("wrong")
	return false
end

function LaStatisticsBase:implementFunction()
	--刷新控件，从网上获取到该班级的统计数据，加载到控件上
	function self:refresh()
		if self._bBusyToRefresh then return end
		self._bBusyToRefresh = true

		--读档动画
		local loadbox = moLoadingbox.open(self)

		--设置url
		local send_url = self:getFinalURL()
		
		moCache.request_cancel()
		moCache.request_json( send_url, function(t)
			self._bBusyToRefresh = false

			--关闭读档动画
			if not loadbox:removeFromParent() then return end

			if t and type(t) == 'table' then
				self:processStatusData(t)
			end
		end)
	end

	function self:processStatusData(table)
		--把json解析出来的table以学科>月份>数据分类，
		--内部数据按：时间，次数 排列，并记录
		for i, v in ipairs(table_name) do
			if self._tabData[v.course] == nil then
				self._tabData[v.course] = {}
			end

			self._tabData[v.course][v.year_month] = {
				v.cnt_times, --作业时间
				v.cnt_home_work,} --作业次数
		end

		--根据导入的学科，生成科目按钮
		local courseBtn = nil
		local bHasSetFirst = false
		local strCourse = nil
		for course, v in pairs(self._tabData) do
			--改变模型
			strCourse = moTopics.course_map[course]

			--为了防止过长，取最后4个utf8的汉字作为标题
			strCourse = string.sub(strCourse, -12, -1)

			self._labCourse:setString(strCourse)

			--克隆模型
			courseBtn = self._layCourseModel:clone()
			if not courseBtn then break end

			--按钮自己记录学科编号
			courseBtn:setTag(course)

			--加入列表
			self._listCourse:pushBackCustomItem(courseBtn)

			if not bHasSetFirst then --激活第一个学科
				self:activeCourseBtn(courseBtn)			
				bHasSetFirst = true
			end
		end

		--起始在最左边，所以左边肯定没有超出的控件
		self._imageLeft:setVisible(false) 

		--如果生成的科目数没有超出显示区域，则不显示左右指示标，否则显示右指示标
		if self._listCourse:getInnerContainerSize().width > 
			self._listCourse:getContentSize().width then
			self._imageRight:setVisible(true)
		else
			self._imageRight:setVisible(false)
		end
		
	end	

	function self:activeCourseBtn(btn)
		--如果已经被激活则不能再次激活
		local courseNumber = btn:getTag()
		if self._nCurrentBtnTag == courseNumber then return end

		--把激活指示移动到当前按钮上
		if self._laySelected:getParent() ~= nil then
			self._laySelected:removeFromParent()
		end

		btn:addChild(self._laySelected, 5)

		--根据tag中所记录的科目编号，设置柱状图		
		self:setHistogram(courseNumber)

		--记录
		self._nCurrentBtnTag = courseNumber
	end

	function self:setHistogram(number)
		self._layHistogram:clearAllItems()

		local tabCourse = self._tabData[number]
		for str, tabData in pairs(tabCourse) do
			--处理年月的字符串 201411 to 14年11月
			str = string.sub(str, 3, 4) .. '年' .. string.sub(str, 5, -1) .. '月'

			--增加项
			self._layHistogram:addItem(str, unpack(tabData))
		end

		--激活第一个按钮
		self._layHistogram:_setAllCheckBoxUnselected() --先让所有的复选框都取消选择
		self._layHistogram._ckbHomeworkCount:setTouchEnabled(false) --自己不可以再被点击
		self._layHistogram._ckbHomeworkCount:setSelectedState(true)

		self._layHistogram:shiftCategory(1) --切换到第一项
		self._layHistogram:show() --显示
	end

	function self:enter()
		if self._bIsFirstEnter == true then
			self.refresh()
			self._bIsFirstEnter = false
		end
	end
end

return {
	Class = LaStatisticsBase
}
