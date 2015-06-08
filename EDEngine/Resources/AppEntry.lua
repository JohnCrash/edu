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
		--self:Snow(true)
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
	
	local debugip = uikits.editbox{
		caption = '192.168.2.*',
		x=320*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale
	}
	debugip:setText("192.168.2.182")
	
	local amouse = uikits.button{caption='打地鼠',x=64*scale,y = 64*scale +5*item_h,
	width=128*scale,height=48*scale,
	eventClick=function(sender)
		update.create{name='amouse',updates={'amouse','luacore'},
			run=function()
			login.set_selector(5)
			uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
			local amouse = require "amouse/amouse_om"
			return AMouseMain()
		end}		
	end}
		
	local tbutton = uikits.button{caption='新打地鼠(学生)',x=64*scale,y = 64*scale +4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='hitmouse',updates={'luacore'},
				run=function()
				login.set_uid_type(login.STUDENT)
				login.set_selector(4)--学生
				local hitmouse = require "hitmouse/main"
				return hitmouse.create()
			end}			
		end}
	local sbutton = uikits.button{caption='新打地鼠(管理)',x=64*scale,y = 64*scale + 3*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='hitmouse',updates={'luacore'},
				run=function()
				login.set_uid_type(login.TEACHER)
				login.set_selector(2)
				local hitmouse = require "amouse/amouse_om"
				return hitmouse.create()
				end}
		end}
	local ebutton = uikits.button{caption='错题本',x=64*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='errortitle',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_uid_type(login.STUDENT)
				login.set_selector(1) --学生
				local Loading = require "errortitile/Loading"
				return Loading.create()
			end}
		end}
	--[[	
	local epbutton = uikits.button{caption='家长错题本',x=64*scale,y = 64*scale + 6*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='parenterrortitle',updates={'homework','errortitile','luacore'},
				run=function()
				login.set_uid_type(login.PARENT)
				login.set_selector(3) --家长
				local Loading = require "errortitile/Loading"
				return Loading.create()
			end}
		end}
		--]]
	local epbutton = uikits.button{caption='错题',x=64*scale,y = 64*scale + 6*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='errortitlenew',updates={'errortitlenew','luacore'},
				run=function()
				login.set_selector(3) 
				local selstudent = require "errortitlenew/Loading"
				return selstudent.create()
			end}
		end}
	local pbutton = uikits.button{caption='卡牌',x=64*scale,y = 64*scale + 7*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
				login.set_selector(3) 
				local selstudent1 = require "poetrymatch/Loading"
				uikits.pushScene( selstudent1.create() )
		end}
	local g_last
	local record =  uikits.button{caption='show BaiduVoice',x=264*scale,y = 64*scale + 4*item_h,
		width=128*scale,height=48*scale,
	}
	local box = debugip
	uikits.event( record,
		function(sender,eventType)
			if cc_showBaiduVoice then
				cc_showBaiduVoice( function(text)
					if cc_isobj(box) then
						box:setText(text)
					else
						print(text)
					end
				end)
			end
		end)	
	local playsound = uikits.button{caption='Test Class',x=464*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
				local factory = require "factory"
				local base = require "base"
				local uuidClassSearcher = '621d7bfe3db93cbdcdb4c1f47a79f336'
				local progressbox = factory.create(base.ProgressBox)
				progressbox:open()
				progressbox:setProgress(0)	
				factory.import({uuidClassSearcher},
						function(b,err)
							progressbox:close()
							if b then
								local searcher = factory.create(uuidClassSearcher)
								searcher:push()
							else
									kits.log("")
							end
						end,
						function(d,txt)
							progressbox:setProgress(d)
							progressbox:setText(tostring(math.floor(d*100))..'% '..tostring(txt))						
						end)
			end}
	local resetwindow = uikits.button{caption='messagebox',x=264*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
				local messagebox = require "messagebox"
				messagebox.open(bg,function()end,messagebox.REPAIR,"title","text")
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
		fontSize = 64,
		x=320*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale
	}
	debugip:setText("192.168.2.75")
	local isopen = false
	local debugbutton = uikits.button{caption='调试...',x=320*scale,y = 64*scale + item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			if not isopen then
				require("mobdebug").start(debugip:getStringValue())
				isopen = true
			end
		end}	
	local testInput = uikits.editbox{
		caption = 'TEST INPUT',
		fontSize = 64,
		x=(320+320)*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale
	}
	testInput:setText("TEST INPUT")
	bg:addChild(testInput)
	local height_ = 0
	local idx = 4
	local ffmpeg_as
	local sp,sp2
	local ff = uikits.button{caption='FFMPEG',x=664*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			local moveies = { 
			"g:/Shake It Off.mp3",
			"g:/music_logo.mp3",
			"http://dl-lejiaolexue.qiniudn.com/07766ef6c835484fa8eaf606353f0cee.m3u8",
			"http://dl-lejiaolexue.qiniudn.com/92dc0b8689d64c1682d3d3f2501b3e8d.m3u8",
			"http://dl-lejiaolexue.qiniudn.com/729c4a6a87c541ff8e9eff183ce98658.m3u8",
			"http://dl-lejiaolexue.qiniudn.com/835764b62d6e47e9b0c7cab42ed90fa3.m3u8",
			}
			local ffplayer = require "ffplayer"
			if ffmpeg_as then ffmpeg_as:close() end
			if sp then 
				sp:removeFromParent()
				sp=nil
			end
			if sp2 then
				sp2:removeFromParent()
				sp2=nil			
			end
			if idx > #moveies then
				idx = 3
			end
			ffmpeg_as = ffplayer.playStream(moveies[idx],function(state,stream,tx)
					if state ~=5 then
						print( "state:"..state)
					end
					if state==ffplayer.STATE_OPEN then
						stream:seek(stream.length*0.8)
						stream:play()
					elseif state==ffplayer.STATE_OPEN_VIDEO and tx then
						sp = cc.Sprite:createWithTexture(tx)
						sp:setAnchorPoint(cc.p(0,0))
						sp:setPosition(cc.p(0,0))
						bg:addChild(sp)
						sp2 = cc.Sprite:createWithTexture(tx)
						sp2:setScaleX(2)
						sp2:setScaleY(2)
						sp2:setAnchorPoint(cc.p(0,0))
						sp2:setPosition(cc.p(stream.width,0))					
						bg:addChild(sp2)
						--stream:pause()
					elseif state==ffplayer.STATE_PROGRESS then
						print( "progress "..math.floor(10000*stream.current/stream.length)/100)
					end
				end)
				idx = idx + 1
		end}		
	bg:addChild(ff)
	local as
	local ffplay = uikits.button{caption='FFAUDIO',x=464*scale,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			local ffplayer = require "ffplayer"
			if as then as:close() end
			local filename = "G:/Maps.mp3"
			as = ffplayer.playStream(filename,
				function(state,as)
					print("STATE:"..state)
					if state == ffplayer.STATE_PROGRESS then
						print( "progress "..math.floor(10000*as.current/as.length)/100)
					else
						print( "CURRENT STATE : "..state )
					end
				end)
		end}
	local play = uikits.button{caption='play',x=464*scale+300,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			as:seek(as.length*0)
			as:play()
		end}
	local pause = uikits.button{caption='pause',x=464*scale-300,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			as:pause()
		end}		
	local close = uikits.button{caption='close',x=464*scale-600,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			as:close()
		end}		
	bg:addChild(close)	
	bg:addChild(pause)	
	bg:addChild(play)	
	bg:addChild(ffplay)
	--[[-----------------------------------
	local ti = os.clock()
	local moLaBattle = require "poetrymatch/BattleScene/LaBattle"
	local laBattle = moLaBattle.Class:create()
	bg:addChild(laBattle, 10)
	print(string.format("time is %f", os.clock() - ti))




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
