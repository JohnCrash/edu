local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Leitaihistory = class("Leitaihistory")
Leitaihistory.__index = Leitaihistory
local ui = {
	Leitaihistory_FILE = 'poetrymatch/wangqihg.json',
	Leitaihistory_FILE_3_4 = 'poetrymatch/wangqihg.json',
	VIEW_HISTORY = 'gun',
	VIEW_PER_HISTORY = 'gun/leit1',
	TXT_TITLE = 'leitbt',
	TXT_DATE = 'sj',
	TXT_SCORE = 'pm',
	TXT_ROUND = 'huih',
	TXT_RIGHT = 'zhengq',
	TXT_TIME = 'yongs',
	TXT_RANK = 'mc',

	VIEW_HISTORY_NO = 'meiyou',
	
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Leitaihistory)		

	scene:addChild(cur_layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			cur_layer:init()
		elseif "exit" == event then			
			cur_layer:release()
		end
	end	
	cur_layer:registerScriptHandler(onNodeEvent)
	return scene	
end

function Leitaihistory:show_info(rank_info)

	local view_history_no = uikits.child(self._Leitaihistory,ui.VIEW_HISTORY_NO)
	local view_history = uikits.child(self._Leitaihistory,ui.VIEW_HISTORY)
	view_history_no:setVisible(false)
	view_history:setVisible(false)

	local view_person_src = uikits.child(self._Leitaihistory,ui.VIEW_PER_HISTORY)
	local viewSize=view_history:getContentSize()
	local viewPosition=cc.p(view_history:getPosition())
	local viewParent=view_history:getParent()
	view_history:setVisible(false)	
	if rank_info and type(rank_info) == 'table' then
		--view_history:setVisible(true)
		local view_person_rank1=person_info.createRankView(viewParent,viewPosition,viewSize,view_person_src,function(item,data)
			local txt_rank = uikits.child(item,ui.TXT_RANK)	 
			local txt_title = uikits.child(item,ui.TXT_TITLE)	
			local txt_date = uikits.child(item,ui.TXT_DATE)	
			local txt_score = uikits.child(item,ui.TXT_SCORE)	
			local txt_round = uikits.child(item,ui.TXT_ROUND)	
			local txt_right = uikits.child(item,ui.TXT_RIGHT)	
			local txt_time = uikits.child(item,ui.TXT_TIME)	
			txt_title:setString(data.defense_name)
			txt_date:setString(data.end_time)
			txt_score:setString(data.score)
			txt_round:setString(data.round_cnt)
			txt_right:setString(data.correct_cnt)
			txt_time:setString(data.times)
			txt_rank:setString(data.rank..'名')
			end,function(waitingNode,afterReflash)
			local data = rank_info
			afterReflash(data)
		end)
	else
		view_history_no:setVisible(true)
	end
end

function Leitaihistory:getdatabyurl()
	local send_data
	person_info.post_data_by_new_form(self._Leitaihistory,'my_defense',send_data,function(t,v)
		if t and t == 200 then
			self:show_info(v)
		else
			person_info.messagebox(self._Leitaihistory,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:getdatabyurl()
				else
					self:getdatabyurl()
				end
			end)
		end
	end)
end

function Leitaihistory:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Leitaihistory = uikits.fromJson{file_9_16=ui.Leitaihistory_FILE,file_3_4=ui.Leitaihistory_FILE_3_4}
	self:addChild(self._Leitaihistory)

	self:getdatabyurl()

	local but_quit = uikits.child(self._Leitaihistory,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function Leitaihistory:release()

end
return {
create = create,
}