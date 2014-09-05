local kits = require "kits"
local uikits = require "uikits"
local update = require "update"
local login = require "login"
local resume = require "resume"

local ui = {
}

local AppEntry = class("AppEntry")
AppEntry.__index = AppEntry

function AppEntry.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),AppEntry)
	
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

function AppEntry:init()
	local glview = cc.Director:getInstance():getOpenGLView()
	local ss = glview:getFrameSize()
	local scale = 2
	local bg = uikits.layout{width=ss.width*scale,height=ss.height*scale}
	local item_h = 64*scale
	
	local amouse = uikits.button{caption='amouse',x=64*scale,y = 64*scale +5*item_h,
	width=128*scale,height=48*scale,
	eventClick=function(sender)
		update.create{name='amouse',updates={'amouse','luacore'},
			run=function()
			uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
			local amouse = require "amouse/amouse_om"
			return AMouseMain()
		end}		
	end}
		
	local tbutton = uikits.button{caption='teacher',x=64*scale,y = 64*scale +4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='teacher',updates={'homework','luacore'},
				run=function()
				login.set_selector(2)
				local teacher = require "homework/teacher"
				return teacher.create()
			end}			
		end}
	local sbutton = uikits.button{caption='student',x=64*scale,y = 64*scale + 3*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='student',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(1) --学生
				local worklist = require "homework/worklist"
				return worklist.create()
				end}
		end}
	local ebutton = uikits.button{caption='errortitle',x=64*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='errortitle',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(1) --学生
				local Loading = require "errortitile/Loading"
				return Loading.create()
			end}
		end}
	local exitbutton = uikits.button{caption='exit',x=64*scale,y = 64*scale + item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			kits.quit()
		end}
	local debugip = uikits.editbox{
		caption = '192.168.2.*',
		x=320*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale
	}
	debugip:setText("192.168.2.182")
	local isopen = false
	local debugbutton = uikits.button{caption='debug...',x=320*scale,y = 64*scale + item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			if not isopen then
				require("mobdebug").start(debugip:getStringValue())
				isopen = true
			end
		end}	
	bg:addChild(debugip)
	bg:addChild(debugbutton)
	bg:addChild(amouse)
	bg:addChild(tbutton)
	bg:addChild(sbutton)
	bg:addChild(ebutton)
	bg:addChild(exitbutton)
	self:addChild(bg)
	resume.clearflag("update") --update isok
end

function AppEntry:release()
	
end

return AppEntry
