local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"

local local_dir = kits.get_local_directory()..'res/'

local ui = {
	FILE = 'hitmouse2/shijiejiang.json',
	FILE_3_4 = 'hitmouse2/shijiejiang43.json',
	designWidth = 1920,
	designHeight = 1080,	
	BACK = 'ding/fan',
	LIST = 'jiangx',
	TOP = 'bism',
	ITEM = 'jiang1',
	TOP_CAPTION = 'shaim',
	
	TOP_DATE = 'shijian',
	ITEM_NAME = 'shaim',
	ITEM_AWARD_COUNT = 'rens',
	ITEM_CUP = 'jiang',
	ITEM_TU = 'wup',
	ITEM_BUTTON = 'wup/tu',
	ITEM_TEXT = 'wup/wen',
}

local worldmatch_cup = uikits.SceneClass("worldmatch_cup",ui)

function worldmatch_cup:init(b)
	if b then
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		local scrollview = uikits.scrollex(self._root,ui.LIST,{ui.ITEM},{ui.TOP})
		if self._arg  then
			uikits.child(scrollview._tops[1],ui.TOP_CAPTION):setString(self._arg.caption or '-')
			uikits.child(scrollview._tops[1],ui.TOP_DATE):setString(self._arg.date or '-')
			local data
			if self._arg._isteacher then
				data = self._arg._data.v12
			else
				data = self._arg._data.v16
			end
			http.logTable(data,1)
			if self._arg._data and data and type(data)=='table' then
				local count = #data
				local imgfiles = {}
				for i=1,count do
					local v = data[count-i+1]
					local item = scrollview:additem(1)
					uikits.child(item,ui.ITEM_NAME):setString(v.name or '-')
					if v.award then
						uikits.child(item,ui.ITEM_CUP):setVisible(true)
					else
						uikits.child(item,ui.ITEM_CUP):setVisible(false)
					end
					
					local label = uikits.child(item,ui.ITEM_AWARD_COUNT)
					if label then
						label:setString((v.awardcount or '-').."名")
					end
					
					local image_item = uikits.child(item,ui.ITEM_TU)
					if v.image_url and string.len(v.image_url) > 0 then
						image_item:setVisible(true)
						http.load_image( image_item,v.image_url )
					else
						image_item:setVisible(false)
					end
					if v.image_url and string.len(v.image_url)>0 then
						local file = kits.get_cache_path()..tostring(cache.get_name(v.image_url))
						table.insert(imgfiles,1,file)
						local preview_but = uikits.child(item,ui.ITEM_BUTTON)
						uikits.event(preview_but,function(sender)
							local imagepreview = require "hitmouse2/imagepreview"
							uikits.pushScene( imagepreview.create(count-i+1,imgfiles) )
						end)
					end
				end
			end
		end
		scrollview:relayout()
		uikits.enableMouseWheelIFWindows(scrollview)
	end
end

function worldmatch_cup:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return worldmatch_cup