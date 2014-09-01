local kits = require "kits"
local uikits = require "uikits"

local Console = class("Console")
Console.__index = Console
local isopen = false
function Console.create()
	if isopen then return end
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Console)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function Console:init()
	isopen = true
	local glview = cc.Director:getInstance():getOpenGLView()
	local ss = glview:getFrameSize()
	local scale = uikits.scale()
	local bh = 64*scale
	local view = uikits.scrollview{width=ss.width*scale,height=ss.height*scale-bh,y=bh,bgcolor=cc.c3b(0,0,64)}
	local close = uikits.button{caption="close",
			fontSize=32*scale,width=128*scale,height=64*scale,
			anchorX=0,anchorY=0}
	uikits.event(close,function(sender)
		uikits.popScene()
	end )
	local h = 0
	local item_h = 24*scale
	local logs_org=kits.get_logs()
	local logs = {}
	for i = 1,#logs_org do
		table.insert(logs,logs_org[#logs_org-i+1])
	end
	uikits.scrollview_step_add(view,logs,20,
		function(msg)
			if msg then
				local color
				local title = string.sub(msg,1,4)
				if title=='ERRO' or title=='erro' then
					color = cc.c3b(255,0,0)
				elseif title=='WARN' or title=='warn' then
					color = cc.c3b(255,255,0)
				elseif title=='INFO' or title=='info' then
					color = cc.c3b(0,255,0)
				else
					color = cc.c3b(255,255,255)
				end
				local ox
				if string.sub(msg,1,1)=='\t' then
					ox = 32*scale
				else
					ox = 0
				end
				local length = string.len(msg)
				local maxn = 96
				if length < maxn then
					local item = uikits.text{caption=msg,x=ox,y=h,fontSize=item_h,color=color}
					view:addChild(item)
					h = h + item_h
				else
					--折行
					local i = 1
					local s = {}
					while i<=length do
						table.insert(s,string.sub(msg,i,i+maxn))
						i = i + maxn + 1
					end
					for i=1,#s do
						local item = uikits.text{caption=s[#s-i+1],x=ox,y=h,fontSize=item_h,color=color}
						view:addChild(item)
						h = h + item_h						
					end
				end
			else --重新布局
				view:setInnerContainerSize(cc.size(ss.width*scale*2,h+2*item_h))			
				view:scrollToBottom(0.1,true)
			end
		end,ccui.ScrollviewEventType.scrollToTop)
		
	self:addChild(view)
	self:addChild(close)
end

function Console:release()
	isopen = false
end

return Console