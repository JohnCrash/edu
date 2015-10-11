local kits = require "kits"
local uikits = require "uikits"
local update = require "update"
local login = require "login"
local resume = require "resume"
require "ljshellDeprecated"
local RecordVoice = require "recordvoice"
local mt = require "mt"

hw_cur_child_id = 0
local ui = {
}

-----------------
local function request_n( url,func,prog )
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK' and obj.data then
						func( true,obj.data )
					else
						func( false,obj.errmsg )
					end
				elseif obj.state == 'LOADING' and prog then
					prog( obj.progress )
				end
			end )
	if not mh then
		func( false,msg )
		kits.log('ERROR : request failed! url = '..tostring(url))
		kits.log('	reason:'..tostring(msg))
	end
end

local function messagebox(caption,text,button,func)
	local factory = require "factory"
	local base = require "base"
	local messageBox = factory.create(base.MessageBox)
	messageBox:open{caption=caption,text=text,onClick=func,button=button or 1}
end
-----------------

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

local users = {
        {
           LoginUserName="s16600000001",
            NickName="平板01",
            UserID=1602035,
            sc1="8481103C1DBA5F0D150556812A6263ED0A7F9ABBakt%2fMAHsC52KiGgNI1Rn6lAqah%2buIFjv8AuIl4WZ%2bxYnBkqOgDwlYzegoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000002",
            NickName="平板02",
            UserID=1602037,
            sc1="613C1EBBE6E3F572383C8643AB028FEC5CEADB65akt%2fMAHsCZ2KiGgNI1Rn6lAqahyuIFjv8AuIl4WZ%2bxYnBkqOgDwlYzSgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000003",
            NickName="平板03",
            UserID=1602039,
            sc1="857BD714837FCD492BB3B7129419961F64F49A8Cakt%2fMAHsB52KiGgNI1Rn6lAqah2uIFjv8AuIl4WZ%2bxYnBkqOgDwlYzWgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000004",
            NickName="平板04",
            UserID=1602041,
            sc1="350CFA81E4631C3FD36AB788BEA711576C3EDE8Cakt%2fMAHrD52KiGgNI1Rn6lAqahquIFjv8AuIl4WZ%2bxYnBkqOgDwlYzKgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000005",
            NickName="平板05",
            UserID=1602043,
            sc1="8FADE7281A03B5F2D0CCE353E470DF71F948FDEBakt%2fMAHrDZ2KiGgNI1Rn6lAqahuuIFjv8AuIl4WZ%2bxYnBkqOgDwlYzOgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000006",
            NickName="平板06",
            UserID=1602045,
            sc1="E4BCEE72EF8521FA8B83A7029E0747245B4D8624akt%2fMAHrC52KiGgNI1Rn6lAqahiuIFjv8AuIl4WZ%2bxYnBkqOgDwlYzCgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000007",
            NickName="平板07",
            UserID=1602047,
            sc1="DFD5DD495A09A01AE34FC00348E12F5D60FAF34Aakt%2fMAHrCZ2KiGgNI1Rn6lAqahmuIFjv8AuIl4WZ%2bxYnBkqOgDwlYzGgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000008",
            NickName="平板08",
            UserID=1602049,
            sc1="A3AF29E2B9471FA0803A85EEC587221F88407BD4akt%2fMAHrB52KiGgNI1Rn6lAqahauIFjv8AuIl4WZ%2bxYnBkqOgDwlYz6goVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000009",
            NickName="平板09",
            UserID=1602051,
            sc1="528F0DDAA64AF45B5B9576FA3018CAA15E377A8Dakt%2fMAHqD52KiGgNI1Rn6lAqaheuIFjv8AuIl4WZ%2bxYnBkqOgDwlYz%2bgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000010",
            NickName="平板10",
            UserID=1602053,
            sc1="60BF7393485EF8045828C7A66202C8B521CB638Dakt%2fMAHqDZ2KiGgNI1Rn6lAqax6uIFjv8AuIl4WZ%2bxYnBkqOgDwlYjagoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000011",
            NickName="平板11",
            UserID=1602055,
            sc1="B78CFF1B2FF97170EA3944894BB185B222D469B2akt%2fMAHqC52KiGgNI1Rn6lAqax%2buIFjv8AuIl4WZ%2bxYnBkqOgDwlYjegoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000012",
            NickName="平板12",
            UserID=1602057,
            sc1="30EC1E99CAC52EC2FE7C8A3968A6BA4000640A8Eakt%2fMAHqCZ2KiGgNI1Rn6lAqaxyuIFjv8AuIl4WZ%2bxYnBkqOgDwlYjSgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000013",
            NickName="平板13",
            UserID=1602059,
            sc1="60D6AF55C114280769A69F6C1D1E48D7ABD06510akt%2fMAHqB52KiGgNI1Rn6lAqax2uIFjv8AuIl4WZ%2bxYnBkqOgDwlYjWgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000014",
            NickName="平板14",
            UserID=1602061,
            sc1="E4C711CD3EF527B1685004BD1F134E5817724D67akt%2fMAHpD52KiGgNI1Rn6lAqaxquIFjv8AuIl4WZ%2bxYnBkqOgDwlYjKgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000015",
            NickName="平板15",
            UserID=1602063,
            sc1="ECD63BA4222AFC8D02BC1B7AF743590F3AF5FFA6akt%2fMAHpDZ2KiGgNI1Rn6lAqaxuuIFjv8AuIl4WZ%2bxYnBkqOgDwlYjOgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000016",
            NickName="平板16",
            UserID=1602065,
            sc1="F33741EC071F1E38134C49C49C04BD3293C36096akt%2fMAHpC52KiGgNI1Rn6lAqaxiuIFjv8AuIl4WZ%2bxYnBkqOgDwlYjCgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000017",
            NickName="平板17",
            UserID=1602067,
            sc1="4DFEC060D2E589057B049072C4010C20F81F7418akt%2fMAHpCZ2KiGgNI1Rn6lAqaxmuIFjv8AuIl4WZ%2bxYnBkqOgDwlYjGgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000018",
            NickName="平板18",
            UserID=1602069,
            sc1="69FB6FADD921D70BD8089CA13E9B7DAFD7E8A79Eakt%2fMAHpB52KiGgNI1Rn6lAqaxauIFjv8AuIl4WZ%2bxYnBkqOgDwlYj6goVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000019",
            NickName="平板19",
            UserID=1602071,
            sc1="C07794C0871583D5A12115C17F472CE4121361D6akt%2fMAHoD52KiGgNI1Rn6lAqaxeuIFjv8AuIl4WZ%2bxYnBkqOgDwlYj%2bgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000020",
            NickName="平板20",
            UserID=1602073,
            sc1="2E42A7D85708517B61ED0E5EF621CE971F45D5A4akt%2fMAHoDZ2KiGgNI1Rn6lAqaB6uIFjv8AuIl4WZ%2bxYnBkqOgDwlYTagoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000021",
            NickName="平板21",
            UserID=1602075,
            sc1="B8E71BECED0AFDF0F56AC3BEC412AACAD1B08BF0akt%2fMAHoC52KiGgNI1Rn6lAqaB%2buIFjv8AuIl4WZ%2bxYnBkqOgDwlYTegoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000022",
            NickName="平板22",
            UserID=1602077,
            sc1="59AC36C52EE584B3AFD8C689A91FE83E34346830akt%2fMAHoCZ2KiGgNI1Rn6lAqaByuIFjv8AuIl4WZ%2bxYnBkqOgDwlYTSgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000023",
            NickName="平板23",
            UserID=1602079,
            sc1="F0F8985C4AE0FF2C4CF82E791005F152D897AC6Cakt%2fMAHoB52KiGgNI1Rn6lAqaB2uIFjv8AuIl4WZ%2bxYnBkqOgDwlYTWgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000024",
            NickName="平板24",
            UserID=1602081,
            sc1="16E6A57490D06AD47018D10BD5EEA591AACDB5ABakt%2fMAHnD52KiGgNI1Rn6lAqaBquIFjv8AuIl4WZ%2bxYnBkqOgDwlYTKgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000025",
            NickName="平板25",
            UserID=1602083,
            sc1="FE474B408BEA573D4EAEC9C4ED5D32633C6623F0akt%2fMAHnDZ2KiGgNI1Rn6lAqaBuuIFjv8AuIl4WZ%2bxYnBkqOgDwlYTOgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000026",
            NickName="平板26",
            UserID=1602085,
            sc1="C62E2290C82DC0656EC990F8F77F246D1DF3DBB2akt%2fMAHnC52KiGgNI1Rn6lAqaBiuIFjv8AuIl4WZ%2bxYnBkqOgDwlYTCgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000027",
            NickName="平板27",
            UserID=1602087,
            sc1="E3416DDFB634B4EB579D7D7A89CBC16CCCBFDBE8akt%2fMAHnCZ2KiGgNI1Rn6lAqaBmuIFjv8AuIl4WZ%2bxYnBkqOgDwlYTGgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000028",
            NickName="平板28",
            UserID=1602089,
            sc1="900BEDB97B3BA20710C101A9EE2D51F18A2360D6akt%2fMAHnB52KiGgNI1Rn6lAqaBauIFjv8AuIl4WZ%2bxYnBkqOgDwlYT6goVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000029",
            NickName="平板29",
            UserID=1602091,
            sc1="FC9E8A6F5A3181962323ACA15397FBA58D0BBC5Dakt%2fMAHmD52KiGgNI1Rn6lAqaBeuIFjv8AuIl4WZ%2bxYnBkqOgDwlYT%2bgoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
        {
           LoginUserName="s16600000030",
            NickName="平板30",
            UserID=1602093,
            sc1="1CE186C9354272D067D1F1ECA898D9820BF97049akt%2fMAHmDZ2KiGgNI1Rn6lAqaR6uIFjv8AuIl4WZ%2bxYnBkqOgDwlYDagoVCE9E%2fxTOLjwN1Zkm7MiCBdqXsBOrVzzLK83LvX9QEDKV4Dyjc%3d"
        },
}

function AppEntry:init()
	--self:Snow(true)
	--self:LavaFlow(32)
	local glview = cc.Director:getInstance():getOpenGLView()
	local ss = glview:getFrameSize()
	local scale = 2
	local bg = uikits.layout{width=ss.width*scale,height=ss.height*scale}
	local item_h = 64*scale
	
	local col = 6
	local ox = 24*scale
	local oy = 32*scale
	local space = 24*scale
	local width = 128*scale
	local height = 48*scale
	for i,v in pairs(users) do
		local but = uikits.button{caption=v.NickName,x=((i-1)%col)*(width+space)+ox,y=math.floor((i-1)/col)*(height+space)+oy,
			width=width,height=height,
			eventClick=function(sender)
				login.set_cookie( 'sc1='..v.sc1 )
				login.set_userid( v.UserID )
				--local selstudent1 = require "poetrymatch/Loading"
				--uikits.replaceScene( selstudent1.create() )
				update.create{name='poetrymatch',updates={'poetrymatch','luacore'},
					run=function()
					local selstudent = require "poetrymatch/Loading"
					return selstudent.create()
				end}				
			end}
		bg:addChild( but )
	end
	local dbg_but = uikits.button{caption="打开调试",x=ox,y=(height+space)*5+space,
			width=width,height=height,
			eventClick=function(sender)
				kits.config("debug",true)
			end}
	bg:addChild(dbg_but)
	local dbg_but_close = uikits.button{caption="关闭调试",x=ox+width+space,y=(height+space)*5+space,
			width=width,height=height,
			eventClick=function(sender)
				kits.config("debug",false)
			end}
	bg:addChild(dbg_but_close)	
	local setup_but = uikits.button{caption="安装客户端",x=ox+2*(width+space),y=(height+space)*5+space,
			width=width,height=height,
			eventClick=function(sender)
				local url = "http://192.168.2.8/app/EDEngine.apk"
				cc_openURL(url)
			end}
	bg:addChild(setup_but)		
	self:addChild(bg)
	resume.clearflag("update") --update isok
end

function AppEntry:release()
	
end

return AppEntry
