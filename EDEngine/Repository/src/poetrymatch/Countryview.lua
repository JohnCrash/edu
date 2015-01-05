local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"
local bossview = require "poetrymatch/Bossview"

local Countryview = class("Countryview")
Countryview.__index = Countryview
local ui = {
	Countryview_FILE = 'poetrymatch/chuangg.json',
	Countryview_FILE_3_4 = 'poetrymatch/chuangg.json',
	GUANKA_VIEW = 'guanka',
	COUNTRY_VIEW = 'guanka/kg1',
	BUTTON_COUNTRY = 'bt',
	TXT_STAR_NUM = 'xing',
	BUTTON_QUIT = 'xinxi/fanhui',
	BUTTON_PAIHANG = 'xinxi/chuanggph',
	
	FUR_COUNTRY_VIEW = 'guanka/kg1_0',
	PIC_MAN = 'guanka/xingbie2',
	PIC_WOMAN = 'guanka/xingbie',
}

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Countryview)		
	
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
local section_info = {}

function Countryview:get_user_section_info()
	local send_data
	person_info.post_data_by_new_form('get_user_road_block',send_data,function(t,v)
		if t and t == true then
--[[			local section_info = {}
			for i=1,#v do
				local cur_section_info = {}
				cur_section_info.id = v[i].road_block_id
				cur_section_info.name = v[i].road_block_name
				cur_section_info.star_all = v[i].road_block_tot_Star
				cur_section_info.des = v[i].road_block_des
				section_info[#section_info+1] = cur_section_info
			end--]]
			for i=1 ,#section_info do
				if v[i] then
					section_info[i].star_has = v[i].tot_gain_star
					section_info[i].is_admit = 1
				else
					section_info[i].star_has = 0
					section_info[i].is_admit = 0					
				end
			end
			person_info.set_all_section_info(section_info)
			section_info = {}
			self:show_country()
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:get_user_section_info()
				else
					self:get_user_section_info()
				end
			end)
		end		
	end)

end

function Countryview:getdatabyurl()
	local send_data
	person_info.post_data_by_new_form('get_road_block',send_data,function(t,v)
		if t and t == true then
			
			for i=1,#v do
				local cur_section_info = {}
				--cur_section_info.id = v[i].road_block_id
				cur_section_info.id = '8'
				cur_section_info.name = v[i].road_block_name
				cur_section_info.star_all = 0
				if v[i].road_block_tot_star then
					cur_section_info.star_all = v[i].road_block_tot_star
				end
				cur_section_info.des = v[i].road_block_des
				section_info[#section_info+1] = cur_section_info
			end
			self:get_user_section_info()
		else
			person_info.messagebox(self,person_info.NETWORK_ERROR,function(e)
				if e == person_info.OK then
					self:getdatabyurl()
				else
					self:getdatabyurl()
				end
			end)
		end		
	end)
end

function Countryview:save_innerpos()
	self.inner_posx,self.inner_posy = self.guanka_view:getInnerContainer():getPosition()
end

function Countryview:set_innerpos()
	self.guanka_view:getInnerContainer():setPosition(cc.p(self.inner_posx,self.inner_posy))
end

local country_space = 10

function Countryview:show_country()	
	local fur_country_view = uikits.child(self._Countryview,ui.FUR_COUNTRY_VIEW)
	self.country_view = uikits.child(self._Countryview,ui.COUNTRY_VIEW)	
	self.country_view:setVisible(false)
	local all_country_info = person_info.get_all_section_info()
	local size_scroll = self.guanka_view:getInnerContainerSize()
	local size_view = self.guanka_view:getContentSize()
	local pos_x_src = self.country_view:getPositionX()
	local size_country_src = self.country_view:getContentSize()
	pos_x_src = pos_x_src+(size_country_src.width+country_space)*(#all_country_info+1)
	if pos_x_src > size_view.width then
		size_scroll.width = pos_x_src
	else
		size_scroll.width = size_view.width
	end
	
	self.guanka_view:setInnerContainerSize(size_scroll)
	for i=1,#all_country_info do
		local cur_country = self.country_view:clone()
		local pic_country = uikits.child(cur_country,ui.BUTTON_COUNTRY)
		pic_country.name = all_country_info[i].name
		pic_country.id = all_country_info[i].id
		local pic_name_def
		local pic_name_dis
		pic_name_def = all_country_info[i].id..'.png'
		if all_country_info[i].is_admit == 1 then
			person_info.load_section_pic(pic_country,pic_name_def)
		else
			pic_name_dis = all_country_info[i].id..'b.png'
			person_info.load_section_pic(pic_country,pic_name_def,pic_name_def,pic_name_dis)
			pic_country:setEnabled(false)
			pic_country:setBright(false)
			pic_country:setTouchEnabled(false)	
		end 
		local txt_star_num = uikits.child(cur_country,ui.TXT_STAR_NUM)
		txt_star_num:setString(all_country_info[i].star_has..'/'..all_country_info[i].star_all)
		
		uikits.event(pic_country,	
		function(sender,eventType)	
			self:save_innerpos()
			local scene_next = bossview.create(sender.name,sender.id)	
			uikits.pushScene(scene_next)	
		end,"click")
		
		local pos_x = cur_country:getPositionX()
		local size_country = cur_country:getContentSize()
		pos_x = pos_x+(size_country.width+country_space)*(i-1)
		cur_country:setPositionX(pos_x)
		cur_country:setVisible(true)
		self.guanka_view:addChild(cur_country)
		if i == #all_country_info then
			pos_x = pos_x+(size_country.width+country_space)
			fur_country_view:setPositionX(pos_x)
			fur_country_view:setVisible(true)
		end
	end
	
end

function Countryview:init_gui()	
	local pic_man = uikits.child(self._Countryview,ui.PIC_MAN)
	local pic_woman = uikits.child(self._Countryview,ui.PIC_WOMAN)
	pic_man:setVisible(false)
	pic_woman:setVisible(false)
	local user_info = person_info.get_user_info()
	if user_info.sex == 1 then
		pic_man:setVisible(true)
	else 
		pic_woman:setVisible(true)
	end
	self:getdatabyurl()
end

function Countryview:init()	
	if self._Countryview then
		self:set_innerpos()
		return
	end
	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Countryview = uikits.fromJson{file_9_16=ui.Countryview_FILE,file_3_4=ui.Countryview_FILE_3_4}
	self:addChild(self._Countryview)

	local but_quit = uikits.child(self._Countryview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")

	local but_paihang = uikits.child(self._Countryview,ui.BUTTON_PAIHANG)
	uikits.event(but_paihang,	
		function(sender,eventType)	
			
		end,"click")

	self.guanka_view = uikits.child(self._Countryview,ui.GUANKA_VIEW)
	self:init_gui()
--	self:getdatabyurl()
--	local loadbox = Countryviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Countryview:release()

end
return {
create = create,
}