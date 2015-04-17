local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"
local json = require "json-c"

return {
	ccCreate=function(self)
		self:attach(gl.glNodeCreate())
		local function visit()
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
	end,
	loadFromJson=function(self,file)
		local t = self:readJson(file)
		if t and t.segments and t.grain then
			self._tdata = t
			self._grain = t.grain
			self._segments = t.segments
			for i,v in pairs(self._segments) do
				v.scale = v.scale or cc.p(1,1)
				v.offset = v.offset or cc.p(0,0)
				if v.mipmap then
					v.show = {}
					v.hide = {}
					for k,img in pairs(v.mipmap) do
						local obj = cc.Sprint:create()
						obj:setTexture(self:getR(img))
						obj:setVisible(false)
						obj:setPosition(v.offset)
						obj:setScale(v.scale)
						self:addChild(obj)
						local s = obj:getContentSize()
						local level = math.floor(s.width/self._grain)
						if s.width/self._grain > level + 0.01 or levle==0 then
							kits.log("WARNING "..self:getClassid().." loadFromJson")
							kits.log("	image width is not grain Multiple "..tostring(img))
						end
						v.hide[level] = v.hide[level] or {}
						v.show[level] = v.show[level] or {}
						table.insert(v.hide[level],obj)
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