local uikits = require "uikits"

local ui = {
	LOADBOX = 'homework/ladingbox_1/ladingbox_1.json',
	LOADING = 'homework/load/load.ExportJson',
	FILE = 'homework/network_error/networkbox.json', --网络错误
	FILE2 = 'homework/network_error/repairbox.json', --系统维护500
	EXIT = 'red_in/out',
	TRY = 'red_in/again',
}

--放一个旋转圈
local function put_lading_circle( parent )
	local size
	if not parent then return end
	
	if parent.getSize then
		size = parent:getSize()
	else
		size = uikits.screenSize()
		size.width = size.width * uikits.scale()
		size.height = size.height * uikits.scale()
	end
	--旋转体
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.LOADING)
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.LOADING)	
	local circle = ccs.Armature:create('load')
--BUG? 不能加入相对布局窗体中
--	local layout = uikits.layout{bgcolor=cc.c3b(math.random(0,255),math.random(0,255),math.random(0,255)),
		--bgcolor2=cc.c3b(math.random(0,255),math.random(0,255),math.random(0,255)),anchorX=0.5,anchorY=0.5,
		--x = size.width/2,y = size.height/2,width,width=100,height=100
		--}
	if circle then
		circle:getAnimation():playWithIndex(0)
		circle:setAnchorPoint(cc.p(0.5,0.5))
		circle:setPosition( cc.p(size.width/2,size.height/2) )
	--	layout:addChild( circle )
		parent:addChild( circle )
		return circle
	end
end

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
	circle = put_lading_circle,
}