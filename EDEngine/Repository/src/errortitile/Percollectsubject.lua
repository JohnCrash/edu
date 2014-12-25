local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "loadingbox"
local cache = require "cache"
local dopractice = require "src/errortitile/dopractice"
local login = require "login"
local messagebox = require "messagebox"
local topics = require "src/errortitile/topics"
--local answer = curweek or require "src/errortitile/answer"
--local BigquestionView = require "src/errortitile/BigquestionView"
local Percollectsubject = class("Percollectsubject")
Percollectsubject.__index = Percollectsubject
local collect_space = 10
local is_loading
local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(courseid,label,num)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),Percollectsubject)		
	cur_layer.courseid = courseid
	cur_layer.label = label
	cur_layer.num = num
	cur_layer.time = 0
	cur_layer.pageindex = 1
	cur_layer.totalpagecount = 0
	is_loading = false
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

function Percollectsubject:resetpagedata()
	
	self.pageindex = 1
	local ret = self:getdatabyurl()
	if ret == false then
		return
	end
end

function Percollectsubject:addcollectitem(index,collectitem,page,src_collect_view)
	local wrong_view
	local is_first
	local row_num 
	local pos_x
	local pos_y		
	local but_more
	local infomation_view
	local label_difficulty
	local label_item_name
	local wrong_per	
	local label_wrong_per			
	
	local collect_view = src_collect_view:clone()
	local size  = collect_view:getContentSize()
	if _G.screen_type == 1 then
		row_num = index/2	
		row_num = math.ceil(row_num)
		if index%2 == 1 then
			--is_first = true
			pos_x = src_collect_view:getPositionX()		
			--collect_view:setVisible(true)	
		else
			--is_first = false
			pos_x = src_collect_view:getPositionX()*2+size.width	
		end			
	else
		row_num = index
		pos_x = src_collect_view:getPositionX()	
	end
	collect_view:setVisible(true)						
	pos_y = page:getInnerContainerSize().height-(size.height+ collect_space)*row_num	
	collect_view:setPosition(cc.p(pos_x,pos_y))	
			
	infomation_view = collect_view:getChildByTag(643)
	but_more = infomation_view:getChildByTag(644)
	label_item_name = infomation_view:getChildByTag(645)
	label_wrong_per = infomation_view:getChildByTag(648)
	wrong_per = infomation_view:getChildByTag(649)
	label_difficulty = infomation_view:getChildByTag(647)
	local questions_view = collect_view:getChildByTag(650)
	local size_questions_view = questions_view:getContentSize()

	label_item_name:setString(collectitem.item_name)
	label_difficulty:setString(collectitem.difficulty)				
	wrong_per:setString(collectitem.perwrong.."%")	
	
	label_wrong_per:setVisible(false)
	wrong_per:setVisible(false)
	
	local scrollView = ccui.ScrollView:create()
    scrollView:setTouchEnabled(true)
    scrollView:setContentSize(size_questions_view)        
    scrollView:setPosition(cc.p(0,0))
	
    questions_view:addChild(scrollView)
	local data = {}

	if collectitem.item_type > 0 and collectitem.item_type < 13 then
--		print(topics.types[item_data.item_type])
		if topics.types[collectitem.item_type].conv(collectitem,data) then
			data.eventInitComplate = function(layout,data)
				local arraychildren = scrollView:getChildren()
				for i=1,#arraychildren do 
					arraychildren[i]:setEnabled(false)
				end
			end
			--questions_view:setEnabled(false)
			topics.types[collectitem.item_type].init(scrollView,data)
		end		
	end	
	scrollView:addTouchEventListener(				
					function(sender,eventType)
						if eventType == ccui.TouchEventType.began then
							page:setEnabled(false)
						elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
							page:setEnabled(true)	
						end
					end)
					
	local questions_path = "errortitile/kong.png"
	local questions_but = ccui.Button:create()
	questions_but:setTouchEnabled(true)
	questions_but:loadTextures(questions_path, questions_path, "")
	local size_question = questions_view:getContentSize()	
--	questions_but:setContentSize(size_question)
	local scale_x = size_question.width/questions_but:getContentSize().width
	local scale_y = size_question.height/questions_but:getContentSize().height

	questions_but:setScale(scale_y)
	questions_but:setPosition(cc.p(size_question.width/2,size_question.height/2))
	
--	questions_but.tb_wrongtitle_item = tb_wrongtitle_item
--	questions_but.file_path = questions_path
	--print(self.name..'+'..self.label..'+'..self.range..'+'..self.id)
	--questions_but:addTouchEventListener(questionsCallback)
--[[	uikits.event(questions_but,
		function(sender,eventType)
			local questions_but = sender
			local save_is_collect = tag_collect:isVisible()		
			local scene_next = BigquestionView.create(questions_but.tb_wrongtitle_item,questions_but.file_path,save_is_collect,self.subject_name,self.subject_label,self.range,self.subject_id)								
			--local scene_next = BigquestionView.create(questions_but.isright,questions_but.answer,questions_but.correct_answer,questions_but.question_id,questions_but.file_path,questions_but.question_type,questions_but.difficulty,questions_but.perwrong,save_is_collect,self.subject_name,self.subject_label,self.range,self.subject_id)								
			--cc.Director:getInstance():replaceScene(scene_next)	
			uikits.pushScene(scene_next)
		end,"click")--]]
	questions_view:addChild(questions_but)
						
--	questions_view:addChild()
--	questions_view:setTouchEnabled(false);
	--处理更多操作按钮
	if login.get_uid_type() == login.STUDENT then
		but_more:setVisible(true)
	elseif login.get_uid_type() == login.PARENT then
		but_more:setVisible(false)
	end		
	but_more.share_box = page.share_box_src:clone()

	local size_share = but_more.share_box:getContentSize()
	local size_but = but_more:getContentSize()
	local size_view = collect_view:getContentSize()
	--wrong_view:addChild(but_more.share_box)
	
	but_more.share_box:setPosition(cc.p(size_view.width-size_share.width,size_view.height-(size_share.height+size_but.height)))
	but_more.share_box:setVisible(false)
	local but_collect = but_more.share_box:getChildByTag(661)
	but_collect:setSelectedState(false)	
	
	collect_view:addChild(but_more.share_box)	
	local but_sendtofriend = but_more.share_box:getChildByTag(660)
	local but_sendtogroup = but_more.share_box:getChildByTag(659)
	but_sendtofriend:setEnabled(false)
	but_sendtofriend:setBright(false)
	but_sendtofriend:setTouchEnabled(false)
	but_sendtogroup:setEnabled(false)
	but_sendtogroup:setBright(false)
	but_sendtogroup:setTouchEnabled(false)	
	
	but_collect.parentview = page
	but_collect.item_id = collectitem.item_id
	
	--设置收藏按钮功能
	uikits.event(but_collect,
		function(sender,eventType)
			local but_collect = sender		
			local send_url
			but_more.share_box:setVisible(false)
			send_url = t_nextview[4].url.."?item_id="..but_collect.item_id		
			print(send_url)	
			local result = kits.http_get(send_url,login.cookie(),1)	
			print(result)
			local tb_result = json.decode(result)
			local iscollect = but_collect:getSelectedState()
			if 	tb_result.result ~= 0 then				
				print(tb_result.result.." : "..tb_result.message)
				if iscollect == true then
					but_collect:setSelectedState(false)
				else
					but_collect:setSelectedState(true)
				end			
			else				
				local send_data		
				send_data = "?course="..self.courseid.."&page=".."1".."&show_type=1".."&time="..self.time	
				print(t_nextview[6].url..send_data)			
				local loadbox = loadingbox.open(self)
				is_loading = true
				cache.request_json( t_nextview[6].url..send_data,function(t)
						if t and type(t)=='table' then
							uikits.delay_call(self,self.resetpagedata,1,self)
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
						is_loading = false
						loadbox:removeFromParent()
					end,'N')	
					return true
			end	
	end,"click")
	--设置发送给朋友功能
	uikits.event(but_sendtofriend,
		function(sender,eventType)
			but_more.share_box:setVisible(false)
	end,"click")
	--设置发送到群组功能
	uikits.event(but_sendtogroup,
		function(sender,eventType)
			but_more.share_box:setVisible(false)
	end,"click")
	--设置更多按钮功能	
	uikits.event(but_more,
		function(sender,eventType)
			local but_more = sender		
			local isvis = but_more.share_box:isVisible()
			if isvis == true then
				but_more.share_box:setVisible(false)
			else
				but_more.share_box:setVisible(true)
			end
	end,"click")		
	page:addChild(collect_view,1,1000+index)		
end

function Percollectsubject:updatepage()
	self.share_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/share.json")
	local title = self._widget:getChildByTag(1150) --获取title
	local error_num = title:getChildByTag(1151) --获取错题数目文字描述	
	error_num:setString(self.num)
	
	local page_data = self._widget:getChildByTag(641)				
	local per_collectview = page_data:getChildByTag(642)  --获取单个已纠收藏题view		
	
--	per_wrongview_no:setVisible(false)
	--计算行数，设置滚动层长度
	if self.pageindex == 1 then
		--计算行数，设置滚动层长度
		local collect_title_num = table.getn(self.collect_items)
		--print(collect_title_num)
		local row_num
		if _G.screen_type == 1 then
			row_num = collect_title_num/2	
			row_num = math.ceil(row_num)		
		else
			row_num = collect_title_num
		end
		local size  = per_collectview:getContentSize()	
		local size_win = self._widget:getContentSize()
		page_data:setInnerContainerSize(cc.size(size_win.width,(size.height+collect_space)*row_num))
		page_data.share_box_src = self.share_view:getChildByTag(657)
		for i,obj in pairs(self.collect_items) do
			self:addcollectitem(i,self.collect_items[i],page_data,per_collectview)
		end				
	else
		local collect_title_num = table.getn(self.collect_items)
		local row_num
		row_num = collect_title_num/2	
		row_num = math.ceil(row_num)
		local size  = per_collectview:getContentSize()	
		
		local size_old = page_data:getInnerContainerSize()
		local count_old = page_data:getChildrenCount()-1
		page_data:setInnerContainerSize(cc.size(size_old.width,size_old.height+(size.height+collect_space)*row_num))
		page_data.share_box_src = self.share_view:getChildByTag(657)
		
		local collectview = page_data:getChildren()
		for i,obj in pairs(collectview) do
			local per_size_old_x = collectview[i]:getPositionX()
			local per_size_old_y = collectview[i]:getPositionY()+(size.height+collect_space)*row_num
			collectview[i]:setPosition(cc.p(per_size_old_x,per_size_old_y))
		end
		
		for i,obj in pairs(self.collect_items) do
			self:addcollectitem(i+count_old,self.collect_items[i],page_data,per_collectview)
		end					
	end
end

function Percollectsubject:getdatabyurl()
	local send_data
	
	--send_data = "?course="..self.courseid.."&page="..self.pageindex.."&show_type=1".."&time="..self.time	
	if login.get_uid_type() == login.STUDENT then
		send_data = "?course="..self.courseid.."&page="..self.pageindex.."&show_type=1".."&time="..self.time
	elseif login.get_uid_type() == login.PARENT then
		send_data = "?course="..self.courseid.."&page="..self.pageindex.."&show_type=1".."&time="..self.time.."&user_id="..login.get_subuid()
	end
--	print(t_nextview[6].url..send_data)
	local loadbox = loadingbox.open(self)
	is_loading = true
	cache.request_json( t_nextview[6].url..send_data,function(t)
			if t and type(t)=='table' then
				self.totalpagecount = t.page_total
				self.num = t.total_count	
				self.collect_items = t.exerbook_user_items	
				local tab_json = {}
				for i,obj in pairs(self.collect_items) do
					tab_json[i] = self.collect_items[i].item_id
				end
				local json_data = {}
				json_data.item_id = tab_json
				send_data = json.encode(json_data)
				result = kits.http_post(t_nextview[8].url,send_data,login.cookie(),1)
				local tb_result = json.decode(result)
				if tb_result.result == 0 then
					local tb_perwrong = tb_result.exer_book_stat
					for i,obj in pairs(tb_perwrong) do
						self.collect_items[i].perwrong = tb_perwrong[i].wrong_per
					end
				end
				self:updatepage()
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
			is_loading = false
			loadbox:removeFromParent()
		end,'N')	
	return true	
end

function Percollectsubject:init()	
	if _G.screen_type == 1 then
		topics.set_scale(1.2)
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/collaction_ti.json")	
	else
		topics.set_scale(1)
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/collaction_ti43.json")	
	end
		
	self.share_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/share.json")	
	self:addChild(self._widget)

	local title = self._widget:getChildByTag(1150) --获取title
	local subject_name = title:getChildByTag(1154) --获取科目名称
	subject_name:setString(self.label.."收藏")
--	local error_num = title:getChildByTag(1151) --获取错题数目文字描述	
--	error_num:setString(self.num)
	
	local but_goback = title:getChildByTag(1152)   --获取返回按钮	
	--处理返回按钮，切换至首页	
	uikits.event(but_goback,
		function(sender,eventType)
--[[			local t_collectlist = package.loaded["src/errortitile/CollectView"]
			if t_collectlist then
				local scene_next = t_collectlist.create()								
				cc.Director:getInstance():replaceScene(scene_next)	--]]
				uikits.popScene()								
	end,"click")
	
	local but_practice = title:getChildByTag(1155) --获取错题重做按钮
	--处理错题重做按钮
	uikits.event(but_practice,
		function(sender,eventType)
		local send_data
		send_data = "?range=3".."&course="..self.courseid.."&redoflag=2&show_type=1"
		local loadbox = loadingbox.open(self)
		cache.request_json( t_nextview[9].url..send_data,function(t)
				local tb_item_id
				if t and type(t)=='table' then
					tb_item_id = t.exerbook_user_items
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
				loadbox:removeFromParent()
				local scene_next = dopractice.create(tb_item_id)	
				uikits.pushScene(scene_next)								
				--cc.Director:getInstance():replaceScene(scene_next)		
			end,'N')	
	end,"click")
	if login.get_uid_type() == login.STUDENT then
		but_practice:setVisible(true)
	elseif login.get_uid_type() == login.PARENT then
		but_practice:setVisible(false)
	end		
	
	local page_data = self._widget:getChildByTag(641)				
	local per_collectview = page_data:getChildByTag(642)  --获取单个已纠收藏题view			
	per_collectview:setVisible(false)
	
	uikits.event(page_data,
		function(sender,eventType)
			if eventType == ccui.ScrollviewEventType.scrollToBottom then
				if is_loading == false then
					self:updatecollectview()				
				end
			end
		end)	
	local ret = self:getdatabyurl()
	if ret == false then
		return
	end
end

function Percollectsubject:updatecollectview()
	
	if self.pageindex == self.totalpagecount then
		return
	end
	self.pageindex = self.pageindex+1
	
	local ret = self:getdatabyurl()
	if ret == false then
		print("Percollectsubject get error!")
		return
	end
end	

function Percollectsubject:release()
	self.pageindex = 1
	local default_scale = topics.get_default_scale()
	topics.set_scale(default_scale)
end
return {
create = create,
}