local uikits = require "uikits"

local ui = {
	LOADBOX = 'homework/ladingbox_1/ladingbox_1.json',
	LOADING = 'homework/load/load.ExportJson',
	FILE = 'homework/network_error/networkbox.json', --网络错误
	FILE2 = 'homework/network_error/repairbox.json', --系统维护500
	EXIT = 'red_in/out',
	TRY = 'red_in/again',
}

local function open_loadingbox( parent,dt,func )
	local s
	if dt == 1 then
		s = uikits.fromJson{file=ui.LOADBOX}
	elseif dt == 2 then
		s = uikits.fromJson{file=ui.FILE}
	elseif dt == 3 then
		s = uikits.fromJson{file=ui.FILE2}
	else
		s = uikits.fromJson{file=ui.LOADBOX}
	end
	s:setAnchorPoint{x=0.5,y=0.5}
	local size
	if parent.getSize then
		size = parent:getSize()
	else
		size = uikits.screenSize()
		size.width = size.width * uikits.scale()
		size.height = size.height * uikits.scale()
	end
	s:setPosition{x=size.width/2,y=size.height/2}
	--居中显示
	parent:addChild( s )
	if dt == 1 or not dt then
		--旋转体
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.LOADING)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.LOADING)	
		s._circle = ccs.Armature:create('load')
		s._circle:getAnimation():playWithIndex(0)
		s._circle:setAnchorPoint(cc.p(0.5,0.5))
		size = s:getSize()
		s._circle:setPosition(cc.p(size.width/2,size.height*2/3))
		s:addChild( s._circle )
	end
	if func then
		local quit = uikits.child(s,ui.EXIT)
		local try = uikits.child(s,ui.TRY)
		if quit then
			uikits.event( quit,function(sender)
											func( 5 )
										end,'click')
		end
		if try then
			uikits.event( try,function(sender)
											func( 4 )
										end,'click')		
		end
	end
	return s
end

return 
{
	LOADING = 1,
	RETRY = 2,
	REPAIR = 3,
	TRY = 4,
	CLOSE = 5,
	open = open_loadingbox,
}