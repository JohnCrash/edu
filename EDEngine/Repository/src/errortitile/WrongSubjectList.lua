local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local cache = require "cache"
local persubject = require "src/errortitile/persubject"
local CollectView = require "src/errortitile/CollectView"
local StatisticsView = require "src/errortitile/StatisticsView"
local MoreView = require "src/errortitile/MoreView"
local loadingbox = require "src/errortitile/loadingbox"
local login = require "login"
local ui = {
	BASEFILE = "errortitile/TheWrong/Export/wrong_day.json",
	MAINMENU = '7',
	collectbut = '7/11',
	statisticsbut = '7/12',
	morebut = '7/13',
	PAGEVIEW = '261',
	DAYVIEW = '14',
	daysel = '14/15',
	day7but = '14/16',
	day30but = '14/17',
	day180but = '14/18',
	LESFILE = "errortitile/TheWrong/Export/lesson.json",
	LES_VIEW = '20',
	leftbut = '20/130',
	rightbut = '20/21',
	empty_pic = '3635',
	}		

local WrongSubjectList = class("WrongSubjectList")
WrongSubjectList.__index = WrongSubjectList
local scale = 960/1080

local all_subject_list = {
{10001,"语文",678,679},
{10002,"数学",682,683},
{10003,"英语",684,685},
{20004,"物理",686,687},
{20005,"化学",688,689},
{20006,"政治",692,693},
{20009,"历史",696,697},
{20008,"地理",700,701},
{"science","科学",704,705},
{10009,"信息技术",708,709},
{20007,"生物",712,713},
{10005,"英语",684,685},
{20001,"语文",678,679},
{20002,"数学",682,683},
{20003,"英语",684,685},
{30001,"语文",678,679},
{30002,"数学",682,683},
{30003,"英语",684,685},
{30004,"物理",686,687},
{30005,"化学",688,689},
{30006,"政治",692,693},
{30007,"生物",712,713},
{30008,"地理",700,701},
{30009,"历史",696,697},
}
local course_map = {
{101,""},
{10001,"语文"},
{10002,"数学"},
{10003,"英语"},
{10005,"英语"},
{10009,"信息技术"},
{10010,""},
{10011,""},
{11005,"英语"},
{20001,"语文"},
{20002,"数学"},
{20003,"英语"},
{20004,"物理"},
{20005,"化学"},
{20006,"政治"},
{20007,"生物"},
{20008,"地理"},
{20009,"历史"},
{30001,"语文"},
{30002,"数学"},
{30003,"英语"},
{30004,"物理"},
{30005,"化学"},
{30006,"政治"},
{30007,"生物"},
{30008,"地理"},
{30009,"历史"},
}
--[[local test_list = {
{1,"语文",5,10},
{"math","数学",6,20},
{"english","英语",7,25},
{"infomation","信息技术",8,30},
{"science","科学",9,35},
{"chemistry","化学",10,40},
{"organisms","生物",11,45}
}--]]

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)	
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

--WrongSubjectList.subject_name = nil
function create()
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),WrongSubjectList)		
	cur_layer.subject_view = nil
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

--设置科目排列
function WrongSubjectList:setsubjects(subject_view,test_list)
	local temp_subject
	for i, obj in pairs(all_subject_list) do	
		temp_subject = subject_view:getChildByTag(all_subject_list[i][3])
		temp_subject:setVisible(false)
	end
	if #test_list == 0 then
		local empty_view
		if _G.screen_type == 1 then		
			empty_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/meicuoti.json")
		else	
			empty_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/meicuoti43.json")	
		end
			local src_empty_pic = uikits.child(empty_view,ui.empty_pic)
			local cur_empty_pic = src_empty_pic:clone()
			subject_view:addChild(cur_empty_pic)	
		return
	end	

	for i, obj in pairs(test_list) do	
		for j, obj in pairs(all_subject_list) do
			if test_list[i][1] == all_subject_list[j][1] then	
				local subject_samename = subject_view:getChildByTag(all_subject_list[j][3])		
				local subject_samepos = subject_view:getChildByTag(all_subject_list[i][3])
				local cur_subject = subject_samename:clone()
				local label_error_num = cur_subject:getChildByTag(all_subject_list[j][4])				
				local str_error_num = string.format("%d/%d",test_list[i][3],test_list[i][4])						
				label_error_num:setString(str_error_num)
				cur_subject:setPosition(subject_samepos:getPosition())
				cur_subject:setVisible(true)	
				cur_subject.courseid = test_list[i][1]
				cur_subject.course = test_list[i][2]
				cur_subject.label = str_error_num
				--print(test_list[i][2].."+"..str_error_num)
			--	cur_subject:addTouchEventListener(persubjectCallback)
				uikits.event(cur_subject,
						function(sender,eventType)
							local cur_subject = sender
							local pageView = uikits.child(self._widget,ui.PAGEVIEW) --获取翻页层容器
							local pageindex = pageView:getCurPageIndex()
							local scene_next = persubject.create(cur_subject.course,cur_subject.label,cur_subject.courseid,pageindex+1)								
							--cc.Director:getInstance():replaceScene(scene_next)	
							uikits.pushScene(scene_next)	
						end,"click")		
				subject_view:addChild(cur_subject)	
				break
			end
		end
	end						
end

--获取每页课程内容
function WrongSubjectList:showsubjectlist(src_view,list_type)

	local cur_view = src_view:clone()
	cur_view:setPosition(cc.p(0,0))		
	--cur_view:setAnchorPoint(cc.p(0.5,0.5))
	cur_view:setVisible(true)
	
	local temp_view = uikits.child(cur_view,ui.LES_VIEW)
	--local temp_view = cur_view:getChildByTag(20)
	temp_view:setBounceEnabled(false)

	--处理左右翻动按钮控制翻动页面
	--左翻	
	local but_left_n = uikits.child(cur_view,ui.leftbut)
	uikits.event(but_left_n,
		function(sender,eventType)
			local pageView = uikits.child(self._widget,ui.PAGEVIEW) --获取翻页层容器
			local cur_index = pageView:getCurPageIndex()
			if cur_index ~= 0 then
				cur_index = cur_index-1 
			end						
			pageView:scrollToPage(cur_index)		
		end,"click")	
		
	--右翻
	local but_right_n = uikits.child(cur_view,ui.rightbut)
	uikits.event(but_right_n,
		function(sender,eventType)
			local pageView = uikits.child(self._widget,ui.PAGEVIEW) --获取翻页层容器
			local cur_index = pageView:getCurPageIndex()
			if cur_index ~= 2 then
				cur_index = cur_index+1 
			end						
			pageView:scrollToPage(cur_index)				
		end,"click")	

--	local temp_subject
	if list_type == 1 then		
		self:setsubjects(temp_view,self.wronglist7)
	elseif list_type == 2 then
		self:setsubjects(temp_view,self.wronglist30)
	elseif list_type == 3 then
		self:setsubjects(temp_view,self.wronglist180)
	end	
	return cur_view
end
WrongSubjectList.wronglist7 = {}
WrongSubjectList.wronglist30 = {}
WrongSubjectList.wronglist180 = {}
function WrongSubjectList:format_listdata(all_subject)
	--local num = table.getn(all_subject)
	local wronglist7_num = 1
	local wronglist30_num = 1
	local wronglist180_num = 1
	for i, obj in pairs(all_subject) do
		if all_subject[i].range == 1 then		
			if all_subject[i].course ~= 0 then			
				self.wronglist7[wronglist7_num] = {}				
				self.wronglist7[wronglist7_num][1] = all_subject[i].course
				for j,obj in pairs(course_map) do
					if course_map[j][1] == all_subject[i].course then
						self.wronglist7[wronglist7_num][2] = course_map[j][2]
						break
					end 
				end
				--self.wronglist7[wronglist7_num][2] = course_map[all_subject[i].course]
				self.wronglist7[wronglist7_num][3] = all_subject[i].corr_cnt
				self.wronglist7[wronglist7_num][4] = all_subject[i].wront_cnt
				wronglist7_num = wronglist7_num+1							
			end											
		elseif all_subject[i].range == 2 then
			if all_subject[i].course ~= 0 then
				self.wronglist30[wronglist30_num] = {}
				self.wronglist30[wronglist30_num][1] = all_subject[i].course
				for j,obj in pairs(course_map) do
					if course_map[j][1] == all_subject[i].course then
						self.wronglist30[wronglist30_num][2] = course_map[j][2]
						break
					end 
				end
				--self.wronglist30[wronglist30_num][2] = course_map[all_subject[i].course]
				self.wronglist30[wronglist30_num][3] = all_subject[i].corr_cnt
				self.wronglist30[wronglist30_num][4] = all_subject[i].wront_cnt
				wronglist30_num = wronglist30_num+1
			end
		elseif all_subject[i].range == 3 then
			if all_subject[i].course ~= 0 then
				self.wronglist180[wronglist180_num] = {}
				self.wronglist180[wronglist180_num][1] = all_subject[i].course
				for j,obj in pairs(course_map) do
					if course_map[j][1] == all_subject[i].course then
						self.wronglist180[wronglist180_num][2] = course_map[j][2]
						break
					end 
				end
				--self.wronglist180[wronglist180_num][2] = course_map[all_subject[i].course]
				self.wronglist180[wronglist180_num][3] = all_subject[i].corr_cnt
				self.wronglist180[wronglist180_num][4] = all_subject[i].wront_cnt
				wronglist180_num = wronglist180_num+1	
			end	
		end
		--all_subject[i].
	end
end

function WrongSubjectList:updatepage()
	local subject_view
	if _G.screen_type == 1 then		
		subject_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/lesson.json")
	else	
		subject_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/lesson43.json")	
	end
	local pageView = uikits.child(self._widget,ui.PAGEVIEW) --获取翻页层容器
	
	subject_view:setVisible(false)	
	--添加翻页内容
	for i = 1 , 3 do	
		local cur_view = self:showsubjectlist(subject_view,i)		
		pageView:addPage(cur_view)			
	end	
	print(os.time())
	--翻页动作处理，改变光标位置
	uikits.event(pageView,
			function(sender,eventType)
				if eventType == ccui.PageViewEventType.turning then
					local pageView = sender
					local cur_index = pageView:getCurPageIndex()
					local day_view = uikits.child(self._widget,ui.DAYVIEW)
					local day_sel = uikits.child(self._widget,ui.daysel)		
					local widgetSize = day_view:getContentSize()
					day_sel:setPositionX(widgetSize.width/6.0*(cur_index*2+1))
				end		
			end)
end

function WrongSubjectList:getdatabyurl()
	local send_data
	send_data = "?show_type=2"
--[[	local send_url = t_nextview[2].url..send_data
	local result = kits.http_get(send_url,cookie1,1)
					print(result)	
					local tb_result = json.decode(result)
					if 	tb_result.result ~= 0 then				
						print(tb_result.result.." : "..tb_result.message)				
					end	--]]
					
	local loadbox = loadingbox.open(self)
	cache.request_json( t_nextview[1].url..send_data,function(t)
			if t and type(t)=='table' then
				if t.result ~= 0 then
					if t.result ~= 100 then
						loadbox:removeFromParent()
						return false
					end
					
				else
					self:format_listdata(t.exer_book_stat)
				end
				self:updatepage()
			end
			loadbox:removeFromParent()
		end,'N')
	
--	print(result)	
	return true
end

function WrongSubjectList:init()
	
	--local subject_view
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/wrong_day.json")		
		--self.subject_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/lesson.json")
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/wrong_day43.json")		
		--self.subject_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/lesson43.json")	
	end
	self:addChild(self._widget)
	
	local pageView = uikits.child(self._widget,ui.PAGEVIEW) --获取翻页层容器

	--处理按钮切换翻页
	local day_view = uikits.child(self._widget,ui.DAYVIEW)
	local day_sel = uikits.child(self._widget,ui.daysel)	
	local but_day7_n = uikits.child(self._widget,ui.day7but)
	local but_day30_n = uikits.child(self._widget,ui.day30but)
	local but_day180_n = uikits.child(self._widget,ui.day180but)
	--7天
	uikits.event(but_day7_n,
			function(sender,eventType)
				local cur_index = 0		
				pageView:scrollToPage(cur_index)
			end,"click")		
	
	--30天	
	uikits.event(but_day30_n,
			function(sender,eventType)
				local cur_index = 1		
				pageView:scrollToPage(cur_index)
			end,"click")
	
	--180天
	uikits.event(but_day180_n,
			function(sender,eventType)
				local cur_index = 2		
				pageView:scrollToPage(cur_index)
			end,"click")	
	
	--处理切换收藏按钮
	local mainmenu = uikits.child(self._widget,ui.day180but)
	local but_collect = uikits.child(self._widget,ui.collectbut)
	
	uikits.event(but_collect,
			function(sender,eventType)
				local scene_next = CollectView.create()								
				cc.Director:getInstance():replaceScene(scene_next)			
			end,"click")

	--处理切换统计按钮
	local but_statistics = uikits.child(self._widget,ui.statisticsbut)	
	uikits.event(but_statistics,
			function(sender,eventType)
				local scene_next = StatisticsView.create()								
				cc.Director:getInstance():replaceScene(scene_next)		
			end,"click")
	--处理切换更多按钮
	local but_more = uikits.child(self._widget,ui.morebut)
	uikits.event(but_more,
			function(sender,eventType)
				local scene_next = MoreView.create()								
				cc.Director:getInstance():replaceScene(scene_next)			
			end,"click")
			
	local ret = self:getdatabyurl()
	if ret == false then
		print("WrongSubjectList get error!")
		return
	end
end

function WrongSubjectList:release()
	self._widget = nil
end
return {
create = create,
}
