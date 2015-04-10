local kits = require "kits"
local uikits = require "uikits"
local base = require "base"
local factory = require "factory"

return {
	init=function(self)
	end,
	release=function(self)
	end,
	loadLevel=function(self,json)
	end,
	test = function(self)
		print("Level Scene test")
		super.test(self)
	end,
}
