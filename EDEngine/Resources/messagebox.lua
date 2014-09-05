local kits = require "kits"
local uikits = require "uikits"

local ui = {
	LOADBOX = 'homework/ladingbox.json',
	LOADING = 'load/load.ExportJson',
	FILE = 'homework/networkbox.json', --网络错误
	FILE2 = 'homework/repairbox.json', --系统维护500
	EXIT = 'red_in/out',
	TRY = 'red_in/again',
}
local g_scale = 2
local function messagebox( parent,func,dt )
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
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.screenSize()
		size.width = size.width * g_scale
		size.height = size.height * g_scale
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
		size = s:getContentSize()
		s._circle:setPosition(cc.p(size.width/2,size.height*2/3))
		s:addChild( s._circle )
	end
	if func then
		local quit = uikits.child(s,ui.EXIT)
		local try = uikits.child(s,ui.TRY)
		if quit then
			uikits.event( quit,function(sender)
											uikits.delay_call(parent,function()
												s:removeFromParent()
											end,0)
											func( 5 )
										end,'click')
		end
		if try then
			uikits.event( try,function(sender)
											uikits.delay_call(parent,function()
												s:removeFromParent()
											end,0)
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
	open = messagebox,
}