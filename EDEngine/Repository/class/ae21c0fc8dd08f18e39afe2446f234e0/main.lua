local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"
local json = require "json-c"

local uuid = {
	block = "e0624a7d0d7a6c3d4a3439588ed98fb0",
	selecter = "d2cec3976ce41e69c1bde08fb032af7b",
	calcbox = "2c718eeb0fb6c1cdfcf03fd20c1df0ba",
	parallaxFeild = "1f113e04275489b8ee542deb43873498",
}
--[[
	通过摆放正确的方块，过河
	数据类型
	{
		"level":[
			{
			},
			{
			}
		]
	}
--]]
return {
	init=function(self)
		factory.importByProgressBox(self:depends(),
		function(b,msg)
			if b then
				self:initScene()
			else
				local box = factory.create(base.MessageBox)
				box:open{caption='加载失败',text={
				"确定退出",tostring(msg)},button=1,
				onClick=function(idx)
					self:pop()
				end}
			end
		end)
	end,
	depends=function(self)
		local t = {}
		for i,v in pairs(uuid) do
			table.insert(t,v)
		end
		return t
	end,
	loadLevelByJson=function(self,t)
		if t and t.section then
			self._level = t
		else
			kits.log("ERROR "..self:getClassid().." loadLevelByJson")
			kits.log("	loadLevelByJson t = nil")
		end
	end,
	loadLevelByFile=function(self,levelJson)
		local file = kits.read_file(levelJson)
		if file then
			local t = json.decode(file)
			self:loadLevelByJson(t)
		else
			kits.log("ERROR "..self:getClassid().." loadLevelByFile")
			kits.log("	Can not read file "..tostring(levelJson))
		end
	end,
	initParallax = function(self)
		self._level = self._level or {}
		self._skin = self._level.skin or 1
		if self._skin==1 then
			self._parallax = factory.create(uuid.parallaxFeild)
		end
		if self._parallax then
			self:addChild(self._parallax)
		else
			kits.log("ERROR initParallax fail,self._parallax = nil")
			kits.log("	skin = "..tostring(self._skin))
		end
	end,
	initScene = function(self)
		self:initParallax()
	end,
	release=function(self)
	end,
	loadLevel=function(self,json)
	end,
	buildLevel=function(self,notify)
	end,	
	test=function(self)
		print("24点")
		super.test(self)
	end,
}
