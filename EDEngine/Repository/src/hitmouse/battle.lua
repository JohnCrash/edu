require "AudioEngine" 
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local lxp = require "lom"
local json = require "json-c"
local level = require "hitmouse/level"

local ui = {
	FILE = 'hitmouse/zuoti.json',
	FILE_3_4 = 'hitmouse/zuoti43.json',
	TOPBAR = 'ding',
	BACK = 'ding/hui',
	NUMBER = 'ding/tu/tishu',
	PROGRESS = 'ding/jindu',
	SCORE = 'ding/defen',
	SCORE_RECT = 'ding/donghua',
	ANIMATION_RGN = "ding/donghua",
	
	ZI1 = "zi1/wen",
	ZI2 = "zi2/wen",
	ZI3 = "zi3/wen",
	ZI4 = "zi4/wen",
	
	TIMEOVER_WINDOW = 'js1',
	SUCCESS_WINDOW = 'js2',
	FAILED_WINDOW = 'js3',
	
	ANIMATION_1 = "hitmouse/NewAnimation/NewAnimation.ExportJson",
	ANIMATION_2 = "hitmouse/chong_zi/chong_zi.ExportJson",
	ANIMATION_3 = "hitmouse/defen/defen.ExportJson",
	
	USE_TIME = 'js1/sj',
	RIGHT_COUNT = 'js1/tisu',
	SCORE_COUNT = 'js1/defen',
	TIME_OVER_BUT = 'js1/quer',
	
	USE_TIME2 = 'js2/sj',
	RIGHT_COUNT2 = 'js2/tisu',
	SCORE_COUNT2 = 'js2/defen',
	SUCCESS_OVER_BUT = 'js2/quer',	
	
	FAILED_OVER_BUT = 'js3/quer',
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

--修改游戏声效
function battle:play_sound( idx )
	local name
	
	if self._player_data and self._player_data.sound then
		if idx == SND_UI_CLICK then
			name = 'hitmouse/snd/qiaoda.mp3'
		elseif idx == SND_CLICK then
			name = 'hitmouse/snd/qiaoda.mp3'
		elseif idx == SND_MISS then
			name = 'hitmouse/snd/shibai.MP3'
		elseif idx == SND_HIT then
			name = 'hitmouse/snd/beida.MP3'
		elseif idx == SND_RIGHT then
			name = 'hitmouse/snd/zhengque.MP3'
		elseif idx == SND_FAIL then
			name = 'hitmouse/snd/shibai.mp3'
		elseif idx == SND_NEXT_PROM then
			name = 'hitmouse/snd/guoguan.MP3'
		elseif idx == SND_PASS then
			name = 'hitmouse/snd/complete.mp3'
		elseif idx == SND_GOLD then
			name = 'hitmouse/snd/gold.mp3'
		else
			return
		end
		kits.log( "Play sound: "..name )
		AudioEngine.playEffect(name)
	end
end

function battle:initGame( arg )
	self._game_time = 0
	self._arg = arg
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
		self:addChild(self._amouse[i])
		self._choose_text[i]:setFontSize(100)
		self._choose_text[i]:setColor(cc.c3b(0,0,0))
	end	
	--锤子
	self._hummer = ccs.Armature:create("NewAnimation")
	self:hummer_home()
	self._hummer:getAnimation():playWithIndex(1)
	self:addChild(self._hummer,2000)
	
	self._defenAnimation = ccs.Armature:create("defen")
	self._defenAnimation:getAnimation():playWithIndex(0)
	self._fen_animation_is_show = false
	self._topbar:addChild(self._defenAnimation)
	self._defenAnimation:setVisible(false)
	self._defenAnimation:setAnchorPoint(cc.p(0,0))
	self._score_rect = uikits.child(self._root,ui.SCORE_RECT)
	local x,y = self._score_rect:getPosition()
	self._defenAnimation:setPosition(cc.p(x,y))
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

--延迟调用
function battle:delay_call(func,param,delay)
	local schedulerID
	if func == nil then
		kits.log( "func = nil?")
		return
	end
	if not schedulerID then
		local function delay_call_func()
			self._scheduler:unscheduleScriptEntry(schedulerID)
			self._schedulerIDS[schedulerID] = nil
			schedulerID = nil		
			func(self,param)
		end
		schedulerID = self._scheduler:scheduleScriptFunc(delay_call_func,delay,false)
		self._schedulerIDS = self._schedulerIDS or {}
		self._schedulerIDS[schedulerID] = schedulerID
	end	
end

function battle:utf8_string_to_table( w )
	local length = cc.utf8.length(w)
	local t = {}
	if length and length > 1 then
		local idx = 0
		repeat
			local idx2 = cc.utf8.next(w,idx)
			if idx2 then
				table.insert(t,string.sub(w,idx+1,idx+idx2))
				idx = idx2 + idx
			end
		until #t >= length
	end
	return t
end

function battle:set_topics_word( w )
	self._topics_world = w
	local t = self:utf8_string_to_table(w)
	local idx = 1
	for i=1,#t do
		local c = t[i]
		if c~='(' and c~=')' then
			self._cn_label[idx]:setString(c)
			idx = idx + 1
		end
		if idx > 4 then
			break
		end
	end
end

function battle:get_topics_word()
	return self._topics_world or ""
end

function battle:flash_xing()
	--self._xing:setVisible(true)
	--self._xing_time = self._game_time
	--self._xing:getAnimation():playWithIndex(0)
end

--显示正确答案n=1 or n=2
function battle:show_right_word( n,b )
	local text = self:get_topics_word() --self._cn_label:getString()
	if text and n <= self._yes_num then
		if self._yes_num > 1 then
			text = string.gsub(text,'　',self._yes[n],1)
		else
			text = string.gsub(text,'　',self._yes[n])
		end
		self:set_topics_word( text ) --self._cn_label:setString(text)
	end
	--答对设置积分增加
	if b then
		self._fen_adding = self._fen_adding + 100 + 10*self._fen_mul
		self._fen_mul = self._fen_mul + 1
		--提示已经过关
		if self._pass or self:getIntegration() > 60 then
			self:play_sound(SND_PASS)
			self:flash_xing()
			self._pass = true
		end
	end
end

--取得积分1-100
function battle:getIntegration()
	--对错占80% , 时间占20%
	local r_rate = 1
	local t_rate = 0
	
	if self._words and #self._words >= 1 and 
		self._word_index >= self._error_num then
		local ra = (100*r_rate)/#self._words --每题多少分数
		local td = (self._time_limit-self._game_time+1)/self._time_limit
		if td > t_rate then td = t_rate end
		if td < 0 then td = 0 end
		return ra*self._right_num + td*100
	else
		return 0
	end
end

--开始下一个词
function battle:reload_scene(b)
	for i=1,4 do
		self._amouse[i]:getAnimation():playWithIndex(0)
	end
	self:next_select()
end

--正确
function battle:show_right(i)
	--重置
	self._fen_mul = 1
	
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
	if self._answer_num == 1 then
		self:show_right_word(1,false)
		self:show_right_word(2,false)
	elseif self._answer_num == 2 then
		self:show_right_word(2,false)
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
function battle:init_data()
	level.init()
	self._words = {}
	self._time_limit = self._arg.time_limit --时限
	self._word_num = self._arg.signle+self._arg.dual --词数	
	local data = level.get{
		diff1=self._arg.diff1,
		diff2=self._arg.diff2,
		rand=self._arg.rand,
		signle=self._arg.signle,
		dual=self._arg.dual}
	kits.log("battle:")
	kits.log("========================")
	kits.log("time limit:"..self._arg.time_limit)
	kits.log("condition:"..self._arg.condition.."%")
	kits.log("num :"..self._word_num)
	kits.log("diff1 = "..self._arg.diff1)
	kits.log("diff2 = "..self._arg.diff2)
	kits.log("rand = "..self._arg.rand)
	kits.log("signle="..self._arg.signle)
	kits.log("dual = "..self._arg.dual)
	kits.log("========================")
	for k,v in pairs(data) do
		kits.log(v.name.."		"..v.answer)
		table.insert(self._words,v)
	end
	math.randomseed(os.time())
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
					self._pause = true -- 暂停游戏
					self:game_over(2)
					return false
				end
			end
			return true
		end
	end
	uikits.delay_call(self,timer_update,1.0)
end

--游戏结束
function battle:game_over(mode)
	if self._game_over_flag then return end
	self._game_over_flag = true
	print("Game Over~")
	local fen100 = self:getIntegration()
	local b = fen100 > 60
	kits.log("分数:"..self:getIntegration())
	
	self._worm:setVisible(false)
	local fen_text = tostring(math.floor(self._fen))
	self._fen_label:setString(fen_text)
	for i=1,4 do
		self._amouse[i]:setVisible(false)
		self._cn_label[i]:getParent():setVisible(false)
	end
	if b then
		--播放成功过关的声音
		self:play_sound(SND_NEXT_PROM)	
		if mode == 2 then
			self._timeover_ui:setVisible(true)
			uikits.child(self._root,ui.USE_TIME):setString(tostring(self._xing_time))
			uikits.child(self._root,ui.RIGHT_COUNT):setString(tostring(self._right_num))
			uikits.child(self._root,ui.SCORE_COUNT):setString(fen_text)			
		else
			self._pnum_label:setString("0")
			self._success_ui:setVisible(true)
			uikits.child(self._root,ui.USE_TIME2):setString(tostring(self._xing_time))
			uikits.child(self._root,ui.RIGHT_COUNT2):setString(tostring(self._right_num))
			uikits.child(self._root,ui.SCORE_COUNT2):setString(fen_text)
		end
	else
		self._failed_ui:setVisible(true)
	end
	
	if b then
		--提交到网络
		--self:upload_rank( self._player_data.stage,self._fen )
	end	
end

function battle:upload_rank( stage,score )
end

--设置剩余的题数
function battle:set_last_proms( N )
	if self._pnum_label then
		self._pnum_label:setString( tostring(N) )
	end
end

--选择第index个词语
function battle:select_word(index)
	self:set_topics_word(self._words[index].name)
	
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

--多次偏移
function battle:rand_idx_loop(n)
	for i=1,n do
		self:random_idx()
	end
end

function battle:random_idx()
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

function battle:merge_word(yp,np)
	local p = {}
	for i,v in ipairs(yp) do
		p[#p+1] = v
	end
	for i,v in ipairs(np) do
		p[#p+1] = v
	end
	return p			
end

--设置词语yp,np.正确答案，错误答案
function battle:set_word( yp,np )
	--合并到一个4个表中
	local p = self:merge_word(yp,np)
	--随机移动
	self:rand_idx_loop(5)
	self._yes_num = #yp
	self._yes = yp
	if self._yes_num > 0 and #p == 4 then
		for i,v in ipairs(self._rand_idx) do
			self._choose_text[i]:setString(p[v])
		end
	else
		kits.log("Error word")
	end
end

--装填下一个词语
function battle:next_select()
	--FIXBUG
	self._judge_index = nil
	self._judge_num = nil
	
	self._ideal_pause = false
	
	if self._word_index > #self._words then
		self:game_over(1)
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
				if not self._fen_animation_is_show then
					self._defenAnimation:setVisible(true)
					
					self._fen_animation_is_show = true
				end
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
			elseif self._fen_animation_is_show then
				self._defenAnimation:setVisible(false)
				self._fen_animation_is_show = false
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
	self:init_data()
	self:init_timer()
	self:init_adding_timer()
	--载入第一词
	self:next_select()
end

function battle:load_player_data()
	local s = kits.read_local_file('hitmouse.json')
	if s then
		self._player_data = json.decode( s )
	end
end

function battle:save_player_data()
	if self._player_data then
		local s = json.encode( self._player_data )
		if s then
			kits.write_local_file('hitmouse.json',s)
		else
			kits.log("save_player_data error!")
		end
	end
end

function battle:init_player_data()
	self:load_player_data()
	self._player_data = self._player_data or { sound = true,music = true,stage = 1,scroce=0 }
end

function battle:init()
	self._ss = cc.size(1920,1080);
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		self._scheduler = self:getScheduler()
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			uikits.popScene()
		end)
		self._topbar = uikits.child(self._root,ui.TOPBAR)
		self._time_bar = uikits.child(self._root,ui.PROGRESS)
		self._pnum_label = uikits.child(self._root,ui.NUMBER)
		self._fen_label = uikits.child(self._root,ui.SCORE)
		self._cn_label = {}
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI1))
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI2))
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI3))
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI4))
		self._timeover_ui = uikits.child(self._root,ui.TIMEOVER_WINDOW)
		self._success_ui = uikits.child(self._root,ui.SUCCESS_WINDOW)
		self._failed_ui = uikits.child(self._root,ui.FAILED_WINDOW)
		self:init_role()
		self:init_player_data()
		self:init_event()
		self:startStage()
		self._mut = kits.config("hitmouse_mute","get")
		if not self._mut then
			math.randomseed(os.time())
			music.stop()
			music.play()
		end		
	end
end

function battle:release()
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_1)
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_2)
	ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_3)
	if self._schedulerIDS then
		for i,v in pairs(self._schedulerIDS) do
			if v then
				self._scheduler:unscheduleScriptEntry(v)
			end
		end
	end
	self._schedulerIDS = nil
end

return battle