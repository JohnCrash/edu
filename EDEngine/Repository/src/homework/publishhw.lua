local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"
local Publishhwret = require "homework/publishhwret"
local messagebox = require "messagebox"

local ui = {
	FILE = 'homework/laoshizuoye/fabu.json',
	FILE_3_4 = 'homework/laoshizuoye/fabu43.json',
	YINBI_TITLE = 'leirong/ys3',
	YINBI_VIEW = 'leirong/yinbi',
	CHECK_DATE_BASE = 'leirong/riqi/tu/d',
	BUTTON_BACK = 'ding/back',
	BUTTON_CONFIRM = 'ding/qr',
	BANJI_VIEW = 'leirong/banji',
	PER_BANJI_VIEW = 'leirong/banji/ban1',
	BANJI_LABEL = 'bm',
}

local day_index_seled
local banji_sel_num

local banji_space = 30
local Publishhw = class("Publishhw")
Publishhw.__index = Publishhw

function Publishhw.create(tb_parent_view)
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Publishhw)
	layer.tb_parent_view = tb_parent_view
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

function Publishhw:SetButtonEnabled(but)
	if banji_sel_num  ~= 0 then
		but:setEnabled(true)
		but:setBright(true)
		but:setTouchEnabled(true)
	else
		but:setEnabled(false)
		but:setBright(false)
		but:setTouchEnabled(false)	
	end
end

function Publishhw:showbanjilist(tb_banji)
	local banji_view = uikits.child(self._widget,ui.BANJI_VIEW)
	local src_per_banji_view = uikits.child(self._widget,ui.PER_BANJI_VIEW)
	for i, obj in pairs(tb_banji) do
		cur_banji_view = src_per_banji_view:clone()
		local banji_label = uikits.child(cur_banji_view,ui.BANJI_LABEL)
		banji_label:setString(obj.zone_name)
		cur_banji_view:setVisible(true)
		local pos_x_src = cur_banji_view:getPositionX()
		local size_view = cur_banji_view:getContentSize()
		local pos_x_cur = pos_x_src + (i-1)*(size_view.width+banji_space)
		cur_banji_view:setPositionX(pos_x_cur)
		banji_view:addChild(cur_banji_view,1,obj.zone_id)
	end
	local size_banji_view = banji_view:getContentSize()
	local size_view = src_per_banji_view:getContentSize()
	banji_view:setInnerContainerSize(cc.size(#tb_banji*(size_view.width+banji_space),size_banji_view.height))
end

function Publishhw:getdatabyurl()
	local send_url = 'http://api.lejiaolexue.com/rest/user/'..login.uid()..'/zone/class'
	local loadbox = loadingbox.open(self)
	cache.request_json( send_url,function(t)
			if t and type(t)=='table' then
				if t.result == 0 then
					if t.zone and type(t.zone)=='table' then
						self.tb_banji = t.zone
						self:showbanjilist(self.tb_banji)						
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
			loadbox:removeFromParent()
		end,'NC')
end

local new_homework_url = 'http://new.www.lejiaolexue.com/paper/handler/AddPaper.ashx?idx=1&'
local add_homework_item_url = 'http://new.www.lejiaolexue.com/paper/handler/ManuallyItem.ashx'
local publish_homework_url = 'http://new.www.lejiaolexue.com/exam/handler/pubexam.ashx'
local finish_days = {
1,
2,
4,
8,
9,
15,
30,
60,
}

function Publishhw:format_item_list()
	local ret = {}
	for i,v in pairs(self.tb_parent_view._confirm_item) do
		local per_item_info = {}
		per_item_info.item_id = v.item_id
		per_item_info.item_type = v.item_type
		per_item_info.origin = 1
		per_item_info.sort = 100
		ret[#ret+1] = per_item_info
	end
	self._item_count = #ret
	return ret
end

function Publishhw:format_publish_data()
	local ret 
	local data_cur_sec = os.time()
	local tb_data = os.date("*t",data_cur_sec )
	local data_cur_begain = data_cur_sec - tb_data.hour*60*60 - tb_data.min*60 - tb_data.sec
	local data_finish = data_cur_begain + finish_days[day_index_seled]*24*60*60 + 6*60*60
	local tb_data_finish = os.date("*t",data_finish )
	ret = '?exam_name='..tb_data.year..'年'..tb_data.month..'月'..tb_data.day..'日'..self.tb_parent_view._selector[1].name..'作业'
	ret = ret..'&paper_id='..self._paperid
	ret = ret..'&course='..self.tb_parent_view._selector[1].id
	if self.tb_parent_view._selector[2] then
		ret = ret..'&book_version='..self.tb_parent_view._selector[2].id
	end
	if self.tb_parent_view._selector[3] then
		ret = ret..'&node_vol='..self.tb_parent_view._selector[3].id
	end
	if self.tb_parent_view._selector[4] then
		ret = ret..'&node_unit='..self.tb_parent_view._selector[4].id
	end
	if self.tb_parent_view._selector[5] then
		ret = ret..'&node_section='..self.tb_parent_view._selector[5].id
		ret = ret..'&node_section_name='..self.tb_parent_view._selector[5].name
	end
	ret = ret..'&period=1&tag_solution=1&tag_selfcheck=1&comment=0&score_type=2&from=1&exam_type=11'
	ret = ret..'&from_user_id='..login.uid()
	ret = ret..'&items='..self._item_count
	ret = ret..'&open_time='..os.date("%Y-%m-%d %X",data_cur_sec )
	ret = ret..'&finish_time='..os.date("%Y-%m-%d %X",data_finish )
	
	local banji_view = uikits.child(self._widget,ui.BANJI_VIEW)
	local banji_list = banji_view:getChildren()
	local classdata = {}
	for i,v in pairs(banji_list) do
		if v:getSelectedState() == true then
			local per_classdata = {}
			per_classdata.class_id = v:getTag()
			per_classdata.group_id = ''
			classdata[#classdata+1] = per_classdata		
		end
	end
	local tb_class = {}
	tb_class.result = classdata
	ret = ret..'&classandgroup='..json.encode(tb_class)
	--print("classandgroup::"..json.encode(tb_class))
	return ret
end

function Publishhw:publish_homework()
	local data_cur_sec = os.time()
	local tb_data = os.date("*t",data_cur_sec )
	local send_data_course = '&course='..self.tb_parent_view._selector[1].id
	local send_url = new_homework_url..'title='.. tb_data.year..'年'..tb_data.month..'月'..tb_data.day..'日'..self.tb_parent_view._selector[1].name..'作业'..send_data_course
	local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
	but_confirm:setEnabled(false)
	but_confirm:setBright(false)
	but_confirm:setTouchEnabled(false)	
	local loadbox = loadingbox.open( self )
	local ret = cache.request( send_url,function(b)
				--loadbox:removeFromParent()
				if b then
					local result = cache.get_data( send_url )
					if result and type(result) == 'string' then
						self._paperid = result
						local send_data_pid = '?pid='..self._paperid
						local tb_para = self:format_item_list()
						local send_data_para = '&para='..json.encode(tb_para)
						send_url = add_homework_item_url..send_data_pid..send_data_para
						local ret = cache.request( send_url,function(b)
									loadbox:removeFromParent()
									if b then
										local result = cache.get_data( send_url )
										if result and result == 'True' then
											local send_data = self:format_publish_data()
											send_url = publish_homework_url..send_data
											result = kits.http_get(send_url,login.cookie(),1)
											loadbox:removeFromParent()
											if result and type(result) == 'string' then
												uikits.pushScene(Publishhwret.create(self.tb_parent_view))
											else
												kits.log('publish_homework  error')
												return
											end
										else
											loadbox:removeFromParent()
											but_confirm:setEnabled(true)
											but_confirm:setBright(true)
											but_confirm:setTouchEnabled(true)	
											kits.log('add_homework_item  error')
											return
										end
									else
										loadbox:removeFromParent()
										but_confirm:setEnabled(true)
										but_confirm:setBright(true)
										but_confirm:setTouchEnabled(true)	
										messagebox.open(self,function(e)
											if e == messagebox.TRY then
												self:publish_homework()
											elseif e == messagebox.CLOSE then
												uikits.popScene()
											end
										end,messagebox.RETRY)										
									end
								end)
					else
						loadbox:removeFromParent()
						kits.log('new_homework  error')
						return	
					end
				else
					loadbox:removeFromParent()
					messagebox.open(self,function(e)
						if e == messagebox.TRY then
							self:publish_homework()
						elseif e == messagebox.CLOSE then
							uikits.popScene()
						end
					end,messagebox.RETRY)	
				end
			end)
end

function Publishhw:publish_topics()
	if self.tb_parent_view then
		local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
		but_confirm:setEnabled(false)
		but_confirm:setBright(false)
		but_confirm:setTouchEnabled(false)
		self._item_count = 0
		local custom_items = {}
		local data = self.tb_parent_view._subjective_data
		local selector = self.tb_parent_view._selector	
		local function upload(item) --upload attachments
			kits.log('>>>UPLOAD')
			local url
			local suf = string.sub(item.file,-4)
			local suffix = string.lower(suf)
			if suffix == '.amr' then
				url = 'http://image.lejiaolexue.com/handler/item/attachment_upload.ashx'
			else
				url = 'http://image.lejiaolexue.com/handler/item/upload.ashx'
			end
			--local url = 'http://file-stu.lejiaolexue.com/rest/user/upload/hw'
			local local_file = item.file
			local data = kits.read_file( local_file )
			if data then
				cache.upload( url,item.file,data,
					function(b,t)
						if b then
							if t.src and t.mini_src then
								item.src = t.src
								item.mini_src = t.mini_src
								kits.log("INFO : upload "..tostring(item.mini_src))
							else
								item.err = 'result'
								kits.log("ERROR : Publishhw:publish_topics upload result invalid")
							end
						else
							item.err = 'upload'
							kits.log("ERROR :  Publishhw:publish_topics upload failed")
							kits.log("	local file "..local_file)
							kits.log("	url "..url)
						end
					end)
			else
				item.err = 'read'
				kits.log("ERROR : Publishhw:publish_topics upload can't open file "..local_file)
			end
		end
		local function additem(item) --add topics item
			kits.log('>>>ADD ATTACHMENTS')
			local att = {}
			for i,v in pairs(item.items) do
				table.insert(att,{src=v.mini_src,name=v.mini_src})
			end
			local t = {
				content = kits.encode_str(tostring(item.text)),
				content_fenxi = '',
				diff = 60,
				type = 93,
				attach=json.encode(att),
				answerCark='[{"item_type":93}]',
			}
			if selector then
				for i=1,5 do
					if selector[i] then
						if i==1 then
							t.course = selector[i].id
						elseif i==2 then
							t.version = selector[i].id
						elseif i==3 then
							t.vol = selector[i].id
						elseif i==4 then
							t.unit = selector[i].id
						elseif i==5 then
							t.section = selector[i].id
						end
					end
				end
			else
				kits.log('WARNING : Publishhw:publish_topics selector = nil')
			end
			local url = "http://new.www.lejiaolexue.com/paper/handler/AddItem.ashx?"..kits.encode_url( t )
			cache.request(url,function(b)
				if b then
					item.id = cache.get_data(url)
					if item.id then
						kits.log('Add success :'..tostring(item.id))
						table.insert(custom_items,{item_id=item.id,item_type=93})
					else
						item.err = 'fail'
						kits.log("ERROR : Publishhw:add_topics_item failed 2")
					end
				else
					item.err = 'fail'
					kits.log("ERROR : Publishhw:add_topics_item failed 1")				
				end
			end)
		end
		local create_paper_isdone = uikits.RUN
		local paper_id = nil
		local function create_paper()
			kits.log('>>>CREATE PAPER')
			local data_cur_sec = os.time()
			local tb_data = os.date("*t",data_cur_sec )
			local send_data_course = '&course='..selector[1].id
			local send_url = new_homework_url..'title='.. tb_data.year..'年'..tb_data.month..'月'..tb_data.day..'日'..selector[1].name..'作业'..send_data_course
			cache.request( send_url,function(b)
				if b then
					local result = cache.get_data( send_url )
					if result and type(result)=='string' then
						create_paper_isdone = uikits.OK
						paper_id = result
					else
						create_paper_isdone = uikits.FAIL
					end
				else
					create_paper_isdone = uikits.FAIL
				end
			end)
		end
		local add_paper_item_isdone = uikits.RUN
		local function add_paper_item() --add_item
			kits.log('>>>ADD ITEM')
			if self.tb_parent_view._confirm_item and table.maxn(self.tb_parent_view._confirm_item)>0 then
				self._paperid = paper_id
				local send_data_pid = '?pid='..self._paperid
				local tb_para = self:format_item_list()
				local send_data_para = '&para='..json.encode(tb_para)
				
				local send_url = add_homework_item_url..send_data_pid..send_data_para
				cache.request( send_url,function(b)
						if b then
							local result = cache.get_data( send_url )
							if result then
								add_paper_item_isdone = uikits.OK
							else
								add_paper_item_isdone = uikits.FAIL
								kits.log('ERROR : add_paper_item  error1')
							end						
						else
							add_paper_item_isdone = uikits.FAIL
							kits.log('ERROR : add_paper_item error0')
						end
					end)
			else
				add_paper_item_isdone = uikits.OK
			end
		end
		local add_paper_custom_item_isdone = uikits.RUN
		local function add_paper_custom_item() --add custom item
			kits.log('>>>ADD CUSTOM ITEM')
			if #custom_items <= 0 then
				--没有跳过
				self._paperid = paper_id
				kits.log("	CUSTOM ITEM EMPTY")
				add_paper_custom_item_isdone = uikits.OK
			else
				--有主观题
				self._paperid = paper_id
				local send_data_pid = '?pid='..self._paperid
				local tb_para = {}
				for i,v in pairs(custom_items) do
					local per_item_info = {}
					per_item_info.item_id = v.item_id
					per_item_info.item_type = v.item_type
					per_item_info.origin = 2
					per_item_info.sort = 100
					tb_para[#tb_para+1] = per_item_info
				end
				self._item_count = self._item_count or 0
				self._item_count = self._item_count  + #tb_para
				local send_data_para = '&para='..json.encode(tb_para)
				local send_url = add_homework_item_url..send_data_pid..send_data_para
				cache.request( send_url,function(b)
						if b then
							local result = cache.get_data( send_url )
							if result then
								add_paper_custom_item_isdone = uikits.OK
							else
								add_paper_custom_item_isdone = uikits.FAIL
								kits.log('ERROR : add_paper_item  error1')
							end						
						else
							add_paper_custom_item_isdone = uikits.FAIL
							kits.log('ERROR : add_paper_item error0')
						end
					end)		
			end
		end
		local publish_paper_isdone = uikits.RUN
		local function publish_paper()
			kits.log('>>>PUBLISH')
			local send_data = self:format_publish_data()
			local send_url = kits.encode_space(publish_homework_url..send_data)
			cache.request( send_url,function(b)
						if b then
							local result = cache.get_data( send_url )
							if result then
								publish_paper_isdone = uikits.OK
								kits.log('>>>COMPLETE')
								uikits.pushScene(Publishhwret.create(self.tb_parent_view))
							else
								publish_paper_isdone = uikits.FAIL
								kits.log('ERROR : publish_paper error1')
							end
						else
							publish_paper_isdone = uikits.FAIL
							kits.log('ERROR : publish_paper error0')
						end
					end)
		end
		local wnd = self
		local loadbox = loadingbox.open(self)
		uikits.sequence_call{
			function(state) --upload all attachments
				if state==uikits.RUN then
					if data then
						for i,v in pairs(data) do
							if v.items then
								for k,item in pairs(v.items) do
									upload( item )
								end
							end
						end
					end
					return true
				elseif state==uikits.STATE then
					local s = uikits.OK
					if data then
						for i,v in pairs(data) do
							if v.items then
								for k,item in pairs(v.items) do
									if item.err then
										return uikits.FAIL
									elseif not item.src then
										s = uikits.RUN
									end
								end						
							end
						end
					end
					return s
				end
			end,
			function(state) --add topics
				if state==uikits.RUN then
					if data then
						for i,v in pairs(data) do
							additem(v)
						end
					end
					return true					
				elseif state==uikits.STATE then
					local s=uikits.OK
					if data then
						for i,v in pairs(data) do
							if v.err then
								return uikits.FAIL
							elseif not v.id then
								s=uikits.RUN
							end
						end
					end
					return s
				end
			end,
			function(state) --create paper
				if state==uikits.RUN then
					create_paper()
					return true
				elseif state==uikits.STATE then
					return create_paper_isdone
				end
			end,
			function(state) --add paper item
				if state==uikits.RUN then
					add_paper_item()
					return true
				elseif state==uikits.STATE then
					return add_paper_item_isdone
				end			
			end,
			function(state) --add custom item
				if state==uikits.RUN then
					add_paper_custom_item()
					return true
				elseif state==uikits.STATE then
					return add_paper_custom_item_isdone
				end						
			end,
			function(state) --publish paper
				if state==uikits.RUN then
					publish_paper()
					return true
				elseif state==uikits.STATE then
					return publish_paper_isdone
				end			
			end,
			event=function(self,s)
				if s==uikits.BEGIN then
					kits.log('BEGIN')
				elseif s==uikits.END then
					kits.log('END')
					loadbox:removeFromParent()
				elseif s==uikits.NEXT then
					kits.log('NEXT STEP')
				elseif s==uikits.FAIL then
					kits.log('FAIL')
					self:pause()
					messagebox.open(wnd,function(e)
							if e == messagebox.TRY then
								self:continue()
							elseif e == messagebox.CLOSE then
								self:close()
								uikits.delay_call(nil,function()uikits.popScene() end)
							end
						end,messagebox.RETRY)
				end
				return true
			end
		}
		--add topics items
	else
		kits.log("ERROR : Publishhw:publish_topics invalid paramter")
	end
end

function Publishhw:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	self._widget = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._widget)
	self:getdatabyurl()
	local yinbi_title = uikits.child(self._widget,ui.YINBI_TITLE)
	local yinbi_view = uikits.child(self._widget,ui.YINBI_VIEW)
	yinbi_title:setVisible(false)
	yinbi_view:setVisible(false)

	local but_back = uikits.child(self._widget,ui.BUTTON_BACK)
	local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
	uikits.event(but_back,
		function(sender,eventType)
		uikits.popScene()
	end,"click")

	uikits.event(but_confirm,
		function(sender,eventType)
		print('1111111')
		--uikits.pushScene(Publishhwret.create(self.tb_parent_view))
		--self:publish_homework()
		self:publish_topics()
	end,"click")	
	banji_sel_num = 0
	self:SetButtonEnabled(but_confirm)
	local banji_view = uikits.child(self._widget,ui.BANJI_VIEW)
	banji_view:setDirection(ccui.ScrollViewDir.horizontal)
	local per_banji_view = uikits.child(self._widget,ui.PER_BANJI_VIEW)
	per_banji_view:setVisible(false)
	
	uikits.event(per_banji_view,
			function(sender,eventType)
				local but_confirm = uikits.child(self._widget,ui.BUTTON_CONFIRM)
				if eventType == true then
					banji_sel_num = banji_sel_num+1
				else
					banji_sel_num = banji_sel_num-1
				end
				self:SetButtonEnabled(but_confirm)
		end)		
	
	for i = 1,8 do 
		local checkbox_day = uikits.child(self._widget,ui.CHECK_DATE_BASE..i)
		if i == 1 then
			checkbox_day:setSelectedState(true)
			day_index_seled = i
		else
			checkbox_day:setSelectedState(false)	
		end
		checkbox_day.index = i
		uikits.event(checkbox_day,
			function(sender,eventType)
				local checkbox_day = sender
				local checkbox_day_old = uikits.child(self._widget,ui.CHECK_DATE_BASE..day_index_seled)
				if eventType == true then
					if day_index_seled ~= checkbox_day.index then
						checkbox_day_old:setSelectedState(false)
					end
					day_index_seled = checkbox_day.index
				else
					if day_index_seled == checkbox_day.index then
						checkbox_day:setSelectedState(true)
					end
				end
		end)	
	end
end

function Publishhw:release()
	
end

return Publishhw