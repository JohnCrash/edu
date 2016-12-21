require "AudioEngine" 
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local lxp = require "lom"
local json = require "json-c"
local level = require "han/game"
local state = require "han/state"
local http = require "han/http"
local music = require "han/music"

local _platform = cc.Application:getInstance():getTargetPlatform()
--本地支援缓冲区
local local_dir = kits.get_local_directory()..'res/'
local SND_UI_CLICK = 0
local SND_CLICK = 1
local SND_MISS = 2
local SND_HIT = 3
local SND_RIGHT = 4
local SND_FAIL = 5
local SND_NEXT_PROM = 6
local SND_PASS = 7
local SND_GOLD = 8

local ui = {
	FILE = 'han/zuoti.json',
	FILE_3_4 = 'han/zuoti43.json',
	TOPBAR = 'ding',
	BACK = 'ding/hui',
	NUMBER = 'ding/tu/tishu',
	PROGRESS = 'ding/jindu',
	SCORE = 'ding/defen',
	SCORE_RECT = 'ding/donghua',
	ANIMATION_RGN = "ding/donghua",
	OK_BUT = 'quer',
	
	ZI1 = "tix1/da1/w1",
	ZI2 = "tix1/da2/w1",
	ZI3 = "tix1/da3/w1",
	ZI4 = "tix1/da4/w1",
	
	TIMEOVER_WINDOW = 'js1',
	SUCCESS_WINDOW = 'js2',
	FAILED_WINDOW = 'js3',
	
	ANIMATION_1 = "han/NewAnimation/NewAnimation.ExportJson",
	ANIMATION_2 = "han/chong_zi/chong_zi.ExportJson",
	ANIMATION_3 = "han/defen/defen.ExportJson",
	
	ANIMATION_JUDGE = "han/success/success.ExportJson",
	
	ANIMATION_BAOYA = "han/baoya/baoya.ExportJson",
	ANIMATION_BANGZI = "han/bangzi/bangzi.ExportJson",
	ANIMATION_TOUMU = "han/toumu/toumu.ExportJson",
	
	ANIMATION_RIGHT = "han/gou/gou.ExportJson",
	
	USE_TIME = 'js1/sj',
	RIGHT_COUNT = 'js1/tisu',
	SCORE_COUNT = 'js1/defen',
	TIME_OVER_BUT = 'js1/quer',
	
	USE_TIME2 = 'js2/sj',
	RIGHT_COUNT2 = 'js2/tisu',
	SCORE_COUNT2 = 'js2/defen',
	SUCCESS_OVER_BUT = 'js2/quer',	
	
	FAILED_OVER_BUT = 'js3/quer',
	
	SHARE_SCORE_LABEL1 = 'js1/w3',
	SHARE_SCORE1 = 'js1/gongxian',
	SHARE_SCORE_LABEL2 = 'js2/w3',
	SHARE_SCORE2 = 'js2/gongxian',
	
	MATCH_OVER = 'js4',
	USE_TIME3 = 'js4/sj',
	RIGHT_COUNT3 = 'js4/tisu',
	SCORE_COUNT3 = 'js4/defen',
	MATCH_OVER_BUT = 'js4/quer',	
	SHARE_SCORE_LABEL3 = 'js4/w3',
	SHARE_SCORE3 = 'js4/gongxian',	
	
	TYPE_BASE = 'tix',
	
	TYPE2_NAME = "tu/chengy",
	
	TYPE3_NAME = "tu/renw",
	
	TYPE4_NAME = "tu/chucu",
	
	TYPE5_NAME = "tu/chengy",
	
	TYPE6_NAME = "tu/chengy",
	
	TYPE7_EXPLANATION = 'tu/chengy',
	TYPE7_INPUT = 'datiqu/shuru',
	TYPE7_MK_BUT = 'datiqu/yuyin',
	TYPE7_OK = 'datiqu/quer',
}

local JUDGE_RIGHT = 1
local JUDGE_WRONG = 2

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
	if idx == SND_UI_CLICK then
		name = 'han/snd/qiaoda.mp3'
	elseif idx == SND_CLICK then
		name = 'han/snd/qiaoda.mp3'
	elseif idx == SND_MISS then
		name = 'han/snd/shibai.MP3'
	elseif idx == SND_HIT then
		name = 'han/snd/beida.MP3'
	elseif idx == SND_RIGHT then
		name = 'han/snd/zhengque.MP3'
	elseif idx == SND_FAIL then
		name = 'han/snd/shibai.mp3'
	elseif idx == SND_NEXT_PROM then
		name = 'han/snd/guoguan.MP3'
	elseif idx == SND_PASS then
		name = 'han/snd/complete.mp3'
	elseif idx == SND_GOLD then
		name = 'han/snd/gold.mp3'
	else
		return
	end
	kits.log( "Play sound: "..name )
	--print("kits.get_local_directory() = "..kits.get_local_directory())
	AudioEngine.playEffect(local_dir..name)
end

function battle:initGame( arg )
	self._game_time = 0
	self._arg = arg
	if arg and type(arg)=='table' then
		self._time_limit = arg.time_limit or 30
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
		arm:removeArmatureFileInfo(ui.ANIMATION_JUDGE)
		arm:addArmatureFileInfo(ui.ANIMATION_JUDGE)
		arm:removeArmatureFileInfo(ui.ANIMATION_BAOYA)
		arm:addArmatureFileInfo(ui.ANIMATION_BAOYA)
		arm:removeArmatureFileInfo(ui.ANIMATION_BANGZI)
		arm:addArmatureFileInfo(ui.ANIMATION_BANGZI)
		arm:removeArmatureFileInfo(ui.ANIMATION_TOUMU)
		arm:addArmatureFileInfo(ui.ANIMATION_TOUMU)		
		arm:removeArmatureFileInfo(ui.ANIMATION_RIGHT)
		arm:addArmatureFileInfo(ui.ANIMATION_RIGHT)				
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
			b = -64
			self._amouse[i]:setPosition(cc.p(b+(i-1)*(box.width+b),1.0*box.height))
		else
			self._amouse[i]:setPosition(cc.p(b+(i-1)*(box.width+b),1.0*box.height))
		end
		self._choose_text[i]:setAnchorPoint(cc.p(0.5,0.5))
		local bone = self._amouse[i]:getBone("Layer12")
		if bone then
			bone:addDisplay(self._choose_text[i],0)
			bone:changeDisplayWithIndex(0,true)
		end
		self:addChild(self._amouse[i],100)
		self._choose_text[i]:setFontSize(100)
		self._choose_text[i]:setColor(cc.c3b(0,0,0))
	end	
	self._character = {}
	self._character_text = {}
	local scale 
	if self._screen ==1 then
		scale = 0.5
	else
		scale = 0.7
	end
	local animation_table = {"baoya","bangzi","toumu"}
	for k=1,3 do
		self._character[k] = {}
		self._character_text[k] = {}
		for i=1,4 do
			self._character[k][i] = ccs.Armature:create(animation_table[k])
			self._character_text[k][i] = ccui.Text:create()
			local box = self._character[k][i]:getBoundingBox()
			self._character[k][i]:getAnimation():playWithIndex(0)
			
			local b 
			if self._screen == 1 then
				b = (self._ss.width-4*box.width*scale)/5
				b=-450
			else
				b = (self._ss.width-4*box.width*scale)/5
				b=-300			
			end
			self._character[k][i]:setAnchorPoint(cc.p(0,0))
			local offsetx,offsety
			if self._screen == 1 then
				offsetx,offsety = 200,-100
			else
				offsetx,offsety = 0,-200
			end
			--if k==1 then
			--	offsetx = -60
			--end
			offsetx = offsetx + 260
			if self._screen == 1 then
				self._character[k][i]:setPosition(cc.p(b+(i-1)*(box.width+b)+offsetx,0.3*box.height+offsety))
			else
				self._character[k][i]:setPosition(cc.p(b+(i-1)*(box.width+b)+offsetx,0.3*box.height+offsety))
			end
			self._character[k][i]:setScaleX(scale)
			self._character[k][i]:setScaleY(scale)
			self._character_text[k][i]:setAnchorPoint(cc.p(0.5,0.5))
			local bone = self._character[k][i]:getBone("ti")
			if bone then
				bone:addDisplay(self._character_text[k][i],0)
				bone:changeDisplayWithIndex(0,true)
			else
				kits.log("ERROR self._character["..k.."] getBone('ti') = nil")
			end
			self:addChild(self._character[k][i],100)
			self._character_text[k][i]:setFontSize(85)
			self._character_text[k][i]:setColor(cc.c3b(0,0,0))
		end
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
	if self._score_rect then
		local x,y = self._score_rect:getPosition()
		self._defenAnimation:setPosition(cc.p(x,y))
	else
		self._defenAnimation:setVisible(false)
	end
end

function battle:showMouse(b)
	self._is_mouse_show = b
	for i=1,4 do
		if self._amouse[i] then
			self._amouse[i]:setVisible(b)
		end
	end
end

function battle:switchCharacter(i,b)
	self._is_character_show = b
	self._idx_character_show = i
	for k=1,3 do
		for s=1,4 do
			if k~=i then
				self._character[k][s]:setVisible(false)
			else
				self._character[k][s]:setVisible(b)
			end
			self._character[k][s]:getAnimation():playWithIndex(math.random(0,4))			
		end
	end
end

function battle:initAnswer(q)
	if self._is_character_show and self._idx_character_show then
		if q and q.answer then
			for i=1,4 do
				self._character_text[self._idx_character_show][i]:setString(q.answer[i] or "-")
			end
		else
			kits.log("ERROR initAnswer q or q.answer = nil")
			http.logTable(q,1)
		end
	else
		kits.log("ERROR self._is_character_show = "..tostring(self._is_character_show))
		kits.log("ERROR self._idx_character_show = "..tostring(self._idx_character_show))
	end
end

function battle:showHummer(b)
	if self._hummer then
		self._hummer:setVisible(b)
	end
end

function battle:hummer_home()
	if _platform~=cc.PLATFORM_OS_WINDOWS then
		if self._screen == 1 then
			self._hummer:setPosition( cc.p(self._ss.width/10,64) )
		else
			self._hummer:setPosition( cc.p(self._ss.width/10,self._ss.height*4.6/7) )
		end
	end
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

--[[
				type(int):题目的类型(1-7)			
					1.成语补全,缺字选择补全
					2.成语选典故人物
					3.典故选成语
					4.出处选成语
					5.成语选出处
					6.释义选成语
					7.释义填空成语
--]]					
local tst = {
	35, --1
	60,
	75,
	110,
	100,
	40,
	110,
	35, --8
	60,
	75,
	110,
	100,
	40,
	110,	
}

function battle:clac_score(ttype)
	local dt = os.time() - self._ttime
	local base_score = tst[ttype] or 30
	
	local tt = (self._avg_time - dt)
	if tt < 0 then
		tt = 0
	end
	kits.log("基础分:"..base_score.." 时间分:"..tostring(tt*6).." 累计分:"..tostring(10*self._fen_mul))
	self._fen_adding = math.floor(self._fen_adding + base_score + 10*self._fen_mul + tt*6)
	self._fen_mul = self._fen_mul + 1
end

function battle:judge2(i)
	self._current_word.my_answer = self._current_word.answer[i]
	if self._current_word.answer[i] == self._current_word.correct then
		self._current_word.judge = true
		self._character[self._idx_character_show][i]:getAnimation():playWithIndex(5)
		self:play_sound(SND_RIGHT)
		self:delay_call(self.next_select,nil,1.5)
		self:clac_score(self._current_word.type)
		
		self._right_num = self._right_num + 1
		kits.log("INFO "..tostring(self._current_word.answer[i]).."=="..tostring(self._current_word.correct))
		kits.log("INFO right_num = "..tostring(self._right_num))
	else
		self._current_word.judge = false
		self._character[self._idx_character_show][i]:getAnimation():playWithIndex(6)
		self:delay_call(self.show_right2,i,2)
		self:play_sound(SND_FAIL)
		self._fen_mul = 1
		self._error_num = self._error_num + 1
		kits.log("INFO "..tostring(self._current_word.answer[i]).."~="..tostring(self._current_word.correct))
		kits.log("INFO right_num = "..tostring(self._right_num))		
	end
end

function battle:show_right2(si)
	self:hummer_home()
	for i=1,4 do
		if self._current_word.answer[i]==self._current_word.correct then
			self._character[self._idx_character_show][i]:getAnimation():playWithIndex(7)
			break
		end
	end
	self:delay_call(self.next_select,nil,2)
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
		self._current_word.judge = true
		self:clac_score(self._current_word.type)
		
		--提示已经过关
		if self._pass or self:getIntegration() > self._arg.condition then
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
	self._current_word.judge = false
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
		if self._game_over_flag then return end
		local p = touches[1]:getLocation()
		self._hummer:getAnimation():playWithIndex(1)
		self._hummer:setPosition(p)
		if self._pause then return end
		if self._is_mouse_show then
			for i=1,4 do
				local box = self._amouse[i]:getBoundingBox()
				if p.x > box.x and p.x < box.x+box.width and
					p.y > box.y and p.y < box.y+box.height then
					self:judge(i)
					return
				end
			end
		elseif self._is_character_show and self._idx_character_show and self._character[self._idx_character_show] then
			if self._ideal_pause then return end
			for i=1,4 do
				local box = self._character[self._idx_character_show][i]:getBoundingBox()
				if p.x > box.x and p.x < box.x+box.width and
					p.y > box.y and p.y < box.y+box.height then
					self._ideal_pause = true
					self:judge2(i)
					return
				end
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
		if key == cc.KeyCode.KEY_ESCAPE then
			--返回上一层对话栏
			--if event == ccui.TouchEventType.ended then
				if self._where then
					kits.log( 'self._where:')
					self._where( self )
				else
					--Android return key
					kits.log( 'self._where: nil')
					--backMain()
					--uikits.popScene()
					if self._arg.type==1 or self._arg.type==4 then
						local text
						if self._arg.type==1 then
							text = "你‘确定’要退出闯关吗？"
						else
							text = "你‘确定’要退出错题任务吗？"
						end
						
						if not self._ismessagebox then
						self._ismessagebox = true
						http.messagebox(self._root,http.DIY_MSG,function(e)
							self._ismessagebox = false
							if e==http.OK then
								self._game_over_flag = true
								uikits.popScene()
							end
						end,text,"确定")			
						end
					else
						http.messagebox(self._root,http.DIY_MSG,function(e)
							if e==http.OK then
								self:upload_scroe2(self._arg.level,math.floor(self._fen),self._game_time,self._right_num,-1)					
							end
						end,"退出比赛将浪费一次比赛机会\n你‘确定’要退出比赛吗？","确定")						
					end					
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
--	self._words = {}
	self._time_limit = self._arg.time_limit --时限
	
	local data
	
	if self._arg.type ~= 4 then
		kits.log("battle:init_data")
		--kits.logTable(self._arg)
		data = level.get(self._arg)
	else
		--错题任务
		data = self._arg
		if data.answers then
			for i,v in pairs(data.answers) do
				if v.cy_id then
					data.answers[i] = json.decode(v.cy_id)
				end
			end
		else
			kits.log("ERROR data.answers = nil")
		end
	end
	kits.log("data:")
	kits.logTable(data)
	self._word_num = data.question_amount
	self._words = data.answers
	
	--fixbug
	if self._words then
		self._word_num = 0
		for i,v in pairs(self._words) do
			self._word_num	= self._word_num + v.count or 0
		end
	end
	--计算每道题的平均用时
	kits.log("self._time_limit = "..self._time_limit)
	kits.log("self._word_num = "..self._word_num)
	if self._time_limit and self._word_num and self._word_num~=0 then
		self._avg_time = self._time_limit/self._word_num
	else
		self._avg_time = 0
	end
	--[[
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
	--]]
	math.randomseed(self._arg.road_radom or 0)
	--一次加载全部的词，然后随机挑出_word_num个词
	--[[
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
	--]]
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
	self._xing_time = 0 --通关时间
end

function battle:init_timer()
	self._game_time = 0
	self:update_time_bar()
	local function timer_update(time)
		if self._time_bar and cc_isobj(self._time_bar) then
			if self._game_over_flag then
				return
			end
			--不要显示大于时限的
			if self._game_time <= self._time_limit then
				--self._time_label:setText(self._game_time.."/"..self._time_limit)
				self._game_time = self._game_time + 1
				self:update_time_bar()
			end
			if not self._ideal_pause then
				if self._is_mouse_show then
					if self._game_time % 3 == 0 then
						self._amouse[math.random(1,2)]:getAnimation():playWithIndex(math.random(4,5))
						self._amouse[math.random(3,4)]:getAnimation():playWithIndex(math.random(4,5))
					elseif self._game_time % 3 == 1 then
						self._amouse[math.random(1,2)]:getAnimation():playWithIndex(math.random(4,5))
						self._amouse[math.random(3,4)]:getAnimation():playWithIndex(math.random(4,5))
					end
				elseif self._is_character_show and self._idx_character_show and self._character[self._idx_character_show] then
					if self._game_time % 3 == 0 then
						self._character[self._idx_character_show][math.random(1,2)]:getAnimation():playWithIndex(math.random(0,4))
						self._character[self._idx_character_show][math.random(3,4)]:getAnimation():playWithIndex(math.random(0,4))
					elseif self._game_time % 3 == 1 then
						self._character[self._idx_character_show][math.random(1,2)]:getAnimation():playWithIndex(math.random(0,4))
						self._character[self._idx_character_show][math.random(3,4)]:getAnimation():playWithIndex(math.random(0,4))
					end					
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

local function l4p5(x) --四舍五入
	local d = math.floor(x)
	if x-d>=0.5 then
		return d+1
	else
		return d
	end
end

--游戏结束
function battle:game_over(mode)
	if self._game_over_flag then return end
	self._game_over_flag = true
	kits.log("Game Over~")
	local fen100 = self:getIntegration()
	local b = fen100 >= self._arg.condition
	kits.log("分数:"..self:getIntegration())
	
	self._worm:setVisible(false)
	local fen_text = tostring(math.floor(self._fen))
	self._fen_label:setString(fen_text)
	--[[
	for i=1,4 do
		self._amouse[i]:setVisible(false)
		self._cn_label[i]:getParent():setVisible(false)
	end
	self:switchCharacter(1,false)
	--]]
	if self._current_plane then
		self._current_plane:setVisible(false)
	end
	self:showHummer(false)
	
	if self._arg.type==1 or self._arg.type==4 then
		local ok
		if b then
			--播放成功过关的声音
			self:play_sound(SND_NEXT_PROM)	
			if mode == 2 then
				ok=uikits.child(self._failed_ui,ui.OK_BUT)
				self._failed_ui:setVisible(true)			
			--[[
				--self._timeover_ui:setVisible(true)
				--uikits.child(self._root,ui.USE_TIME):setString(tostring(self._game_time))
				uikits.child(self._root,ui.RIGHT_COUNT):setString(tostring(self._right_num))
				uikits.child(self._root,ui.SCORE_COUNT):setString(fen_text)		
				--ok=uikits.child(self._timeover_ui,ui.OK_BUT)
				local label = uikits.child(self._root,ui.SHARE_SCORE_LABEL1)
				local share_score = uikits.child(self._root,ui.SHARE_SCORE1)
				if http.get_id_flag()==http.ID_FLAG_PAR then
				--if false then
					share_score:setString(tostring(l4p5(self._fen*0.1)))
				else
					label:setVisible(false)
					share_score:setVisible(false)
				end
				--]]
			else
				self._success_ui:setVisible(true)
				uikits.child(self._root,ui.USE_TIME2):setString(tostring(self._game_time))
				uikits.child(self._root,ui.RIGHT_COUNT2):setString(tostring(self._right_num))
				uikits.child(self._root,ui.SCORE_COUNT2):setString(fen_text)
				ok=uikits.child(self._success_ui,ui.OK_BUT)
				local label = uikits.child(self._root,ui.SHARE_SCORE_LABEL2)
				local share_score = uikits.child(self._root,ui.SHARE_SCORE2)
				if label then
					if http.get_id_flag()==http.ID_FLAG_PAR then
					--if false then
						label:setVisible(true)
						share_score:setVisible(true)						
						share_score:setString(tostring(l4p5(self._fen*0.1)))
					else
						label:setVisible(false)
						share_score:setVisible(false)
					end
				end
			end
		else
			ok=uikits.child(self._failed_ui,ui.OK_BUT)
			self._failed_ui:setVisible(true)
		end
		if ok then
			uikits.event(ok,function(sender)
				self._game_over_flag = true
				uikits.popScene()
			end)
		end
		if b then
			--提交游戏数据
			self:upload_scroe2(self._arg.level,math.floor(self._fen),self._game_time,self._right_num,fen100)
		end
	elseif self._arg.type==2 or self._arg.type==3 then
		--比赛结束
		local moui = uikits.child(self._root,ui.MATCH_OVER)
		moui:setVisible(true)
		uikits.child(self._root,ui.USE_TIME3):setString(tostring(self._game_time))
		uikits.child(self._root,ui.RIGHT_COUNT3):setString(tostring(self._right_num))	
		uikits.child(self._root,ui.SCORE_COUNT3):setString(tostring(math.floor(self._fen)))
		local label = uikits.child(self._root,ui.SHARE_SCORE_LABEL3)
		local share_score = uikits.child(self._root,ui.SHARE_SCORE3)		
		if http.get_id_flag()== http.ID_FLAG_PAR then
		--if false then
			label:setVisible(true)
			share_score:setVisible(true)		
			share_score:setString(tostring(math.floor(self._fen*0.1)))
		else
			label:setVisible(false)
			share_score:setVisible(false)
		end		
		local ok = uikits.child(self._root,ui.MATCH_OVER_BUT)
		if ok then
			uikits.event(ok,function(sender)
				self._game_over_flag = true
				uikits.popScene()
			end)
		end		
		self:upload_scroe2(self._arg.level,math.floor(self._fen),self._game_time,self._right_num,fen100)
	else
		kits.log("ERROR invalid match type "..tostring(self._arg.type))
	end
end
--[[
function battle:upload_scroe( level_id,score,use_time,right_num )
	local send_data = {v1=level_id,v2=self._arg.type,v3=score,v4=right_num,v5=use_time}
	kits.log("do battle:upload_scroe")
	http.post_data(self._root,'submit_integral',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			local current = level.getCurrent()
			local count = level.getLevelCount()
			if current<count then
				level.setCurrent(current+1)
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
			   if e==http.OK then
					self:upload_scroe( level_id,score,use_time,right_num )
				else
					uikits.popScene()
				end
			end,v)
		end
	end)
end
--]]
function battle:upload_scroe2( level_id,score,use_time,right_num,fen100 )
	local send_data = {v1=level_id,v2=self._arg.type,v3=use_time,v5=self._arg.subid,v6=score,v7=fen100,v8=self._arg.diff}
	send_data.v4 = {}
	--[[错题
	for i,v in pairs(self._words) do
		local en
		if v.judge or self._arg.type~=1 then
			en = ''
		else
			en = json.encode(v)
		end
		table.insert(send_data.v4,{type=v.type,isright=v.judge,cy_id=en})
	end
	--]]
	kits.log("do battle:upload_scroe2")
	http.post_data(self._root,'submit_answer',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			if v.v1 and self._arg.type==1 then
				local d=level.getDifficulty()
				local current = level.getCurrent(d)
				local count = level.getLevelCount(d)
				if current<count and level_id == current then
					level.setCurrent2(current+1,d)
				end
				--重新设置星星数
				local st = level.get_level_star(d)
				if v.v2 and st and st[level_id] then
					local sc = tonumber(st[level_id].star_count)
					kits.log("INFO OLD STAR COUNT = "..tostring(sc))
					kits.log("INFO NEW STAR COUNT = "..tostring(v.v2))
					if sc and sc < v.v2 then
						st[level_id].star_count = v.v2
					end
				end
			end
			if v.v1 then
				if v.v4 then
					state.set_sliver(v.v4)
				end
				if v.v5 and v.v6 and v.v7 then
					state.set_sp(v.v5,v.v6,v.v7)
				end
			end
			if fen100 < 0 then
				self._game_over_flag = true
				uikits.popScene()
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
			   if e==http.OK then
					self:upload_scroe2( level_id,score,use_time,right_num,fen100 )
				else
					self._game_over_flag = true
					uikits.popScene()
				end
			end,v)
		end
	end)
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
	if self._current_word then --不允许错误
		if self._arg.type==4 and not self._current_word.judge then
			self._pause = false
			self._ideal_pause = false
			self._judge_index = nil
			self._judge_num = nil			
			self._answer_num = 1
			self:hummer_home()			
			self._word_index = self._word_index - 1
			self:init_current_question(self._current_word)
			self._word_index = self._word_index + 1
			return
		end
	end
	--FIXBUG
	self._judge_index = nil
	self._judge_num = nil
	self._ttime = os.time()
	self._ideal_pause = false
	kits.log("===========next_select===========")
	kits.log(tostring(self._word_index).."/"..tostring(#self._words))
	kits.log("======================")
	if self._word_index > #self._words then
		self:set_last_proms(0)
		self:game_over(1)
		return
	end
	--设置剩余的题数
	self:set_last_proms(#self._words-self._word_index+1)
	
	self._current_word = self._words[self._word_index]
	self:init_current_question(self._current_word)
	--[[
	self._answer_num = 1
	self:hummer_home()
	self:select_word(self._word_index)
	--]]
	self._answer_num = 1
	self:hummer_home()
	
	self._word_index = self._word_index + 1
	self._all_num = self._all_num + 1
	self._pause = false
end

function battle:init_problem( plane,topics,choose,q,label_name )
	local isSelected = false
	local selectedItem
	--初始化题面
	local prob_item 
	for i,v in ipairs(topics) do
		local item = uikits.child(plane,v)
		if item and item.setString then
			if type(q.name)=='table' and q.name[i] then
				if q.name[i] == ' ' then
					prob_item = item
				end
				item:setString( tostring(q.name[i]) )
			elseif type(q.name)=='string' then
				item:setString( q.name )
			else
				kits.log("Problem error q.name = "..tostring(q.name))
			end
		else
			kits.log("Problem error item = nil or item not setString q.type = "..tostring(q.type))
			kits.log("v = "..tostring(v))
		end
	end
	--初始化选择
	local right_location = nil
	for i,v in ipairs(choose) do
		local item = uikits.child(plane,v)
		if item then
			if label_name then
				local text = uikits.child(item,label_name)
				if text then
					if q.answer and q.answer[i] then
						--设置正确答案位置
						if tostring(q.answer[i]) == tostring(q.correct) then
							right_location = item
						end
						text:setString( tostring(q.answer[i]) )
					else
						kits.log("Problem error q.type = "..tostring(q.type))
						kits.log("q.answer = "..tostring(q.answer))	
						text:setString( "" )
					end
				else
					kits.log("Problem error q.type = "..tostring(q.type))
					kits.log("label_name = "..tostring(label_name))
				end
			else
				--对错
				--设置正确答案位置
				if tostring(q.answer[i]) == tostring(q.correct) then
					right_location = item
				end	
			end
			if item.setSelectedState then
				item:setSelectedState(false)
			end
			uikits.event(item,function(sender)
				if isSelected then 
					if sender and sender.setSelectedState then
						if sender == selectedItem then
							item:setSelectedState(true)
						else
							item:setSelectedState(false)
						end
					end
					return 
				end
				isSelected = true
				selectedItem = sender
				if prob_item then
					prob_item:setString(q.answer[i])
				end				
				
				if tostring(q.answer[i]) == tostring(q.correct) then
				--if true then
					--选择正确
					self:play_sound(SND_RIGHT)
					q.judge = true
					self:clac_score(q.type)
					
					self._right_num = self._right_num + 1
					kits.log("INFO "..tostring(q.answer[i]).."=="..tostring(q.correct))
					kits.log("INFO right_num = "..tostring(self._right_num))		
					dt = self:playJudgeAnimation(JUDGE_RIGHT)	
					uikits.delay_call(self._root,function(s)
						self:next_select()
					end,dt)						
				else
					--选择错误
					self:play_sound(SND_FAIL)
					q.judge = false
					self._fen_mul = 1
					self._error_num = self._error_num + 1				
					dt = self:playJudgeAnimation(JUDGE_WRONG)		
					uikits.delay_call(self._root,function(s)
						--show right
						if right_location then
							if not self._right_animation then
								self._right_animation = ccs.Armature:create("gou")
								self:addChild(self._right_animation,10)
							end
							self._right_animation:setVisible(true)
							local x,y = right_location:getPosition()
							local size = right_location:getContentSize()
							self._right_animation:setScaleX(0.6)
							self._right_animation:setScaleY(0.6)
							self._right_animation:setPosition(cc.p(x+size.width/2,y-size.height/2))
							self._right_animation:getAnimation():playWithIndex(0)
							uikits.delay_call(self._root,function(s)
								self._right_animation:setVisible(false)
								self:next_select()
							end,3)
						else
							kits.log("right_location = nil")
						end
					end,dt)	
				end
			end)
		else
			kits.log("Problem error item = nil q.type = "..tostring(q.type))
			kits.log("v = "..tostring(v))		
		end
	end
end

local fonts = {
	"han/font/cao.ttf",
	"han/font/xing.ttf",
	"han/font/zhuan.ttf",
}

function battle:initType5Font()
	if self._fontLabel then return end
	self._fontLabel = {}
	for i=1,3 do
		self._fontLabel[i] = cc.Label.createWidthTTF("",fonts[i],32)
	end
end

local function random_rang(rangs)
	local count = #rangs
	for i = 1,count do
		local s = rangs[i]
		local idx = math.random(1,count)
		rangs[i] = rangs[idx]
		rangs[idx] = s
	end	
end

function battle:type5(plane,topics,word,choose,q)
	local isSelected = false
	local selectedItem
	local st = math.random(1,3)
	local cn
	local right_location
	local rm = {1,2,3}
	random_rang(rm)
	--self:initType5Font()
	if st==1 then
		cn = "草书"
	elseif st==2 then
		cn = "行书"
	elseif st==3 then
		cn = "篆书"
	else
		return
	end
	local top = uikits.child(plane,topics)
	if top then
		top:setString(string.format("请选择以下字所对应%s的是哪一个？",cn))
	end
	local wor = uikits.child(plane,word)
	if wor then
		wor:setString(q.name)
	end
	local cho = {}
	--print( "cn="..cn)
	for i=1,#choose do
		cho[i] = uikits.child(plane,choose[i])
		if cho[i] then
			cho[i]:setString(q.name)
			print("index = "..i)
			print("setFontName : "..tostring(fonts[rm[i]]))
			cho[i]:setFontName(fonts[rm[i]])
		--	print(i..":"..rm[i]..":"..fonts[rm[i]])
			if st == rm[i] then
				right_location = cho[i]:getParent()
			end
			local item  = cho[i]:getParent()
			if item.setSelectedState then
				item:setSelectedState(false)
			end			
			uikits.event(item,function(sender)
				if isSelected then 
					if item and item.setSelectedState then
						if sender == selectedItem then
							item:setSelectedState(true)
						else
							item:setSelectedState(false)
						end
					end
					return 
				end
				isSelected = true	
				selectedItem = sender				
				if st == rm[i] then
				--if true then
					--选择正确
					self:play_sound(SND_RIGHT)
					q.judge = true
					self:clac_score(q.type)
						
					self._right_num = self._right_num + 1	
					dt = self:playJudgeAnimation(JUDGE_RIGHT)	
					uikits.delay_call(self._root,function(s)
						self:next_select()
					end,dt)		
				else
					--选择错误
					self:play_sound(SND_FAIL)
					q.judge = false
					self._fen_mul = 1
					self._error_num = self._error_num + 1				
					dt = self:playJudgeAnimation(JUDGE_WRONG)		
					uikits.delay_call(self._root,function(s)
						--show right
						if right_location then
							if not self._right_animation then
								self._right_animation = ccs.Armature:create("gou")
								self:addChild(self._right_animation,10)
							end
							self._right_animation:setVisible(true)
							local x,y = right_location:getPosition()
							local size = right_location:getContentSize()
							self._right_animation:setPosition(cc.p(x+size.width/2,y-size.height/2))
							self._right_animation:getAnimation():playWithIndex(0)
							uikits.delay_call(self._root,function(s)
								self._right_animation:setVisible(false)
								self:next_select()
							end,3)
						else
							kits.log("right_location = nil")
						end
					end,dt)	
				end
			end)
		end
	end
end

function battle:type6(plane,topcis,words,choose,q)
	local isSelected = false
	local st = math.random(1,3)
	local cn
	local right_location
	local rm = {1,2,3}
	random_rang(rm)
	--self:initType5Font()
	if st==1 then
		cn = "草书"
	elseif st==2 then
		cn = "行书"
	elseif st==3 then
		cn = "篆书"
	else
		return
	end
	local top = uikits.child(plane,topcis)
	if top then
		top:setString(string.format("请判断以下字是否是%s？",cn))
	end
	local correct = math.random(1,2) --1正确，2错误
	local wor = uikits.child(plane,words[1])
	if wor then
		wor:setString(q.name)
	end
	local wor2 = uikits.child(plane,words[2])
	if wor2 then
		wor2:setString(q.name)
		if correct == 1 then
			wor2:setFontName(fonts[st])
		else
			local c = {}
			for i=1,3 do
				if i~=st then
					table.insert(c,i)
				end
			end
			wor2:setFontName(fonts[c[math.random(1,2)]])
		end
	end	
	local function right(item)
		if isSelected then 
			if item and item.setSelectedState then
				item:setSelectedState(false)
			end
			return 
		end
		isSelected = true	
		--选择正确
		self:play_sound(SND_RIGHT)
		q.judge = true
		self:clac_score(q.type)
			
		self._right_num = self._right_num + 1	
		dt = self:playJudgeAnimation(JUDGE_RIGHT)	
		uikits.delay_call(self._root,function(s)
			self:next_select()
		end,dt)	
	end
	
	local function wrong(item)
		if isSelected then 
			if item and item.setSelectedState then
				item:setSelectedState(false)
			end
			return 
		end
		isSelected = true		
		--选择错误
		self:play_sound(SND_FAIL)
		q.judge = false
		self._fen_mul = 1
		self._error_num = self._error_num + 1				
		dt = self:playJudgeAnimation(JUDGE_WRONG)		
		uikits.delay_call(self._root,function(s)
			--show right
			if right_location then
				if not self._right_animation then
					self._right_animation = ccs.Armature:create("gou")
					self:addChild(self._right_animation,10)
				end
				self._right_animation:setVisible(true)
				local x,y = right_location:getPosition()
				local size = right_location:getContentSize()
				self._right_animation:setPosition(cc.p(x+size.width/2,y-size.height/2))
				self._right_animation:getAnimation():playWithIndex(0)
				uikits.delay_call(self._root,function(s)
					self._right_animation:setVisible(false)
					self:next_select()
				end,3)
			else
				kits.log("right_location = nil")
			end
		end,dt)			
	end
	
	local dui = uikits.child(plane,choose[1])
	local chuo = uikits.child(plane,choose[2])
	dui:setSelectedState(false)
	chuo:setSelectedState(false)
	if correct==1 then
		right_location = dui
	else
		right_location = chuo
	end
	uikits.event(dui,function(sender)
		if correct==1 then
		--if true then
			right(sender)
		else
			wrong(sender)
		end
	end)
	uikits.event(chuo,function(sender)
		if correct==2 then
		--if true then
			right(sender)
		else
			wrong(sender)
		end
	end)
end

function battle:init_current_question( q )
	http.logTable(q,1)
	if self._current_plane then
		self._current_plane:setVisible(false)
	end
	self:showMouse(false)
	self:switchCharacter(1,false)
	self:showHummer(false)
	self._current_plane = uikits.child(self._root,ui.TYPE_BASE..tostring(q.type))
	if self._current_plane then
		self._current_plane:setVisible(true)
	end
	if q.type==1 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chengy'},
			{'da1','da2','da3','da4'},
			q ,"w1")
	elseif q.type==2 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chucu','tu/kuang2/chucu'},
			{'dui','cuo'},
			q ,nil)	
	elseif q.type==3 then
		self:init_problem(self._current_plane,
			{'tu/kuang/renw'},
			{'da1','da2','da3','da4'},
			q,"w1" )		
	elseif q.type==4 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chengy'},
			{'jies1','jies2','jies3'},
			q,"wen")		
	elseif q.type==5 then
		self:type5(self._current_plane,
			"tu/w2",
			"tu/kuang/chengy",
			{"da1/wen","da2/wen","da3/wen"},
			q
		)
	elseif q.type==6 then
		self:type6(self._current_plane,
			"tu/w2",
			{"tu/kuang/chucu","tu/kuang2/chucu"},
			{"dui","cuo"},
			q
		)
	elseif q.type==7 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chengy'},
			{'da1','da2','da3'},
			q,"w1")		
	elseif q.type==8 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chucu','tu/kuang2/chucu'},
			{'dui','cuo'},
			q,nil )		
	elseif q.type==9 then
		self:init_problem(self._current_plane,
			{'tu/kuang/renw'},
			{'da1','da2','da3','da4'},
			q ,"w1")		
	elseif q.type==10 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chengy'},
			{'jies1','jies2','jies3'},
			q ,"wen")	
	elseif q.type==11 then
		self:init_problem(self._current_plane,
			{'zi1/wen','zi2/wen','zi3/wen','zi4/wen'},
			{'da1','da2','da3','da4'},
			q,"w1" )		
	elseif q.type==12 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chucu'},
			{'dui','cuo'},
			q,nil )		
	elseif q.type==13 then
		self:init_problem(self._current_plane,
			{'tu/kuang/chengy','jies1/wen'},
			{'dui','cuo'},
			q,nil )		
	else
		kits.log("ERROR init_current_question q.type= "..tostring(q.type))
	end
	
	--[[
	--4选一
	if q.type==1 then
		self:showMouse(true)
		self:showHummer(true)
		self:select_word(self._word_index)
	--2选一
	elseif q.type==2 then
		self:switchCharacter(math.random(1,3),true)
		self:showHummer(true)
		uikits.child(self._current_plane,ui.TYPE2_NAME):setString(q.name or "-")
		self:initAnswer(q)		
	elseif q.type==3 then
		self:switchCharacter(math.random(1,3),true)
		self:showHummer(true)
		uikits.child(self._current_plane,ui.TYPE3_NAME):setString(q.name or "-")
		self:initAnswer(q)
	elseif q.type==4 then
		self:switchCharacter(math.random(1,3),true)
		self:showHummer(true)
		uikits.child(self._current_plane,ui.TYPE4_NAME):setString(q.name or "-")
		self:initAnswer(q)	
	elseif q.type==5 then
		self:showHummer(true)
		uikits.child(self._current_plane,ui.TYPE5_NAME):setString(q.name or "-")
		local right_location
		for i=1,4 do
			local item = uikits.child(self._current_plane,"t"..i)
			local text = uikits.child(item,"chuchu")
			if q.answer[i] then
				if q.answer[i] == q.correct then
					right_location = uikits.child(self._current_plane,"ts"..i)
				end
				text:setVisible(true)
				text:setString( tostring(q.answer[i]) )
				uikits.event(item,function(sender)
					if self._ideal_pause then return end
					self._ideal_pause = true
					local dt = 0
					if q.answer[i] == q.correct then
						self:play_sound(SND_RIGHT)
						self._current_word.judge = true
						self:clac_score(self._current_word.type)
						
						self._right_num = self._right_num + 1
						kits.log("INFO "..tostring(self._current_word.answer[i]).."=="..tostring(self._current_word.correct))
						kits.log("INFO right_num = "..tostring(self._right_num))		
						dt = self:playJudgeAnimation(JUDGE_RIGHT)	
						uikits.delay_call(self._root,function(s)
							self:next_select()
						end,dt)	
					else
						self:play_sound(SND_FAIL)
						self._current_word.judge = false
						self._fen_mul = 1
						self._error_num = self._error_num + 1				
						dt = self:playJudgeAnimation(JUDGE_WRONG)	
						uikits.delay_call(self._root,function(s)
							--show right
							if right_location then
								if not self._right_animation then
									self._right_animation = ccs.Armature:create("gou")
									self:addChild(self._right_animation,10)
								end
								self._right_animation:setVisible(true)
								local x,y = right_location:getPosition()
								self._right_animation:setPosition(cc.p(x,y+100))
								self._right_animation:getAnimation():playWithIndex(0)
								uikits.delay_call(self._root,function(s)
									self._right_animation:setVisible(false)
									self:next_select()
								end,3)
							end
						end,dt)							
					end				
				end)
			else
				item:setVisible(false)
			end
		end
	elseif q.type==6 then
		self:switchCharacter(math.random(1,3),true)
		self:showHummer(true)
		uikits.child(self._current_plane,ui.TYPE6_NAME):setString(q.name or "-")
		self:initAnswer(q)	
	elseif q.type==7 then
		uikits.child(self._current_plane,ui.TYPE7_EXPLANATION):setString(q.name or "-")
		local input = uikits.child(self._current_plane,ui.TYPE7_INPUT)
		input:setText("")
		local baidu = uikits.child(self._current_plane,ui.TYPE7_MK_BUT)
		if kTargetWindows ~= CCApplication:getInstance():getTargetPlatform() then
			uikits.event(baidu,function(sender)
				local len = 0
				if self._current_word and self._current_word.correct then
					len = string.len(self._current_word.correct)
				end
				kits.log("LEN = "..len)
				if cc_showBaiduVoice then
					cc_showBaiduVoice(function (text)
						if len>0 then
							input:setText(string.sub(text,0,len))
						else
							input:setText(text)
						end
					end)
				end
			end)
		else
			baidu:setVisible(false)
		end
		local ok = uikits.child(self._current_plane,ui.TYPE7_OK)
		uikits.event(ok,function(sender)
			if self._ideal_pause then return end
			self._current_word.my_answer = input:getStringValue()
			local dt = 0
			self._ideal_pause = true
			if self._current_word.my_answer == self._current_word.correct then
				self:play_sound(SND_RIGHT)
				self._current_word.judge = true
				self:clac_score(self._current_word.type)
				
				self._right_num = self._right_num + 1				
				dt = self:playJudgeAnimation(JUDGE_RIGHT)
			else
				self:play_sound(SND_FAIL)
				self._current_word.judge = false
				self._fen_mul = 1
				self._error_num = self._error_num + 1				
				dt = self:playJudgeAnimation(JUDGE_WRONG)
			end
			uikits.delay_call(self._root,function(s)
				if self._current_word.judge then
					self:next_select()
				else
					--show right
					input:setText(self._current_word.correct or "-")
					uikits.delay_call(self._root,function(s)
						self:next_select()
					end,3)
				end
			end,dt)
		end)
	else
		kits.log("ERROR init_current_question q.type= "..tostring(q.type))
	end
	--]]
end

function battle:playJudgeAnimation(idx)
	if not self._judge_animation then
		self._judge_animation = ccs.Armature:create("success")
		self._judge_animation:setAnchorPoint(0.5,0.5)
		self._judge_animation:setPosition(cc.p(self._ss.width/2,self._ss.height/2))
		self:addChild(self._judge_animation,100)
	end
	self._judge_animation:setVisible(true)
	if idx == JUDGE_RIGHT then
		self._judge_animation:getAnimation():playWithIndex(0)
		self:play_sound(SND_RIGHT)
	elseif idx == JUDGE_WRONG then
		self._judge_animation:getAnimation():playWithIndex(1)	
		self:play_sound(SND_FAIL)
	end
	if pidx then
		uikits.delay(self._root,function(dt)
			self._judge_animation:setVisible(false)
		end,1.2)
	end
	return 1.5
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

	for i=1,13 do
		local item = uikits.child(self._root,ui.TYPE_BASE..tostring(i))
		if item then
			item:setVisible(false)
		end
	end
	
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

local function open_console()
	local console = require "console"
	if console.isopen() then
		cc.Director:getInstance():popScene()
	else
		local scene = console.create()
		if scene then
			cc.Director:getInstance():pushScene( scene )
		end
	end	
end
	
function battle:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
		self._screen = 2
	else
		self._ss = cc.size(1440,1080)
		self._screen = 1
	end

	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		self._scheduler = self:getScheduler()
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,function(sender)
			if self._arg.type==1 or self._arg.type==4 then
				local text
				if self._arg.type==1 then
					text = "你‘确定’要退出闯关吗？"
				else
					text = "你‘确定’要退出错题任务吗？"
				end
				if not self._ismessagebox then
					self._ismessagebox = true
					http.messagebox(self._root,http.DIY_MSG,function(e)
						self._ismessagebox = false
						if e==http.OK then
							self._game_over_flag = true
							uikits.popScene()
						else
							open_console()
						end
					end,text,"确定")			
				end
			else
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e==http.OK then
						self:upload_scroe2(self._arg.level,math.floor(self._fen),self._game_time,self._right_num,-1)					
					end
				end,"退出比赛将浪费一次比赛机会\n你‘确定’要退出比赛吗？","确定")						
			end
		end)
		self._topbar = uikits.child(self._root,ui.TOPBAR)
		self._time_bar = uikits.child(self._root,ui.PROGRESS)
		self._pnum_label = uikits.child(self._root,ui.NUMBER)
		self._fen_label = uikits.child(self._root,ui.SCORE)
		self._fen_label:setString('0')
		self._cn_label = {}
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI1))
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI2))
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI3))
		table.insert(self._cn_label,uikits.child(self._root,ui.ZI4))
		--self._timeover_ui = uikits.child(self._root,ui.TIMEOVER_WINDOW)
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
	if self._game_over_flag then
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_1)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_2)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_3)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_JUDGE)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_BAOYA)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_BANGZI)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_TOUMU)
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(ui.ANIMATION_RIGHT)
		if self._schedulerIDS then
			for i,v in pairs(self._schedulerIDS) do
				if v then
					self._scheduler:unscheduleScriptEntry(v)
				end
			end
		end
		self._schedulerIDS = nil
	end
end

return battle