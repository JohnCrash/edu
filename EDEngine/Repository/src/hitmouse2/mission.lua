local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/renwu.json',
	FILE_3_4 = 'hitmouse2/renwu43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	LIST = 'leib',
	ITEM = 'rw1',
	TOP = 'suju',
	DONE = 'meiyou',
	MISSION_COUNT = 'zsai',
	ACC_COUNT = 'jues',
	DONE_COUNT = 'guanc',
	TAKE_SLIVER = 'yinb',
	TAKE_BUT = 'lj',
	LABEL = 'w1',
	MISSION_BUT = 'ks',
}

local mission = uikits.SceneClass("mission",ui)

function mission:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		self._scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM},{ui.TOP})		
		
		self:initData()
	end
end

function mission:initData()
	local send_data = {}
	kits.log("do mission:init...")
	self._scrollview:clear()
	http.post_data(self._root,'get_task_list',send_data,function(t,v)
		if t and t==200 and v then
			kits.log("loading get_task_list success!")
			http.logTable(v,1)
			self:setTitle(v.v1,v.v2)
			for i,v in pairs(v.v3) do
				self:additem(v)
			end
			self._scrollview:relayout()
			if v.v3 and #v.v3== 0 and self._arg then
				self._arg.hasMission = false
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
	end,true)
	self:setTitle("","")
end

function mission:setTitle(c,a)
	local tops = self._scrollview._tops[1]
	uikits.child(tops,ui.MISSION_COUNT):setString(c or "-")
	uikits.child(tops,ui.ACC_COUNT):setString(a or "-")
end

function mission:getAward(taskid,button,item)
	local send_data = {v1=taskid}
	kits.log("do mission:getAward...")
	http.post_data(self._root,'get_task_award',send_data,function(t,v)
			if t and t==200 and v then
				http.logTable(v,1)
				if v.v1 and v.v2 then
					state.set_sliver(v.v2)
					button:setSelectedState(false)
					button:setEnabled(false)
					state.playSound('gold.mp3')
					self:initData()
--					self._scrollview:remove(item)
--					item:removeFromParent()
--					self._scrollview:relayout()
					if self._scrollview._list and #self._scrollview._list==0 then
						if self._arg then
							self._arg.hasMission = false
						end
					end
				else
					kits.log("ERROR get_task_award v1 or v2 = nil")
				end
			else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e == http.RETRY then
					self:getAward(taskid)
				else
					uikits.popScene()
				end
			end,v)	
		end
	end,true)
end

function mission:doMission( task_id )
	local send_data = {v1=task_id,v2=4,v3=1,v4=false,v5=0}
	http.post_data(self._root,'get_new_match',send_data,function(t,v)
			if t and t==200 and v then
			--	http.logTable(v,1)
				if v.v1 then
					v.v5.threshold = v.v6
					v.v5.condition = v.v6
					v.v5.type = 4
					v.v5.level = task_id
					local battle = require "hitmouse2/battle"
					uikits.replaceScene(battle.create(v.v5))			
				else
					http.messagebox(self._root,http.OK_MSG,function(e)
					end,tostring(v.v2 or 'get_new_match return v.v2 = nil'))
				end			
			else
				http.messagebox(self._root,http.DIY_MSG,function(e)
					if e == http.RETRY then
						self.doMission( task_id )
					else
						uikits.popScene()
					end
				end,v)		
			 end
		end)
end

function mission:additem(v)
	local item = self._scrollview:additem(1)
	uikits.child(item,ui.DONE_COUNT):setString(v.Task_param or '-')
	uikits.child(item,ui.TAKE_SLIVER):setString(v.Task_award or '-')
	local mission_but = uikits.child(item,ui.MISSION_BUT)
	local but = uikits.child(item,ui.TAKE_BUT)
	mission_but:setVisible(false)
	if v.Task_type==1 then
	elseif v.Task_type==2 then
		if not v.Task_where then
			mission_but:setVisible(true)
			but:setVisible(false)
			uikits.event(mission_but,function(sender)
				self:doMission(v.task_id)
			end)
		end
		uikits.child(item,ui.LABEL):setString("错题任务：")
	end
	if v.Task_where then
		but:setVisible(true)
		but:setEnabled(true)
		but:setSelectedState(true)
		uikits.event(but,function(sender)
			but:setSelectedState(true)
			self:getAward(v.task_id,but,item)
		end)
	else
		but:setEnabled(false)
		but:setSelectedState(false)
	end
end

function mission:release()
end

return mission