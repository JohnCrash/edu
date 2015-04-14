local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local selecterUUID = "d2cec3976ce41e69c1bde08fb032af7b"
local calcUUID = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"
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
		factory.importByProgressBox({calcUUID,selecterUUID,blockUUID},
		function(b,msg)
			if b then
				self._calcbox = factory.create(blockUUID)
				self._selecter = factory.create(selecterUUID)
				self:initGame()
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
	loadLevel=function(self,levelJson)
		if not levelJson then return end
	end,
	initBaseScene = function(self,data)
		
	end,
	initScene = function(self,data)
		self:initBaseScene()
		
		--[[
		self._selecter:reset{colum=5,raw=2}
		math.randomseed(os.time())
		for i = 1,5 do
			local o = factory.create(blockUUID)
			o:doAction(tostring(math.random(0,9)))
			self._selecter:insert(i,1,o)
		end
		local o = factory.create(blockUUID)
		o:doAction('+')
		self._selecter:insert(1,2,o)
		o = factory.create(blockUUID)
		o:doAction('-')
		self._selecter:insert(2,2,o)
		o = factory.create(blockUUID)
		o:doAction('*')
		self._selecter:insert(3,2,o)
		o = factory.create(blockUUID)
		o:doAction('/')
		self._selecter:insert(4,2,o)
		o = factory.create(blockUUID)
		o:doAction('=')
		self._selecter:insert(5,2,o)	

		local ss = uikits.getDR()
		local selecter_size = self._selecter:getSize()
		self:addChild(self._selecter)
		--]]
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
