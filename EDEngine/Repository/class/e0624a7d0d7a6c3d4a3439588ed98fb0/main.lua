local NumberBlock={}

function NumberBlock:__init__()
	self._ccnode = cc.Sprite:create()
	self._ccnode:loadTexture(self:getR("res/"))
end

function NumberBlock:setNumber()
end

function NumberBlock:init()
end

function NumberBlock:release()
end

function NumberBlock:test()
end

return NumberBlock