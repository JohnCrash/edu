lxp = require "lom"

local function AMouseMainLayer()

    local function title()
      return "AccelerometerTest"
    end
    local layer = cc.Layer:create()
	local amouse = {}
	local choose_text = {}
	local ss = cc.Director:getInstance():getVisibleSize()
	local words = {}
	
	local function init_words()
	end
	
    local function onEnter()
		local scheduler = cc.Director:getInstance():getScheduler()
		local bg    = cc.Sprite:create("amouse/mainscene.png")
		bg:setPosition(VisibleRect:center())
		layer:addChild(bg)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("amouse/NewAnimation.ExportJson")
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("amouse/NewAnimation.ExportJson")
		--load words xml file
		init_words()
		local hummer = ccs.Armature:create("NewAnimation")
		for i=1,4 do
			amouse[i] = ccs.Armature:create("NewAnimation")
			choose_text[i] = ccui.Text:create()
			local box = amouse[i]:boundingBox()
			amouse[i]:getAnimation():playWithIndex(0)
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
			for i=1,4 do
				local box = amouse[i]:boundingBox()
				if p.x > box.x and p.x < box.x+box.width and
					p.y > box.y and p.y < box.y+box.height then
					amouse[i]:getAnimation():playWithIndex(3)
				end
			end
		end
		local function onTouchMoved(touches, event)
			local p = touches[1]:getLocation()
			hummer:setPosition(p)
		end
		
		hummer:setPosition(VisibleRect:center())
		hummer:getAnimation():playWithIndex(1)
		
		local time_bg = ccui.Button:create()
		time_bg:loadTextures("amouse/NewUI0.png","amouse/NewUI0.png","")
		time_bg:setPosition(cc.p(ss.width/2,ss.height*5.6/6))
		layer:addChild(time_bg)
		local sprite_bg = cc.Sprite:create("amouse/NewUI01.png")
		sprite_bg:setPosition(cc.p(ss.width/2,ss.height*4/6))
		sprite_bg:setScaleX(4)
		layer:addChild(sprite_bg)
		
		local time_label = ccui.Text:create()
		time_label:setPosition(cc.p(ss.width/2,ss.height*5.6/6+10))
		time_label:setFontSize(30)
		layer:addChild(time_label)		
		--local font = cc.LabelTTF:create()
		--font:setFontName("Marker Felt")
		
		local cn_label = cc.LabelTTF:create("", "Marker Felt", 60)
		if cn_label then
			cn_label:setColor(cc.c3b(255,0,0))
			cn_label:setPosition(cc.p(ss.width/2,ss.height*2/3))
			layer:addChild(cn_label)
		end
		
		local listener = cc.EventListenerTouchAllAtOnce:create()
		listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
		listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )
		
		---layer:setTouchEnabled(true)
		local eventDispatcher = layer:getEventDispatcher()
		
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
		local count_time = 1
		local schedulerEntry
		local function timer_update(time)
			time_label:setText(count_time)
			count_time = count_time + 1
			if count_time > 60 then
				scheduler:unscheduleScriptEntry(schedulerEntry)
			end
		end
		--layer:scheduleUpdateWithPriorityLua(timer_update,0)
		schedulerEntry = scheduler:scheduleScriptFunc(timer_update,1.0,false)
		
		layer:addChild(hummer)

		local function next_select()
			cn_label:setString("人山人海")
			choose_text[1]:setText("扇")
			choose_text[2]:setText("山")
			choose_text[3]:setText("三")
			choose_text[4]:setText("衫")
		end

		next_select()
    end

    local function onExit()
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
	local scene = cc.Scene:create()
	scene:addChild(AMouseMainLayer())
	scene:addChild(CreateBackMenuItem())
	return scene
end
