local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Mallview = class("Mallview")
Mallview.__index = Mallview
local ui = {
	Mallview_FILE = 'poetrymatch/shangcheng.json',
	Mallview_FILE_3_4 = 'poetrymatch/shangcheng.json',
	VIEW_ALL_CARD = 'gun',
	BUTTON_CU = 'gun/tong',
	BUTTON_GOLD = 'gun/jin',
	BUTTON_SILVER = 'gun/yin',
	
	
	VIEW_CARD_INFO = 'xiangq',
	
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Mallview)		
	
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

function Mallview:show_mall_card()
	
end

function Mallview:getdatabyurl()
	local send_data = {}
	send_data.v1 = self.sel_pinzhi
	person_info.post_data_by_new_form('get_product_cards',send_data,function(t,v)
		if t and t == true then
			if v and type(v) == 'table' then
				self:show_mall_card(v)			
			end
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:update_user_info()
				else
					self:update_user_info()
				end
			end)
		end
	end)
end

function Mallview:gui_init()	
	local but_cu = uikits.child(self._Mallview,ui.BUTTON_CU)
	local but_gold = uikits.child(self._Mallview,ui.BUTTON_GOLD)
	local but_silver = uikits.child(self._Mallview,ui.BUTTON_SILVER)
	self.sel_pinzhi = 1
	but_cu:setSelectedState(true)
	but_cu.index = 1
	but_gold:setSelectedState(false)
	but_gold.index = 3
	but_silver:setSelectedState(false)
	but_silver.index = 2
	
	local function set_checkbox_pinzhi(cur_but,is_sel)
		if is_sel == true then
			if self.sel_pinzhi == 1 then
				but_cu:setSelectedState(false)
			elseif self.sel_pinzhi == 2 then
				but_silver:setSelectedState(false)
			elseif self.sel_pinzhi == 3 then
				but_gold:setSelectedState(false)
			end
			self.sel_pinzhi = cur_but.index
			self:getdatabyurl()
		else
			if cur_but.index == self.sel_pinzhi then
				cur_but:setSelectedState(true)
			end
		end
	end
	
	uikits.event(but_cu,	
		function(sender,eventType)	
			set_checkbox_pinzhi(sender,eventType)
	end)		
	uikits.event(but_gold,	
		function(sender,eventType)	
			set_checkbox_pinzhi(sender,eventType)
	end)	
	uikits.event(but_silver,	
		function(sender,eventType)	
			set_checkbox_pinzhi(sender,eventType)
	end)	
	
	self:getdatabyurl()
end	

function Mallview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Mallview = uikits.fromJson{file_9_16=ui.Mallview_FILE,file_3_4=ui.Mallview_FILE_3_4}
	self:addChild(self._Mallview)
	self:gui_init()	
	--self:getdatabyurl()	
	local but_quit = uikits.child(self._Mallview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")	
--	local loadbox = Mallviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Mallview:release()

end
return {
create = create,
}