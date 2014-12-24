local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Bagview = class("Bagview")
Bagview.__index = Bagview
local ui = {
	Bagview_FILE = 'poetrymatch/beibao.json',
	Bagview_FILE_3_4 = 'poetrymatch/beibao.json',
	
	BUTTON_SILVER = 'xinxi/yibi/jia',
	TXT_SILVER_NUM = 'xinxi/yibi/zhi',
	
	VIEW_BAG = 'gun',
	VIEW_BATTLE_LIST = 'gun/czk',
	PIC_CARD_BATTLE = 'gun/czk/kp1',
	BUTTON_CARD_EXCHANGE = 'g1',
	TXT_CARD_BATTLE_LVL = 'dj',
	PIC_CARD_BATTLE_UPLVL = 'sjl',
	VIEW_CARD_BAG = 'gun/k1',
	PIC_CARD_BAG = 'kp',
	TXT_CARD_BAG_LVL = 'kp/dj',
	PIC_CARD_BAG_UPLVL = 'sjl',
	VIEW_BUY_STORE = 'gun/zhenjia',
	
	VIEW_CARD_INFO = 'kpxiangq',
	PIC_CARD_INFO = 'kpxiangq/kp',
	TXT_CARD_INFO_LVL = 'kpxiangq/kp/dj',
	TXT_CARD_INFO_NAME = 'kpxiangq/mz',
	PIC_CARD_INFO_GOLD = 'kpxiangq/jing',
	PIC_CARD_INFO_SILVER = 'kpxiangq/yin',
	PIC_CARD_INFO_CU = 'kpxiangq/tong',
	
	
	VIEW_SHI_INFO = 'shi',
	VIEW_CARD_EXCHANGE = 'gengh',
	VIEW_SKILL_INFO = 'jnxiangq',
	VIEW_LEARN_SKILL = 'xuexijn',
	VIEW_NO_CARD = 'meiyyougenghuan',
	
	BUTTON_LE = 'xinxi/lebi/jia',
	TXT_LE_NUM = 'xinxi/lebi/zhi',	
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Bagview)		
	
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

function Bagview:getdatabyurl()

	cache.request_json( get_uesr_info_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				if t.uig[1].user_role == 1 then	--xuesheng
					login.set_uid_type(login.STUDENT)
					local scene_next = errortitleview.create(t.uig[1].uname)		
					--uikits.pushScene(scene_next)						
					cc.Director:getInstance():replaceScene(scene_next)	
				elseif t.uig[1].user_role == 2 then	--jiazhang
					login.set_uid_type(login.PARENT)
					self:getdatabyparent()
				elseif t.uig[1].user_role == 3 then	--laoshi
					login.set_uid_type(login.TEACHER)
					self:showteacherview()		
				end
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:init()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')
end

function Bagview:show_silver()
	local silver_num = person_info.get_user_silver()
	local txt_silver = uikits.child(self._Bagview,ui.TXT_SILVER_NUM)
	txt_silver:setString(silver_num)
	
	local but_silver = uikits.child(self._Bagview,ui.BUTTON_SILVER)
--	but_silver:setVisible(false)
	uikits.event(but_silver,	
		function(sender,eventType)	
			sender:setEnabled(false)
			sender:setTouchEnabled(false)
			local le_num = person_info.get_user_le_coin()
			if le_num < 10 then
				person_info.messagebox(self,person_info.NO_LE,function(e)
					if e == person_info.OK then
						print('aaaaaaaaaaaa')
					else
						print('bbbbbbbbbbbb')
					end
				end)
			else
				le_num = le_num -10 
				silver_num = silver_num + 1000
				local txt_le = uikits.child(self._Bagview,ui.TXT_LE_NUM)
				txt_le:setString(le_num)
				txt_silver:setString(silver_num)
				person_info.set_user_silver(silver_num)
				person_info.set_user_le_coin(le_num)
			end
			sender:setEnabled(true)
			sender:setTouchEnabled(true)			
		end,"click")
end

function Bagview:show_le_coin()
	local le_num = person_info.get_user_le_coin()
	local txt_le = uikits.child(self._Bagview,ui.TXT_LE_NUM)
	txt_le:setString(le_num)
	
	local but_le = uikits.child(self._Bagview,ui.BUTTON_LE)
	but_le:setVisible(false)
	uikits.event(but_le,	
		function(sender,eventType)	
			
		end,"click")
end

function Bagview:show_exchange_card(id)	

end
	
function Bagview:buy_store()		

end
	
function Bagview:show_card_info(id)	
	self.view_bag:setVisible(false)
	self.view_card_info:setVisible(true)
	local card_info = person_info.get_card_in_bag_by_id(id)
	
end

local card_space_shu = 42
local card_space_heng = 94
local card_battle_space = 188

function Bagview:show_bag_view()	
	self.view_bag:setVisible(true)
	local all_card_info,max_store_num = person_info.get_all_card_in_bag()
	local battle_cards = person_info.get_all_card_in_battle()
	local view_card_bag_src = uikits.child(self._Bagview,ui.VIEW_CARD_BAG)
	local view_battle_list = uikits.child(self._Bagview,ui.VIEW_BATTLE_LIST)
	local size_battle_list = view_battle_list:getContentSize()
	local size_scroll = self.view_bag:getInnerContainerSize()
	local size_bag_view = self.view_bag:getContentSize()
	local size_card_src = view_card_bag_src:getContentSize()
	local pos_battle_list_x,pos_battle_list_y = view_battle_list:getPosition()
	local pos_card_src_x,pos_card_src_y = view_card_bag_src:getPosition()
	local row_num = max_store_num/5+1
	local pos_card_y_start = size_bag_view.height - pos_card_src_y
	local pos_battle_y_start = size_bag_view.height - pos_battle_list_y
	
	size_scroll.height = pos_card_y_start + row_num*(size_card_src.height+card_space_shu) - size_card_src.height/2
	self.view_bag:setInnerContainerSize(size_scroll)
	view_battle_list:setPosition(cc.p(pos_battle_list_x,size_scroll.height-pos_battle_y_start))
	
	pos_card_y_start = size_scroll.height-pos_card_y_start
	local pos_card_x_start = pos_card_src_x
	local cur_row = 0
	local cur_line = 5
	view_card_bag_src:setVisible(false)
	for i=1,max_store_num+#battle_cards do
		if i>#all_card_info then
			local cur_card = view_card_bag_src:clone()
			cur_card:setVisible(true)
			self.view_bag:addChild(cur_card)
			local pic_card_bag = uikits.child(cur_card,ui.PIC_CARD_BAG)
			local txt_card_bag_lvl = uikits.child(cur_card,ui.TXT_CARD_BAG_LVL)
			local pic_card_bag_uplvl = uikits.child(cur_card,ui.PIC_CARD_BAG_UPLVL)
			if cur_line == 5 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_card_x_start +(size_card_src.width+card_space_heng)*(cur_line-1)
			local cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row-1)
			cur_card:setPosition(cc.p(cur_pos_x,cur_pos_y))
			
			if i>#all_card_info then
				pic_card_bag:setVisible(false)
				txt_card_bag_lvl:setVisible(false)
				pic_card_bag_uplvl:setVisible(false)
			end		
			if i == max_store_num+#battle_cards then
				cur_pos_x = pos_card_x_start
				cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row)
				local view_buy_store = uikits.child(self._Bagview,ui.VIEW_BUY_STORE)
				view_buy_store:setPosition(cc.p(cur_pos_x,cur_pos_y))
				uikits.event(view_buy_store,	
					function(sender,eventType)	
						self:buy_store()
					end,"click")			
			end
		elseif all_card_info[i].in_battle_list == 0 then
			local cur_card = view_card_bag_src:clone()
			cur_card:setVisible(true)
			self.view_bag:addChild(cur_card)
			local pic_card_bag = uikits.child(cur_card,ui.PIC_CARD_BAG)
			local txt_card_bag_lvl = uikits.child(cur_card,ui.TXT_CARD_BAG_LVL)
			local pic_card_bag_uplvl = uikits.child(cur_card,ui.PIC_CARD_BAG_UPLVL)
			if cur_line == 5 then
				cur_line = 1
				cur_row = cur_row + 1 
			else
				cur_line = cur_line + 1 
			end
			local cur_pos_x = pos_card_x_start +(size_card_src.width+card_space_heng)*(cur_line-1)
			local cur_pos_y = pos_card_y_start -(size_card_src.height+card_space_shu)*(cur_row-1)
			cur_card:setPosition(cc.p(cur_pos_x,cur_pos_y))
			
			local pic_name = all_card_info[i].id..'.png'
			person_info.load_card_pic(pic_card_bag,pic_name)
			txt_card_bag_lvl:setString(all_card_info[i].lvl)
			pic_card_bag.id = all_card_info[i].id
			uikits.event(pic_card_bag,	
				function(sender,eventType)	
					self:show_card_info(sender.id)
				end,"click")
			pic_card_bag:setVisible(true)
			txt_card_bag_lvl:setVisible(true)
			pic_card_bag_uplvl:setVisible(true)
		end
	end

	local card_battle_src = uikits.child(self._Bagview,ui.PIC_CARD_BATTLE)
	card_battle_src:setVisible(false)

	for i=1,#battle_cards do
		local cur_card = card_battle_src:clone()
		local pic_name = battle_cards[i].id..'2.png'
		person_info.load_card_pic(cur_card,pic_name)
		local txt_card_lvl = uikits.child(cur_card,ui.TXT_CARD_BATTLE_LVL)
		local pos_x = cur_card:getPositionX()
		local size_card = cur_card:getContentSize()
		pos_x = pos_x+(size_card.width+card_battle_space)*(i-1)
		cur_card:setPositionX(pos_x)
		txt_card_lvl:setString(battle_cards[i].lvl)
		local but_card_exchange = uikits.child(cur_card,ui.BUTTON_CARD_EXCHANGE)
		but_card_exchange.id = battle_cards[i].id
		cur_card.id = battle_cards[i].id
		uikits.event(but_card_exchange,	
			function(sender,eventType)	
				self:show_exchange_card(sender.id)
			end,"click")
		uikits.event(cur_card,	
			function(sender,eventType)	
				self:show_card_info(sender.id)
			end,"click")
		cur_card:setVisible(true)
		view_battle_list:addChild(cur_card)
	end	
end

function Bagview:initgui()	
	self.view_bag = uikits.child(self._Bagview,ui.VIEW_BAG)
	self.view_card_info = uikits.child(self._Bagview,ui.VIEW_CARD_INFO)
	self.view_shi_info = uikits.child(self._Bagview,ui.VIEW_SHI_INFO)
	self.view_card_exchange = uikits.child(self._Bagview,ui.VIEW_CARD_EXCHANGE)
	self.view_skill_info = uikits.child(self._Bagview,ui.VIEW_SKILL_INFO)
	self.view_learn_skill = uikits.child(self._Bagview,ui.VIEW_LEARN_SKILL)
	self.view_no_card = uikits.child(self._Bagview,ui.VIEW_NO_CARD)

	self.view_bag:setVisible(false)
	self.view_card_info:setVisible(false)
	self.view_shi_info:setVisible(false)
	self.view_card_exchange:setVisible(false)
	self.view_skill_info:setVisible(false)
	self.view_learn_skill:setVisible(false)
	self.view_no_card:setVisible(false)
		
	self:show_silver()
	self:show_le_coin()
	self:show_bag_view()
end

function Bagview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Bagview = uikits.fromJson{file_9_16=ui.Bagview_FILE,file_3_4=ui.Bagview_FILE_3_4}
	self:addChild(self._Bagview)
	
	local but_quit = uikits.child(self._Bagview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
		
	self:initgui()
--	self:getdatabyurl()
--	local loadbox = Bagviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Bagview:release()

end
return {
create = create,
}