--LaStatisticsStudent.lua
--考试作业的统计层的学生继承类
--	会隐藏班级按钮和班级层
--卢乐颜
--2014.11.13

local lly = require "homework/lly/llyLuaBase"
local moLaStatisticsBase = require "homework/lly/LaStatisticsBase"
local moLogin = require "login"

lly.finalizeCurrentEnvironment()

local LaStatisticsStudent = lly.class("LaStatisticsStudent", moLaStatisticsBase.Class)

function LaStatisticsStudent:ctor()
	self.super.ctor(self)

	--载入学生统计的url
	self.STU_STATUS_URL = 'http://new.www.lejiaolexue.com/paper/handler/GetStatisticsStudent.ashx'

	self.getFinalURL_inherit = function () end --继承
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

	function self:getFinalURL_inherit()
		-- 判断身份
		local identity = moLogin.get_uid_type()

		-- if学生 then self.STU_STATUS_URL
		-- if 家长 then self.STU_STATUS_URL。。g_uid
		if identity == moLogin.STUDENT then
			return self.STU_STATUS_URL
		else
			return self.STU_STATUS_URL .. '?uid=' .. moLogin.get_subuid()
		end
	end

end

return {
	Class = LaStatisticsStudent,
}