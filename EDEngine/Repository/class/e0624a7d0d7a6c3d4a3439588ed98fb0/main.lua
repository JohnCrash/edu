local uikits = require "uikits"

return{
	test=function(self)
		self.super.test(self)
		local ss = uikits.getDR()
		for i=0,9 do
			self:addAction{name=tostring(i),image="res/"..tostring(i)..".png"}
		end
		uikits.delay_call(nil,function()self:doAction("3")end)
		uikits.delay_call(nil,function()self:doAction("2")end,0.5)
		uikits.delay_call(nil,function()self:doAction("1")end,1)
		self:setPosition(cc.p(ss.width/2,ss.height/2))
		self:setSize(cc.size(128,128))		
	end,
}