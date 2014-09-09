local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "src/errortitile/loadingbox"
local cache = require "cache"
--local answer = curweek or require "src/errortitile/answer"
local StatisticsView = class("StatisticsView")
StatisticsView.__index = StatisticsView

local ui = {
	BASEFILE = "errortitile/TheWrong/Export/statistics.json",
	MAINMENU = '878',
	statistics_view = '949',
	wronglist_but = '878/880',
	collect_but = '878/881',
	more_but = '878/883',
	
	MAINMENU43 = '1374',
	wronglist43_but = '1374/1376',
	collect43_but = '1374/1377',
	more43_but = '1374/1379',
	
	title_view = '932/934',
	title_all = '932/934/935',	
	title_chinese = '932/934/936',	
	title_math = '932/934/937',	
	title_english = '932/934/938',	
	title_science = '932/934/939',	
	title_infomation = '932/934/940',	
	title_geography = '932/934/941',	
	title_history = '932/934/942',	
	title_organisms = '932/934/943',	
	title_chemistry = '932/934/944',	
	title_physics = '932/934/945',	
	title_politics = '932/934/946',
	title_zonghe = '932/934/4068',
	title_sel = '932/934/947',
	
	label_all_num = '951/999',
	bar_num_cuxin = '951/955/957',
	num_cuxin = '951/955/960',
	bar_num_mohu = '951/964/965',
	num_mohu = '951/964/966',
	bar_num_cuowu = '951/970/971',
	num_cuowu = '951/970/972',
	bar_num_buhui = '951/976/977',
	num_buhui = '951/976/978',
	bar_num_jisuan = '951/982/983',
	num_jisuan = '951/982/984',
	bar_num_qita = '951/988/989',
	num_qita = '951/988/990',
	bar_num_weizhi = '951/994/995',
	num_weizhi = '951/994/996',
	empty_pic = '3649',
	}		

local collect_space = 10

local all_subject_list = {
{0,"全部",ui.title_all},
{10001,"语文",ui.title_chinese},
{10002,"数学",ui.title_math},
{10003,"英语",ui.title_english},
{4,"科学",ui.title_science},
{10009,"信息技术",ui.title_infomation},
{20008,"地理",ui.title_geography},
{20009,"历史",ui.title_history},
{20007,"生物",ui.title_organisms},
{20005,"化学",ui.title_chemistry},
{20004,"物理",ui.title_physics},
{20006,"政治",ui.title_politics},
{101,"综合",ui.title_zonghe},
{10005,"英语",ui.title_english},
{20001,"语文",ui.title_chinese},
{20002,"数学",ui.title_math},
{20003,"英语",ui.title_english},
{30001,"语文",ui.title_chinese},
{30002,"数学",ui.title_math},
{30003,"英语",ui.title_english},
{30004,"物理",ui.title_physics},
{30005,"化学",ui.title_chemistry},
{30006,"政治",ui.title_politics},
{30007,"生物",ui.title_organisms},
{30008,"地理",ui.title_geography},
{30009,"历史",ui.title_history},
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),StatisticsView)		
	cur_layer.statisticsitems = {}
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

function StatisticsView:showstatisticslist(src_view,cur_statisticsitems)
	local cur_view = src_view:clone()
	cur_view:setPosition(cc.p(0,0))			
	cur_view:setVisible(true)
	local allnum = uikits.child(cur_view,ui.label_all_num)
	allnum:setString(cur_statisticsitems.cnt)
	
	--清空每个错误原因
	local bar_num
	local num
	bar_num = uikits.child(cur_view,ui.bar_num_weizhi)
	num = uikits.child(cur_view,ui.num_weizhi)
	num:setString(0)		
	bar_num:setPercent(0)
	
	bar_num = uikits.child(cur_view,ui.bar_num_cuxin)
	num = uikits.child(cur_view,ui.num_cuxin)
	num:setString(0)		
	bar_num:setPercent(0)												

	bar_num = uikits.child(cur_view,ui.bar_num_mohu)
	num = uikits.child(cur_view,ui.num_mohu)	
	num:setString(0)		
	bar_num:setPercent(0)						
	
	bar_num = uikits.child(cur_view,ui.bar_num_cuowu)
	num = uikits.child(cur_view,ui.num_cuowu)			
	num:setString(0)	
	bar_num:setPercent(0)								

	bar_num = uikits.child(cur_view,ui.bar_num_jisuan)
	num = uikits.child(cur_view,ui.num_jisuan)		
	num:setString(0)	
	bar_num:setPercent(0)									

	bar_num = uikits.child(cur_view,ui.bar_num_buhui)
	num = uikits.child(cur_view,ui.num_buhui)		
	num:setString(0)	
	bar_num:setPercent(0)										
		
	bar_num = uikits.child(cur_view,ui.bar_num_qita)
	num = uikits.child(cur_view,ui.num_qita)		
	num:setString(0)	
	bar_num:setPercent(0)		
	
	for i=0,6 do	
		local label_num
		local num
		local percent
		for j, obj in pairs(cur_statisticsitems.reason_stat) do
			if cur_statisticsitems.reason_stat[j].reason == i then								
				if i == 0 then
					bar_num = uikits.child(cur_view,ui.bar_num_weizhi)
					num = uikits.child(cur_view,ui.num_weizhi)
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100
					bar_num:setPercent(percent)
				elseif i == 1 then
					bar_num = uikits.child(cur_view,ui.bar_num_cuxin)
					num = uikits.child(cur_view,ui.num_cuxin)
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100					
					bar_num:setPercent(percent)												
				elseif i == 2 then
					bar_num = uikits.child(cur_view,ui.bar_num_mohu)
					num = uikits.child(cur_view,ui.num_mohu)	
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100
					bar_num:setPercent(percent)						
				elseif i == 3 then
					bar_num = uikits.child(cur_view,ui.bar_num_cuowu)
					num = uikits.child(cur_view,ui.num_cuowu)			
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100
					bar_num:setPercent(percent)								
				elseif i == 4 then
					bar_num = uikits.child(cur_view,ui.bar_num_jisuan)
					num = uikits.child(cur_view,ui.num_jisuan)		
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100
					bar_num:setPercent(percent)									
				elseif i == 5 then
					bar_num = uikits.child(cur_view,ui.bar_num_buhui)
					num = uikits.child(cur_view,ui.num_buhui)		
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100
					bar_num:setPercent(percent)								
				elseif i == 6 then
					bar_num = uikits.child(cur_view,ui.bar_num_qita)
					num = uikits.child(cur_view,ui.num_qita)		
					num:setString(cur_statisticsitems.reason_stat[j].cnt)
					percent = cur_statisticsitems.reason_stat[j].cnt/cur_statisticsitems.cnt*100
					bar_num:setPercent(percent)								
				end
			end
		end
	end
	
	return cur_view
end
function StatisticsView:updatepage()
	
	local statistics_view = uikits.child(self._widget,ui.statistics_view)
	if #self.statisticsitems == 0 then
		local empty_view
		if _G.screen_type == 1 then		
			empty_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/meitongji.json")
		else	
			empty_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/meitongji43.json")	
		end
		local day_sel = uikits.child(self._widget,ui.title_sel)
		day_sel:setVisible(false)
		local src_empty_pic = uikits.child(empty_view,ui.empty_pic)
		local cur_empty_pic = src_empty_pic:clone()
		statistics_view:addChild(cur_empty_pic)	
		return
	end
	
	if _G.screen_type == 1 then	
		--self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics.json")		
		self.statistics_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics_les.json")
	else
		--self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics43.json")		
		self.statistics_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics_les43.json")
	end

	local title_view = uikits.child(self._widget,ui.title_view)
	
    for index, obj in pairs(self.statisticsitems) do
	--	print(index)
		local cur_view = self:showstatisticslist(self.statistics_view,self.statisticsitems[index])	
		statistics_view:addPage(cur_view)		
		
		for j, obj in pairs(all_subject_list) do
			if self.statisticsitems[index].course == all_subject_list[j][1] then	
				local subject_samename = uikits.child(self._widget,all_subject_list[j][3])
				local subject_samepos = uikits.child(self._widget,all_subject_list[index][3])
				local cur_subject = subject_samename:clone()

				cur_subject:setPosition(subject_samepos:getPosition())
				cur_subject:setVisible(true)	
				cur_subject.index = index-1
				--cur_subject.course = test_list[index][2]
				--print(test_list[i][2].."+"..str_error_num)
				--cur_subject:addTouchEventListener(changesubjectCallback)
				uikits.event(cur_subject,
					function(sender,eventType)
						local but_subject = sender
						statistics_view:scrollToPage(but_subject.index)				
				end,"click")
				title_view:addChild(cur_subject)	
				break
			end
		end
	end
	local subject_num = table.getn(self.statisticsitems)
	local size_subject = uikits.child(self._widget,all_subject_list[1][3]):getContentSize()
	title_view:setInnerContainerSize(cc.size(size_subject.width*subject_num,size_subject.height))	
end
function StatisticsView:getdatabyurl()
	local send_data
	if _G.user_status == 1 then
		send_data = "?range=3"
	elseif _G.user_status == 2 then
		send_data = "?range=3&user_id=".._G.cur_child_id
	end
	
	local loadbox = loadingbox.open(self)
	cache.request_json( t_nextview[7].url..send_data,function(t)
			if t and type(t)=='table' then
				if t.result ~= 0 then
					if t.result ~= 100 then
						loadbox:removeFromParent()
						return false					
					end
				else
					self.statisticsitems = t.course_stat
				end
				self:updatepage()
			end
			loadbox:removeFromParent()
		end,'N')
	return true
end

function StatisticsView:init()	
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")		

	if _G.screen_type == 1 then	
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics.json")		
	--	self.statistics_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics_les.json")
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics43.json")		
	--	self.statistics_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics_les43.json")
	end
	self:addChild(self._widget)
	
	local statistics_view = uikits.child(self._widget,ui.statistics_view)
	
	local title_sel = uikits.child(self._widget,ui.title_sel)

	for i, obj in pairs(all_subject_list) do
		local temp_subject = uikits.child(self._widget,all_subject_list[i][3])
		temp_subject:setVisible(false)		
	end

	uikits.event(statistics_view,
		function(sender,eventType)
			if eventType == ccui.PageViewEventType.turning then
				local statistics_view = sender
				local cur_index = statistics_view:getCurPageIndex()
				local day_sel = uikits.child(self._widget,ui.title_sel)		
				local widgetSize = day_sel:getContentSize()
				day_sel:setPositionX(widgetSize.width*cur_index)
			end		
		end)

	--处理切换首页按钮
	--local mainmenu = uikits.child(self._widget,ui.MAINMENU)
	local but_wronglist
	local but_collect
	local but_more
	if _G.screen_type == 1 then	
		but_wronglist = uikits.child(self._widget,ui.wronglist_but)
		but_collect = uikits.child(self._widget,ui.collect_but)
		but_more = uikits.child(self._widget,ui.more_but)
	else
		but_wronglist = uikits.child(self._widget,ui.wronglist43_but)
		but_collect = uikits.child(self._widget,ui.collect43_but)
		but_more = uikits.child(self._widget,ui.more43_but)	
	end
		
	uikits.event(but_wronglist,
			function(sender,eventType)
				local t_wronglist = package.loaded["errortitile/WrongSubjectList"]
				if t_wronglist then
					local scene_next = t_wronglist.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")
			
	uikits.event(but_collect,
			function(sender,eventType)
				local t_collect = package.loaded["src/errortitile/CollectView"]
				if t_collect then
					local scene_next = t_collect.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")	
	--处理切换更多按钮
	uikits.event(but_more,
			function(sender,eventType)
				local t_more = package.loaded["src/errortitile/MoreView"]
				if t_more then
					local scene_next = t_more.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")
			
	local ret = self:getdatabyurl()
	if ret == false then
		print("StatisticsView get error!")
		return
	end	
end

function StatisticsView:release()

end
return {
create = create,
}