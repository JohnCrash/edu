local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"
local json = require "json-c"

return {
	ccCreate=function(self)
		self:attach(gl.glNodeCreate())
		local function visit()
			if not self._segments then return end
			local pt = self:ccNode():convertToNodeSpace(cc.p(0,0))
			for i,v in pairs(self._show) do
				v.obj:setVisible(false)
				table.insert(self._segments[v.index].levels[v.level],v.obj)
				self._show[i] = nil
			end
			for i,v in pairs(self._segs) do
				if v.endx>=pt.x then
					if v.offset.x > pt.x+self._ss.width then
						return
					end
					local seg = self._segments[v.index]
					--先取一个最接近于v.repes的值，然后在取剩下的。
					--比如要求重复23,mipmap是1,2,3,4,8
					--那么就是先取8,在取8,在取7,但是没有7,就取一个最接近的4,然后是1
					--seg.maxlevel v.repes
				end
			end
		end
		self:ccNode():registerScriptDrawHandler(visit)
		self:loadFromJson("segment.json")		
	end,
	init=function(self)
		self._ss = self:getScene():getSize()
		if self._tdata.width then
			local scale = self._ss.width/self._tdata.width
			self._ss.width = self._tdata.width
			self:setScale(scale)
		end	
	end,
	release=function(self)
	end,
	addSegment=function(self,index,re,pt)
		local oldpt = cc.p(self._segpt.x,self._segpt.y)
		if pt then
			self._segpt = pt
		else
			self._segpt.x = self._segpt.x + re*self._grain
		end
		table.insert(self._segs,{index=index,repes = re,offset=self._segpt,endx=self._segpt.x+re*self._grain}
		return {x=oldpt.x,y=oldpt.y,width=re*self._grain}
	end,
	getSize=function(self)
		local t = self._segs[#self._segs]
		if t and t.offset and self._grain then
			return cc.size(t.offset.x+t.repes*self._grain,self._height)
		end
		return cc.size(0,self._height or 0)
	end,
	loadFromJson=function(self,file)
		local t = self:readJson(file)
		if t and t.segments and t.grain then
			self._tdata = t
			self._grain = t.grain
			self._segments = t.segments
			self._segs = {}
			self._show = {}
			self._height = 0
			self._segpt = cc.p(0,0)
			for i,v in pairs(self._segments) do
				v.scale = v.scale or cc.p(1,1)
				v.offset = v.offset or cc.p(0,0)
				if v.mipmap then
					v.levels = {}
					v.maxlevel = 0
					
					for k,img in pairs(v.mipmap) do
						local obj = cc.Sprint:create()
						obj:setTexture(self:getR(img))
						obj:setVisible(false)
						obj:setPosition(v.offset)
						obj:setScale(v.scale)
						self:addChild(obj)
						local s = obj:getContentSize()
						self._height = math.max(self._height,s.height)
						local level = math.floor(s.width/self._grain)
						if s.width/self._grain > level + 0.01 or levle==0 then
							kits.log("WARNING "..self:getClassid().." loadFromJson")
							kits.log("	image width is not grain Multiple "..tostring(img))
						end
						v.levels[level] = v.levels[level] or {}
						v.maxlevel = math.max(v.maxlevel,level)
						table.insert(v.levels[level],obj)
					end
				else
					kits.log("ERROR "..self:getClassid().." loadFromJson")
					kits.log("	mipmap = nil")
				end
			end
		else
			kits.log("ERROR "..self:getClassid().." loadFromJson")
			kits.log("	segment.json have not segments or grain")
		end	
	end,
	test=function(self)
		super.test(self)
		local move = cc.MoveTo:create(1000,cc.p(-1024*400,0))
		self:ccNode():runAction(move)	
	end,
}