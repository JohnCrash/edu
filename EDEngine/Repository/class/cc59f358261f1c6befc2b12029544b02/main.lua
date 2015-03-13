local factory = require "factory"
local my = require "class/cc59f358261f1c6befc2b12029544b02/test_in_hello"

return {
	open=function(self,t)
		self.super.open(self,t)
		if factory.create("e0624a7d0d7a6c3d4a3439588ed98fb0") then
			print("factory.create e0624a7d0d7a6c3d4a3439588ed98fb0 ok")
		else
			print("factory.create e0624a7d0d7a6c3d4a3439588ed98fb0 failed")
		end
	end,
	setProgress=function(self,d)
	end,
}