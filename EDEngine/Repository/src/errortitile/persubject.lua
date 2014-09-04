local uikits = require "uikits"
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "src/errortitile/loadingbox"
local cache = require "cache"
local dopractice = require "src/errortitile/dopractice"
local topics = require "src/errortitile/topics"
local login = require "login"
--local answer = curweek or require "src/errortitile/answer"
local BigquestionView = require "src/errortitile/BigquestionView"
local persubject = class("persubject")
persubject.__index = persubject
local wrong_space = 10
local scale = 640/1920
--local save_is_collect

local is_loading

--[[persubject.subject_name = nil
persubject.subject_label = nil
persubject.range = nil
persubject.subject_id = nil
persubject.pageindex = nil
persubject.wrongtitleitems = {}
persubject.totalpagecount = 0--]]

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(name,label,id,range)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),persubject)		
	if name == nil then
--[[		print("11111111")--]]
		cur_layer.subject_name = "未知科目"		
	else
--[[		if type(name)=='table' then
			print("222222")
		else
			print("333333333")
		end--]]
		cur_layer.subject_name = name	
	end
	if label == nil then
		cur_layer.subject_label = ""		
	else
		cur_layer.subject_label = label	
	end
--[[	print("range::::"..range)--]]
	if range == nil then
		cur_layer.range = 1		
	else
		cur_layer.range = range	
	end	
	if id == nil then
		cur_layer.subject_id = 101		
	else
		cur_layer.subject_id = id	
	end	
	cur_layer.subject_id = id
	cur_layer.pageindex = 1
	cur_layer.has_correct = 0
--	print(name.."::"..label.."::"..range.."::"..id.."::")
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

function persubject:addwrong(index,src_wrongview,src_wrongview_has,src_wrongview_no,tb_wrongtitle_item)
	
	local wrong_view
	local is_first
	local row_num
	local pos_x
	local pos_y
	local check_view
	local but_more
	local infomation_view
	local label_difficulty
	local tag_collect
	local wrong_per
	local answer_view
	local label_myanswer
	local questions_view
	local label_type
	
	wrong_view = src_wrongview:clone()
	self.main_wrongview:addChild(wrong_view,1,1000+index)
	if _G.screen_type == 1 then

		if index%2 == 1 then
		--	is_first = true
			pos_x = src_wrongview_has:getPositionX()	
			--print("1--index:"..src_wrongview_has:getPosition())	
		else
		--	is_first = false
			pos_x = src_wrongview_no:getPositionX()		
		--	print("2--index:"..src_wrongview_no:getPosition())
		end		
		row_num = index/2
		row_num = math.ceil(row_num)
	else
		pos_x = src_wrongview_has:getPositionX()
		row_num = index
	end			

	if tb_wrongtitle_item.isright == 1 then
		check_view = wrong_view:getChildByTag(388)			
		infomation_view = wrong_view:getChildByTag(374)
		but_more = infomation_view:getChildByTag(375)
		label_difficulty = infomation_view:getChildByTag(378)
		wrong_per = infomation_view:getChildByTag(380)
		label_type = infomation_view:getChildByTag(376)
		tag_collect = wrong_view:getChildByTag(399)
	--	answer_view = wrong_view:getChildByTag(381)
	--	label_myanswer = answer_view:getChildByTag(386)
		questions_view = wrong_view:getChildByTag(387)
	else		
		--print(tb_wrongtitle_item.isright)
		check_view = wrong_view:getChildByTag(344)
		infomation_view = wrong_view:getChildByTag(321)
		but_more = infomation_view:getChildByTag(331)
		label_difficulty = infomation_view:getChildByTag(326)
		wrong_per = infomation_view:getChildByTag(330)
		label_type = infomation_view:getChildByTag(322)
		tag_collect = wrong_view:getChildByTag(397)
	--	answer_view = wrong_view:getChildByTag(332)
	--	label_myanswer = answer_view:getChildByTag(343)
		questions_view = wrong_view:getChildByTag(333)
	end
	
	-- 测试题干显示
	local size_questions_view = questions_view:getContentSize()
	local scrollView = ccui.ScrollView:create()
    scrollView:setTouchEnabled(true)
    scrollView:setContentSize(size_questions_view)        
    scrollView:setPosition(cc.p(0,0))
	
    questions_view:addChild(scrollView)
	local data = {}
	if tb_wrongtitle_item.item_type > 0 and tb_wrongtitle_item.item_type < 13 then
		if topics.types[tb_wrongtitle_item.item_type].conv(tb_wrongtitle_item,data) then
			data.eventInitComplate = function(layout,data)
				local arraychildren = scrollView:getChildren()
				for i=1,#arraychildren do 
					arraychildren[i]:setEnabled(false)
				end
			end
			data._options = nil
			--scrollView:setEnabled(false)
			topics.types[tb_wrongtitle_item.item_type].init(scrollView,data)
		end		
	end	
	scrollView:addTouchEventListener(				
					function(sender,eventType)
						if eventType == ccui.TouchEventType.began then
							self.main_wrongview:setEnabled(false)
						elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
							self.main_wrongview:setEnabled(true)	
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
	
	questions_but.tb_wrongtitle_item = tb_wrongtitle_item
	questions_but.file_path = questions_path
	--print(self.name..'+'..self.label..'+'..self.range..'+'..self.id)
	--questions_but:addTouchEventListener(questionsCallback)
	uikits.event(questions_but,
		function(sender,eventType)
			local questions_but = sender
			local save_is_collect = tag_collect:isVisible()		
			local scene_next = BigquestionView.create(questions_but.tb_wrongtitle_item,questions_but.file_path,save_is_collect,self.subject_name,self.subject_label,self.range,self.subject_id)								
			--local scene_next = BigquestionView.create(questions_but.isright,questions_but.answer,questions_but.correct_answer,questions_but.question_id,questions_but.file_path,questions_but.question_type,questions_but.difficulty,questions_but.perwrong,save_is_collect,self.subject_name,self.subject_label,self.range,self.subject_id)								
			--cc.Director:getInstance():replaceScene(scene_next)	
			uikits.pushScene(scene_next)
		end,"click")
	questions_view:addChild(questions_but)
	--完成测试
	
	local size  = wrong_view:getContentSize()
	pos_y = self.main_wrongview:getInnerContainerSize().height-(size.height+ wrong_space)*row_num	
	wrong_view:setPosition(cc.p(pos_x,pos_y))	
	wrong_view:setVisible(true)
	
	label_difficulty:setString(tb_wrongtitle_item.difficulty)

	if tb_wrongtitle_item.is_col == 1 then
		tag_collect:setVisible(true)
	else
		tag_collect:setVisible(false)
	end
	--label_myanswer:setString(tb_wrongtitle_item.answer)
	wrong_per:setString(tb_wrongtitle_item.perwrong.."%")
	print(tb_wrongtitle_item.item_name)
	label_type:setString(tb_wrongtitle_item.item_name)
	
	--设置复选框，只可单独选择一个错误原因		
	local check_boxlist = check_view:getChildren()
	local check_boxnum = check_view:getChildrenCount()	
	for i=1,check_boxnum do	
		if _G.user_status == 1 then
			check_boxlist[i]:setEnabled(true)
		elseif _G.user_status == 2 then
			check_boxlist[i]:setEnabled(false)
		end		
		if i ~= tb_wrongtitle_item.reason then
			--local per_checkbox = check_view:getChildByTag(72+i)
			check_boxlist[i]:setSelectedState(false)
		else
			check_boxlist[i]:setSelectedState(true)
		end
	end
	local checkview_size = check_view:getContentSize()
	local per_checkbox_size = check_boxlist[1]:getContentSize()
	local per_checkbox_posX = check_boxlist[1]:getPositionX()
	check_view:setInnerContainerSize(cc.size((per_checkbox_size.width+(per_checkbox_posX-per_checkbox_size.width/2))*check_boxnum,checkview_size.height))

	local i
	for i=1,check_boxnum do	
		uikits.event(check_boxlist[i],
			function(sender,eventType)
				--print(ccui.CheckBoxEventType.selected)	
				if eventType == true then		
					local j
					local send_url
					local tag = sender:getTag()
					for j=1,check_boxnum do			
						local tag_box = check_boxlist[j]:getTag()
						if tag ~= tag_box then
							--local per_checkbox = check_view:getChildByTag(72+i)
							check_boxlist[j]:setSelectedState(false)
						else		
							local base_url
							if t_nextview then
								base_url = t_nextview[3].url
							else
								base_url = "http://app.lejiaolexue.com/exerbook/handler/ItemReason.ashx"
							end
							if check_boxlist[j]:getSelectedState() == true then
								send_url = base_url.."?item_id="..tb_wrongtitle_item.item_id.."&reason="..j
							else
								send_url = base_url.."?item_id="..tb_wrongtitle_item.item_id.."&reason="..0
							end	
						end			

					end
					--print(send_url)
					local result = kits.http_get(send_url,login.cookie(),1)
					--print(result)	
					local tb_result = json.decode(result)
					if 	tb_result.result ~= 0 then				
						print(tb_result.result.." : "..tb_result.message)				
					end	
				end
			end)
	end
	
	--处理更多操作按钮
	--local share_view = 
	--self.share_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/share.json")	
	if _G.user_status == 1 then
		but_more:setVisible(true)
	elseif _G.user_status == 2 then
		but_more:setVisible(false)
	end		
	local share_box_src = self.share_view:getChildByTag(657)
	but_more.share_box = share_box_src:clone()

	--but_more.share_box:setScale(1.5)
	
	local size_share = but_more.share_box:getContentSize()
	local size_but = but_more:getContentSize()
	local size_view = wrong_view:getContentSize()
	--wrong_view:addChild(but_more.share_box)
	
	but_more.share_box:setPosition(cc.p(size_view.width-size_share.width,size_view.height-(size_share.height+size_but.height)))
	but_more.share_box:setVisible(false)
	local but_collect = but_more.share_box:getChildByTag(661)
	if tb_wrongtitle_item.is_col == 1 then
		but_collect:setSelectedState(false)
	else
		but_collect:setSelectedState(true)
	end		
	
	wrong_view:addChild(but_more.share_box)	
	local but_sendtofriend = but_more.share_box:getChildByTag(660)
	local but_sendtogroup = but_more.share_box:getChildByTag(659)
	
	--设置收藏按钮功能
	uikits.event(but_collect,
		function(sender,eventType)
			local but_collect = sender		
			local send_url
			but_more.share_box:setVisible(false)
			local base_url
			if t_nextview then
				base_url = t_nextview[4].url
			else
				base_url = "http://app.lejiaolexue.com/exerbook/handler/ItemCol.ashx"
			end
			send_url = base_url.."?item_id="..tb_wrongtitle_item.item_id			
			local result = kits.http_get(send_url,login.cookie(),1)	
			--print(t_nextview[4].url.."?item_id="..tb_wrongtitle_item.item_id)
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
				if tb_result.is_col == 1 then
					tag_collect:setVisible(true)
					if iscollect == false then
						but_collect:setSelectedState(true)
					end						
				else
					tag_collect:setVisible(false)	
					if iscollect == true then
						but_collect:setSelectedState(false)
					end						
				end			
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
end

function persubject:encodeURI(s)
	s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
	return string.gsub(s, " ", "+")
end

function persubject:updatepage()
	self.share_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/share.json")
	self.main_wrongview = 	self._widget:getChildByTag(400)  --获取整体错题view
	local per_wrongview_has = self.main_wrongview:getChildByTag(373)  --获取单个已纠错错题view	
--	per_wrongview_has:setVisible(false)
	local per_wrongview_no = self.main_wrongview:getChildByTag(318)  --获取单个未纠错错题view	
--	per_wrongview_no:setVisible(false)
	--计算行数，设置滚动层长度
	if self.pageindex == 1 then
		local error_title_num = table.getn(self.wrongtitleitems)
		local row_num
		row_num = error_title_num/2	
		row_num = math.ceil(row_num)
		local size  = per_wrongview_has:getContentSize()	
		local size_win = self._widget:getContentSize()
		self.main_wrongview:setInnerContainerSize(cc.size(size_win.width,(size.height+wrong_space)*row_num))

		for i,obj in pairs(self.wrongtitleitems) do
			if self.wrongtitleitems[i].isright ~= 1 then		
				--self.has_correct = true
				self:addwrong(i,per_wrongview_no,per_wrongview_has,per_wrongview_no,self.wrongtitleitems[i])
			else			
				self:addwrong(i,per_wrongview_has,per_wrongview_has,per_wrongview_no,self.wrongtitleitems[i])
			end			
		end		
	else
		local error_title_num = table.getn(self.wrongtitleitems)
		local row_num
		row_num = error_title_num/2	
		row_num = math.ceil(row_num)
		local size  = per_wrongview_has:getContentSize()		
		local size_old = self.main_wrongview:getInnerContainerSize()
		local count_old = self.main_wrongview:getChildrenCount()-2
		self.main_wrongview:setInnerContainerSize(cc.size(size_old.width,size_old.height+(size.height+wrong_space)*row_num))
		
		local wrongview = self.main_wrongview:getChildren()
		local pos
		for i,obj in pairs(wrongview) do
			local is_clone = wrongview[i]:isVisible()
			if is_clone == true then
				local per_size_old_x = wrongview[i]:getPositionX()
				local per_size_old_y = wrongview[i]:getPositionY()+(size.height+wrong_space)*row_num
				wrongview[i]:setPosition(cc.p(per_size_old_x,per_size_old_y))		
			else
				pos = wrongview[i]:getPositionX()
			end
		end
		pos = per_wrongview_no:getPositionX()
		
		for i,obj in pairs(self.wrongtitleitems) do
			if self.wrongtitleitems[i].isright ~= 1 then		
				self:addwrong(i+count_old,per_wrongview_no,per_wrongview_has,per_wrongview_no,self.wrongtitleitems[i])
				pos = per_wrongview_no:getPositionX()
			else			
				self:addwrong(i+count_old,per_wrongview_has,per_wrongview_has,per_wrongview_no,self.wrongtitleitems[i])
			end			
		end	
	end
end

function persubject:getdatabyurl()
	local send_data
	if _G.user_status == 1 then
		send_data = "?range="..self.range.."&course="..self.subject_id.."&page="..self.pageindex.."&show_type=2"
	elseif _G.user_status == 2 then
		send_data = "?range="..self.range.."&course="..self.subject_id.."&page="..self.pageindex.."&show_type=2&user_id=".._G.cur_child_id
	end
	
--[[	local send_url = t_nextview[2].url..send_data
	local result = kits.http_get(send_url,login.cookie(),1)
	--kits.log('ERROR--result:::'..result )
	local tb_result = json.decode(result)
	if 	tb_result.result ~= 0 then				
		print(tb_result.result.." : "..tb_result.message)				
	end	
	self.totalpagecount = tb_result.page_total
	self.wrongtitleitems = tb_result.exerbook_user_items	
	self.has_correct = tb_result.has_correct
	local tab_json = {}
	for i,obj in pairs(self.wrongtitleitems) do
		tab_json[i] = self.wrongtitleitems[i].item_id
	end
	local json_data = {}
	json_data.item_id = tab_json
	send_data = json.encode(json_data)
	result = kits.http_post(t_nextview[8].url,send_data,login.cookie(),1)
	local tb_result = json.decode(result)
	if tb_result.result == 0 then
		local tb_perwrong = tb_result.exer_book_stat
		for i,obj in pairs(tb_perwrong) do
			self.wrongtitleitems[i].perwrong = tb_perwrong[i].wrong_per
		end
	end
	self:updatepage()--]]
					
	local loadbox = loadingbox.open(self)
	is_loading = true
	local send_url
	if t_nextview then
		send_url = t_nextview[2].url 
	else
		send_url = "http://app.lejiaolexue.com/exerbook/handler/ExerPreview.ashx"
	end
	cache.request_json( send_url..send_data,function(t)	
			if t and type(t)=='table' then
				self.totalpagecount = t.page_total
				self.wrongtitleitems = t.exerbook_user_items	
				self.has_correct = t.has_correct
				local tab_json = {}
				for i,obj in pairs(self.wrongtitleitems) do
					tab_json[i] = self.wrongtitleitems[i].item_id
				end
				local json_data = {}
				json_data.item_id = tab_json
				send_data = json.encode(json_data)
				local base_url
				if t_nextview then
					base_url = t_nextview[8].url 
				else
					base_url = "http://app.lejiaolexue.com/exerbook/handler/ItemWrongPer.ashx"
				end				
				result = kits.http_post(base_url,send_data,login.cookie(),1)
				local tb_result = json.decode(result)
				if tb_result.result == 0 then
					local tb_perwrong = tb_result.exer_book_stat
					for i,obj in pairs(tb_perwrong) do
						self.wrongtitleitems[i].perwrong = tb_perwrong[i].wrong_per
					end
				end
				self:updatepage()
			end
			loadbox:removeFromParent()
			is_loading = false
		end,'N')	
	return true
end

function persubject:showpracticeview()
	self.practice_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/practice_up.json")	
	local practice_view = self.practice_view:getChildByTag(832)--获取开始练习的对话框
	local practice_title = practice_view:getChildByTag(833)--获取对话框title
	local but_close = practice_title:getChildByTag(834)--获取关闭按钮
	local but_practice_all = practice_view:getChildByTag(835)--获取全部重做按钮
	local but_practice_no = practice_view:getChildByTag(836)--获取只做错题按钮
	
	local size_win = self._widget:getContentSize()
	local size_view = practice_view:getContentSize()
	practice_view:setPosition(cc.p((size_win.width-size_view.width)/2,(size_win.height-size_view.height)/2))
	--practice_view:
	
	--设置关闭按钮功能
	
	uikits.event(but_close,
			function(sender,eventType)
				self.practice_view:setVisible(false)	
			end,"click")	
	
		--设置全部重做按钮功能
	uikits.event(but_practice_all,
			function(sender,eventType)
				self.practice_view:setVisible(false)
				local send_data
				send_data = "?range="..self.range.."&course="..self.subject_id.."&redoflag=2&show_type=2"
				local loadbox = loadingbox.open(self)
				local base_url
				if t_nextview then
					base_url = t_nextview[9].url 
				else
					base_url = "http://app.lejiaolexue.com/exerbook/handler/ItemsEditItemids.ashx"
				end		
				cache.request_json( base_url..send_data,function(t)
						local tb_item_id
						if t and type(t)=='table' then
							tb_item_id = t.exerbook_user_items
						end
						loadbox:removeFromParent()
						local scene_next = dopractice.create(tb_item_id)
						uikits.pushScene(scene_next)									
						--cc.Director:getInstance():replaceScene(scene_next)		
					end,'N')	
			end,"click")	

		--设置只做错题按钮功能
	uikits.event(but_practice_no,
			function(sender,eventType)
				self.practice_view:setVisible(false)
				local send_data
				send_data = "?range="..self.range.."&course="..self.subject_id.."&redoflag=1&show_type=2"
				local loadbox = loadingbox.open(self)
				local base_url
				if t_nextview then
					base_url = t_nextview[9].url 
				else
					base_url = "http://app.lejiaolexue.com/exerbook/handler/ItemsEditItemids.ashx"
				end		
				cache.request_json( base_url..send_data,function(t)
						local tb_item_id
						if t and type(t)=='table' then
							tb_item_id = t.exerbook_user_items
						end
						loadbox:removeFromParent()
						local scene_next = dopractice.create(tb_item_id)
						uikits.pushScene(scene_next)									
					--	cc.Director:getInstance():replaceScene(scene_next)		
					end,'N')			
			end,"click")	

	self:addChild(self.practice_view,10000)
end

function persubject:updatewrongview()
	if self.pageindex == self.totalpagecount then
		return
	end
	self.pageindex = self.pageindex+1
	
	local ret = self:getdatabyurl()
	if ret == false then
		print("persubject get error!")
		return
	end
end	

function persubject:init()	
	local design	
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		topics.set_scale(1.2)
		_G.screen_type = 1
		design = {width=1920,height=1080}
	else
		topics.set_scale(1)
		_G.screen_type = 2
		design = {width=1440,height=1080}	
	end
	uikits.initDR(design)
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/inlesson.json")		
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/inlesson43.json")		
	end
	self:addChild(self._widget)
	--self.share_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/share.json")
	--self.practice_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/practice_up.json")	
	self:showpracticeview()
	self.practice_view:setVisible(false)
	local ret = self:getdatabyurl()
	if ret == false then
		print("persubject get error!")
		return
	end
	
	self.main_wrongview = 	self._widget:getChildByTag(400)  --获取整体错题view
	local per_wrongview_has = self.main_wrongview:getChildByTag(373)  --获取单个已纠错错题view	
	per_wrongview_has:setVisible(false)
	local per_wrongview_no = self.main_wrongview:getChildByTag(318)  --获取单个未纠错错题view	
	per_wrongview_no:setVisible(false)	
	
	local title = self._widget:getChildByTag(312) --获取title

	local subject_name = title:getChildByTag(314) --获取科目名称
	subject_name:setString(self.subject_name.."错题")
	local error_num = title:getChildByTag(316) --获取错题数目文字描述	
	error_num:setString(self.subject_label)
	
	local but_goback = title:getChildByTag(313)   --获取返回按钮	
	 --处理返回按钮，切换至首页
	uikits.event(but_goback,
	function(sender,eventType)
--[[		local t_wronglist = package.loaded["src/errortitile/WrongSubjectList"]
		if t_wronglist then
			local scene_next = t_wronglist.create()				
			cc.Director:getInstance():replaceScene(scene_next)								
		end				--]]
		uikits.popScene()
	end,"click")
	
	local but_practice = title:getChildByTag(317) --获取错题重做按钮
	--处理错题重做按钮	
	uikits.event(but_practice,
	function(sender,eventType)
		self.practice_view:setVisible(true)	
		local practice_view = self.practice_view:getChildByTag(832)--获取开始练习的对话框
		local but_practice_no = practice_view:getChildByTag(836)--获取只做错题按钮
		print("self.has_correct::"..self.has_correct)
		if self.has_correct == 0 then
			but_practice_no:setVisible(false)
		else
			but_practice_no:setVisible(true)
		end			
	end,"click")	
	if _G.user_status == 1 then
		but_practice:setVisible(true)
	elseif _G.user_status == 2 then
		but_practice:setVisible(false)
	end	
	--下拉更新错题列表
	uikits.event(self.main_wrongview,
		function(sender,eventType)
			if eventType == ccui.ScrollviewEventType.scrollToBottom then
				if is_loading == false then
					self:updatewrongview()				
				end
			end
		end)	
	
end

function persubject:clear_all_item()
	self.pageindex = 1
--[[	self.wrongtitleitems = {}
	self.subject_name = nil
	self.subject_label = nil
	self.range = nil
	self.subject_id = nil
	self.pageindex = nil
	self.main_wrongview:removeAllChildren()
	self.main_wrongview = {}--]]
--[[	if self._list then
		for i =1,#self._list do
			local u = uikits.child( self._list[i],ui.END_DATE )
			if u and u._scID then
				u:getScheduler():unscheduleScriptEntry(u._scID)
			end
			if i ~= 1 then
				self._list[i]:removeFromParent()
			else
				self._list[i]:setVisible(false) --第一个是模板
			end
		end
		self._list = {}
	end--]]
	local default_scale = topics.get_default_scale()
	topics.set_scale(default_scale)
end

function persubject:release()
	self:clear_all_item()
end
return {
create = create,
}