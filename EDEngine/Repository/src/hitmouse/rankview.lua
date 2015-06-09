local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local hitconfig = require 'hitmouse/hitconfig'

local ui = {
	TEA_FILE = 'hitmouse/xiangqing.json',
	TEA_FILE_3_4 = 'hitmouse/xiangqing43.json',

	STU_FILE = 'hitmouse/xiangqing.json',
	STU_FILE_3_4 = 'hitmouse/xiangqing43.json',
	VIEW_RANK = 'gun',
	VIEW_PER_USER = 'gun/ren1',
	
	BUTTON_QUIT  = 'ding/fan',
}

local rankview = class("rankview")
rankview.__index = rankview

function rankview.create(rank_data)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),rankview)
	layer.rank_data = rank_data
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

function rankview:show_rank()
	local view_rank = uikits.child(self._rankview,ui.VIEW_RANK)
	local view_person_src = uikits.child(self._rankview,ui.VIEW_PER_USER)
	local viewSize=view_rank:getContentSize()
	local viewPosition=cc.p(view_rank:getPosition())
	local viewParent=view_rank:getParent()
	view_rank:setVisible(false)
	if self.rank_data and type(self.rank_data) == 'table' then
		local view_rank = hitconfig.createRankView(viewParent,viewPosition,viewSize,view_person_src,function(item,data)
				
			end,function(waitingNode,afterReflash)
			local data = self.rank_data 
			afterReflash(data)
		end)
	end
end

function rankview:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self.id_flag = hitconfig.get_id_flag()
	if self.id_flag == hitconfig.ID_FLAG_STU then
		self._rankview = uikits.fromJson{file_9_16=ui.STU_FILE,file_3_4=ui.STU_FILE_3_4}	
	else
		self._rankview = uikits.fromJson{file_9_16=ui.TEA_FILE,file_3_4=ui.TEA_FILE_3_4}		
	end
	self:addChild(self._rankview)
	self:show_rank()
	local but_quit = uikits.child(self._rankview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
end

function rankview:release()
	
end

return rankview