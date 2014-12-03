local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
local selstudent = require "errortitile/selstudent"
local WrongSubjectList = require "errortitile/WrongSubjectList"
local messagebox = require "messagebox"
local Loading = class("Loading")
Loading.__index = Loading

local get_uesr_info_url = 'http://api.lejiaolexue.com/rest/userinfo/simple/current'

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Loading)		
	--cur_layer.screen_type = screen_type	
	
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

--local cookie_1 = "sc1=D3F1DC81D98457FE8E1085CB4262CAAD5C443773akl%2bNQbvBYOcjHsDK0Fu4kV%2fbgv3ZBi7sFKU19KP5ks0GkvPwGpmMWe%2b8Q6O%2fkT7EuHjkQ%3d%3d"

function Loading:getdatabyurl()
--	local send_data
--	send_data = "?range="..self.range.."&course="..self.subject_id.."&page="..self.pageindex.."&show_type=2"
	
--	local send_url = t_nextview[2].url..send_data
--[[	local result = kits.http_get(get_uesr_info_url,login.cookie(),1)
	kits.log('ERROR--result:::'..result )
	local tb_result = json.decode(result)
	if 	tb_result.result ~= 0 then				
		print(tb_result.result.." : "..tb_result.message)			
	else
		--local tb_uig = json.decode(tb_result.uig)
		if tb_result.uig[1].user_role == 1 then	--?§éú
			_G.user_status = 1
			local scene_next = WrongSubjectList.create()								
			cc.Director:getInstance():replaceScene(scene_next)	
		elseif tb_result.uig[1].user_role == 2 then	--?ò3¤
			_G.user_status = 2
			local scene_next = selstudent.create()								
			cc.Director:getInstance():replaceScene(scene_next)				
		end
	end	--]]
	cache.request_json( get_uesr_info_url,function(t)
		if t and type(t)=='table' then
			if 	t.result ~= 0 then				
				print(t.result.." : "..t.message)			
			else
				--local tb_uig = json.decode(tb_result.uig)
				if t.uig[1].user_role == 1 then	--?§éú
					login.set_uid_type(login.STUDENT)
					local scene_next = WrongSubjectList.create()								
					cc.Director:getInstance():replaceScene(scene_next)	
				elseif t.uig[1].user_role == 2 then	--?ò3¤
					login.set_uid_type(login.PARENT)
					local scene_next = selstudent.create()								
					cc.Director:getInstance():replaceScene(scene_next)				
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
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")	
	local design	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		_G.screen_type = 1
		design = {width=1920,height=1080}
	else
		_G.screen_type = 2
		design = {width=1440,height=1080}	
	end
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/loading.json")		
		design = {width=1920,height=1080}		
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/loading43.json")		
		design = {width=1440,height=1080}		
	end
	self:addChild(self._widget)
	uikits.initDR(design)
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