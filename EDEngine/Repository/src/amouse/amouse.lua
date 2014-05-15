lxp = require "lom"
require "AudioEngine"

local local_dir = cc.FileUtils:getInstance():getWritablePath()..'res/'
local SND_CLICK = 1
local SND_MISS = 2
local SND_HIT = 3
local SND_RIGHT = 4
local SND_FAIL = 5
local SND_NEXT_PROM = 6

local function play_sound( idx )
	local name

	if idx == SND_CLICK then
		name = 'amouse/snd/qiaoda.mp3'
	elseif idx == SND_MISS then
		name = 'amouse/snd/shibai.MP3'
	elseif idx == SND_HIT then
		name = 'amouse/snd/beida.MP3'
	elseif idx == SND_RIGHT then
		name = 'amouse/snd/zhengque.MP3'
	elseif idx == SND_FAIL then
		name = 'amouse/snd/shibai.mp3'
	elseif idx == SND_NEXT_PROM then
		return
	end
	AudioEngine.playEffect(name)
end

local function read_local_file( name )
  local file = local_dir..name
  local alls
  for line in io.lines(file) do
    if not alls then
      alls = line
    else
      alls = alls..line
    end
  end
  return alls
end

local function AMouseMainLayer()

    local function title()
      return "AccelerometerTest"
    end
    local layer = cc.Layer:create()
	local amouse = {}
	local choose_text = {}
	local ss = cc.Director:getInstance():getVisibleSize()
	local scheduler = cc.Director:getInstance():getScheduler()
	local words = {}
	local word_index = 1
	local rand_idx = {2,3,4,1}
	local yes_num = 0
	local ideal_pause = false
	local schedulerEntry
	local all_num = 0
	local error_num = 0
	local errors = {}
	
	local function delay_call( func,param,delay )
		local schedulerID
		if not schedulerID then
			local function delay_call_func()
				func(param)
				scheduler:unscheduleScriptEntry(schedulerID)
				schedulerID = nil
			end
			schedulerID = scheduler:scheduleScriptFunc(delay_call_func,delay,false)
		end
	end
	
	local function init_words()
		local promble_xml = read_local_file('amouse/data.xml')
		words = {}
		math.randomseed(os.time())
		if promble_xml then
			local items = lxp.parse(promble_xml)
			for i,v in ipairs(items) do
				if v.attr and v.attr.name and v.attr.answer then
					words[#words+1] = {name=v.attr.name,answer=v.attr.answer}
				end
			end
		end
	end
	
    local function onEnter()
		local next_prom
		local bg    = cc.Sprite:create("amouse/mainscene.png")
		bg:setPosition(VisibleRect:center())
		layer:addChild(bg)
		local time_bg = ccui.Button:create()
		time_bg:loadTextures("amouse/NewUI0.png","amouse/NewUI0.png","")
		time_bg:setPosition(cc.p(ss.width/2,ss.height*5.6/6))
		layer:addChild(time_bg)
		local sprite_bg = cc.Sprite:create("amouse/NewUI01.png")
		sprite_bg:setAnchorPoint(cc.p(0.5,0.5))
		sprite_bg:setPosition(cc.p(ss.width/2,ss.height*4.6/7))
		sprite_bg:setScaleY(0.8)
		sprite_bg:setScaleX(0.8)
		layer:addChild(sprite_bg)
		
		local time_label = ccui.Text:create()
		time_label:setPosition(cc.p(ss.width/2,ss.height*5.6/6+10))
		time_label:setFontSize(30)
		layer:addChild(time_label)	
		
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("amouse/NewAnimation.ExportJson")
-- for CCLuaEngine traceback
local function __G__TRACKBACK__(msg)
    cclog("----------------------------------------")
    cclog("LUA ERROR: " .. tostring(msg) .. "\n")
    cclog(debug.traceback())
    cclog("----------------------------------------")
  end  
  local function doad()
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("amouse/NewAnimation.ExportJson")
  end
		xpcall(doad,__G__TRACKBACK__)
		--load words xml file
		init_words()
		local hummer = ccs.Armature:create("NewAnimation")
		
		--local function onFrameEvent(bone,evt,originFrameIndex,currentFrameIndex)
		--	print("FrameEvent")
		--end
		for i=1,4 do
			amouse[i] = ccs.Armature:create("NewAnimation")
			choose_text[i] = ccui.Text:create()
			local box = amouse[i]:getBoundingBox()
			amouse[i]:getAnimation():playWithIndex(0)
			--amouse[i]:getAnimation():setFrameEventCallFunc(onFrameEvent)
			--VisibleRect:center()
			local b = (ss.width-4*box.width)/5
			amouse[i]:setAnchorPoint(cc.p(0,0))
			amouse[i]:setPosition(cc.p(b+(i-1)*(box.width+b),box.height/2))
			choose_text[i]:setAnchorPoint(cc.p(0.5,0.5))
			--choose_text[i]:setPosition(cc.p(b+(i-1)*(box.width+b)+box.width*3/5,box.height/2+box.height*5/4))
			local bone = amouse[i]:getBone("Layer12")
			if bone then
				bone:addDisplay(choose_text[i],0)
				bone:changeDisplayWithIndex(0,true)
			end
			layer:addChild(amouse[i])
			choose_text[i]:setFontSize(50)
			choose_text[i]:setColor(cc.c3b(0,0,0))
			--layer:addChild(choose_text[i])
			--amouse[i]:getAnimation():playWithIndex(2)
		end
		local answer_num = 1
		local function reload_scene(b)
			for i=1,4 do
				amouse[i]:getAnimation():playWithIndex(0)
			end		
			next_prom()
		end
		local function show_right(i)
			error_num = error_num + 1
			errors[#errors+1] = word_index
			for i,v in ipairs(rand_idx) do
				if v == 1 then
					amouse[i]:getAnimation():playWithIndex(6)
					delay_call(reload_scene,true,3)
				elseif v == 2 and yes_num==2 then
					amouse[i]:getAnimation():playWithIndex(6)
				end
			end
		end
		
		local function judge(i)
			if yes_num == 1 then
				if ideal_pause then
					return
				end
				if rand_idx[i] <= yes_num then
					ideal_pause = true
					amouse[i]:getAnimation():playWithIndex(3)
					delay_call(reload_scene,true,1.5)
					play_sound(SND_RIGHT)
				else
					ideal_pause = true
					amouse[i]:getAnimation():playWithIndex(2)
					delay_call(show_right,i,1.5)
					play_sound(SND_FAIL)
				end
			elseif yes_num == 2 then
				if answer_num == 1 and rand_idx[i] == 1 then
					ideal_pause = true
					amouse[i]:getAnimation():playWithIndex(3)
					play_sound(SND_RIGHT)
					answer_num = answer_num + 1
				elseif answer_num == 2 and rand_idx[i] == 2 then
					amouse[i]:getAnimation():playWithIndex(3)
					delay_call(reload_scene,true,1.5)
					play_sound(SND_RIGHT)
				else
					ideal_pause = true
					amouse[i]:getAnimation():playWithIndex(2)
					delay_call(show_right,i,1.5)
					play_sound(SND_FAIL)
				end
			end
		end
		local function touchEvent(sender,eventType)
			if eventType == ccui.TouchEventType.began then
				hummer:getAnimation():playWithIndex(1)
			elseif eventType == ccui.TouchEventType.moved then
				--hummer:setPosition()
			elseif eventType == ccui.TouchEventType.ended then
			elseif eventType == ccui.TouchEventType.canceled then
			end
		end
		local function onTouchBegan(touches, event)
			local p = touches[1]:getLocation()
			hummer:getAnimation():playWithIndex(1)
			hummer:setPosition(p)
			
			play_sound(SND_CLICK)
			for i=1,4 do
				local box = amouse[i]:getBoundingBox()
				if p.x > box.x and p.x < box.x+box.width and
					p.y > box.y and p.y < box.y+box.height then
					judge(i)
					return
				end
			end
			
		end
		local function onMouseMoved(event)
			hummer:setPosition(cc.p(event:getCursorX(),event:getCursorY()))
		end
		
		local function onTouchMoved(touches, event)
			local p = touches[1]:getLocation()
			hummer:setPosition(p)
		end
		
		hummer:setPosition(VisibleRect:center())
		hummer:getAnimation():playWithIndex(1)
		
		--local font = cc.LabelTTF:create()
		--font:setFontName("Marker Felt")
		
		local cn_label = cc.LabelTTF:create("", "Marker Felt", 60)
		if cn_label then
			cn_label:setColor(cc.c3b(255,0,0))
			cn_label:setPosition(cc.p(ss.width/2,ss.height*2/3))
			layer:addChild(cn_label)
		end
		local nn_label = cc.LabelTTF:create("", "Marker Felt", 30)
		if nn_label then
			nn_label:setColor(cc.c3b(255,0,0))
			nn_label:setPosition(cc.p(ss.width/10,ss.height*18/20))
			layer:addChild(nn_label)
		end
		
		local function merge_word(yp,np)
			local p = {}
			for i,v in ipairs(yp) do
				p[#p+1] = v
			end
			for i,v in ipairs(np) do
				p[#p+1] = v
			end
			return p			
		end
		
		local function random_idx()
			local n1 = math.random(1,4)
			local n2
			repeat
				n2 = math.random(1,4)
			until n1 ~= n2
			--xchang
			local temp = rand_idx[n1]
			rand_idx[n1] = rand_idx[n2]
			rand_idx[n2] = temp
		end
		local function rand_idx_loop(n)
			for i=1,n do
				random_idx()
			end
		end
		local function set_word( yp,np )
			local p = merge_word(yp,np)
			rand_idx_loop(5)
			yes_num = #yp
			if yes_num > 0 and #p == 4 then
				for i,v in ipairs(rand_idx) do
					choose_text[i]:setText(p[v])
				end
			else
				--error?
			end
		end
		
		local function select_word(index)
			cn_label:setString(words[index].name)
			local prob = words[index].answer
			local length = cc.utf8.length(prob)
			local text_idx = 1
			local yp = {}
			local np = {}
			local flag = false
			if length and length > 1 then
				local idx = 0
				repeat
					local idx2 = cc.utf8.next(prob,idx)
					if idx2 and idx2 < length then
						if text_idx <= 6 then
							local c = string.sub(prob,idx+1,idx+idx2)
							if c == ',' then
								flag = true
							elseif flag then
								np[#np+1] = c
							else
								yp[#yp+1] = c
							end
							--choose_text[text_idx]:setText( string.sub(prob,idx+1,idx+idx2) )
						else
							break
						end
						text_idx = text_idx + 1
						idx = idx2 + idx
					end
				until idx2 == nil or idx2 >= length
				if flag and #yp>0 and #np >0 then
					set_word(yp,np)
				else
					--error?
					word_index = word_index + 1
					next_prom()
				end
			end
		end
		
		local function next_select()
			answer_num = 1
			select_word(word_index)
			word_index = word_index + 1
			ideal_pause = false
			all_num = all_num + 1
			play_sound(SND_NEXT_PROM)
		--	if nn_label then
		--		nn_label:setString("错误:"..error_num)
		--	end
		end
		
		--precall
		next_prom = next_select
		local listener = cc.EventListenerTouchAllAtOnce:create()
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )
		local listener_mouse = cc.EventListenerMouse:create()
		listener_mouse:registerScriptHandler(onMouseMoved,cc.Handler.EVENT_MOUSE_MOVE )
		
		---layer:setTouchEnabled(true)
		local eventDispatcher = layer:getEventDispatcher()
		
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener_mouse, layer)
		local count_time = 1

		local function timer_update(time)
			if time_label and count_time then
				time_label:setText(count_time)
				count_time = count_time + 1
				if not ideal_pause then
					if count_time % 3 == 0 then
						amouse[math.random(1,2)]:getAnimation():playWithIndex(math.random(4,5))
						amouse[math.random(3,4)]:getAnimation():playWithIndex(math.random(4,5))
					elseif count_time % 3 == 1 then
						amouse[math.random(1,2)]:getAnimation():playWithIndex(math.random(4,5))
						amouse[math.random(3,4)]:getAnimation():playWithIndex(math.random(4,5))
					end
				end
				if count_time > 60 then
					scheduler:unscheduleScriptEntry(schedulerEntry)
				end
			elseif schedulerEntry then
				scheduler:unscheduleScriptEntry(schedulerEntry)
			end
		end
		--layer:scheduleUpdateWithPriorityLua(timer_update,0)
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1.0,false)
		
		layer:addChild(hummer)

		next_select(0)
    end

    local function onExit()
		if schedulerEntry then
			scheduler:unscheduleScriptEntry(schedulerEntry)
		end
        layer:setAccelerometerEnabled(false)
    end

    local function onNodeEvent(event)
        if "enter" == event then
            onEnter()
        elseif "exit" == event then
            onExit()
        end
    end

    layer:registerScriptHandler(onNodeEvent)
    
    return layer
end

function AMouseMain()
	cclog("A mouse hello!")
--	require("mobdebug").start("192.168.2.182")
	local scene = cc.Scene:create()
	scene:addChild(AMouseMainLayer())
	scene:addChild(CreateBackMenuItem())
	return scene
end
