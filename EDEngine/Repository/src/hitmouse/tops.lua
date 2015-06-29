local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse/level"
local http = require "hitmouse/hitconfig"
local global = require "hitmouse/global"

local ui = {
	FILE = 'hitmouse/paihang.json',
	FILE_3_4 = 'hitmouse/paihang43.json',
	BACK = 'ding/fan',
	CAPTION = 'ding/wen',
	LIST = 'p',
	ITEM = 'ren',
	LOGO = 'touxiang',
	NAME = 'ming',
	USETIME = 'sj',
	SCORE = 'df',
	SCORE_PARENT = 'df2',
	SCORE_TOTAL = 'zdf',
	CLASS_CAPTION = 'ding/Label_10',
	NEXT_CLASS_BUTTON = 'ding/Button_11',
	PREV_CLASS_BUTTON = 'ding/Button_12',
}

local tops = uikits.SceneClass("tops")
--[[
local tops = class("tops")
tops.__index = tops

function tops.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),tops)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end
--]]
function tops:init()
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
		uikits.event(self._scrollview._scrollview,function(sender,state)
			if state == ccui.ScrollviewEventType.scrollToBottom then
				if not self._done_loading and self._tatolPags and self._curPage < self._tatolPags then
					self._curPage = self._curPage + 1
					kits.log("continue loading...")
					self:initTops(self._curPage)
					self._done_loading = true
				end
			end
		end)
		uikits.enableMouseWheelIFWindows(self._scrollview)
		self._curPage = 1
		self:initTops(self._curPage)
		self._next_but = uikits.child(self._root,ui.NEXT_CLASS_BUTTON)
		self._prev_but = uikits.child(self._root,ui.PREV_CLASS_BUTTON)
		self._calss_title = uikits.child(self._root,ui.CLASS_CAPTION)
		self._next_but:setVisible(false)
		self._prev_but:setVisible(false)
		self._calss_title:setVisible(false)
		self._calss_title:setString("")
		if http.get_id_flag()==http.ID_FLAG_TEA or 
			http.get_id_flag()==http.ID_FLAG_SCH or 
			http.get_id_flag()==http.ID_FLAG_PRA then
			local v
			if http.get_id_flag()==http.ID_FLAG_PRA then
				v = global.getChildInfo()
			else
				v = global.getTeacherClass()
			end
			if v then
				http.logTable(v)
				if v.v1 and v.v2 and #v.v2>1 then
					self._next_but:setVisible(true)
					self._prev_but:setVisible(true)
					self._calss_title:setVisible(true)
					local idx = 1
					uikits.event(self._next_but,function(sender)
						idx=idx+1
						if not v.v2[idx] then
							idx=1
						end
						self._scrollview:clear()
						self._curPage = 1
						self:initTops(self._curPage,v.v2[idx].uid or v.v2[idx])
					end)
					uikits.event(self._prev_but,function(sender)
						idx=idx-1
						if not v.v2[idx] then
							idx=#v.v2
						end
						self._scrollview:clear()
						self._curPage = 1
						self:initTops(self._curPage,v.v2[idx].uid or v.v2[idx])
					end)						
				end
			else
				kits.log("ERROR get_teacherclass failed~")
			end
		end
	end
end

function tops:initTops(cur,className)
	local send_data = {V1=1,V2=1,V3=cur,V4=18,V5=className or ""}
	http.post_data(self._root,'road_block_rank',send_data,function(t,v)
		if t and t==200 and v then
			http.logTable(v)
			if v.v1 then
				for i,u in pairs(v.v1) do
					local item = self._scrollview:additem()
					http.load_logo_pic(uikits.child(item,ui.LOGO),u.user_id or 0)
					uikits.child(item,ui.NAME):setString(u.uname or "?")
					uikits.child(item,ui.USETIME):setString(u.str_times or "?")
					uikits.child(item,ui.SCORE):setString(u.integral or "?")
					uikits.child(item,ui.SCORE_PARENT):setString(u.parent_integral or "?")
					if u.integral and u.parent_integral then
						uikits.child(item,ui.SCORE_TOTAL):setString(u.integral+u.parent_integral)
					else
						uikits.child(item,ui.SCORE_TOTAL):setString("?")
					end
				end
			else
				kits.log("ERROR tops:initTops road_block_rank v.v1 = nil")
			end
			self._scrollview:relayout()
			if v.v2 then
				self._tatolPags = self._tatolPags or v.v2
			else
				kits.log("ERROR tops:initTops road_block_rank v.v2 = nil")
			end
			if v.v3 and not self._caption_flag then
				self._calss_title:setString(tostring(v.v3))
			elseif not v.v3 then
				kits.log("ERROR tops:initTops road_block_rank v.v3 = nil")
			end			
		else
			http.messagebox(self._root,http.DOWNLOAD_ERROR,function(e)
				if e==http.RETRY then
					self:initTops(cur,className)
				else
					uikits.popScene()
				end
			end)				
		end
		self._done_loading = nil
	end)
end

function tops:release()
	uikits.enableMouseWheelIFWindows(nil)
end

return tops