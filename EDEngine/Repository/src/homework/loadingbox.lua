local uikits = require "uikits"

local ui = {
	LOADBOX = 'homework/ladingbox_1/ladingbox_1.json',
}

local function open_loadingbox( parent )
	local s = uikits.fromJson{file=ui.LOADBOX}
	s:setAnchorPoint{x=0.5,y=0.5}
	local size = parent:getSize()
	s:setPosition{x=size.width/2,y=size.height/2}
	--居中显示
	parent:addChild( s )
	return s
end

return 
{
	open = open_loadingbox,
}