local uikits = require "uikits"

return{
	ccCreate=function(self)
		super.ccCreate(self)
		for i=0,9 do
			self:addAction{name=tostring(i),image="res/"..tostring(i)..".png"}
		end
		self:addAction{name='+',image="res/add.png"}
		self:addAction{name='-',image="res/sub.png"}
		self:addAction{name='*',image="res/mul.png"}
		self:addAction{name='/',image="res/div.png"}
		self:addAction{name='=',image="res/eq.png"}
	end,
	test=function(self)
		super.test(self)
		self:scheduler(function()self:doAction("3")end)
		self:scheduler(function()self:doAction("2")end,0.5)
		self:scheduler(function()self:doAction("1")end,1)
		self:setScale(5)	
	end,
}