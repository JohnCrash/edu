require "AudioEngine" 
local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local battle = require "han/battle"
local level = require "han/game"
local http = require "han/http"
local global = require "han/global"
local state = require "han/state"

local ui = {
	FILE = 'han/chuangguan.json',
	FILE_3_4 = 'han/chuangguan43.json',
	BACK = 'ding/fan',
	LIST = 'fan',
	ITEM_NUMBER = 'g1',
	ITEM_CURRENT = 'g2',
	ITEM_LOCK = 'g3',
	MISSION_BUT = 'ding/renwu',
	MISSION_FLAG = 'ding/renwu/hong',
	NOTICE_BUT = 'ding/xiaoxi',
	NOTICE_BOBO = 'ding/xiaoxi/hong',
	SP = 'ding/tili/su',
	SP_ADD_BUT = 'ding/tili/jia',
	BUY_SLIVER_BUT = 'ding/yinbi/jia',
	SLIVER = 'ding/yinbi/su',	
	SETTING_BUT = 'ding/sez',
	START_UI = 'guan',
	
	START_LEVEL = 'guan',
	
	CHILD_PLANE = 'duo',
	CHILD_NEXT = 'you',
	CHILD_PREV = 'zuo',
	CHILD_NAME = 'mz',
	
	LEVEL_TOP10 = 'tongx/gund',
	LEVEL_ITEM = 'tongx1',
	LEVEL_ITEM_NAME = 'mz',
	LEVEL_ITEM_LOGO = 'touxiang',
	LEVEL_ITEM_SCORE = 'defen',
	
	NOTHING_PLANE = 'tongx/meiyou',
	
	START_CHEET_BUT = 'tianyan',
	START_CHEET_CAST = 'tili_0',
	
	START_BUT = 'kais',
	START_CAST = 'tili',
	
	START_CHANCEL = 'fangq',
	
	SCORE_LIST = 'wofen',
	SCORE_ITEM1 = 'wo',
	SCORE_ITEM2 = 'jiaren1',
	SCORE_ITEM3 = 'zongfen',
	SCORE_LOGO = 'touxiang',
	SCORE_NAME = 'mz',
	SCORE_SCORE = 'defen',
	SCORE_ADD = 'tu',
}

local levelScene = uikits.SceneClass("levelScene")
--[[
local levelScene = class("levelScene")
levelScene.__index = levelScene

function levelScene.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),levelScene)
	
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
--]]
function levelScene:clear()
	if self._items then
		for i,v in pairs(self._items) do
			v:removeFromParent()
		end
		self._items = {}
	end
end

function levelScene:add(m,n,b)
	self._items = self._items or {}
	local item
	if m==1 then
		item = self._item_number:clone()
	elseif m==2 then
		item = self._item_current:clone()
	else
		item = self._item_lock:clone()
	end
	if m==1 or m==2 then
		uikits.event(item,function(sender)
			self:prepare_start(m,n,b)
		end)
	end
	item:setVisible(true)
	if n then
		local stars = state.get_level_star()
		local txt = uikits.child(item,'su')
		if txt then
			txt:setString(tostring(n))
		else
			txt = uikits.child(item,'tisu')
			local pass_n
			if stars and stars[n] then
				pass_n = stars[n].pass_condition
			end
			if txt then
				txt:setString(tostring(math.floor(pass_n or "0")))
			end
		end
		if m==1 then
			local ck = {}
			for i=1,3 do
				ck[i] = uikits.child(item,'x'..i)
				ck[i]:setSelectedState(false)
				ck[i]:setEnabled(false)
			end
			if stars and stars[n] and stars[n].star_count then
				local sc = tonumber(stars[n].star_count)
				if sc == 1 then
					ck[1]:setSelectedState(true)
				elseif sc == 2 then
					ck[1]:setSelectedState(true)
					ck[2]:setSelectedState(true)
				elseif sc == 3 then
					ck[1]:setSelectedState(true)
					ck[2]:setSelectedState(true)			
					ck[3]:setSelectedState(true)
				end
			end
		end
	end
	self._list:addChild(item)
	if not b then
		table.insert(self._items,item)	
	end
	return item
end

function levelScene:prepare_start( m,n,b )
	local send_data = {V1=n}
	kits.log("do prepare_start launch battle...")
	http.post_data(self._root,'get_road_block_info',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			self:init_start_ui(v,m,n,b)
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:prepare_start(m,n,b)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end)
end

function levelScene:open_eos(level)
	local send_data = {v1=level,v2=1,v3=0,v4=true}
	http.post_data(self._root,'get_new_match',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			if v.v1 then
				if v.v5 then
					uikits.pushScene( require "hitmouse2/eos".create(v.v5) )
				else
					kits.log("ERROR get_new_match v5=nil")
				end
			else
				http.messagebox(self._root,http.OK_MSG,function(e)
				end,tostring(v.v2 or 'get_new_match return v.v2 = nil'))						
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:open_eos(level)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end)			
end

function levelScene:start_state()
	if self._start_ui and self._v4 then
		if state.get_sp() < self._v4 then
			uikits.child(self._start_ui,ui.START_CAST):setColor(cc.c3b(255,0,0))
			uikits.child(self._start_ui,ui.START_BUT):setBright(false)
			uikits.child(self._start_ui,ui.START_BUT):setEnabled(false)
		else
			uikits.child(self._start_ui,ui.START_CAST):setColor(cc.c3b(0,255,0))
			uikits.child(self._start_ui,ui.START_BUT):setBright(true)
			uikits.child(self._start_ui,ui.START_BUT):setEnabled(true)		
		end
	end
end

function levelScene:init_start_ui(v,m,n,b)
	self._start_ui:setVisible(true)
	self._start_ui:setLocalZOrder(10)
	uikits.event(uikits.child(self._start_ui,ui.START_CHANCEL),
		function(sender)
			self._start_ui:setVisible(false)
		end)
	uikits.child(self._start_ui,ui.START_LEVEL):setString(n or '-')
	self._v4 = v.v4
	self:start_state()
	uikits.child(self._start_ui,ui.START_CAST):setString(v.v4 or '-')
	--[[
	if state.get_sliver() < v.v5 then
		uikits.child(self._start_ui,ui.START_CHEET_CAST):setColor(cc.c3b(255,0,0))
	end
	uikits.child(self._start_ui,ui.START_CHEET_CAST):setString(v.v5 or '-')
	--]]
	--[[
	if v.v6 and type(v.v6)=='table' then
		self._top10:clear()
		if #v.v6 > 0 then
			self._top10._scrollview:setVisible(true)
			self._nothing:setVisible(false)		
		else
			self._top10._scrollview:setVisible(false)
			self._nothing:setVisible(true)				
		end
		for i,v in pairs(v.v6) do
			local item = self._top10:additem(1)
			uikits.child(item,ui.LEVEL_ITEM_NAME):setString(v.name or '-')
			http.load_logo_pic(uikits.child(item,ui.LEVEL_ITEM_LOGO),v.uid or 0)
			uikits.child(item,ui.LEVEL_ITEM_SCORE):setString(v.score or '-')
		end
		self._top10:relayout_horz()
	end
	--]]
	uikits.event(uikits.child(self._start_ui,ui.START_BUT),
		function(sender)
			self:start_game2(v,m,n,b)
		end)
	uikits.event(uikits.child(self._start_ui,ui.START_CHEET_BUT),
		function(sender)
			self:open_eos(n)
		end)		
	--childs
	--[[
	local child_plane = uikits.child(self._start_ui,ui.CHILD_PLANE)
	local tt = global.getChildInfo()
	local childs
	if tt and tt.v2 then
		childs = tt.v2
	end
	if childs and type(childs)=='table' and #childs>0 then
		child_plane:setVisible(true)
		local next_but = uikits.child(child_plane,ui.CHILD_NEXT)
		local prev_but = uikits.child(child_plane,ui.CHILD_PREV)
		local cur = 1
		local name = uikits.child(child_plane,ui.CHILD_NAME)
		name:setString(childs[cur].user_name or '-')
		uikits.event(next_but,function(sender)
			cur = cur + 1
			if cur > #childs then
				cur = 1
			end
			name:setString(childs[cur].user_name or '-')
		end)
		uikits.event(prev_but,function(sender)
			cur = cur - 1
			if cur <= 0 then
				cur = 1
			end
			name:setString(childs[cur].user_name or '-')		
		end)
	else
		child_plane:setVisible(false)
	end
	if child_plane then
		child_plane:setVisible(false) --关闭切换
	end
	--]]
	--calc total score
	--[[
	if not self._parent_scroll  then
		self._parent_scroll = uikits.scrollex(self._start_ui,ui.SCORE_LIST,
		{ui.SCORE_ITEM1,ui.SCORE_ITEM2,ui.SCORE_ITEM3})
	end
	self._parent_scroll:clear()
	local function init_item( item,score,uid,name )
		uikits.child(item,ui.SCORE_SCORE):setString( score or '-' )
		uikits.child(item,ui.SCORE_NAME):setString( name or '-' )
		http.load_logo_pic(uikits.child(item,ui.SCORE_LOGO),uid or 0 )
	end
	local me_item = self._parent_scroll:additem(1)
	init_item(me_item,v.v2 or '-',login.uid(),state.get_name() or "")
	if v and v.v3 and type(v.v3)=='table' and #v.v3 > 0 then
		local total = v.v2 or 0
		for i,s in pairs(v.v3) do
			local parent_item = self._parent_scroll:additem(2)
			init_item(parent_item,s.score,s.uid,s.name)
			total = total + (s.score or 0)
		end
		local total_item = self._parent_scroll:additem(3)
		total_item:setString( total )
	else
		uikits.child(me_item,ui.SCORE_ADD):setVisible(false)
	end
	self._parent_scroll:relayout_horz()
	--]]
end

function levelScene:start_game2(v,m,n,b)
	local send_data = {V1=n,V2=1}
	kits.log("do levelScene launch battle...")
	http.post_data(self._root,'get_new_match',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			if v.v1 then
				if v.v3 then
					state.set_sliver(v.v3)
					state.set_sp(v.v4.v1,v.v4.v2,v.v4.v3)
					self:initBoboState()
				end
				v.v5.threshold = v.v6
				v.v5.condition = v.v6
				v.v5.type = 1
				v.v5.level = n
				uikits.pushScene(battle.create(v.v5))
				self._start_ui:setVisible(false)
			else 
				http.messagebox(self._root,http.OK_MSG,function(e)
				end,tostring(v.v2 or 'get_new_match return v.v2 = nil'))
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:start_game2(v,m,n,b)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end)	
end

function levelScene:start_game(m,n,b)
	local send_data = {V1=n,V2=1}
	kits.log("do levelScene launch battle...")
	http.post_data(self._root,'get_match',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			local signle,dual = 1,1
			if v.question_amount and v.question_signle then
				signle = v.question_signle
				dual = v.question_amount-signle
			else
				kits.log("ERROR get_match invaild result,v.question_signle = nil")
			end	
--[[					
			uikits.pushScene(battle.create{
					level = v.road_block_id or 1,
					time_limit = 120,
					rand = 1,
					diff1 = 1,
					diff2 = 5,
					signle = 1,
					dual = 0,
					condition = 70,
					type = 1,
				})	
				--]]
				v.v5.threshold = v.v6
				v.v5.condition = v.v6
				v.v5.type = 1
				v.v5.level = n
				uikits.pushScene(battle.create(v.v5))							
	--[[						
			uikits.pushScene(battle.create{
					level = v.road_block_id or 1,
					time_limit = v.times or 10,
					rand = v.road_radom or 0,
					diff1 = v.diffcult_low or 0,
					diff2 = v.diffcult_up or 0,
					signle = signle,
					dual = dual,
					condition = v.pass_condition or 60,
					type = 1,
				})
				--]]
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:start_game(m,n,b)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end)	
end
	
function levelScene:relayout()
	if self._items then
		local count = #self._items
		local raw = math.floor(count/self._colume)
		if count%self._colume > 0 then
			raw = raw + 1
		end
		local size = cc.size(self._list_size.width,raw*(self._item_size.height+self._space)+self._space)
		local x,y = self._offset,size.height-self._space-self._item_size.height
		self._list:setInnerContainerSize(size)
		local n = 1
		for i=1,count do
			self._items[i]:setPosition(cc.p(x,y))
			if n < self._colume then
				x = x + self._space + self._item_size.width
				n = n + 1
			else
				x = self._offset
				y = y - self._space - self._item_size.height
				n = 1
			end
		end
	end
end

function levelScene:visibleCurrent()
	if self._items and self._current and self._items[self._current] then
		local x,y = self._items[self._current]:getPosition()
		local inner = self._list:getInnerContainer()
		local xx,yy = inner:getPosition()
		if y<-yy then
			inner:setPosition(cc.p(xx,-(y-self._space)))
		end
	end
end

function levelScene:init()
	--self._news = state.get_news()
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
			uikits.popScene()
		end)
		self._list = uikits.child(self._root,ui.LIST)
		uikits.enableMouseWheelIFWindows(self._list)
		self._item_number = uikits.child(self._list,ui.ITEM_NUMBER)
		self._item_current = uikits.child(self._list,ui.ITEM_CURRENT)
		self._item_lock = uikits.child(self._list,ui.ITEM_LOCK)
		self._item_number:setAnchorPoint(cc.p(0,0))
		self._item_current:setAnchorPoint(cc.p(0,0))
		self._item_lock:setAnchorPoint(cc.p(0,0))
		self._item_size = self._item_number:getContentSize()
		self._list_size = self._list:getContentSize()
		if self._list_size.width == 1920 then
			self._colume = 7
			self._offset = 36
			self._space = 12
		else
			self._colume = 5
			self._offset = 64
			self._space = 16		
		end
		self._item_number:setVisible(false)
		self._item_current:setVisible(false)
		self._item_lock:setVisible(false)
		uikits.event(uikits.child(self._root,ui.MISSION_BUT),function(sender)
			local scene = require "hitmouse2/mission"
			self._news.hasMission = false
			uikits.pushScene(scene.create())
		end)	
		uikits.event(uikits.child(self._root,ui.SETTING_BUT),function(sender)
			local scene = require "hitmouse2/setting"
			uikits.pushScene(scene.create())		
		end)			
		uikits.event(uikits.child(self._root,ui.NOTICE_BUT),function(sender)
			local scene = require "hitmouse2/notice"
			self._news.hasMsg = false
			uikits.pushScene(scene.create())
		end)	
--[[		
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
--]]		   
		self._start_ui = uikits.child(self._root,ui.START_UI)
		self._start_ui:setVisible(false)

		--[[
		self._top10 = uikits.scrollex(self._start_ui,ui.LEVEL_TOP10,{ui.LEVEL_ITEM})
		self._top10:clear()
		self._nothing = uikits.child(self._start_ui,ui.NOTHING_PLANE)
		self._nothing:setVisible(true)
		self._top10._scrollview:setVisible(false)
		uikits.delay_call(self._root,function(dt)
			if self and cc_isobj(self._root) then
				self:initBoboState()
				return true
			end
		end,1)
		--]]
	end
	--if self._current and self._current==level.getCurrent() then
	--elseif self._current and self._current==level.getCurrent()-1 then
	--	self:initOpenNext()
	--else
		self:clear()
		self._current = level.getCurrent()
		self._count = level.getLevelCount()
		self:initLevelList()
	--end
	self:initBoboState()
end

function levelScene:initBoboState()
	--[[
	uikits.child(self._root,ui.NOTICE_BOBO):setVisible(self._news.hasMsg)
	uikits.child(self._root,ui.MISSION_FLAG):setVisible(self._news.hasMission)
	local sp,up = state.get_sp()
	uikits.child(self._root,ui.SP):setString(tostring(sp).."/"..tostring(up))
	uikits.child(self._root,ui.SLIVER):setString(tostring(state.get_sliver()))
	self:start_state()
	--]]
end

function levelScene:initOpenNext()
	if self._current and self._items and self._current < self._count then
		local cx,cy = self._items[self._current]:getPosition()
		local dx,dy = self._items[self._current+1]:getPosition()
		self._items[self._current]:removeFromParent()
		self._items[self._current+1]:removeFromParent()
		self._items[self._current] = self:add(1,self._current,true)
		self._items[self._current+1] = self:add(2,self._current+1,true)
		self._items[self._current]:setPosition(cc.p(cx,cy))
		self._items[self._current+1]:setPosition(cc.p(dx,dy))
		self._current = self._current + 1
		self:visibleCurrent()
	end
end

function levelScene:initLevelList()
	for i = 1,self._current-1 do
		self:add(1,i)
	end
	if self._current <= 0 then
		self._current = 1
	end
	if self._current <= self._count then
		self:add(2,self._current)
		for i = self._current+1,self._count do
			self:add(3)
		end
	end
	self:relayout()
	self:visibleCurrent()
end

function levelScene:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return levelScene