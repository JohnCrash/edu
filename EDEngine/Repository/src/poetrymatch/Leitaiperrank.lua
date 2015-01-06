local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Leitaiperrank = class("Leitaiperrank")
Leitaiperrank.__index = Leitaiperrank
local ui = {
	Leitaiperrank_FILE = 'poetrymatch/gerenph.json',
	Leitaiperrank_FILE_3_4 = 'poetrymatch/gerenph.json',
	VIEW_RANK = 'gun',
	VIEW_PER_USER = 'gun/xs',
	PIC_USER = 'xs1/toux',
	TXT_USER_NAME = 'xs1/mz',
	TXT_USER_SCH = 'xs1/xues',
	TXT_USER_RANK = 'xs1/quan/mc',
	TXT_USER_SCORE = 'xs1/defen',
	
	TXT_TITLE = 'xinxi/bt',
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(name,id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Leitaiperrank)		
	cur_layer.title = name
	cur_layer.leitai_id = id

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

function Leitaiperrank:show_info(rank_info)

	local view_person_rank = uikits.child(self._Leitaiperrank,ui.VIEW_RANK)
	local view_person_src = uikits.child(self._Leitaiperrank,ui.VIEW_PER_USER)
	local viewSize=view_person_rank:getContentSize()
	local viewPosition=cc.p(view_person_rank:getPosition())
	local viewParent=view_person_rank:getParent()
	view_person_rank:setVisible(false)	
	if rank_info and type(rank_info) == 'table' then
		local view_person_rank1=person_info.createRankView(viewParent,viewPosition,viewSize,view_person_src,function(item,data)
		
			local pic_user = uikits.child(item,ui.PIC_USER)	
			local txt_rank = uikits.child(item,ui.TXT_USER_RANK)	
			local txt_name = uikits.child(item,ui.TXT_USER_NAME)	
			local txt_score = uikits.child(item,ui.TXT_USER_SCORE)	
			local txt_school_name = uikits.child(item,ui.TXT_USER_SCH)	
			person_info.load_logo_pic(pic_user,data.user_id)
			txt_rank:setString(data.rank)
			txt_name:setString(data.uname)
			txt_score:setString(data.score)
			txt_school_name:setString(data.sch_name)
			
			end,function(waitingNode,afterReflash)
			local data = rank_info
			afterReflash(data)
		end)		
	end
end

function Leitaiperrank:getdatabyurl()
	local send_data = {}
	send_data.v1 = self.leitai_id
	person_info.post_data_by_new_form(self._Leitaiperrank,'get_defense_person_leaderboard',send_data,function(t,v)
		if t and t == 200 then
			self:show_info(v)
		else
			person_info.messagebox(self._Leitaiperrank,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:getdatabyurl()
				else
					self:getdatabyurl()
				end
			end)
		end
	end)
end

function Leitaiperrank:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Leitaiperrank = uikits.fromJson{file_9_16=ui.Leitaiperrank_FILE,file_3_4=ui.Leitaiperrank_FILE_3_4}
	self:addChild(self._Leitaiperrank)
	self:getdatabyurl()
	
	local txt_title = uikits.child(self._Leitaiperrank,ui.TXT_TITLE)
	txt_title:setString(self.title)
	local but_quit = uikits.child(self._Leitaiperrank,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function Leitaiperrank:release()

end
return {
create = create,
}