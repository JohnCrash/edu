local uikits = require "uikits"
local kits = require "kits"
local base = require "base"
local factory = require "factory"

local blockUUID = "e0624a7d0d7a6c3d4a3439588ed98fb0"
local boxUUID = "2c718eeb0fb6c1cdfcf03fd20c1df0ba"

return {
	ccCreate=function(self)
		super.ccCreate(self)
		self:addAction{name="drop",script=drop}
	end,
	init=function(self)
	end,
	release=function(self)
	end,
	test = function(self)
		super.test(self)
	end
}
