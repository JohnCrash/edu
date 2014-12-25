local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local loadingbox = require "loadingbox"
local topics = require "homework/topics"
local mt = require "mt"
local json = require "json-c"

kits.log( "Hello World!" )
kits.log( "====================" )
local res_root = 'homework/'
local ui = {
	FILE = res_root..'workflow.json',
	FILE_3_4 = res_root..'workflow43.json',
	PLAYBOX = 'homework/playbox.json',
	PLAY = 'pause',
	PAUSE = 'play',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	LINK_DOT = res_root..'round_dot.png',
	ARROW = 'arrow',
	ARROW_UP = 'up',
	PAGE_VIEW = 'questions_view',
	NEXT_BUTTON = 'next_problem',
	FINISH_BUTTON = 'finish_5',
	ITEM_CURRENT = 'state_past',
	ITEM_FINISHED = 'state_now',
	ITEM_UNFINISHED = 'state_future',
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,
	ANSWER_FIELD = 'milk_side',
	TYPE_IMG = 'item',
	OPTION_A = 'option_a',
	OPTION_B = 'option_b',
	OPTION_C = 'option_c',
	OPTION_D = 'option_d',
	OPTION_E = 'option_e',
	OPTION_F = 'option_f',
	OPTION_G = 'option_g',
	OPTION_H = 'option_h',
	OPTION_YES = 'option_right',
	OPTION_NO = 'option_wrong',
	OPTION_NO_SUPPORT = 'option_not',
	EDIT_TOPICS = 'edit_topics',
	EDIT_TOPICS2 = 'edit_topics2',
	EDIT_TOPICS3 = 'edit_topics3',
	EDIT_TOPICS_ITEM = 'option_write_1',
	EDIT_TOPICS_NUMBER = 'num',
	FRACTION_LEFT = 'option_write_1/answer_text3',
	FRACTION_UP = 'option_write_1/answer_text',
	FRACTION_DOWN = 'option_write_1/answer_text2',
	LINK_TEXT = 'option_connection',
	DRAG_TEXT = 'option_drag',
	POSITION_TEXT = 'option_position',
	POSITION_SORT = 'option_sort',
	ANSWER_TEXT = 'answer_text',
	TOPICS_NUM = 'topics_num',
}

local loadpaper_url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx"
local loadextam_url = "http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx"
local commit_answer_url = 'http://new.www.lejiaolexue.com/student/handler/SubmitAnswer.ashx'
local cloud_answer_url = 'http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx'

local WorkFlow = class("WorkFlow")
WorkFlow.__index = WorkFlow

function WorkFlow.create( t )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkFlow)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			if t and type(t)=='table' then
				layer._args = t
			end
			layer:init()
		elseif "exit" == event then
			layer:release()
		end
	end	
	
	layer:registerScriptHandler(onNodeEvent)
	return scene
end

--总得存储一遍
function WorkFlow:save()
	if self._url_topics and self.data then
		--收集答案
		for i,v in pairs(self.data) do
			if self._data and self._data[i] then
				v.my_answer = self._data[i].my_answer
				v.state = self._data[i].state
			else
				kits.log( 'error : WorkFlow:save self._data['..i..'] = nil')
			end
		end
		local result = json.encode( self.data,2 )
		if result then
			kits.write_cache(cache.get_name( self._url_topics ),result)
		end
	end
end

--从服务器上取答案
--examId=
--examld=
function WorkFlow:get_cloud_topics( v,func )
	local form = 'examId='..tostring(self._args.exam_id)
	..'&itemId='..tostring(v.item_id)
	..'&teacherId='..tostring(self._args.tid)
	local url = cloud_answer_url..'?'..form
	local ret,msg = mt.new('POST',url,login.cookie(),
					function(obj)
						if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
							if obj.state == 'OK' and obj.data then
								kits.log('	cloud answer :'..url..' success!')
								local answer
								func( answer )
							else
								func()
								kits.log('	get cloud answer '..url..' faild?')
							end
						end
					end,form )
	if not ret then
		kits.log('	get cloud answer '..url..' faild!')
		if msg then
			kits.log( msg )
		end
		func()
	end
end

function WorkFlow:commit_topics( v )
	local answer
	if v and v.my_answer and type(v.my_answer)=='string' then
		answer = v.my_answer
	elseif v and v.my_answer and type(v.my_answer)=='table' then
		answer = ''
		if v.isFraction then
			local idx = 1
			for k,s in pairs(v.isFraction) do
				if s == 2 then
					if idx+1 <= #v.my_answer then
						if string.len(answer) > 0 then
							answer = answer..','
						end					
						answer = answer..v.my_answer[idx]..'~'..v.my_answer[idx+1]
						idx = idx + 2
					else
						kits.log("ERROR : Fraction my_answer invalide value 2")
					end
				elseif s == 3 then
					if idx+2 <= #v.my_answer then
						if string.len(answer) > 0 then
							answer = answer..','
						end
						answer = answer..v.my_answer[idx]..'~'..v.my_answer[idx+1]..'~'..v.my_answer[idx+2]
						idx = idx + 3
					else
						kits.log("ERROR : Fraction my_answer invalide value 3")
					end	
				elseif s == 1 then
					if idx <= #v.my_answer then
						if string.len(answer) > 0 then
							answer = answer..','
						end
						answer = answer..v.my_answer[idx]
						idx = idx + 1	
					else
						kits.log("ERROR : Fraction my_answer invalide value 4")
					end
				else
					kits.log("ERROR : Fraction invalide value" )
				end
			end
		else
			for i,v in pairs(v.my_answer) do
				if v then
					if i ~= 1 then answer = answer..',' end
					answer = answer..tostring(v)
				end
			end
		end
	else
		kits.log('ERROR commit my_answer invalid')
		return
	end
	
	if not self._topics_table then
		self._topics_table = {}
	end
	if not self._topics_table.answers then
		self._topics_table.answers = {}
	end
	if not self._topics_table.answers[v.item_id] then
		self._topics_table.answers[v.item_id] = {}
	end
	
	v.user_time = v.user_time or 0
	local cur_time = os.time()
	local dt = cur_time-self._topics_begin_time --做题题目计时器
	v.user_time = v.user_time + dt
	local url = commit_answer_url..'?examId='..tostring(self._args.exam_id)
	..'&itemId='..tostring(v.item_id)
	..'&answer='..tostring(answer)
	..'&times='..dt
	..'&tid='..tostring(self._args.tid)
	self._topics_begin_time = os.time() --重新计时
	local ret = mt.new('GET',url,login.cookie(),
					function(obj)
						if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
							if obj.state == 'OK' and obj.data then
								v.commit_faild = false
								if self and self._topics_table then
									local answer = self._topics_table.answers[v.item_id]
									answer.user_time = v.user_time
									answer.commit_faild = v.commit_faild
									kits.log('	commit '..url..' success!')
								else
									kits.log('ERROR commit time out!')
								end
							else
								v.commit_faild = true
								if self and self._topics_table and self._topics_table.answers then
									local answer = self._topics_table.answers[v.item_id]
									answer.user_time = v.user_time
									answer.commit_faild = v.commit_faild
									kits.log('ERROR : WorkFlow:commit_topics')
									kits.log('	commit '..url..' faild!')
								else
									kits.log('ERROR commit time out faild')
								end
							end
						end
					end )
	if not ret then
		v.commit_faild = true
		local answer = self._topics_table.answers[v.item_id]
		answer.user_time = v.user_time
		answer.commit_faild = v.commit_faild
		kits.log('ERROR : WorkFlow:commit_topics')
		kits.log('	commit '..url..' faild!')
	end
end

local function answer_eq(a1,a2)
	if type(a1)==type(a2) and type(a1)=='string' then
		return a1==a2
	elseif type(a1)==type(a2) and type(a1)=='table' and #a1==#a2 then
		for i=1,#a1 do
			if a1[i] ~= a2[i] then
				return false
			end
		end
		return true
	end
	return false
end

local function answer_clone(a)
	if a and type(a)=='table' then
		local r = {}
		for i,v in pairs(a) do
			r[i] = v
		end
		return r
	else
		return a
	end
end

local function has_answer( answer )
	if answer and type(answer)=='table' then
		local ans1 = answer[1]
		if ans1 and ((type(ans1)=='string' and string.len(ans1)>0) or type(ans1)=='number') then
			return true
		end
	end
end

function WorkFlow:check_finished()
	local b = true
	if self._data then
		for i,v in pairs(self._data) do
			--结束按钮,状态改变
			if v.state == ui.STATE_UNFINISHED then
				b = false
			end				
		end
		if b then
			self._next_button:setVisible(false)
			self._finish_button:setVisible(true)
		else
			self._next_button:setVisible(true)
			self._finish_button:setVisible(false)		
		end		
	end
end
--每道题存一遍
function WorkFlow:save_answer()
	--比较下看看答案修改过没，如果修改过就保存
	self._topics_table.answers = self._topics_table.answers or {}
	local isc = false
	local b = true
	if self._data then
		for i,v in pairs(self._data) do
			if v.my_answer and not answer_eq(self._topics_table.answers[v.item_id],v.my_answer) then
			--答案被修改过,需要存储
				if v.item_id then
					if has_answer(v.my_answer) then
						self:commit_topics( v )
					end
					self._topics_table.answers[v.item_id] = answer_clone(v.my_answer)
					isc = true	
				else
					kits.log('error : WorkFlow:save_answer v.item_id = nil' )
				end
			end
			--结束按钮,状态改变
			if v.state == ui.STATE_UNFINISHED then
				b = false
			end
			if v.commit_faild and v.item_id then
				kits.log('WARNING commit topics faild,try again!')
				self:commit_topics( v ) --如果发生提交失败将，每次重试
			end
		end
		if isc then
			if self._args.exam_id then --作业
				topics.write( self._args.exam_id,self._topics_table )
			elseif self._args.pid then --卷面	
				topics.write( self._args.pid,self._topics_table )
			else
				kits.log('error : WorkFlow:save_answer exam_id = nil and pid = nil')
			end
		end
		if b then
			self._next_button:setVisible(false)
			self._finish_button:setVisible(true)
		else
			self._next_button:setVisible(true)
			self._finish_button:setVisible(false)		
		end		
	end
end

function WorkFlow:init_ui_from_data()
	local x
	x,self._item_y = self._item_current:getPosition()
	if self._data then
		kits.log('	load_original_data_from_string success')
		self._url_topics = self._args.url_topics
		for i,v in pairs(self._data) do
			self:add_item( v )
		end
		self:set_current(1)
		self:relayout()
	end
end

function WorkFlow:init_data( )
	--提交页面已经加载了题面
	if self._args._exam_table then --作业已经有了直接加载
		--加载答案
		if self._args.exam_id then
			self._topics_table = topics.read( self._args.exam_id ) or {}
		elseif self._args.pid then
			self._topics_table = topics.read( self._args.pid ) or {}
		else
			self._topics_table = {}
			kits.log('error : WorkFlow:init_data exam_id=nil and pid=nil')
		end
		self._data = self:load_original_data_from_table(self._args._exam_table)
		self:init_ui_from_data()
		return
	end
	--正常加载
	if not (self._args.pid and self._args.uid) then
		kits.log('error : WorkFlow:init_data invalid arguments')
		return
	end
	
	local url_topics
	if self._args.exam_id then
		--取作业
		url_topics = loadextam_url..'?examId='..self._args.exam_id..'&teacherId='..self._args.tid
		--取得以前做的答案
		self._topics_table = topics.read( self._args.exam_id ) or {}
	elseif self._args.pid then
		--取卷面
		url_topics = loadpaper_url..'?pid='..self._args.pid..'&uid='..self._args.uid
		--取得以前做的答案
		self._topics_table = topics.read( self._args.pid ) or {}
	else
		self._topics_table = {}
		kits.log('error : WorkFlow:init_data exam_id=nil and pid=nil')
		return
	end
	kits.log('WorkFlow:init_data request :'..url_topics )
	local loadbox = loadingbox.open( self )
	local ret = cache.request( url_topics,function(b)
				loadbox:removeFromParent()
				if b then
					kits.log('	request success')
					local result = cache.get_data( url_topics )
					if result and type(result) == 'string' then
						kits.log('	cache.get_data success')
						self._data = self:load_original_data_from_string( result )
						self._args.url_topics = url_topics
						self:init_ui_from_data()
					end
				end
			end)
end

function WorkFlow:load_cloud_answer( e )
	if e and type(e)=='table' then
		if e.my_answer and has_answer(e.my_answer) then
			--已经有答案了
			return
		elseif self._topics_table and self._topics_table.answers and 
				self._topics_table.answers[e.item_id] then
			--已经有答案了
			return
		else
			--cloud
			--向资源请求表加入答案链接，和处理程序。
			local form = 'examId='..tostring(self._args.exam_id)
				..'&itemId='..tostring(e.item_id)
				..'&teacherId='..tostring(self._args.tid)
			local url = cloud_answer_url..'?'..form
			local n = #e.resource_cache.urls
			e.resource_cache.urls[n+1] = 
			{
				url = url,
				done = function(data) --处理下载的答案
					if data and type(data)=='string' then
						local result = json.decode(data)
						if result and type(result)=='table' and result.detail and 
							type(result.detail)=='table' and  result.detail.answer  and 
							type(result.detail.answer)=='string' then
							local t = json.decode(result.detail.answer)
							if t and type(t)=='table' and t.answers and type(t.answers)=='table' then
								kits.log('	CLOUD ANSWER:'..result.detail.answer )
								e.my_answer = {}
								if e.isFraction then
									--分数题
									for i,v in pairs(t.answers) do
										local str = v.value
										local num1,num2,num3 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*~(%-*%+*%d*$*)%s*')
										if num1 and num2 and num3 then
											table.insert(e.my_answer,num1)
											table.insert(e.my_answer,num2)
											table.insert(e.my_answer,num3)
										else
											num1,num2 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*')
											if num1 and num2 then
												table.insert(e.my_answer,num1)
												table.insert(e.my_answer,num2)
											else
												table.insert(e.my_answer,str)
											end
										end
									end
								else
									for i,v in pairs(t.answers) do
										e.my_answer[i] = v.value
									end
								end
								if has_answer(e.my_answer) then
									e.state = ui.STATE_FINISHED
								else
									e.state = ui.STATE_UNFINISHED
								end
							end
						end
					end
				end
			}
		end
	end
end

function WorkFlow:load_original_data_from_file( file )
	local result = kits.read_cache(file)
	if result then
		return self:load_original_data_from_string(result)
	end
end

function WorkFlow:load_original_data_from_table( data )
	local res = {}
	if data then
		local ds
		if data.item and type(data.item)=='table' then
			ds = data.item
		else
			ds = data
		end
		self.data = ds --保存副本
		kits.log('	type(ds)='..type(ds)..',#ds='..table.maxn(ds))
		for i,v in ipairs(ds) do
			kits.log('	key='..tostring(i))
			kits.log('	value='..tostring(v))
		end
		for i,v in ipairs(ds) do
			local k = {}
			k.item_type = v.item_type

			if self._topics_table and self._topics_table.answers then
				--从答案表中取答案
				local local_answer = self._topics_table.answers[v.item_id]
				k.my_answer = answer_clone(local_answer)
			else
				k.my_answer = answer_clone(v.my_answer)
			end
			if self._topics_table and self._topics_table.answers and self._topics_table.answers[v.item_id] then
				k.state =  ui.STATE_FINISHED
			else
				k.state = ui.STATE_UNFINISHED
				b = false
			end
			k.item_id = v.item_id
			k.item_id_num = v.item_id_num
			if topics.types and topics.types[k.item_type] and
				topics.types[k.item_type].conv then
				kits.log( topics.types[k.item_type].name )
				k.resource_cache = {} 
				k.resource_cache.urls = {} --资源缓冲表,
				local b,msg = topics.types[k.item_type].conv( v,k )
				if b then
					self:load_cloud_answer( k ) --如果没有本地答案，尝试从网上获取
					res[#res+1] = k
				else
					kits.log('转换问题 "'..topics.types[k.item_type].name..'" 类型ID"'..k.item_type..'" ID:'..tostring(v.Id))
					kits.log('	error msg: '..msg )
				end
			else
				kits.log('不支持的题型: '..v.item_type)
			end
		end
		if b then
			self._next_button:setVisible(false)
			self._finish_button:setVisible(true)
		end
	else
		kits.log('	load_original_data_from_table decode_json faild')
	end
	return res
end

function WorkFlow:load_original_data_from_string( str )
	local b = true
	if str then
		local data = kits.decode_json(str)
		return self:load_original_data_from_table(data)
	else
		kits.log('	load_original_data_from_string decode_json str=nil')
	end
end

function WorkFlow:get_topics_answers_num()
	local count = 0
	if self._topics_table and self._topics_table.answers then
		for k,v in pairs(self._topics_table.answers) do
			if has_answer(v) then
				count = count + 1
			end
		end
	end
	return count
end

function WorkFlow:optimization_scrollview()
	local function optimization_scroll()
		if self._scrollview then
			local childs = self._scrollview:getChildren()
			local inner = self._scrollview:getInnerContainer()
			local inner_x,inner_y = inner:getPosition()
			local size = self._scrollview:getContentSize()
			for i,v in pairs(childs) do
				if v._isclone then
					local x,y = v:getPosition()
					if x+inner_x < 0 or x+inner_x > size.width then
						v:setVisible(false)
					else
						v:setVisible(true)
					end
				end
			end
		end
	end
	optimization_scroll()
	if self._remove_items and #self._remove_items>0 then
		for i,v in pairs(self._remove_items) do
			v:setVisible(false)
		end
	end
	uikits.event( self._scrollview,function(sender,eventType)
			optimization_scroll()
		end)
end

function WorkFlow:optimization_pageview()
	local function optimization_page(idx)
		local idx = self._pageview:getCurPageIndex()
		local pages = self._pageview:getPages()
		for i,v in pairs(pages) do
			if i-1<=idx+1 and i-1>= idx-1 then
				v:setVisible(true)
			else
				v:setVisible(false)
			end
		end
	end
	optimization_page()
	uikits.event( self._pageview,function(sender,eventType)
			if eventType == ccui.PageViewEventType.turning then
				local i = sender:getCurPageIndex()
				optimization_page()
				self:set_current( i+1 )
			end					
		end)
end

function WorkFlow:init_gui()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		WorkFlow.scale = uikits.initDR{width=1920,height=1080}
	else
		WorkFlow.scale = uikits.initDR{width=1440,height=1080}
	end
	
	WorkFlow.space = 16*WorkFlow.scale
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	uikits.event(uikits.child(self._root,ui.BACK),function(sender)
		--保存
		self:save_answer()
		--self:save()
		--将做题数量返回上一级
		if self._topics_table and self._topics_table.answers then
			self._args.cnt_item_finish = self:get_topics_answers_num()
		end
		uikits.popScene()
		end,'click')
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._pageview = uikits.child(self._root,ui.PAGE_VIEW)
	self._pageview_size = self._pageview:getContentSize()
	
	self._arrow = uikits.child(self._root,ui.ARROW)
	self._arrow_up = uikits.child(self._root,ui.ARROW_UP)
	
	uikits.event(self._pageview,
			function(sender,eventType)
				if eventType == ccui.PageViewEventType.turning then
					local i = sender:getCurPageIndex()
					self:set_current( i+1 )
				end				
			end)
	self._item_current = uikits.child(self._scrollview,ui.ITEM_CURRENT)
	self._item_finished = uikits.child(self._scrollview,ui.ITEM_FINISHED)
	self._item_unfinished = uikits.child(self._scrollview,ui.ITEM_UNFINISHED)
	
	self._item_current:setVisible(false)
	self._item_finished:setVisible(false)
	self._item_unfinished:setVisible(false)

	self._item_size = self._item_current:getContentSize()
	
	self._next_button = uikits.child(self._root,ui.NEXT_BUTTON )
	self._finish_button = uikits.child(self._root,ui.FINISH_BUTTON )
	uikits.event( self._next_button,
				function(sender)
					self:next_item()
				end,'click')
	uikits.event( self._finish_button,
				function(sender)
					--保存
					self:save_answer()
					--self:save()
					if self._topics_table and self._topics_table.answers then
						self._args.cnt_item_finish = self:get_topics_answers_num()
					end
					uikits.popScene()
				end,'click')
				
	self:init_anser_gui()
	
	local x
	x,self._item_y = self._item_current:getPosition()
	if self._data then
		for i,v in pairs(self._data) do
			self:add_item( v )
		end
		self:set_current(1)
		self:relayout()
	end
	self._pageview:setTouchEnabled(false)
end

function WorkFlow:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width*(#self._list+1),self._item_size.height))
		for i,v in ipairs(self._list) do
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
		end
	end
end

function WorkFlow:init_delay_release()
	local scheduler = self:getScheduler()
	local function timer_func()
		if self._remove_items and #self._remove_items>0 then
			for i,v in pairs(self._remove_items) do
				v:removeFromParent()
			end
			self._remove_items = nil
		end
	end
	self._scID = scheduler:scheduleScriptFunc( timer_func,1,false )
end

function WorkFlow:set_item_state( i,ste )
	if self._list[i] then
		local item = self._list[i]
		local num = uikits.child(item,ui.ITEM_NUM)
		local s = num:getString()
		local x,y = item:getPosition()
		--3.2不能再其方法内部释放对象
		--item:removeFromParent()
		--延迟释放
		item:setVisible(false)
		self._remove_items = self._remove_items or {}
		table.insert(self._remove_items,item)
		
		item = self:clone_item(ste)
		local n = uikits.child(item,ui.ITEM_NUM )
		n:setString( s )
		item:setPosition( cc.p(x,y) )
		item:setVisible(true)
		self._list[i] = item
		self._scrollview:addChild(item)	
		local index = i
		uikits.event(item,function(sender) self:set_current( index ) end,'click')
	end
end

function WorkFlow:clone_item( state )
	local item
	if state == ui.STATE_CURRENT then
		item = self._item_current:clone()
		item._isclone = true
		return item
	elseif state == ui.STATE_FINISHED then
		item = self._item_finished:clone()
		item._isclone = true
		return item
	elseif state == ui.STATE_UNFINISHED then
		item = self._item_unfinished:clone()
		item._isclone = true
		return item
	else
		kits.log( '	ERROR: clone_item state = '..tostring(state) )
		return self._item_unfinished:clone()
	end
end

function WorkFlow:next_item()
	if self._current and self._current < #self._list then
		self:set_current( self._current+1 )
	end
end

function WorkFlow:set_current( i )
	if self._current ~= i then
		self:set_item_state( i,ui.STATE_CURRENT )
		if self._current then
				self:set_item_state(self._current,self._data[self._current].state)
		end
		self._current = i
		local ps = self._pageview:getCurPageIndex()+1
		if ps ~= i then
			self._pageview:scrollToPage(i-1)
		end
		self:set_anwser_field(i)
	end
end

function WorkFlow:add_item( t )
	t.state = t.state or ui.STATE_UNFINISHED
	local item = self:clone_item( t.state )
	if item then
		local n = uikits.child(item,ui.ITEM_NUM)
		n:setString( tostring(#self._list + 1) )
		self._list[#self._list+1] = item
		item:setVisible(true)
		self._scrollview:addChild(item)
		local index = #self._list
		uikits.event(item,function(sender) self:set_current( index ) end,'began')
		--add page
		local layout = uikits.scrollview{bgcolor=cc.c3b(255,255,255)}
		layout:setContentSize(self._pageview_size)
		--layout:addChild(uikits.text{caption='Page'..#self._list,fontSize=32})
		self._pageview:addPage( layout )
		--layout:setTouchEnabled(false)
		--self:set_image( #self._list )
	else
		kits.log( '	ERROR: clone_item() return nil' )
	end
end

function WorkFlow:init_anser_gui()
	self._option_img = {}
	self._answer_items = {}
	
	local a = uikits.child(self._root,ui.ANSWER_FIELD)
	self._answer_field = a
	self._answer_type = uikits.child(a,ui.TYPE_IMG)
	--选择
	self._option_img[1] = uikits.child(a,ui.OPTION_A)
	self._option_img[2] = uikits.child(a,ui.OPTION_B)
	self._option_img[3] = uikits.child(a,ui.OPTION_C)
	self._option_img[4] = uikits.child(a,ui.OPTION_D)
	self._option_img[5] = uikits.child(a,ui.OPTION_E)
	self._option_img[6] = uikits.child(a,ui.OPTION_F)
	--self._option_img[7] = uikits.child(a,ui.OPTION_G)
	--self._option_img[8] = uikits.child(a,ui.OPTION_H)
	
	self._option_link = uikits.child(a,ui.LINK_TEXT)
	self._option_drag = uikits.child(a,ui.DRAG_TEXT)
	self._option_sort = uikits.child(a,ui.POSITION_SORT)
	self._option_position = uikits.child(a,ui.POSITION_TEXT)
	self._option_yes = uikits.child(a,ui.OPTION_YES)
	self._option_no = uikits.child(a,ui.OPTION_NO)
	self._option_not_support = uikits.child(a,ui.OPTION_NO_SUPPORT)

	self._option_edit_view = uikits.child(a,ui.EDIT_TOPICS)
	self._option_edit = {}
	local ed = uikits.child(self._option_edit_view,ui.EDIT_TOPICS_ITEM)
	table.insert(self._option_edit,ed)
	local x,y = ed:getPosition()
	for i=2,12 do
		local op = ed:clone()
		self._option_edit_view:addChild(op)
		x = x + op:getContentSize().width + 32
		op:setPosition(cc.p(x,y))
		local num = uikits.child(op,ui.EDIT_TOPICS_NUMBER)
		if num then
			num:setString(tostring(i))
		end
		local e = uikits.child(op,ui.ANSWER_TEXT)
		if e then
			e:setPlaceHolder("请输入答案")
		end
		table.insert(self._option_edit,op)
	end
	--保存初始位置
	self._option_edit_pts = {}
	for i,v in pairs(self._option_edit) do
		local x,y = v:getPosition()
		table.insert(self._option_edit_pts,{x=x,y=y})
	end
	--分数题
	self._option_edit_view2 = uikits.child(a,ui.EDIT_TOPICS2)
	self._option_edit_view3 = uikits.child(a,ui.EDIT_TOPICS3)
	--保存初始位置
	local x,y = self._option_edit_view2:getPosition()
	self._option_edit_2_pts = {x=x,y=y}
	x,y = self._option_edit_view3:getPosition()
	self._option_edit_3_pts = {x=x,y=y}
	
	self._topics_num = uikits.child(self._root,ui.TOPICS_NUM)
	if self._topics_num then
		self._topics_num:setVisible(true)
		self._topics_num:setString("")
	end
end

function WorkFlow:clear_all_option_check()
	for i = 1,#self._option_img do
		self._option_img[i]:setSelectedState(false)
	end
end

--将编辑框位置重置会原始状态
function WorkFlow:resetOptionEditPosition()
	if self._option_edit_pts then
		for i,v in pairs(self._option_edit_pts) do
			if self._option_edit and self._option_edit[i] then
				self._option_edit[i]:setPosition( v )
			end
		end
	end
	if self._option_edit_view2 and self._option_edit_view3 then
		self._option_edit_view2:setPosition(self._option_edit_2_pts)
		self._option_edit_view3:setPosition(self._option_edit_3_pts)
	end
end

function WorkFlow:set_anwser_field( i )
	if self._data[i] then
		if self._topics_num then
			if self._data[i].item_id_num then
				self._topics_num:setString(tostring(self._data[i].item_id_num)..'-'..tostring(self._data[i].item_id))
			end
		end
		if self._answer_items then
			for i,v in pairs(self._answer_items) do
				v:removeFromParent()
			end
			self._answer_items = {}
			--重置答题区控件
			for i=1,6 do
				self._option_img[i]:setVisible(false)
			end
			self._option_edit_view:setVisible(false)
			for i=1,#self._option_edit do
				self._option_edit[i]:setVisible(false)
			end
			self._option_edit_view2:setVisible(false)
			self._option_edit_view3:setVisible(false)
			self:resetOptionEditPosition()
			self._option_link:setVisible(false)
			self._option_yes:setVisible(false)
			self._option_no:setVisible(false)			
			self._option_drag:setVisible(false)
			self._option_sort:setVisible(false)
			self._option_position:setVisible(false)
			self._option_not_support:setVisible(false)
			if self.switch_remove_list then
				for i,v in pairs(self.switch_remove_list) do
					v:removeFromParent()
				end
				self.switch_remove_list = {}
			end
		end
		local t = self._data[i].item_type
		
		if topics.types[t] and topics.types[t].img and topics.types[t].init then
			self._answer_type:loadTexture(topics.types[t].img)
			--设置题的提示文字
			if t==4 then
				self._option_link:setVisible(true)
			elseif t==8 or t==7 then
				self._option_sort:setVisible(true)
			elseif t== 9 or t==10 then
				self._option_position:setVisible(true)
			elseif t==11 or t==12 then
				self._option_drag:setVisible(true)
			end
			local layout = self._pageview:getPage( i-1 )
			if not self._topics_begin_time then
				self._topics_begin_time = os.time()--开始计时
			end
			local data = self._data[i]
			--设置答题区控件
			if t==1 then --判断
				data._options = {}
				data._options[1] = self._option_yes
				data._options[2] = self._option_no
			elseif t==2 or t==3 or t==6 then --单选,多选
				data._options = {}
				for i=1,6 do
					data._options[i] = self._option_img[i]
				end
			elseif t==5 then --填空
				if data.isFraction then
					--======
					--分数题
					--======
					data._options = {}
					local offsetx
					local space = 100
					local edit_use = 1
					local is3used
					local is2used
					local function calc_offsetx( item,id )
						if item and cc_isobj(item) then
							if not offsetx then
								if id then
									item = uikits.child(item,id)
								end
								if item then
									local ap = item:getAnchorPoint()
									local size = item:getContentSize()
									local x,y = item:getPosition()
									offsetx = x + size.width * (1-ap.x)
								else
									kits.log("ERROR : calc_offsetx item = nil")
								end
							else
								--偏移
								if id then
									child = uikits.child(item,id)
								end								
								if not child then 
									child = item
								end
								
								local x,y = item:getPosition()
								--local edit = uikits.child(item,ui.EDIT_TOPICS_ITEM) 
								local size = child:getContentSize()
								local ap = child:getAnchorPoint()
								x = offsetx + size.width*ap.x + space
								offsetx = x + size.width*(1-ap.x)
								item:setPosition( cc.p(x,y) )							
							end					
						else
							kits.log("ERROR : calc_offsetx item = nil")
						end
					end
					
					for i,v in pairs(data.isFraction) do
						if v == 2 then
							local item
							if not is2used then
								item = self._option_edit_view2
								is2used = true
							else
								local parent = self._option_edit_view2:getParent()
								item = self._option_edit_view2:clone()
								parent:addChild(item)
								self.switch_remove_list = self.switch_remove_list or {}
								table.insert(self.switch_remove_list,item)
							end
							calc_offsetx( item,ui.EDIT_TOPICS_ITEM )
							item:setVisible(true)
							table.insert(data._options,uikits.child(item,ui.FRACTION_UP) )
							table.insert(data._options,uikits.child(item,ui.FRACTION_DOWN))
						elseif v == 3 then
							local item
							if not is3used then
								item = self._option_edit_view3
								is3used = true
							else
								local parent = self._option_edit_view3:getParent()
								item = self._option_edit_view3:clone()
								parent:addChild( item )
								self.switch_remove_list = self.switch_remove_list or {}
								table.insert(self.switch_remove_list,item)							
							end
							calc_offsetx( item,ui.EDIT_TOPICS_ITEM )					
							item:setVisible(true)
							table.insert(data._options,uikits.child(item,ui.FRACTION_LEFT) )
							table.insert(data._options,uikits.child(item,ui.FRACTION_UP) )
							table.insert(data._options,uikits.child(item,ui.FRACTION_DOWN))	
						elseif v == 1 then
							--这是一个普通编辑框
							local item
							item = self._option_edit[edit_use]
							calc_offsetx( item )
							self._option_edit_view:setVisible(true)
							item:setVisible(true)							
							table.insert(data._options,item)
							edit_use = edit_use + 1
						else
							kits.log("ERROR : can not support data.options > 3")
						end
					end
					--=========
					--分数题结束
					--=========
				else
					--正常填空
					self._option_edit_view:setVisible(true)
					data._options = {}
					for i=1,#self._option_edit do
						data._options[i] = self._option_edit[i]
					end
				end
			end
			local function layout_scroll_arrow(layout_local,data)
				--如果内容超出滚动区
				local size = layout_local:getContentSize()
				local insize = layout_local:getInnerContainerSize()
				if size.height < insize.height then
					self._arrow:setVisible(true)
					self._arrow_up:setVisible(true)
					uikits.event( self._arrow,function(sender)
						layout_local:scrollToBottom(0.3,true)
					end,'click')
					uikits.event( self._arrow_up,function(sender)
						layout_local:scrollToTop(0.3,true)
					end,'click')				
				else
					self._arrow:setVisible(false)
					self._arrow_up:setVisible(false)
				end			
			end
			uikits.delay_call( self,uikits.stopAllSound,1.5 ) --停止可能的播放,放置切换声音被关闭
			--保存答案
			self:save_answer() --不在每次修改时保存，而是在每次切换的时候保存
			data.eventAnswer=function(layout,data)
				--self:save_answer()
				self:check_finished()
			end
			data.eventInitComplate=function(layout,data)
				layout_scroll_arrow(layout,data)
			end
			layout_scroll_arrow(layout,data)
			topics.types[t].init(layout,data)
			self._topics_begin_time = os.time()--开始计时
		else
			--不支持的类型
			if  topics.types[t] and topics.types[t].name then
				kits.log( "Can't support type "..t.."	name : "..topics.types[t].name )
			else
				kits.log( "Can't support type "..t )
			end
			self._option_not_support:setVisible(true)
		end
		self._prev_option_index = i
	end
end

function WorkFlow:init()
	if not self._root then
		self._list = {}
		self:init_gui()
		self:init_data()
		self:optimization_scrollview()
		self:optimization_pageview()
	end
	self:init_delay_release()
end

function WorkFlow:release()
	if self._scID then
		self:getScheduler():unscheduleScriptEntry(self._scID)
		self._scID = nil
	end
end

return WorkFlow