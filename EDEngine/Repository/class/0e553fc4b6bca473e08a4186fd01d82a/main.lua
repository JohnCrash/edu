local uikits = require "uikits"
local kits = require "kits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local boxUUID = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		local function fall()
			local blockObj = self:fall()
			local p = blockObj:getPosition()
			p.y = p.y - 1000
			local function removeMe(node)
				blockObj:removeFromParent()
			end
			blockObj:ccNode():runAction(
				cc.Sequence:create(
					cc.MoveTo:create(1,p),
					cc.CallFunc:create(removeMe))
				)			
		end
		local function init( colum,orientation )
			self:reset{colum=colum,orientation=orientation}
		end
		self:addAction{name="fall",script=fall}
		self:addAction{name="init",script=init}
		self:setDefaultAction("init")
		self:reset()
	end,
	reset=function(self,t)
		self:initSequence()
		t = t or {}
		self._colum=t.colum or 6
		self._orientation = t.orientation or "left"
		local x = 0
		local y = 0
		self._blockWidth = t.blockWidth or 128
		self:setSize(cc.size(self._blockWidth*self._colum,self._blockWidth))
		if self._orientation=='right' then
			x = self._size.width-self._blockWidth
		end
		if self._blocks then
			for i,v in pairs(self._blocks) do
				v:removeFromParent()
			end
		end
		self._blocks = {}
		for i=self._index,self._index+self._colum-1 do
			local c = string.sub(self._sequence,i,i)
			local obj = factory.create(blockUUID)
			self:addChild( obj )
			table.insert(self._blocks,obj)
			obj:doAction(c)
			obj:setPosition(cc.p(x,y))
			obj:setSize(cc.size(self._blockWidth,self._blockWidth))
			if self._orientation=='right' then
				x = x - self._blockWidth
			else
				x = x + self._blockWidth
			end
		end
		self._index = self._index+self._colum		
	end,
	fall=function(self)
		local obj = factory.create(blockUUID)
		obj:doAction(string.sub(self._sequence,self._index,self._index))
		self._index=self._index+1
		if self._index > #self._sequence then
			self._index = 1
		end
		local p = self._blocks[#self._blocks]:getPosition()
		local orientation = self._orientation
		table.insert(self._blocks,obj)
		if orientation=='right' then
			p.x=p.x-self._blockWidth
		else
			p.x=p.x+self._blockWidth
		end
		obj:setSize(cc.size(self._blockWidth,self._blockWidth))
		obj:setPosition(p)	
		self:addChild(obj)
		for i,v in pairs(self._blocks) do
			local p = v:getPosition()
			if orientation=='right' then
				p.x = p.x + self._blockWidth
			else
				p.x = p.x - self._blockWidth
			end
			v:setPosition(p)
		end
		local blockObj
		blockObj = self._blocks[1]
		table.remove(self._blocks,1)
		local current = blockObj:currentAction()
		blockObj:removeFromParent()
		blockObj = factory.create(blockUUID)
		blockObj:doAction(current)
		blockObj:setSize(cc.size(self._blockWidth,self._blockWidth))
		return blockObj
	end,
	setSize=function(self,s)
		self._size = s
	end,
	getSize=function(self)
		return self._size
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
		--self:setSize(cc.size(960,128))
		self:doAction("init",6,"right")
	end
}
