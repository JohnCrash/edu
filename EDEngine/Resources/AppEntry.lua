local kits = require "kits"
local uikits = require "uikits"
local update = require "update"
local login = require "login"
local resume = require "resume"
require "ljshellDeprecated"
local RecordVoice = require "recordvoice"

hw_cur_child_id = 0
local ui = {
}

----------------------------------



-----------------------------------

local ljshell = require "ljshell"
kits.log('ShareDir:'..ljshell.getDirectory(ljshell.ShareDir))
kits.log('DataDir:'..ljshell.getDirectory(ljshell.DataDir))
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

--粒子系统(礼花)
function AppEntry:LavaFlow( N )
	local ss = self:getContentSize()
	local function flower()
		local plist = 'Particles/ExplodingRing.plist'
		local emitter = {}
		for i = 1,N do
			emitter[i] = cc.ParticleSystemQuad:create(plist)
			emitter[i]:setPosition(cc.p(ss.width*(i+7)/ (N+2), ss.height / 1.25))
			emitter[i]:setStartColor(cc.c4f(0,0,0,1))
		end
		
		local batch = cc.ParticleBatchNode:createWithTexture(emitter[1]:getTexture())

		for i = 1,N do
			batch:addChild(emitter[i], 0)
		end

		self:addChild(batch, 10)
		self:Snow(true)
		self._cn_label = cc.LabelTTF:create("周末愉快", "Marker Felt", 128)
		self._cn_label:setPosition(cc.p(ss.width/2,ss.height*4/5))
		self:addChild(self._cn_label)
	end
	--先起来然后开花
	local amgr = cc.Director:getInstance():getActionManager()
	
	for i = 1,N do
		local emitter = cc.ParticleSystemQuad:create("Particles/lightDot.plist")
		local x = ss.width*(i+1)/ (N+2) - ss.width/2 --(N+1)/ (2*(N+2))
		local action = cc.MoveBy:create(0.8,cc.p(x,ss.height / 1.25))
		amgr:addAction( action,emitter,true)
		self:addChild(emitter)
		emitter:setPosition(ss.width / 2, 0)
	end
	uikits.delay_call( self,flower,1 )
end

s_snow='Particles/ExplodingRing.png'
--粒子系统(飘动)
function AppEntry:Snow( b )
	if not self._emitter and b then
		local emitter = cc.ParticleSnow:create()
		local pos_x, pos_y = emitter:getPosition()
		emitter:setPosition(pos_x, pos_y - 110)
		emitter:setLife(3)
		emitter:setLifeVar(1)

		-- gravity
		emitter:setGravity(cc.p(0, -10))

		-- speed of particles
		emitter:setSpeed(130)
		emitter:setSpeedVar(30)

		local startColor = emitter:getStartColor()
		startColor.r = 0.9
		startColor.g = 0.9
		startColor.b = 0.9
		emitter:setStartColor(startColor)

		local startColorVar = emitter:getStartColorVar()
		startColorVar.b = 0.1
		emitter:setStartColorVar(startColorVar)

		emitter:setEmissionRate(emitter:getTotalParticles() / emitter:getLife())

		emitter:setTexture(cc.Director:getInstance():getTextureCache():addImage(s_snow))

		local size = self:getContentSize()
		emitter:setPosition(size.width / 2, size.height)
		
		self._emitter = emitter
		self:addChild(self._emitter, 10)
	elseif self._emitter then
		self._emitter:removeFromParent()
		self._emitter = nil
	end
end

function AppEntry:init()
	--self:Snow(true)
	--self:LavaFlow(32)
	local glview = cc.Director:getInstance():getOpenGLView()
	local ss = glview:getFrameSize()
	local scale = 2
	local bg = uikits.layout{width=ss.width*scale,height=ss.height*scale}
	local item_h = 64*scale
	
	local amouse = uikits.button{caption='打地鼠',x=64*scale,y = 64*scale +5*item_h,
	width=128*scale,height=48*scale,
	eventClick=function(sender)
		update.create{name='amouse',updates={'amouse','luacore'},
			run=function()
			uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
			local amouse = require "amouse/amouse_om"
			return AMouseMain()
		end}		
	end}
		
	local tbutton = uikits.button{caption='老师作业',x=64*scale,y = 64*scale +4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='teacher',updates={'homework','luacore'},
				run=function()
				login.set_selector(2)
				local teacher = require "homework/teacher"
				return teacher.create()
			end}			
		end}
	local sbutton = uikits.button{caption='学生作业',x=64*scale,y = 64*scale + 3*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='student',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(1) --学生
				local worklist = require "homework/worklist"
				return worklist.create()
				end}
		end}
	local ebutton = uikits.button{caption='错题本',x=64*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='errortitle',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(1) --学生
				local Loading = require "errortitile/Loading"
				return Loading.create()
			end}
		end}
		
	local epbutton = uikits.button{caption='家长错题本',x=64*scale,y = 64*scale + 6*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='parenterrortitle',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(3) --家长
				local Loading = require "errortitile/Loading"
				return Loading.create()
			end}
		end}
		
	local pbutton = uikits.button{caption='家长作业本',x=64*scale,y = 64*scale + 7*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='parenthw',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(3) --家长
				local selstudent = require "homework/selstudent.lua"
				return selstudent.create()
			end}
		end}
	local g_last
	local record =  uikits.button{caption='录音',x=264*scale,y = 64*scale + 4*item_h,
		width=128*scale,height=48*scale,
	}
	uikits.event( record,
		function(sender,eventType) 
			RecordVoice.open(
							bg,
							function(b,file)
								self._recording = nil
								if b then
									local tlen = cc_getVoiceLength(file)
									g_last = file
								end
							end
						) 
		end)	
	local playsound = uikits.button{caption='播放',x=464*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
				kits.log("play "..tostring(g_last))
				if cc_playVoice(g_last) then
					kits.log('play success')
				else
					kits.log('play fail')
				end
			end}	
	local resetwindow = uikits.button{caption='重启改变尺寸',x=264*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
				local mode,width,height = cc_getWindowInfo()
				print( 'mode = '..mode )
				print( 'width = '..width )
				print( 'height = '..height )
				width,height = cc_getScreenInfo()
				print( 'screenwidth = '..width )
				print( 'screenheight = '..height )
--				if cc_resetWindow("window",480,640) then
					local Director = cc.Director:getInstance()
					local glview = Director:getOpenGLView()
					glview:setFrameSize(480,640)	
--					Director:endToLua()
--				end
			end}				
	local cam =   uikits.button{caption='拍照',x=464*scale,y = 64*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			kits.log("cam")
			cc_takeResource(TAKE_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						--file = res
					else
						kits.log("cc_takeResource return fail")
					end
				end)
			end}
	local photo =   uikits.button{caption='图库',x=664*scale,y = 64*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			kits.log("photo")
			cc_takeResource(PICK_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						--file = res
						local b,res = cc_adjustPhoto(res,128)
						if b then
							kits.log('adjust success '..res)
						else
							kits.log('adjust fail : '..res)
						end
					else
						kits.log("cc_takeResource return fail")
					end
				end)
			end}
		
	local exitbutton = uikits.button{caption='退出',x=64*scale,y = 64*scale + item_h,
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
	local debugbutton = uikits.button{caption='调试...',x=320*scale,y = 64*scale + item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			if not isopen then
				require("mobdebug").start(debugip:getStringValue())
				isopen = true
			end
		end}	

	--[[-----------------------------------
	local moLaStatisticsStudent = require "homework/lly/LaStatisticsTeacher"
	print("2hahahahah")

	local layStats = moLaStatisticsStudent.Class:create()
	bg:addChild(layStats, 100)

	layStats:enter()

	----------------]]

	bg:addChild(resetwindow)
	bg:addChild(playsound)
	bg:addChild(debugip)
	bg:addChild(debugbutton)
	bg:addChild(amouse)
	bg:addChild(tbutton)
	bg:addChild(sbutton)
	bg:addChild(ebutton)
	bg:addChild(epbutton)
	bg:addChild(pbutton)
	bg:addChild(exitbutton)
	bg:addChild(record)
	bg:addChild(cam)
	bg:addChild(photo)
	self:addChild(bg)
	resume.clearflag("update") --update isok
end

function AppEntry:release()
	
end

return AppEntry
