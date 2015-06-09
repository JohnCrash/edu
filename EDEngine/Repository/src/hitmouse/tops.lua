local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local level = require "hitmouse/level"
local http = require "hitmouse/hitconfig"

local ui = {
	FILE = 'hitmouse/paihang.json',
	FILE_3_4 = 'hitmouse/paihang43.json',
	BACK = 'ding/fan',
	LIST = 'p',
	ITEM = 'ren',
}

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

function tops:init()
	self._ss = cc.size(1920,1080);
	uikits.initDR{width=self._ss.width,height=self._ss.height}
	if not self._root then
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		self:addChild(self._root)
		uikits.event(uikits.child(self._root,ui.BACK),function(sender)
			uikits.popScene()
		end)
		self._scrollview = uikits.scroll(self._root,ui.LIST,ui.ITEM)
		local send_data = {V1=1,V2=1,V3=1,V4=24}
		http.post_data(self._root,'road_block_rank',send_data,function(t,v)
			if t and t==200 then
				pt(v)
				for i=1,15 do
					self._scrollview:additem()
				end
				self._scrollview:relayout()
			else
				http.messagebox(self._root,http.NETWORK_ERROR,function(e)
				end)				
			end
		end)
	end
end

function tops:release()
	
end

return tops