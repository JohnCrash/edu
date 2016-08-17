require "AudioEngine" 
local kits = require "kits"
local music = require "hitmouse2/music"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local global = require "hitmouse2/global"

local ui = {
	FILE = 'hitmouse2/shouye.json',
	FILE_3_4 = 'hitmouse2/shouye43.json',
	BACK = 'ding/fan',
	LEVEL_BUT = 'cg',
	TOP_BUT = 'ph',
	MATCH_BUT = 'bs',
	MATCH_NEW = 'bs/tix',
	SETTING_BUT = 'ding/sez',
	NOTICE_BUT = 'ding/xiaoxi',
	NOTICE_BOBO = 'ding/xiaoxi/hong',
	MISSION_BUT = 'ding/renwu',
	MISSION_FLAG = 'ding/renwu/hong',
	SP = 'ding/tili/su',
	SP_ADD_BUT = 'ding/tili/jia',
	BUY_SLIVER_BUT = 'ding/yinbi/jia',
	SLIVER = 'ding/yinbi/su',
	ACHIEVEMENT_BUT = 'cj',
	ACHIEVEMENT_FLAG = 'cj/tix',
	WORLD_MATCH_BUT = 'sj',
	WORLD_MATCH_FLAG = 'sj/tix',
	SWITCH_CHILD_BUT = 'gh',
	SWITCH_CHILD_PLANE = 'duohz',
	ZIBO_BUT = 'zibo',
	CHILD_NAME = 'hz1/mz',
	CHILD_BUT = 'hz1/an',
	CHILD_LOGO = 'hz1',
	LIST = 'gund',
	ITEM = 're',
	CURRENT_CHILD = 'hz',
}

local main = uikits.SceneClass("main")

function main:initBoboState()
	uikits.child(self._root,ui.NOTICE_BOBO):setVisible(self._news.hasMsg)
	uikits.child(self._root,ui.MISSION_FLAG):setVisible(self._news.hasMission)
	uikits.child(self._root,ui.MATCH_NEW):setVisible(self._news.hasMatch)
	uikits.child(self._root,ui.WORLD_MATCH_FLAG):setVisible(self._news.hasWorldMatch)
	uikits.child(self._root,ui.ACHIEVEMENT_FLAG):setVisible(self._news.hasAchievement)
	local sp,up = state.get_sp()
	uikits.child(self._root,ui.SP):setString(tostring(sp).."/"..tostring(up))
	uikits.child(self._root,ui.SLIVER):setString(tostring(state.get_sliver()))
end

function main:init(b)
	local function quit()
		if self._switch_show then
			self._switch_plane:setVisible(false)
			self._switch_show = nil
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					uikits.delay_call( self._root,function(dt)
						music.stop()
						uikits.popScene()
					end)
				end
			end,"确定要退出游戏吗？","确定","取消")			
		end	
	end
	
	local function onKeyRelease(key,event)
		if key == cc.KeyCode.KEY_ESCAPE then
			quit()
		end
	end
	uikits.pushKeyboardListener(onKeyRelease)
	self._news = state.get_news()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		self._ss = cc.size(1920,1080)
	else
		self._ss = cc.size(1440,1080)
	end
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			quit()
		end)
		uikits.event(uikits.child(self._root,ui.TOP_BUT),function(sender)
			local scene = require "hitmouse2/tops"
			uikits.pushScene(scene.create())
		end)
		uikits.event(uikits.child(self._root,ui.MATCH_BUT),function(sender)
			local scene = require "hitmouse2/matchview"
			self._news.hasMatch = false
			uikits.pushScene(scene.create())		
		end)
		uikits.event(uikits.child(self._root,ui.SETTING_BUT),function(sender)
			local scene = require "hitmouse2/setting"
			uikits.pushScene(scene.create())		
		end)		
		uikits.event(uikits.child(self._root,ui.LEVEL_BUT),function(sender)
			local scene = require "hitmouse2/levelScene"
			uikits.pushScene(scene.create())		
		end)	
		uikits.event(uikits.child(self._root,ui.NOTICE_BUT),function(sender)
			local scene = require "hitmouse2/notice"
			self._news.hasMsg = false
			uikits.pushScene(scene.create())
		end)
		uikits.event(uikits.child(self._root,ui.WORLD_MATCH_BUT),function(sender)
			self._news.hasWorldMatch = false
			if http.get_id_flag()==http.ID_FLAG_STU or http.get_id_flag()==http.ID_FLAG_PAR then
				local scene = require "hitmouse2/worldmatch"
				uikits.pushScene(scene.create())
			else
				local scene = require "hitmouse2/worldmatch_teacher"
				uikits.pushScene(scene.create())			
			end
		end)		
		uikits.event(uikits.child(self._root,ui.ACHIEVEMENT_BUT),function(sender)
			self._news.hasAchievement = false
			if http.get_id_flag()==http.ID_FLAG_STU then
				local scene = require "hitmouse2/achievement"
				uikits.pushScene(scene.create())
			else
				local scene = require "hitmouse2/achievement_teacher"
				uikits.pushScene(scene.create())			
			end
		end)		
		local zibo = uikits.child(self._root,ui.ZIBO_BUT)
		if zibo then
			zibo:setVisible(false)
			uikits.delay_call( self._root,function(dt)
				local zone = state.get_zone()
				kits.log( "zone :"..tostring(zone) )
				if zone then
					if tostring(zone) == "370300" then
						zibo:setVisible(true)
						uikits.event(zibo,function(sender)
							uikits.pushScene(require "hitmouse2/zibo".create())
						end)
					end
					return false
				end
				return true
			end,0.1)
		end
		uikits.event(uikits.child(self._root,ui.MISSION_BUT),function(sender)
			local scene = require "hitmouse2/mission"
			--self._news.hasMission = false
			uikits.pushScene(scene.create(self._news))
		end)		
		state.request_buy_sp(self._root,ui.SP_ADD_BUT,function(v)
			self:initBoboState()
		end)
		state.request_buy_silver(self._root,ui.BUY_SLIVER_BUT,function(b)
			local as = state.get_add_sliver()
			
			if b and as > 0 then
				local count = 1
				local o = state.get_sliver()
				state.set_sliver(o+as)
				local name = 'hitmouse2/snd/gold.mp3'
				local local_dir = kits.get_local_directory()..'res/'
				AudioEngine.playEffect(local_dir..name)
				uikits.delay_call(self._root,function(dt)
					uikits.child(self._root,ui.SLIVER):setString(math.floor(o+as*count/10))
					if count <= 10 then
						count=count+1
						return true
					else
						return false
					end
				end,0.2)
			end
		end)
		uikits.delay_call(self._root,function(dt)
			if cc_isobj(self._root) then
				self:initBoboState()
				return true
			end
		end,1)		
		self._mut = kits.config("hitmouse_mute","get")
		if not self._mut then
			math.randomseed(os.time())
			music.play()
		end
		self._switch_plane = uikits.child(self._root,ui.SWITCH_CHILD_PLANE)
		self._current_child = uikits.child(self._root,ui.CURRENT_CHILD)
		self._current_child:setVisible(false)
		self._switch_plane:setVisible(false)		
		local id = http.get_id_flag()
		local but = uikits.child(self._root,ui.SWITCH_CHILD_BUT)
		but:setVisible(false)
		--if id == http.ID_FLAG_PAR then
		if global.getAttachChildUID() ~= 0 then
			http.logTable(global.getChildInfo())
			local child_info = global.getChildInfo().v2
			print("--------My childs---------")
			http.logTable(child_info,1)
			if child_info and type(child_info)=='table' and #child_info>0 then
				but:setVisible(true)	
				self._current_child:setVisible(true)
				http.load_logo_pic(self._current_child,global.getAttachChildUID() or 0)
				uikits.event(but,function(sender)
					self:showSwitchChild()
				end)
			end
		end
		self:checkUpdate()
	end
	self:initBoboState()
end

function main:checkUpdate()
	kits.log("main:checkUpdate")
	if kits.isNeedUpade then
		kits.isNeedUpade('hitmouse2',function(b)
			if b then
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e==http.RETRY then
						uikits.delay_call( self._root,function(dt)
							kits.doUpdate('hitmouse2')
						end,0.1)
					end
				end,"有一个新的版本可用","马上升级","稍后再说")
			else
				kits.log("INFO:hitmouse2 not need update~")
			end
		end)
	end
end

function main:showSwitchChild()
	self._switch_plane:setVisible(true)
	self._switch_show = true
	if not self._scrollview then
		self._scrollview = uikits.scrollex(self._switch_plane,ui.LIST,{ui.ITEM})
		local child_info = global.getChildInfo().v2
		for i,v in pairs(child_info) do
			local item = self._scrollview:additem(1)
			uikits.child(item,ui.CHILD_NAME):setString(v.user_name or '-')
			http.load_logo_pic(uikits.child(item,ui.CHILD_LOGO),v.user_id or 0)
			uikits.event(uikits.child(item,ui.CHILD_BUT),function(sender)
				global.setAttachChildUID(v.user_id)
				http.load_logo_pic(self._current_child,global.getAttachChildUID() or 0)
				self:setCurrentChild(v.user_id,self._switch_plane)
			end)
		end
		self._scrollview:relayout_horz()
	end
end

function main:setCurrentChild(uid,plane)
	local send_data = {v1=uid}
	kits.log("do loading:setCurrentChild...")
	http.post_data(self._root,'attach_child',send_data,function(t,v)
		if t and t==200 and v and v.v1 then
			kits.log("loading setCurrentChild success!")
			http.logTable(v,1)
			plane:setVisible(false)
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:setCurrentChild()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end)	
end

function main:release()
	uikits.popKeyboardListener()
end

return main