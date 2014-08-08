local kits = require 'kits'
local cache = require 'cache'
local json = require 'json-c'

local course={
	[101]="综合科目",
	[10001]="小学语文",
	[10002]="小学数学",
	[10003]="小学英语",
	[10005]="小学英语笔试",
	[10009]="(小学)信息技术",
	[10010]="(小学)安全知识",
	[10011]="(小学)智力百科",
	[11005]="小学英语听力",
	[20001]="初中语文",
	[20002]="初中数学",
	[20003]="初中英语",
	[20004]="初中物理",
	[20005]="初中化学",
	[20006]="初中政治",
	[20007]="初中生物",
	[20008]="初中地理",
	[20009]="初中历史",
	[30001]="高中语文",
	[30002]="高中数学",
	[30003]="高中英语",
	[30004]="高中物理",
	[30005]="高中化学",
	[30006]="高中政治",
	[30007]="高中生物",
	[30008]="高中地理",
	[30009]="高中历史",
}

local topics={
	[1]="判断",
	[2]="单选",
	[3]="多选",
	[4]="连线",
	[5]="填空",
	[6]="选择",
	[7]="横排序",
	[8]="竖排序",
	[9]="点图单选",
	[10]="点图多选",
	[11]="单拖放",
	[12]="多拖放",
	[13]="完形",
	[14]="复合",
	[15]="主观有答案",
	[16]="主观无答案",
}

local course_icon={
	[0] = {name="综合科目",logo="zhonghe.png"},
	[101]={name="综合科目",logo="zhonghe.png"},
	[10001]={name="小学语文",logo="chinese1.jpg"},
	[10002]={name="小学数学",logo="math.jpg"},
	[10003]={name="小学英语",logo="english.jpg"},
	[10005]={name="小学英语笔试",logo="english.jpg"},
	[10009]={name="(小学)信息技术",logo="infomation.jpg"},
	[10010]={name="(小学)安全知识",logo=""},
	[10011]={name="(小学)智力百科",logo=""},
	[11005]={name="小学英语听力",logo="english.jpg"},
	[20001]={name="初中语文",logo="chinese1.jpg"},
	[20002]={name="初中数学",logo="math.jpg"},
	[20003]={name="初中英语",logo="english.jpg"},
	[20004]={name="初中物理",logo="physics.jpg"},
	[20005]={name="初中化学",logo="chemistry.jpg"},
	[20006]={name="初中政治",logo="politics.jpg"},
	[20007]={name="初中生物",logo="biolody.jpg"},
	[20008]={name="初中地理",logo="geography.jpg"},
	[20009]={name="初中历史",logo="history.jpg"},
	[30001]={name="高中语文",logo="chinese1.jpg"},
	[30002]={name="高中数学",logo="math.jpg"},
	[30003]={name="高中英语",logo="english.jpg"},
	[30004]={name="高中物理",logo="physics.jpg"},
	[30005]={name="高中化学",logo="chemistry.jpg"},
	[30006]={name="高中政治",logo="politics.jpg"},
	[30007]={name="高中生物",logo="biolody.jpg"},
	[30008]={name="高中地理",logo="geography.jpg"},
	[30009]={name="高中历史",logo="history.jpg"},
}

local function read_topics_cache( pid )
	local result = kits.read_cache( pid )
	if result then
		local t = json.decode(result)
		if t then
			return t
		else
			print('error : t = nil, read_topics_cache pid = '..tostring(pid))
		end
	else
		print('error : result = nil , read_topics_cache pid = '..tostring(pid))
	end
end

local function write_topics_cache( pid,t )
	local result = json.encode( t,2 )
	if result then
		kits.write_cache( pid,result )
	else
		print('error : result = nil, write_topics_cache pid = '..tostring(pid))
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

local function print_sort( e )
	kits.log( 'sort:' )
	kits.log( '	sort_items:')
	print_items( e.sort_items )
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

local types={
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
return 
{
	read = read_topics_cache,
	write = write_topics_cache,
	course_map = course,
	topics_map = topics,
	course_icon = course_icon,
	types = types,
}
