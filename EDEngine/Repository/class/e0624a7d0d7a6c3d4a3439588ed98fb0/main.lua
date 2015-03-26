local uikits = require "uikits"

return{
	test=function(self)
		super.test(self)
		for i=0,9 do
			self:addAction{name=tostring(i),image="res/"..tostring(i)..".png"}
		end
		uikits.delay_call(nil,function()self:doAction("3")end)
		uikits.delay_call(nil,function()self:doAction("2")end,0.5)
		uikits.delay_call(nil,function()self:doAction("1")end,1)
		self:setSize(cc.size(128,128))		
	end,
}