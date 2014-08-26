local uikits = require "uikits"
local socket = require "socket"
local res = require "src/testResource"
--local loadingbox = require "src/errortitile/loadingbox"
--local answer = curweek or require "src/errortitile/answer"
local WrongSubjectList = require "src/errortitile/WrongSubjectList"
local Loading = class("Loading")
Loading.__index = Loading

local test_wrong_list_url = 'http://192.168.2.114:81/exerbook/handler/ExerStat.ashx.ashx'

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
--	local loadbox = loadingbox.open(self)
	local scene_next = WrongSubjectList.create()								
	cc.Director:getInstance():replaceScene(scene_next)	

end

function Loading:release()

end
return {
create = create,
}