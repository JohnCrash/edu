--LaStatisticsTeacher.lua
--考试作业的统计层的教师继承类
--	开启班级的选择
--	进入时，会首先刷新班级列表，点击班级项的时候才会显示该班级的统计数据
--	刷新按钮重载为刷新班级列表
--卢乐颜
--2014.11.13

local lly = require "homework/lly/llyLuaBase"
local moLaStatisticsBase = require "homework/lly/LaStatisticsBase"

local moLogin = require "login"
local moCache = require "cache"
local moLoadingbox = require "loadingbox"

lly.finalizeCurrentEnvironment()

--常量
local CONST = lly.const{
	CLASS_MODEL = "Panel_banji_all",
	CLASS_MODEL_LABEL = "Label_banji",

	CLASS_DATA_URL = "http://api.lejiaolexue.com/rest/user/%d/zone/class",
	TEACHER_STATUS_URL = "http://new.www.lejiaolexue.com/paper/handler/GetStatisticsTeacher.ashx?c_id=%d",
}

local LaStatisticsTeacher = lly.class("LaStatisticsTeacher", moLaStatisticsBase.Class)

function LaStatisticsTeacher:ctor()
	self.super.ctor(self)

	--变量
	self._layClassModel = {}
	self._labClassInModel = {}

	self._nCurrentClass = 0 --当前班级

	--方法
	self.refreshClassList = function () end --刷新班级列表

	self.processClassData = function (table) end --处理班级数据

	self.shiftClass = function (id, str) end --激活按钮的回调

	self.enter = function () end --重载

	self.getFinalURL_inherit = function () end --继承

end

function LaStatisticsTeacher:init( ... )
	repeat
		if not self.super.init(self, ...) then break end

		self._layClassBtn:setVisible(true)

		--班级按钮功能：打开列表
		self._layClassBtn:addTouchEventListener(function (sender, touchType)
			if touchType == ccui.TouchEventType.ended then
				lly.logCurLocAnd("touch")
				self._listClass:setVisible(not self._listClass:isVisible())
			end
		end)

		--首先关闭
		self._listClass:setVisible(false)

		--列表内的模型
		self._layClassModel = self._listClass:getChildByName(CONST.CLASS_MODEL)
		if not self._layClassModel then break end

		self._labClassInModel = self._layClassModel:getChildByName(CONST.CLASS_MODEL_LABEL)
		if not self._labClassInModel then break end

		--模型的点击回调，变颜色
		self._layClassModel:addTouchEventListener(function (sender, touchType)
			if touchType == ccui.TouchEventType.began then
				sender:setBackGroundColor(moLaStatisticsBase.CONST.BTN_COLOR_PRESS)

			elseif touchType == ccui.TouchEventType.ended then
				sender:setBackGroundColor(moLaStatisticsBase.CONST.BTN_COLOR_NORMAL)

				--切换班级
				self:shiftClass(sender:getTag(), sender:getName())

				--收起列表
				self._listClass:setVisible(false)

			elseif touchType == ccui.TouchEventType.canceled then
				sender:setBackGroundColor(moLaStatisticsBase.CONST.BTN_COLOR_NORMAL)
			end
		end)

		lly.logCurLocAnd("right")
		return true
	until true

	lly.logCurLocAnd("wrong")
	return false
end

function LaStatisticsTeacher:implementFunction()
	self.super.implementFunction(self)

	--刷新年级列表，载入第一个项目的数据
	function self:refreshClassList()
		if self._bBusyToRefresh then return end
		self._bBusyToRefresh = true

		moCache.request_cancel()
		local url = string.format(CONST.CLASS_DATA_URL, moLogin.uid())

		local Loadbox = moLoadingbox.open(self._wiRoot)

		moCache.request_json(url,function(t)
			self._bBusyToRefresh = false

			--关闭读档动画
			if not Loadbox:removeFromParent() then return end

			--[=[测试数据
			local j = [[
			{
				"msg": "成功", 
				"result": 0, 
				"zone": 
				[
			        {
			            "admit_time": 1376930755,
			            "apply_time": 1376930755,
			            "edu_role": 1,
			            "is_primary": 1,
			            "mode_born": 1,
			            "mode_form": 201,
			            "parent_zone_id": 126453,
			            "role": 0,
			            "status": 200,
			            "update_time": 1376915618,
			            "user_id": 125907,
			            "zone_id": 141442,
			            "zone_name": "6年级三班"
			        },{
			            "admit_time": 1376930755,
			            "apply_time": 1376930755,
			            "edu_role": 1,
			            "is_primary": 1,
			            "mode_born": 1,
			            "mode_form": 201,
			            "parent_zone_id": 126453,
			            "role": 0,
			            "status": 200,
			            "update_time": 1376915618,
			            "user_id": 125908,
			            "zone_id": 141443,
			            "zone_name": "6年级四班"
			        }
		    	]
			}
			]]

			local json = require "json"
			t = json.decode(j)
			--]=]
				
			if t and type(t) == 'table' and t.result == 0 and t.zone then
				self:processClassData(t.zone)
			else
				lly.logCurLocAnd("wrong Data")
			end
			
		end)

	end

	--遍历table生成班级按钮
	function self:processClassData(tab)
		lly.ensure(tab, "table")

		local classBtn = nil
		local bHasSetFirst = false

		for i, class in ipairs(tab) do
			--修改模型后
			self._labClassInModel:setString(class.zone_name)

			--克隆模型
			classBtn = self._layClassModel:clone()
			if not classBtn then break end

			--记录id和name
			classBtn:setTag(class.zone_id)
			classBtn:setName(class.zone_name)

			--放入列表
			self._listClass:pushBackCustomItem(classBtn)

			--载入第一个班级
			if bHasSetFirst == false then
				self:shiftClass(class.zone_id, class.zone_name)
				bHasSetFirst = true
			end
		end
	end

	function self:shiftClass(id, str)
		lly.ensure(id, "number")
		lly.ensure(str, "string")

		--把class按钮上的字改成此按钮上文字
		self._labClassInBtn:setString(str)

		--设置当前班级
		self._nCurrentClass = id

		--根据当前按钮表示的班级，载入班级数据
		self:refresh()
	end

	--重载
	function self:enter()
		if self._bIsFirstEnter == true then
			self:refreshClassList()
			self._bIsFirstEnter = false
		end
	end

	function self:getFinalURL_inherit()
		return string.format(CONST.TEACHER_STATUS_URL, self._nCurrentClass)
	end
end

return {
	Class = LaStatisticsTeacher,
	CONST = CONST,
}