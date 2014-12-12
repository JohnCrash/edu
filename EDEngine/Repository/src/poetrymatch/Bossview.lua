local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Bossview = class("Bossview")
Bossview.__index = Bossview
local ui = {
	Bossview_FILE = 'poetrymatch/gk.json',
	Bossview_FILE_3_4 = 'poetrymatch/gk.json',
	
	VIEW_ALL_BOSS = 'kapai',
	VIEW_PER_BOSS = 'kapai/kp1',
	TXT_BOSS_LVL = 'dengji',
	CHECK_STAR1 = 'xx1',
	CHECK_STAR2 = 'xx2',
	CHECK_STAR2 = 'xx2',
	
	VIEW_BOSS_INFO = 'tan',
	
	TXT_COUNTRY_NAME = 'xinxi/wen',
	BUTTON_QUIT = 'xinxi/fanhui',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(country_name,country_id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Bossview)		
	cur_layer.country_name = country_name
	cur_layer.country_id = country_id
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

function Bossview:getdatabyurl()

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

function Bossview:show_boss()	
	self.all_boss_info = person_info.get_boss_info_by_id(self.id)
	
end

function Bossview:init_gui()	
	self:show_boss()
end

function Bossview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Bossview = uikits.fromJson{file_9_16=ui.Bossview_FILE,file_3_4=ui.Bossview_FILE_3_4}
	self:addChild(self._Bossview)
	self.view_boss_info = uikits.child(self._Bossview,ui.VIEW_BOSS_INFO)
	self.view_boss_info:setVisible(false)
	
	local txt_country_name = uikits.child(self._Bossview,ui.TXT_COUNTRY_NAME)
	txt_country_name:setString(self.country_name)
	
	local but_quit = uikits.child(self._Bossview,ui.BUTTON_QUIT)
	uikits.event(but_quit,	
		function(sender,eventType)	
			uikits.popScene()
		end,"click")
	self.init_gui()
end

function Bossview:release()

end
return {
create = create,
}