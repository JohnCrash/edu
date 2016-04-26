local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local login = require "login"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/shijiesai.json',
	FILE_3_4 = 'hitmouse2/shijiesai43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	RULE_BUT = 'ding/guizhe',
	WATCH_BUT = 'ding/cheng',
	CUP_BUT = 'ding/jiangxiang',
	
	WATCH_PLANE = 'bishichu',
	VOTE_PLANE = 'weijinji',
	ASK_VOTE_PLANE = 'jinji',
	WATCH_PLANE2 = 'bishihou',
	TOP_PLANE = 'zhuihou',
	
	LIST  = 'ren/gun',
	ITEM = 'csz1',
	ITEM_LOGO = 'toux',
	ITEM_RANK = 'pm',
	ITEM_NAME = 'mingz',
	ITEM_SCHOOL = 'xs',
	ITEM_CLASS = 'banji',
	ITEM_SCORE = 'zchengj',
	ITEM_PARENT_SCORE1 = 'jiaz',
	ITEM_ASK_VOTE_SCORE = 'piao',
	ITEM_ASK_VOTE  = 'yinpiao',
	ITEM_ASK_VOTE_BUT = 'xuany',
	
	LIST_TOPS = 'zhuihou',
	ITEM_TOPS = 'ren1',
	ITEM_TOPS_TOP = 'jies',
	ITEM_TOPS_TOP_NO_RANK = 'mei',
	ITEM_TOPS_TOP_LABEL = 'banj',
	ITEM_TOPS_TOP_RANK = 'xuexiao',
	ITEM_TOPS_LOGO = 'toux',
	ITEM_TOPS_NAME = 'mingz',
	ITEM_TOPS_SCHOOL = 'xuexiao',
	ITEM_TOPS_CLASS = 'banji',
	ITEM_TOPS_TOTAL_SCORE = 'chengji',
	ITEM_TOPS_TOTAL_ASK_VOTE = 'tou',
	ITEM_TOPS_RANK = 'tu5/mingci',
	
	PLANE = 'wo',
	PLANE_RANK = 'mc',
	PLANE_LABEL = 'w1',
	PLANE_SCORE = 'zchengj',
	PLANE_PARENT_SCORE = 'jiaz',
	PLANE_PARENT_LIST = 'gund',
	PLANE_PARENT_ITEM = 'jia1',
	ITEM_PARENT_NAME = 'w4',
	ITEM_PARENT_SCORE = 'jiaf',
	PLANE_START_BUT = 'kais',
	PLANE_START_SLIVER = 'yinb',
	PLANE_START_SLIVER_LABEL = 'w6',
	PLANE_RULE_LABEL = 'hei/gui',
	PLANE_WARNING_1 = 'hei/s1',
	PLANE_WARNING_2 = 'hei/s2',
	PLANE_WARNING_3 = 'hei/s3',
	PLANE_ASK_VOTE_SCORE_LABEL = 'w3',
	PLANE_ASK_VOTE_SCORE = 'piao',
	PLANE_TIME_LABEL = 'hei/shij',
	PLANE_STAGE_1 = '1',
	PLANE_STAGE_2 = '2',
	PLANE_STAGE_3 = '3',
	PLANE_STAGE_4 = '4',
	PLANE_STAGE_5 = '5',
	PLANE_TIMER = 'daojis',
	PLANE_ASK_VOTE_BUT = 'Button_155',
}

local _mingchi = '名'
local worldmatch_stage = uikits.SceneClass("worldmatch_stage",ui)
local playlists = {}

function worldmatch_stage:init(b)
	if b then
		--[[debug
		local button = uikits.button{caption="推进到下一阶段\n(仅测试用)",width=260,height=96,
				eventClick=function(sender)
					state.next_stage(self._root,self._arg.worldmatch_id,function(b)
						if b then
							self:initData()
						end
					end)
				end}
		local ding = uikits.child(self._root,ui.BACK)
		ding:addChild(button)
		local x,y = uikits.child(self._root,ui.RULE_BUT):getPosition()
		button:setPosition(cc.p(x-420,y-45))
		--]]	
	
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		uikits.event(uikits.child(self._root,ui.RULE_BUT),function(sender)
			uikits.pushScene( require "hitmouse2/shijiegui".create(self._arg) )
		end)
		uikits.event(uikits.child(self._root,ui.WATCH_BUT),function(sender)
			uikits.pushScene( require "hitmouse2/worldmatch_level".create(self._arg) )
		end)
		uikits.event(uikits.child(self._root,ui.CUP_BUT),function(sender)
			uikits.pushScene( require "hitmouse2/worldmatch_cup".create(self._arg) )
		end)		
		self._watch_plane = uikits.child(self._root,ui.WATCH_PLANE)
		self._vote_plane = uikits.child(self._root,ui.VOTE_PLANE)
		self._ask_vote_plane = uikits.child(self._root,ui.ASK_VOTE_PLANE)
		self._watch_plane2 = uikits.child(self._root,ui.WATCH_PLANE2)
		self._top_plane = uikits.child(self._root,ui.TOP_PLANE)
	end
	if self._watch_plane then
		self._watch_plane:setVisible(false)
	end
	if self._vote_plane then
		self._vote_plane:setVisible(false)
	end
	if self._ask_vote_plane then
		self._ask_vote_plane:setVisible(false)
	end
	if self._watch_plane2 then
		self._watch_plane2:setVisible(false)
	end
	if self._top_plane then
		self._top_plane:setVisible(false)	
	end
	self:initData()
end

function worldmatch_stage:initData()
	local send_data = {v1=self._arg.worldmatch_id}
	kits.log("do worldmatch_stage:initData...("..tostring(self._arg.worldmatch_id)..")")
	http.post_data(self._root,'worldsub_detail_s',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_stage:initData success!")
			http.logTable(v,1)
			self._data = v
			self._arg._data = v
			if v and type(v)=='table' then
				if v.v6==1 then
					if v.v5>1 then
						self._watch_plane2:setVisible(true)
						self:initListPlayer(self._watch_plane2)
						self:initPlane(self._watch_plane2)
					else
						self._watch_plane:setVisible(true)
						self:initListPlayer(self._watch_plane)
						self:initPlane(self._watch_plane)
					end
				elseif v.v6==2 then
					self._ask_vote_plane:setVisible(true)
					self:initListPlayer(self._ask_vote_plane)
					self:initPlane(self._ask_vote_plane)
				elseif v.v6==3 then
					self._vote_plane:setVisible(true)
					self:initListPlayer(self._vote_plane)
					self:initPlane(self._vote_plane)
				elseif v.v6==4 then
					self._vote_plane:setVisible(true)
					self:initListPlayer(self._vote_plane)
					self:initPlane(self._vote_plane)
				elseif v.v6==5 then
					self._top_plane:setVisible(true)
					self:initTops()
				else
					kits.log("ERROR worldsub_detail_s v.v6="..tostring(v.v6))
				end
			else
				kits.log("ERROR worldsub_detail_s return invalid value")
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:initData()
				else
					uikits.popScene()
				end
			end,v)			
		end
	end)	
end

local function setString(parent,uiid,str)
	local item = uikits.child(parent,uiid)
	if item then
		item:setString( str or '-' )
	end
end

function worldmatch_stage:start_match()
	if self._data and self._data.v13 then
		if self._data.v13 < 0 then
			http.messagebox(self._root,http.OK_MSG,function(s)
			end,"你已经用完了你的比赛次数")		
			return
		end
		if state.get_sliver() < self._data.v13 then
			http.messagebox(self._root,http.NO_SILVER,function(s)
			end)
			return
		end
	end
	print("match_stage = "..tostring(self._arg.match_stage))
	local send_data = {V1=self._arg.worldmatch_id,V2=3,v3=self._arg.match_stage,v4=false,v5=0}
	kits.log("do levelScene launch battle...")
	http.post_data(self._root,'get_new_match',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v,1)
			if v.v1 then
				if v.v3 then
					state.set_sliver(v.v3)
					state.set_sp(v.v4.v1,v.v4.v2,v.v4.v3)
				end
				v.v5.threshold = v.v6
				v.v5.condition = v.v6
				v.v5.type = 3
				v.v5.level = self._arg.worldmatch_id
				if self._data then
					v.v5.subid = self._data.v5 or 0
				end
				local battle = require "hitmouse2/battle"
				uikits.pushScene(battle.create(v.v5))
			else 
				http.messagebox(self._root,http.OK_MSG,function(e)
				end,tostring(v.v2 or 'get_new_match return v.v2 = nil'))
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:start_match(v,m,n,b)
				else
					uikits.popScene()
				end
			end,v)		
		end
	end)	
end

function worldmatch_stage:initPlane(parent)
	local plane = uikits.child(parent,ui.PLANE)
	if self._data.v1 and self._data.v1 > 0 then
		setString(plane,ui.PLANE_RANK,self._data.v1)
	elseif self._data.v1 and self._data.v1==-2 then
		setString(plane,ui.PLANE_RANK,"暂无排名")
	elseif self._data.v1 and self._data.v1==-1 then
		setString(plane,ui.PLANE_RANK,"已淘汰")
	end
	if http.get_id_flag()==http.ID_FLAG_PAR then
		setString(plane,ui.PLANE_LABEL,"孩子的本轮名次")
	end
	setString(plane,ui.PLANE_SCORE,self._data.v2)
	setString(plane,ui.PLANE_PARENT_SCORE,self._data.v3)
	setString(plane,ui.PLANE_RULE_LABEL,self._data.v7)
	setString(plane,ui.PLANE_START_SLIVER,self._data.v13)
	setString(plane,ui.PLANE_ASK_VOTE_SCORE,self._data.v17)
	
	if parent == self._vote_plane then --投票
		setString(plane,ui.PLANE_ASK_VOTE_SCORE,self._data.v11)
		--家长不能进行投票，剩余票数的界面隐藏起来
		if http.get_id_flag()==http.ID_FLAG_PAR then
			local label = uikits.child(plane,ui.PLANE_ASK_VOTE_SCORE)
			if label then
				label:setVisible(false)
			end
			label = uikits.child(plane,ui.PLANE_ASK_VOTE_SCORE_LABEL)
			if label then
				label:setVisible(false)
			end			
		end
	elseif parent == self._ask_vote_plane then --拉票
	else --比赛
	end
	
	local timer = uikits.child(plane,ui.PLANE_TIME_LABEL)
	if timer then
		if self._data.v8 then
			state.timer(timer,self._data.v8)
		else
			timer:setString('-')
		end
	end	
	local list = uikits.child(plane,ui.PLANE_PARENT_LIST)
	if list and self._data.v9 then
		self._parent_scrollview = self._parent_scrollview or uikits.scrollex(plane,ui.PLANE_PARENT_LIST,{ui.PLANE_PARENT_ITEM})
		self._parent_scrollview:clear()
		for i,v in pairs(self._data.v9) do
			local item = self._parent_scrollview:additem(1)
			uikits.child(item,ui.ITEM_PARENT_NAME):setString( v.name or '-' )
			uikits.child(item,ui.ITEM_PARENT_SCORE):setString( v.score or '-' )
		end
		self._parent_scrollview:relayout_horz()
	elseif self._parent_scrollview then
		self._parent_scrollview:clear()
		self._parent_scrollview:relayout_horz()
	end
	local but = uikits.child(plane,ui.PLANE_START_BUT)	
	if but then
		--start match button
		if self._data and self._data.v13 and self._data.v13 < 0 then
			but:setEnabled(false)
			but:setBright(false)
			local label = uikits.child(plane,ui.PLANE_START_SLIVER)
			if label then
				label:setVisible(false)
			end
			label = uikits.child(plane,ui.PLANE_START_SLIVER_LABEL)
			if label then
				label:setVisible(false)
			end			
		else
			uikits.event(but,function(sender)
				self:start_match()
			end)
		end
	end
	but = uikits.child(plane,ui.PLANE_ASK_VOTE_BUT)
	--家长不能进行投票和发布宣言,已经被淘汰的不能发布宣言
	if http.get_id_flag()==http.ID_FLAG_PAR or 
		self._data.v1 ==-1 then
		--but:setVisible(false) 
		if but then
			but:setBright(false)
			but:setEnabled(false)
		end
		--[[
		local pp = uikits.child(plane,ui.PLANE_ASK_VOTE_SCORE)
		if pp then
			pp:setVisible(false)
		end
		pp = uikits.child(plane,"w3")
		if pp then
			pp:setVisible(false)
		end		
		--]]
	end
	if but then
		uikits.event(but,function(sender)
				self:do_vote(self._data.v20,self._data.v21,self._data.v22,
					self._data.v19,self._arg.worldmatch_id,login.uid(),self._data.v11)			
		end)
	end	
	--warning
	local w1 = uikits.child(plane,ui.PLANE_WARNING_1)
	local w2 = uikits.child(plane,ui.PLANE_WARNING_2)
	local w3 = uikits.child(plane,ui.PLANE_WARNING_3)
	if w1 and w2 and w3 then
		local rs = self._data.v18 or 1
		w1:setVisible(false)
		w2:setVisible(false)
		w3:setVisible(false)
		if self._data.v1 <= rs/3+1 then
			w3:setVisible(true)
		elseif self._data.v1 <= rs*2/3+1 then
			w2:setVisible(true)
		else
			w1:setVisible(true)
		end
	end
	local stages = {}
	local stage1 = uikits.child(plane,ui.PLANE_STAGE_1)
	if not stage1 then
		stage1 = uikits.child(plane,ui.PLANE_STAGE_2)
	end
	if stage1 then
		table.insert(stages,stage1)
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_2))
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_3))
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_4))
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_5))
		for i=1,5 do
			if stages[i] then
				stages[i]:setVisible(false)
			end
		end
		local show = {}
		if self._data.v4 == 2 then
			table.insert(show,1)
			table.insert(show,5)
		elseif self._data.v4 == 3 then
			table.insert(show,1)
			table.insert(show,2)
			table.insert(show,5)			
		elseif self._data.v4 == 4 then
			table.insert(show,1)
			table.insert(show,2)
			table.insert(show,3)
			table.insert(show,5)			
		else
			table.insert(show,1)
			table.insert(show,2)
			table.insert(show,3)
			table.insert(show,4)
			table.insert(show,5)			
		end
		if self._data.v5 and show[self._data.v5] then
			stages[show[self._data.v5]]:setVisible(true)
		end
	end
	--timer
	local timer = uikits.child(plane,ui.PLANE_TIMER)
	if timer then
		if self._data.v8 then
			state.timer(timer,self._data.v8)
		else
			timer:setString('-')
		end
	end
end

function worldmatch_stage:initListPlayer(parent)
	if playlists[parent] then
		self._playes_scrollview = playlists[parent]
	else
		self._playes_scrollview = uikits.scrollex(parent,ui.LIST,{ui.ITEM})
		playlists[parent] = self._playes_scrollview
		
		uikits.event(self._playes_scrollview._scrollview,function(sender,state)
			if state == ccui.ScrollviewEventType.scrollToBottom then
				if not self._done_loading and self._tatolPags and self._curPage < self._tatolPags then
					self._curPage = self._curPage + 1
					kits.log("continue loading...")
					self:getPlayerList(parent,self._curPage)
					self._done_loading = true
				end
			end
		end)		
	end
	self:getPlayerList(parent)
	uikits.enableMouseWheelIFWindows(self._playes_scrollview)
end

function worldmatch_stage:add_player(v)
	if not self._playes_scrollview then
		kits.log("ERROR worldmatch_stage:add_player self._playes_scrollview = nil")
		return
	end
	local item = self._playes_scrollview:additem(1)
	uikits.child(item,ui.ITEM_NAME):setString(v.name or '-')
	http.load_logo_pic(uikits.child(item,ui.ITEM_TOPS_LOGO),v.uid or 0)
	uikits.child(item,ui.ITEM_SCHOOL):setString(v.school or '-')
	uikits.child(item,ui.ITEM_CLASS):setString(v.classname or '-')
	local rank = uikits.child(item,ui.ITEM_RANK)
	local score = uikits.child(item,ui.ITEM_SCORE)
	local vote = uikits.child(item,ui.ITEM_ASK_VOTE)
	local but = uikits.child(item,ui.ITEM_ASK_VOTE_BUT)
	local vote_score = uikits.child(item,ui.ITEM_ASK_VOTE_SCORE)
	local parent_score = uikits.child(item,ui.ITEM_PARENT_SCORE1)
	if score then
		score:setString(v.total_score or '-')
	end
	if vote then
		vote:setString(v.vote or '-')
	end
	if vote_score then
		vote_score:setString(v.vote_score or '-')
	end
	if parent_score then
		parent_score:setString(v.parent_score or '-')
	end
	if rank then
		rank:setString(v.rank or '-')
	end
	if http.get_id_flag()==http.ID_FLAG_PAR or 
		--self._data.v1 ==-1 or  --已经被淘汰的用户可以进行投票
		self._data.v6 ~= 4 then
		--but:setVisible(false) --家长不能进行投票和发布宣言
		if but then
			but:setBright(false)
			but:setEnabled(false)
		end
	end
	if but then
		uikits.event(but,function(sender)
			self:do_vote(v.name,v.classname,v.school,
				v.vote,self._arg.worldmatch_id,v.uid,self._data.v11)
		end)
	end
end

function worldmatch_stage:player_list_relayout()
	if self._playes_scrollview then
		--print("player_list_relayout "..tostring(self._data.v6))
		if self._data.v6 == 1 then
			self._playes_scrollview:relayout_colume(3,0,0,0) --
		elseif self._data.v6 == 2 then
			self._playes_scrollview:relayout_colume(2,0,0,0) --
		elseif self._data.v6 == 3 then
			self._playes_scrollview:relayout_colume(2,0,0,0)
		elseif self._data.v6 == 4 then
			self._playes_scrollview:relayout_colume(2,0,0,0)
		elseif self._data.v6 == 5 then
			self._playes_scrollview:relayout_colume(2,0,0,0)
		else
			self._playes_scrollview:relayout_colume(2,0,0,0)			
		end
	else
		kits.log("ERROR worldmatch_stage:player_list_relayout self._playes_scrollview = nil")
	end
end

function worldmatch_stage:getPlayerList(parent,cur)
	if self._playes_scrollview then
		if cur == 1 or not cur then
			self._playes_scrollview:clear()
			self:player_list_relayout()
		end
	else
		kits.log("ERROR worldmatch_stage:getPlayerList self._playes_scrollview = nil")
	end
	self._curPage = cur or 1
	local send_data = {v1=self._arg.worldmatch_id,v2=self._curPage}
	http.post_data(self._root,'worldcup_list_payer',send_data,function(t,v)
		if t and t==200 and v then
			if v.v1 and v.v2 and v.v3 then
				self._tatolPags = v.v1
				for i,v in pairs(v.v3) do
					self:add_player( v )
				end
				self:player_list_relayout()
				self._done_loading = false
			else
				kits.log("ERROR worldcup_list_payer return invalid value")
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:getPlayerList(parent,cur)
				else
					uikits.popScene()
				end
			end,v)	
		end
	end)	
end

function worldmatch_stage:initTops()
	self._tops_scrollview = self._tops_scrollview or uikits.scrollex(self._root,ui.LIST_TOPS,{ui.ITEM_TOPS},{ui.ITEM_TOPS_TOP})
	self._tops_scrollview:clear()
	for i,v in pairs(self._data.v10) do
		local item = self._tops_scrollview:additem(1)
		self._tops_scrollview._list[#self._tops_scrollview._list] = nil
		table.insert(self._tops_scrollview._list,1,item)	
		uikits.child(item,ui.ITEM_TOPS_NAME):setString(v.name or '-')
		http.load_logo_pic(uikits.child(item,ui.ITEM_TOPS_LOGO),v.uid or 0)
		uikits.child(item,ui.ITEM_TOPS_SCHOOL):setString(v.school or '-')
		uikits.child(item,ui.ITEM_TOPS_CLASS):setString(v.classname or '-')
		uikits.child(item,ui.ITEM_TOPS_TOTAL_SCORE):setString(v.total_score or '-')
		uikits.child(item,ui.ITEM_TOPS_TOTAL_ASK_VOTE):setString(v.total_vote or '-')
		uikits.child(item,ui.ITEM_TOPS_RANK):setString(v.rank or '-')
	end
	local no_rank = uikits.child(self._tops_scrollview._tops[1],ui.ITEM_TOPS_TOP_NO_RANK)
	local rank = uikits.child(self._tops_scrollview._tops[1],ui.ITEM_TOPS_TOP_RANK)
	local rank_label = uikits.child(self._tops_scrollview._tops[1],ui.ITEM_TOPS_TOP_LABEL)
	if self._data.v1 and self._data.v1>0 then
		no_rank:setVisible(false)
		rank_label:setVisible(true)
		rank:setVisible(true)
		rank:setString( self._data.v1.._mingchi )
	else
		no_rank:setVisible(true)
		rank_label:setVisible(false)
		rank:setVisible(false)
	end
	self._tops_scrollview:relayout()
end

function worldmatch_stage:do_vote(n,c,s,v,w,u,m)
	if self._arg and self._arg._data then
		--local v = self._arg._data
		uikits.pushScene(require "hitmouse2/worldmatch_vote".create
		{
			name = n,
			class = c,
			school = s,
			vote = v,
			worldmatch_id = w,
			uid = u,
			my_vote = m,
		})
	end
end

function worldmatch_stage:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return worldmatch_stage