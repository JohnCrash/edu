local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"

--[[
	将一个游戏场景和关卡数据关联上
--]]
return {
	init=function(self)
	end,
	release=function(self)
	end,
	loadLevel=function(self,json)
	end,
	buildLevel=function(self,notify)
	end,
	test = function(self)
		print("Level Scene test")
		super.test(self)
	end,
}
