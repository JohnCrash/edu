local uikits = require "uikits"
local kits = require "kits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local calcBox = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		self._enable = true
		local function onTouchBegan(touches,event)
			if self._enable and #touches==1 then
				local col,raw
				local p = self:ccNode():convertToNodeSpace(touches[1]:getLocation())
				if p.y>=0 and p.x>=0 and p.x<=self._size.width and p.y<=self._size.height then
					local raw = math.floor(p.y/self._blockWidth)+1
					local col = math.floor(p.x/self._blockWidth)+1
					local obj = self._blocks[col][raw]		
					self._blocks[col][raw] = nil					
					if self._onSelect and obj then
						obj:ccNode():retain()
						obj:ccNode():autorelease()
						obj:removeFromParent()
						self._onSelect( obj,col,raw )
					end
				end
			end
		end
		local function onTouchMoved(touches,event)
		end
		local function onTouchEnded(touches,event)
		end
		local listener = cc.EventListenerTouchAllAtOnce:create()
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )	
		listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCHES_ENDED )	
		local eventDispatcher=self:ccNode():getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,self:ccNode())
	end,
	enable=function(self,en)
		self._enable = en
	end,
	onSelect=function(self,func)
		self._onSelect = func
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
				o:setAnchor(cc.p(0,0))
				o:setPosition(cc.p((col-1)*self._blockWidth,(raw-1)*self._blockWidth))
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
	get=function(self)
	end,
	test=function(self)
		super.test(self)
		factory.import({blockUUID,calcBox},function(b)
			if b then
				--初始化一个数字盘
				self:reset{colum=5,raw=2}
				math.randomseed(os.time())
				for i = 1,5 do
					local o = factory.create(blockUUID)
					o:doAction(tostring(math.random(0,9)))
					self:insert(i,1,o)
				end
				local o = factory.create(blockUUID)
				o:doAction('+')
				self:insert(1,2,o)
				o = factory.create(blockUUID)
				o:doAction('-')
				self:insert(2,2,o)
				o = factory.create(blockUUID)
				o:doAction('*')
				self:insert(3,2,o)
				o = factory.create(blockUUID)
				o:doAction('/')
				self:insert(4,2,o)
				o = factory.create(blockUUID)
				o:doAction('=')
				self:insert(5,2,o)		
				--在做一个选择盘
				--创建一个计算盒
				local box = factory.create(calcBox)
				box:reset{colum=15,raw=7}
				local ss = uikits.getDR()
				local bs = box:getSize()
				local s = self:getSize()
				local ox = (ss.width-bs.width)/2
				local oy = (ss.height-bs.height-s.height)/2
				box:setPosition(cc.p(ox,oy))
				ox = (ss.width-s.width)/2
				self:setPosition(cc.p(ox,oy+bs.height))
				self:getScene():addChild(box)
				box:setFallSpeed(50)
				self:onSelect(function(obj,col,raw)
					box:add(obj)
					self:enable(false)
					if raw == 1 then
						local o = factory.create(blockUUID)
						o:doAction(tostring(math.random(0,9)))
						self:insert(col,1,o)					
					elseif raw==2 then
						local o = factory.create(blockUUID)
						local op = {
							[1] = '+',[2]='-',[3]='*',[4]='/',[5]='='
						}
						o:doAction(op[col])
						self:insert(col,2,o)										
					end
				end)
				box:onFalldown(function()
					self:enable(true)
				end)
			end
		end)
	end,
}