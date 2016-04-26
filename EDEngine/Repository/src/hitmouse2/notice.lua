local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse2/level"
local music = require "hitmouse2/music"
local http = require "hitmouse2/hitconfig"

local ui = {
	FILE = 'hitmouse2/xiaoxi.json',
	FILE_3_4 = 'hitmouse2/xiaoxi43.json',
	BACK = 'ding/fan',
	LIST = 'gun',
	ITEM = 'x1',
	ITEM_TITLE = 'w1',
	ITEM_TIME = 'w2',
	ITEM_TEXT = 'w3',
}

local notice = uikits.SceneClass("notice")

function notice:init()
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
		self._scrollview = uikits.scroll(self._root,ui.LIST,ui.ITEM)
		uikits.enableMouseWheelIFWindows(self._scrollview)
		self._curPage = 1
		uikits.event(self._scrollview._scrollview,function(sender,state)
			if state == ccui.ScrollviewEventType.scrollToBottom then
				if not self._done_loading and self._tatolPags and self._curPage < self._tatolPags then
					self._curPage = self._curPage + 1
					kits.log("continue loading...")
					self:initNotices(self._curPage)
					self._done_loading = true
				end
			end
		end)		
		self:initNotices(self._curPage)
	end
end

function notice:initNotices(cur)
	local send_data = {v1=cur,v2=12}
	http.post_data(self._root,'get_msg',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v)
			self._scrollview:relayout()
			if v.v2 then
				self._tatolPags = self._tatolPags or v.v2
			else
				kits.log("ERROR tops:initNotices get_msg v.v2 = nil")
			end
			if v.v1 then
				for k,u in pairs(v.v1) do
					local item = self._scrollview:additem()
					uikits.child(item,ui.ITEM_TITLE):setString(u.msg_title or "?")
					uikits.child(item,ui.ITEM_TIME):setString(u.add_time or "?")
					uikits.child(item,ui.ITEM_TEXT):setString(u.msg_info or "?")
				end
			else
				kits.log("ERROR tops:initNotices get_msg v.v1 = nil")
			end
			self._scrollview:relayout()
		else
			http.messagebox(self._root,http.DOWLOAD_ERROR,function(e)
				if e==http.RETRY then
					self:initNotices(cur)
				else
					uikits.popScene()
				end
			end)				
		end
		self._done_loading = nil
	end)
end

function notice:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return notice