local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/jiluLAO.json',
	FILE_3_4 = 'hitmouse2/jiluLAO43.json',
	designWidth = 1920,
	designHeight = 1080,
	BACK = 'ding/fan',
	LIST = 'leib',
	ITEM = 'ji1',
	NAME = 'mingz',
	MEMO = 'fab',
	CAPTION = 'saim',
	DATE = 'shij',
	COUNT = 'rens',
	LOGO = 'toux',
	TOP_BUT = 'cha',
	TOP_PLANE = 'xiangqing',
	TOP_LIST = 'paim',
	TOP_ITEM = 'ren1', --叫黄强去掉wod
	TOP_STAGE = 'qieh',
	TOP_STAGE_BASE = 'xian/s',
	TOP_RANK = 'mc',
	TOP_LOGO = 'toux',
	TOP_NAME = 'mz',
	TOP_CLASS = 'bj',
	TOP_SCORE = 'df',
	TOP_PARENT_SCORE = 'df2',
	TOP_TOTAL_SCORE = 'defen',
}

local worldmatch_teacher_log = uikits.SceneClass("worldmatch_teacher_log",ui)

function worldmatch_teacher_log:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			if not self._worldmatch_id then
				uikits.popScene()
			else
				self._worldmatch_id = nil
				self._scrollview._scrollview:setVisible(true)
				self._plane:setVisible(false)		
			end
		end)
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM})
		self._scrollview:clear()
		self._scrollview:relayout()
		
		self._plane = uikits.child(self._root,ui.TOP_PLANE)
		self._scrollview._scrollview:setVisible(true)
		self._plane:setVisible(false)
		
		self._stages = {}
		self._top_plane = uikits.child(self._plane,ui.TOP_STAGE)
		for i=1,5 do
			table.insert(self._stages,ui.TOP_STAGE_BASE..i)
		end
		
		self._topsview = uikits.scrollex(self._plane,ui.TOP_LIST,{ui.TOP_ITEM})
		self._topsview:clear()
		self._topsview:relayout()
		self:initData()
	end
end

function worldmatch_teacher_log:initData()
	local send_data = {}
	kits.log("do worldmatch_teacher_log:initData...")
	http.post_data(self._root,'worldcup_history_list',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_teacher_log:initData success!")
			http.logTable(v,1)
			if v and type(v)=='table' and v.v1 and v.v2 then
				for i,s in pairs(v.v2) do
					self:additem(s)
				end
				self._scrollview:relayout()
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

function worldmatch_teacher_log:additem(v)
	local item = self._scrollview:additem(1)
	uikits.child(item,ui.NAME):setString(v.pubuser or '-')
	uikits.child(item,ui.MEMO):setString(v.pubuser_meno or '-')
	uikits.child(item,ui.CAPTION):setString(v.caption or '-')
	uikits.child(item,ui.DATE):setString(v.date or '-')
	uikits.child(item,ui.COUNT):setString(v.player_count or '-')
	uikits.event(uikits.child(item,ui.TOP_BUT),function(sender)
		self._worldmatch_id = v.worldmatch_id
		self._match_level_count = v.match_level_count
		self:initTops()
	end)
	http.load_logo_pic(uikits.child(item,ui.LOGO),v.uid or 0)
end

function worldmatch_teacher_log:initTops()
	self._scrollview._scrollview:setVisible(false)
	self._plane:setVisible(true)
	local show = {}
	
	if self._match_level_count == 2 then
		table.insert(show,1)
		table.insert(show,5)
	elseif self._match_level_count == 3 then
		table.insert(show,1)
		table.insert(show,2)	
		table.insert(show,5)	
	elseif self._match_level_count == 4 then
		table.insert(show,1)
		table.insert(show,2)	
		table.insert(show,3)
		table.insert(show,5)		
	elseif self._match_level_count == 5 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,4)
		table.insert(show,5)
	end
	for i=1,5 do
		uikits.child(self._top_plane,self._stages[i]):setVisible(false)
	end
	local tabs = {}
	for i,v in pairs(show) do
		table.insert(tabs,self._stages[v])
		uikits.child(self._top_plane,self._stages[v]):setVisible(true)
	end
	state.tab(self._top_plane,tabs,function(i)
		self:showTops(i)
	end)
end

function worldmatch_teacher_log:showTops(cur)
	self._topsview:clear()
	self._topsview:relayout()
		
	local send_data = 
	{
		v1 = self._worldmatch_id,
		v2 = cur
	}
	kits.log("do worldmatch_teacher_log:showTops...")
	http.post_data(self._root,'worldcup_tops',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_teacher_log:showTops success!")
			http.logTable(v,1)
			if v and type(v)=='table'  then
				for i,s in pairs(v) do
					self:additem2(s)
				end
				self._topsview:relayout()
			end
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:showTops()
				else
					uikits.popScene()
				end
			end,v)	
		end
	end)
end

function worldmatch_teacher_log:additem2(v)
	local item = self._topsview:additem(1)
	self._topsview._list[#self._topsview._list] = nil
	table.insert(self._topsview._list,1,item)
	uikits.child(item,ui.TOP_RANK):setString(v.rank or '-')
	uikits.child(item,ui.TOP_NAME):setString(v.name or '-')
	uikits.child(item,ui.TOP_CLASS):setString(v.classname or '-')
	uikits.child(item,ui.TOP_SCORE):setString(v.integral or '-')
	uikits.child(item,ui.TOP_PARENT_SCORE):setString(v.Parent_integral or '-')
	uikits.child(item,ui.TOP_TOTAL_SCORE):setString(v.Sum_integral or '-')
	http.load_logo_pic(uikits.child(item,ui.TOP_LOGO),v.uid or 0)
end

function worldmatch_teacher_log:release()
end

return worldmatch_teacher_log