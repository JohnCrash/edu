return{
	test=function(self)
		self:use("res/3.png")
		self:setPosition(cc.p(90,90))
		self.super.test(self)
	end,
}