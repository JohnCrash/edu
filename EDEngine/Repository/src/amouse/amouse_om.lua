require "AudioEngine" 
lxp = require "lom"
kits = require "kits"
json = require "json"
curl = require 'curl'
uikits = require "uikits"
login = require "login"

local AMouseScene = class("AMouseScene")
AMouseScene.__index = AMouseScene
AMouseScene._uiLayer= nil
AMouseScene._widget = nil
AMouseScene._sceneTitle = nil

--本地支援缓冲区
local local_dir = cc.FileUtils:getInstance():getWritablePath()..'res/'
local SND_UI_CLICK = 0
local SND_CLICK = 1
local SND_MISS = 2
local SND_HIT = 3
local SND_RIGHT = 4
local SND_FAIL = 5
local SND_NEXT_PROM = 6
local SND_PASS = 7
local SND_GOLD = 8

local function screenCenterPt()
	local s = uikits.screenSize()
	return cc.p(1024/2,768/2)
end

--kits.log( 'do convert' )
--require "src/amouse/resize_json"
--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_1/jie_mian_1.json')
--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_2/jie_mian_2.json')
--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_3/jie_mian_3.json')
--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_4/jie_mian_4.json')
--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_5/jie_mian_5.json')
--resize_json('D:/1Source/Edu/EDEngine/proj.win32/Debug.win32/res/amouse/jie_mian_6/jie_mian_6.json')

local cookie1 = 'sc1=B964C5AB31B11EBA73E96DEC7FE9A793CDAD3028ak99MgbuBYOcjHsDJkE16kV%2fYgv0Yxi7sUzUhsLI5lYpE0jPwGtmazO%2b8luQqkfvSLX2wN0fxGPd03oZpHJbaewnwrbp3A%3d%3d'
local cookie2 = 'sc1=B4623839ECF0FA103672BA497C781F52454EA887ak99MgfmBYOcjHsDJkE16kV%2fYgv0Yxi7sUzUh8KTvFYoQUjPwGtmazO%2b8luQqkfvSLX2wN0fxGLdiCAZpSBbaewnwrbp3A%3d%3d'
local cookie = login.cookie()
--[[
local s_all_rank_url = 'http://192.168.2.120/ourgame/api/rank/top.ashx?app_id=20001&zone_id=141442&period=0'
local s_week_rank_url = 'http://192.168.2.120/ourgame/api/rank/top.ashx?app_id=20001&zone_id=141442&period=0'
local s_upload_url = 'http://192.168.2.120/ourgame/api/score/submit.ashx'
--]]
local s_all_rank_url = 'http://app.lejiaolexue.com/ourgame/api/rank/top.ashx?app_id=20001&zone_id=141442&period=0'
local s_week_rank_url = 'http://app.lejiaolexue.com/ourgame/api/rank/top.ashx?app_id=20001&zone_id=141442&period=0'
local s_upload_url = 'http://app.lejiaolexue.com/ourgame/api/score/submit.ashx'

local function test_server()
	kits.log("server test http_get")
	kits.log("-------------------------------------")
	kits.log( kits.http_get(s_all_rank_url,cookie,1) )
	
	kits.log("server test http_post")
	kits.log("-------------------------------------")
	local t = 
	{
		app_id = 20001,
		game_id = 'amouse',
		stage_id = 1,
		rid = 2,
		score = 2293243,
		chk = 'swer1234234234sdf'
	}
	
	kits.log('OPT_POSTFIELDS:'..kits.encode_url(t))
	kits.log("-------------------------------------")
	local reslut = kits.http_post(s_upload_url,kits.encode_url(t),cookie,1) 
	if reslut then
		kits.log( tostring( reslut ) )
	else
		kits.log(" kits.http_post return nil")
	end
end

--test_server()
--上传玩家积分
function AMouseScene:upload_rank( stage,scor )
	local text = kits.encode_url{ app_id = 20001,game_id='amouse', stage_id = stage,score = scor,rid = 3,chk = '21342342424323421345235' }
	local reslut = kits.http_post( s_upload_url,text,cookie,10 )
	if reslut and type(reslut) == 'string' and string.sub(reslut,1,1) == '{' then
		kits.log('upload : '..tostring(reslut) )
		local ret = json.decode(reslut)
	else
		kits.log('upload error:')
		kits.log( reslut )
	end
end

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

function AMouseScene:stop_music()
	if AudioEngine.isMusicPlaying () then
		AudioEngine.stopMusic()
	end
end

function AMouseScene:play_music()
	local name
	
	if AudioEngine.isMusicPlaying () then
		return
	end
	local idx = math.random(1,3)
	if self._music_idx then
		for i=1,10 do
			if idx ~= self._music_idx then
				self._music_idx = idx
				break
			end
			idx = math.random(1,3)
		end
	else
		self._music_idx = idx
	end
	if self._player_data and self._player_data.music then
		if idx <=3 and idx >= 1 then
			name = 'amouse/snd/beijing'..idx..'.mp3'
		else
			return
		end
		
		AudioEngine.playMusic( name,true )
	end
end

--修改游戏声效
function AMouseScene:play_sound( idx )
	local name
	
	if self._player_data and self._player_data.sound then
		if idx == SND_UI_CLICK then
			name = 'amouse/snd/qiaoda.mp3'
		elseif idx == SND_CLICK then
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
			name = 'amouse/snd/guoguan.MP3'
		elseif idx == SND_PASS then
			name = 'amouse/snd/complete.mp3'
		elseif idx == SND_GOLD then
			name = 'amouse/snd/gold.mp3'
		else
			return
		end
		kits.log( "Play sound: "..name )
		AudioEngine.playEffect(name)
	end
end

--返回主菜单					
local function backMain()
	--local scene = cc.Scene:create()
    --scene:addChild(CreateTestMenu())

    --cc.Director:getInstance():replaceScene(scene)
	uikits.popScene()
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

--设置剩余的题数
function AMouseScene:set_last_proms( N )
	if self._pnum_label then
		self._pnum_label:setString( tostring(N) )
	end
end

--初始化背景与基本界面
function AMouseScene:init_bg_and_ui()
	local ratio = 1
	if self._screen == 1 then
		ratio = 1
	else
		ratio = 1.1
	end
	--背景
	self._bg = cc.Sprite:create("amouse/mainscene.png")
	self._bg:setPosition(screenCenterPt())
	self:addChild(self._bg,1)
	--题目背景
	self._sprite_bg = cc.Sprite:create("amouse/NewUI01.png")
	self._sprite_bg:setAnchorPoint(cc.p(0.5,0.5))
	self._sprite_bg:setPosition(cc.p(self._ss.width/2,self._ss.height*4.6/7*ratio))
	self._sprite_bg:setScaleY(0.8)
	self._sprite_bg:setScaleX(0.8)
	self:addChild(self._sprite_bg,2)

	--时间条
	local widget = ccs.GUIReader:getInstance():widgetFromJsonFile("amouse/jie_mian_3/jie_mian_3.json")
	if widget then
		self:addChild(widget,100)
		widget:setScaleX(0.5)
		widget:setScaleY(0.5)
		widget:setTouchEnabled(false)
		local root = self:getChildByTag(38)
		self._time_widget = root
		self._time_bar = root:getChildByTag(42) --time_bar
		--root:addChild(self._worm)
--		self._worm = root:getChildByTag(44) --小虫
--		self._worm:setAnchorPoint(cc.p(0.8,0.5))
		--题目数文本框
		self._pnum_label = root:getChildByTag(40)

		if self._pnum_label then
			--题数
			self._pnum_label2 = cc.LabelBMFont:create("30", "fonts/font-issue1343.fnt")
			self._pnum_label:addChild(self._pnum_label2,102)
			self._pnum_label2:setScaleX(2)
			self._pnum_label2:setScaleY(2)
			local size = self._pnum_label:getContentSize()
			self._pnum_label2:setAnchorPoint( cc.p(0.5,0.5) )
			self._pnum_label2:setPosition( cc.p(size.width*2/3,size.height/2) )
			self._pnum_label = self._pnum_label2
		end
		self._fen_label = root:getChildByTag(294)
		--积分
		if self._fen_label then
			self._fen_label2 = cc.LabelBMFont:create("0", "fonts/font-issue1343.fnt")
			self._fen_label:addChild(self._fen_label2,103)
			self._fen_label2:setScaleX(2)
			self._fen_label2:setScaleY(2)
			local size = self._fen_label:getContentSize()
			self._fen_label2:setAnchorPoint( cc.p(0.5,0.5) )
			self._fen_label2:setPosition( cc.p(size.width*2/3,size.height/2) )
			self._fen_label = self._fen_label2
		end
	end
	
	--题目文字
	self._cn_label = cc.LabelTTF:create("", "Marker Felt", 60)
	self._cn_label:setColor(cc.c3b(255,0,0))
	self._cn_label:setPosition(cc.p(self._ss.width/2,self._ss.height*2/3*ratio))
	self:addChild(self._cn_label,104)
	self._nn_label = cc.LabelTTF:create("", "Marker Felt", 30)
	self._nn_label:setColor(cc.c3b(255,0,0))
	self._nn_label:setPosition(cc.p(self._ss.width/10,self._ss.height*18/20))
	self:addChild(self._nn_label,105)
end

--取得积分1-100
function AMouseScene:getIntegration()
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

function AMouseScene:game_setting_Dialog( where )
	kits.log("game setting dialog")
	self:close_Dialog()
	self._where = where
	
	self._uiLayer = cc.Layer:create()
	self:addChild(self._uiLayer,1300)
	self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("amouse/jie_mian_6/jie_mian_6.json")
	self._uiLayer:addChild(self._widget)
	--self._widget:setScaleX(0.5)
	--self._widget:setScaleY(0.5)
		
	local function return_up( sender,eventType )
		if eventType == ccui.TouchEventType.ended then
			self:close_Dialog()
			self:save_player_data()
			where( self )
			self:play_sound( SND_UI_CLICK )
		end
	end
	local function music_func( sender,eventType )
		if eventType == ccui.TouchEventType.ended then
			self._player_data.music = not sender:getSelectedState()
			if self._player_data.music then
				kits.log("music on")
				self:play_music()
			else
				kits.log("music off")
				self:stop_music()
			end
			self:play_sound( SND_UI_CLICK )			
		end
	end
	local function sound_func( sender,eventType )
		if eventType == ccui.TouchEventType.ended then
			self._player_data.sound = not sender:getSelectedState()
			if self._player_data.sound then
				kits.log("sound on")
			else
				kits.log("sound off")
			end
			self:play_sound( SND_UI_CLICK )						
		end
	end
	
	local root = self._uiLayer:getChildByTag(3)
	--返回 button
	root:getChildByTag(8):addTouchEventListener(return_up) --返回
	local music = root:getChildByTag(98)
	local sound = root:getChildByTag(96)
	music:addTouchEventListener(music_func) --music
	sound:addTouchEventListener(sound_func) --sound	
	if self._player_data then
		if self._player_data.music then
			music:setSelectedState(true)
		else
			music:setSelectedState(false)
		end
		if self._player_data.sound then
			sound:setSelectedState(true)
		else
			sound:setSelectedState(false)
		end		
	end
end

--访问服务器下载top rank并且设置
function AMouseScene:set_top_list( url )
	local result = kits.http_get( url,cookie,10 ) --time out 1s
	if result and type(result)== 'string' and string.sub(result,1,1) == '{' then
		local tops = json.decode(result)
		local i = 1
		kits.log( result )
		if tops and tops.users and type(tops.users)=='table' then
			for k,v in pairs(tops.users) do
				kits.log( "table:"..k )
				if type(v)=='table' then
					for n,s in pairs(v) do
						kits.log( "	"..n..":"..s )
						if n == 'uname' and type(s)=='string' then
							self._top_lists[i]:getChildByName('Label_name'):setString(s)
						elseif n == 'score' and type(s)=='number' then
							self._top_lists[i]:getChildByName('Label_fen'):setString(tostring(s))
						elseif n == 'school' and type(s)=='string' then
							self._top_lists[i]:getChildByName('Label_school'):setString(s)
						end
					end
					--v = { uname='user name',user_id=1220423,score=1223}
				end
				i = i + 1
				if i > 5 then
					break
				end
			end
		else
			kits.log("players rank table error!")
		end
	else
		kits.log("get players rank error!")
		if result then 
			kits.log(string.sub(result,1,128)) 
		end
	end
end

--清空积分表
function AMouseScene:clean_top_list()
	if self._top_lists and type(self._top_lists) == 'table' then
		for i = 1,#self._top_lists do
			self._top_lists[i]:getChildByName('Label_fen'):setString(' ')
			self._top_lists[i]:getChildByName('Label_school'):setString(' ')
			self._top_lists[i]:getChildByName('Label_name'):setString(' ')
		end
	end
end

function AMouseScene:game_top10_Dialog( where )
	kits.log("game top10 dialog")
	self:close_Dialog()
	self._where = where

	self._uiLayer = cc.Layer:create()
	self:addChild(self._uiLayer,1300)
	self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("amouse/jie_mian_5/jie_mian_5.json")
	self._uiLayer:addChild(self._widget)
	--self._widget:setScaleX(0.5)
	--self._widget:setScaleY(0.5)
	local current_checkbox = nil
	--返回
	local function return_up( sender,eventType )
		if eventType == ccui.TouchEventType.ended then
			self:close_Dialog()
			where( self )
		elseif eventType == ccui.TouchEventType.began then
			self:play_sound( SND_UI_CLICK )
			self:clean_top_list()
			if current_checkbox then
				current_checkbox:setSelectedState(false)
				current_checkbox = sender
			end
		end
	end
	--周排行
	local function week_top( sender,eventType )
		if eventType == ccui.TouchEventType.ended then
			kits.log("week top")
			self:clean_top_list()
			self:set_top_list(s_week_rank_url)
		elseif eventType == ccui.TouchEventType.began then
			self:play_sound( SND_UI_CLICK )
			self:clean_top_list()
			if current_checkbox then
				current_checkbox:setSelectedState(false)
				current_checkbox = sender
			end			
		end
	end
	--总排行
	local function all_top( sender,eventType )
		if eventType == ccui.TouchEventType.ended then
			kits.log("total top")
			self:clean_top_list()
			self:set_top_list(s_all_rank_url)
		elseif eventType == ccui.TouchEventType.began then
			self:play_sound( SND_UI_CLICK )
			self:clean_top_list()
			if current_checkbox then
				current_checkbox:setSelectedState(false)
				current_checkbox = sender
			end			
		end
	end	
	local root = self._uiLayer:getChildByTag(3)
	--返回 button
	root:getChildByTag(8):addTouchEventListener(return_up) --返回
	root:getChildByTag(98):addTouchEventListener(week_top) --本周
	root:getChildByTag(96):addTouchEventListener(all_top) --历史最佳
	root:getChildByTag(97):addTouchEventListener(week_top) --历史最佳

	self._top_lists = {}
	--初始化积分表
	for i = 1,5 do
		self._top_lists[i] = root:getChildByName('Label_t'..i)
		self._top_lists[i]:setString( i )
	end
	self:clean_top_list()
	--默认进入的时候设置本周
	self:set_top_list(s_week_rank_url)
	--当前checkbox
	current_checkbox = root:getChildByTag(98)	
	current_checkbox:setSelectedState(true)
end

function AMouseScene:close_Dialog()
	if self._uiLayer then
		local layer = self._uiLayer
		layer:setVisible(false)
		uikits.delay_call(self,function() 
			layer:removeFromParent()
			layer = nil end,0)
		--self._uiLayer:removeFromParent()
		self._widget = nil
		self._uiLayer = nil
		self._where = nil
	end
	if self._uiScene then
		uikits.popScene()
		self._uiScene = nil
		self._widget = nil
		self._where = nil
	end
end

--初始化玩家数据
function AMouseScene:init_player_data()
	self:load_player_data()
	self._player_data = self._player_data or { sound = true,music = true,stage = 1,scroce=0 }
end

function AMouseScene:load_player_data()
	local s = kits.read_local_file('amouse_stage.json')
	if s then
		self._player_data = json.decode( s )
	end
end

function AMouseScene:save_player_data()
	if self._player_data then
		local s = json.encode( self._player_data )
		if s then
			kits.write_local_file('amouse_stage.json',s)
		else
			kits.log("save_player_data error!")
		end
	end
end

function AMouseScene:game_start_Dialog()
	kits.log("game start dialog")
	self:close_Dialog()
	if self._uiLayer then return end
	
	self._hummer:setVisible(false)
	self._uiLayer = cc.Layer:create()
	self:addChild(self._uiLayer,1200)
	self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("amouse/jie_mian_4/jie_mian_4.json")
	self._uiLayer:addChild(self._widget)
--	self._widget:setScaleX(0.5)
--	self._widget:setScaleY(0.5)
	--self._widget:setPosition(cc.p(0,-self._ss.height/10))
	local function setting(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			kits.log("game setting...")
			self:game_setting_Dialog( self.game_start_Dialog )
			self:play_sound( SND_UI_CLICK )						
		end
	end
	local function top10(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			kits.log("game top10...")
			self:game_top10_Dialog( self.game_start_Dialog )
			self:play_sound( SND_UI_CLICK )						
		end
	end
	local function new_game()
			self:close_Dialog()
			self:startStage()	
	end
	local function stages(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			kits.log( "game new game...")
			self._stage = tonumber(string.match(sender:getName(),'0+%d0*'))
			kits.log( "game level "..self._stage )
			self:delay_call( new_game,0,0.1 )
			self:play_sound( SND_UI_CLICK )						
		end
	end
	local function exiting(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			self:close_Dialog()
			self:stop_music()
			backMain()		
			self:play_sound( SND_UI_CLICK )						
		end
	end
	
	local root = self._uiLayer:getChildByTag(45)
	--排行button
	root:getChildByTag(70):addTouchEventListener(top10) --排行
	--设置button
	root:getChildByTag(74):addTouchEventListener(setting) --设置
	--退出
	root:getChildByTag(186):addTouchEventListener(exiting) --退出
	--stage1-10
	for i = 1,10 do
		local cb = root:getChildByName('CheckBox_g00'..i)

		if i <= self._player_data.stage then
			--亮的
			cb:setSelectedState(true)
			cb:setBright(true)
			cb:addTouchEventListener(stages) --关卡事件
		else
			--灰的
			cb:setBright(false)
		end
	end
	--播放背景音乐
	if not AudioEngine.isMusicPlaying () then
		self:play_music()
	end
end

--一关结束
function AMouseScene:game_end_Dialog()
	--if self._uiLayer then return end
	--60分过关
	local fen100 = self:getIntegration()
	local b = fen100 > 60
	kits.log("分数:"..self:getIntegration())
	local function exitGame(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			self:close_Dialog()
			self:stop_music()
			backMain()
			self:play_sound( SND_UI_CLICK )						
		end
	end
	local function nextStage(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			self:close_Dialog()
			--下一关
			self._stage = self._stage + 1
			if self._stage > 10 then
				self:game_start_Dialog() --完全打穿
			else
				self:startStage()
			end
			self:play_sound( SND_UI_CLICK )						
		end
	end
	local function tryaginStage(sender,eventType)
		if eventType == ccui.TouchEventType.ended then
			self:close_Dialog()
			self:startStage()
			self:play_sound( SND_UI_CLICK )
		end
	end
	--self._uiLayer = cc.Layer:create()
	--self:addChild(self._uiLayer)
	self._uiScene = cc.Scene:create()
	uikits.pushScene(self._uiScene)
	if b then
		--播放成功过关的声音
		self:play_sound(SND_NEXT_PROM)
			
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("amouse/jie_mian_1/jie_mian_1.json")
		self._widget:setScaleX(0.5)
		self._widget:setScaleY(0.5)
		if self._player_data.stage < self._stage + 1 then
			self._player_data.stage = self._stage + 1
			--本地保存
			self:save_player_data()
		end
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("amouse/jie_mian_2/jie_mian_2.json")
	end
	--self._uiLayer:addChild(self._widget)
	self._uiScene:addChild(self._widget)
	--设置本地积分
	if b then
		local root = self._uiScene:getChildByTag(3)
		local parent = root:getChildByName('ImageView_38')
		parent:getChildByTag(207):setString(tostring(self._xing_time)) --通关用时
		parent:getChildByTag(210):setString(tostring(math.floor(self:getIntegration()))..'%') --正确数
		parent:getChildByTag(211):setString(tostring(self._fen)) --成绩
		parent:getChildByTag(212):setString(tostring(self._fen)) --历史最好成绩	
	end
	--self._widget:setPosition(cc.p(0,-self._ss.height/10))	
	if b then
		local root = self._uiScene:getChildByTag(3)
		root:getChildByTag(7):getChildByTag(8):addTouchEventListener(exitGame) --exit
		root:getChildByTag(11):getChildByTag(12):addTouchEventListener(nextStage) --next	
	else
		local root = self._uiScene:getChildByTag(3)
		root:getChildByTag(7):getChildByTag(8):addTouchEventListener(exitGame) --exit
		root:getChildByTag(11):getChildByTag(12):addTouchEventListener(tryaginStage) --next
	end
	
	if b then
		--关闭通关星星
		if self._xing then
			self._xing:setVisible(false)
		end
		--提交到网络
		self:upload_rank( self._player_data.stage,self._fen )
	end
end

function AMouseScene:hummer_home()
	self._hummer:setPosition( cc.p(self._ss.width/5,self._ss.height*4.6/7) )
end

--初始化角色
function AMouseScene:init_role()
	local arm = ccs.ArmatureDataManager:getInstance()
	if arm then
		arm:removeArmatureFileInfo("amouse/NewAnimation.ExportJson")
		arm:addArmatureFileInfo("amouse/NewAnimation.ExportJson")
		arm:removeArmatureFileInfo("amouse/chong_zi/chong_zi.ExportJson")
		arm:addArmatureFileInfo("amouse/chong_zi/chong_zi.ExportJson")
		arm:removeArmatureFileInfo("amouse/xing/xing.ExportJson")
		arm:addArmatureFileInfo("amouse/xing/xing.ExportJson")
	else
		kits.log("ERROR init_role ccs.ArmatureDataManager:getInstance() return nil")
	end
	--时间小虫
	self._worm = ccs.Armature:create("chong_zi")
	self._worm:getAnimation():playWithIndex(0)
	--过关星星
	self._xing = ccs.Armature:create("xing")
	self._xing:getAnimation():playWithIndex(0)
	self:addChild(self._xing,1000)
	self._xing:setVisible(false)
	--将星星放在积分下面
	if self._fen_label then
		local x,y = self._fen_label:getPosition()
		local s = self._fen_label:getContentSize()
		local p = self._fen_label:getParent():convertToWorldSpace(cc.p(x,y))
		p.y = p.y - s.height
		self._xing:setAnchorPoint(cc.p(1,1))
		self._xing:setPosition(p)
	end
	
	if self._time_bar then
		self._time_widget:addChild(self._worm,110)
		local worm = self._time_widget:getChildByTag(359) --小虫
		local x,y = worm:getPosition()
		--隐藏静态虫子
		worm:setEnabled(false)
		worm:setVisible(false)
		self._worm:setAnchorPoint(cc.p(0.8,0.5))
		self._worm:setPosition(cc.p(x,y))
	end
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

--延迟调用
function AMouseScene:delay_call(func,param,delay)
	local schedulerID
	if func == nil then
		kits.log( "func = nil?")
		return
	end
	if not schedulerID then
		local function delay_call_func()
			self._scheduler:unscheduleScriptEntry(schedulerID)
			schedulerID = nil		
			func(self,param)
		end
		schedulerID = self._scheduler:scheduleScriptFunc(delay_call_func,delay,false)
	end	
end

--正确
function AMouseScene:show_right(i)
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

--开始下一个词
function AMouseScene:reload_scene(b)
	for i=1,4 do
		self._amouse[i]:getAnimation():playWithIndex(0)
	end
	self:next_select()
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

--初始化事件
function AMouseScene:init_event()
	--多点触摸
	local function onTouchBegan(touches,event)
		local p = touches[1]:getLocation()
		self._hummer:getAnimation():playWithIndex(1)
		self._hummer:setPosition(p)
		
		self:play_sound(SND_CLICK)
		--游戏已经暂停
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
	--触摸
	self._listener = cc.EventListenerTouchAllAtOnce:create()
	self._listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCHES_BEGAN )
	self._listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCHES_MOVED )
	--鼠标
	self._listener_mouse = cc.EventListenerMouse:create(1)
	self._listener_mouse:registerScriptHandler(onMouseMoved,cc.Handler.EVENT_MOUSE_MOVE )
	--键盘,Android返回
	self._listener_keyboard = cc.EventListenerKeyboard:create()
	self._listener_keyboard:registerScriptHandler(onKeyRelease,cc.Handler.EVENT_KEYBOARD_RELEASED )
	--Android返回键由CreateBackMenuItem完成了
	local eventDispatcher = self:getEventDispatcher()
	
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener, self)
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener_mouse, self)
	eventDispatcher:addEventListenerWithSceneGraphPriority(self._listener_keyboard, self)	
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
	self._yes = yp
	if self._yes_num > 0 and #p == 4 then
		for i,v in ipairs(self._rand_idx) do
			self._choose_text[i]:setString(p[v])
		end
	else
		kits.log("Error word")
	end
end

--显示正确答案n=1 or n=2
function AMouseScene:show_right_word( n,b )
	local text = self._cn_label:getString()
	if text and n <= self._yes_num then
		if self._yes_num > 1 then
			text = string.gsub(text,'　',self._yes[n],1)
		else
			text = string.gsub(text,'　',self._yes[n])
		end
		self._cn_label:setString(text)
	end
	--答对设置积分增加
	if b then
		self._fen_adding = self._fen_adding + 100 + 10*self._fen_mul
		self._fen_mul = self._fen_mul + 1
		--提示已经过关
		if self._pass or self:getIntegration() > 60 then
			self:play_sound(SND_PASS)
			self._xing:setVisible(true)
			self._xing_time = self._game_time
			self._xing:getAnimation():playWithIndex(0)
			self._pass = true
		end
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
function AMouseScene:next_select()
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
		
--初始化游戏数据,i代表关卡,1-10
function AMouseScene:init_data( i )
	i = i or 1
	local filename = 'res/amouse/data/'..tostring(i)..'.xml'
	filename = cc.FileUtils:getInstance():fullPathForFilename(filename)
	local promble_xml = kits.read_file(filename)
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
		kits.log("Can\'t open resource file : res/amouse/data/.xml")
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

--小虫子
function AMouseScene:update_time_bar()
	if self._time_bar and self._time_limit and self._game_time 
		and self._time_limit >= 1 and  self._game_time<=self._time_limit then
		--设置进度条
		self._time_bar:setPercent( 100*self._game_time/self._time_limit)
		--设置小虫
		local x,y = self._worm:getPosition()
		local box = self._time_bar:getBoundingBox()
		x = box.x + box.width*self._game_time/self._time_limit
		self._worm:setPosition(cc.p(x,y))
	end
end

--积分增加timer
function AMouseScene:init_adding_timer()
	if self._schedulerEntry2 then
		self._scheduler:unscheduleScriptEntry(self._schedulerEntry2)
		self._schedulerEntry2 = nil
	end
	local t = 0
	local old_time = 0
	local function timer_update(dt)
		t = t + dt
		if self._fen_label then
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
		end
	end
	self._schedulerEntry2 = self._scheduler:scheduleScriptFunc(timer_update,0.05,false) --20 FPS
end
--周期
function AMouseScene:init_timer()
	if self._schedulerEntry then
		self._scheduler:unscheduleScriptEntry(self._schedulerEntry)
		self._schedulerEntry = nil
	end
	self._game_time = 0
	self:update_time_bar()
	local function timer_update(time)
		if self._time_bar then
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
		elseif self._schedulerEntry then
			self._scheduler:unscheduleScriptEntry(self._schedulerEntry)
			self._schedulerEntry = nil
		end
	end
	self._schedulerEntry = self._scheduler:scheduleScriptFunc(timer_update,1.0,false)
end

--正确彩蛋1
function AMouseScene:ColourEgg()
	local emitter = cc.ParticleSystemQuad:create("Particles/lightDot.plist")
	self:addChild(emitter)
	
	emitter:setPosition(self._ss.width / 2, self._ss.height / 2)
	self._emitter = emitter
end

--正确彩蛋1
function AMouseScene:ColourEgg2()
end

--粒子系统(礼花)
function AMouseScene:LavaFlow( N )
	local function flower()
		self:setColor(cc.c3b(0, 0, 0))
		local plist = 'Particles/ExplodingRing.plist'
		local emitter = {}
		for i = 1,N do
			emitter[i] = cc.ParticleSystemQuad:create(plist)
			emitter[i]:setPosition(cc.p(self._ss.width*(i+1)/ (N+2), self._ss.height / 1.25))
			emitter[i]:setStartColor(cc.c4f(0,0,0,1))
		end
		
		local batch = cc.ParticleBatchNode:createWithTexture(emitter[1]:getTexture())

		for i = 1,N do
			batch:addChild(emitter[i], 0)
		end

		self:addChild(batch, 10)
	end
	--先起来然后开花
	local amgr = cc.Director:getInstance():getActionManager()
	for i = 1,N do
		local emitter = cc.ParticleSystemQuad:create("Particles/lightDot.plist")
		local x = self._ss.width*(i+1)/ (N+2) - self._ss.width/2 --(N+1)/ (2*(N+2))
		local action = cc.MoveBy:create(0.8,cc.p(x,self._ss.height / 1.25))
		amgr:addAction( action,emitter,true)
		self:addChild(emitter)
		emitter:setPosition(self._ss.width / 2, 0)
	end
	self:delay_call( flower,0,0.9 )
end

--粒子系统(飘动)
function AMouseScene:Snow( b )
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

		emitter:setPosition(self._ss.width / 2, self._ss.height)
		
		self._emitter = emitter
		self:addChild(self._emitter, 10)
	elseif self._emitter then
		self._emitter:removeFromParent()
		self._emitter = nil
	end
end

--游戏结束
function AMouseScene:game_over()
	--self:Snow( false )
	self:game_end_Dialog()
end

function AMouseScene:startStage()
	self._pause = false
	self._hummer:setVisible(true)
	--初始化游戏数据
	self:init_data(self._stage)
	--开雪花
	kits.log("New game...")
	--新的音乐
	self:play_music()
	--self:LavaFlow(3)
	--self:Snow( true )
	--self:ColourEgg()
	self:init_timer()
	self:init_adding_timer()
	--载入第一词
	self:next_select()
end

function AMouseScene:init()
	--游戏基本变量初始化
	if not self._ss then
		self._ss = cc.Director:getInstance():getVisibleSize()
		local radio = self._ss.width/self._ss.height
		kits.log("radio = "..radio )
		if radio <= 15/9 and radio >= 4/3 then
			self._screen = 1
			kits.log("4/3" )
		elseif radio >= 15/9 then
			self._screen = 2
			kits.log("16/9" )
		else
			self._screen = 1
			kits.log("4/3" )
		end
		if uikits.get_factor() == uikits.FACTOR_9_16 then
			uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
		else
			uikits.initDR{width=1024,height=768,mode=cc.ResolutionPolicy.NO_BORDER}
		end	
		--self._scheduler = cc.Director:getInstance():getScheduler()
		self._scheduler = self:getScheduler()
		--初始化玩家数据
		self:init_player_data()
		
		--初始化背景和ui
		self:init_bg_and_ui()
		self:init_role()
		
		--初始化事件
		self:init_event()
		--启动游戏
		self:game_start_Dialog()
	end
end

--释放
function AMouseScene:release()
	if not self._uiScene and not self._uiLayer  then
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("amouse/NewAnimation.ExportJson")
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("amouse/chong_zi/chong_zi.ExportJson")
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo("amouse/xing/xing.ExportJson")
		self:stop_music()
	end
end

function AMouseScene.create()
	local scene = cc.Scene:create()
	local layer = AMouseScene.extend(cc.Layer:create())
	
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

function AMouseMain()
	cclog("A mouse hello!")
	local scene = AMouseScene.create()
	--scene:addChild(CreateBackMenuItem())
	return scene
end

return AMouseScene
