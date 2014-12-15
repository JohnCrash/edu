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
	FUR_COUNTRY_VIEW = 'guanka/kg1_0',
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

function Countryview:getdatabyurl()

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
			pic_name_dis = all_country_info[i].id..'2.png'
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
	self:show_country()
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