local kits = require "kits"
local uikits = require "uikits"
local update = require "update"
local login = require "login"
local resume = require "resume"
local mt = require "mt"
local pay = require "pay"

require "ljshellDeprecated"
local RecordVoice = require "recordvoice"

local app,cookie,uid = cc_launchparam()

if not cc_isdebug() and app == "" then
	return
end

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

local function keep_alive( url,func )
	local mh,msg = mt.new('GET',url,login.cookie(),
			function(obj)
				if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
					if obj.state == 'OK' and obj.data then
						func( true,obj.data )
					else
						func( false,obj.errmsg )
					end
				end
			end,true,30,20)
	if not mh then
		func( false,msg )
		kits.log('ERROR : request failed! url = '..tostring(url))
		kits.log('	reason:'..tostring(msg))
	end
	return mh,msg
end


local function zmq_test_1()
	local zmq = require"lzmq"

	local context = zmq.init(1)

	--  Socket to talk to server
	print("Connecting to hello world server...")
	local socket = context:socket(zmq.REQ)
	socket:connect("tcp://192.168.2.157:5555")
	
	print("zmq.REVTIMO="..tostring(zmq.RCVTIMEO))
	socket:setopt_int(zmq.RCVTIMEO,500)
	for n=1,10 do
		print("Sending Hello " .. n .. " ...")
		local msg,errorMsg = socket:send("Hello")
		if not msg then
			print("send error :"..tostring(errorMsg))
			break
		end
		msg,errorMsg = socket:recv()
		if msg then
			print("Received World " ..  n .. " [" ..msg.. "]")
		else
			print("recevied error : "..tostring(errorMsg))
			break
		end
	end
	socket:close(1)
	context:term()
end
local zmq = require"lzmq"

local context = zmq.init(1)
local function zmq_test()

	--  Socket to talk to server
	local thread = require "thread"
	local addr = "inproc://thread"
	thread.new("zmqth",function(event,msg)
	end,context:lightuserdata(),addr)
	local socket = context:socket(zmq.PAIR)
	socket:connect(addr)
	socket:send("go")
	socket:close()
--	context:term()
end
--chat
local function zmq_test2()
end

local function toint32( s )
	return string.byte(s,4)
end

local function int32tostr( v )
	local p0 = string.char(v%255)
	return '\0\0\0'..p0
end

local function send( socket,msg )
	local length = string.len(msg)
	print( length.."-"..msg )
	socket:send(int32tostr(length)..msg)
end

local function recv( socket )
	local msg,err = socket:receive(4)
	if msg and string.len(msg)==4 then
		local l = toint32(msg)
		print( "recv "..tostring(l))
		if l >= 0 then
			return socket:receive(l)
		end
	else
		print( "recv "..tostring(err) )
	end
	return nil,err
end
--[[
local socket = require "socket"
local http = require "socket.http"
local frame = require "websocket.frame"
local ws_client = require "websocket.client_sync"()
--]]
local socket = require "ansync_socket"

local function test_websocket()
	local count = 0
	local serial = 0
	local connects = {}

	for i=1,1 do
		table.insert(connects,socket.create("192.168.2.153",8888,function(event,msg)
			if event=="frame" and msg then
				for i,v in pairs(msg) do
					count = count - 1
					--print( tostring(event) .."=["..tostring(v).."] "..tostring(count) )
				end
			elseif event~="idle" then
				--print( tostring(event) .."=["..tostring(msg).."]" )
			end
		end))
	end
	
	if connects then
		for i,connect in pairs(connects) do
			count = count+1
			print("send enter")
			b,msg = connect:send(json.encode{m="enter"})--math.random(1,10000)
			count = count+1
			print("send say hello world")
			b,msg = connect:send(json.encode{m="say",c="hello world"})--math.random(1,10000)		
			count = count+1
			print("send say hi !")
			b,msg = connect:send(json.encode{m="say",c="hi !"})--math.random(1,10000)
			uikits.delay_call(nil,function(dt)
				serial = serial+1
				count = count+1
				b,msg = connect:send(json.encode{m="echo",c="hi "..serial})--math.random(1,10000)
				serial = serial+1
				count = count+1				
				b,msg = connect:send(json.encode{m="say",c="hi "..serial})--math.random(1,10000)
				return true
			end)
		end
	else
		print("connect failed")
	end
--[[
	local socket = require "socket"
	
	local ct = {}
	for i=1,1 do
		local ot = cc_clock()
		local connect = socket.connect("192.168.2.162",8009)
		table.insert(ct,{socket = connect,err = msg})
		if connect then
			print( "connect "..i..tostring(math.floor((cc_clock()-ot)*1000)).."ms" )
		else
			print( "failed "..tostring(msg) )
		end
	end
	local count = 0
	for i,v in pairs(ct) do
		if v.con then
			local ot = cc_clock()
			connect:send("hello world "..math.random(1,10000).."\n")
			print( "send delay "..tostring(math.floor((cc_clock()-ot)*1000)).."ms" )
		end
	end
	for i,v in pairs(ct) do
		if v.con then
			local msg = recv(v.con)
			if msg and type(msg)=="string" and string.find(msg,"hello world")==1 then
				count = count + 1
			end
			print( "send 'hello world' recv : "..tostring(msg) )
		end	
	end
	for i,v in pairs(ct) do
		if v.con then
			v.con:close()
			print( "close socket")
		end	
	end	
	print( "success "..tostring(count))
	--]]
--[[
	local ws = require "websock".create("ws://192.168.2.162:8009",
	function(event,msg)
		if event=="closed" then
			print("websocket closed")
		elseif event=="frame" then
			print("websocket receive : "..tostring(msg))
		elseif event=="error" then
			print("websocket error : "..tostring(msg))
		end
	end)
	--]]
	--ws:send("hello world")
	--ws:send("websocket")
	--ws:send("close")
	--uikits.delay_call(nil,function(dt)ws:close()end,1)
 --[[
	local thread = require "thread"
	local filo = {"hello","world"}
	
  local b,msg = ws_client:connect("ws://localhost/echo")
  if b then
		ws_client.sock:settimeout(0)
	  ws_client:send("hello")
	  ws_client:send("hello world")
	  ws_client:send("websocket")
	  uikits.delay_call(nil,function(dt)
		 local msg,status = ws_client:receive()
		 if msg then
			print('received :'..msg)
			return true
		elseif status == "closed" then
			print("close")
			ws_client:close()
		elseif status == "timeout" then
			return true
		end
	  end,0.1)
  end
  print( b,msg )
  --]]
  
	--[[
	local wsSendText = nil
	local sendTextStatus  = nil
	local receiveTextTimes = 0

	wsSendText = cc.WebSocket:create("ws://localhost/echo")
    local function wsSendTextClose(strData)
        print("_wsiSendText websocket instance closed.")
        sendTextStatus = nil
        wsSendText = nil
    end	
    local function wsSendTextOpen(strData)
		print("wsSendTextOpen")
    end

    local function wsSendTextMessage(strData)
      local strInfo= "response text msg: "..strData..", "..receiveTextTimes    
	  print(strInfo)
    end
    local function wsSendTextError(strData)
        print("sendText Error was fired")
    end	
    if nil ~= wsSendText then
        wsSendText:registerScriptHandler(wsSendTextOpen,cc.WEBSOCKET_OPEN)
        wsSendText:registerScriptHandler(wsSendTextMessage,cc.WEBSOCKET_MESSAGE)
        wsSendText:registerScriptHandler(wsSendTextClose,cc.WEBSOCKET_CLOSE)
        wsSendText:registerScriptHandler(wsSendTextError,cc.WEBSOCKET_ERROR)
    end	
	--]]
	
	
	--[[
	local function wait()
		return true,"hi","hello","world"
	end
	local function printd(...)
		print("1 "..select(1,...))
		print("2 "..select(2,...))
		print("3 "..select(3,...))
	end
	local b,p1,p2,p3,p4 = wait()
	printd(p1,p2,p3,p4)
	--]]
	
	--[[
	local words = {"hello","world","good","bye","end"}
	local thread = require "thread"
	local count = 1

	local t1 = thread.new("test2",function(i,w)
		print( "i="..tostring(i).."  w="..tostring(w))
		return i,w
	end,2,2)
	--]]
	
	--[[
	local thread = require "thread"
	local t1 = thread.new("httpthread",function(data,msg)
		if data then
			print( "===========================" )
			print( tostring(data) )
			print( "===========================" )
		else
			print( tostring(msg) )
		end
	end,"local.test.idiom.com","/Handler.ashx",80)
	--]]
	
	--http://local.test.idiom.com/Handler.ashx
 --[[
	local connect = socket.connect("local.test.idiom.com",80)
	local buf,err_msg
	if connect then
		print("connect :"..tostring(connect))
		local reqs = "GET /Handler.ashx HTTP/1.0\r\n"
		reqs = reqs.."Host:local.test.idiom.com\r\n"
		--reqs = reqs.."Connection:Keep-Alive\r\n"
		--reqs = reqs.."Content-length:0\r\n"
		reqs = reqs.."\r\n"
		local result = connect:send(reqs)
		print("send "..reqs)
		print("result "..tostring(result))
		repeat
			local t = cc_clock()
			local chunk,status,partial = connect:receive()
			print("receive :"..tostring(chunk).."  | status:"..tostring(status).."  | dt= "..(cc_clock()-t))
			if not buf then
				buf = chunk
			elseif buf and chunk then
				buf = buf..chunk
			else
				print("?")
			end
		until status == 'closed'
		connect:close()
	else
		print("can not connect")
	end
	--]]
	
	--[[
	login.set_selector(24)
	cache = require "cache"
	local url = "http://api.lejiaolexue.com/rest/asset/userasset.ashx?currecy=2"
	cache.request_json(url,function(data)
		print(tostring(data))
	end)
	--]]
	
	--[[
	local b,msg = pay.pay(1040,"201505061543478378",1,"乐信测试产品",1,"1","QW36GFDHGHDFSDFFSDFSREES0987",
		function(b,data)
			if b then
				print("pay success : "..tostring(data))
			else
				print("pay failed : "..tostring(data))
			end
		end)
	if b then
	else
		print(msg)
	end
	--]]
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
	debugip:setText("192.168.2.157")
	
	local amouse = uikits.button{caption='二打一',x=64*scale,y = 64*scale +5*item_h,
	width=128*scale,height=48*scale,
	eventClick=function(sender)
		update.create{name='v21',updates={'v21','luacore'},
			run=function()
			login.set_selector(5)
			uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
			local v21 = require "v21/main"
			uikits.pushScene(v21.create())
		end}		
	end}
		
	local tbutton = uikits.button{caption='学习乐园',x=64*scale,y = 64*scale +4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			--update.create{name='qwxt',updates={'qwxt','luacore','topics','wuliu'},
				--run=function()
				login.set_uid_type(login.STUDENT)
				login.set_selector(36)--学生
				--login.set_selector(29) 
				local qwxt = require "qwxt/main"
				--return qwxt.create()
				uikits.pushScene(qwxt.create())
			--end}			
		end}
	local sbutton = uikits.button{caption='速算',x=64*scale,y = 64*scale + 3*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='calc',updates={'luacore'},
				run=function()
				login.set_uid_type(login.TEACHER)
				--login.set_selector(15) --学生
				--login.set_selector(24) --田老师(校长）
				---login.set_selector(30) --张燕老师(校长）
				--login.set_selector(34) --张燕学生2
				--login.set_selector(33) --张燕老师八
				--login.set_selector(35) --胡老师
				--login.set_selector(36) --李杰
				--login.set_selector(42) --刘
				--login.set_selector(37) --刘
				--login.set_selector(38) --李杰老师
				--login.set_selector(39) --家长
				--login.set_selector(40)
				--login.set_selector(48) --省局长
				--login.set_selector(49) --李杰家长
				--login.set_selector(50) 
				login.set_selector(54) 
				--login.set_selector(53) 
				local ss = require "calc/loading"
				return ss.create()
				end}
		end}
	local ebutton = uikits.button{caption='新打地鼠2',x=64*scale,y = 64*scale + 2*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='hitmouse2',updates={'luacore'},
				run=function()
				--login.set_selector(25) --李杰
				--login.set_uid_type(login.TEACHER)
				--login.set_selector(11) --秦胜兵(教育局领导)
				--login.set_selector(12) --五五
				--login.set_selector(17) --五五的家长
				--login.set_selector(13) --李四 (领导但不能发比赛)
				--login.set_selector(14) --六六
				--login.set_selector(15) --六六的哥哥
				--login.set_selector(16) --六六母亲 (家长)
				--login.set_selector(18) --额额
				--login.set_selector(18) --杨艳波
				--login.set_selector(20) --张泳
				--login.set_selector(43)--李四
				login.set_selector(47)--
				--login.set_selector(22) --未来之星校长
				--login.set_selector(23) --大小校长
				--login.set_selector(24) --田老师
				--login.set_selector(26) 
				--login.set_selector(25) 
				local Loading = require "hitmouse2/loading"
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
	local epbutton = uikits.button{caption='TEST',x=64*scale,y = 64*scale + 6*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			--update.create{name='test',updates={'test','luacore'},
			--	run=function()
			--	login.set_selector(3) 
			--	local selstudent = require "test/test"
			--	uikits.pushScene(selstudent.create())
			--end}
			local cache = require "cache"
			cache.post("http://baidu.com/hello.a?hehe","from=a",function(b,data)
				
			end,"hello:0")
		end}
	local pbutton = uikits.button{caption='市场',x=64*scale,y = 64*scale + 7*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			update.create{name='test',updates={'lemall','luacore'},
				run=function()
				login.set_selector(9) 
				local selstudent = require "lemall/Loading"
				return selstudent.create()
			end}
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
	local han =  uikits.button{caption='汉字',x=264*scale,y = 64*scale + 3*item_h,
		width=128*scale,height=48*scale,
	}
	uikits.event( han,
		function(sender,eventType)
			update.create{name='han',updates={'luacore','han'},
				run=function()
				login.set_uid_type(login.TEACHER)
				--login.set_selector(15) --学生
				--login.set_selector(24) --田老师(校长）
				---login.set_selector(30) --张燕老师(校长）
				--login.set_selector(34) --张燕学生2
				--login.set_selector(33) --张燕老师八
				--login.set_selector(35) --胡老师
				--login.set_selector(36) --李杰
				login.set_selector(37) --刘
				--login.set_selector(38) --李杰老师
				--login.set_selector(39) --家长
				--login.set_selector(40)
				local ss = require "han/loading"
				return ss.create()
				end}			
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
	local resetwindow = uikits.button{caption='zmq test',x=264*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			zmq_test()
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
	debugip:setText("192.168.2.157")
	local isopen = false
	local debugbutton = uikits.button{caption='调试...',x=320*scale,y = 64*scale + item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			if not isopen then
				kits.log("debug "..tostring(debugip:getStringValue()))
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
	local ff = uikits.button{caption='KEEP-ALIVE',x=664*scale,y = 164*scale + 4*item_h,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			local mt = require "mt"
			local url = "http://app.lejiaolexue.com/poems_test/poems.ashx"
			local handle,msg
			local count = 0
			local isok
			handle,msg = keep_alive(url,function(b,data)
				if b then
					count = count + 1
					kits.log( tostring(count).."-[1]-"..tostring(data) )
					isok = true
				else
					kits.log( "keep_alive failed" )
				end
			end)
			uikits.delay_call(nil,function(dt)
				if isok then
					isok = false
					handle:reconnect('GET',url,login.cookie(),function(obj)
					if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
						if obj.state == 'OK'  and obj.data then
							count = count + 1
							kits.log( tostring(count).."-[1]-"..tostring(obj.data) )
							if count > 10 then
								obj:close()
								return false
							end
							isok = true
						else
							kits.log( "keep_alive reconnect failed" )
						end
						end						
					end)
				end
				return true
			end,1)
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
						--print( "progress "..math.floor(10000*as.current/as.length)/100)
						print( "progress "..as.current)
					else
						print( "CURRENT STATE : "..state )
					end
				end)
		end}
	local play = uikits.button{caption='play',x=464*scale+300,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			--as:seek(as.length*0)
			as:play()
		end}
	local pause = uikits.button{caption='pause',x=464*scale-300,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			as:pause()
		end}		
	local close = uikits.button{caption='HTTP Socket',x=464*scale-600,y = 164*scale + 4*item_h+100,
		width=128*scale,height=48*scale,
		eventClick=function(sender)
			test_websocket()
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
	local rect = uikits.rect{x2=200,y2=200,x1=100,y1=100,fillColor=cc.c4f(1,1,1,1)}
	bg:addChild(rect)
	local image = uikits.image{image="g:\\cache\\4f595dcf81bd1de16866de754a934533.gif",x=100,y=100}
	bg:addChild(image)
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
	bg:addChild(han)
	self:addChild(bg)
	resume.clearflag("update") --update isok
end

function AppEntry:release()
	
end

return AppEntry
