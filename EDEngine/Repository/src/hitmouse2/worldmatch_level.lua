local kits = require "kits"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/shijiecheng.json',
	FILE_3_4 = 'hitmouse2/shijiecheng43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	LIST = 'cheng',
	ITEM_CAPTION = 'bism',
	ITEM = 'sai1',
	CAPTION = 'shaim',
	DATE = 'shijian',
	ITEM_DATE = 'shij',
	ITEM_DATE2 = 'shij2',
	STAGE = 's',
	LABEL = 'w4',
	LABEL2 = 'w2',
	DURING = 'daoji',
}

local worldmatch_level = uikits.SceneClass("worldmatch_level",ui)

function worldmatch_level:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		if self._arg then
			local scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM},{ui.ITEM_CAPTION})
			uikits.child(scrollview._tops[1],ui.CAPTION):setString(self._arg.caption or '-' )
			uikits.child(scrollview._tops[1],ui.DATE):setString(self._arg.date)
			local data
			if self._arg._isteacher then
				data = self._arg._data.v11
			else
				data = self._arg._data.v15
			end
			http.logTable(data,1)
				
			if self._arg._data and data and type(data)=='table' then
				local count = #data
				local show = {}
				if count == 2 then
					table.insert(show,1)
					table.insert(show,5)
				elseif count == 3 then
					table.insert(show,1)
					table.insert(show,2)
					table.insert(show,5)			
				elseif count == 4 then
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

				if data and type(data)=='table' then
					for i = 1, count do
						local v = data[i]
						local item = scrollview:additem(1)
						scrollview._list[#scrollview._list] = nil
						table.insert(scrollview._list,1,item)
						uikits.child(item,ui.ITEM_DATE):setString(v.date or '-')
						uikits.child(item,ui.ITEM_DATE2):setString(v.date2 or '-')
						local stages = {}
						for k=1,5 do
							table.insert(stages,uikits.child(item,ui.STAGE..k))
						end
						for k=1,5 do
							stages[k]:setVisible(false)
						end
						if stages[show[i]] then
							stages[show[i]]:setVisible(true)
						end
						if v.state==3 then
							uikits.child(item,ui.LABEL):setString("该轮结束")
						elseif v.state==1 then
							uikits.child(item,ui.LABEL):setString("比赛进行中")
						elseif v.state==2 then
							uikits.child(item,ui.LABEL):setString("投票阶段")
						elseif v.during_second and v.during_second>0 then
							uikits.child(item,ui.LABEL):setVisible(false)
							uikits.child(item,ui.LABEL2):setVisible(true)
							uikits.child(item,ui.DURING):setVisible(true)
							uikits.child(item,ui.DURING):setString(kits.time_to_string_simple(v.during_second))
						else
							uikits.child(item,ui.LABEL):setString("-")
						end
					end
				end
			end
			scrollview:relayout()
			uikits.enableMouseWheelIFWindows(scrollview)
		else
			uikits.child(self._root,ui.CAPTION):setString("-")
			uikits.child(self._root,ui.DATE):setString("-")
		end
	end
end

function worldmatch_level:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return worldmatch_level