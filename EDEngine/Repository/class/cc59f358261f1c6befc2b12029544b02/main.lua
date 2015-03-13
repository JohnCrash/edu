local my = require "class/cc59f358261f1c6befc2b12029544b02/test_in_hello"

return {
	open=function(self,t)
		self.super.open(self,t)
		print("new progress box is open")
	end,
	setProgress=function(self,d)
	end,
}