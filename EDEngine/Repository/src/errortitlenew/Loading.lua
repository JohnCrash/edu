local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local messagebox = require "messagebox"
local errortitleview = require "errortitlenew/ErrorTitlePerView"
local studentsel = require "errortitlenew/StudentSel"

local Loading = class("Loading")
Loading.__index = Loading
local ui = {
	LOADING_FILE = 'errortitlenew/loading.json',
	LOADING_FILE_3_4 = 'errortitlenew/loading43.json',
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Loading)		
	
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

local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/current'
local get_child_info_url = 'http://api.lejiaolexue.com/rest/user/current/closefriend/child'
local get_class_url = 'http://api.lejiaolexue.com/rest/user/145487/zone/class'
local get_stu_url = 'http://api.lejiaolexue.com/rest/zone/145488/student/page=1&page_size=200'

function Loading:showparentview()
	if #self.childinfo == 1 then
		login.set_subuid(self.childinfo[1].uid)
		local scene_next = errortitleview.create(self.childinfo[1].uname)								
		cc.Director:getInstance():replaceScene(scene_next)			
	else
		local scene_next = studentsel.create(self.childinfo)								
		cc.Director:getInstance():replaceScene(scene_next)		
	end
	
--[[	local scene_next = studentsel.create(self.childinfo)								
	cc.Director:getInstance():replaceScene(scene_next)		--]]
end

function Loading:getdatabyparent()
	cache.request_json( get_child_info_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				self.childinfo = t.uis
				self:showparentview()
			end	
		else
			--既没有网络也没有缓冲
			messagebox.open(self,function(e)
				if e == messagebox.TRY then
					self:getdatabyparent()
				elseif e == messagebox.CLOSE then
					uikits.popScene()
				end
			end,messagebox.RETRY)	
		end
	end,'N')	
end

function Loading:showteacherview()
	local scene_next = studentsel.create()								
	cc.Director:getInstance():replaceScene(scene_next)		
end

function Loading:getdatabyurl()

	cache.request_json( get_uesr_info_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				if t.uig[1].user_role == 1 then	--xuesheng
					login.set_uid_type(login.STUDENT)
					local scene_next = errortitleview.create(t.uig[1].uname)								
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

function Loading:init()	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._loading = uikits.fromJson{file_9_16=ui.LOADING_FILE,file_3_4=ui.LOADING_FILE_3_4}
	self:addChild(self._loading)
	
	self:getdatabyurl()
--	local loadbox = loadingbox.open(self)
--	local scene_next = WrongSubjectList.create()								
--	cc.Director:getInstance():replaceScene(scene_next)	

end

function Loading:release()

end
return {
create = create,
}