require "AudioEngine" 
local kits = require "kits"
local music = require "hitmouse2/music"
local uikits = require "uikits"
local state = require "hitmouse2/state"
local http = require "hitmouse2/hitconfig"
local global = require "hitmouse2/global"
local login = require "login"

local ui = {
	FILE = 'hitmouse2/zibo2.json',
	FILE_3_4 = 'hitmouse2/zibo243.json',
	BACK = 'ding/fan',
	LIST = 'gun',
	ITEM = 'ren1',
	NAME = 'mz',
	SCORE = 'defen',
	SCORE_RANK = 'mc',
	LOGO = 'toux',
	SCHOOL = 'bj',
}

local zibotop = uikits.SceneClass("zibotop")

function zibotop:init(b)
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
		self._curPage = 1		
		uikits.event(self._scrollview._scrollview,function(sender,state)
			if state == ccui.ScrollviewEventType.scrollToBottom then
				if not self._done_loading and self._tatolPags and self._curPage < self._tatolPags then
					self._curPage = self._curPage + 1
					kits.log("continue loading...")
					self:initTops(self._curPage,self._currentParam)
					self._done_loading = true
				end
			end
		end)
		uikits.enableMouseWheelIFWindows(self._scrollview)		
		self:initTops(1)
	end
end

function zibotop:initTops(cur,className)
	if cur==1 then
		self._scrollview._scrollview:jumpToTop()
	end
	local send_data = {V1=1,V2=4,V3=cur,V4=18,V5=className or ""}
	http.post_data(self._root,'road_block_rank_zibo',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v)
			if v.v1 then
				for i,u in pairs(v.v1) do
					local item = self._scrollview:additem()
					if u.user_id==login.uid() then
						item:setBackGroundColor(cc.c3b(3, 12, 21))
					end
					http.load_logo_pic(uikits.child(item,ui.LOGO),u.user_id or 0)
					uikits.child(item,ui.NAME):setString(u.uname or "?")
					--uikits.child(item,ui.USETIME):setString(u.str_times or "?")
					uikits.child(item,ui.SCORE):setString(u.integral or "?")
					--uikits.child(item,ui.SCORE_PARENT):setString(u.parent_integral or "?")
					uikits.child(item,ui.SCORE_RANK):setString(u.rank or "?")
					uikits.child(item,ui.SCHOOL):setString(u.user_zone or "?")
					--[[
					if u.integral and u.parent_integral then
						uikits.child(item,ui.SCORE_TOTAL):setString(u.integral+u.parent_integral)
					else
						uikits.child(item,ui.SCORE_TOTAL):setString("?")
					end
					--]]
				end
			else
				kits.log("ERROR tops:initTops road_block_rank_zibo v.v1 = nil")
			end
			self._scrollview:relayout()
			if v.v2 then
				self._tatolPags = self._tatolPags or v.v2
			else
				kits.log("ERROR tops:initTops road_block_rank_zibo v.v2 = nil")
			end		
		else
			http.messagebox(self._root,http.DIY_MSG,function(e)
				if e==http.RETRY then
					self:initTops(cur,className)
				else
					uikits.popScene()
				end
			end,v)				
		end
		self._done_loading = nil
	end)
end

function zibotop:release()
	uikits.popKeyboardListener()
end

return zibotop