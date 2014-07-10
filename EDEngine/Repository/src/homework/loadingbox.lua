local uikits = require "uikits"

local ui = {
	LOADBOX = 'homework/ladingbox_1/ladingbox_1.json',
	LOADING = 'homework/load/load.ExportJson'
}

local function open_loadingbox( parent )
	local s = uikits.fromJson{file=ui.LOADBOX}
	s:setAnchorPoint{x=0.5,y=0.5}
	local size = parent:getSize()
	s:setPosition{x=size.width/2,y=size.height/2}
	--居中显示
	parent:addChild( s )
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.LOADING)
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.LOADING)	
	s._circle = ccs.Armature:create('load')
	s._circle:getAnimation():playWithIndex(0)
	s._circle:setAnchorPoint(cc.p(0.5,0.5))
	size = s:getSize()
	s._circle:setPosition(cc.p(size.width/2,size.height*2/3))
	s:addChild( s._circle )
	s:setTouchEnabled(false)
	return s
end

return 
{
	open = open_loadingbox,
}