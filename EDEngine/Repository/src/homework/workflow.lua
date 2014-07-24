local uikits = require "uikits"
local cache = require "cache"
local login = require "login"
local loadingbox = require "homework/loadingbox"
local topics = require "homework/topics"
local mt = require "mt"
local json = require "json-c"

kits.log( "Hello World!" )
kits.log( "====================" )
local res_root = 'homework/z21_1/'
local ui = {
	FILE = res_root..'z21_1.json',
	PLAYBOX = 'homework/playbox/playbox.json',
	PLAY = 'pause',
	PAUSE = 'play',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	LINK_DOT = res_root..'round_dot.png',
	ARROW = 'arrow',
	ARROW_UP = 'up',
	PAGE_VIEW = 'questions_view',
	NEXT_BUTTON = 'milk_write/next_problem',
	FINISH_BUTTON = 'milk_write/finish_5',
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
	EDIT_1 = 'option_write_1',
	EDIT_2 = 'option_write_2',
	EDIT_3 = 'option_write_3',
	EDIT_4 = 'option_write_4',
	LINK_TEXT = 'option_connection',
	DRAG_TEXT = 'option_drag',
	POSITION_TEXT = 'option_position',
	POSITION_SORT = 'option_sort',
	ANSWER_TEXT = 'answer_text',
}

local answer_abc = {}
local answer_idx = {}

local function init_answer_map()
	for i = 1,24 do
		answer_abc[i] = string.char( string.byte('A') + i - 1 )
		answer_idx[answer_abc[i]] = i
	end
end

local function string_sort( s )
	local t = {}
	for i = 1,string.len(s) do
		table.insert(t,string.sub(s,i,i))
	end
	table.sort( t )
	return table.concat( t )
end

local this
local function save_my_answer()
	if this then
		this:save_answer()
	else
		kits.log('error save_my_answer this = nil')
	end
end

local loadpaper_url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx"
local loadextam_url = "http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx"
local commit_answer_url = 'http://new.www.lejiaolexue.com/student/handler/SubmitAnswer.ashx'
local cloud_answer_url = 'http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx'
--[[
item
{
	image,
	isload, --图片已经存在
	item_type, --题型
	isdone,
}
--]]
local WorkFlow = class("WorkFlow")
WorkFlow.__index = WorkFlow

local function add_resource_cache( rst,url )
	local v = {}
	if type(url)=='string' then
		v.url = url
	elseif type(url)=='table' and url.type and (url.type == 2 or url.type == 3)
				and url.image then
		v.url = url.image
	end
	v.cookie = login.cookie()
	rst[#rst+1] = v
end

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
	local url = commit_answer_url..'?examId='..tostring(self._args.exam_id)
	..'&itemId='..tostring(v.item_id)
	..'&answer='..tostring(v.my_answer)
	..'&times='..math.floor(os.time()-self._topics_begin_time) --做题题目计时器
	..'&tid='..tostring(self._args.tid)
	self._topics_begin_time = os.time() --重新计时
	local ret = mt.new('GET',url,login.cookie(),
					function(obj)
						if obj.state == 'OK' or obj.state == 'CANCEL' or obj.state == 'FAILED'  then
							if obj.state == 'OK' and obj.data then
								kits.log('	commit '..url..' success!')
							else
								kits.log('	commit '..url..' faild!')
							end
						end
					end )
	if not ret then
		kits.log('	commit '..url..' faild!')
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
			if v.my_answer and self._topics_table.answers[v.item_id] ~= v.my_answer then
			--答案被修改过,需要存储
				if v.item_id then
					self:commit_topics( v )
					self._topics_table.answers[v.item_id] = v.my_answer
					isc = true	
				else
					kits.log('error : WorkFlow:save_answer v.item_id = nil' )
				end
			end
			--结束按钮,状态改变
			if v.state == ui.STATE_UNFINISHED then
				b = false
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

function WorkFlow:init_data( )
	if not (self._args.pid and self._args.uid) then
		kits.log('error : WorkFlow:init_data invalid arguments')
		return
	end
	local loadbox = loadingbox.open( self )
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
		kits.log('error : WorkFlow:init_data exam_id=nil and pid=nil')
		return
	end
	init_answer_map()
	this = self 
	
	local ret = cache.request_resources( { urls = { [1]={url = url_topics,cookie=login.cookie()}},ui=self },
			function(rtb,i,isok)
				if isok then
					local result = cache.get_data( url_topics )
					if result and type(result) == 'string' then
						self._data = self:load_original_data_from_string( result )
						local x
						x,self._item_y = self._item_current:getPosition()
						if self._data then
							self._url_topics = url_topics
							for i,v in pairs(self._data) do
								self:add_item( v )
							end
							self:set_current(1)
							self:relayout()
						end		
						loadbox:removeFromParent()
						return
					end
				end
				loadbox:removeFromParent()
				kits.log('cache request faild :'..url_topics)
			end)
	if not ret then
		--加载失败
		kits.log('Connect faild : '..url_topics )
		loadbox:removeFromParent()
		local box = loadingbox.open( self,loadingbox.RETRY,
			function( id )
				box:removeFromParent() --CLOSE
				if id == loadingbox.TRY then
					self:init_data() --? FIXBUG
				end
			end)
	end
end

local function parse_options(s,option1_func,option2_func,msg)
	if s.options and type(s.options)=='string' then
		local result = kits.decode_json( s.options )
		if result and type(result) == 'table' and result.options and type(result.options)=='table' then
			for i,v in pairs(result.options) do
				if v.option then
					option1_func( v.option )
				end
			end
		else
			kits.log( 'error parse_options '..tostring(s.options) )
			return false,msg.." 'options.options' ?"
		end
		if result and type(result) == 'table'  and result.options2 and type(result.options2)=='table' then
			for i,v in pairs(result.options2) do
				if v.option then
					option2_func( v.option )
				end
			end
		else
			kits.log( 'error parse_options '..tostring(s.options) )
			return false,msg.." 'options.options2' ?"
		end		
	else
		kits.log( 'error parse_options '..tostring(s.options) )
		return false,msg.." 'options' ?"
	end
	return true
end

local function parse_attachment(s,i,msg)
	if s.attachment and type(s.attachment) == 'string' then
		local result = kits.decode_json( s.attachment )
		--取得背景
		if result and type(result) == 'table' and  result.attachments and
			result.attachments[i] then
			return result.attachments[i].value --拖拽背景图
		else
			return false,msg..' "attachment" ?'
		end
	else
		return false,msg..' "attachment" ?'
	end
end
--返回一个表,type=1 文本,2图片,3 mp3 
--fontSize
--fontColor
local function parse_html( str )
	local s = string.match(str,'%s+src%s*=%s*"(.-)"') --匹配<img src="
	local t = {}
	t.type = 0 --失败
	if s then
		t.type = 2
		t.image = s
		kits.log('	parse_html : '..s)
		--kits.log( '	parse_html : '..s..'		'..tostring(str) )
	else
		s = string.gsub(str,'<.->','') --删除里面的全部< >
		if s then
			--形如 A."",B."",去掉
			local ss = string.match(s,'"(.-)"')
			t.type = 1
			if ss then
				t.text = ss
			else
				t.text = s
			end
			kits.log('	parse_html : '..t.text)
		else
			kits.log( '		ERROR parse_html:'..tostring(str) )
		end
	end
	return t
end

local function parse_rect( str )
	local s,n1,n2,n3,n4 = string.match(str,'(%u).*\"(%-*%d+),(%-*%d+),(%-*%d+),(%-*%d+)\"')

	if s and n1 and n2 and n3 and n4 then
		return {x1=tonumber(n1),y1=tonumber(n2),x2=tonumber(n3),y2=tonumber(n4),c=s}
	else
		n1,n2,n3,n4 = string.match(str,'\"(%-*%d+),(%-*%d+),(%-*%d+),(%-*%d+)\"')
		if n1 and n2 and n3 and n4 then
			return {x1=tonumber(n1),y1=tonumber(n2),x2=tonumber(n3),y2=tonumber(n4)}
		else
			kits.log( '		ERROR parse_rect : ' ..tostring(str) )
		end
	end
end	

local function parse_text( str )
	return string.match(str,'\"(.-)\"')
end

local function parse_answer(s)
	if s and s.correct_answer and type(s.correct_answer)=='string' then
		local ca = kits.decode_json( s.correct_answer )
		if ca and ca.answers and type(ca.answers) == 'table' then
			return ca.answers
		else
			kits.log('		ERROR parse_answer: '..tostring(s) )
		end
	end
end

local function print_rects( t )
--[[
	if t and type(t) == 'table' then
		for i,v in pairs(t) do
			if v.x1 and v.y1 and v.x2 and v.y2 then
				kits.log( '		rect# '..v.x1..','..v.y1..','..v.x2..','..v.y2 )
			else
				kits.log( '		nil' )
			end
		end	
	end --]]
end

local function print_items( t )
--[[
	if t and type(t)=='table' then
		for i,v in pairs(t) do
			if v.type == 1 then
				kits.log( '		text# '..tostring(v.text) )
			elseif v.type == 2 then
				kits.log( '		image# '..tostring(v.image) )
			end
		end
	end--]]
end

local function print_drag( e )
--[[
	kits.log( 'drag:' )
	kits.log( '	attachment = '..tostring(e.attachment[1]) )
	kits.log( '	drag_rects:')
	print_rects( e.drag_rects )
	kits.log( '	drag_objs:')
	print_items( e.drag_objs )--]]
end

local function load_attachment(s,e,info)
	e.attachment = eattachment or {}
	for i=1,10 do
		local res,msg = parse_attachment(s,i,info)
		if res then
			e.attachment[#e.attachment+1] = res
			add_resource_cache( e.resource_cache.urls,res )
		else
			return res,msg
		end	
	end
end

function WorkFlow:load_cloud_answer( e )
	if e and type(e)=='table' then
		if e.my_answer and type(e.my_answer)=='string' and string.len(e.my_answer)>0 then
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
				cookie = login.cookie(),
				done = function(data) --处理下载的答案
					if data and type(data)=='string' then
						local result = json.decode(data)
						if result and type(result)=='table' and result.detail and 
							type(result.detail)=='table' and  result.detail.answer  and 
							type(result.detail.answer)=='string' then
							local t = json.decode(result.detail.answer)
							if t and type(t)=='table' and t.answers and type(t.answers)=='table' then
								kits.log('	CLOUD ANSWER:'..result.detail.answer )
								if #t.answers > 0 and t.answers[1].value then
									e.my_answer = t.answers[1].value
								end
							end
						end
					end
				end
			}
		end
	end
end

--单,多拖拽转换
local function drag_conv(s,e)
	load_attachment(s,e,'drag_conv')
	local t = {}
	local t2 = {}
	res,msg = parse_options( s,
		function(op)
			t[#t+1] = parse_rect( op )
		end,
		function(op)
			local item = parse_html( op ) 
			t2[#t2+1] = item
			add_resource_cache( e.resource_cache.urls,item )
		end,
		'drag_conv' )
	e.drag_rects = t
	e.drag_objs = t2
	e.answer = parse_answer( s )

	print_drag( e ) --for debug
	
	return res,msg
end		

local function print_click( e )
	kits.log( 'click:' )
	kits.log( '	attachment = '..tostring(e.attachment[1]) )
	kits.log( '	click_rects:')
	print_rects( e.click_rects )
end

--单点和多点转换
local function click_conv(s,e)
	load_attachment(s,e,'click_conv')
	local t = {}
	local res,msg = parse_options( s,
		function(op)
			t[#t+1] = parse_rect( op )
		end,
		function(op)
		end,
		'click_conv' )
	e.click_rects = t
	e.answer = parse_answer( s )
	
	print_click(e) --for debug
	
	return res,msg
end

local function print_sort( e )
	kits.log( 'sort:' )
	kits.log( '	sort_items:')
	print_items( e.sort_items )
end

--排序题转换
local function sort_conv(s,e)
	load_attachment(s,e,'sort_conv')
	local t = {}
	local res,msg = parse_options( s,
		function(op)
			local item = parse_html( op )
			t[#t+1] = item
			add_resource_cache( e.resource_cache.urls,item )
		end,
		function(op)
		end,
		'sort_conv' )
	e.sort_items = t
	e.answer = parse_answer( s )
	
	print_sort( e ) --for debug
	return res,msg
end

local function print_link( e )
	kits.log( 'sort:' )
	kits.log( '	link_items1:')
	print_items( e.link_items1 )
	kits.log( '	link_items2:')
	print_items( e.link_items2 )
	
end
--连线题转换
local function link_conv(s,e)
	load_attachment(s,e,'link_conv')
	local t = {}
	local t2 = {}
	local res,msg = parse_options( s,
		function(op)
			local item = parse_html( op )
			t[#t+1] = item
			add_resource_cache( e.resource_cache.urls,item )
		end,
		function(op)
			local item = parse_html( op )
			t2[#t2+1] = item
			add_resource_cache( e.resource_cache.urls,item )
		end,
		'drag_conv' )
	e.link_items1 = t
	e.link_items2 = t2
	e.answer = parse_answer( s )
	
	print_link( e ) --for debug
	return res,msg
end

--[[
	将原数据转换为我定义的数据
--]]
WorkFlow._type_convs=
{
	[1] = {name='判断',
				conv=function(s,e)
					load_attachment(s,e,'pd_conv')
					e.answer = parse_answer( s )
					return true
				end
			},
	[2] = {name='单选',
				conv=function(s,e)
					load_attachment(s,e,'signal_conv')
					local op = kits.decode_json( s.options )
					if op and op.options and type(op.options)=='table' then
						e.options = #op.options --取得选择题个数
					else
						return false,"single select 'options'?"
					end
					e.answer = parse_answer( s )
					return true
				end
			},
	[3] = {name='多选',
				conv=function(s,e)
					load_attachment(s,e,'multi_conv')
					local op = kits.decode_json( s.options )
					if op and op.options and type(op.options)=='table' then
						e.options = #op.options --取得选择题个数
					else
						return false,"multiple select 'options'?"
					end
					e.answer = parse_answer( s )
					return true
				end
			},
	[4] = {name='连线',
				conv=link_conv
			},	
	[5] = {name='填空',
				conv=function(s,e)
					load_attachment(s,e,'edit_conv')
					local ca = kits.decode_json( s.correct_answer )
					if ca and ca.answers and type(ca.answers)=='table' then
						e.options = #ca.answers --多少个空
					else
						return false,"edit 'answers'?"
					end
					e.answer = parse_answer( s )
					return true
				end	
			},
	[7] = {name='横排序',
				conv=sort_conv
			},
	[8] = {name='竖排序',
				conv=sort_conv
			},
	[9] = {name='点图单选',
				conv=click_conv
			},
	[10] = {name='点图多选',
				conv=click_conv
			},
	[11] = {name='单拖放',
				conv=drag_conv
			},
	[12] = {name='多拖放',
				conv=drag_conv
			}
}

function WorkFlow:load_original_data_from_file( file )
	local result = kits.read_cache(file)
	if result then
		return self:load_original_data_from_string(result)
	end
end

function WorkFlow:load_original_data_from_string( str )
	local res = {}
	local b = true
	if str then
		local data = kits.decode_json(str)

		if data then
			local ds
			if data.item and type(data.item)=='table' then
				ds = data.item
			else
				ds = data
			end
			self.data = ds --保存副本
			for i,v in ipairs(ds) do
				local k = {}
				k.item_type = v.item_type
				if v.image then
					k.isload = true --is downloaded?
					k.image = v.image
				else
					k.isload = true
					k.image = 'Pic/my/'..i..'.png'
					kits.log( k.image )
				end
				if self._topics_table and self._topics_table.answers then
					--从答案表中取答案
					k.my_answer = self._topics_table.answers[v.item_id]
				else
					k.my_answer = v.my_answer
				end
				if k.my_answer and type(k.my_answer)=='string' and string.len(k.my_answer)>0 then
					k.state =  ui.STATE_FINISHED
				else
					k.state = ui.STATE_UNFINISHED
					b = false
				end
				k.item_id = v.item_id
				if self._type_convs[k.item_type] and self._type_convs[k.item_type].conv then
					kits.log( self._type_convs[k.item_type].name )
					k.resource_cache = {} 
					k.resource_cache.urls = {} --资源缓冲表,
					local b,msg = self._type_convs[k.item_type].conv( v,k )
					if b then
						self:load_cloud_answer( k ) --如果没有本地答案，尝试从网上获取
						res[#res+1] = k
					else
						kits.log('转换问题 "'..self._type_convs[k.item_type].name..'" 类型ID"'..k.item_type..'" ID:'..tostring(v.Id))
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
		end
	end
	return res
end

function WorkFlow:init_gui()
	WorkFlow.scale = uikits.initDR{width=1920,height=1080}
	WorkFlow.space = 16*WorkFlow.scale
	self._root = uikits.fromJson{file=ui.FILE}
	self:addChild(self._root)
	uikits.event(uikits.child(self._root,ui.BACK),function(sender)
		--保存
		self:save()
		uikits.popScene()
		end)
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._pageview = uikits.child(self._root,ui.PAGE_VIEW)
	self._pageview_size = self._pageview:getSize()
	
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

	self._item_size = self._item_current:getSize()
	
	self._next_button = uikits.child(self._root,ui.NEXT_BUTTON )
	self._finish_button = uikits.child(self._root,ui.FINISH_BUTTON )
	uikits.event( self._next_button,
				function(sender)
					self:next_item()
				end,'click')
	uikits.event( self._finish_button,
				function(sender)
					--保存
					self:save()
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

function WorkFlow:set_item_state( i,ste )
	if self._list[i] then
		local item = self._list[i]
		local num = uikits.child(item,ui.ITEM_NUM)
		local s = num:getString()
		local x,y = item:getPosition()
		item:removeFromParent()
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
	if state == ui.STATE_CURRENT then
		return self._item_current:clone()
	elseif state == ui.STATE_FINISHED then
		return self._item_finished:clone()
	elseif state == ui.STATE_UNFINISHED then
		return self._item_unfinished:clone()
	else
		kits.log( '	ERROR: clone_item state = '..tostring(state) )
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
		uikits.event(item,function(sender) self:set_current( index ) end,'click')
		--add page
		local layout = uikits.scrollview{bgcolor=cc.c3b(255,255,255)}
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
	self._option_img[7] = uikits.child(a,ui.OPTION_G)
	self._option_img[8] = uikits.child(a,ui.OPTION_H)
	
	self._option_link = uikits.child(a,ui.LINK_TEXT)
	self._option_drag = uikits.child(a,ui.DRAG_TEXT)
	self._option_sort = uikits.child(a,ui.POSITION_SORT)
	self._option_yes = uikits.child(a,ui.OPTION_YES)
	self._option_no = uikits.child(a,ui.OPTION_NO)
	self._option_not_support = uikits.child(a,ui.OPTION_NO_SUPPORT)
	
	self._option_edit = {}
	self._option_edit[1] = uikits.child(a,ui.EDIT_1)
	self._option_edit[2] = uikits.child(a,ui.EDIT_2)
	self._option_edit[3] = uikits.child(a,ui.EDIT_3)
	self._option_edit[4] = uikits.child(a,ui.EDIT_4)
end

local function item_ui( t )
	if t then
		if t.type == 1 then --text
			--kits.log('	#TEXT: '..t.text )
			return uikits.text{caption=t.text,font='',fontSize=32,color=cc.c3b(0,0,0)}
			--return uikits.text{caption='Linux',fontSize=32,color=cc.c3b(0,0,0)}
		elseif t.type == 2 then --image
			--可能是.mp3
			--png,jpg,gif
			if t.image and type(t.image)=='string' and string.len(t.image)>4 then
				local ex = string.lower( string.sub(t.image,-3) )
				if ex == 'png' or ex == 'jpg' or ex == 'gif' then
					return uikits.image{image=cache.get_name(t.image)}
				elseif ex == 'mp3' then
					kits.log('ERROR MP3 '..t.image )
				else
					kits.log('error item_ui not support file format :'..t.image)
				end
			else
				kits.log('error item_ui image='..tostring(t.image))	
			end
		else
			kits.log('error item_ui type='..tostring(t.type))
		end
	else
		kits.log('error item_ui t = nil')
	end
end

function WorkFlow:clear_all_option_check()
	for i = 1,#self._option_img do
		self._option_img[i]:setSelectedState(false)
	end
end

function WorkFlow:cache_done( rst,efunc,layout,data,op,i,other,pageview )
	if rst and type(rst)=='table' then
		--开始请求资源
		local n = 0
		
		rst.loading = loadingbox.open( layout )

		local r,msg = cache.request_resources( rst,
				function(rs,i,b)
					n = n+1
					if n >= #rs.urls then
						--全部下载完毕
						rst.loading:removeFromParent() 
						rst.loading = nil 
						if efunc and type(efunc)=='function' then
							efunc(layout,data,op,i,other,pageview)
						end
					end
				end )
		if not r then 
			--加载失败
			kits.log( msg ) 
		end
	end
end

--正则rect
local function normal_rect( rc )
	if rc.x1 > rc.x2 then
		local t = rc.x1
		rc.x1 = rc.x2
		rc.x2 = t	
	end
	if  rc.y1 > rc.y2 then
		local t = rc.y1
		rc.y1 = rc.y2
		rc.y2 = t	
	end
end

local function expand_rect( rc,s )
	rc.x1 = rc.x1 - s
	rc.x2 = rc.x2 + s
	rc.y1 = rc.y1 - s
	rc.y2 = rc.y2 + s
end

local function attachment_ui_bg( t )
	if t and type(t)=='table' and t.attachment then
		for i,v in pairs(t.attachment) do
			if v and type(v)=='string' and string.len(v)>4 then
				local ex = string.lower( string.sub(v,-3) )
				if ex=='png' or ex=='gif' or ex=='jpg' then
					return uikits.image{image=cache.get_name(v),x=t.x,anchorX=t.anchorX}
				end
			end
		end
	end
	kits.log('error attachment_ui_bg not found image' )
end

local function attachment_ui_player( t )
	if t and type(t)=='table' and t.attachment then
		for i,v in pairs(t.attachment) do
			if v and type(v)=='string' and string.len(v)>4 then
				local ex = string.lower( string.sub(v,-3) )
				if ex=='mp3' or ex=='wav' then
					local pbox = uikits.fromJson{file=ui.PLAYBOX}
					if pbox then
						pbox:setAnchorPoint(cc.p(0.5,0))
						pbox:setPosition(cc.p(t.x or 0,t.y or 0))
						local play_but = uikits.child(pbox,ui.PLAY)
						local pause_but = uikits.child(pbox,ui.PAUSE)
						local file = cache.get_name(v)
						local snd_idx
						play_but:setVisible(true)
						pause_but:setVisible(false)
						uikits.event(play_but,
							function(sender)
								snd_idx = uikits.playSound(file)
						--		play_but:setVisible(false)
						--		pause_but:setVisible(true)
							end )
							--[[ 目前声音不支持监听状态
						uikits.event(pause_but,
							function(sender)
								if snd_idx then
									play_but:setVisible(true)
									pause_but:setVisible(false)
									uikits.pauseSound(snd_idx)							
								end
							end ) --]]
					end
					return pbox
				end
			end
		end
	end
	kits.log('error attachment_ui_player not found sound' )
end

--设置题干,包括附件
local function set_topics_image( layout,data,x,y )
	--每种题型都有可能有附件声音,或者图片(暂时没有处理?)
	local size = layout:getSize()
	local player = attachment_ui_player{attachment = data.attachment,x = size.width/2,anchorX=0.5}
	if player then
		layout:addChild( player )
		player:setPosition(cc.p(size.width/2,y+WorkFlow.space))
		y = y + player:getSize().height
	end
	if data.image then
	--题目图片
		local img = uikits.image{image=data.image}
		img:setScaleX(WorkFlow.scale)
		img:setScaleY(WorkFlow.scale)
		layout:addChild(img)
		uikits.relayout_h( {img},x,y+2*WorkFlow.space,layout:getSize().width,WorkFlow.space,WorkFlow.scale)
		local size = layout:getSize()
		local width,height
		width = size.width
		height = y+img:getSize().height*WorkFlow.scale + 4 * WorkFlow.space
		layout:setInnerContainerSize( cc.size(width,height) )
	end
end
	
local function relayout_link( layout,data,op,i )
	local ui1 = {}
	local ui2 = {}
	local dot1 = {}
	local dot2 = {}
	local up = nil --选择上索引
	local down = nil --选择下索引
	local up_rect = nil
	local down_rect = nil
	local answer = {}
	local answer_links = {}
	
	local function add_line()
		answer[up] = down
		local x,y = ui1[up]:getPosition()
		x = x + ui1[up]:getSize().width*WorkFlow.scale/2
		local x2,y2 = ui2[down]:getPosition()
		x2 = x2 + ui2[down]:getSize().width*WorkFlow.scale/2
		y2 = y2 + ui2[down]:getSize().height*WorkFlow.scale
		local node = uikits.line{x1=x,y1=y,x2=x2,y2=y2,linewidth=2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,1,0,1)}
		node:setPosition(cc.p( 0,0 ) )
		layout:addChild( node )
		answer_links[up] = node	
	end
	local function do_link()
		if up and down then
			if answer_links[up] then
				answer_links[up]:removeFromParent()
			end
			add_line()
			if up_rect then 
				uikits.delay_call( layout,function() 
							if up_rect then 
								up_rect:removeFromParent() 
								up_rect = nil 
							end
						end,0.2 )
			end
			if down_rect then
				uikits.delay_call( layout,function() 
							if down_rect then 
								down_rect:removeFromParent() 
								down_rect = nil 
							end
						end,0.2 )			
			end
			down = nil
			up = nil
			--收集答案
			data.my_answer = ''
			for i = 1,table.maxn(answer) do
				if answer[i] then
					data.my_answer = data.my_answer..answer_abc[answer[i]]
				else
					data.my_answer = data.my_answer..'0'
				end
			end
			kits.log( data.my_answer )
			if string.len(data.my_answer) > 0 then
				data.state = ui.STATE_FINISHED
			else
				data.state = ui.STATE_UNFINISHED
			end
			save_my_answer()
		end
	end
	local function select_rect(item,b)
		local x,y = item:getPosition()
		local size = item:getSize()
		size.width = size.width*WorkFlow.scale
		size.height = size.height*WorkFlow.scale
		if b then
			if up_rect then up_rect:removeFromParent() end				
			up_rect = uikits.rect{x1=x,y1=y,x2=x+size.width,y2=y+size.height,fillColor=cc.c4f(1,0,0,0.2)}	
			layout:addChild(up_rect)
		else
			if down_rect then down_rect:removeFromParent() end				
			down_rect = uikits.rect{x1=x,y1=y,x2=x+size.width,y2=y+size.height,fillColor=cc.c4f(1,0,0,0.2)}			
			layout:addChild(down_rect)
		end
	end
	for i,v in pairs(data.link_items1) do
		local item = item_ui( v )
		ui1[#ui1+1] = item
		local k = #ui1
		uikits.event( item,
			function(sender)
				up = k
				select_rect(ui1[up],true)
				do_link()
			end,'click' )		
		local s = item:getSize()
		layout:addChild(item)
		local dot = uikits.image{image=ui.LINK_DOT,anchorX=0.5,anchorY=0.5}
		table.insert( dot1,dot )
		dot:setScaleX(0.5)
		dot:setScaleY(0.5)
		layout:addChild(dot)
	end
	for i,v in pairs(data.link_items2) do
		local item = item_ui( v )
		ui2[#ui2+1] = item
		local k = #ui2
		uikits.event( item,
			function(sender)
				down = k
				select_rect(ui2[down],false)
				do_link()
			end,'click' )
		layout:addChild(item)
		local dot = uikits.image{image=ui.LINK_DOT,anchorX=0.5,anchorY=0.5}
		table.insert( dot2,dot )
		dot:setScaleX(0.5)
		dot:setScaleY(0.5)		
		layout:addChild(dot)		
	end

	local rect1 = uikits.relayout_h( ui2,0,0,layout:getSize().width,WorkFlow.space,WorkFlow.scale)
	local rect2 = uikits.relayout_h( ui1,0,rect1.height*4,layout:getSize().width,WorkFlow.space,WorkFlow.scale)
	for i,v in pairs(ui1) do
		local x,y = v:getPosition()
		local size = v:getSize()
		size.width = size.width*WorkFlow.scale
		dot1[i]:setPosition( cc.p(x+size.width/2,y ) )
	end
	for i,v in pairs(ui2) do
		local x,y = v:getPosition()
		local size = v:getSize()
		size.width = size.width*WorkFlow.scale
		size.height = size.height*WorkFlow.scale
		dot2[i]:setPosition( cc.p(x+size.width/2,y+size.height ) )	
	end
	set_topics_image( layout,data,0,rect2.y+rect2.height )
	--载入答案
	if data.my_answer and type(data.my_answer)=='string' and string.len(data.my_answer)>0 then
		for i = 1,string.len(data.my_answer) do
			local s = string.sub(data.my_answer,i,i)
			if s and answer_idx[s] then
				--加入连线
				up = i
				down = answer_idx[s]
				add_line()
			end
		end
		up = nil
		down = nil
	else
		data.my_answer = ''
		for i = 1,#ui1 do
			data.my_answer	 = data.my_answer .. '0'
		end
	end
end

local function get_center_pt( item )
	local size = item:getSize()
	local x,y = item:getPosition()
	return size.width*WorkFlow.scale/2+x,size.height*WorkFlow.scale/2+y
end

local function relayout_sort( layout,data,op,i,isH,pageview )
	local ui1 = {}
	local orgrcs = {}
	local sp = {x=0,y=0}
	local zorder = 1
	local orgp = {}
	local place_rect = nil
	local sorts = {}
	local function isin( item )
		for i,v in pairs(sorts) do
			if v == item then
				return true
			end
		end
	end
	local function remove_item( item )
		for i = 1,#sorts do
			if sorts[i] == item then
				table.remove(sorts,i)
				return
			end
		end
	end
	local function insert( item,x,y )
		for i = 1,#sorts do
			local xx,yy = get_center_pt( sorts[i] )
			if x < xx then
				table.insert(sorts,i,item)
				return
			end
		end
		sorts[#sorts+1] = item
	end
	local function sort_index( item )
		for i = 1,#sorts do
			if sorts[i] == item then
				return i
			end
		end
	end
	local function relayout( item,x,y )
		uikits.relayout_h( sorts,place_rect.x1,place_rect.y1,place_rect.x2-place_rect.x1,WorkFlow.space,WorkFlow.scale,item )
	end
	local function place_item( item,x,y )
		if x > place_rect.x1 and y > place_rect.y1 and x < place_rect.x2 and y < place_rect.y2 then
			if not isin( item ) then
				insert(item,x,y)
			end
			local it = sort_index( item )
			if it then
				local b = false
				table.remove( sorts,it )
				for i = 1,#sorts do
					local xx,yy = get_center_pt( sorts[i] )
					if x < xx then
						table.insert(sorts,i,item)
						b = true
						break
					end
				end
				if not b then
					table.insert(sorts,item)
				end
			end
			relayout( item,x,y )
			return true
		end
	end
	local function map_abc(item)
		for i,v in pairs(ui1) do
			if v == item then
				return answer_abc[i]
			end
		end
	end
	for k,v in pairs( data.sort_items ) do
		local item = item_ui( v )
		layout:addChild( item )
		ui1[#ui1+1] = item
		item:setTouchEnabled(true)
		item:addTouchEventListener(
				function(sender,eventType)
					if eventType == ccui.TouchEventType.began then
						local p = sender:getTouchStartPos()
						sp = sender:convertToNodeSpace( p )
						sp.x = sp.x * WorkFlow.scale
						sp.y = sp.y * WorkFlow.scale
						pageview:setEnabled(false)
						layout:setEnabled(false)
						zorder = sender:getLocalZOrder()
						sender:setLocalZOrder(1000)
					elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
						local p = sender:getTouchEndPos()
						p = layout:convertToNodeSpace( p )
						pageview:setEnabled(true)
						layout:setEnabled(true)
						sender:setLocalZOrder(zorder)
						if not place_item( sender,p.x,p.y ) then 
							sender:setPosition( orgp[sender] )
							remove_item( sender )
						end
						relayout()
						if #sorts > 0 then
							data.state = ui.STATE_FINISHED
						else
							data.state = ui.STATE_UNFINISHED
						end
						--收集答案
						data.my_answer = ''
						for i,v in pairs(sorts) do
							data.my_answer = data.my_answer..map_abc(v)
						end
						kits.log( data.my_answer )
						save_my_answer()
					elseif eventType == ccui.TouchEventType.moved then
						local p = sender:getTouchMovePos()
						p = layout:convertToNodeSpace(p)
						sender:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
						place_item( sender,p.x,p.y )
					end
				end)
	end
	local result = uikits.relayout_h( ui1,0,0,layout:getSize().width,WorkFlow.space,WorkFlow.scale)
	uikits.move( ui1,0,result.height + 26 )
	place_rect = {x1=result.x-4,y1=4,x2=result.x+result.width+4,y2=result.height + 12}
	layout:addChild( uikits.rect{x1=place_rect.x1,y1=place_rect.y1,x2=place_rect.x2,y2=place_rect.y2,color=cc.c3b(0,0,255),linewidth=2} )
	place_rect.y1 = place_rect.y1 + 2 
	for k,v in pairs( ui1 ) do
		local size = v:getSize()
		size.width = size.width * WorkFlow.scale
		size.height = size.height * WorkFlow.scale
		local x,y = v:getPosition()
		orgrcs[#orgrcs+1] = { x=x,y=y,width=size.width,height=size.height }
		layout:addChild( uikits.rect{x1=x-1,y1=y-1,x2=x+size.width+1,y2=y+size.height+1,color=cc.c3b(255,0,0),linewidth=2} )
		orgp[v] = cc.p(x,y)
	end
	set_topics_image( layout,data,0,result.height + 36 + result.height )
	--恢复答案
	if data.my_answer then
		for i = 1,string.len(data.my_answer) do
			local s = string.sub(data.my_answer,i,i)
			if s then
				local n = answer_idx[s]
				table.insert(sorts,ui1[n])
			end
		end
		--排布位置
		relayout()
	end
end

local function relayout_click( layout,data,op,i,ismulti )
	local size = layout:getSize()
	local bg = attachment_ui_bg{attachment = data.attachment,x = size.width/2,anchorX=0.5}
	local rects = {}
	local rect_node = {}
	local bg_size = bg:getSize()
	
	bg:setScaleX(WorkFlow.scale)
	bg:setScaleY(WorkFlow.scale)
	
	local total_height = bg_size.height
	layout:addChild( bg )
	for i,v in pairs(data.click_rects) do
		local rc = {x1=v.x1,y1=bg_size.height-v.y1,x2=v.x2,y2=bg_size.height-v.y2,c=v.c}
		normal_rect( rc )
		expand_rect( rc,2 )
		rects[#rects+1] = rc
		rc.widget = uikits.layout{x=rc.x1,y=rc.y1,width=rc.x2-rc.x1,height=rc.y2-rc.y1}
		bg:addChild( rc.widget )
		uikits.event(rc.widget,
			function (sender) 
				if ismulti then --多点
					if rect_node[i] then
						rect_node[i]:removeFromParent()
						rect_node[i] = nil
						if rects[i].c then
							if string.find(data.my_answer,rects[i].c) then
								data.my_answer = string.gsub(data.my_answer,rects[i].c,'')
							end
						else
							if string.find(data.my_answer,answer_abc[i]) then
								data.my_answer = string.gsub(data.my_answer,answer_abc[i],'')
							end
						end
					else
						rect_node[i] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2)}
						data.my_answer = data.my_answer..answer_abc[i]
						bg:addChild( rect_node[i] )
					end
				else --单点
					for k,s in pairs(rect_node) do
						s:removeFromParent()
						rect_node[k] = nil
					end
					rect_node[i] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2)}
					data.my_answer = answer_abc[i]
					bg:addChild( rect_node[i] )
				end
				data.my_answer = string_sort(data.my_answer)
				kits.log( data.my_answer )
				if string.len(data.my_answer) > 0 then
					data.state = ui.STATE_FINISHED
				else
					data.state = ui.STATE_UNFINISHED
				end				
				save_my_answer()
			end,'click' )
	end
	set_topics_image( layout,data,0,bg_size.height*WorkFlow.scale )
	--载入答案
	if data.my_answer and type(data.my_answer)=='string' then
		for i = 1,string.len(data.my_answer) do
			local s = string.sub(data.my_answer,i,i)
			if s then
				local k = answer_idx[s]
				local rc = rects[k]
				rect_node[k] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2)}
				bg:addChild( rect_node[k] )
			end
		end
	else
		data.my_answer = ''
	end
end

local function relayout_drag( layout,data,op,i,ismul,pageview )
	local ui1 = {}
	local ui2 = {}
	local sp
	local orgp = {}
	local bg =  attachment_ui_bg{attachment=data.attachment,x=layout:getSize().width/2,anchorX = 0.5}
	local drags = {}
	local draging_item
	
	layout:addChild(bg)
	local bgsize = bg:getSize()
	bg:setScaleX(WorkFlow.scale)
	bg:setScaleY(WorkFlow.scale)

	for k,v in pairs( data.drag_rects ) do
		bg:addChild( uikits.rect{x1=v.x1,y1=bgsize.height-v.y1,x2=v.x2,y2=bgsize.height-v.y2,fillColor=cc.c4f(1,0,0,0.1)} )
	end
	local function get_index( item )
		for i = 1,#ui1 do
			if item == ui1[i] then return i end
		end
	end
	local function search_drags( item )
		for i,v in pairs(drags) do
			if v.item == item then
				return i
			end
		end
	end
	local function search_drags_by_index( inx )
		for i,v in pairs(drags) do
			if v.idx == inx then
				return i
			end
		end
	end
	local function get_pt_center( item,i )
		local xx,yy = bg:getPosition()
		local v = data.drag_rects[i]
		xx = xx - bg:getSize().width*WorkFlow.scale/2
		local rc =  {
				x1 = xx + v.x1 * WorkFlow.scale,
				x2 = xx + v.x2 * WorkFlow.scale,
				y1 = yy + (bgsize.height-v.y1)*WorkFlow.scale,
				y2 = yy + (bgsize.height-v.y2)*WorkFlow.scale
			}
			normal_rect( rc )
		local sz = item:getSize()
		local offx = ((rc.x2-rc.x1) - sz.width*WorkFlow.scale)/2
		local offy = ((rc.y2-rc.y1) - sz.height*WorkFlow.scale)/2
		local cp  = {x = rc.x1 + offx,y = rc.y1+ offy } 
		return cp
	end
	local function put_in( sender,x,y )
		local xx,yy = bg:getPosition()
		xx = xx - bg:getSize().width*WorkFlow.scale/2
		for i,v in pairs( data.drag_rects ) do
			local rc = {
				x1 = xx + v.x1 * WorkFlow.scale,
				x2 = xx + v.x2 * WorkFlow.scale,
				y1 = yy + (bgsize.height-v.y1)*WorkFlow.scale,
				y2 = yy + (bgsize.height-v.y2)*WorkFlow.scale
			}
			normal_rect( rc )
			if x > rc.x1 and x < rc.x2 and y > rc.y1 and y < rc.y2 then
				local sz = sender:getSize()
				local offx = ((rc.x2-rc.x1) - sz.width*WorkFlow.scale)/2
				local offy = ((rc.y2-rc.y1) - sz.height*WorkFlow.scale)/2
				local cp = {x = rc.x1 + offx,y = rc.y1+ offy }
				sender:setPosition( cp )
				local idx = get_index( sender )
				if idx then
					local it = search_drags( sender )
					if it then
						drags[it] = nil
					end
					if drags[i] then
						drags[i].item:setPosition( orgp[drags[i].item] )
					end
					drags[i] = { idx = idx,item = sender }
				end
				return true
			end
		end
		return false
	end
	local function put_in_multi( sender,x,y )
		local xx,yy = bg:getPosition()
		xx = xx - bg:getSize().width*WorkFlow.scale/2
		for i,v in pairs( data.drag_rects ) do
			local rc = {
				x1 = xx + v.x1 * WorkFlow.scale,
				x2 = xx + v.x2 * WorkFlow.scale,
				y1 = yy + (bgsize.height-v.y1)*WorkFlow.scale,
				y2 = yy + (bgsize.height-v.y2)*WorkFlow.scale
			}
			normal_rect( rc )
			if x > rc.x1 and x < rc.x2 and y > rc.y1 and y < rc.y2 then
				local sz = draging_item:getSize()
				local offx = ((rc.x2-rc.x1) - sz.width*WorkFlow.scale)/2
				local offy = ((rc.y2-rc.y1) - sz.height*WorkFlow.scale)/2
				local cp = {x = rc.x1 + offx,y = rc.y1+ offy }
				
				local idx
				if not sender.isclone then
					idx = get_index( sender )
				end
				if idx then
					draging_item:setPosition( cp )
					if drags[i] and drags[i].item then
						drags[i].item:removeFromParent()
						drags[i] = nil
					end
					drags[i] = { idx = idx,item = draging_item }
					draging_item = nil
				else
					--?
					local j
					for m,n in pairs(drags) do
						if n.item == draging_item then
							j = m
						end
					end
					if j then
						local v = data.drag_rects[j]
						local rc = {
							x1 = xx + v.x1 * WorkFlow.scale,
							x2 = xx + v.x2 * WorkFlow.scale,
							y1 = yy + (bgsize.height-v.y1)*WorkFlow.scale,
							y2 = yy + (bgsize.height-v.y2)*WorkFlow.scale
						}
						local offx = ((rc.x2-rc.x1) - sz.width*WorkFlow.scale)/2
						local offy = ((rc.y2-rc.y1) - sz.height*WorkFlow.scale)/2
						local cp = {x = rc.x1 + offx,y = rc.y1+ offy }						
						draging_item:setPosition( cp )
					end
				end
				return true
			end
		end
		return false	
	end
	for k,v in pairs( data.drag_objs ) do
		local item = item_ui( v )
		layout:addChild( item )
		table.insert(ui1,item)
		item:setTouchEnabled(true)
		item:addTouchEventListener(
				function(sender,eventType)
					if eventType == ccui.TouchEventType.began then
						local p = sender:getTouchStartPos()
						sp = sender:convertToNodeSpace( p )
						sp.x = sp.x * WorkFlow.scale
						sp.y = sp.y * WorkFlow.scale
						pageview:setEnabled(false)
						layout:setEnabled(false)
						if ismul then
							if not sender.isclone then
								draging_item = sender:clone()
								draging_item.isclone = true
								layout:addChild( draging_item )
							else
								draging_item = sender --isclone
							end
						end
					elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
						local p = sender:getTouchEndPos()
						p = layout:convertToNodeSpace( p )
						pageview:setEnabled(true)
						layout:setEnabled(true)
						if ismul then
							if draging_item then
								if not put_in_multi( sender,p.x,p.y ) then
									if draging_item.isclone then
										for m,n in pairs(drags) do
											if n.item == draging_item then
												drags[m] = nil
												break
											end
										end
									end
									draging_item:removeFromParent()
									draging_item = nil							
								end
							end
						else
							if not put_in( sender,p.x,p.y ) then
								sender:setPosition( orgp[sender] )
								for i,j in pairs(drags) do
									if j.item == sender then
										--table.remove(drags,i)
										drags[i] = nil
										break
									end
								end
							end
						end
						--收集答案
						data.my_answer = ''
						for k=1,table.maxn(drags) do
							if drags[k] then
								data.my_answer = data.my_answer..answer_abc[drags[k].idx]
							else
								data.my_answer = data.my_answer..'0'
							end
						end
						kits.log( data.my_answer )
						if string.len(data.my_answer) > 0 then
							data.state = ui.STATE_FINISHED
						else
							data.state = ui.STATE_UNFINISHED
						end						
						save_my_answer()
					elseif eventType == ccui.TouchEventType.moved then
						local p = sender:getTouchMovePos()
						p = layout:convertToNodeSpace(p)
						if ismul then
							if draging_item then
								draging_item:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
							end
						else
							sender:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
						end
					end
				end)
	end
	local rc = uikits.relayout_h( ui1,0,0,layout:getSize().width,WorkFlow.space,WorkFlow.scale)
	local x,y = bg:getPosition()
	uikits.move( ui1,0,bg:getSize().height*WorkFlow.scale+y+WorkFlow.space )
	for k,v in pairs( ui1 ) do
		local x,y = v:getPosition()
		orgp[v] = cc.p(x,y)
	end

	set_topics_image( layout,data,0,bgsize.height*WorkFlow.scale+y+WorkFlow.space+rc.height)
	--恢复答案
	if data.my_answer then
		for i = 1,string.len(data.my_answer) do
			local s = string.sub(data.my_answer,i,i)
			local k = answer_idx[s]
			if k and ui1[k] then
				if ismul then
					local ts = ui1[k]:clone()
					ts.isclone = true
					drags[i] = { idx = k,item= ts }
					layout:addChild( ts )
					ts:setPosition( get_pt_center(ts,i ))
				else
					drags[i] = { idx = k,item=ui1[k] }
					ui1[k]:setPosition( get_pt_center(ui1[k],i ))
				end
			end
		end
	end
end

local function relayout_topics( layout,data,op,i,ismul,pageview )
	set_topics_image( layout,data,0,WorkFlow.space)
end

WorkFlow._topics = {
	[1] = {name='判断',img='true_or_false_item.png',
				init=function(self,frame,layout,data,op)
					self._option_yes:setVisible(true)
					self._option_no:setVisible(true)
					if data.my_answer == 'A' then
						self._option_yes:setSelectedState(true)
						self._option_no:setSelectedState(false)
					elseif data.my_answer == 'B' then
						self._option_yes:setSelectedState(false)
						self._option_no:setSelectedState(true)	
					else
						self._option_yes:setSelectedState(false)
						self._option_no:setSelectedState(false)
					end
					uikits.event(self._option_yes,
						function (sender,b)
							if b then
								if data.my_answer == 'B' then
									self._option_no:setSelectedState(false)
								end
								data.my_answer = 'A'
								data.state = ui.STATE_FINISHED
							else
								data.my_answer = ''
								data.state = ui.STATE_UNFINISHED
							end
							kits.log( data.my_answer )
							save_my_answer()
						end)
					uikits.event(self._option_no,
						function (sender,b)
							if b then
								if data.my_answer == 'A' then
									self._option_yes:setSelectedState(false)
								end
								data.my_answer = 'B'
								data.state = ui.STATE_FINISHED
							else
								data.my_answer = ''
								data.state = ui.STATE_UNFINISHED
							end			
							kits.log( data.my_answer )				
							save_my_answer()
						end)
					if not data._layout_ then
						self:cache_done( data.resource_cache,relayout_topics,layout,data,op,i )
						data._layout_ = true
					end						
				end},
	[2] = {name='单选',img='single_item.png',
				init=function(self,frame,layout,data,op)
					for i = 1,op do
						self._option_img[i]:setVisible(true)
						if answer_abc[i] == data.my_answer then
							self._option_img[i]:setSelectedState(true)
						else
							self._option_img[i]:setSelectedState(false)
						end
						local m = i
						uikits.event(self._option_img[i],
							function(sender,b)
								if b then
									data.my_answer = answer_abc[m]
									self:clear_all_option_check()
									sender:setSelectedState(true)
									data.state = ui.STATE_FINISHED
								else
									data.my_answer = ''
									data.state = ui.STATE_UNFINISHED
								end
								kits.log( data.my_answer )
								save_my_answer()
							end)
					end
					if not data._layout_ then
						self:cache_done( data.resource_cache,relayout_topics,layout,data,op,i )
						data._layout_ = true
					end					
				end},
	[3] = {name='多选',img='multiple_item.png',
				init=function(self,frame,layout,data,op)
					for i = 1, op do
						self._option_img[i]:setVisible(true)
						if data.my_answer and type(data.my_answer)=='string' and
							string.find(data.my_answer,answer_abc[i]) then
							self._option_img[i]:setSelectedState(true)
						else
							self._option_img[i]:setSelectedState(false)
						end
						local m = i
						uikits.event(self._option_img[i],
							function(sender,b)
								data.my_answer = data.my_answer or ''
								if string.find(data.my_answer,answer_abc[m]) then
									data.my_answer = string.gsub(data.my_answer,answer_abc[m],'')
								else
									data.my_answer = data.my_answer .. answer_abc[m]
								end
								if string.len(data.my_answer) > 0 then
									data.state = ui.STATE_FINISHED
								else
									data.state = ui.STATE_UNFINISHED
								end
								--保持顺序CB->BC
								data.my_answer = string_sort(data.my_answer)
								kits.log( data.my_answer )
								save_my_answer()
							end)
					end
					if not data._layout_ then
						self:cache_done( data.resource_cache,relayout_topics,layout,data,op,i )
						data._layout_ = true
					end					
				end},
	[4] = {name='连线',img='connection_item.png',
				init=function(self,frame,layout,data,op,i)
					self._option_link:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_link,layout,data,op,i )
						data._layout_ = true --界面已经布置好
					end
				end},
	[5] = {name='填空',img='write_item.png',
				init=function(self,frame,layout,data,op)
					if op then
						data.answer = data.answer or {}
						for i = 1,op do
							self._option_edit[i]:setVisible(true)
							local e = uikits.child(self._option_edit[i],ui.ANSWER_TEXT)
							if data.answer and data.answer[i] then
								e:setText(data.answer[i])
							else
								e:setText('')
							end
							uikits.event(e,
									function(sender,eventType)
										if eventType == ccui.TextFiledEventType.insert_text then
											data.state = ui.STATE_FINISHED
											data.answer[i] = sender:getStringValue()
										elseif eventType == ccui.TextFiledEventType.delete_backward then
											data.state = ui.STATE_FINISHED
											data.answer[i] = sender:getStringValue()
										end
									end)							
						end
					end
				end},
	[7] = {name='横排序',img='sort_item.png',
				init=function(self,frame,layout,data,op)
					self._option_sort:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_sort,layout,data,op,i,true,self._pageview )
						data._layout_ = true --界面已经布置好
					end					
				end},
	[8] = {name='竖排序',img='sort_item.png',
				init=function(self,frame,layout,data,op)
					self._option_sort:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_sort,layout,data,op,i,false,self._pageview )
						data._layout_ = true --界面已经布置好
					end					
				end},
	[9] = {name='点图单选',img='position_item.png',
				init=function(self,frame,layout,data,op)
					--self._option_drag:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_click,layout,data,op,i,false,self._pageview )
						data._layout_ = true --界面已经布置好
					end				
				end},
	[10] = {name='点图多选',img='position_item.png',
				init=function(self,frame,layout,data,op)
					--self._option_drag:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_click,layout,data,op,i,true,self._pageview )
						data._layout_ = true --界面已经布置好
					end				
				end},
	[11] = {name='单拖放',img='drag_item.png',
				init=function(self,frame,layout,data,op)
					self._option_drag:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_drag,layout,data,op,i,false,self._pageview )
						data._layout_ = true --界面已经布置好
					end					
				end},
	[12] = {name='多拖放',img='drag_item.png',
				init=function(self,frame,layout,data,op)
					self._option_drag:setVisible(true)
					--初始化
					if not data._layout_ then
						--布置界面
						self:cache_done( data.resource_cache,relayout_drag,layout,data,op,i,true,self._pageview )
						data._layout_ = true --界面已经布置好
					end					
				end},
}

function WorkFlow:set_anwser_field( i )
	if self._data[i] then
		if self._answer_items then
			for i,v in pairs(self._answer_items) do
				v:removeFromParent()
			end
			self._answer_items = {}
			for i=1,8 do
				self._option_img[i]:setVisible(false)
			end
			for i=1,4 do
				self._option_edit[i]:setVisible(false)
			end
			self._option_link:setVisible(false)
			self._option_yes:setVisible(false)
			self._option_no:setVisible(false)			
			self._option_drag:setVisible(false)
			self._option_sort:setVisible(false)
			self._option_not_support:setVisible(false)
		end
		local t = self._data[i].item_type
		
		if self._topics[t] and self._topics[t].img and self._topics[t].init then
			self._answer_type:loadTexture(res_root..self._topics[t].img)
			
			if self._prev_option_index then
				local prev_t = self._data[self._prev_option_index].item_type
				if self._topics[prev_t] and self._topics[prev_t].release then
					--上一个的释放
					local layout = self._pageview:getPage( self._prev_option_index-1 )
					self._topics[prev_t].release( self,self._answer_field,layout,self._data[self._prev_option_index],self._data[self._prev_option_index].options,self._prev_option_index)
				end
			end
			local layout = self._pageview:getPage( i-1 )
			self._topics_begin_time = os.time()--开始计时
			self._topics[t].init(self,self._answer_field,layout,self._data[i],self._data[i].options,i)
			--如果内容超出滚动区
			local size = layout:getSize()
			local insize = layout:getInnerContainerSize()
			if size.height < insize.height then
				self._arrow:setVisible(true)
				self._arrow_up:setVisible(true)
				uikits.event( self._arrow,function(sender)
					layout:scrollToBottom(0.3,true)
				end,'click')
				uikits.event( self._arrow_up,function(sender)
					layout:scrollToTop(0.3,true)
				end,'click')				
			else
				self._arrow:setVisible(false)
				self._arrow_up:setVisible(false)
			end
		else
			--不支持的类型
			if  self._topics[t] and  self._topics[t].name then
				kits.log( "Can't support type "..t.."	name : "..self._topics[t].name )
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
	end
end

function WorkFlow:release()
end

return WorkFlow