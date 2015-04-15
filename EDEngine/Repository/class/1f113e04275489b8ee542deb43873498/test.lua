local kits = require "kits"
local uikits = require "uikits"
local json = require "json-c"
local factory = require "factory"
local base = require "base"

local fieldUUID ="dcbeb36aa886a490d9437569e4972793"
local cloudUUID = "813e959e60d40f104496bfd818eb40ba"

return {
	ccCreate=function(self)
		self:attach(cc.ParallaxNode:create())
	end,
	addParallaxLayer=function(self,layer,z,ratio,offset)
		if layer._ccnode then
			layer._parent_node = self
			self._child_nodes[layer] = layer
			self:ccNode():addChild(layer:ccNode(),z or -1,ratio or cc.p(1,1),offset or cc.p(0,0))
		elseif cc_isobj(layer) then
			self:ccNode():addChild(layer,z or -1,ratio or cc.p(1,1),offset or cc.p(0,0))
		end
	end,
	test=function(self)
		super.test(self)
		factory.importByProgressBox({fieldUUID,cloudUUID},
		function(b)
			local cloud = factory.create(cloudUUID)
			local field = factory.create(fieldUUID)
			print("Cloud!")
			local bg = cc.Sprite:create()
			bg:setAnchorPoint(cc.p(0,0))
			bg:setTexture(self:getR("beijing.png"))
			bg:setScaleY(0.75)
			self:addParallaxLayer(bg,-1,cc.p(0,0),cc.p(0,0))
			self:addParallaxLayer(cloud,1,cc.p(0.4,0.5),cc.p(0,150))
			self:addParallaxLayer(field,1,cc.p(1,1),cc.p(0,-100))
			local move = cc.MoveTo:create(1000,cc.p(-1024*400,0))
			self:ccNode():runAction(move)
		end)
	end,				
}