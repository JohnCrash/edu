local uikits = require "uikits"
local kits = require "kits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local calcBox = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"

return {
	ccCreate=function(self)
		super.ccCreate(self)
	end,
	reset=function(self,t)
		self._idx = 0
		self._colum = t.colum or 6
		self._raw = t.raw or 1
		self._blockWidth = t.blockWidth or 128
		self:setSize(cc.size(self._blockWidth*self._colum,self._blockWidth*self._raw))
		self:clear()
		self._blocks = {}
		for i=1,self._colum do
			self._blocks[i] = {}
		end
	end,
	clear=function(self)
		if not self._blocks then return end
		for i=1,self._colum do
			for j=1,self._raw do
				local obj = self._blocks[i][j]
				if obj then
					obj:removeFromParent()
				end
				self._blocks[i][j] = nil
			end
		end
	end,
	insert=function(self,col,raw,o)
		if col and raw and o then
			if col<=self._colum and col>=1 and raw<=self._raw and raw>=0 then
				local old = self._blocks[col][raw]
				if old then old:removeFromParent() end
				self._blocks[col][raw] = o
				o:setSize(cc.size(self._blockWidth,self._blockWidth))
				self:addChild(o)
				o:setPosition(cc.p(col*self._blockWidth,raw*self._blockWidth))
			end
		end
	end,
	relayout=function(self)
		for i=1,self._colum do
			for j=1,self._raw do
				local o = self._blocks[i][j]
				if o then
					o:setPosition(cc.p(self._blockWidth*(i-1),self._blockWidth*(j-1)))
				end
			end
		end		
	end,
	setSize=function(self,s)
		self._size = s
	end,
	getSize=function(self)
		return self._size
	end,	
	fall=function(self)
	end,
	test=function(self)
		super.test(self)
		factory.import({blockUUID,calcBox},function(b)
			if b then
				--初始化一个数字盘
				self:reset{colum=15,raw=1}
				for i = 1,10 do
					local o = factory.create(blockUUID)
					o:doAction(tostring(i-1))
					self:insert(i,1,o)
				end
				local o = factory.create(blockUUID)
				o:doAction('+')
				self:insert(11,1,o)
				o = factory.create(blockUUID)
				o:doAction('-')
				self:insert(12,1,o)
				o = factory.create(blockUUID)
				o:doAction('*')
				self:insert(13,1,o)
				o = factory.create(blockUUID)
				o:doAction('/')
				self:insert(14,1,o)				
				o = factory.create(blockUUID)
				o:doAction('=')
				self:insert(15,1,o)					
				--创建一个计算盒
				local box = factory.create(calcBox)
				box:reset{colum=12,raw=7,
					onEvent=function(msg)
						if msg=='ready' then
						else
							print("msg="..tostring(msg))
						end
					end
				}
				local ss = uikits.getDR()
				local bs = box:getSize()
				local s = self:getSize()
				local ox = (ss.width-math.max(bs.width,s.width))/2
				local oy = (ss.height-bs.height-s.height)/2
				box:setPosition(cc.p(ox,oy))
				self:setPosition(cc.p(ox,oy+bs.height))
				self:getScene():addChild(box)
			end
		end)
	end,
}