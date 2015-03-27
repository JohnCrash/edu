local uikits = require "uikits"
local kits = require "kits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local boxUUID = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		local function drop()
			local obj = factory.create(blockUUID)
			obj:doAction(string.sub(self._sequence,self._index,self._index))
			self._index=self._index+1
			if self._index > #self._sequence then
				self._index = 1
			end
			local p = self._blocks[#self._blocks]:getPosition()
			table.insert(self._blocks,obj)
			p.x=p.x+128
			self:addChild(obj)
			obj:setPosition(p)	
			obj:setSize(cc.size(128,128))			
			for i,v in pairs(self._blocks) do
				local p = v:getPosition()
				p.x = p.x - 128
				v:setPosition(p)
			end
			local p = self._blocks[1]:getPosition()
			p.y = p.y - 1000
			obj = self._blocks[1]
			local function removeMe(node)
				print("remove me")
				obj:removeFromParent()
			end
			obj:ccNode():runAction(
				cc.Sequence:create(
					cc.MoveTo:create(1,p),
					cc.CallFunc:create(removeMe))
				)
			table.remove(self._blocks,1)
		end
		local function init()
			self:initSequence()
			local colum = 6
			local x = 0
			local y = 0
			self._blocks = {}
			for i=self._index,self._index+colum do
				local c = string.sub(self._sequence,i,i)
				local obj = factory.create(blockUUID)
				self:addChild( obj )
				table.insert(self._blocks,obj)
				obj:doAction(c)
				obj:setPosition(cc.p(x,y))
				obj:setSize(cc.size(128,128))
				x = x + 128
			end
			self._index = self._index+colum
		end
		self:addAction{name="drop",script=drop}
		self:addAction{name="init",script=init}
		self:setDefaultAction("init")
		self:reset()
	end,
	initSequence=function(self)
		math.randomseed(os.time())
		local function eq()
			local x
			local y
			local e = math.random(1,4)
			local z
			if e == 1 then
				x = math.random(0,99)
				y = math.random(0,99)
				z = x+y
				e = '+'
			elseif e == 2 then
				x = math.random(0,99)
				y = math.random(0,99)		
				if x>y then
					z = x-y
				else
					z = y-x
				end
				e = '-'
			elseif e == 3 then
				x = math.random(0,99)
				y = math.random(0,99)	
				z = x*y
				e = '*'
			elseif e == 4 then
				y = math.random(1,9)
				z = math.random(1,9)
				x = z*y --z = x/y
				e = '/'
			end
			return tostring(x)..e..y..'='..z
		end
		local sq = {}
		for i=1,100 do
			table.insert(sq,eq())
		end
		self._sequence = table.concat(sq)
		self._index = 1
	end,
	init=function(self)
	end,
	release=function(self)
	end,
	testScene=function(self)
		local factory = require "factory"
		return factory.create(base.PhysicsScene)		
	end,
	test = function(self)
		super.test(self)
	end
}
