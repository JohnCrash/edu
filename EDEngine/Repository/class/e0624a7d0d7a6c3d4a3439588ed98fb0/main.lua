local uikits = require "uikits"

return{
	test=function(self)
		self.super.test(self)
		local ss = uikits.getDR()
		self:use("res/3.png")
		self:setPosition(cc.p(ss.width/2,ss.height/2))
		self:setSize(cc.size(128,128))		
	end,
}