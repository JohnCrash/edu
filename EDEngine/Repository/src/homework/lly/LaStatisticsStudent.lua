--LaStatisticsStudent.lua
--考试作业的统计层的学生继承类
--	会隐藏班级按钮和班级层
--卢乐颜
--2014.11.13

local lly = require "homework/lly/llyLuaBase"
local moLaStatisticsBase = require "homework/lly/LaStatisticsBase"

lly.finalizeCurrentEnvironment()

local LaStatisticsStudent = lly.class("LaStatisticsStudent", moLaStatisticsBase.Class)

function LaStatisticsStudent:ctor()
	self.super.ctor(self)

	--载入学生统计的url
	self.STU_STATUS_URL = 'http://new.www.lejiaolexue.com/paper/handler/GetStatisticsStudent.ashx'

	self.getFinalURL = function () end --继承
end

function LaStatisticsStudent:init( ... )
	repeat
		if not self.super.init(self, ...) then break end

		self._layClassBtn:setVisible(false)
		self._listClass:setVisible(false)

		lly.logCurLocAnd("right")
		return true
	until true

	lly.logCurLocAnd("wrong")
	return false
end

function LaStatisticsStudent:implementFunction()
	self.super.implementFunction(self)

	function self:getFinalURL()
		if _G.hw_cur_child_id == 0 then
			return self.STU_STATUS_URL
		else
			return url .. '?uid=' .. _G.hw_cur_child_id
		end
	end

end

return {
	Class = LaStatisticsStudent,
}