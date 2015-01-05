local kits = require "kits"
local uikits = require "uikits"

local ui = {
	LOADBOX = 'load/ladingbox.json',
	LOADING = 'load/load.ExportJson',
	FILE = 'messagebox/networkbox.json', --网络错误
	FILE2 = 'messagebox/repairbox.json', --系统维护500
	FILE3 = 'messagebox/tanchu.json',
	EXIT = 'red_in/out',
	TRY = 'red_in/again',
	OK = 'qr',
}

local function messagebox( parent,func,dt,caption,text )
	local s
	if not parent then return end
	if not cc_isobj(parent) then return end
	if dt == 1 then
		s = uikits.fromJson{file=ui.LOADBOX}
		s._text = uikits.child(s,"loading_txet")
		
		if title and caption then
			s._text:setString( tostring(caption))
		end		
	elseif dt == 2 then
		s = uikits.fromJson{file=ui.FILE}
		s._caption = uikits.child(s,"text")
		if caption then
			s._caption:setString( tostring(caption))
		end
		s._text = uikits.child(s,"text2")
		if text then
			s._text:setString( tostring(text) )
		end
	elseif dt == 3 then
		s = uikits.fromJson{file=ui.FILE2}
		s._caption = uikits.child(s,"text")
		if caption then
			s._caption:setString( tostring(caption))
		end
		s._text = uikits.child(s,"text2")
		if text then
			s._text:setString( tostring(text) )
		end		
	elseif dt == 6 then --message
		s = uikits.fromJson{file=ui.FILE3}
		local tt = uikits.child(s,'text_0')
		local label = uikits.child(s,'Label_10')
		if tt and caption then
			tt:setString( caption )
		end
		if label and text then
			label:setString( text )
		end
	else
		s = uikits.fromJson{file=ui.LOADBOX}
	end
	s:setAnchorPoint{x=0.5,y=0.5}
	local size
	if parent.getContentSize then
		size = parent:getContentSize()
	else
		size = uikits.getDR()
	end
	s:setPosition{x=size.width/2,y=size.height/2}
	--居中显示
	parent:addChild( s,9999 )
	if dt == 1 or not dt then
		--旋转体
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.LOADING)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(ui.LOADING)	
		s._circle = ccs.Armature:create('load')
		s._circle:getAnimation():playWithIndex(0)
		s._circle:setAnchorPoint(cc.p(0.5,0.5))
		size = s:getContentSize()
		s._circle:setPosition(cc.p(size.width/2,size.height*2/3))
		s:addChild( s._circle,9999 )
	end
	if func then
		local quit = uikits.child(s,ui.EXIT)
		local try = uikits.child(s,ui.TRY)
		local ok = uikits.child(s,ui.OK)
		if ok then
			if parent.setKeyboardEnabled then
				parent:setKeyboardEnabled(false)
			end
			uikits.event( ok,function(sender)
											if parent.setKeyboardEnabled then
												parent:setKeyboardEnabled(true)
											end
											uikits.delay_call(parent,function()
												s:removeFromParent()
											end,0)
											func( 5 )
										end,'click')
		end
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
	s.setString = function( self,text,caption )
		if self._text then
			self._text:setString( text )
		end
		if self._caption then
			self._caption:setString( caption )
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
	MESSAGE = 6,
	open = messagebox,
}