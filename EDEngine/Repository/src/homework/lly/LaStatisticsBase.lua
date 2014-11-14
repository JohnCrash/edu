--LaStatisticsBase.lua
--考试作业的统计层的基类
--包括学生，家长，老师的统计层，
--家长和学生的是同一个，学生和老师同时继承于基础层，但学生的就是基础层，老师的多了班级的选择

require "llyLuaBase"

lly.finalizeCurrentEnvironment()

local LaStatisticsBase = lly.class("LaStatisticsBase", function () 
    return cc.Layer:create()
end)

function LaStatisticsBase:ctor()
end

function LaStatisticsBase:init( ... )
	return true
end

function LaStatisticsBase:implementFunction( ... )
	-- body
end


return LaStatisticsBase
