lxp = require "lom"
kits = require "kits"

local AMouseScene = class("AMouseScene")
AMouseScene.__index = AMouseScene
AMouseScene._uiLayer= nil
AMouseScene._widget = nil
AMouseScene._sceneTitle = nil

--本地支援缓冲区
local local_dir = cc.FileUtils:getInstance():getWritablePath()..'res/'
local SND_CLICK = 1
local SND_MISS = 2
local SND_HIT = 3
local SND_RIGHT = 4
local SND_FAIL = 5
local SND_NEXT_PROM = 6

--产生一个xml文档报告游戏体验结果
local function get_errors_xml(do_num,err_num,err_table)
	local xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	xml = xml.."<errors do_num=\""..do_num.."\" err_num=\""..err_num.."\" >\n"
	for i,v in ipairs(err_table) do
		xml = xml.."	<item idx="..v.." />\n"
	end
	xml = xml.."</errors>\n"
	return xml
end

--修改游戏声效
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

--返回主菜单					
local function backMain()
	local scene = cc.Scene:create()
    scene:addChild(CreateTestMenu())

    cc.Director:getInstance():replaceScene(scene)
end

function AMouseScene.extend(target)
    local t = tolua.getpeer(target)
    if not t then
        t = {}
        tolua.setpeer(target, t)
    end
    setmetatable(t, AMouseScene)
    return target
end

--初始化背景与基本界面
function AMouseScene:init_bg_and_ui()
	--背景
	self._bg = cc.Sprite:create("amouse/mainscene.png")
	self._bg:setPosition(VisibleRect:center())
	self:addChild(self._bg)
	--时间背景
	self._time_bg = ccui.Button:create()
	self._time_bg:loadTextures("amouse/NewUI0.png","amouse/NewUI0.png","")
	self._time_bg:setPosition(cc.p(self._ss.width/2,self._ss.height*5.6/6))
	self:addChild(self._time_bg)
	--题目背景
	self._sprite_bg = cc.Sprite:create("amouse/NewUI01.png")
	self._sprite_bg:setAnchorPoint(cc.p(0.5,0.5))
	self._sprite_bg:setPosition(cc.p(self._ss.width/2,self._ss.height*4.6/7))
	self._sprite_bg:setScaleY(0.8)
	self._sprite_bg:setScaleX(0.8)
	self:addChild(self._sprite_bg)
	--时间文字
	self._time_label = ccui.Text:create()
	self._time_label:setPosition(cc.p(self._ss.width/2,self._ss.height*5.6/6+10))
	self._time_label:setFontSize(30)
	self:addChild(self._time_label)
	--题目文字
	self._cn_label = cc.LabelTTF:create("", "Marker Felt", 60)
	self._cn_label:setColor(cc.c3b(255,0,0))
	self._cn_label:setPosition(cc.p(self._ss.width/2,self._ss.height*2/3))
	self:addChild(self._cn_label)
	self._nn_label = cc.LabelTTF:create("", "Marker Felt", 30)
	self._nn_label:setColor(cc.c3b(255,0,0))
	self._nn_label:setPosition(cc.p(self._ss.width/10,self._ss.height*18/20))
	self:addChild(self._nn_label)
end

function AMouseScene:hummer_home()
	self._hummer:setPosition( cc.p(self._ss.width/5,self._ss.height*4.6/7) )
end

--初始化角色
function AMouseScene:init_role()
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("amouse/NewAnimation.ExportJson")
	ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("amouse/NewAnimation.ExportJson")
	--4个地鼠
	self._amouse = {}
	self._choose_text = {}
	for i=1,4 do
		self._amouse[i] = ccs.Armature:create("NewAnimation")
		self._choose_text[i] = ccui.Text:create()
		local box = self._amouse[i]:getBoundingBox()
		self._amouse[i]:getAnimation():playWithIndex(0)
		
		local b = (self._ss.width-4*box.width)/5
		self._amouse[i]:setAnchorPoint(cc.p(0,0))
		self._amouse[i]:setPosition(cc.p(b+(i-1)*(box.width+b),box.height/2))
		self._choose_text[i]:setAnchorPoint(cc.p(0.5,0.5))
		local bone = self._amouse[i]:getBone("Layer12")
		if bone then
			bone:addDisplay(self._choose_text[i],0)
			bone:changeDisplayWithIndex(0,true)
		end
		self:addChild(self._amouse[i])
		self._choose_text[i]:setFontSize(50)
		self._choose_text[i]:setColor(cc.c3b(0,0,0))
	end
	--锤子
	self._hummer = ccs.Armature:create("NewAnimation")
	self:hummer_home()
	self._hummer:getAnimation():playWithIndex(1)
	self:addChild(self._hummer)	
end

--延迟调用
function AMouseScene:delay_call(func,param,delay)
	local schedulerID
	if not schedulerID then
		local function delay_call_func()
			func(self,param)
			scheduler:unscheduleScriptEntry(schedulerID)
			schedulerID = nil
			func = nil
		end
		schedulerID = scheduler:scheduleScriptFunc(delay_call_func,delay,false)
	end	
end

--正确
function AMouseScene:show_right(i)
	self._error_num = self._error_num + 1
	if self._errors[#self._errors] ~= self._word_index-1 then
		self._errors[#self._errors+1] = self._word_index-1
	end
	self:hummer_home()
	for i,v in ipairs(self._rand_idx) do
		if v == 1 then
			self._amouse[i]:getAnimation():playWithIndex(6)
			self:delay_call(self.reload_scene,true,3)
		elseif v == 2 and self._yes_num==2 then
			self._amouse[i]:getAnimation():playWithIndex(6)
		end
	end
end
		
--敲击判断，i敲击了第几个地鼠
function AMouseScene:judge(i)
	--取前两次打击
	if not self._judge_index then
		self._judge_index = self._word_index
		self._judge_num = self._yes_num
	else
		if self._judge_index == self._word_index then
			if self._judge_num == 2 then
				--第二次打击	
				self._judge_num =self._judge_num-1
			else
				--丢弃多余的打击
				return
			end
		else
			--第一次打击
			self._judge_index = self._word_index
			self._judge_num = self._yes_num
		end
	end
	if self._yes_num == 1 then
		--单答案
		if self._ideal_pause then
			return
		end
		if self._rand_idx[i] <= self._yes_num then
			self._ideal_pause = true
			self._amouse[i]:getAnimation():playWithIndex(3)
			self:delay_call(self.reload_scene,true,1.5) --延迟调用
			play_sound(SND_RIGHT)
		else
			self._ideal_pause = true
			self._amouse[i]:getAnimation():playWithIndex(2)
			self:delay_call(self.show_right,i,1.5)
			play_sound(SND_FAIL)
		end
	elseif self._yes_num == 2 then
		--双答案
		if self._answer_num == 1 and self._rand_idx[i] == 1 then
			--第一个打对
			self._ideal_pause = true
			self._amouse[i]:getAnimation():playWithIndex(3)
			play_sound(SND_RIGHT)
			self._answer_num = self._answer_num + 1
		elseif self._answer_num == 2 and self._rand_idx[i] == 2 then
			--第二个打对
			self._amouse[i]:getAnimation():playWithIndex(3)
			self:delay_call(self.reload_scene,true,1.5)
			play_sound(SND_RIGHT)
		else
			--打错
			self._ideal_pause = true
			self._judge_num = 1 --丢弃后续打击
			self._amouse[i]:getAnimation():playWithIndex(2)
			self:delay_call(self.show_right,i,1.5)
			play_sound(SND_FAIL)
		end
	end
end

--初始化事件
function AMouseScene:init_event()
	--多点触摸
	local function onTouchBegan(touches,event)
		local p = touches[1]:getLocation()
		self._hummer:getAnimation():playWithIndex(1)
		self._hummer:setPosition(p)
		
		play_sound(SND_CLICK)
		for i=1,4 do
			local box = self._amouse[i]:getBoundingBox()
			if p.x > box.x and p.x < box.x+box.width and
				p.y > box.y and p.y < box.y+box.height then
				self:judge(i)
				return
			end
		end
	end

	local function onTouchMoved(touches, event)
		local p = touches[1]:getLocation()
		self._hummer:setPosition(p)
	end

	--鼠标移动
	local function onMouseMoved(event)
		self._hummer:setPosition(cc.p(event:getCursorX(),event:getCursorY()))
	end

	--按键释放
	local function onKeyRelease(key,event)
		if key == cc.KeyCode.KEY_BACKSPACE then
			--Android return key
			backMain()
		end
	end
	--触摸
	self._listener = cc.EventListenerTouchAllAtOnce:create()
	self._listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	self._listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )
	--鼠标
--	self._listener_mouse = cc.EventListenerMouse:create()
--	self._listener_mouse:registerScriptHandler(onMouseMoved,cc.Handler.EVENT_MOUSE_MOVE )
	--键盘,Android返回
--	local listener_keyboard = cc.EventListenerKeyboard:create()
--	listener_keyboard:registerScriptHandler(self.onKeyRelease,cc.Handler.EVENT_KEYBOARD_RELEASED )
	--Android返回键由CreateBackMenuItem完成了
	local eventDispatcher = self:getEventDispatcher()
	
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener, self)
--	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener_mouse, self)
--	eventDispatcher:addEventListenerWithSceneGraphPriority(listener_keyboard, self)	
end

function AMouseScene:random_idx()
	local n1 = math.random(1,4)
	local n2
	repeat
		n2 = math.random(1,4)
	until n1 ~= n2
	--xchang
	local temp = self._rand_idx[n1]
	self._rand_idx[n1] = self._rand_idx[n2]
	self._rand_idx[n2] = temp
end
		
function AMouseScene:merge_word(yp,np)
	local p = {}
	for i,v in ipairs(yp) do
		p[#p+1] = v
	end
	for i,v in ipairs(np) do
		p[#p+1] = v
	end
	return p			
end

--多次偏移
function AMouseScene:rand_idx_loop(n)
	for i=1,n do
		self:random_idx()
	end
end
		
--设置词语yp,np.正确答案，错误答案
function AMouseScene:set_word( yp,np )
	--合并到一个4个表中
	local p = self:merge_word(yp,np)
	--随机移动
	self:rand_idx_loop(5)
	self._yes_num = #yp
	if self._yes_num > 0 and #p == 4 then
		for i,v in ipairs(self._rand_idx) do
			self._choose_text[i]:setText(p[v])
		end
	else
		print("Error word")
	end
end
		
--选择第index个词语
function AMouseScene:select_word(index)
	self._cn_label:setString(self._words[index].name)
	local prob = self._words[index].answer
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
				else
					break
				end
				text_idx = text_idx + 1
				idx = idx2 + idx
			end
		until idx2 == nil or idx2 >= length
		if flag and #yp>0 and #np >0 then
			self:set_word(yp,np)
		else
			--error?
			print("error?")
			print("flag="..flag)
			print("yp="..#yp)
			print("np="..#np)
			self._word_index = self._word_index + 1
			self:next_select()
		end
	end
end

--装填下一个词语
function AMouseScene:next_select()
	self._answer_num = 1
	self:hummer_home()
	self:select_word(self._word_index)
	self._word_index = self._word_index + 1
	self._ideal_pause = false
	self._all_num = self._all_num + 1
	play_sound(SND_NEXT_PROM)
end
		
--初始化游戏数据
function AMouseScene:init_data()
	local promble_xml = kits.read_local_file('res/amouse/data.xml')
	self._words = {} --全部词语
	self._time_limit = 60 --时限
	math.randomseed(os.time())
	if promble_xml then
		local items = lxp.parse(promble_xml)
	  if items then
			if items.attr and items.attr.time_limit then
				self._time_limit = tonumber(items.attr.time_limit)
			end
			for i,v in ipairs(items) do
				if v.attr and v.attr.name and v.attr.answer then
					self._words[#self._words+1] = {name=v.attr.name,answer=v.attr.answer}
				end
			end
	  end
	else
		print("Can\'t open resource file : res/amouse/data.xml")
	end
	--初始化随机表
	self._rand_idx = {2,3,4,1}
	self._yes_num = 0
	self._all_num = 0
	self._error_num = 0 --错误数
	self._errors = {} --错误的词表
	self._ideal_pause = false --空闲模式暂停
	self._word_index = 1 --开始第一个词语
end

function AMouseScene:init()
	--游戏基本变量初始化
	self._ss = cc.Director:getInstance():getVisibleSize()
	self._scheduler = cc.Director:getInstance():getScheduler()
	
	self:init_bg_and_ui()
	self:init_role()
	
	self:init_event()
	--初始化游戏数据
	self:init_data()
	
	--载入第一词
	self:next_select()
end

function AMouseScene.create()
    local scene = cc.Scene:create()
    local layer = AMouseScene.extend(cc.Layer:create())
    layer:init()
    scene:addChild(layer)
    return scene 
end

function AMouseMain()
	cclog("A mouse hello!")
	require("mobdebug").start("192.168.2.182")
	local scene = AMouseScene.create()
	scene:addChild(CreateBackMenuItem())
	return scene
end
