local kits = require "kits"
local uikits = require "uikits"

local Console = class("Console")
Console.__index = Console

local isopen_flag = false

function Console.isopen()
	return isopen_flag
end

function Console.create()
	if isopen_flag then return end
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

local function add_table( t,s )
	local i = 1
	local length = string.len(s)
	while i <= length do
		local begin = i
		i = string.find(s,'\n',i)
		if i then
			table.insert(t,string.sub(s,begin,i-1))
		else
			table.insert(t,string.sub(s,begin))
			break
		end
		i = i + 1
	end
end
local dr
function Console:init()
	isopen_flag = true
	dr = uikits.getDR()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	local glview = cc.Director:getInstance():getOpenGLView()
	local ss = glview:getFrameSize()
	local scale = 2
	local bh = 64*scale
	local view = uikits.scrollview{width=ss.width*scale,height=ss.height*scale-bh,y=bh,bgcolor=cc.c3b(0,0,64)}
	local close = uikits.button{caption="close",
			fontSize=32*scale,width=128*scale,height=64*scale,
			anchorX=0,anchorY=0}
	uikits.event(close,function(sender)
		uikits.initDR{width=dr.width,height=dr.height}
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
				--����
				local i = 1
				local s = {}
				while i<=length do
					add_table( s,string.sub(msg,i,i+maxn) )
					--table.insert(s,string.sub(msg,i,i+maxn))
					i = i + maxn + 1
				end
				for i=1,#s do
					local item = uikits.text{caption=s[#s-i+1],x=ox,y=h,fontSize=item_h,color=color}
					view:addChild(item)
					h = h + item_h
				end
			else --���²���
				view:setInnerContainerSize(cc.size(ss.width*scale*2,h+2*item_h))			
				view:scrollToBottom(0.1,true)
			end
		end,ccui.ScrollviewEventType.scrollToTop)
	--��һ������
	local debugip = uikits.editbox{
		caption = '192.168.2.*',
		x=128*scale,
		width=240*scale,height=320*scale
	}
	debugip:setText("192.168.2.182")
	local isdebug
	local debugbutton = uikits.button{caption='Debug...',fontSize=32*scale,x=(128+240)*scale,
		width=128*scale,height=64*scale,
		eventClick=function(sender)
			if not isdebug then
				require("mobdebug").start(debugip:getStringValue())
				isdebug = true
			end
		end}
	local exitbut = uikits.button{caption='Exit',fontSize=32*scale,x=(128+240+128)*scale,
		width=128*scale,height=64*scale,
		eventClick=function(sender)
			kits.quit()
		end}		
	local isOpen = false
	local update_directory_button = uikits.button{caption='Update server...',fontSize=32*scale,x=(128+240+2*128)*scale,
		width=128*2.5*scale,height=64*scale,
		eventClick=function(sender)
			if isOpen then return end
			local layout = uikits.layout{width=640*scale,height=128*scale,x=ss.width/2,y=ss.height/2,anchorX=0.5,anchorY=0.5,bgcolor=cc.c3b(0,0,0)}
			local edit = uikits.editbox{caption="http://file.lejiaolexue.com/upgrade/luaapp/v6/",y = 64*scale,width=640*scale,height=48*scale}
			local txt = uikits.text{caption="Modify update server:",width=640*scale,height=48,y=(64+48)*scale}
			local cancel = uikits.button{width=180*scale,height=64*scale,caption="Cancel"}
			local ok = uikits.button{width=320*scale,height=64*scale,caption="Ok",x=320*scale}
			local default = uikits.button{width=160*scale,height=64*scale,caption="Default",x=160*scale}
			local function close()
				uikits.delay_call( nil,function()
					layout:removeFromParent()
					isOpen = false
				end)
			end
			uikits.event( default,function(sender)
				edit:setText( "http://file.lejiaolexue.com/upgrade/luaapp/v6/" )
			end)
			uikits.event( ok,function(sender)
				local ip = edit:getStringValue()
				kits.log("modify update server :"..tostring(ip))
				kits.config("update_server",ip)
				kits.config("current_server",ip)
				close()
			end)
			uikits.event( cancel,function(sender)
				close()
			end)		
			edit:setText( tostring(kits.config("current_server","get")) )
			layout:addChild(default)
			layout:addChild(txt)
			layout:addChild(ok)
			layout:addChild(cancel)
			layout:addChild(edit)
			self:addChild(layout)
			isOpen = true
		end}		
	self:addChild(update_directory_button)		
	self:addChild(exitbut)		
	self:addChild(debugip)
	self:addChild(debugbutton)
	
	self:addChild(view)
	self:addChild(close)
end

function Console:release()
	isopen_flag = false
	uikits.initDR{width=dr.width,height=dr.height,mode=dr.mode}
end

return Console