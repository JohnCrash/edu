local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "src/errortitile/loadingbox"
local cache = require "cache"
local login = require "login"
local StatisticsView = require "src/errortitile/StatisticsView"
local Percollectsubject = require "src/errortitile/Percollectsubject"
local CollectView = class("CollectView")
CollectView.__index = CollectView

local all_subject_list = {
{10001,"语文",1114,1115},
{10002,"数学",1116,1117},
{10003,"英语",1118,1119},
{20004,"物理",1120,1121},
{20005,"化学",1122,1123},
{20006,"政治",1124,1125},
{20009,"历史",1126,1127},
{20008,"地理",1128,1129},
{4,"科学",1130,1131},
{10009,"信息技术",1132,1133},
{20007,"生物",1134,1135},
{10005,"英语",1118,1119},
{20001,"语文",1114,1115},
{20002,"数学",1116,1117},
{20003,"英语",1118,1119},
{30001,"语文",1114,1115},
{30002,"数学",1116,1117},
{30003,"英语",1118,1119},
{30004,"物理",1120,1121},
{30005,"化学",1122,1123},
{30006,"政治",1124,1125},
{30007,"生物",1134,1135},
{30008,"地理",1128,1129},
{30009,"历史",1126,1127},
--{0,"全部",593}
}

local all_subject_list_practice = {
{10001,"语文",847},
{10002,"数学",848},
{3,"英语",849},
{4,"科学",850},
{5,"信息技术",851},
{10,"物理",852},
{9,"化学",853},
{8,"生物",854},
{7,"历史",855},
{6,"地理",856},
{11,"政治",857},
--{0,"全部",593}
}

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(name,label)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),CollectView)		
	cur_layer.subject_name = name
	cur_layer.subject_label = label
	cur_layer.collectitems = {}
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

--展示收藏题滚动页内容	
function CollectView:showpagedata(page_data)
	local send_data			
	send_data = "?course="..page_data.courseid.."&page=".."1".."&show_type=1".."&time="..page_data.time	
	local result = kits.http_get(t_nextview[6].url..send_data,login.cookie(),1)	
	--print(result)
	local tb_pagedata = json.decode(result)
	if 	tb_pagedata.result == 0 then
--[[		if tb_pagedata.time == 	page_data.time then		
			print("no change time= "..page_data.time)
			return
		else
			page_data.time = tb_pagedata.time
		end--]]
		local collect_items = tb_pagedata.exerbook_user_items				
		local per_collectview = page_data:getChildByTag(642)  --获取单个已纠收藏题view			
		per_collectview:setVisible(false)
		--print(per_collectview:isVisible())
		--计算行数，设置滚动层长度
		local collect_title_num = table.getn(collect_items)
		--print(collect_title_num)
		local row_num
		row_num = collect_title_num/2	
		row_num = math.ceil(row_num)
		local size  = per_collectview:getContentSize()	
		local size_win = self._widget:getSize()
		page_data:setInnerContainerSize(cc.size(size_win.width,(size.height+collect_space)*row_num))
		
		for i,obj in pairs(collect_items) do
			self:addcollectitem(i,collect_items[i],page_data,per_collectview)
		end				
	else
		return false
	end			
end

function CollectView:showpracticeview()
	self.practice_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/collection_up.json")	
--	self.practice_view:setPosition(cc.p(0,100))
--	self.practice_view:setScale(0.5)		
	local practice_view = self.practice_view:getChildByTag(832)--获取开始练习的对话框
	local practice_title = practice_view:getChildByTag(833)--获取对话框title
	local but_close = practice_title:getChildByTag(834)--获取关闭按钮
	--local but_practice_all = practice_view:getChildByTag(835)--获取全部重做按钮
	--local but_practice_no = practice_view:getChildByTag(836)--获取只做错题按钮
	
	--设置关闭按钮功能
	local function closeCallback(sender,eventType)
		local but_close = sender
		if eventType == ccui.TouchEventType.ended then		
			self.practice_view:removeFromParent()
			self.practice_view = nil
		end
	end
	but_close:addTouchEventListener(closeCallback)	
	
	--隐藏原有科目按钮
	for i, obj in pairs(all_subject_list_practice) do	
		temp_subject = practice_view:getChildByTag(all_subject_list_practice[i][3])
		temp_subject:setVisible(false)
	end
	
	local function startpracticeCallback(sender,eventType)
		local but_close = sender
		if eventType == ccui.TouchEventType.ended then		
			
		end		
	end
	--添加已有的科目page	
	for i, obj in pairs(self.collectitems) do
		for j,obj in pairs(all_subject_list_practice) do
			if self.collectitems[i].course == all_subject_list_practice[j][1] then
				local subject_samename = practice_view:getChildByTag(all_subject_list_practice[j][3])
				local subject_samepos
				local cur_subject = subject_samename:clone()
				if self.collectitems[i].course == 0 then
					subject_samepos = practice_view:getChildByTag(all_subject_list_practice[j][3])
					cur_subject.courseid = all_subject_list_practice[j][3]
					cur_subject.index = 0
				else
					subject_samepos = practice_view:getChildByTag(all_subject_list_practice[i][3])
					cur_subject.courseid = all_subject_list_practice[j][3]
					cur_subject.index = i
				end															
				cur_subject:setPosition(subject_samepos:getPosition())
				cur_subject:setVisible(true)	
				cur_subject:addTouchEventListener(startpracticeCallback)					
						
				practice_view:addChild(cur_subject)
			end
		end			
	end			
	self:addChild(self.practice_view,1000)
end

function CollectView:updatepage()
	
	local subject_view = self._widget:getChildByTag(1113) --获取科目view
	
	print(#self.collectitems)
	if #self.collectitems == 0 then
		local empty_view
		if _G.screen_type == 1 then		
			empty_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/meishouchang.json")
		else	
			empty_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/meishouchang43.json")	
		end
			local src_empty_pic = empty_view:getChildByTag(3641)
			local cur_empty_pic = src_empty_pic:clone()
			subject_view:addChild(cur_empty_pic)	
		return
	end	
	
	for i, obj in pairs(self.collectitems) do
		for j,obj in pairs(all_subject_list) do
			if self.collectitems[i].course == all_subject_list[j][1] then				
				local subject_samename = subject_view:getChildByTag(all_subject_list[j][3])
				local subject_samepos = subject_view:getChildByTag(all_subject_list[i][3])
				local cur_subject = subject_samename:clone()	
				local label_num = cur_subject:getChildByTag(all_subject_list[j][4])	
				label_num:setString(self.collectitems[i].wront_cnt)			

				cur_subject.courseid = all_subject_list[j][1]				
				cur_subject.label = all_subject_list[j][2]
				cur_subject.num = self.collectitems[i].wront_cnt
	
				cur_subject:setPosition(subject_samepos:getPosition())
				cur_subject:setVisible(true)	
				--cur_subject:addTouchEventListener(showsubjectCallback)		
				uikits.event(cur_subject,
					function(sender,eventType)
						local cur_subject = sender	
						local scene_next = Percollectsubject.create(cur_subject.courseid,cur_subject.label,cur_subject.num)								
						--cc.Director:getInstance():replaceScene(scene_next)		
						uikits.pushScene(scene_next)				
					end,"click")							
				subject_view:addChild(cur_subject)																
			end
		end			
	end				
end

function CollectView:getdatabyurl()
	local send_data
	send_data = "?show_type=1"
	
--[[	local send_url = t_nextview[5].url..send_data
	local result = kits.http_get(send_url,cookie1,1)
	print(result)	
	local tb_result = json.decode(result)
	if 	tb_result.result ~= 0 then				
		print(tb_result.result.." : "..tb_result.message)				
	end	
	self.collectitems = tb_result.exer_book_stat
	self:updatepage()--]]
					
	local loadbox = loadingbox.open(self)
	cache.request_json( t_nextview[5].url..send_data,function(t)
			if t and type(t)=='table' then
				if t.result ~= 0 then
					if t.result ~= 100 then
						loadbox:removeFromParent()
						return false
					end
				else
					self.collectitems = t.exer_book_stat
				end
				self:updatepage()
			end
			loadbox:removeFromParent()
		end,'N')
	return true
end

function CollectView:init()	
--	loadArmature("errortitile/silver/Export/NewAnimation/NewAnimation.ExportJson")		
	if _G.screen_type == 1 then	
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/collection.json")		
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/collection43.json")			
	end
	self:addChild(self._widget)

	
	local subject_view = self._widget:getChildByTag(1113) --获取科目view
	for i, obj in pairs(all_subject_list) do	
		local temp_subject = subject_view:getChildByTag(all_subject_list[i][3])
		temp_subject:setVisible(false)
	end

	--处理切换首页按钮
	local mainmenu = self._widget:getChildByTag(580)
	local but_wronglist = mainmenu:getChildByTag(582)	
	uikits.event(but_wronglist,
			function(sender,eventType)
				local t_wronglist = package.loaded["src/errortitile/WrongSubjectList"]
				if t_wronglist then
					local scene_next = t_wronglist.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end					
			end,"click")
	--处理切换统计按钮
	local but_statistics = mainmenu:getChildByTag(584)
	uikits.event(but_statistics,
			function(sender,eventType)
				local t_statistics = package.loaded["src/errortitile/StatisticsView"]
				if t_statistics then
					local scene_next = t_statistics.create()								
					cc.Director:getInstance():replaceScene(scene_next)								
				end				
			end,"click")	
	--处理切换更多按钮
	local but_more = mainmenu:getChildByTag(585)
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
		print("CollectView get error!")
		return
	end	
end

function CollectView:release()

end
return {
create = create,
}