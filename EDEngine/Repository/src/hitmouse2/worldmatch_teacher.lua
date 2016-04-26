local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/sjLAO.json',
	FILE_3_4 = 'hitmouse2/sjLAO43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	LOG_BUT = 'ding/chans',
	
	CLOSE_PLANE='meiy',
	LIST = 'you',
	ITEM = 'sj1',
	ENTER_BUT = 'jin',
	ITEM_CAPTION = 'mc',
	ITEM_PUB_NAME = 'mingz',
	ITEM_PUB_MEMO = 'fab',
	ITEM_DATE = 'shij',
	ITEM_STAGE = 'xian/s',
	ITEM_LOGO = 'toux',	
	ITEM2 = 'jia',
	ITEM2_ADD = 'jia',
	ADD_BUT  = 'meiy/tianjia',
}

local worldmatch_teacher = uikits.SceneClass("worldmatch_teacher",ui)

function worldmatch_teacher:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		uikits.event(uikits.child(self._root,ui.LOG_BUT),function(sender)
			uikits.pushScene(require "hitmouse2/worldmatch_teacher_log".create())
		end)		
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM,ui.ITEM2})
		self._close_plane = uikits.child(self._root,ui.CLOSE_PLANE)
	end
	
	if self._scrollview then
		self._scrollview:clear()
		self._scrollview._scrollview:setVisible(false)
		self._close_plane:setVisible(false)
		uikits.event(uikits.child(self._root,ui.ADD_BUT),function(sender)
				local scene = require "hitmouse2/worldmatch_pub"
				uikits.pushScene(scene.create())			
		end)
		self:initData()		
	end
end

function worldmatch_teacher:initData()
	local send_data = {}
	kits.log("do worldmatch:initData...")
	http.post_data(self._root,'worldmatch_list',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading worldmatch:initData success!")
			http.logTable(v,1)
			if v and type(v)=='table' then
				if #v > 0 then
					self._scrollview._scrollview:setVisible(true)
					for i,u in pairs(v) do
						self:additem(u)
					end
					local b = state.get_region()
					if b then
						local item = self._scrollview:additem(2)
						self._scrollview._list[#self._scrollview._list] = nil
						table.insert(self._scrollview._list,1,item)	
						uikits.event( uikits.child(item,ui.ITEM2_ADD) ,function(sender)
							local scene = require "hitmouse2/worldmatch_pub"
							uikits.pushScene(scene.create())					
						end)
					end							
					self._scrollview:relayout_horz()
				else
					local b = state.get_region()
					if b then
						self._close_plane:setVisible(true)
					end
				end
			else
				kits.log("ERROR worldmatch_list return invalid value")
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

function worldmatch_teacher:additem(v)
	local item = self._scrollview:additem(1)
	self._scrollview._list[#self._scrollview._list] = nil
	table.insert(self._scrollview._list,1,item)	
	uikits.child(item,ui.ITEM_CAPTION):setString(v.caption or '-')
	uikits.child(item,ui.ITEM_PUB_NAME):setString(v.pubuser or '-')
	uikits.child(item,ui.ITEM_DATE):setString(v.date or '-')
	uikits.child(item,ui.ITEM_PUB_MEMO):setString(v.pubuser_memo or '-')
	http.load_logo_pic(uikits.child(item,ui.ITEM_LOGO),v.pubuser_uid or 0)
	uikits.event(uikits.child(item,ui.ENTER_BUT),function(sender)
		local scene = require "hitmouse2/worldmatch_stage_teacher".create{caption=v.caption,date=v.date,worldmatch_id=v.worldmatch_id,match_stage=v.match_stage}
		uikits.pushScene(scene)
	end)
	local stage = {}
	for i=1,5 do
		local s = uikits.child(item,ui.ITEM_STAGE..i)
		s:setVisible(false)
		table.insert(stage,s)
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
		kits.log("ERROR worldmatch:additem match_level_count = "..tostring(v.match_level_count))
	end
	for i,k in pairs(show) do
		if i <= v.match_stage then
			stage[k]:setSelectedState(true)
		else
			stage[k]:setSelectedState(false)
		end
		stage[k]:setVisible(true)
	end
end

function worldmatch_teacher:release()
end

return worldmatch_teacher