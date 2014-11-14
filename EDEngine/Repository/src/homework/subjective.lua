local kits = require "kits"
local uikits = require "uikits"
local json = require "json-c"
local loadingbox = require "loadingbox"
local cache = require "cache"
local RecordVoice = require "recordvoice"
local messagebox_ = require "messagebox"
local login = require "login"

local ui = {
	FILE = 'homework/subjective.json',
	FILE_3_4 = 'homework/subjective43.json',
	BACK = 'milk_write/back',
	LIST = 'milk_write/state_view',
	ITEM_CURRENT = 'state_now',
	ITEM_FINISHED = 'state_past',
	ITEM_UNFINISHED = 'state_future',
	NEXT_BUTTON = 'next_problem', 
	FINISH_BUTTON = 'finish_5',
	TEACHER_VIEW = 'teacher_view',
	TOPICS_BG = 'teacher_view/Panel_36',
	TOPICS = 'teacher_view/Panel_36/homework_text',
	RECORD_BUTTON = 'write_view/white_3/recording',
	CAM_BUTTON = 'write_view/white_3/photograph',
	PHOTO_BUTTON = 'write_view/white_3/photo',
	
	WRITE_VIEW = 'write_view',
	WRITE_TEXT = 'write_view/write_text',
	TOPICS_PIC = 'teacher_view/tu1',
	TOPICS_VOICE = 'teacher_view/chat',
	TOPICS_VOICE_PLAY = 'chat',
	TOPICS_VOICE_TIME = 'chat_time',
	
	AUDIO_VIEW = 'chat_view',
	AUDIO_BUTTON = 'chat',
	AUDIO_TIME = 'chat_time',
	AUDIO_DELETE_BUTTON = 'delete',
	
	PICTURE_VIEW = 'picture_view',
	PICTURE_PIC = 'picture',
	PICTURE_DELETE_BUTTON = 'delete',
	
	ITEM_NUM = 'number',
	STATE_CURRENT = 1,
	STATE_FINISHED = 2,
	STATE_UNFINISHED = 3,	
	PAGE_VIEW = 'homework_view',
}
local cloud_answer_url = 'http://new.www.lejiaolexue.com/student/handler/WorkItem.ashx'
local Subjective = class("Subjective")
Subjective.__index = Subjective

local function stopSound()
	uikits.delay_call( nil,uikits.stopAllSound,1.5 )
end

local function messagebox(parent,title,text )
	messagebox_.open(parent,function()end,messagebox_.MESSAGE,tostring(title),tostring(text) )
end

function Subjective.create( args )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),Subjective)
	
	scene:addChild(layer)
	layer._args = args
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

function Subjective:clone_item( state )
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

function Subjective:init_delay_release()
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

function Subjective:set_item_state( i,ste )
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
		uikits.event(item,function(sender) 
		stopSound()
		self:set_current( index ) end,'click')
	end
end

function Subjective:calc_times( i )
	--计时
	if self._current then
		local layout = self._pageview:getPage(self._current)
		if layout and layout._times and layout._begin_time then
			layout._times = layout._times + (os.time()-layout._begin_time)
		end
	end
	if i then
		local layout = self._pageview:getPage(i)
		if layout then
			layout._times = layout._times or 0
			layout._begin_time = os.time()
		end
	end
end

function Subjective:set_current( i )
	if self._current ~= i then
		self:set_item_state( i,ui.STATE_CURRENT )
		if self._current then
				self:set_item_state(self._current,self._data[self._current].state)
		end
		self:calc_times( i )
		self._current = i
		local ps = self._pageview:getCurPageIndex()+1
		if ps ~= i then
			self._pageview:scrollToPage(i-1)
		end
		--self:set_anwser_field(i)
	end
end

function Subjective:add_item( t )
	t.state = t.state or ui.STATE_UNFINISHED
	local item = self:clone_item( t.state )
	if item then
		local n = uikits.child(item,ui.ITEM_NUM)
		n:setString( tostring(#self._list + 1) )
		self._list[#self._list+1] = item
		item:setVisible(true)
		self._scrollview:addChild(item)
		local index = #self._list
		uikits.event(item,function(sender) 
		stopSound()
		self:set_current( index ) end,'click')
		--add page
		local layout = self._scroll:clone()
		
		layout._item_id = t.item_id
		layout._times = 0
		layout._begin_time = os.time()
	
		layout:setVisible(true)
		local topics = uikits.child(layout,ui.TOPICS)
		topics:setString( t.content )
		
		local audio_view = uikits.child(layout,ui.AUDIO_VIEW)
		audio_view:setVisible(false)
		
		local picture_view = uikits.child(layout,ui.PICTURE_VIEW)
		picture_view:setVisible(false)
		
		local tpic = uikits.child(layout,ui.TOPICS_PIC)
		local tvoice = uikits.child(layout,ui.TOPICS_VOICE)
		
		local write_text = uikits.child(layout,ui.WRITE_TEXT)
		local org_text = uikits.child( self._scroll,ui.WRITE_TEXT)
		local holderText = org_text:getPlaceHolder()
		write_text:setPlaceHolder(holderText)
		if self._args.status == 10 or self._args.status == 11 then
			--已经提交，不修改
			write_text:setTouchAreaEnabled(false)
			write_text:setEnabled(false)
		end	
		tpic:setVisible(false)
		tvoice:setVisible(false)
		
		--add loading circle
		--load attachments
		local rtable = {}
		rtable.urls = {}
		if t.attachment then
			local atts = json.decode(t.attachment)
			if atts and atts.attachments then
				for i,v in pairs(atts.attachments) do
					if v.value then
						table.insert(rtable.urls,{url=v.value,filename=v.name})
					end
				end
			end
		end
		local n = 0
		self._pageview:addPage( layout )
		rtable.loading = loadingbox.circle(layout)
		cache.request_resources( rtable,
			function(rs,i,b)
				n = n + 1
				if b and rs.urls[i] then
					kits.log('download -> '..rs.urls[i].url )
					kits.log('cahce ->' ..rs.urls[i].filename)
					kits.log('file is '..tostring(kits.exist_cache(rs.urls[i].filename )))
				end
				if n >= #rs.urls then --complete
					if rs.loading and cc_isobj(rs.loading) then
						rs.loading:removeFromParent() 
					else
						return
					end
					--done
					self:relayout_topics( layout,rs.urls )
				end
			end)
	else
		kits.log( '	ERROR: clone_item() return nil' )
	end
end

function Subjective:relayout_topics( layout,urls )
	local layout_size = layout:getContentSize()
	local topics = uikits.child(layout,ui.TEACHER_VIEW)
	local topics_txtbg = uikits.child(layout,ui.TOPICS_BG)
	local topics_txt = uikits.child(layout,ui.TOPICS)
	local topics_pic = uikits.child(layout,ui.TOPICS_PIC)
	local topics_voice = uikits.child(layout,ui.TOPICS_VOICE)
	local topics_size = topics:getContentSize()
	local topics_txt_size = topics_txtbg:getContentSize()
	local topics_txt_x,topics_txt_y = topics_txtbg:getPosition()
	local topics_space = topics_size.height - (topics_txt_y+topics_txt_size.height)
	local topics_y = topics_space
	for i,v in pairs(urls) do
		if kits.exist_cache(v.filename) then
			local suffix = string.lower(string.sub(v.filename,-4))
			if suffix == '.amr' then
				local voice = topics_voice:clone()
				local voice_button = uikits.child(voice,ui.TOPICS_VOICE_PLAY)
				local voice_time = uikits.child(voice,ui.TOPICS_VOICE_TIME)
				local path = kits.get_cache_path()..v.filename
				local leng = cc_getVoiceLength( path )
				voice_time:setString( kits.time_to_string_simple(math.floor(leng)))
				
				uikits.event( voice_button,function(sender)
					uikits.playSound( path )
				end)
				voice:setPosition( topics_txt_x,topics_y )
				topics_y = topics_y + topics_space
				topics_y = topics_y + voice:getContentSize().height
				topics:addChild( voice )
				voice:setVisible(true)
			elseif suffix == '.jpg' or suffix == '.png' or suffix == '.gif' then
				local pic = topics_pic:clone()
				pic:loadTexture( v.filename )
				pic:setPosition( topics_txt_x,topics_y )
				topics_y = topics_y + topics_space
				topics_y = topics_y + pic:getContentSize().height				
				topics:addChild( pic )
				pic:setVisible(true)
			else
				kits.log("ERROR not support type "..v.filename )
			end
		end
	end
	topics_txtbg:setPosition( topics_txt_x,topics_y )
	topics_y = topics_y + 2*topics_space + topics_txt_size.height
	topics:setContentSize(cc.size(topics_size.width,topics_y))
	local move_y = topics_size.height - topics_y
	local write_view = uikits.child( layout,ui.WRITE_VIEW )
	local write_view_size = write_view:getContentSize()
	local mvs = {}
	table.insert(mvs,topics)
	table.insert(mvs,write_view)
	uikits.move(mvs,0,move_y)
	
	layout._topics = topics
	layout._writer = write_view
	layout._space = topics_space
	layout._size = layout_size
	layout._x = topics_txt_x
	
	--设置事件
	local next_button = uikits.child(layout,ui.NEXT_BUTTON)
	local finish_button = uikits.child(layout,ui.FINISH_BUTTON)
	uikits.event( next_button,function(sender)
		self:save()
		self:next_item()
	end)
	uikits.event( finish_button,function(sender)
	--保存
		self:save()
		uikits.popScene()
	end)	
	local record_button = uikits.child(layout,ui.RECORD_BUTTON)
	local cam_button = uikits.child(layout,ui.CAM_BUTTON)
	local pic_button = uikits.child(layout,ui.PHOTO_BUTTON)
	uikits.event( record_button,function(sender)
			if not (self._args.status == 10 or self._args.status == 11) then
				stopSound()
				RecordVoice.open(
						self,
						function(b,file)
							self._recording = nil
							if b then
								local tlen = cc_getVoiceLength(file)
								--messagebox( self,"add voice",tostring(file))
								self:add_voice( layout,file,tlen )
								self:relayout_myanswer( layout )
							end
						end
					)
			else
				messagebox(self,"提示","作业已经提交不能修改！")
			end
	end)
	uikits.event( cam_button,function(sender)
			if not (self._args.status == 10 or self._args.status == 11) then
				stopSound()
				cc_takeResource(TAKE_PICTURE,function(t,result,res)
						kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
						if result == RESULT_OK then
							--file = res
							local b,res = cc_adjustPhoto(res,1024)
							if b then
								--messagebox( self,"add photo",tostring(res))
								self:add_photo( layout,res )
								self:relayout_myanswer( layout )
							else
								messagebox(self,"错误","图像调整失败")
							end
						end
					end)
			else
				messagebox(self,"提示","作业已经提交不能修改！")
			end
	end)
	uikits.event( pic_button,function(sender)
			if not(self._args.status == 10 or self._args.status == 11) then
				stopSound()
				cc_takeResource(PICK_PICTURE,function(t,result,res)
						kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
						if result == RESULT_OK then
							local b,res = cc_adjustPhoto(res,1024)
							if b then
								--messagebox( self,"add picture",tostring(res))
								self:add_photo( layout,res )
								self:relayout_myanswer( layout )
							else
								messagebox(self,"错误","图像调整失败")
							end
						end					
					end)
			else
				messagebox(self,"提示","作业已经提交不能修改！")
			end
	end)
	
	self:relayout_myanswer(layout)
--	layout:setInnerContainerSize(cc.size(layout_size.width,topics_y + 2*topics_space +write_view_size.height ))
end

function Subjective:add_photo( layout,photo_file )
	local pic = uikits.child( layout,ui.PICTURE_VIEW):clone()
	local img = uikits.child( pic,ui.PICTURE_PIC )
	local del = uikits.child( pic,ui.PICTURE_DELETE_BUTTON )
	uikits.event( del,function(sender)
			if layout._list then
				local del_pos = nil
				for i,v in pairs(layout._list) do
					if v.item == pic then
						del_pos = i
						break
					end
				end
				if del_pos then
					table.remove(layout._list,del_pos)
				end
				uikits.delay_call( nil,function()
					pic:removeFromParent()
				end )
				self:relayout_myanswer( layout )
			end
		end)
	img:loadTexture( photo_file )
	local size = img:getContentSize()
	local del_size = del:getContentSize()
	del:setPosition(cc.p(size.width+3/2*del_size.width,size.height/2))
	if self._args.status == 10 or self._args.status == 11 then
		--已经提交，不删除
		del:setVisible(false)
	end
	local old = pic:getContentSize()
	pic:setContentSize(cc.size(old.width,size.height))
	layout:addChild(pic)
	layout._list = layout._list or {}
	table.insert(layout._list,{file=photo_file,item=pic})
end

function Subjective:add_voice( layout,voice_file,tlen )
	local voice = uikits.child( layout,ui.AUDIO_VIEW):clone()
	local play = uikits.child( voice,ui.AUDIO_BUTTON )
	local del = uikits.child( voice,ui.PICTURE_DELETE_BUTTON )
	local chat_time = uikits.child( voice,ui.AUDIO_TIME )
	chat_time:setString( kits.time_to_string_simple(math.floor(tlen)) )
	uikits.event( del,function(sender)
			stopSound()
			if layout._list then
				local del_pos = nil
				for i,v in pairs(layout._list) do
					if v.item == voice then
						del_pos = i
						break
					end
				end
				if del_pos then
					table.remove(layout._list,del_pos)
				end
				uikits.delay_call( nil,function()
					voice:removeFromParent()
				end )
				self:relayout_myanswer( layout )
			end
		end)
	if self._args.status == 10 or self._args.status == 11 then
		--已经提交，不删除
		del:setVisible(false)
	end		
	uikits.event( play,function(sender)
		stopSound()
		uikits.playSound(voice_file)
	end )
	layout:addChild(voice)
	layout._list = layout._list or {}
	table.insert(layout._list,{file=voice_file,item=voice})
end

function Subjective:relayout_myanswer( layout )
	if not layout._space then return end
	local next_button = uikits.child(layout,ui.NEXT_BUTTON)
	local finish_button = uikits.child(layout,ui.FINISH_BUTTON)
	local y = layout._space
	local but_size = next_button:getContentSize()
	next_button:setPosition( cc.p(layout._size.width/2,y+but_size.height/2) )
	finish_button:setPosition( cc.p(layout._size.width/2,y+but_size.height/2) )
	if layout._isdone then
		next_button:setVisible( false )
		finish_button:setVisible( true )	
	else
		next_button:setVisible( true )
		finish_button:setVisible( false )
	end
	y = y + but_size.height + layout._space
	--新加的item
	layout._list = layout._list or {}
	for i,v in pairs( layout._list ) do
		if v.item then
			 v.item:setPosition( cc.p(layout._x,y) )
			 v.item:setVisible( true )
			y = y +  v.item:getContentSize().height + layout._space
		end
	end
	layout._writer:setPosition( cc.p(layout._x,y) )
	y = y + layout._writer:getContentSize().height + layout._space
	layout._topics:setPosition( cc.p(layout._x,y) )
	y = y + layout._topics:getContentSize().height + layout._space
	layout:setInnerContainerSize(cc.size(layout._size.width,y))
end

function Subjective:relayout()
	if self._scrollview and #self._list > 0 then
		self._scrollview:setInnerContainerSize(cc.size(self._item_size.width*(#self._list+1),self._item_size.height))
		for i,v in ipairs(self._list) do
			v:setPosition(cc.p(i*self._item_size.width,self._item_y))
		end
	end
end

function Subjective:next_item()
	if self._current and self._current < #self._list then
		stopSound()
		self:set_current( self._current+1 )
	end
end

function Subjective:save()
	if self._args.status == 10 or self._args.status == 11 then
		--已经提交，不存储
		return
	end
	if self._args and self._args.exam_id then
		self:calc_times() --计算当前时间
		local file = self._args.exam_id..login.uid()..'.custom'
		local t = {}
		for i,layout in pairs(self._pageview:getPages()) do
			local p = {}
			p.item_id = layout._item_id
			p.text = uikits.child(layout,ui.WRITE_TEXT ):getStringValue()
			p.attachments = {}
			if layout._list then
				for k,v in pairs(layout._list) do
					table.insert(p.attachments,{filename=v.file} )
				end
			end
			--table.insert(t,p)
			t[p.item_id] = p
		end
		local str = json.encode( t )
		kits.write_cache( file,str )
	end
end

function Subjective:load_myanswer_from_table( t )
	local pages = self._pageview:getPages()
	if pages and t then
		for i,layout in pairs(pages) do
			if t[layout._item_id] then
				local item = t[layout._item_id]
				layout._times = item.times or 0
				layout._begin_time = os.time()
				uikits.child(layout,ui.WRITE_TEXT ):setText( item.text or '' )
				for k,v in pairs(item.attachments) do
					local suffix = string.lower(string.sub(v.filename,-4))
					if suffix == '.png' or suffix == '.jpg' or suffix == '.gif' then
						self:add_photo( layout,v.filename )
					elseif suffix == '.amr' then
						local tlen = cc_getVoiceLength( v.filename )
						self:add_voice( layout,v.filename,tlen )
					else
						kits.log("ERROR not support meida type "..tostring(suffix))
					end
				end
			else
				kits.log("ERROR load_myanswer_from_table t[i] = nil or layout._item_id == t[i].item_id")
			end
			self:relayout_myanswer(layout)
		end
	else
		kits.log("ERROR load_myanswer_from_table pages = nil or t = nil")
	end
end

function Subjective:load_from_cloud()
	local function download_resources( rsts,cloud_answer )
		local n = 0
		local loadbox = loadingbox.open(self)
		local r,msg = cache.request_resources( rsts,function(rs,i,b)
			n = n+1
			if n >= #rs.urls then
				--全部下载完成
				if not loadbox:removeFromParent() then
					return
				end
				self:load_myanswer_from_table( cloud_answer )
			end
		end)
		if not r then
			kits.log(msg)
		end
	end
	
	if self._args.status == 10 or self._args.status == 11 then
		if self._data then
			local total_count = 0
			local count = 0
			local urls = {}
			local rsts = {}
			rsts.urls = {}
			local tryagin = true
			local cloud_answer = {}
			for i,v in ipairs(self._data) do
				if v.item_type == 93 then
					local form = 'examId='..tostring(self._args.exam_id)
					..'&itemId='..tostring(v.item_id)
					..'&teacherId='..tostring(self._args.tid)
					local url = cloud_answer_url..'?'..form
					table.insert(urls,url)
					total_count = total_count + 1
				end
			end
			if total_count > 0 then
				local loadbox = loadingbox.open(self)
				for i,v in pairs(urls) do
					cache.request_json(v,function(t)
							if t and t.detail then --答案数据
								local answer = t.detail
								local p = {}
								if answer.answer then
									local t = json.decode(answer.answer)
									if t and type(t)=='table' and t.answers and type(t.answers)=='table' then
										if t.answers[1] then
											p.text = tostring( t.answers[1].content)
										end
									end
								end
								p.item_id = answer.item_id
								p.attachments = {}
								if answer.val_attach then
									local attach = json.decode(answer.val_attach)
									if attach and attach.attachments then
										for k,v in pairs(attach.attachments) do
											if v.value and v.name then
												table.insert(p.attachments,{filename=v.name,url=v.value})
												table.insert(rsts.urls,{url=v.value,filename=v.name})
											else
												kits.log("ERROR attachments value = nil or name = nil")
											end
										end
									end
								end
								--table.insert(cloud_answer,p)
								cloud_answer[p.item_id] = p
							else
								--下载失败
								if not tryagin then return end
								tryagin = false
								messagebox_.open(self,function(e)
									if e == messagebox_.TRY then									
										cache.request_cancel()
										self:load_from_cloud()
										tryagin = false
									end
								end,messagebox_.RETRY,"下载主观题答案是出错","是否重试?")								
							end
							if tryagin then
								count = count + 1
								if count == total_count then
									--全部做完
									if not loadbox:removeFromParent() then
										return
									end
									local str = json.encode( cloud_answer )
									local file = self._args.exam_id..login.uid()..'.custom'
									if tryagin then --没有出错
										kits.write_cache( file,str )
									
										--下载全部附件
										download_resources( rsts,cloud_answer )							
									end
								end
							end
						end)
				end
			end
		end
	end
end

function Subjective:load_myanswer()
	if self._args and self._args.exam_id then
		local file = self._args.exam_id..login.uid()..'.custom'
		local str = kits.read_cache( file )
		if str then
			local t = json.decode( str )
			if t then
				self:load_myanswer_from_table( t )
				return
			end
		end
	end
	self:load_from_cloud()
end

function Subjective:init()
	self:init_gui()
	self:init_delay_release()
	self:init_data()
end

local loadpaper_url = "http://new.www.lejiaolexue.com/paper/handler/LoadPaperItem.ashx"
local loadextam_url = "http://new.www.lejiaolexue.com/student/handler/GetStudentItemList.ashx"

function Subjective:init_data()
	if self._args then
		local url_topics
		if self._args.exam_id then
			--取作业
			url_topics = loadextam_url..'?examId='..self._args.exam_id..'&teacherId='..self._args.tid
			--取得以前做的答案
			--self._topics_table = topics.read( self._args.exam_id ) or {}
		elseif self._args.pid then
			--取卷面
			url_topics = loadpaper_url..'?pid='..self._args.pid..'&uid='..self._args.uid
			--取得以前做的答案
			--self._topics_table = topics.read( self._args.pid ) or {}
		else
			--self._topics_table = {}
			kits.log('error : Subjective:init_data exam_id=nil and pid=nil')
			return
		end
		kits.log('Subjective:init_data request :'..url_topics )
		local loadbox = loadingbox.open(self)
		cache.request_json( url_topics,function(t)
				loadbox:removeFromParent()
				if t then
					self:load_subjective_from_table(t)
					self:load_myanswer()
				else
					kits.log('ERROR Subjective:init_data request failed')
				end			
		end)
	else
		local res = kits.read_cache('sujective.json')
		if res then
			local t = json.decode(res)
			if t and type(t)=='table' then
				for i,v in pairs(t) do
					print( v.topics )
				end
				self._data = t
			end
		end
		kits.log('载入模拟数据..')
	end
end

function Subjective:load_subjective_from_table(data)
	if data then
		local ds
		if data.item and type(data.item)=='table' then
			ds = data.item
		else
			ds = data
		end
		self._data = ds --保存副本
		for i,v in ipairs(ds) do
			if v.item_type==93 then --自定义题
				self:add_item( v )
			end
		end	
		self:set_current(1)
		self:relayout()
	end
end

function Subjective:scroll_relayout()
	--计算高度
	local uis = {}
	local ts = self._tops:getContentSize()
	local cs = self._scroll:getContentSize()
	local ds = {height=0,width=0}--self._delete_button:getContentSize()
	local x,y = 0,0 --self._delete_button:getPosition()
	y = self._space
	--self._delete_button:setPosition(cc.p(x,y))
	y = y + ds.height + self._space
	for i,v in pairs(self._items) do
		if v:isVisible() then
			local xx,yy = v:getPosition()
			v:setPosition( cc.p(xx,y) )
			y = y + v:getContentSize().height*v:getScaleY() + self._space
			table.insert(uis,v)
		end
	end
	local xx,yy = self._tops:getPosition()
	self._tops:setPosition(cc.p(xx,y))
	y = y + ts.height + self._space
	self._scroll:setInnerContainerSize(cc.size(cs.width,y))
	table.insert(uis,self._tops)
	--table.insert(uis,self._delete_button)
	if y < cs.height then
		uikits.move( uis,0,cs.height-y)
	end
end

function Subjective:relayout_tops()
end

function Subjective:init_gui()
	if not self._root then
		self._list = {}
		self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
		local back = uikits.child(self._root,ui.BACK)
		uikits.event(back,
			function(sender)
				stopSound()
				self:save()
				uikits.popScene()
			end)
		self:addChild(self._root)
		
		self._scrollview = uikits.child(self._root,ui.LIST) --index list
		self._scroll = uikits.child(self._root,ui.PAGE_VIEW)
		self._scroll_size = self._scroll:getContentSize()
		
		self._tops = uikits.child(self._scroll,ui.TEACHER_VIEW)
		local cs = self._scroll:getContentSize()
		local ts = self._tops:getContentSize()
		local tx,ty = self._tops:getPosition()
		self._space = cs.height-ty-ts.height
		--self._input_text = uikits.child(self._tops,ui.INPUT_TEXT)
		local x,y = self._tops:getPosition()
		self._tops_space = y-self._tops:getContentSize().height
		self._tops_ox = x
	
		self._record_button = uikits.child(self._tops,ui.RECORD_BUTTON)
		self._cam_button = uikits.child(self._tops,ui.CAM_BUTTON)
		self._photo_button = uikits.child(self._tops,ui.PHOTO_BUTTON)

		self._audio_item = uikits.child(self._scroll,ui.AUDIO_VIEW)
		self._img_item = uikits.child(self._scroll,ui.PICTURE_VIEW)
		self._audio_item:setVisible(false)
		self._img_item:setVisible(false)
		self._scroll_list = {}
		self._items = {}
		self._remove_items = {}
		
		local x_,y_ = self._scroll:getPosition()
		local anp = self._scroll:getAnchorPoint()
		self._pageview = uikits.pageview{
			bgcolor=self._root:getBackGroundColor(),
			x = x_,
			y = y_,
			anchorX = anp.x,
			anchorY = anp.y,
			width=self._scroll_size.width,
			height=self._scroll_size.height}	
		self._scroll:setVisible(false)
		self._root:addChild( self._pageview )
		uikits.event(self._pageview,
			function(sender,eventType)
				if eventType == ccui.PageViewEventType.turning then
					local i = sender:getCurPageIndex()
					stopSound()
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
				
		local x
		x,self._item_y = self._item_current:getPosition()			
		---装入数据
		if self._data then
			for i,v in pairs(self._data) do
				self:add_item( v )
			end
			stopSound()
			self:set_current(1)
			self:relayout()
		end
	end
end

function Subjective:release()
	if self._scID then
		self:getScheduler():unscheduleScriptEntry(self._scID)
		self._scID = nil
	end
end

return Subjective