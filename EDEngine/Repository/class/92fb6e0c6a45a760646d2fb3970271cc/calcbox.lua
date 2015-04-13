local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
--[[
	计算盒对象,
--]]
return {
	ccCreate=function(self)
		super.ccCreate(self)
	end,
	reset=function(self,t)
		t = t or {}
		self:clear()
		self._colum = t.colum or self._colum or 8
		self._blockWidth = t.blockWidth or self._blockWidth or 128
		self:setSize(cc.size(self._colum*self._blockWidth,self._blockWidth))
	end,
	add=function(self,obj)
		if self._blocks and factory.checkType(obj,blockUUID) then
			if #self._blocks<=self._colum then
				table.insert(self._blocks,obj)
				self:relayoutBlock()
				self:calcResult()
			elseif self._onEerror then
				self._onEerror()
			end				
		end
	end,
	calcResult = function(self)
		
	end,
	clear=function(self)
		if self._blocks then
			for i,obj in pairs(self._blocks) do
				if obj then obj:removeFromParent() end
			end
		end
		self._blocks = {}
	end,
	relayoutBlock=function(self)
		if self._blocks then
			local x = 0
			local y = 0
			for i,obj in pairs(self._blocks) do
				if obj then
					obj:setPosition(cc.p(x,y))
					x = x + self._blockWidth
				end
			end
		end
	end,
	setSize=function(self,s)
		self._size = s
	end,
	getSize=function(self,s)
		return self._size
	end,	
	setResult=function(self,num)
		factory.import({blockUUID},
			function(b)
				
			end)
	end,
	onEq=function(self,notify)
		self._onEq = notify
	end,
	onEerror=function(self,notify)
		self._onEerror = notify
	end,
}
