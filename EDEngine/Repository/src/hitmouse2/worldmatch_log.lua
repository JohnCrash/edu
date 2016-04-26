local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/shijiechans.json',
	FILE_3_4 = 'hitmouse2/shijiechans43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	LIST = 'leib',
	ITEM = 'ji1',
	ITEM_CAPTION = 'saim',
	ITEM_DATE = 'shij',
	ITEM_PLAYER_COUNT = 'rens',
	ITEM_STAGE = 'xian/s',
	CLOSE_PLANE = 'meiyou',	
}

local worldmatch_log = uikits.SceneClass("worldmatch_log",ui)

function worldmatch_log:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM})
		self._close_plane = uikits.child(self._root,ui.CLOSE_PLANE)
		self._scrollview._scrollview:setVisible(false)
		self._close_plane:setVisible(false)		
		self:initData()		
	end
end

function worldmatch_log:initData()
	local send_data = {}
	kits.log("do worldmatch_log:initData...")
	http.post_data(self._root,'worldcup_history',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch_log:initData success!")
			http.logTable(v,1)
			if v and type(v)=='table' then
				if #v > 0 then
					self._scrollview._scrollview:setVisible(true)
					for i,u in pairs(v) do
						self:additem(u)
					end
					self._scrollview:relayout()
					uikits.enableMouseWheelIFWindows(self._scrollview)
				else
					self._close_plane:setVisible(true)
				end
			else
				kits.log("ERROR worldcup_history return invalid value")
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

function worldmatch_log:additem(v)
	local item = self._scrollview:additem(1)
	uikits.child(item,ui.ITEM_CAPTION):setString(v.caption or '-')
	uikits.child(item,ui.ITEM_DATE):setString(v.date or '-')
	uikits.child(item,ui.ITEM_PLAYER_COUNT):setString(v.player_count or '-')
	
	local stage = {}
	local rank_label = {}
	for i=1,5 do
		local s = uikits.child(item,ui.ITEM_STAGE..i)
		s:setVisible(false)
		table.insert(stage,s)
		local text = uikits.child(item,ui.ITEM_STAGE..i..'/w'..i..'/mingc')
		if text then
			text:setVisible(false)
		end
		text = uikits.child(item,ui.ITEM_STAGE..i..'/w'..i)
		table.insert(rank_label,text)
	end
	local show = {}
	if v.match_level_count == 2 then
		table.insert(show,1)
		table.insert(show,5)
	elseif v.match_level_count == 3 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,5)	
	elseif v.match_level_count == 4 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,5)	
	elseif v.match_level_count == 5 then
		table.insert(show,1)
		table.insert(show,2)
		table.insert(show,3)
		table.insert(show,4)
		table.insert(show,5)	
	else
		kits.log("ERROR worldmatch_stage:additem match_level_count = "..tostring(v.match_level_count))
	end
	for i,k in pairs(show) do
		if v and v.match_stage then
			if i <= v.match_stage then
				stage[k]:setSelectedState(true)
			else
				stage[k]:setSelectedState(false)
			end
			stage[k]:setVisible(true)
			if v.ranks[i] > 0 then
				rank_label[k]:setString('第'..(v.ranks[i] or '-')..'名')
			else
				rank_label[k]:setString('淘汰')
			end
		else
			kits.log("ERROR worldcup_history  match_stage = nil")
		end
	end
end

function worldmatch_log:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return worldmatch_log