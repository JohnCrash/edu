local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"

local MountainUUID = "033b3be83c70075bbe5f98cc9f634a27"
local cloudUUID = "4abdf31c00f3d1dc7c5870188fef0481"
local wayUUID = "a01ee8a3db56d31570a9307e56d91c3f"

--[[
	横向以一种模式简单无限重复的场景,我使用了glNode用来跟踪绘制
--]]
return {
	ccCreate=function(self)
		self:attach(gl.glNodeCreate())
		local ss
		local prev_x
		local function visit()
			local pt = self:getPosition()
			if prev_x==pt.x or not self._patterns  then
				return
			end
			prev_x=pt.x
			ss = ss or self:getScene():getSize() --简单优化
			for i,v in pairs(self._patterns) do
				local x = -pt.x + math.fmod(pt.x,v.strip)+ v.offset.x
				local y = v.offset.y
				if not v.obj then
					v.obj = {}
					for k=1,math.floor(ss.width/v.strip) + 1 do
						local obj = uikits.image{image=self:getR(v.image)}
						self:addChild(obj)
						obj:setScaleX(v.scale.x)
						obj:setScaleY(v.scale.y)
						obj:setAnchorPoint(v.anchor)
						obj:setRotation(v.angle)
						table.insert(v.obj,obj)
					end
				end
				for k,o in pairs(v.obj) do
					o:setPosition(cc.p(x,y))
					if pt.x > 0 then
						x = x - v.strip
					else
						x = x + v.strip
					end
				end
			end
		end
		self:ccNode():registerScriptDrawHandler(visit)
		self:loadFromJson("pattern.json")
	end,
	loadFromJson=function(self,file)
		local t = self:readJson(file)
		if t and t.patterns then
			self._patterns = t.patterns
			--检查剔除不正确的项
			for i,v in pairs(self._patterns) do
				v.scale = v.scale or cc.p(1,1)
				v.angle = v.angle or 0
				v.anchor = v.anchor or cc.p(0,0)
				v.offset = v.offset or cc.p(0,0)
			end
		end
	end,
	test=function(self)
		super.test(self)
		local move = cc.MoveTo:create(1000,cc.p(-1024*400,0))
		self:ccNode():runAction(move)
	end,
}