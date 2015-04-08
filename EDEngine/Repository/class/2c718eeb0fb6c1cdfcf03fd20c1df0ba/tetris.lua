local kits = require "kits"
local uikits = require "uikits"
local factory = require "factory"
local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local sequercerUUID = "0e553fc4b6bca473e08a4186fd01d82a"

local EQ = {['=']=1}
local OP = {['+']=1,['-']=2,['*']=3,['/']=4}
local NM = {}
for i=0,9 do
	NM[tostring(i)] = i
end

return {
	ccCreate=function(self)
		super.ccCreate(self)
		local function init( colum,orientation )
			self:reset()
		end
		local function pause()
			self:pause()
		end
		local function resume()
			self:resume()
		end
		local function right()
			self:move(1)
		end
		local function left()
			self:move(-1)
		end
		local function fall()
			self:fall(3)
		end
		local function normal()
			self._OSpeed = 10
			self._fallSpeed = self._OSpeed
		end
		local function fast()
			self._OSpeed = self._OSpeed+10
			self._fallSpeed =self._OSpeed
		end
		local function auto()
			if self._auto then
				self._auto = false
			else
				self._auto = true
			end
		end
		self:addAction{name="正常速度",script=normal}
		self:addAction{name="快速速度",script=fast}
		self:addAction{name="下",script=fall}
		self:addAction{name="左",script=left}
		self:addAction{name="右",script=right}
		self:addAction{name="自动",script=auto}		
		self:addAction{name="暂停",script=pause}
		self:addAction{name="恢复",script=resume}
		self:addAction{name="重新开始",script=init}	
		self:reset{}
		
		local mp
		local ah
		local opFallBlock
		local rate = 1
		local stime
		local spt
		local function onTouchBegan(touches,event)
			if #touches==1 then
				opFallBlock = self._fallBlock
				ah = 0
				self._fallStartPt = nil
				mp = touches[1]:getLocation()
			end
		end
		local function onTouchMoved(touches,event)
			if #touches==1 and self._fallBlock==opFallBlock then
				local p = touches[1]:getLocation()
				local sp = touches[1]:getStartLocation()
				if math.abs(p.x-mp.x) >= math.abs(p.y-mp.y) then
					ah = ah+p.x-mp.x
					if math.abs(ah)>self._blockWidth*rate then
						local m = math.floor(ah/(self._blockWidth*rate))
						if m < 0 then
							m = m+1
						end
						self:move(m)
						self._fallSpeed = self._OSpeed
						ah = ah - m*(self._blockWidth*rate)
					end
					self._fallStartPt = nil
					self._fallSpeed = self._OSpeed
				elseif self._fallBlock then
					local cp = self._fallBlock:getPosition()
					if not self._fallStartPt then
						self._fallStartPt = cp
						spt = p
						stime = cc_clock()
					else
						self._fallStopY = sp.y-p.y
						if self._fallStartPt.y-cp.y<self._fallStopY then
							self._fallSpeed = 1000
						else
							self._fallSpeed = self._OSpeed
						end
					end
					ah = 0
				end
				mp = p
			end		
		end
		local function onTouchEnded(touches,event)
			self._fallSpeed = self._OSpeed
			self._fallStartPt = nil
			--直接落下
			local p = touches[1]:getLocation()
			local sp = touches[1]:getStartLocation()			
			if self._fallBlock and stime and spt.y-p.y>64 and cc_clock()-stime<0.5 then
				self:fall()
			end
		end
		local listener = cc.EventListenerTouchAllAtOnce:create()
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )	
		listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCHES_ENDED )	
		local eventDispatcher=self:ccNode():getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener,self:ccNode())
	end,
	setSize=function(self,s)
		self._size = s
	end,
	getSize=function(self,s)
		return self._size
	end,
	pause = function(self)
		self._pause=true
	end,
	setFallSpeed=function(self,speed)
		self._OSpeed = speed
		self._fallSpeed = speed
	end,
	getFallSpeed=function(self)
		return self._fallSpeed
	end,	
	resume=function(self)
		self._pause=false
	end,
	reset = function(self,t)
		t = t or {}
		self._colum = t.colum or self._colum or 6
		self._raw = t.raw or self._raw or 8
		self._blockWidth = t.blockWidth or self._blockWidth or 128
		self._OSpeed = t._OSpeed or self._OSpeed or 200
		self._fallSpeed = self._OSpeed
		self._fallColum = self._fallColum or 1
		if self._grid then
			for i,v in pairs(self._grid) do
				if v then
					for k,obj in pairs(v) do
						obj:removeFromParent()
					end
				end
			end
		end
		self._grid = {}
		for i=1,self._colum do
			self._grid[i] = {}
		end
		self:setSize(cc.size(self._colum*self._blockWidth,self._raw*self._blockWidth))	
		if self._scID then
			self:removeScheduler(self._scID)
		end
		local function mainLoop(dt)
			if self._pause then return true end
			if not self._fallBlock then --下落已经结束
				if self._onReady then
					self._onReady()
				end
			else --下落过程中
				local p = self._fallBlock:getPosition()
				local topRaw = self:getColumTop(self._fallColum)
				local fallHeight=topRaw*self._blockWidth				
				local maxFall = p.y - fallHeight
				if maxFall<0 then
					print("game over")
					if self._onGameOver then
						self._onGameOver()
					end
					self:reset()
					return false
				end
				local fall
				if self._fallStartPt and self._fallStopY then
					if not (self._fallStartPt.y-p.y<self._fallStopY) then
						self._fallSpeed = self._OSpeed
					end
				end
				if self._fallSpeed*dt > maxFall then
					p.y = p.y - maxFall
					p.x = (self._fallColum-1)*self._blockWidth
					self._fallBlock:setPosition(p)
					--放置好
					self._grid[self._fallColum][topRaw+1] = self._fallBlock
					self._fallBlock = nil
					self._fallSpeed = self._OSpeed
					self:clacAndClearRaw()
					if self._onFalldown then
						self._onFalldown()
					end
				else
					p.y = p.y - self._fallSpeed*dt
					p.x = (self._fallColum-1)*self._blockWidth
					self._fallBlock:setPosition(p)
				end
			end
			return true
		end
		self._scID = self:scheduler(mainLoop)
	end,
	onGameOver=function(self,func)
		self._onGameOver = func
	end,
	onFalldown=function(self,func)
		self._onFalldown = func
	end,
	onReady=function(self,func)
		self._onReady = func
	end,
	getColumTop = function(self,n)
		for i=self._raw,1,-1 do
			if self._grid[n][i] then
				return i
			end
		end
		return 0
	end,
	fall=function(self,n) --快速下降当前块
		if self._fallBlock then
			local fallHeight = self:getColumTop(self._fallColum)*self._blockWidth
			if not n then
				local p = self._fallBlock:getPosition()
				p.y = fallHeight
				self._fallBlock:setPosition(p)
			else
				local p = self._fallBlock:getPosition()
				p.y = p.y-n*self._blockWidth
				if p.y < fallHeight then
					p.y = fallHeight
				end
				self._fallBlock:setPosition(p)
			end
		end
	end,
	move=function(self,n) --左右移动当前块
		if self._fallBlock then
			local b,e,d
			b = self._fallColum
			e = self._fallColum+n
			if e>self._colum then
				e = self._colum
			end
			if e < 1 then
				e = 1
			end
			if e>b then
				d = 1
			else
				d = -1
			end
			local p = self._fallBlock:getPosition()
			for i=b,e,d do
				local fallHeight=self:getColumTop(i)*self._blockWidth
				if p.y < fallHeight then
					return
				end
				self._fallColum=i
			end
		end
	end,
	isFalling=function(self)
		if self._fallBlock then return true end
	end,
	add=function(self,block)
		if not self._fallBlock then
			self._fallBlock = block
			
			if self._auto then
				self._fallColum = self._fallColum or 1 --math.floor(self._colum/2)
				self._fallColum = self._fallColum+1
				if self._fallColum > self._colum then
					self._fallColum = 1
				end
			end
			
			self:addChild(self._fallBlock)
			self._fallBlock:setPosition(cc.p((self._fallColum-1)*self._blockWidth,(self._raw-1)*self._blockWidth))
		end
	end,
	printResult=function(self,result,value)
		local t = {}
		for k,v in pairs(result) do
			table.insert(t,v.symbol)
		end	
		if #t>0 then
			if value then
				print("	"..tostring(value).."="..table.concat(t) )
			else
				print( table.concat(t) )
			end
		end
	end,
	clacAndClearRaw=function(self)
		local isdo
		for i=1,self._raw do
			local result = self:clac(self:raw(i))
			self:printResult(result)
			for k,v in pairs(result) do
				self._grid[v.col][v.raw] = nil
				v.object:removeFromParent()
				isdo = true
			end
		end
		for i=1,self._colum do
			local result = self:clac(self:colum(i))
			self:printResult(result)
			for k,v in pairs(result) do
				self._grid[v.col][v.raw] = nil
				v.object:removeFromParent()
				isdo = true
			end
		end		
		if isdo then
			self:relayoutBlock()
		end
	end,
	relayoutBlock=function(self) --重新布局方块
		local p = cc.p(0,0)
		for i=1,self._colum do
			p.x = (i-1)*self._blockWidth
			p.y = 0
			local k=1
			for j=1,self._raw do
				local c = self._grid[i][j]
				if c then
					if k~=j then
						self._grid[i][k]=self._grid[i][j]
						self._grid[i][j] = nil
					end
					local oldp = c:getPosition()
					if oldp.y ~= p.y then
						--c:setPosition(p)
						c:ccNode():runAction(cc.MoveTo:create(0.5,p))
					end
					p.y = p.y+self._blockWidth
					k=k+1
				end
			end
		end
	end,
	clacPart = function(self,part,orientation ) --计算等式,part如3+2
		local b,e,d
		if orientation==1 then
			b = 1
			e = #part
			d = 1
		elseif orientation==2 then
			b = #part
			e = 1
			d = -1
		else
			return
		end
		local result={}
		local array={}
		local op
		local lastValue
		local opValue
		for i=b,e,d do
			local c = part[i]
			table.insert(array,c)
			if NM[c.symbol] then
				local value
				if lastValue then
					if orientation==2 then
						local m = math.pow(10,string.len(tostring(math.floor(lastValue))))
						lastValue = NM[c.symbol]*m + lastValue						
					else --1
						lastValue = lastValue*10+NM[c.symbol]
					end
				else
					lastValue = NM[c.symbol]
				end				
				if op then
					if op=='+' then
						value = opValue+lastValue
					elseif op=='-' then
						if orientation==1 then
							value = opValue-lastValue
						else
							value = lastValue-opValue
						end
					elseif op=='*' then
						value = opValue*lastValue
					elseif op=='/' then
						if lastValue ~= 0 then
							if orientation==1 then
								value = opValue/lastValue
							else
								value = lastValue/opValue
							end
						else
							value = -1
						end
					end
				else
					value = lastValue
				end
				local clone = {}
				for i=1,#array do
					if orientation==1 then
						table.insert(clone,array[i])
					else
						table.insert(clone,1,array[i])
					end
				end
				result[value] = {value=value,operator=op,list=clone}
			elseif OP[c.symbol] then
				if not lastValue then
					return result --开始为符号，连续的符号
				end
				op = c.symbol
				opValue = lastValue
				lastValue = nil
			end
		end
		return result
	end,
	clac = function(self,line) --返回等式，忽略空白区
		local parts = {}
		local part = {}
		local eqs = {}
		for i=1,#line do
			local c = line[i]
			if c.symbol=='=' and #part>0  then
				table.insert(parts,part)
				table.insert(eqs,c)
				part={}
			elseif c.symbol=='N' then --忽略
			else
				table.insert(part,c)
			end
		end
		if #part>0 then
			table.insert(parts,part)
		end
		local result = {}
		if #parts>0 then
			for i=1,#parts-1 do
				local s1 = self:clacPart(parts[i],2)
				local s2 = self:clacPart(parts[i+1],1)
				for n,v in pairs(s1) do
					if s2[n] and (v.operator or s2[n].operator) then
						for k,c in pairs(v.list) do
							table.insert(result,c)
						end
						table.insert(result,eqs[i])
						for k,c in pairs(s2[n].list) do
							table.insert(result,c)
						end
						return result
					end
				end
			end
		end
		return result
	end,
	raw = function(self,raw)
		local t={}
		for i=1,self._colum do
			local obj = self._grid[i][raw]
			if obj then
				table.insert(t,{symbol=obj:currentAction(),object=obj,col=i,raw=raw})
			else
				table.insert(t,{symbol='N',col=i,raw=raw})
			end
		end
		return t
	end,
	colum=function(self,col)
		local t={}
		for i=1,self._raw do
			local obj = self._grid[col][i]
			if obj then
				table.insert(t,{symbol=obj:currentAction(),object=obj,col=col,raw=i})
			else
				table.insert(t,{symbol='N',col=col,raw=i})
			end
		end
		return t
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
			local colum = 12
			local raw = 11
			local blockWidth=96
			seqer:reset{colum=colum,blockWidth=blockWidth}
			self:reset{colum=colum,raw=raw,blockWidth=blockWidth}	
			self:onGameOver(function()
				print("Game Over")
			end)
			self:onFalldown(function()
			end)
			self:onReady(function()
					local obj = seqer:get()
					if obj then
						self:add( obj )
					end						
			end)
			--居中放置
			local p = self:getPosition()
			local ss = uikits.getDR()
			local height = self._size.height+blockWidth
			p.y = (ss.height-height)/2
			p.x = (ss.width-self._size.width)/2
			self:setPosition(p)
			p.y = p.y+self._size.height
			seqer:setPosition(p)			
		end)
	end
}
