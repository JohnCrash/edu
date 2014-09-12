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

--粒子系统(礼花)
function AppEntry:LavaFlow( N )
	local ss = self:getContentSize()
	local function flower()
		self:setColor(cc.c3b(0, 0, 0))
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
	self:LavaFlow(32)
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
		
	local epbutton = uikits.button{caption='parenterrortitle',x=64*scale,y = 64*scale + 6*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='parenterrortitle',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_selector(3) --学生
				local Loading = require "errortitile/Loading"
				return Loading.create()
			end}
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
	bg:addChild(debugip)
	bg:addChild(debugbutton)
	bg:addChild(amouse)
	bg:addChild(tbutton)
	bg:addChild(sbutton)
	bg:addChild(ebutton)
	bg:addChild(epbutton)
	bg:addChild(exitbutton)
	self:addChild(bg)
	resume.clearflag("update") --update isok
end

function AppEntry:release()
	
end

return AppEntry
