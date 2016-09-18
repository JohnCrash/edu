local kits = require 'kits'
local uikits = require 'uikits'
local cache = require 'cache'
local json = require 'json-c'
local login = require "login"
local loadingbox = require "loadingbox"

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

local ui={
	PLAYBOX = 'topics/playbox.json',
	FLASHBOX = 'topics/jgg.ExportJson',
	PLAY = 'pause',
	PAUSE = 'play',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,	
	LINK_DOT = 'topics/round_dot.png',
}

local TOPICS_SPACE = 16
local ITEM_SPACE = 8
local SORT_SPACE = 0
local SORT_BORDER = 0
local SORT_STYLE = 1
local DRAG_STYLE = 1
local DRAG_BORDER = 0
local answer_abc = {}
local answer_idx = {}
local EditChildTag = 'answer_text'
local max_options = 6
local max_edit = 12
local res_root = 'topics/'
local g_default_scale

if uikits.get_factor() == uikits.FACTOR_3_4 then
	g_default_scale = 2*1
else
	g_default_scale = 2*1.2
end

local g_scale = g_default_scale

local function get_default_scale()
	return g_default_scale
end

local function set_scale(s)
	g_scale = s
end

local function get_scale()
	return g_scale
end

local function set_EditChildTag( t )
	EditChildTag = t
end

local function init_answer_map()
	for i = 1,26 do
		answer_abc[i] = string.char( string.byte('A') + i - 1 )
		answer_idx[answer_abc[i]] = i
	end
end

init_answer_map()

local function string_sort( s )
	local t = {}
	for i = 1,string.len(s) do
		table.insert(t,string.sub(s,i,i))
	end
	table.sort( t )
	return table.concat( t )
end

local function call_answer_event(layout,data)
	if data and data.eventAnswer then
		data.eventAnswer(layout,data)
	end
end

local function item_ui( t )
	if t then
		if t.type == 1 then --text
			--kits.log('	#TEXT: '..t.text )
			local item = uikits.text{caption=t.text,font=nil,fontSize=32,color=cc.c3b(0,0,0),anchorX=0.5,anchorY=0.5}			
			local size = item:getContentSize()
			local t = uikits.layout{width=size.width+2*ITEM_SPACE,height=size.height+2*ITEM_SPACE}
			size = t:getContentSize()
			item:setPosition(cc.p(size.width/2,size.height/2))
			--t:setOpacity(12)			
			t:addChild( item )
		
			return t
			--return uikits.text{caption='Linux',fontSize=32,color=cc.c3b(0,0,0)}
		elseif t.type == 2 then --image
			--可能是.mp3
			--png,jpg,gif
			if t.image and type(t.image)=='string' and string.len(t.image)>4 then
				local ex = string.lower( string.sub(t.image,-3) )
				if ex == 'png' or ex == 'jpg' or ex == 'gif' then
					local item = uikits.image{image=cache.get_name(t.image),anchorX=0.5,anchorY=0.5}
					--item:setScaleX(g_scale)
					--item:setScaleY(g_scale)
					local size = item:getContentSize()
					local t = uikits.layout{width=size.width+2*ITEM_SPACE,height=size.height+2*ITEM_SPACE}
					size = t:getContentSize()
					item:setPosition(cc.p(size.width/2,size.height/2))
					--t:setOpacity(12)
					t:addChild( item )			

					return t
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

local function item_ui2( t )
	if t then
		if t.type == 1 then --text
			--kits.log('	#TEXT: '..t.text )
			local item = uikits.text{caption=t.text,font=nil,fontSize=32,color=cc.c3b(0,0,0),anchorX=0.5,anchorY=0.5}			
			local size = item:getContentSize()
			local t = uikits.layout{width=size.width+2*ITEM_SPACE,height=size.height+2*ITEM_SPACE}
			size = t:getContentSize()
			item:setPosition(cc.p(size.width/2,size.height/2))
			--t:setOpacity(12)			
			t:addChild( item )
		
			return t
			--return uikits.text{caption='Linux',fontSize=32,color=cc.c3b(0,0,0)}
		elseif t.type == 2 then --image
			--可能是.mp3
			--png,jpg,gif
			if t.image and type(t.image)=='string' and string.len(t.image)>4 then
				local ex = string.lower( string.sub(t.image,-3) )
				if ex == 'png' or ex == 'jpg' or ex == 'gif' then
					local item = uikits.image{image=cache.get_name(t.image),anchorX=0,anchorY=0}
					local size = item:getContentSize()
					local t = uikits.layout{width=size.width,height=size.height,anchorX=0,anchorY=0}
					size = t:getContentSize()
					--item:setPosition(cc.p(size.width/2,size.height/2))
					--t:setOpacity(12)
					--t:addChild( uikits.rect{x1=0,x2=size.width,y1=0,y2=size.height,fillColor=cc.c4f(1,0,1,0.2),anchorX=0,anchorY=0} )
					t:addChild( item )
					return t
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

local function read_topics_cache( pid )
	local result = kits.read_cache( pid..tostring(login.uid()) )
	if result then
		local t = json.decode(result)
		if t then
			return t
		else
			kits.log('error : t = nil, read_topics_cache pid = '..tostring(pid))
		end
	else
		kits.log('error : result = nil , read_topics_cache pid = '..tostring(pid))
	end
end

local function write_topics_cache( pid,t )
	local result = json.encode( t,2 )
	if result then
		kits.write_cache( pid..tostring(login.uid()),result )
	else
		kits.log('error : result = nil, write_topics_cache pid = '..tostring(pid))
	end
end

local function add_resource_cache( rst,url )
	local v = {}
	if type(url)=='string' then
		v.url = url
	elseif type(url)=='table' and url.type and (url.type == 2 or url.type == 3)
				and url.image then
		v.url = url.image
	end
	if v.url then
		rst[#rst+1] = v
	end
end

local function add_topics_image_resourec( e )
	if e.item_id then
		local host = kits.getImageDownloadServer()
		local uri = "http://"..host.."/item_preview/"..e.item_id.."_0.jpg"
		e.topics_image_name = e.item_id..'.jpg'
		table.insert(e.resource_cache.urls,{url=uri,filename=e.item_id..'.jpg'})
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
			if ss==nil then
				local _,ss1 = string.match(s,"(%u).(.+)")
				if ss1 then ss=ss1 end
			end
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
	if t.text then
		t.text = string.gsub(t.text,string.char(10),'') --去掉可能的回车
		t.text = string.gsub(t.text,'&nbsp;','')
	end
	return t
end

--加引号的格式
local function parse_rect_fh( str )
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

--不加引号的格式
local function parse_rect( str )
	local s,n1,n2,n3,n4 = string.match(str,'(%u).(%-*%d+),(%-*%d+),(%-*%d+),(%-*%d+)')

	if s and n1 and n2 and n3 and n4 then
		return {x1=tonumber(n1),y1=tonumber(n2),x2=tonumber(n3),y2=tonumber(n4),c=s}
	else
		n1,n2,n3,n4 = string.match(str,'(%-*%d+),(%-*%d+),(%-*%d+),(%-*%d+)')
		if n1 and n2 and n3 and n4 then
			return {x1=tonumber(n1),y1=tonumber(n2),x2=tonumber(n3),y2=tonumber(n4)}
		else
			return parse_rect_fh( str )
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
			kits.log('		ERROR parse_answer: '..tostring(ca) )
			kits.log('		have not correct_answer')
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
	e.resource_cache = e.resource_cache or {}
	e.resource_cache.urls = e.resource_cache.urls or {}
	e.attachment = eattachment or {}
	e.item_id = s.item_id
	add_topics_image_resourec( e )
	local i=1
	while true do
		local res,msg = parse_attachment(s,i,info)
		if res then
			e.attachment[#e.attachment+1] = res
			add_resource_cache( e.resource_cache.urls,res )
		else
			return res,msg
		end
		i=i+1
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
	if s.options then
		local t = kits.decode_json(s.options)
		if t and t.drag_position then
			e.drag_position=t.drag_position
		else
			e.drag_position=0
			kits.log("WARNING drag_conv options.drag_position no define")
		end
	else
		e.drag_position=0
		kits.log("WARNING drag_conv options no define")
	end
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

local function isurl( url )
	if url and type(url)=='string' and string.len(url) > 4 then
		if string.lower( string.sub(url,1,4) ) == 'http' then
			return true
		end
	end
	return false
end

local function request_resources( rtable,efunc,priority )
	if rtable and type(rtable)=='table' and rtable.urls and type(rtable.urls) == 'table' and 
		efunc and type(efunc)=='function' then
		local b = true
		for i,v in pairs(rtable.urls) do
			b = false
			if type(v)=='table' and isurl(v.url) then
				cache.request_nc(v.url,function(b)
					efunc( rtable,i,b )
				end,v.filename)
			else
				efunc( rtable,i,false )
			end
		end
		if b then
			efunc( rtable,0,b )
		end
	else
		return false,"request_resources invalid argument"
	end
	return true
end

--下载完毕才能进行下一步的初始化
local function cache_done(layout,data,efunc,param1,param2,param3)
	if data and not data._isdone_ and data.resource_cache then
		data._isdone_ = true
		--开始请求资源
		local n = 0
		local rst = data.resource_cache
		rst.loading = loadingbox.circle( layout )
		local success=true
		local r,msg = request_resources( rst,
				function(rs,i,b)
					n = n+1
					if b and rs.urls[i] and rs.urls[i].done and type(rs.urls[i].done)=='function' then
						local data = cache.get_data( rs.urls[i].url )
						rs.urls[i].done( data )
					end
					if not b then
						success=false
					end
					if n >= #rs.urls then
						--全部下载完毕
						data._isdownload_ = true
						if rst.loading and cc_isobj(rst.loading) then
							rst.loading:removeFromParent() 
						else
							return
						end
						rst.loading = nil 
						if efunc and type(efunc)=='function' then
							efunc(layout,data,param1,param2,param3)
							--初始化完成
							if data.eventInitComplate then
								data.eventInitComplate(layout,data,success)
							end
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
	return rc
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
					return uikits.image{image=cache.get_name(v),x=t.x,y=t.y,anchorX=t.anchorX}
				end
			end
		end
	end
	kits.log('error attachment_ui_bg not found image' )
	return uikits.image{x=t.x,y=t.y,anchorX=t.anchorX}
end

local function attachment_ui_player( t )
	if t and type(t)=='table' and t.attachment then
		for i,v in pairs(t.attachment) do
			if v and type(v)=='string' and string.len(v)>4 then
				local ex = string.lower( string.sub(v,-3) )
				if ex=='mp3' or ex=='wav' then
					local ffplayer = require "ffplayer"
					local pbox = uikits.fromJson{file=ui.PLAYBOX}
					if pbox then
						pbox:setAnchorPoint(cc.p(0.5,0))
						pbox:setPosition(cc.p(t.x or 0,t.y or 0))
						local play_but = uikits.child(pbox,ui.PLAY)
						local pause_but = uikits.child(pbox,ui.PAUSE)
						local file = cache.get_name(v)
						play_but:setVisible(true)
						pause_but:setVisible(false)
						local as = ffplayer.playSound("TOPICS",file,function(state,as)
							if state==ffplayer.STATE_END then
								if play_but and pause_but and cc_isobj(play_but) and cc_isobj(pause_but) then
									play_but:setVisible(true)
									pause_but:setVisible(false)		
								end
							end
						end)	
						uikits.event(play_but,function(sender)
							if as and as.isOpen and (as.isEnd or not as.isPlaying) then
								as:seek(0)
								as:play()
								play_but:setVisible(false)
								pause_but:setVisible(true)
							end
						end,'began')
						uikits.event(pause_but,function(sender)
							if as and as.isOpen and as.isPlaying then
								as:pause()
								play_but:setVisible(true)
								pause_but:setVisible(false)
							end
						end,'began')
						pbox:registerScriptHandler(function(event)
							if event=="cleanup" and as then
								as:close()
							end
						end)
					end
					return pbox
				end
			end
		end
	end
end

--设置题干,包括附件
local function set_topics_image( layout,data,x,y )
	--每种题型都有可能有附件声音,或者图片(暂时没有处理?)
	if layout then
		x = x or 0
		y = y or 0
		local size = layout:getContentSize()
		local player = attachment_ui_player{attachment = data.attachment,x = size.width/2,anchorX=0.5}
		if player then
			layout:addChild( player )
			player:setPosition(cc.p(size.width/2,y+TOPICS_SPACE))
			y = y + player:getContentSize().height
		end
		local size = layout:getContentSize()
		local width,height
		width = size.width
		height = y + 4 * TOPICS_SPACE
		if data.topics_image_name then
		--题目图片
			local img = uikits.image{image=data.topics_image_name}
			local scale=g_scale
			--放大后不能让图片越过边界
			if img:getContentSize().width*g_scale>layout:getContentSize().width then
				scale=layout:getContentSize().width/img:getContentSize().width
			end
			img:setScaleX(scale)
			img:setScaleY(scale)
			layout:addChild(img)
			local is = img:getContentSize()
			if y < 4*TOPICS_SPACE and is.height*scale+y < size.height then --题干纵向居中放置
				y = (size.height - y - is.height*scale)/2 + y
			end
			uikits.relayout_h( {img},x,y+2*TOPICS_SPACE,layout:getContentSize().width,TOPICS_SPACE,scale)
			height = height+img:getContentSize().height*scale 
		end
		if layout.setInnerContainerSize then
			layout:setInnerContainerSize( cc.size(width,height) )
		else
			layout:setContentSize( cc.size(width,height) )
		end
	end
end

local function relayout_topics( layout,data )
	set_topics_image( layout,data,0,TOPICS_SPACE)
end

--连线
local function relayout_link( layout,data )
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
	local scale1 = 1
	local scale2 = 1
	local function add_line()
		answer[up] = down
		local x,y = dot1[up]:getPosition()
		local x2,y2 = dot2[down]:getPosition()
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
			data.my_answer[1] = ''
			for i = 1,table.maxn(answer) do
				if answer[i] then
					data.my_answer[1] = data.my_answer[1]..answer_abc[answer[i]]
				else
					data.my_answer[1] = data.my_answer[1]..'0'
				end
			end
			kits.log( data.my_answer[1] )
			if string.len(data.my_answer[1]) > 0 then
				data.state = ui.STATE_FINISHED
			else
				data.state = ui.STATE_UNFINISHED
			end
			call_answer_event(layout,data)
		end
	end
	local function select_rect(item,b)
		local x,y = item:getPosition()
		local size = item:getContentSize()

		if b then
			size.width = size.width*g_scale*scale1
			size.height = size.height*g_scale*scale1
			if up_rect then up_rect:removeFromParent() end				
			up_rect = uikits.rect{x1=x,y1=y,x2=x+size.width,y2=y+size.height,fillColor=cc.c4f(1,0,0,0.3)}	
			layout:addChild(up_rect,30)
		else
			size.width = size.width*g_scale*scale2
			size.height = size.height*g_scale*scale2
			if down_rect then down_rect:removeFromParent() end				
			down_rect = uikits.rect{x1=x,y1=y,x2=x+size.width,y2=y+size.height,fillColor=cc.c4f(1,0,0,0.3)}			
			layout:addChild(down_rect,30)
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
			end,'began' )		
		local s = item:getContentSize()
		layout:addChild(item,20)
		local dot = uikits.image{image=ui.LINK_DOT,anchorX=0.5,anchorY=0.5}
		table.insert( dot1,dot )
		dot:setScaleX(0.5)
		dot:setScaleY(0.5)
		layout:addChild(dot,20)
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
			end,'began' )
		layout:addChild(item,20)
		local dot = uikits.image{image=ui.LINK_DOT,anchorX=0.5,anchorY=0.5}
		table.insert( dot2,dot )
		dot:setScaleX(0.5)
		dot:setScaleY(0.5)		
		layout:addChild(dot)
	end
	local layout_size = layout:getContentSize()
	local rect1 = uikits.relayout_h( ui2,0,2*TOPICS_SPACE,layout_size.width,TOPICS_SPACE,g_scale)
	if layout_size.width-rect1.width > #ui2*4*TOPICS_SPACE then
		rect1 = uikits.relayout_h( ui2,0,2*TOPICS_SPACE,layout_size.width,4*TOPICS_SPACE,g_scale)
	elseif rect1.width > layout_size.width-2*TOPICS_SPACE then
		scale2 = (layout_size.width-2*TOPICS_SPACE)/rect1.width
		rect1 = uikits.relayout_h( ui2,0,2*TOPICS_SPACE,layout_size.width,TOPICS_SPACE,g_scale*scale2)
	end
	local linkHeight = 198 * g_scale
	if rect1.height*3 < 198 * g_scale then
		linkHeight = rect1.height*3
	end
	local rect2 = uikits.relayout_h( ui1,0,linkHeight,layout_size.width,TOPICS_SPACE,g_scale)
	if layout_size.width-rect2.width > #ui1*4*TOPICS_SPACE then
		rect2 = uikits.relayout_h( ui1,0,linkHeight,layout_size.width,4*TOPICS_SPACE,g_scale)
	elseif rect2.width > layout_size.width-2*TOPICS_SPACE then
		scale1 = (layout_size.width-2*TOPICS_SPACE)/rect2.width
		rect2 = uikits.relayout_h( ui1,0,linkHeight,layout_size.width,TOPICS_SPACE,g_scale*scale1)
	end	
	for i,v in pairs(ui1) do
		local x,y = v:getPosition()
		local size = v:getContentSize()
		size.width = size.width*g_scale *scale1
		dot1[i]:setPosition( cc.p(x+size.width/2,y-TOPICS_SPACE ) )

		--size.width = size.width * g_scale
		size.height = size.height * g_scale *scale1
		layout:addChild(uikits.rect{x1=x-6,y1=y-6,x2=x+size.width+6,y2=y+size.height+6,fillColor=cc.c4f(1,0,0,0.1)})		
	end
	for i,v in pairs(ui2) do
		local x,y = v:getPosition()
		local size = v:getContentSize()
		size.width = size.width*g_scale*scale2
		size.height = size.height*g_scale*scale2
		dot2[i]:setPosition( cc.p(x+size.width/2,y+size.height+TOPICS_SPACE ) )	

		layout:addChild(uikits.rect{x1=x-6,y1=y-6,x2=x+size.width+6,y2=y+size.height+6,fillColor=cc.c4f(1,0,0,0.1)})				
	end
	set_topics_image( layout,data,0,rect2.y+rect2.height )
	--载入答案
	if data.my_answer[1] and type(data.my_answer[1])=='string' and string.len(data.my_answer[1])>0 then
		for i = 1,string.len(data.my_answer[1]) do
			local s = string.sub(data.my_answer[1],i,i)
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
		data.my_answer[1] = ''
		for i = 1,#ui1 do
			data.my_answer[1]	 = data.my_answer[1] .. '0'
		end
	end
end

local function get_center_pt( item )
	local size = item:getContentSize()
	local x,y = item:getPosition()
	return size.width*g_scale/2+x,size.height*g_scale/2+y
end

local function setEnabledParent( layout,b )
	local parent = layout
	while parent do
		if tolua.type(parent) == 'ccui.ScrollView' or 
			tolua.type(parent) == 'ccui.PageView' then
			parent:setEnabled(b)
		end
		parent = parent:getParent() 
	end
end

--排序
local function relayout_sort( layout,data )
	local ui1 = {}
	local orgrcs = {}
	local sp = {x=0,y=0}
	local zorder = 1
	local orgp = {}
	local place_rect = nil
	local sorts = {}
	local scale = 1
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
		local result = uikits.relayout_h( sorts,place_rect.x1,place_rect.y1,place_rect.x2-place_rect.x1,SORT_SPACE,g_scale*scale,item )
		uikits.move( sorts,-result.x,SORT_SPACE)
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
		layout:addChild( item,20 )
		ui1[#ui1+1] = item
		item:setTouchEnabled(true)
		item:addTouchEventListener(
				function(sender,eventType)
					if eventType == ccui.TouchEventType.began then
						local p = sender:getTouchBeganPosition()
						sp = sender:convertToNodeSpace( p )
						sp.x = sp.x * g_scale *scale
						sp.y = sp.y * g_scale *scale
						setEnabledParent(layout,false)
						--if data._scrollParent then
						--	data._scrollParent:setEnabled(false)
						--end
						layout:setEnabled(false)
						zorder = sender:getLocalZOrder()
						sender:setLocalZOrder(1000)
						uikits.playClickSound()
					elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
						uikits.playClickSound(3)
						local p = sender:getTouchEndPosition()
							if layout.getInnerContainer then
							local inner = layout:getInnerContainer()
							if inner then
								p = inner:convertToNodeSpace(p)
							else
								p = layout:convertToNodeSpace(p)
							end
						else
							p = layout:convertToNodeSpace(p)
						end
						setEnabledParent(layout,true)
						--if data._scrollParent then
						--	data._scrollParent:setEnabled(true)
						--end
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
						data.my_answer[1] = ''
						for i,v in pairs(sorts) do
							data.my_answer[1] = data.my_answer[1]..map_abc(v)
						end
						kits.log( data.my_answer[1] )
						call_answer_event(layout,data)
					elseif eventType == ccui.TouchEventType.moved then
						local p = sender:getTouchMovePosition()
						if layout.getInnerContainer then
							local inner = layout:getInnerContainer()
							if inner then
								p = inner:convertToNodeSpace(p)
							else
								p = layout:convertToNodeSpace(p)
							end
						else
							p = layout:convertToNodeSpace(p)
						end				
						local select_idx	= sort_index( sender )
						place_item( sender,p.x,p.y )
						local cur_idx = sort_index( sender )
						if select_idx ~= cur_idx and select_idx then
							uikits.playClickSound(2)
						end
						sender:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
					end
				end)
	end
	local layout_size = layout:getContentSize()
	local result = uikits.relayout_h( ui1,0,0,layout_size.width,SORT_SPACE,g_scale)
	if result.width > layout_size.width-2*SORT_SPACE then
		scale = (layout_size.width-2*SORT_SPACE)/result.width
		result = uikits.relayout_h( ui1,0,0,layout_size.width,SORT_SPACE,g_scale*scale)
	end
	result.height = result.height + 2*SORT_SPACE
	uikits.move( ui1,0,result.height + 4*SORT_SPACE )
	place_rect = {x1=result.x-4,y1=2*SORT_SPACE,x2=result.x+result.width+4,y2=result.height + 2*SORT_SPACE}
	
	layout:addChild( uikits.line{x1=place_rect.x1,y1=place_rect.y1+result.height,x2=place_rect.x1+result.width+6,y2=place_rect.y1+result.height,color=cc.c4f(255,0,255,255),linewidth=3},10)	
	
	layout:addChild( uikits.rect{x1=place_rect.x1,y1=place_rect.y1,x2=place_rect.x2,y2=place_rect.y2,fillColor=cc.c4f(1,0,0,0.1),linewidth=2} )
	place_rect.y1 = place_rect.y1 + 2 
	if SORT_STYLE== 0 then
		--绘制多个矩形
		for k,v in pairs( ui1 ) do
			local size = v:getContentSize()
			size.width = size.width * g_scale *scale
			size.height = size.height * g_scale *scale
			local x,y = v:getPosition()
			orgrcs[#orgrcs+1] = { x=x,y=y,width=size.width,height=size.height }
			layout:addChild( uikits.rect{x1=x-SORT_BORDER,y1=y-SORT_BORDER,x2=x+size.width+SORT_BORDER,y2=y+size.height+SORT_BORDER,fillColor=cc.c4f(0,0,1,0.1),linewidth=2} )
			orgp[v] = cc.p(x,y)
		end
	elseif  SORT_STYLE== 1 then
		--合并为一个矩形
		local rect = {x1=layout_size.width,y1=layout_size.height,x2=0,y2=0}
		local function min_rect(x,y)
			rect.x1 = math.min(rect.x1,x)
			rect.x2 = math.max(rect.x2,x)
			rect.y1 = math.min(rect.y1,y)
			rect.y2 = math.max(rect.y2,y)
		end
		for k,v in pairs( ui1 ) do
			local size = v:getContentSize()
			size.width = size.width * g_scale *scale
			size.height = size.height * g_scale *scale
			local x,y = v:getPosition()
			orgrcs[#orgrcs+1] = { x=x,y=y,width=size.width,height=size.height }
			min_rect( x-SORT_BORDER,y-SORT_BORDER )
			min_rect( x+size.width+SORT_BORDER,y+size.height+SORT_BORDER)
--			layout:addChild( uikits.rect{x1=x-SORT_BORDER,y1=y-SORT_BORDER,x2=x+size.width+SORT_BORDER,y2=y+size.height+SORT_BORDER,fillColor=cc.c4f(0,0,1,0.1),linewidth=2} )
			orgp[v] = cc.p(x,y)
		end		
		layout:addChild( uikits.rect{x1=rect.x1,y1=rect.y1,x2=rect.x2,y2=rect.y2,fillColor=cc.c4f(0,0,1,0.1),linewidth=2} )
	end
	set_topics_image( layout,data,0,result.height + 36 + result.height )
	--恢复答案
	if data.my_answer[1] then
		for i = 1,string.len(data.my_answer[1]) do
			local s = string.sub(data.my_answer[1],i,i)
			if s then
				local n = answer_idx[s]
				table.insert(sorts,ui1[n])
			end
		end
		--排布位置
		relayout()
	end
end

--竖排
local function relayout_sort_V( layout,data )
	local ui1 = {}
	local orgrcs = {}
	local sp = {x=0,y=0}
	local zorder = 1
	local orgp = {}
	local place_rect = nil
	local sorts = {}
	local scale = 1
	
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
		local result = uikits.relayout_v( sorts,SORT_SPACE,g_scale*scale)
		local ox1,oy1
		local layout_size = layout:getContentSize()
		ox1 = layout_size.width/2 + SORT_SPACE
		oy1 = SORT_SPACE
		
		uikits.move(sorts,ox1+SORT_SPACE,oy1-SORT_SPACE/2+place_rect.y2-result.height)		
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
					if y < yy then
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
		layout:addChild( item,20 )
		ui1[#ui1+1] = item
		item:setTouchEnabled(true)
		item:addTouchEventListener(
				function(sender,eventType)
					if eventType == ccui.TouchEventType.began then
						local p = sender:getTouchBeganPosition()
						sp = sender:convertToNodeSpace( p )
						sp.x = sp.x * g_scale * scale
						sp.y = sp.y * g_scale * scale
						setEnabledParent(layout,false)
						layout:setEnabled(false)
						zorder = sender:getLocalZOrder()
						sender:setLocalZOrder(1000)
						uikits.playClickSound()
					elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
						uikits.playClickSound(3)
						local p = sender:getTouchEndPosition()
							if layout.getInnerContainer then
							local inner = layout:getInnerContainer()
							if inner then
								p = inner:convertToNodeSpace(p)
							else
								p = layout:convertToNodeSpace(p)
							end
						else
							p = layout:convertToNodeSpace(p)
						end
						setEnabledParent(layout,true)
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
						data.my_answer[1] = ''
						local len = #sorts
						for i = 1,len do
							data.my_answer[1] = data.my_answer[1]..map_abc(sorts[len-i+1])
						end
						kits.log( data.my_answer[1] )
						call_answer_event(layout,data)
					elseif eventType == ccui.TouchEventType.moved then
						local p = sender:getTouchMovePosition()
						if layout.getInnerContainer then
							local inner = layout:getInnerContainer()
							if inner then
								p = inner:convertToNodeSpace(p)
							else
								p = layout:convertToNodeSpace(p)
							end
						else
							p = layout:convertToNodeSpace(p)
						end						
						local select_idx = sort_index( sender )
						place_item( sender,p.x,p.y )
						local cur_idx = sort_index( sender )
						if select_idx ~= cur_idx  and select_idx then
							uikits.playClickSound(2)
						end
						sender:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
					end
				end)
	end

	local layout_size = layout:getContentSize()
	local result = uikits.relayout_v( ui1,SORT_SPACE,g_scale)
	local ox1,oy1
	ox1 = layout_size.width/2 - result.width - SORT_SPACE
	oy1 = SORT_SPACE
	uikits.move(ui1,ox1+SORT_SPACE,oy1+SORT_SPACE/2)
	--layout:addChild( uikits.rect{x1=ox1,y1=oy1,x2=ox1+result.width,y2=oy1+result.height,fillColor=cc.c4f(1,0,0,0.1)} )
	if result.width > (layout_size.width-4*SORT_SPACE)/2 then
		scale = (layout_size.width-4*SORT_SPACE)/2/result.width
		result = uikits.relayout_v( ui1,SORT_SPACE,g_scale*scale)
		ox1 = layout_size.width/2 - result.width - SORT_SPACE
		oy1 = SORT_SPACE
		uikits.move(ui1,ox1+SORT_SPACE,oy1+SORT_SPACE/2)		
	end
	local ox2,oy2
	ox2 = layout_size.width/2 + SORT_SPACE
	oy2 = SORT_SPACE
	layout:addChild( uikits.line{x1=ox2,y1=oy2,x2=ox2,y2=oy2+result.height,color=cc.c4f(255,0,255,255),linewidth=3},10)
	place_rect = {x1=ox2,y1=oy2,x2=ox2+result.width,y2=oy2+result.height}
	layout:addChild( uikits.rect{x1=place_rect.x1,y1=place_rect.y1,x2=place_rect.x2,y2=place_rect.y2,fillColor=cc.c4f(1,0,0,0.1)} )
	place_rect.y1 = place_rect.y1 + 2 
	if SORT_STYLE== 0 then
		for k,v in pairs( ui1 ) do
			local size = v:getContentSize()
			size.width = size.width * g_scale * scale
			size.height = size.height * g_scale* scale
			local x,y = v:getPosition()
			orgrcs[#orgrcs+1] = { x=x,y=y,width=size.width,height=size.height }
			layout:addChild( uikits.rect{x1=x-SORT_BORDER,y1=y-SORT_BORDER,x2=x+size.width+SORT_BORDER,y2=y+size.height+SORT_BORDER,fillColor=cc.c4f(0,0,1,0.1)} )
			orgp[v] = cc.p(x,y)
		end
	elseif  SORT_STYLE== 1 then
		--合并为一个矩形
		local rect = {x1=layout_size.width,y1=layout_size.height,x2=0,y2=0}
		local function min_rect(x,y)
			rect.x1 = math.min(rect.x1,x)
			rect.x2 = math.max(rect.x2,x)
			rect.y1 = math.min(rect.y1,y)
			rect.y2 = math.max(rect.y2,y)
		end
		for k,v in pairs( ui1 ) do
			local size = v:getContentSize()
			size.width = size.width * g_scale *scale
			size.height = size.height * g_scale *scale
			local x,y = v:getPosition()
			orgrcs[#orgrcs+1] = { x=x,y=y,width=size.width,height=size.height }
			min_rect( x-SORT_BORDER,y-SORT_BORDER )
			min_rect( x+size.width+SORT_BORDER,y+size.height+SORT_BORDER)
--			layout:addChild( uikits.rect{x1=x-SORT_BORDER,y1=y-SORT_BORDER,x2=x+size.width+SORT_BORDER,y2=y+size.height+SORT_BORDER,fillColor=cc.c4f(0,0,1,0.1),linewidth=2} )
			orgp[v] = cc.p(x,y)
		end		
		layout:addChild( uikits.rect{x1=rect.x1,y1=rect.y1,x2=rect.x2,y2=rect.y2,fillColor=cc.c4f(0,0,1,0.1),linewidth=2} )	
	end
	set_topics_image( layout,data,0,result.height + 36 )
	--恢复答案
	if data.my_answer[1] then
		local len = string.len(data.my_answer[1])
		for i = 1,len do
			local s = string.sub(data.my_answer[1],len-i+1,len-i+1)
			if s then
				local n = answer_idx[s]
				table.insert(sorts,ui1[n])
			end
		end
		--排布位置
		relayout()
	end
end

--点选
local function relayout_click( layout,data,ismulti )
	local size = layout:getContentSize()
	local bg = attachment_ui_bg{attachment = data.attachment,x = size.width/2,y=2*TOPICS_SPACE,anchorX=0.5,anchorY=0}
	local rects = {}
	local rect_node = {}
	local bg_size = bg:getContentSize()
	
	bg:setScaleX(g_scale)
	bg:setScaleY(g_scale)
	
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
							if string.find(data.my_answer[1],rects[i].c) then
								data.my_answer[1] = string.gsub(data.my_answer[1],rects[i].c,'')
							end
						else
							if string.find(data.my_answer[1],answer_abc[i]) then
								data.my_answer[1] = string.gsub(data.my_answer[1],answer_abc[i],'')
							end
						end
					else
						rect_node[i] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2),linewidth=2}
						data.my_answer[1] = data.my_answer[1]..answer_abc[i]
						bg:addChild( rect_node[i] )
					end
				else --单点
					for k,s in pairs(rect_node) do
						s:removeFromParent()
						rect_node[k] = nil
					end
					rect_node[i] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2),linewidth=2}
					data.my_answer[1] = answer_abc[i]
					bg:addChild( rect_node[i] )
				end
				data.my_answer[1] = string_sort(data.my_answer[1])
				kits.log( data.my_answer[1] )
				if string.len(data.my_answer[1]) > 0 then
					data.state = ui.STATE_FINISHED
				else
					data.state = ui.STATE_UNFINISHED
				end				
				call_answer_event(layout,data)
			end,'began' )
	end

	set_topics_image( layout,data,0,bg_size.height*g_scale )
	--载入答案
	if data.my_answer[1] and type(data.my_answer[1])=='string' then
		for i = 1,string.len(data.my_answer[1]) do
			local s = string.sub(data.my_answer[1],i,i)
			if s then
				local k = answer_idx[s]
				local rc = rects[k]
				if rc then
					rect_node[k] = uikits.rect{x1=rc.x1,y1=rc.y1,x2=rc.x2,y2=rc.y2,color=cc.c3b(255,0,0),fillColor=cc.c4f(1,0,0,0.2)}
					bg:addChild( rect_node[k] )
				else
					kits.log("WARNING : relayout_click rects["..tostring(k).."] = nil")
				end
			end
		end
	else
		data.my_answer[1] = ''
	end
end

local function relayout_drag( layout,data,ismul )
	local ui1 = {}
	local ui2 = {}
	local sp
	local orgp = {}
	local bg =  attachment_ui_bg{attachment=data.attachment,x=layout:getContentSize().width/2,y=2*TOPICS_SPACE,anchorX = 0.5,anchorY=0}
	local drags = {}
	local draging_item
	local scale = 1
	local side = tonumber(data.drag_position)
	
	print("===")
	print("side="..side)
	print("===")
	local function getPX(bw,w)
		if side==4 or side==2 then
			return 0
		elseif side==1 then
			return -5
		elseif side==3 then
			return -5
		end
	end
	local function getPY(bh,h)
		if side==4 then
			return -(bh-h)/2
		elseif side==2 then
			return -5
		elseif side==1 or side==3 then
			return 0
		end
	end
	local function getOffX(bw,w)
		--return (bw-w*g_scale)/2-(getPX(bw/g_scale,w)+3)*g_scale
		local v = (bw-w*g_scale)/2-3*g_scale
		return v
	end
	local function getOffY(bh,h)
		--return (bh-h*g_scale)/2-(getPY(bh/g_scale,h)+3)*g_scale
		v = (bh-h*g_scale)/2+3*g_scale --(getPY(bh/g_scale,h)+3)*g_scale
		return v
	end
	layout:addChild(bg)
	local bgsize = bg:getContentSize()
	bg:setScaleX(g_scale)
	bg:setScaleY(g_scale)

	for k,v in pairs( data.drag_rects ) do
		v.x1 = v.x1-DRAG_BORDER
		v.x2 = v.x2+DRAG_BORDER
		v.y1 = v.y1-DRAG_BORDER
		v.y2 = v.y2+DRAG_BORDER
	end	
	--DRAG_STYLE=0
	if DRAG_STYLE == 0 then
		for k,v in pairs( data.drag_rects ) do
			--[[
			local box = uikits.animationFormJson("amouse/chong_zi/chong_zi.ExportJson",'chong_zi')
			box:getAnimation():playWithIndex(0)
			box:setPosition(cc.p((v.x2+v.x1)/2,bgsize.height-(v.y2+v.y1)/2))
			local size = box:getContentSize()
			box:setScaleX(math.abs(v.x2-v.x1)/size.width)
			box:setScaleY(math.abs(v.y2-v.y1)/size.height)
			--]]
			--box:setOpacity (256)
			--bg:addChild( box )
--			bg:addChild( uikits.rect{x1=v.x1-DRAG_BORDER,y1=bgsize.height-v.y1-DRAG_BORDER,
--				x2=v.x2+DRAG_BORDER,y2=bgsize.height-v.y2+DRAG_BORDER,fillColor=cc.c4f(1,0,0,0.1)} )
			bg:addChild( uikits.rect{x1=v.x1,y1=bgsize.height-v.y1,
				x2=v.x2,y2=bgsize.height-v.y2,fillColor=cc.c4f(1,0,0,0.1)} )
		end
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
		if not v then
			kits.log("WARNING : get_pt_center data.drag_rects["..tostring(i).."] = nil")
			return {x=0,y=0}
		end
		xx = xx - bg:getContentSize().width*g_scale/2
		local rc =  {
				x1 = xx + v.x1 * g_scale,
				x2 = xx + v.x2 * g_scale,
				y1 = yy + (bgsize.height-v.y1)*g_scale,
				y2 = yy + (bgsize.height-v.y2)*g_scale
			}
			normal_rect( rc )
		local sz = item:getContentSize()
		local offx = ((rc.x2-rc.x1) - sz.width*g_scale)/2
		local offy = ((rc.y2-rc.y1) - sz.height*g_scale)/2
		local cp  = {x = rc.x1 + offx,y = rc.y1+ offy } 
		return cp
	end
	local function  xchange( i,j )
		--source = j -> target = i
		if i and j and drags[j] then
			local target
			target = drags[i]
			drags[i] = drags[j]
			drags[j] = target
			local function get_drag_rect(n)
				local xx,yy = bg:getPosition()
				xx = xx - bg:getContentSize().width*g_scale/2
				local v = data.drag_rects[n]
				return normal_rect{
				x1 = xx + v.x1 * g_scale,
				x2 = xx + v.x2 * g_scale,
				y1 = yy + (bgsize.height-v.y1)*g_scale,
				y2 = yy + (bgsize.height-v.y2)*g_scale
				}
			end
			if drags[i] and drags[i].item then
				local sz = drags[i].item:getContentSize()
				local rc = get_drag_rect(i)
				local offx = getOffX(rc.x2-rc.x1,sz.width)
				local offy = getOffY(rc.y2-rc.y1,sz.height)				
				local cp= {x = rc.x1 + offx,y = rc.y1+ offy }
				drags[i].item:setPosition(cp)
			end
			if drags[j] and drags[j].item then
				local sz = drags[j].item:getContentSize()
				local rc = get_drag_rect(j)
				local offx = getOffX(rc.x2-rc.x1,sz.width)
				local offy = getOffY(rc.y2-rc.y1,sz.height)				
				local cp= {x = rc.x1 + offx,y = rc.y1+ offy }
				drags[j].item:setPosition(cp)
			end
		end
	end	
	local function put_in( sender,x,y )
		local xx,yy = bg:getPosition()
		xx = xx - bg:getContentSize().width*g_scale/2
		for i,v in pairs( data.drag_rects ) do
			local rc = {
				x1 = xx + v.x1 * g_scale,
				x2 = xx + v.x2 * g_scale,
				y1 = yy + (bgsize.height-v.y1)*g_scale,
				y2 = yy + (bgsize.height-v.y2)*g_scale
			}
			normal_rect( rc )
			
		--	layout:addChild(uikits.rect{x1=rc.x1,y1=rc.y1,
		--		x2=rc.x2,y2=rc.y2,fillColor=cc.c4f(0,1,0,0.2)})
				
			if x > rc.x1 and x < rc.x2 and y > rc.y1 and y < rc.y2 then
				local sz = sender:getContentSize()
				local offx = getOffX(rc.x2-rc.x1,sz.width)
				local offy = getOffY(rc.y2-rc.y1,sz.height)
				local cp = {x = rc.x1 + offx,y = rc.y1+ offy }
				sender:setPosition( cp )
				-- sender:setAnchorPoint(cc.p(0,0))
				-- print("sx="..sender:getScaleX())
			-- layout:addChild(uikits.rect{x1=cp.x,y1=cp.y,
				-- x2=cp.x+sz.width,y2=cp.y+sz.height,fillColor=cc.c4f(0,0,1,0.2),anchorX=0,anchorY=0})			
				
				local idx = get_index( sender )
				if idx then
					local it = search_drags( sender )
					if it and i and i~=it then
						xchange(i,it)
					else
						if it then
							drags[it] = nil
						end
						if drags[i] then
							drags[i].item:setScaleX(g_scale*scale)
							drags[i].item:setScaleY(g_scale*scale)					
							drags[i].item:setPosition( orgp[drags[i].item] )
						end
						sender:setScaleX(g_scale)
						sender:setScaleY(g_scale)					
						drags[i] = { idx = idx,item = sender }
					end
				end
				return true
			end
		end
		return false
	end
	local function put_in_multi( sender,x,y )
		local xx,yy = bg:getPosition()
		xx = xx - bg:getContentSize().width*g_scale/2
		for i,v in pairs( data.drag_rects ) do
			local rc = {
				x1 = xx + v.x1 * g_scale,
				x2 = xx + v.x2 * g_scale,
				y1 = yy + (bgsize.height-v.y1)*g_scale,
				y2 = yy + (bgsize.height-v.y2)*g_scale
			}
			normal_rect( rc )
			if x > rc.x1 and x < rc.x2 and y > rc.y1 and y < rc.y2 then
				local sz = draging_item:getContentSize()
				local offx = getOffX(rc.x2-rc.x1,sz.width)
				local offy = getOffY(rc.y2-rc.y1,sz.height)	
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
					draging_item:setScaleX(g_scale)
					draging_item:setScaleY(g_scale)
					drags[i] = { idx = idx,item = draging_item }
					draging_item = nil
				else
					--xchange
					local j
					for m,n in pairs(drags) do
						if n.item == draging_item then
							j = m
							break
						end
					end
					xchange( i,j )
				end
				return true
			end
		end
		return false	
	end
	local ismoving --触点没有移动标志
	for k,v in pairs( data.drag_objs ) do
		local item = item_ui2( v )
		layout:addChild( item,100 )
		table.insert(ui1,item)
		item:setTouchEnabled(true)
		item:addTouchEventListener(
				function(sender,eventType)
					if eventType == ccui.TouchEventType.began then
						uikits.playClickSound()
						ismoving = false
						local p = sender:getTouchBeganPosition()
						sp = sender:convertToNodeSpace( p )
						sp.x = sp.x * g_scale
						sp.y = sp.y * g_scale
						setEnabledParent(layout,false)
						layout:setEnabled(false)
						if ismul then
							if not sender.isclone then
								draging_item = sender:clone()
								draging_item.isclone = true
								layout:addChild( draging_item,100 )
							else
								draging_item = sender --isclone
							end
						end
					elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
						uikits.playClickSound(3)
						local p = sender:getTouchEndPosition()
						if layout.getInnerContainer then
							local inner = layout:getInnerContainer()
							if inner then
								p = inner:convertToNodeSpace(p)
							else
								p = layout:convertToNodeSpace(p)
							end
						else
							p = layout:convertToNodeSpace(p)
						end			
						setEnabledParent(layout,true)
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
									uikits.delay_call(layout,function()draging_item:removeFromParent()end,0)
								end
							end
						else
							if not put_in( sender,p.x,p.y ) then
								sender:setScaleX( g_scale*scale )
								sender:setScaleY( g_scale*scale )
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
						data.my_answer[1] = ''
						for k=1,table.maxn(drags) do
							if k>1 then
								data.my_answer[1] = data.my_answer[1]..';'
							end
							if drags[k] then									
								data.my_answer[1] = data.my_answer[1]..answer_abc[k]..answer_abc[drags[k].idx]
							else
								data.my_answer[1] = data.my_answer[1]..answer_abc[k]..'0'
							end
						end
						kits.log( data.my_answer[1] )
						if string.len(data.my_answer[1]) > 0 then
							data.state = ui.STATE_FINISHED
						else
							data.state = ui.STATE_UNFINISHED
						end						
						call_answer_event(layout,data)
					elseif eventType == ccui.TouchEventType.moved then
						ismoving = true
						local p = sender:getTouchMovePosition()
						if layout.getInnerContainer then
							local inner = layout:getInnerContainer()
							if inner then
								p = inner:convertToNodeSpace(p)
							else
								p = layout:convertToNodeSpace(p)
							end
						else
							p = layout:convertToNodeSpace(p)
						end
						if ismul then
							if draging_item then
								draging_item:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
							end
						else
							sender:setPosition( cc.p(p.x-sp.x,p.y-sp.y) )
						end	
						--加入一个滚动，应对拖放位置和目标距离超过一屏
						if layout.scrollToBottom then
							p = sender:getTouchMovePosition()
							local layout_size = layout:getContentSize()
							if p.y < layout_size.height/4 then
								layout:scrollToBottom(0.2,true)
							end
						end
					end
				end)
	end
	
	local layout_size = layout:getContentSize()
	local rc = uikits.relayout_h( ui1,0,0,layout_size.width,2*TOPICS_SPACE,g_scale)
	if rc.width > layout_size.width-2*TOPICS_SPACE then --如果太长，缩小重新排列
		scale = (layout_size.width-2*TOPICS_SPACE)/rc.width
		rc = uikits.relayout_h( ui1,0,0,layout_size.width,TOPICS_SPACE,g_scale*scale)		
	elseif rc.width < layout_size.width/2 then --太小，加大点间距重新排列
		rc = uikits.relayout_h( ui1,0,0,layout_size.width,4*TOPICS_SPACE,g_scale)	
	end
	
	local x,y = bg:getPosition()
	uikits.move( ui1,0,bg:getContentSize().height*g_scale+y+2*TOPICS_SPACE )
	for k,v in pairs( ui1 ) do
		local x,y = v:getPosition()
		orgp[v] = cc.p(x,y)
		local size =v:getContentSize()
		size.width = size.width * g_scale * scale
		size.height = size.height * g_scale * scale
		layout:addChild(uikits.rect{x1=x-6,y1=y-6,x2=x+size.width+6,y2=y+size.height+6,fillColor=cc.c4f(1,0,0,0.1)})
	end

	set_topics_image( layout,data,0,bgsize.height*g_scale+y+TOPICS_SPACE+rc.height)
	--恢复答案
	--AB;BC;CD
	if data.my_answer[1] then
		--将AB;BC;CD转换为BCD
		local aws = string.gsub(data.my_answer[1],';','')
		local s = ''
		for i = 1,string.len(aws) do
			if i%2==0 then
				s = s..string.sub(aws,i,i)
			end
		end
		local asw = s
		for i = 1,string.len(asw) do
			local s = string.sub(asw,i,i)
			local k = answer_idx[s]
			if k and ui1[k] then
				if ismul then
					local ts = ui1[k]:clone()
					ts.isclone = true
					ts:setScaleX(g_scale)
					ts:setScaleY(g_scale)
					drags[i] = { idx = k,item= ts }
					layout:addChild( ts,10 )
					ts:setPosition( get_pt_center(ts,i ))
				else
					ui1[k]:setScaleX(g_scale)
					ui1[k]:setScaleY(g_scale)				
					drags[i] = { idx = k,item=ui1[k] }
					ui1[k]:setPosition( get_pt_center(ui1[k],i ))
				end
			end
		end
	end
end

local function multi_select_conv(s,e)
	load_attachment(s,e,'multi_conv')
	local op = kits.decode_json( s.options )
	if op and op.options and type(op.options)=='table' then
		e.options = math.min(#op.options,max_options) --取得选择题个数
	else
		e.options = max_options
		kits.log('ERROR multi_select_conv '..tostring(s.options))
		return false,"multiple select 'options'?"
	end
	if not e.options or (e.options and e.options <= 0) then
		e.options = max_options
		kits.log('ERROR : multi_select_conv '..tostring(s.options))
	end
	e.answer = parse_answer( s )
	e.my_answer = e.my_answer or {}
	return true
end

local function multi_select_init(layout,data)
	if data._options then
		local _options = data._options
		for i = 1, data.options do
			_options[i]:setVisible(true)
			if data.my_answer[1] and type(data.my_answer[1])=='string' and
				string.find(data.my_answer[1],answer_abc[i]) then
				_options[i]:setSelectedState(true)
			else
				_options[i]:setSelectedState(false)
			end
			local m = i
			uikits.event(_options[i],
				function(sender,b)
					data.my_answer[1] = data.my_answer[1] or ''
					if string.find(data.my_answer[1],answer_abc[m]) then
						data.my_answer[1] = string.gsub(data.my_answer[1],answer_abc[m],'')
					else
						data.my_answer[1] = data.my_answer[1] .. answer_abc[m]
					end
					if string.len(data.my_answer[1]) > 0 then
						data.state = ui.STATE_FINISHED
					else
						data.state = ui.STATE_UNFINISHED
					end
					--保持顺序CB->BC
					data.my_answer[1] = string_sort(data.my_answer[1])
					kits.log( data.my_answer[1] )
					call_answer_event(layout,data)
				end,'began')
		end --for
	end --if
	cache_done(layout,data,relayout_topics)
end						

local function judge(layout,data)
	if data._options  then --具有答题区
		--初始化答案
		data.my_answer = data.my_answer or {}
		local _option_yes = data._options[1]
		local _option_no = data._options[2]
		_option_yes:setVisible(true)
		_option_no:setVisible(true)
		if data.my_answer[1] == 'A' then
			_option_yes:setSelectedState(true)
			_option_no:setSelectedState(false)
		elseif data.my_answer[1] == 'B' then
			_option_yes:setSelectedState(false)
			_option_no:setSelectedState(true)	
		else
			_option_yes:setSelectedState(false)
			_option_no:setSelectedState(false)
		end
	uikits.event(_option_yes,
		function (sender,b)
			if b then
				if data.my_answer[1] == 'B' then
					_option_no:setSelectedState(false)
				end
				data.my_answer[1] = 'A'
				data.state = ui.STATE_FINISHED
			else
				data.my_answer[1] = ''
				data.state = ui.STATE_UNFINISHED
			end
			kits.log( data.my_answer[1] )
			call_answer_event(layout,data)
		end,'began')
	uikits.event(_option_no,
		function (sender,b)
			if b then
				if data.my_answer[1] == 'A' then
					_option_yes:setSelectedState(false)
				end
				data.my_answer[1] = 'B'
				data.state = ui.STATE_FINISHED
			else
				data.my_answer[1] = ''
				data.state = ui.STATE_UNFINISHED
			end			
			kits.log( data.my_answer[1] )				
			call_answer_event(layout,data)
		end,'began')						
	end
	cache_done(layout,data,relayout_topics)
end

local function single_select(layout,data)
	if data._options then
		data.my_answer = data.my_answer or {}
		local _options = data._options
		for i = 1,data.options do
			_options[i]:setVisible(true)
			if answer_abc[i] == data.my_answer[1] then
				_options[i]:setSelectedState(true)
			else
				_options[i]:setSelectedState(false)
			end
			local m = i
			uikits.event(_options[i],
				function(sender,b)
					if b then
						data.my_answer[1] = answer_abc[m]
						for i=1,#_options do
							_options[i]:setSelectedState(false)
						end
						sender:setSelectedState(true)
						data.state = ui.STATE_FINISHED
					else
						data.my_answer[1] = ''
						data.state = ui.STATE_UNFINISHED
					end
					kits.log( data.my_answer[1] )
					call_answer_event(layout,data)
				end,'began')
		end
	end
	cache_done(layout,data,relayout_topics)
end

local EditSpace = 32
local function setEditSpace( d )
	EditSpace = d
end

local function edit_topics(layout,data)
	local function init_edit_tipics()
		if data.options then
			data.my_answer = data.my_answer or {}
			local _options = data._options
			for i = 1,data.options do
				if _options and _options[i] then
					_options[i]:setVisible(true)
					local e
					if cc_type(_options[i]) == 'ccui.TextField' then
						e = _options[i]
					else
						e = uikits.child(_options[i],EditChildTag)
					end
					if data.my_answer[i] then
						e:setText(data.my_answer[i])
					else
						e:setText('')
						data.my_answer[i] = ''
					end
					uikits.event(e,
							function(sender,eventType)
								if eventType == ccui.TextFiledEventType.insert_text then
									data.state = ui.STATE_FINISHED
									data.my_answer[i] = sender:getStringValue()
									call_answer_event(layout,data)
								elseif eventType == ccui.TextFiledEventType.delete_backward then
									data.state = ui.STATE_FINISHED
									data.my_answer[i] = sender:getStringValue()
									call_answer_event(layout,data)
								end
							end)	
				end
			end	
			if _options and type(_options)=='table' then
				local innparent = _options[1]:getParent()
				local parent
				if innparent then
					parent = innparent:getParent()
				end
				if parent and cc_type(parent)=='ccui.ScrollView' then
					local w,h
					h = _options[1]:getContentSize().height
					w = ((_options[1]:getContentSize().width)+EditSpace)*data.options+2*EditSpace
					parent:setInnerContainerSize(cc.size(w,h))
				end
			end		
		end
	end
	
	local function resans_done(layout,data)
		init_edit_tipics()
		relayout_topics(layout,data)
	end
	
	init_edit_tipics()
	cache_done(layout,data,resans_done)
end
--[[
	conv(s,e) 输入的源数据，e是输出的数据
	
	init根据data构建题目,并且将题目内容放置在layout中。
	data中可以附加下列事件
		eventInitComplate(layout,data) 当试题初始化完毕调用
		eventAnswer(layout,data) 当题做了一次回答(修改)
	data中可以附加的数据
		_options 一个控件数组，对于判断题，选择题，它是一个ccui.CheckBox对象数组
						编辑题是一个ccui.TextFeild数组.这些控件组成答题区，控件位置有调用者设置.
		my_answer 答案，一个字符串
--]]

local types={
	[1] = {name='判断',img=res_root..'true_or_false_item.png',
				conv=function(s,e)
					load_attachment(s,e,'pd_conv')
					e.answer = parse_answer( s )
					return true
				end,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					judge(layout,data)
				end
			},
	[2] = {name='单选',img=res_root..'single_item.png',
				conv=function(s,e)		
					load_attachment(s,e,'signal_conv')
					local op = kits.decode_json( s.options )
					if op and op.options and type(op.options)=='table' then
						e.options = math.min(#op.options,max_options) --取得选择题个数
					else
						e.options = 0
						return false,"single select 'options'?"
					end
					e.answer = parse_answer( s )
					return true
				end,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					single_select(layout,data)				
				end
			},
	[3] = {name='多选',img=res_root..'multiple_item.png',
				conv=multi_select_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					multi_select_init(layout,data)
				end
			},
	[4] = {name='连线',img=res_root..'connection_item.png',
				conv=link_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_link)
				end
			},	
	[5] = {name='填空',img=res_root..'write_item.png',
				conv=function(s,e)
					load_attachment(s,e,'edit_conv')
					--判断是不是分数题
					if s.correct_answer then
						local ans = json.decode(s.correct_answer)
						if ans and ans.answers and type(ans.answers)=='table' then
							e.options = 0
							local haveEx
							for k,v in pairs(ans.answers) do
								if v and v.value and type(v.value) == 'string' then
									local str = v.value
									local num1,num2,num3 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*~(%-*%+*%d*$*)%s*')
									if num1 and num2 and num3 then
										e.isFraction = e.isFraction or {}
										table.insert(e.isFraction,3)
										e.options = e.options + 3
									else
										num1,num2 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*')
										if num1 and num2 then
											e.isFraction = e.isFraction or {}
											table.insert(e.isFraction,2)
											e.options = e.options + 2
										else
											haveEx = true
										end
									end									
								end
							end
							--形如1,1~2的答案需要重新搜索
							if e.isFraction and haveEx then
								--重新搜索一遍
								e.isFraction = {}
								e.options = 0
								for k,v in pairs(ans.answers) do
									if v and v.value and type(v.value) == 'string' then
										local str = v.value
										local num1,num2,num3 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*~(%-*%+*%d*$*)%s*')
										if num1 and num2 and num3 then
											e.isFraction = e.isFraction or {}
											table.insert(e.isFraction,3)
											e.options = e.options + 3
										else
											num1,num2 = string.match( str,'%s*(%-*%+*%d*$*)%s*~%s*(%-*%+*%d*$*)%s*')
											if num1 and num2 then
												e.isFraction = e.isFraction or {}
												table.insert(e.isFraction,2)
												e.options = e.options + 2
											else
												e.isFraction = e.isFraction or {}
												table.insert(e.isFraction,1)
												e.options = e.options + 1
											end
										end									
									end								
								end
							end
						end
					end
					if not e.isFraction then
						if s.cnt_answer then
							e.options = s.cnt_answer					
						elseif s.correct_answer and type(s.correct_answer)=='string' then
							local ans = json.decode(s.correct_answer)
							if ans and ans.answers and type(ans.answers)=='table' then
								e.options = #ans.answers
							else
								e.options = 1
							end
						else
							e.options = 1
						end
					end
					e.options = math.min(max_edit,e.options)
					e.answer = parse_answer( s )
					return true
				end,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					edit_topics(layout,data)
				end
			},
	[6] = {name='选择',img=res_root..'multiple_item.png',
				conv=multi_select_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					multi_select_init(layout,data)
				end
			},
	[7] = {name='横排序',img=res_root..'sort_item.png',
				conv=sort_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_sort,true)
				end
			},
	[8] = {name='竖排序',img=res_root..'sort_item.png',
				conv=sort_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_sort_V,false)
				end
			},
	[9] = {name='点图单选',img=res_root..'position_item.png',
				conv=click_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_click,false)
				end
			},
	[10] = {name='点图多选',img=res_root..'position_item.png',
				conv=click_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_click,true)
				end
			},
	[11] = {name='单拖放',img=res_root..'drag_item.png',
				conv=drag_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_drag,false)
				end
			},
	[12] = {name='多拖放',img=res_root..'drag_item.png',
				conv=drag_conv,
				init=function(layout,data)
					data.my_answer = data.my_answer or {}
					cache_done(layout,data,relayout_drag,true)
				end
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
	setEditChildTag = set_EditChildTag,
	setEditSpace = setEditSpace,
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,	
	get_scale = get_scale,
	set_scale = set_scale,
	get_default_scale = get_default_scale,
}
