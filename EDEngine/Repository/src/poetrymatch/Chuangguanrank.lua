local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local person_info = require "poetrymatch/Person_info"

local Chuangguanrank = class("Chuangguanrank")
Chuangguanrank.__index = Chuangguanrank
local ui = {
	Chuangguanrank_FILE = 'poetrymatch/chuanggph.json',
	Chuangguanrank_FILE_3_4 = 'poetrymatch/chuanggph.json',
	
	VIEW_RANK = 'gun',
	VIEW_PER_USER = 'gun/xs',
	PIC_USER = 'xs1/toux',
	TXT_USER_NAME = 'xs1/mz',
	TXT_USER_CLASS = 'xs1/bj',
	TXT_USER_RANK = 'xs1/quan/mc',
	TXT_USER_AP = 'xs1/gongji',
	TXT_USER_LVL = 'xs1/dengji/dengji',
	PRO_USER_EXP = 'xs1/dengji/jidu',
	PIC_BATTLE_CARD = 'xs1/kp1',
	TXT_BATTLE_CARD_LVL = 'dj',
	
	TXT_SCH_NAME = 'xinxi/xuexiao',
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Chuangguanrank)		

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
	
function Chuangguanrank:show_info(rank_info)
	local view_rank = uikits.child(self._Chuangguanrank,ui.VIEW_RANK)
	local view_person_src = uikits.child(self._Chuangguanrank,ui.VIEW_PER_USER)
	local viewSize=view_rank:getContentSize()
	local viewPosition=cc.p(view_rank:getPosition())
	local viewParent=view_rank:getParent()
	view_rank:setVisible(false)
	if rank_info and type(rank_info) == 'table' then
		local view_person_rank1=person_info.createRankView(viewParent,viewPosition,viewSize,view_person_src,function(item,data)

			local pic_user = uikits.child(item,ui.PIC_USER)	
			local txt_rank = uikits.child(item,ui.TXT_USER_RANK)	
			local txt_name = uikits.child(item,ui.TXT_USER_NAME)	
			local txt_ap = uikits.child(item,ui.TXT_USER_AP)	
			local txt_class_name = uikits.child(item,ui.TXT_USER_CLASS)	
			local txt_lvl = uikits.child(item,ui.TXT_USER_LVL)
			person_info.load_logo_pic(pic_user,data.user_id)
			txt_rank:setString(data.rank)
			txt_name:setString(data.uname)
			txt_ap:setString(data.attack_all)
			txt_class_name:setString(data.class_name)
			txt_lvl:setString(data.level)
			
			local pro_user_exp = uikits.child(item,ui.PRO_USER_EXP)
			local percent_exp = (data.exper/data.exper_max)*100
			pro_user_exp:setPercent(percent_exp)

			local battle_card_src = uikits.child(item,ui.PIC_BATTLE_CARD)
			battle_card_src:setVisible(false)
			local size_battle_card = battle_card_src:getContentSize()
			local pos_x_start = battle_card_src:getPositionX()
			if data.card_list then
				local list = data.card_list
				for i=1,#list do
					local cur_card = battle_card_src:clone()
					cur_card:setVisible(true)
					item:addChild(cur_card)
					cur_card:setPositionX(pos_x_start+(i-1)*size_battle_card.width)
					local pic_name = list[i].card_plate_id..'b.png'
					person_info.load_card_pic(cur_card,pic_name)
					local txt_card_lvl = uikits.child(cur_card,ui.TXT_BATTLE_CARD_LVL)
					txt_card_lvl:setString(list[i].card_plate_level)					
				end
			end
			
			end,function(waitingNode,afterReflash)
			local data = rank_info
			afterReflash(data)
		end)
	end
end

function Chuangguanrank:getdatabyurl()
	local send_data
	person_info.post_data_by_new_form(self._Chuangguanrank,'get_user_roadblock_exper_rank',send_data,function(t,v)
		if t and t == 200 then
			self:show_info(v)
		else
			person_info.messagebox(self._Chuangguanrank,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then

				end
			end)
		end
	end)
end

function Chuangguanrank:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Chuangguanrank = uikits.fromJson{file_9_16=ui.Chuangguanrank_FILE,file_3_4=ui.Chuangguanrank_FILE_3_4}
	self:addChild(self._Chuangguanrank)
	local user_info = person_info.get_user_info()
	
	local txt_sch_name = uikits.child(self._Chuangguanrank,ui.TXT_SCH_NAME)	
	txt_sch_name:setString(user_info.school_name)
	
	self:getdatabyurl()

	local but_quit = uikits.child(self._Chuangguanrank,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
end

function Chuangguanrank:release()

end
return {
create = create,
}