local uikits = require "uikits"
local cache = require "cache"
local loadingbox = require "homework/loadingbox"

print( "Hello World!" )
print( "====================" )
local res_root = 'homework/z21_1/'
local ui = {
	FILE = res_root..'z21_1.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	LINK_DOT = res_root..'round_dot.png',
	PAGE_VIEW = 'questions_view',
	NEXT_BUTTON = 'milk_write/next_problem',
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

--[[
	test用
--]]
local cookie_bao = 'sc1=15FD5FCCC97D38082490F38E277704C30C6CD6BAak99MgjoBYOcgHtZIUFvvkV%2fYgutNRji5EzUh8LI5lYpG0jPwGdmMTS%2bqA%2bQqkfvEeP2mYgfxGLd03oZpHpbaewlwrbp3A%3d%3d'
--local url_topics = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx?pid=3544a87f110242798f024d45f1ce74f1&uid=122097"
--local url_topics = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx?pid=93ca856727be4c09b8658935e81db8b8&uid=122097"
local url_topics = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx?pid=93ca856727be4c09b8658935e81db8b8&uid=122097#tc3"

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
	v.coockie = cookie_bao
	rst[#rst+1] = v	
end

function WorkFlow.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),WorkFlow)
	
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

function WorkFlow:init_data()
	--self._data = self:load_original_data_from_file( "job2.json" )
	local result = kits.http_get( url_topics,cookie_bao,5)
	
	if result then
		if type(result) == 'string' then
			self._data = self:load_original_data_from_string( result )
		end
	else
		print('Connect faild : '..url_topics )
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
			return false,msg.." 'options.options' ?"
		end
		if result and type(result) == 'table'  and result.options2 and type(result.options2)=='table' then
			for i,v in pairs(result.options2) do
				if v.option then
					option2_func( v.option )
				end
			end
		else
			return false,msg.." 'options.options2' ?"
		end		
	else
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
	local s = string.match(str,'<img%s+src="(.-)"') --匹配<img src="
	local t = {}
	t.type = 0 --失败
	if s then
		t.type = 2
		t.image = s
	else
		s = string.gsub(str,'<.->','') --删除里面的全部< >
		if s then
			t.type = 1
			t.text = s
		else
			print( '		ERROR parse_html:'..tostring(str) )
		end
	end
	return t
end

local function parse_rect( str )
	local n1,n2,n3,n4 = string.match(str,'\"(%d+),(%d+),(%d+),(%d+)\"')
	if n1 and n2 and n3 and n4 then
		return {x1=tonumber(n1),y1=tonumber(n2),x2=tonumber(n3),y2=tonumber(n4)}
	else
		print( '		ERROR parse_rect : ' ..tostring(str) )
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
			print('		ERROR parse_answer: '..tostring(s) )
		end
	else
		print('		ERROR parse_answer: '..tostring(s) )
	end
end

local function print_rects( t )
	if t and type(t) == 'table' then
		for i,v in pairs(t) do
			if v.x1 and v.y1 and v.x2 and v.y2 then
				print( '		rect# '..v.x1..','..v.y1..','..v.x2..','..v.y2 )
			else
				print( '		nil' )
			end
		end	
	end
end

local function print_items( t )
	if t and type(t)=='table' then
		for i,v in pairs(t) do
			if v.type == 1 then
				print( '		text# '..tostring(v.text) )
			elseif v.type == 2 then
				print( '		image# '..tostring(v.image) )
			end
		end
	end
end

local function print_drag( e )
	print( 'drag:' )
	print( '	img = '..tostring(e.img) )
	print( '	drag_rects:')
	print_rects( e.drag_rects )
	print( '	drag_objs:')
	print_items( e.drag_objs )
end

--单,多拖拽转换
local function drag_conv(s,e)
	local res,msg = parse_attachment(s,1,'drag_conv')
	if res then
		e.img = res
		add_resource_cache( e.resource_cache.urls,res )
	else
		return res,msg
	end
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
	print( 'click:' )
	print( '	img = '..tostring(e.img) )
	print( '	click_rects:')
	print_rects( e.click_rects )
end

--单点和多点转换
local function click_conv(s,e)
	local res,msg = parse_attachment(s,1,'click_conv')
	if res then
		e.img = res
		add_resource_cache( e.resource_cache.urls,res )
	else
		return res,msg
	end
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
	print( 'sort:' )
	print( '	sort_items:')
	print_items( e.sort_items )
end

--排序题转换
local function sort_conv(s,e)
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
	print( 'sort:' )
	print( '	link_items1:')
	print_items( e.link_items1 )
	print( '	link_items2:')
	print_items( e.link_items2 )
	
end
--连线题转换
local function link_conv(s,e)
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
					e.answer = parse_answer( s )
					return true
				end
			},
	[2] = {name='单选',
				conv=function(s,e)
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
	if str then
		local data = kits.decode_json(str)
		if data then
			local ds
			if data.item and type(data.item)=='table' then
				ds = data.item
			else
				ds = data
			end
			for i,v in ipairs(ds) do
				local k = {}
				k.item_type = v.item_type
				k.state = ui.STATE_UNFINISHED
				if v.image then
					k.isload = true --is downloaded?
					k.image = v.image
				else
					k.isload = true
					k.image = 'Pic/my/'..i..'.png'
					print ( k.image )
				end
				if self._type_convs[k.item_type] and self._type_convs[k.item_type].conv then
					print( self._type_convs[k.item_type].name )
					k.resource_cache = {} 
					k.resource_cache.urls = {} --资源缓冲表,
					local b,msg = self._type_convs[k.item_type].conv( v,k )
					if b then
						res[#res+1] = k
					else
						print('转换问题 "'..self._type_convs[k.item_type].name..'" 类型ID"'..k.item_type..'" ID:'..tostring(v.Id))
						print('	error msg: '..msg )
					end
				else
					print('支持的题型: '..v.item_type)
				end
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
		uikits.popScene()
		end)
	self._scrollview = uikits.child(self._root,ui.LIST)
	self._pageview = uikits.child(self._root,ui.PAGE_VIEW)
	self._pageview_size = self._pageview:getSize()
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
	uikits.event( self._next_button,
				function(sender)
					self:next_item()
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

function WorkFlow:set_image( i )
	if not self._data[i].isset and self._data[i].isload then
		local layout = self._pageview:getPage( i-1 )
		if layout then
			local img = uikits.image{image=self._data[i].image,x=self._pageview_size.width/2,y=self._pageview_size.height/2,anchorX=0.5,anchorY=0.5}
			img:setScaleX(WorkFlow.scale)
			img:setScaleY(WorkFlow.scale)
			layout:addChild(img)
			self._data[i].isset = true
		end
	elseif not self._data[i].isload then
		--download?
	end
end

function WorkFlow:add_item( t )
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
		local layout = uikits.layout{bgcolor=cc.c3b(255,255,255)}
		--layout:addChild(uikits.text{caption='Page'..#self._list,fontSize=32})
		self._pageview:addPage( layout )
		--layout:setTouchEnabled(false)
		self:set_image( #self._list )
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
			print('	#TEXT: '..t.text )
			return uikits.text{caption=t.text}
		elseif t.type == 2 then --image
			return uikits.image{image=cache.get_name(t.image)}
		end
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
		if not r then print( msg ) end
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

local function relayout_link( layout,data,op,i )
	local ui1 = {}
	local ui2 = {}
	local dot1 = {}
	local dot2 = {}
	local up = nil
	local down = nil
	local up_rect = nil
	local down_rect = nil
	data.answer = data.answer or {}
	data.answer_links = data.answer_links or {}
	local function do_link()
		if up and down then
			data.answer[up] = down
			if data.answer_links[up] then
				data.answer_links[up]:removeFromParent()
			end
			local x,y = ui1[up]:getPosition()
			x = x + ui1[up]:getSize().width*WorkFlow.scale/2
			local x2,y2 = ui2[down]:getPosition()
			x2 = x2 + ui2[down]:getSize().width*WorkFlow.scale/2
			y2 = y2 + ui2[down]:getSize().height*WorkFlow.scale
			local node = uikits.line{x1=x,y1=y,x2=x2,y2=y2,linewidth=2,color=cc.c3b(255,0,0),fillColor=cc.c4f(0,1,0,1)}
			node:setPosition(cc.p( 0,0 ) )
			layout:addChild( node )
			data.answer_links[up] = node
			
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
			data.state = ui.STATE_FINISHED
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
	uikits.relayout_h( ui1,0,rect1.height*4,layout:getSize().width,WorkFlow.space,WorkFlow.scale)
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
						zorder = sender:getLocalZOrder()
						sender:setLocalZOrder(1000)
					elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
						local p = sender:getTouchEndPos()
						p = layout:convertToNodeSpace( p )
						pageview:setEnabled(true)
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
end

local function relayout_click( layout,data,op,i,ismulti )
	local size = layout:getSize()
	local bg = uikits.image{image=cache.get_name(data.img),x = size.width/2,anchorX=0.5}
	local bg_size = bg:getSize()
	local rects = {}
	local rect_node = {}
	data.answer = data.answer or {}

	bg:setScaleX(WorkFlow.scale)
	bg:setScaleY(WorkFlow.scale)
	layout:addChild( bg )
	for i,v in pairs(data.click_rects) do
		local rc = {x1=v.x1,y1=bg_size.height-v.y1,x2=v.x2,y2=bg_size.height-v.y2}
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
					else
						rect_node[i] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2)}
						bg:addChild( rect_node[i] )
					end
				else --单点
					for k,s in pairs(rect_node) do
						s:removeFromParent()
						rect_node[k] = nil
					end
					rect_node[i] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2)}
					bg:addChild( rect_node[i] )
				end
				data.state = ui.STATE_FINISHED
			end,'click' )
	end
end

local function relayout_drag( layout,data,op,i,ismul,pageview )
	local ui1 = {}
	local ui2 = {}
	local sp
	local orgp = {}
	local bg = uikits.image{image=cache.get_name(data.img),x=layout:getSize().width/2,anchorX = 0.5}
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
										table.remove(drags,i)
										break
									end
								end
							end
						end
						if #drags > 0 then
							data.state = ui.STATE_FINISHED
						else
							data.state = ui.STATE_UNFINISHED
						end
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
end

WorkFlow._topics = {
	--answer = 1 表示A, 2 = B ...
	[1] = {name='判断',img='true_or_false_item.png',
				init=function(self,frame,layout,data,op)
					self._option_yes:setVisible(true)
					self._option_no:setVisible(true)
					if data.answer == 1 then
						self._option_yes:setSelectedState(true)
						self._option_no:setSelectedState(false)
					elseif data.answer == 2 then
						self._option_yes:setSelectedState(false)
						self._option_no:setSelectedState(true)	
					else
						self._option_yes:setSelectedState(false)
						self._option_no:setSelectedState(false)
					end
					uikits.event(self._option_yes,
						function (sender,b)
							if b then
								if data.answer == 2 then
									self._option_no:setSelectedState(false)
								end
								data.answer = 1	
								data.state = ui.STATE_FINISHED
							else
								data.answer = nil
								data.state = ui.STATE_UNFINISHED
							end
						end)
					uikits.event(self._option_no,
						function (sender,b)
							if b then
								if data.answer == 1 then
									self._option_yes:setSelectedState(false)
								end
								data.answer = 2
								data.state = ui.STATE_FINISHED
							else
								data.answer = nil
								data.state = ui.STATE_UNFINISHED
							end						
						end)
				end},
	[2] = {name='单选',img='single_item.png',
				init=function(self,frame,layout,data,op)
					for i = 1,op do
						self._option_img[i]:setVisible(true)
						if i == data.answer then
							self._option_img[i]:setSelectedState(true)
						else
							self._option_img[i]:setSelectedState(false)
						end
						local m = i
						uikits.event(self._option_img[i],
							function(sender,b)
								if b then
									data.answer = m
									self:clear_all_option_check()
									sender:setSelectedState(true)
									data.state = ui.STATE_FINISHED
								else
									data.answer = nil
									data.state = ui.STATE_UNFINISHED
								end
							end)
					end
				end},
	[3] = {name='多选',img='multiple_item.png',
				init=function(self,frame,layout,data,op)
					for i = 1, op do
						self._option_img[i]:setVisible(true)
						if data.answer and type(data.answer)=='table' and data.answer[i] then
							self._option_img[i]:setSelectedState(true)
						else
							self._option_img[i]:setSelectedState(false)
						end
						local m = i
						uikits.event(self._option_img[i],
							function(sender,b)
								data.answer = data.answer or {}
								
								if data.answer[m] then
									data.answer[m] = nil
									data.state = ui.STATE_UNFINISHED
								else
									data.answer[m] = 1
									data.state = ui.STATE_FINISHED
								end
							end)
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
			self._topics[t].init(self,self._answer_field,layout,self._data[i],self._data[i].options,i)
		else
			--不支持的类型
			if  self._topics[t] and  self._topics[t].name then
				print( "Can't support type "..t.."	name : "..self._topics[t].name )
			else
				print( "Can't support type "..t )
			end
			self._option_not_support:setVisible(true)
		end
		self._prev_option_index = i
	end
end

function WorkFlow:init()
	if not self._root then
		self:init_data()
		
		self._list = {}
		self:init_gui()
	end
end

function WorkFlow:release()
end

return WorkFlow