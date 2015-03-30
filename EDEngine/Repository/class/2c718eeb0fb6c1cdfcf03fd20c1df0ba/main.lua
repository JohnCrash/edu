local kits = require "kits"
local uikits = require "uikits"
local factory = require "factory"
local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local sequercerUUID = "0e553fc4b6bca473e08a4186fd01d82a"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		self:reset{}
	end,
	setSize=function(self,s)
		self._size = s
	end,
	getSize=function(self,s)
		return self._size
	end,
	reset = function(self,t)
		t = t or {}
		self._colum = t.colum or 6
		self._raw = t.raw or 8
		self._blockWidth = t.blockWidth or 128
		self._fallSpeed = t._fallSpeed or 200
		self._eventFunc = t.onEvent
		self._grid = {}
		for i=1,self._colum do
			self._grid[i] = {}
		end
		self:setSize(cc.size(self._colum*self._blockWidth,self._raw*self._blockWidth))	
		if self._scID then
			self:removeScheduler(self._scID)
		end
		local function mainLoop(dt)
			local function event(msg)
				if self._eventFunc then
					self._eventFunc(msg)
				else
				--	print("func = nil")
				end
			end
			if not self._fallBlock then --下落已经结束
			--	print("ready")
				event('ready')
			else --下落过程中
				local p = self._fallBlock:getPosition()
				local topRaw = self:getColumTop(self._fallColum)
				local fallHeight=topRaw*self._blockWidth				
				local maxFall = p.y - fallHeight
				if maxFall<0 then
					event("game over")
					print("game over")
					return false
				end
				local fall
				if self._fallSpeed*dt > maxFall then
					p.y = p.y - maxFall
					self._fallBlock:setPosition(p)
					--放置好
					self._grid[self._fallColum][topRaw+1] = self._fallBlock
					self._fallBlock = nil
				else
					p.y = p.y - self._fallSpeed*dt
					self._fallBlock:setPosition(p)
				end
			end
			return true
		end
		self._scID = self:scheduler(mainLoop)
	end,
	getColumTop = function(self,n)
		for i=self._raw,1,-1 do
			if self._grid[n][i] then
				return i
			end
		end
		return 0
	end,
	place=function(self,block)
		if not self._fallBlock then
			self._fallBlock = block
			self._fallColum = 1 --math.floor(self._colum/2)
			self:addChild(self._fallBlock)
			self._fallBlock:setPosition(cc.p((self._fallColum-1)*self._blockWidth,(self._raw-1)*self._blockWidth))
		end
	end,
	test = function(self)
		super.test(self)
		factory.import({sequercerUUID},function(b)
			local seqer = factory.create(sequercerUUID)
			local scene = self:getScene()
			if not seqer then
				kits.log("ERROR create "..sequercerUUID.." failed")
				return
			end
			scene:addChild(seqer)
			local colum = 6
			local raw = 8
			local blockWidth=128
			seqer:reset{colum=colum,blockWidth=blockWidth}
			self:reset{
				colume=colum,raw=raw,blockWidth=blockWidth,
			onEvent=function(msg)
				if msg=="ready" then
					local obj = seqer:fall()
					if obj then
						self:place( obj )
					else
					end
				else
					print("msg="..tostring(msg))
				end
			end}	
			
			local p = self:getPosition()
			local ss = uikits.getDR()
			local height = self._size.height+blockWidth
			p.y = (ss.height-height)/2
			self:setPosition(p)
			p.y = p.y+self._size.height
			seqer:setPosition(p)			
		end)
	end
}
