local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local person_info = require "poetrymatch/Person_info"

local Leitaiview = class("Leitaiview")
Leitaiview.__index = Leitaiview
local ui = {
	Leitaiview_FILE = 'poetrymatch/leitai.json',
	Leitaiview_FILE_3_4 = 'poetrymatch/leitai.json',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Leitaiview)		
	
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

function Leitaiview:getdatabyurl()

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

function Leitaiview:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._Leitaiview = uikits.fromJson{file_9_16=ui.Leitaiview_FILE,file_3_4=ui.Leitaiview_FILE_3_4}
	self:addChild(self._Leitaiview)
	

--	self:getdatabyurl()
--	local loadbox = Leitaiviewbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Leitaiview:release()

end
return {
create = create,
}