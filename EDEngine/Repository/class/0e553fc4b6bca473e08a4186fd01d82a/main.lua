local uikits = require "uikits"
local kits = require "kits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local boxUUID = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		self._queue = {}
	end,
	
	init=function(self)
		self._scheduler = self:ccNode():getScheduler()
		local function spin()
			
		end
		self._schedulerId = self._scheduler:scheduleScriptFunc(spin,1,false)
	end,
	release=function(self)
		if self._schedulerId then
			self._scheduler:unscheduleScriptEntry(self._schedulerId)
			self._schedulerId = nil
		end	
	end,
	doAction=function(self,name)
	end,
	addAction=function(self,name)
	end,
	test = function(self)
		super.test(self)
	end
}
