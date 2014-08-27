local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"

--local answer = curweek or require "src/errortitile/answer"
local MoreView = class("MoreView")
MoreView.__index = MoreView

local ui = {
	BASEFILE = "errortitile/TheWrong/Export/more.json",
	MAINMENU = '878',
	wronglist_but = '878/880',
	collect_but = '878/881',
	statistics_but = '878/882',
	music_but = '1051/1056',
	exit_but = '1051/3665',
	MAINMENU43 = '1430',
	wronglist43_but = '1430/1432',
	collect43_but = '1430/1433',
	statistics43_but = '1430/1434',
	
	}		

local collect_space = 10

local all_subject_list = {
{10001,"语文",594},
{10002,"数学",595},
{3,"英语",596},
{4,"科学",597},
{5,"信息技术",598},
{6,"地理",599},
{7,"历史",600},
{8,"生物",601},
{9,"化学",602},
{10,"物理",603},
{11,"政治",604},
{0,"全部",593}
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),MoreView)		

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

--[[function MoreView:getdatabyurl()
	local send_data
	send_data = "?show_type=1"
	local result = kits.http_get(t_nextview[5].url..send_data,login.cookie(),1)	
	--print(result)
	local tb_collectlist = json.decode(result)
	if 	tb_collectlist.result == 0 then	
		self.collectitems = tb_collectlist.exer_book_stat	
		return true
	else
		return false
	end	
end--]]

function MoreView:init()	
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")		
--	local ret = self:getdatabyurl()
	if ret == false then
		print("MoreView get error!")
		return
	end		
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/more.json")
	else		
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/more43.json")
	end
	--self._widget = uikits.fromjson{file=ui.BASEFILE}
	--self._widget:setPosition(cc.p(0,100))
	--self._widget:setScale(0.5)		
	
	local but_music = uikits.child(self._widget,ui.music_but)
	but_music:setVisible(true)
	
	local but_exit
	but_exit = uikits.child(self._widget,ui.exit_but)
	
	local function exitCallback(sender, eventType) 	
        if eventType == ccui.TouchEventType.ended then				
			cc.Director:getInstance():endToLua()
        end
    end						
	but_exit:addTouchEventListener(exitCallback)			
	--self.statistics_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics_les.json")
	--self._widget:addChild(self.statistics_view)
	--处理切换首页按钮
	--local mainmenu = uikits.child(self._widget,ui.MAINMENU)
	local but_wronglist
	local but_collect
	local but_more

	if _G.screen_type == 1 then	
		but_wronglist = uikits.child(self._widget,ui.wronglist_but)
		but_collect = uikits.child(self._widget,ui.collect_but)
		but_statistics = uikits.child(self._widget,ui.statistics_but)
	else
		but_wronglist = uikits.child(self._widget,ui.wronglist43_but)
		but_collect = uikits.child(self._widget,ui.collect43_but)
		but_statistics = uikits.child(self._widget,ui.statistics43_but)	
	end	
	
	local function wronglistCallback(sender, eventType) 	
        if eventType == ccui.TouchEventType.ended then				
			local t_wronglist = package.loaded["errortitile/WrongSubjectList"]
			if t_wronglist then
				local scene_next = t_wronglist.create()								
				cc.Director:getInstance():replaceScene(scene_next)								
			end						
        end
    end						
	but_wronglist:addTouchEventListener(wronglistCallback)		
	
	--处理切换收藏按钮
	local function collectCallback(sender, eventType) 	
        if eventType == ccui.TouchEventType.ended then				
			local t_collect = package.loaded["src/errortitile/CollectView"]
			if t_collect then
				local scene_next = t_collect.create()								
				cc.Director:getInstance():replaceScene(scene_next)								
			end						
        end
    end						
	but_collect:addTouchEventListener(collectCallback)			
	
	--处理切换统计按钮	
	local function statisticsCallback(sender, eventType) 	
        if eventType == ccui.TouchEventType.ended then				
			local t_statistics = package.loaded["src/errortitile/StatisticsView"]
			if t_statistics then
				local scene_next = t_statistics.create()								
				cc.Director:getInstance():replaceScene(scene_next)								
			end				
        end
    end						
	but_statistics:addTouchEventListener(statisticsCallback)		
	
	self:addChild(self._widget)
end

function MoreView:release()

end
return {
create = create,
}