local uikits = require "uikits"
local socket = require "socket"
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "src/errortitile/loadingbox"
local cache = require "cache"
local login = require "login"
local topics = require "src/errortitile/topics"
local BigquestionView = class("BigquestionView")
BigquestionView.__index = BigquestionView

local function loadArmature( name )
		ccs.ArmatureDataManager:getInstance():removeArmatureFileInfo(name)
		ccs.ArmatureDataManager:getInstance():addArmatureFileInfo(name)	
end

function create(tb_wrongtitle_item,file_path,iscollect,name,label,range,id)
	local scene = cc.Scene:create()				
	local cur_layer = uikits.extend(cc.Layer:create(),BigquestionView)		
	cur_layer.file_path = file_path	
	cur_layer.tb_wrongtitle_item = tb_wrongtitle_item	
	cur_layer.iscollect = iscollect
	cur_layer.name = name
	cur_layer.label = label
	cur_layer.range = range
	cur_layer.id = id		
	--print(question_id)
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

function BigquestionView:showanswerview(pic_path)
	local answer_pic = cc.Sprite:create(pic_path)
	self.picup_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/mypic_up.json")
	local answer_mainview = self.picup_view:getChildByTag(2178)
	local answer_picview = answer_mainview:getChildByTag(2184)
	local answer_titleview = answer_mainview:getChildByTag(2179)
	local but_close = answer_titleview:getChildByTag(2180)
	--print(size_win.width..":::"..size_win.height)
	
	local size_answer = answer_picview:getContentSize()	
	local size_pic = answer_pic:getContentSize()
	local scale_x = size_answer.width/size_pic.width
	local scale_y = size_answer.height/size_pic.height
	answer_pic:setScale(scale_y)
	answer_pic:setPosition(cc.p((size_answer.width)/2,(size_answer.height)/2))
	answer_picview:addChild(answer_pic)
	
	local size_win = self._widget:getContentSize()	
	local size_mainview = answer_mainview:getContentSize()	
	answer_mainview:setPosition(cc.p((size_win.width-size_mainview.width)/2,(size_win.height-size_mainview.height)/2))		
	self:addChild(self.picup_view)	
	self._widget:setTouchEnabled(false)
	self.picup_view:setVisible(false)
	--设置关闭按钮功能
	uikits.event(but_close,
		function(sender,eventType)
			self.picup_view:setVisible(false)
		end,"click")
end

function BigquestionView:init()	
	if _G.screen_type == 1 then
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/big_pic.json")		
	else
		self._widget = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/big_pic43.json")
	end
	self.share_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/share.json")
	self:addChild(self._widget)
--	self.picup_view = ccs.GUIReader:getInstance():widgetFromJsonFile("errortitile/TheWrong/Export/mypic_up.json")
	--local design = {width=1920,height=1080}
	--uikits.initDR(design)
	--设置各位置信息
	local titleview = self._widget:getChildByTag(312)
	local but_more = titleview:getChildByTag(375)
	local but_goback = titleview:getChildByTag(313)
	local label_type = titleview:getChildByTag(376)
	local label_difficulty = titleview:getChildByTag(378)
	local label_perwrong = titleview:getChildByTag(380)
	local question_pic_view = self._widget:getChildByTag(400)
	local tag_collect = self._widget:getChildByTag(516)
	local answerview = self._widget:getChildByTag(1782)
	local right_txt = answerview:getChildByTag(1784)
	local right_pic = answerview:getChildByTag(1788)
	local my_txt = answerview:getChildByTag(1787)
	local my_pic = answerview:getChildByTag(1786)
	local right_label = answerview:getChildByTag(1783)
	local my_label = answerview:getChildByTag(1785)	
	
	right_txt:setVisible(false)	
	right_pic:setVisible(false)	
	right_label:setVisible(false)	
	my_txt:setVisible(false)	
	my_pic:setVisible(false)	
	my_label:setVisible(false)	
--	print("self.tb_wrongtitle_item:::"..self.name)
	label_type:setString(self.tb_wrongtitle_item.item_name)
	label_difficulty:setString(self.tb_wrongtitle_item.difficulty)
	label_perwrong:setString(self.tb_wrongtitle_item.perwrong..'%')
	
--[[	local answerpic_path = "errortitile/22.png"
	if answerpic_path == nil then
		my_txt:setString(self.tb_wrongtitle_item.answer)
		my_pic:setVisible(false)
		right_pic:setVisible(false)	
		if self.isright == 0 then
			right_txt:setString("纠正后可显示正确答案")
		else
			right_txt:setString(self.tb_wrongtitle_item.correct_answer)
		end	
	else
	
		local answer_but = ccui.Button:create()
		answer_but:setTouchEnabled(true)
		answer_but:loadTextures(answerpic_path, answerpic_path, "")
		local size_answer = my_pic:getContentSize()	
		local scale_x = size_answer.width/answer_but:getContentSize().width
		local scale_y = size_answer.height/answer_but:getContentSize().height
		answer_but:setScale(scale_y)
		answer_but:setPosition(cc.p(size_answer.width/2,size_answer.height/2))
		
		self:showanswerview(answerpic_path)

		uikits.event(answer_but,
		function(sender,eventType)
			self.picup_view:setVisible(true)
		end,"click")
		
		my_pic:addChild(answer_but)
		my_txt:setVisible(false)
		my_pic:setVisible(true)
		
		if self.tb_wrongtitle_item.isright == 0 then
			right_txt:setString("纠正后可显示正确答案")
			right_pic:setVisible(false)
		else	
			local answer_but = ccui.Button:create()
			answer_but:setTouchEnabled(true)
			answer_but:loadTextures(answerpic_path, answerpic_path, "")
			local size_answer = my_pic:getContentSize()	
			local scale_x = size_answer.width/answer_but:getContentSize().width
			local scale_y = size_answer.height/answer_but:getContentSize().height
			answer_but:setScale(scale_y)
			answer_but:setPosition(cc.p(size_answer.width/2,size_answer.height/2))
			
			self:showanswerview(answerpic_path)

			uikits.event(answer_but,
			function(sender,eventType)
				self.picup_view:setVisible(true)
			end,"click")
			right_pic:addChild(answer_but)
			right_pic:setVisible(true)
			right_txt:setVisible(false)
		end			
	end--]]


	local data = {}
	if self.tb_wrongtitle_item.item_type > 0 and self.tb_wrongtitle_item.item_type < 13 then
		if topics.types[self.tb_wrongtitle_item.item_type].conv(self.tb_wrongtitle_item,data) then
			data.eventInitComplate = function(layout,data)
				local arraychildren = question_pic_view:getChildren()
				for i=1,#arraychildren do 
					arraychildren[i]:setEnabled(false)
				end
			end
			topics.types[self.tb_wrongtitle_item.item_type].init(question_pic_view,data)
		end		
	end
	question_pic_view:setBounceEnabled(true)
--[[	local question_pic = cc.Sprite:create(self.file_path)
	local size_question = question_pic_view:getContentSize()		
	local scale_x = size_question.width/question_pic:getContentSize().width
	local scale_y = size_question.height/question_pic:getContentSize().height
	question_pic:setScale(scale_y)
	question_pic:setPosition(cc.p(size_question.width/2,size_question.height/2))
	question_pic_view:addChild(question_pic)	--]]
	
	if self.iscollect == true then
		tag_collect:setVisible(true)
	else
		tag_collect:setVisible(false)
	end	
	
	--处理返回按钮，切换至单科错题列表
	uikits.event(but_goback,
		function(sender,eventType)
--[[			local t_persubject = package.loaded["src/errortitile/persubject"]
			if t_persubject then			
				local scene_next = t_persubject.create(self.name,self.label,self.id,self.range)				
				--self:removeFromParent()
				cc.Director:getInstance():replaceScene(scene_next)								
			end	--]]	
			uikits.popScene()
		end,"click")
	--处理更多操作按钮
	--local share_view = 		
	local share_box_src = self.share_view:getChildByTag(657)
	but_more.share_box = share_box_src:clone()

	local size_share = but_more.share_box:getContentSize()
	local size_but = but_more:getContentSize()
	local size_view = self._widget:getContentSize()
	local size_title = titleview:getContentSize()
	--self._widget:addChild(but_more.share_box)
	
	--print((size_but.width-size_share.width)..":::"..(size_view.height-(size_share.height+size_title.height)))
	--(size_view.width-size_share.width)..":::"..(size_view.height-(size_share.height+size_title.height))
	but_more.share_box:setPosition(cc.p((size_but.width-size_share.width),(0-size_share.height)))
	but_more.share_box:setVisible(false)
	local but_collect = but_more.share_box:getChildByTag(661)
	if self.iscollect == true then
		but_collect:setSelectedState(false)
	else
		but_collect:setSelectedState(true)
	end		
	--self._widget:addChild(but_more.share_box)	
	but_more:addChild(but_more.share_box)	
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
			send_url = base_url.."?item_id="..self.tb_wrongtitle_item.item_id		
			local result = kits.http_get(send_url,login.cookie(),1)	
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

function BigquestionView:release()

end
return {
create = create,
}