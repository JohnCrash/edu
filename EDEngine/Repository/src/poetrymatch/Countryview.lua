local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

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

function Countryview:init_gui()	
	
end

function Countryview:init()	
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
	self.country_view = uikits.child(self._Countryview,ui.COUNTRY_VIEW)	
	self.country_view:setVisible(false)
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