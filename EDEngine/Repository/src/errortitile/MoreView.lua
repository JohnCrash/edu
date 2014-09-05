local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local login = require "login"
local cache = require "cache"
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
	
	student_view = '1051/4710',
	per_student_view = '1051/4710/4711',
	student_name = '4713',
	student_checkbox = '4714',
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

local student_space = 40
local get_child_info_url = 'http://api.lejiaolexue.com/rest/user/current/closefriend/child'

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

function MoreView:getdatabyurl()
	local result = kits.http_get(get_child_info_url,login.cookie(),1)
	print(result)
	local tb_result = json.decode(result)
	if 	tb_result.result ~= 0 then				
		print(tb_result.result.." : "..tb_result.message)			
	else
		--local tb_uig = json.decode(tb_result.uig)
		self.childinfo = tb_result.uis
	end	
end

function MoreView:init()	
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")		
--	local ret = self:getdatabyurl()
	if ret == false then
		print("MoreView get error!")
		return
	end		
	if _G.user_status == 1 then
		if _G.screen_type == 1 then
			self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/more.json")
		else		
			self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/more43.json")
		end
	elseif _G.user_status == 2 then
		if _G.screen_type == 1 then
			self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/more2.json")
		else		
			self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/more243.json")
		end
	end
	--self._widget = uikits.fromjson{file=ui.BASEFILE}
	--self._widget:setPosition(cc.p(0,100))
	--self._widget:setScale(0.5)		
	
	local but_music = uikits.child(self._widget,ui.music_but)
	but_music:setVisible(true)
	if but_music then
		but_music:setSelectedState (kits.config("mute","get"))
		uikits.event(but_music,function(sender,b)
			kits.config("mute",b)
			uikits.muteSound(b)
		end)
	end
	
	local but_exit
	but_exit = uikits.child(self._widget,ui.exit_but)
	
	local function exitCallback(sender, eventType) 	
        if eventType == ccui.TouchEventType.ended then				
			kits.quit()
        end
    end						
	but_exit:addTouchEventListener(exitCallback)			
	--self.statistics_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/statistics_les.json")
	--self._widget:addChild(self.statistics_view)
	--处理切换首页按钮
	--local mainmenu = uikits.child(self._widget,ui.MAINMENU)
	if _G.user_status == 2 then
		self:getdatabyurl()
		local student_view = uikits.child(self._widget,ui.student_view)
		local src_student_view = uikits.child(self._widget,ui.per_student_view)
		src_student_view:setVisible(false)
		local size_student_view = student_view:getContentSize()
		local size_per_student_view = src_student_view:getContentSize()
		local all_student_width = (size_per_student_view.width * (#self.childinfo)) + (student_space*(#self.childinfo-1))
		local pos_x_start = (size_student_view.width - all_student_width)/2

		local function selectedEvent(sender,eventType)
			local checkBox = sender
			if eventType == ccui.CheckBoxEventType.selected then
				if _G.cur_child_id == checkBox.uid then
					return
				end
				_G.cur_child_id = checkBox.uid			
				--local parent_view = checkBox:getParent()
				local parent_view = checkBox.parentview
				local tb_all_student = parent_view:getChildren()
				for i=1,#tb_all_student do 
					local checkBox_temp = uikits.child(tb_all_student[i],ui.student_checkbox)
--[[					print(checkBox_temp)
					if checkBox ~= checkBox_temp then
						checkBox_temp:setSelectedState(false)
					end--]]
				end
				local t_wronglist = package.loaded["errortitile/WrongSubjectList"]
				if t_wronglist then
					local scene_next = t_wronglist.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end
			if eventType == ccui.CheckBoxEventType.unselected then
				if _G.cur_child_id == checkBox.uid	then
					checkBox:setSelectedState(true)
				end
			end
		end  

		for i = 1,#self.childinfo do 
			local cur_student_view = src_student_view:clone()
			cur_student_view:setVisible(true)
			student_view:addChild(cur_student_view)
			cur_student_view:setPositionX(pos_x_start)
			local student_name = uikits.child(cur_student_view,ui.student_name)
			local checkBox = uikits.child(cur_student_view,ui.student_checkbox)
			student_name:setString(self.childinfo[i].uname)
			if _G.cur_child_id == self.childinfo[i].uid then
				checkBox:setSelectedState(true)
			else
				checkBox:setSelectedState(false)
			end
			checkBox.uid = self.childinfo[i].uid
			checkBox.parentview = student_view
--[[			uikits.event(checkBox,
				function(sender,eventType)
					local checkBox = sender
					if eventType == ccui.CheckBoxEventType.selected then
						if _G.cur_child_id == checkBox.uid then
							return
						end
						_G.cur_child_id = checkBox.uid			
						--local parent_view = checkBox:getParent()
						local parent_view = checkBox.parentview
						local tb_all_student = parent_view:getChildren()
						for i=1,#tb_all_student do 
							local checkBox_temp = uikits.child(tb_all_student[i],ui.student_checkbox)
						end
						local t_wronglist = package.loaded["errortitile/WrongSubjectList"]
						if t_wronglist then
							local scene_next = t_wronglist.create()								
							cc.Director:getInstance():replaceScene(scene_next)								
						end					
					end
					if eventType == ccui.CheckBoxEventType.unselected then
						if _G.cur_child_id == checkBox.uid	then
							checkBox:setSelectedState(true)
						end
					end			
				end)--]]
			checkBox:addEventListener(selectedEvent)  
			pos_x_start = pos_x_start+size_per_student_view.width+student_space
		end		
	end

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
	
	uikits.event(but_wronglist,
			function(sender,eventType)
				local t_wronglist = package.loaded["errortitile/WrongSubjectList"]
				if t_wronglist then
					local scene_next = t_wronglist.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")
	--处理切换收藏按钮		
	uikits.event(but_collect,
			function(sender,eventType)
				local t_collect = package.loaded["src/errortitile/CollectView"]
				if t_collect then
					local scene_next = t_collect.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")	
	--处理切换统计按钮
	uikits.event(but_statistics,
			function(sender,eventType)
				local t_statistics = package.loaded["src/errortitile/StatisticsView"]
				if t_statistics then
					local scene_next = t_statistics.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")		
	
	self:addChild(self._widget)
end

function MoreView:release()

end
return {
create = create,
}