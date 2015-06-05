local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local lxp = require "lom"

local ui = {
	FILE = 'hitmouse/zuoti.json',
	FILE_3_4 = 'hitmouse/zuoti.json',
	TOPBAR = 'ding',
	BACK = 'ding/hui',
	NUMBER = 'ding/tu/tishu',
	PROGRESS = 'ding/jindu',
	SCORE = 'ding/defen',
	ANIMATION_RGN = "ding/donghua",
	
	TIMEOVER_WINDOW = 'js1',
	SUCCESS_WINDOW = 'js2',
	FAILED_WINDOW = 'js3',
	
	ANIMATION_1 = "hitmouse/NewAnimation/NewAnimation.ExportJson",
	ANIMATION_2 = "hitmouse/chong_zi/chong_zi.ExportJson",
	ANIMATION_3 = "hitmouse/defen/defen.ExportJson",
}

local battle = class("battle")
battle.__index = battle

function battle.create(arg)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),battle)
	
	scene:addChild(layer)
	layer:initGame( arg )
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

function battle:initGame( arg )
	self._game_time = 0
	if arg and type(arg)=='table' then
		self._time_limit = arg.time_limit
	else
		self._time_limit = 30
	end
end

function battle:update_time_bar()
	if self._time_bar and self._time_limit and self._game_time 
		and self._time_limit >= 1 and  self._game_time<=self._time_limit then
		--设置进度条
		self._time_bar:setPercent( 100*self._game_time/self._time_limit)
		--设置小虫
		local x,y = self._time_bar:getPosition()
		local box = self._time_bar:getBoundingBox()
		x = box.x + box.width*self._game_time/self._time_limit
		self._worm:setPosition(cc.p(x,y))
	end
end

function battle:init_role()
	local arm = ccs.ArmatureDataManager:getInstance()
	if arm then
		arm:removeArmatureFileInfo(ui.ANIMATION_1)
		arm:addArmatureFileInfo(ui.ANIMATION_1)
		arm:removeArmatureFileInfo(ui.ANIMATION_2)
		arm:addArmatureFileInfo(ui.ANIMATION_2)
		arm:removeArmatureFileInfo(ui.ANIMATION_3)
		arm:addArmatureFileInfo(ui.ANIMATION_3)
	else
		kits.log("ERROR init_role ccs.ArmatureDataManager:getInstance() return nil")
	end
	self._worm = ccs.Armature:create("chong_zi")
	self._worm:getAnimation():playWithIndex(0)
	self._topbar:addChild(self._worm)
	self:update_time_bar()
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
		if self._screen == 1 then
			self._amouse[i]:setPosition(cc.p(b+(i-1)*(box.width+b),box.height/2))
		else
			self._amouse[i]:setPosition(cc.p(b+(i-1)*(box.width+b),1.0*box.height))
		end
		self._choose_text[i]:setAnchorPoint(cc.p(0.5,0.5))
		local bone = self._amouse[i]:getBone("Layer12")
		if bone then
			bone:addDisplay(self._choose_text[i],0)
			bone:changeDisplayWithIndex(0,true)
		end
		self:addChild(self._amouse[i],111)
		self._choose_text[i]:setFontSize(50)
		self._choose_text[i]:setColor(cc.c3b(0,0,0))
	end	
	--锤子
	self._hummer = ccs.Armature:create("NewAnimation")
	self:hummer_home()
	self._hummer:getAnimation():playWithIndex(1)
	self:addChild(self._hummer,2000)	
end

function battle:hummer_home()
	self._hummer:setPosition( cc.p(self._ss.width/5,self._ss.height*4.6/7) )
end

--敲击判断，i敲击了第几个地鼠
function battle:judge(i)
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
			self:play_sound(SND_RIGHT)
			self._right_num = self._right_num + 1
			self:show_right_word(1,true)
		else
			self._ideal_pause = true
			self._amouse[i]:getAnimation():playWithIndex(2)
			self:delay_call(self.show_right,i,1.5)
			self:play_sound(SND_FAIL)
		end
	elseif self._yes_num == 2 then
		--双答案
		if self._answer_num == 1 and self._rand_idx[i] == 1 then
			--第一个打对
			self._ideal_pause = true
			self._amouse[i]:getAnimation():playWithIndex(3)
			self:play_sound(SND_RIGHT)
			self._answer_num = self._answer_num + 1
			--答对,一题的前一个字答对
			--self._right_num = self._right_num + 1
			self:show_right_word(1,true)
		elseif self._answer_num == 2 and self._rand_idx[i] == 2 then
			--第二个打对
			self._ideal_pause = true
			self._amouse[i]:getAnimation():playWithIndex(3)
			self:delay_call(self.reload_scene,true,1.5)
			self:play_sound(SND_RIGHT)
			--答对
			self._right_num = self._right_num + 1
			self:show_right_word(2,true)
		else
			--打错
			self._ideal_pause = true
			self._judge_num = 1 --丢弃后续打击
			self._amouse[i]:getAnimation():playWithIndex(2)
			self:delay_call(self.show_right,i,1.5)
			self:play_sound(SND_FAIL)
		end
	end
end

function battle:init_event()
	local function onTouchBegan(touches,event)
		local p = touches[1]:getLocation()
		self._hummer:getAnimation():playWithIndex(1)
		self._hummer:setPosition(p)
		if self._pause then return end
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
		if self._mouse_emitter then
			self._mouse_emitter:setPosition(event:getCursorX(),event:getCursorY())
		end
	end

	--按键释放
	local function onKeyRelease(key,event)
		if key == cc.KeyCode.KEY_BACKSPACE then
			--返回上一层对话栏
			--if event == ccui.TouchEventType.ended then
				if self._where then
					kits.log( 'self._where:')
					self._where( self )
				else
					--Android return key
					kits.log( 'self._where: nil')
					self:stop_music()
					backMain()
				end
			--end
		end
	end

	self._listener = cc.EventListenerTouchAllAtOnce:create()
	self._listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	self._listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )

	self._listener_mouse = cc.EventListenerMouse:create(1)
	if not self._listener_mouse then
		self._listener_mouse = cc.EventListenerMouse:create()
	end
	self._listener_mouse:registerScriptHandler(onMouseMoved,cc.Handler.EVENT_MOUSE_MOVE )

	self._listener_keyboard = cc.EventListenerKeyboard:create()
	self._listener_keyboard:registerScriptHandler(onKeyRelease,cc.Handler.EVENT_KEYBOARD_RELEASED )

	local eventDispatcher = self:getEventDispatcher()
	
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener, self)
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener_mouse, self)
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener_keyboard, self)	
end

--初始化游戏数据,i代表关卡,1-10
function battle:init_data( i )
	i = i or 1
	local filename = 'res/amouse/data/'..tostring(i)..'.xml'
	--filename = cc.FileUtils:getInstance():fullPathForFilename(filename)
	local promble_xml = kits.read_local_file(filename)
	self._words = {} --全部词语
	self._time_limit = 60 --时限
	self._word_num = 40 --词数
	math.randomseed(os.time())
	if promble_xml then
		local items = lxp.parse(promble_xml)
	  if items then
			if items.attr then
				if items.attr.time_limit then
					self._time_limit = tonumber(items.attr.time_limit)
				end
				if  items.attr.word_num then
					self._word_num = tonumber(items.attr.word_num)
				end
			end
			for i,v in ipairs(items) do
				if v.attr and v.attr.name and v.attr.answer then
					self._words[#self._words+1] = {name=v.attr.name,answer=v.attr.answer}
				end
			end
	  end
	else
		kits.log("Can\'t open resource file : "..tostring(filename))
	end
	--一次加载全部的词，然后随机挑出_word_num个词
	if self._word_num <= #self._words then
		local ws = {}
		local k
		for i=1,self._word_num do
			k = math.random(1,#self._words)
			ws[i] = self._words[k]
			table.remove(self._words,k)
		end
		self._words = ws
	end
	--初始化随机表
	self._rand_idx = {2,3,4,1}
	self._yes_num = 0
	self._all_num = 0
	self._error_num = 0 --错误数
	self._errors = {} --错误的词表
	self._ideal_pause = false --空闲模式暂停
	self._word_index = 1 --开始第一个词语
	self._right_num = 0 --答对的数
	self._fen = 0 --积分
	self._fen_adding = 0 --真正增加的积分
	self._fen_mul = 1 --连续答对多少次
	self._pass = false --游戏已经通关
	self._xing_time = 1000 --通关时间
end

function battle:init_timer()
	self._game_time = 0
	self:update_time_bar()
	local function timer_update(time)
		if self._time_bar and cc_isobj(self._time_bar) then
			--不要显示大于时限的
			if self._game_time <= self._time_limit then
				--self._time_label:setText(self._game_time.."/"..self._time_limit)
				self._game_time = self._game_time + 1
				self:update_time_bar()
			end
			if not self._ideal_pause then
				if self._game_time % 3 == 0 then
					self._amouse[math.random(1,2)]:getAnimation():playWithIndex(math.random(4,5))
					self._amouse[math.random(3,4)]:getAnimation():playWithIndex(math.random(4,5))
				elseif self._game_time % 3 == 1 then
					self._amouse[math.random(1,2)]:getAnimation():playWithIndex(math.random(4,5))
					self._amouse[math.random(3,4)]:getAnimation():playWithIndex(math.random(4,5))
				end

				if self._game_time > self._time_limit then
					--time over
					self._scheduler:unscheduleScriptEntry(self._schedulerEntry)
					self._schedulerEntry = nil
					self._pause = true -- 暂停游戏
					self:game_over()
				end
			end
			return true
		end
	end
	uikits.delay_call(self,timer_update,1.0)
end

--设置剩余的题数
function battle:set_last_proms( N )
	if self._pnum_label then
		self._pnum_label:setString( tostring(N) )
	end
end

--选择第index个词语
function battle:select_word(index)
	if not self._cn_label then
		kits.log("ERROR battle:select_word self._cn_label = nil")
		return
	end
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
			kits.log("error?")
			kits.log("flag="..flag)
			kits.log("yp="..#yp)
			kits.log("np="..#np)
			self._word_index = self._word_index + 1
			self:next_select()
		end
	end
end

--装填下一个词语
function battle:next_select()
	--FIXBUG
	self._judge_index = nil
	self._judge_num = nil
	
	self._ideal_pause = false
	
	if self._word_index > #self._words then
		self:game_over()
		return
	end
	--设置剩余的题数
	self:set_last_proms(#self._words-self._word_index+1)
	
	self._answer_num = 1
	self:hummer_home()
	self:select_word(self._word_index)
	self._word_index = self._word_index + 1

	self._all_num = self._all_num + 1
end

--积分增加timer
function battle:init_adding_timer()
	local t = 0
	local old_time = 0
	local function timer_update(dt)
		t = t + dt or 0
		if self._fen_label and cc_isobj(self._fen_label) then
			if self._fen_adding > 0 then
				if t > old_time+1 then
					old_time = t
					self:play_sound( SND_GOLD )
				end
				self._fen = self._fen + self._fen_adding/5
				self._fen_adding = self._fen_adding - self._fen_adding/5
				if self._fen_adding < 20 then
					self._fen =  self._fen + self._fen_adding
					self._fen_adding = 0
				end
			end
			self._fen_label:setString(tostring(math.floor(self._fen)))
			return true
		end
	end
	uikits.delay_call(self,timer_update,1/20)
end

function battle:startStage()
	kits.log("New game...")
	self._pause = false
	self._hummer:setVisible(true)
	--初始化游戏数据
	self:init_data(self._stage)
	self:init_timer()
	self:init_adding_timer()
	--载入第一词
	self:next_select()
end

function battle:init()
	self._ss = cc.size(1920,1080);
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			uikits.popScene()
		end)
		self._topbar = uikits.child(self._root,ui.TOPBAR)
		self._time_bar = uikits.child(self._root,ui.PROGRESS)
		self._pnum_label = uikits.child(self._root,ui.NUMBER)
		self._fen_label = uikits.child(self._root,ui.SCORE)
		self:init_role()
		self:init_event()
		self:startStage()
	end
end

function battle:release()
	
end

return battle