local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local login = require "login"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/jinruLAO.json',
	FILE_3_4 = 'hitmouse2/jinruLAO43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	RULE_BUT = 'ding/guizhe',
	WATCH_BUT = 'ding/cheng',
	CUP_BUT = 'ding/jiangxiang',

	WATCH_PLANE = 'bishichu',
	VOTE_PLANE = 'toupiaoz',
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
	
	PLANE_PLAYER_COUNT = 'res',
	PLANE_MYSTUDENT_COUNT = 'res2',
	PLANE_MYSTUDENT_JJ_COUNT = 'wojinj/res',
	
	PLANE_RANK = 'mc',
	PLANE_SCORE = 'zchengj',
	PLANE_PARENT_SCORE = 'jiaz',
	PLANE_PARENT_LIST = 'gund',
	PLANE_PARENT_ITEM = 'jia1',
	ITEM_PARENT_NAME = 'w4',
	ITEM_PARENT_SCORE = 'jiaf',
	PLANE_START_BUT = 'kais',
	PLANE_START_SLIVER = 'yinb',
	
	PLANE_RULE_LABEL = 'hei/gui',
	
	PLANE_WARNING_1 = 'hei/s1',
	PLANE_WARNING_2 = 'hei/s2',
	PLANE_WARNING_3 = 'hei/s3',
	PLANE_ASK_VOTE_SCORE = 'piao',
	PLANE_STAGE_1 = '2',
	PLANE_STAGE_2 = '2',
	PLANE_STAGE_3 = '3',
	PLANE_STAGE_4 = '4',
	PLANE_STAGE_5 = '5',
	PLANE_TIMER = 'daojis',
	PLANE_ASK_VOTE_BUT = 'Button_155',
}

local _mingchi = '名'
local worldmatch_stage_teacher = uikits.SceneClass("worldmatch_stage_teacher",ui)

function worldmatch_stage_teacher:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		uikits.event(uikits.child(self._root,ui.RULE_BUT),function(sender)
			uikits.pushScene( require "hitmouse2/shijiegui".create(self._arg) )
		end)
		uikits.event(uikits.child(self._root,ui.WATCH_BUT),function(sender)
			self._arg._isteacher = true
			uikits.pushScene( require "hitmouse2/worldmatch_level".create(self._arg) )
		end)
		uikits.event(uikits.child(self._root,ui.CUP_BUT),function(sender)
			self._arg._isteacher = true
			uikits.pushScene( require "hitmouse2/worldmatch_cup".create(self._arg) )
		end)		
		self._watch_plane = uikits.child(self._root,ui.WATCH_PLANE)
		self._vote_plane = uikits.child(self._root,ui.VOTE_PLANE)
		self._watch_plane2 = uikits.child(self._root,ui.WATCH_PLANE2)
		self._top_plane = uikits.child(self._root,ui.TOP_PLANE)
		
		self._watch_plane:setVisible(false)
		self._vote_plane:setVisible(false)
		self._watch_plane2:setVisible(false)
		self._top_plane:setVisible(false)
		self:initData()
	end
end

function worldmatch_stage_teacher:initData()
	local send_data = {v1=self._arg.worldmatch_id}
	kits.log("do worldmatch_stage_teacher:initData...("..tostring(self._arg.worldmatch_id)..")")
	http.post_data(self._root,'worldsub_detail',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_stage_teacher:initData success!")
			http.logTable(v,1)
			self._data = v
			self._arg._data = v
			if v and type(v)=='table' then
				if v.v6==1 or v.v6==3 then
					if v.v2>1 then
						self._watch_plane2:setVisible(true)
						self:initPlayerList(self._watch_plane2)
						self:initPlane(self._watch_plane2)
					else
						self._watch_plane:setVisible(true)
						self:initPlayerList(self._watch_plane)
						self:initPlane(self._watch_plane)
					end
				elseif v.v6==2 or v.v6==4 then
					self._vote_plane:setVisible(true)
					self:initPlayerList(self._vote_plane)
					self:initPlane(self._vote_plane)					
				elseif v.v6==5 then
					self._top_plane:setVisible(true)
					self:initTops()
				else
					kits.log("ERROR worldsub_detail v.v6="..tostring(v.v6))
				end
			else
				kits.log("ERROR worldsub_detail return invalid value")
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

function worldmatch_stage_teacher:initPlane(parent)
	local plane = uikits.child(parent,ui.PLANE)
	setString(plane,ui.PLANE_PLAYER_COUNT,self._data.v8)
	setString(plane,ui.PLANE_MYSTUDENT_COUNT,self._data.v9)
	setString(plane,ui.PLANE_RULE_LABEL,self._data.v4)
	setString(plane,ui.PLANE_MYSTUDENT_JJ_COUNT,self._data.v10)
	
	local stages = {}
	local stage1 = uikits.child(plane,ui.PLANE_STAGE_1)
	if stage1 then
		table.insert(stages,stage1)
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_2))
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_3))
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_4))
		table.insert(stages,uikits.child(plane,ui.PLANE_STAGE_5))
		for i=1,5 do
			stages[i]:setVisible(false)
		end
		local show = {}
		if self._data.v1 == 2 then
			table.insert(show,1)
			table.insert(show,5)
		elseif self._data.v1 == 3 then
			table.insert(show,1)
			table.insert(show,2)
			table.insert(show,5)			
		elseif self._data.v1 == 4 then
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
		if self._data.v2 and show[self._data.v2] then
			stages[show[self._data.v2]]:setVisible(true)
		end
	end
	--timer
	local timer = uikits.child(plane,ui.PLANE_TIMER)
	if timer then
		if self._data.v5 then
			state.timer(timer,self._data.v5)
		else
			timer:setString('-')
		end
	end
end

function worldmatch_stage_teacher:initPlayerList(parent)
	local scrollview = uikits.scrollex(parent,ui.LIST,{ui.ITEM})
	for i,v in pairs(self._data.v7) do
		local item = scrollview:additem(1)
		setString(item,ui.ITEM_NAME,v.name or '-')
		http.load_logo_pic(uikits.child(item,ui.ITEM_TOPS_LOGO),v.uid or 0)

		setString(item,ui.ITEM_SCHOOL,v.school or '-')
		setString(item,ui.ITEM_CLASS,v.classname or '-')
		setString(item,ui.ITEM_RANK,v.rank or '-')

		local score = uikits.child(item,ui.ITEM_SCORE)
		local vote = uikits.child(item,ui.ITEM_ASK_VOTE)
		local vote_score = uikits.child(item,ui.ITEM_ASK_VOTE_SCORE)
		local parent_score = uikits.child(item,ui.ITEM_PARENT_SCORE1)
		if score then
			score:setString(v.score or '-')
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
		local but = uikits.child(item,ui.ITEM_ASK_VOTE_BUT)
		if but then
			uikits.event(but,function(sender)
				self:do_vote(v.name,v.classname,v.school,
					v.vote,self._arg.worldmatch_id,v.uid,
					0) --领导不能投票票
			end)
		end
	end
	scrollview:relayout_colume(3,0,20,0)
end

function worldmatch_stage_teacher:do_vote(n,c,s,v,w,u,m)
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
			isteacher = 1,
		})
	end
end

function worldmatch_stage_teacher:initTops()
	local scrollview = uikits.scrollex(self._root,ui.LIST_TOPS,{ui.ITEM_TOPS},{ui.ITEM_TOPS_TOP})
	for i,v in pairs(self._data.v7) do
		local item = scrollview:additem(1)
		scrollview._list[#scrollview._list] = nil
		table.insert(scrollview._list,1,item)
	
		uikits.child(item,ui.ITEM_TOPS_NAME):setString(v.name or '-')
		http.load_logo_pic(uikits.child(item,ui.ITEM_TOPS_LOGO),v.uid or 0)
		uikits.child(item,ui.ITEM_TOPS_SCHOOL):setString(v.school or '-')
		uikits.child(item,ui.ITEM_TOPS_CLASS):setString(v.classname or '-')
		uikits.child(item,ui.ITEM_TOPS_TOTAL_SCORE):setString(v.total_score or '-')
		uikits.child(item,ui.ITEM_TOPS_TOTAL_ASK_VOTE):setString(v.total_vote or '-')
		uikits.child(item,ui.ITEM_TOPS_RANK):setString(v.rank or '-')
	end
	local no_rank = uikits.child(scrollview._tops[1],ui.ITEM_TOPS_TOP_NO_RANK)
	local rank = uikits.child(scrollview._tops[1],ui.ITEM_TOPS_TOP_RANK)
	local rank_label = uikits.child(scrollview._tops[1],ui.ITEM_TOPS_TOP_LABEL)
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
	scrollview:relayout()
end

function worldmatch_stage_teacher:release()
end

return worldmatch_stage_teacher