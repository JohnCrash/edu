local crash = require "crash"
local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"
local Sethwbyles = require "homework/sethwbyles"
local Sethwbyerr = require "homework/sethwbyerr"
local Edithwbyobj = require "homework/edithwbyobj"
local Publishhw = require "homework/publishhw"

local topics_course = topics.course_icon
local res_local = "homework/"
local subjectiveedit = require "homework/subjectiveedit"

crash.open("teacher",1)
local course_icon = topics.course_icon
local ui = {
	FILE = 'homework/laoshizuoye/daiyue.json',
	FILE_3_4 = 'homework/laoshizuoye/daiyue43.json',
	MORE = 'homework/laoshizuoye/gengduo.json',
	MORE_3_4 = 'homework/laoshizuoye/gengduo43.json',	
	RELEASEPAGE = 'homework/laoshizuoye/buzhi.json',
	RELEASE_3_4 = 'homework/laoshizuoye/buzhi43.json',
	STATISTICS_FILE = 'homework/laoshizuoye/tongji.json',
	STATISTICS_FILE_3_4 = 'homework/laoshizuoye/tongji43.json',
	LESSON_LIST = 'lr1',
	LESSON = 'lesson',
	CLASSLIST = 'banji',
	CLASS_BUTTON = 'ban1',
	CLASS_NAME = 'banji',
	MORE_VIEW = 'more_view',
	MORE_SOUND = 'sound',
	BACK = 'ding/back',
	LIST = 'zuo',
	ITEM = 'zuoye1',
	ITEM_CLASS = 'banji',
	ITEM_CAPTION = 'kewen',
	ITEM_TOPICS_NUM = 'zhuguan',
	ITEM_SUBJECTIVE_NUM = 'keguan',
	ITEM_COMMIT_NUM = 'renshu',
	ITEM_COMMIT_PERCENT = 'jin/jindu',
	ITEM_ICON = 'kemu',
	ITEM_CLOSE_TIME = 'jieshushijian',
	BUTTON_LINE = 'ding/redline',
	TAB_BUTTON_1 = 'ding/daiyue',
	TAB_BUTTON_2 = 'ding/buzhi',
	TAB_BUTTON_3 = 'ding/lishi',
	TAB_BUTTON_4 = 'ding/tongji',
	TAB_BUTTON_5 = 'ding/more',
	READYBATCH = 1,
	RELEASE = 2,
	HISTORY = 3,
	STATIST = 4,
	SETTING = 5,
	TOPICS_SELECT = 'ys2',
	TOPICS_SELECT_BUTTON = 'xuanze',
	TOPICS_SELECT_UI = 'xuan',
	TOPICS_SELECT_COURSE = 'xuan/kemu',
	TOPICS_SELECT_COURSE_ITEM = 'yuwen',
	TOPICS_SELECT_VERSION = 'xuan/banben',
	TOPICS_SELECT_VERSION_ITEM = 'bb1',
	TOPICS_SELECT_VOLUME = 'xuan/nianji',
	TOPICS_SELECT_VOLUME_ITEM = 'nj1',
	TOPICS_SELECT_UNIT = 'xuan/danyuan',
	TOPICS_SELECT_UNIT_ITEM = 'dy1',
	TOPICS_SELECT_SECTION = 'xuan/kewen', 
	TOPICS_SET_HOMEWORK_TITLE = 'ys1',
	TOPICS_SET_HOMEWORK_XIUGAI = 'ys1/xiugai',
	TOPICS_SELECT_QUEREN = 'ys2/qr',
	TOPICS_SET_BUTTON_BY_LES = 'xuanze/zz',
	TOPICS_SET_BUTTON_BY_ERR = 'xuanze/ct',
	TOPICS_SET_LABEL_BY_ERR = 'xuanze/wen5',
	TOPICS_SET_LABEL_EMPTY = 'xuanze/wen1',
	TOPICS_EDIT_HOMEWORK_VIEW = 'zuoye',
	TOPICS_EDIT_HOMEWORK_KEGUAN = 'zuoye/keguang',
	TOPICS_EDIT_OBJ_NUM = 'zuoye/keguang/shul',
	TOPICS_EDIT_OBJ_BUT = 'zuoye/keguang/bianji',
	TOPICS_EDIT_OBJ_PIC = 'zuoye/keguang/ti1',
	TOPICS_EDIT_PUBLISH_BUT = 'zuoye/fabu',
	TOPICS_SELECT_SECTION_ITEM = 'ke1', 
	TOPICS_LVL_CHECKBOX1 = 'xuan/xia',
	TOPICS_LVL_CHECKBOX2 = 'xuan/xia2',
	TOPICS_LVL_CHECKBOX3 = 'xuan/xia3',
	TOPICS_LVL_CHECKBOX4 = 'xuan/xia4',
	SUBJECTIVE_EDIT_BUTTON = 'xuanze/gx',
	SUBJECTIVE_EDIT_BUTTON2 = 'zuoye/zhuguang/bianji', 
	SUBJECTIVE_EDIT_NUMBER = 'zuoye/zhuguang/shul',
	TOPICS_SELECT_TITLE_COURSE = 'ys1/kemu',
	TOPICS_SELECT_TITLE_BV = 'ys1/banben',
	TOPICS_SELECT_TITLE_VOL = 'ys1/nianji',
	TOPICS_SELECT_TITLE_UNIT = 'ys1/danyuan',
	TOPICS_SELECT_TITLE_SECTION = 'ys1/kewen',

	
	ST_CAPTION = 'lesson1/text1',
	ST_T_C = 'lesson1/text3',
	ST_T_A = 'lesson1/text5',
	ST_T_T = 'lesson1/text7',	
	ST_SCROLLVIEW = 'lesson_view',
	ST_MONTH = 'month',
	ST_DATE = 'years',
	ST_COUNT = 'text6',
	ST_AVERAGE='text2',
	ST_TIME='text4',
--	ST_COUNT_BAR='number_bar',
--	ST_AVERAGE_BAR='average_bar',
--	ST_TIME_BAR='time_bar',
	ST_COUNT_TEXT='text_no',
	ST_AVERAGE_TEXT='text_av',
	ST_TIME_TEXT='text_ti',	
}

local is_need_update

local exam_list_url="http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx"
local get_class_url = "http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx"

local TeacherList = class("TeacherList")
TeacherList.__index = TeacherList

function TeacherList.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TeacherList)
	is_need_update = true
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

function TeacherList:add_batch_item( v )
	if v and type(v)=='table' then
		local item = self._scrollview:additem{
			[ui.ITEM_CAPTION] = v.exam_name,
			[ui.ITEM_TOPICS_NUM] = v.items or '-',
			[ui.ITEM_COMMIT_NUM] = v.commit_num or '-',
			[ui.ITEM_CLOSE_TIME] = function(child,item)
				if v.finish_time and type(v.finish_time)=='string' then
					local end_time = kits.unix_date_by_string( v.finish_time )
					local dt = end_time - os.time()
					if dt > 0 then
						child:setString( kits.time_to_string_simple(dt) )
					else
						child:setString('已过')
					end
				end
			end,
			[ui.ITEM_CLASS] = function(child,item)
				child:setString('Loading...')
				if v.exam_id and type(v.exam_id)=='string' then
					local url = get_class_url..'?action=brief&examid='..
					v.exam_id
					cache.request_json(url,function(class)
						if class and type(class)=='table' and class[1] and class[1].class_name then
							child:setString( class[1].class_name )
							uikits.event(item,function(sender)
								uikits.pushScene(TeacherBatch.create(v,class[1]))
							end,'click')
							return
						end
					end)
				end
			end,
			[ui.ITEM_ICON] = function(child,item)
				if v and v.course and topics_course and topics_course[v.course] then
					child:loadTexture(res_local..topics_course[v.course].logo)
					--uikits.fitsize(child,280,280)
				end
			end
		}
	else
		kits.log('ERROR TeacherList:add_batch_item vailed v')
	end
end

function TeacherList:add_ready_batch_from_table( t )
	if t and t.page and type(t.page)=='table' then
		for k,v in pairs(t.page) do
			self:add_batch_item( v )
		end
		self._scrollview:relayout()
		return true
	else
		kits.log('ERROR TeacherList:init_ready_batch_from_data decode failed')
	end
end

function TeacherList:init_batch_list( status )
	local loadbox = loadingbox.open(self)
	local total_page = 1
	function down_page( page )
		local url = exam_list_url..'?'..'action=search'..
			'&exam-type=0'.. --全部
			'&exam-status='..status.. 
			'&exam-tag=0'..
			'&in-time=0'..
			'&sort=0'..
			'&page='..page
		cache.request_json(url,
			function(t)
				if t and t.total_page then 
					total_page = t.total_page
					if self and self.add_ready_batch_from_table then
						local retb = self:add_ready_batch_from_table(t)
						if page<total_page and retb then
							down_page( page+1 )
						else
							self._busy =false
							loadbox:removeFromParent()
						end
					end
				else
					self._busy =false
					loadbox:removeFromParent()
				end				
			end)
	end
	down_page(1)
end

--待阅
function TeacherList:init_ready_batch()
	cache.request_cancel()
	
	self._scrollview:setVisible(true)
	self._setting:setVisible(false)
	self._release:setVisible(false)
	self._statistics_root:setVisible(false)
	if not self._scID and not self._busy then
		self._mode = ui.READYBATCH
		self._scrollview:clear()
		self._busy = true
		self:init_batch_list(2)--待批阅
	end
	return true
end

--布置
function TeacherList:init_ready_release()
	cache.request_cancel()
	self._scrollview:setVisible(false)
	self._release:setVisible(true)
	self._setting:setVisible(false)
	self._statistics_root:setVisible(false)

	if self._selector == nil then
		self._confirm_item = {}	
		local but_queren = uikits.child(self._release,ui.TOPICS_SELECT_QUEREN)
		but_queren:setEnabled(false)
		but_queren:setBright(false)
		but_queren:setTouchEnabled(false)
		self:set_homework_ui(1)
		self:release_select_list()			
	end
	return true
end
--历史
function TeacherList:init_ready_history()
	cache.request_cancel()
	
	self._scrollview:setVisible(true)
	self._setting:setVisible(false)
	self._release:setVisible(false)
	self._statistics_root:setVisible(false)
	self._scrollview:clear()
	if not self._scID and not self._busy then
		self._mode = ui.HISTORY
		self._busy = true
		self:init_batch_list(3)--完成批阅
	end
	return true
end

function TeacherList:clone_statistics_item(v)
	self._statistics_item:setVisible(false)
	local item = self._statistics_item:clone()
	
	if item then
		item:setVisible(true)
		if v.course and course_icon[v.course] then
			uikits.child(item,ui.ST_CAPTION):setString(course_icon[v.course].name )
		end
		uikits.child(item,ui.ST_T_C):setString(tostring(v.t_count))
		if v.t_score and v.t_score>0 then
			uikits.child(item,ui.ST_T_A):setString(tostring(v.t_score))
		else
			uikits.child(item,ui.ST_T_A):setString('-')
		end
		uikits.child(item,ui.ST_T_T):setString(tostring(v.t_times))
		local scrollview = uikits.child(item,ui.ST_SCROLLVIEW)
		local idx = 1
		local sitem
		local list = {}
		local size
		local ox,oy
		if v.pm and type(v.pm)=='table' then
			for i,t in pairs(v.pm) do
				if t and t.date then
					if idx == 1 then
						sitem = uikits.child(scrollview,ui.ST_MONTH)
						size = sitem:getContentSize()
						ox,oy = sitem:getPosition()
					else
						sitem = uikits.child(scrollview,ui.ST_MONTH):clone()
						scrollview:addChild(sitem)
					end
					--次数
					local ct = uikits.child(sitem,ui.ST_COUNT)
					ct:setString(tostring(t.count))
					--平均分
					local av = uikits.child(sitem,ui.ST_AVERAGE)
					if t.scroe then
						local num = tonumber(t.scroe)
						if num then
							local sv = math.floor(num*100)
							av:setString(tostring(sv)..'%')
						else
							av:setString('-')
						end
					end
					--用时
					local ti = uikits.child(sitem,ui.ST_TIME)
					ti:setString(tostring(t.time))
					
					table.insert(list,sitem)
					uikits.child(sitem,ui.ST_DATE):setString(t.date)
					idx = idx + 1
				end
			end
			--排列
			scrollview:setInnerContainerSize(cc.size(size.width*#list,size.height))
			for i,t in pairs(list) do
				t:setPosition(cc.p(ox+size.width*(i-1),oy))
			end
		end
		item:setVisible(true)
		self._statistics_view:addChild(item)
		self._statistics_list = self._statistics_list or {}
		table.insert(self._statistics_list,item)
	end
	return item
end

function TeacherList:date_conv(d)
	if d and type(d)=='string' and string.len(d)==6 then
		if string.sub(d,5,5)~='0' then
			return string.sub(d,1,4)..'年'..string.sub(d,-2)..'月'
		else
			return string.sub(d,1,4)..'年'..string.sub(d,-1)..'月'
		end
	else
		return tostring(d)
	end
end
local function minsec(t)
	local mins = math.floor(t/60)
	local sec = t - mins*60
	local result = ''
	if mins ~= 0 then
		result = result..mins..'分'
	end
	if sec ~= 0 then
		result = result..sec..'秒'
	end
	if result == '' then
		result = '-'
	end
	return result
end
function TeacherList:statistics_data(t)
	local idx = {}
	for i,v in pairs(t) do
		idx[v.course] = idx[v.course] or {}
		idx[v.course].course = v.course
		if not idx[v.course].t_times then
			idx[v.course].t_times = 0
		end
		idx[v.course].t_times = idx[v.course].t_times + v.cnt_times
		if not idx[v.course].t_count then
			idx[v.course].t_count = 0
		end
		idx[v.course].t_count = idx[v.course].t_count + v.cnt_home_work
		if not idx[v.course].t_score then
			idx[v.course].t_score = 0
		end		
		idx[v.course].t_score = idx[v.course].t_score + 0--v.success_percent
		idx[v.course].pm = idx[v.course].pm or {}
		local score
		if v.cnt_right and v.cnt_wrong then
			local total = v.cnt_wrong+v.cnt_right
			if total > 0 then
				score = v.cnt_right/total
			else
				kits.log('WARNING : statistics_data total ='..total)
			end
		end
		if score and score == -1 then
			score = '-'
		elseif not score then
			score = '-'
		end
		table.insert(idx[v.course].pm,1,
		{
			date=self:date_conv(v.year_month),
			count = v.cnt_home_work,
			time = minsec(v.cnt_times),
			scroe = tostring(score),
		})
	end
	local result = {}
	local i = 1
	for k,v in pairs(idx) do
		if v.pm and type(v.pm)=='table' and #v.pm>0 then
			v.t_score = v.t_score/#v.pm
			v.t_times = minsec(v.t_times/#v.pm)
		end
		result[i] = v
		i = i + 1
	end
	return result
end

function TeacherList:class_statistics( cls )
	local url = 'http://new.www.lejiaolexue.com/paper/handler/GetStatisticsTeacher.ashx?c_id='..tostring(cls)
	local loadbox = loadingbox.open(self)
	cache.request_json(url,function(t)
		self._statistics_root:setVisible(true)
		if not loadbox:removeFromParent() then
			return
		end

		if t and type(t)=='table' then
			self._statistics_data = TeacherList:statistics_data(t)
			for i,v in pairs(self._statistics_data) do
				self:clone_statistics_item(v)
			end				
			self:relayout_statistics()			
		end
	end)
end
--统计
function TeacherList:init_ready_statistics()
	cache.request_cancel()
	
	self._scrollview:setVisible(false)
	self._setting:setVisible(false)
	self._release:setVisible(false)
	self._statistics_root:setVisible(false)
	self:show_statistics(true)	
	if not self._statistics_data then
		local url = 'http://api.lejiaolexue.com/rest/user/'..login.uid()..'/zone/class'
		local loadbox = loadingbox.open(self)
		cache.request_json(url,function(t)
			if not loadbox:removeFromParent() then
				return
			end
			if t and type(t)=='table' and t.result==0 and t.zone then
				local first_id
				local checks = {}
				for i,v in pairs(t.zone) do
					local item = self._classview:additem{[ui.CLASS_NAME] = v.zone_name}
					uikits.event(item,function(sender,b)
						self:clear_statistics()
						for k,it in pairs(checks) do
							it:setSelectedState(false)
						end
						sender:setSelectedState(true)
						self:class_statistics(v.zone_id)
					end)
					if not first_id then
						first_id = v.zone_id
						item:setSelectedState(true)
					end
					table.insert(checks,item)
				end
				self._classview:relayout()
				self:clear_statistics()
				self:class_statistics(first_id)
			else
				kits.log('ERROR TeacherList:init_ready_statistics invalid request result')
			end
		end)
	else
		self._statistics_root:setVisible(true)
	end
	return true
end

function TeacherList:show_statistics(b)
	if self._statistics_list then
		for i,v in pairs(self._statistics_list) do
			v:setVisible(b)
		end
	end
end

function TeacherList:relayout_statistics()
	if self._statistics_list then
		local height = self._statistics_item_height*(#self._statistics_list)
		self._statistics_view:setInnerContainerSize(cc.size(self._statistics_item_width,height))
		local offy = 0
		local size = self._statistics_view:getContentSize()
		if height < size.height then
			offy = size.height - height --顶到顶
		end

		for i = 1,#self._statistics_list do
			self._statistics_list[#self._statistics_list-i+1]:setPosition(cc.p(self._statistics_item_ox,self._statistics_item_height*(i-1)+offy))
		end
	end
end

function TeacherList:clear_statistics()
	self._statistics_item:setVisible(false)
	if self._statistics_list then
		for i ,v in pairs(self._statistics_list) do
			if v then
				v:removeFromParent()
			end
		end
		self._statistics_list = {}
	end
end
--设置
function TeacherList:init_ready_setting()
	cache.request_cancel()
	
	self._scrollview:setVisible(false)
	self._setting:setVisible(true)
	self._release:setVisible(false)
	self._statistics_root:setVisible(false)
	return true
end

function TeacherList:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	
	--设置页
	self._setting_root = uikits.fromJson{file_9_16=ui.MORE,file_3_4=ui.MORE_3_4}
	self._setting = uikits.child(self._setting_root,ui.MORE_VIEW):clone()
	local cs = uikits.child(self._setting,ui.MORE_SOUND)
	if cs then
		cs:setSelectedState (kits.config("mute","get"))
		uikits.event(cs,function(sender,b)
			kits.config("mute",b)
			uikits.muteSound(b)
		end)
	end
	self._root:addChild(self._setting)
	
	self._statistics_root = uikits.fromJson{file_9_16=ui.STATISTICS_FILE,file_3_4=ui.STATISTICS_FILE_3_4}
	self:addChild(self._statistics_root)
	self._statistics_view = uikits.child(self._statistics_root,ui.LESSON_LIST)
	self._statistics_root:setVisible(false)
	--self._statistics_view:setVisible(false)
	local statistics_item = uikits.child(self._statistics_view,ui.LESSON)
	self._statistics_item = statistics_item
	if statistics_item then
		size = statistics_item:getContentSize()
		self._statistics_item_width = size.width
		self._statistics_item_height = size.height
		self._statistics_item_ox,self._statistics_item_oy = statistics_item:getPosition()
	end
	self._classview = uikits.scroll(self._statistics_root,ui.CLASSLIST,ui.CLASS_BUTTON,true,16)
	--发布页
	self._release = uikits.fromJson{file_9_16=ui.RELEASEPAGE,file_3_4=ui.RELEASE_3_4}
	self._root:addChild(self._release)
	--选择科目
	self._cousor = uikits.scroll(self._release,ui.TOPICS_SELECT_COURSE,ui.TOPICS_SELECT_COURSE_ITEM,true)

	--选择版本
	self._version = uikits.scroll(self._release,ui.TOPICS_SELECT_VERSION,ui.TOPICS_SELECT_VERSION_ITEM,true)

	--选择章
	self._volume = uikits.scroll(self._release,ui.TOPICS_SELECT_VOLUME,ui.TOPICS_SELECT_VOLUME_ITEM,true)

	--选择单元
	self._unit = uikits.scroll(self._release,ui.TOPICS_SELECT_UNIT,ui.TOPICS_SELECT_UNIT_ITEM,true)

	--选择
	self._section = uikits.scroll(self._release,ui.TOPICS_SELECT_SECTION,ui.TOPICS_SELECT_SECTION_ITEM,true)
	self._check = {}
	self._check[1] = uikits.child(self._release,ui.TOPICS_LVL_CHECKBOX1)
	self._check[2] = uikits.child(self._release,ui.TOPICS_LVL_CHECKBOX2)
	self._check[3] = uikits.child(self._release,ui.TOPICS_LVL_CHECKBOX3)
	self._check[4] = uikits.child(self._release,ui.TOPICS_LVL_CHECKBOX4)
	
	self._subjective_button = uikits.child(self._release,ui.SUBJECTIVE_EDIT_BUTTON)
	uikits.event(self._subjective_button,function(sender)
			self._issubjectiveedit = true
			self._subjective_data = self._subjective_data or {}
			uikits.pushScene( subjectiveedit.create(self._subjective_data) )
		end
	)
	local subjective_button = uikits.child(self._release,ui.SUBJECTIVE_EDIT_BUTTON2)
	uikits.event(subjective_button,function(sender)
			self._issubjectiveedit = true
			self._subjective_data = self._subjective_data or {}
			uikits.pushScene( subjectiveedit.create(self._subjective_data) )
		end
	)
	--返回按钮
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)
		cache.request_cancel()
		uikits.popScene()end)
	--列表视图
	self._scrollview = uikits.scroll(self._root,ui.LIST,ui.ITEM)
	--切换标签
	self._tab = uikits.tab(self._root,ui.BUTTON_LINE,
		{[ui.TAB_BUTTON_1]=function(sender) return self:init_ready_batch()end,
		[ui.TAB_BUTTON_2]=function(sender) return self:init_ready_release()end,
		[ui.TAB_BUTTON_3]=function(sender) return self:init_ready_history()end,
		[ui.TAB_BUTTON_4]=function(sender) return self:init_ready_statistics()end,
		[ui.TAB_BUTTON_5]=function(sender) return self:init_ready_setting() end,
		})
end
local selevel = {
	'course',
	'book_version',
	'vol',
	'unit',
	'section',
}
local uilevel = {
	ui.TOPICS_SELECT_COURSE,
	ui.TOPICS_SELECT_VERSION,
	ui.TOPICS_SELECT_VOLUME,
	ui.TOPICS_SELECT_VOLUME,
	ui.TOPICS_SELECT_UNIT,
	ui.TOPICS_SELECT_SECTION,
}
local courseimg = {
	[101]="zhonghe",
	[10001]="chinese",
	[10002]="math",
	[10003]="english",
	[10005]="english",
	[10009]="info",
	[10010]="science",
	[10011]="science",
	[11005]="english",
	[20001]="chinese",
	[20002]="math",
	[20003]="english",
	[20004]="physics",
	[20005]="chemistry",
	[20006]="politics",
	[20007]="organisms",
	[20008]="geography",
	[20009]="history",
	[30001]="chinese",
	[30002]="math",
	[30003]="english",
	[30004]="physics",
	[30005]="chemistry",
	[30006]="politics",
	[30007]="organisms",
	[30008]="geography",
	[30009]="history",	
}
function TeacherList:add_level_item( level,v )
	local scroll
	if level == 1 then
		local item = self._cousor:additem()
		if item then
			local n = courseimg[v.id]
			if n then
				item:loadTextureBackGround('homework/laoshizuoye/'..n..'_off.png')
				item:loadTextureFrontCross('homework/laoshizuoye/'..n..'_on.png')
				item:loadTextureBackGroundSelected('homework/laoshizuoye/'..n..'_on.png')
			else
				kits.log('ERROR TeacherList:add_level_item unkown type')
			end
			uikits.event(item,function(sender,b)
				self._selector[level] = v
				self:level_reset(level,sender)
				for i = level+2,5 do
					self:level_clear(i)
				end				
				self:release_select_list( level + 1 )
				local but_queren = uikits.child(self._release,ui.TOPICS_SELECT_QUEREN)
				but_queren:setEnabled(true)
				but_queren:setBright(true)
				but_queren:setTouchEnabled(true)		
			end)
		end
	elseif level == 2 then
		scroll = self._version
		self._check[1]:setSelectedState(true)
	elseif level == 3 then
		scroll = self._volume
		self._check[2]:setSelectedState(true)
	elseif level == 4 then
		scroll = self._unit
		self._check[3]:setSelectedState(true)
	elseif level == 5 then
		scroll = self._section
		self._check[4]:setSelectedState(true)
	end
	if scroll then
		local item = scroll:additem()
		if item then
			local text = uikits.child(item,'mingzi')
			if text and v and v.name then
				text:setString( v.name )
			end
			uikits.event(item,function(sender,b)
				self._selector[level] = v
				self:level_reset(level,sender)
				for i = level+2,5 do
					self:level_clear(i)
				end
				if level <= 4 then
					self:release_select_list( level + 1 )
				end
				local but_queren = uikits.child(self._release,ui.TOPICS_SELECT_QUEREN)
				but_queren:setEnabled(true)
				but_queren:setBright(true)
				but_queren:setTouchEnabled(true)
				
			end)
		end
	end
end

function TeacherList:level_reset( level,item )
	local list
	if level == 1 then
		list = self._cousor._list
	elseif level == 2 then
		list = self._version._list
	elseif level == 3 then
		list = self._volume._list
	elseif level == 4 then
		list = self._unit._list
	elseif level == 5 then
		list = self._section._list
	end
	if list then
		for k,v in pairs(list) do
			if v ~= item then
				v:setSelectedState(false)
			else
				v:setSelectedState(true)
			end
		end
	end
end

function TeacherList:level_relayout( level )
	if level == 1 then
		self._cousor:relayout()
	elseif level == 2 then
		self._version:relayout()
	elseif level == 3 then
		self._volume:relayout()
	elseif level == 4 then
		self._unit:relayout()
	elseif level == 5 then
		self._section:relayout()
	end
end

function TeacherList:level_clear( level )
	if level == 1 then
		self._cousor:clear()
		self._check[1]:setSelectedState(false)
	elseif level == 2 then
		self._version:clear()
		self._check[2]:setSelectedState(false)
	elseif level == 3 then
		self._volume:clear()
		self._check[3]:setSelectedState(false)
	elseif level == 4 then
		self._unit:clear()
		self._check[4]:setSelectedState(false)
	elseif level == 5 then
		self._section:clear()
	end
	self._selector[level] = nil
end

function TeacherList:release_select_list( level )
	level = level or 1
	self._selector = self._selector or {}
	local url = "http://api.lejiaolexue.com/resource/coursehandler.ashx?limit=1"
	for i = 1,level do
		if self._selector[i-1] and selevel[i-1] then
			url = url..'&'..selevel[i-1]..'='..self._selector[i-1].id
		end
	end
	url = url..'&item='..selevel[level]
	local loadbox = loadingbox.open(self)
	cache.request(url,function(b)
			if not loadbox:removeFromParent() then
				return
			end
			if b then
				local s = cache.get_data(url)
				if s and string.sub(s,1,1)=='(' then
					local js = string.sub(s,2,-2)
					local t = json.decode(js)
					if t then
						self:level_clear(level)
						local tt = {}
						for k,v in pairs(t) do
							tt[#t-k-1] = v
						end
						for k,v in pairs(tt) do
							if v and v.name then
								self:add_level_item(level,v)
							end
						end
						self:level_relayout(level)
					end
				end
			end
		end)
end

function TeacherList:set_homework_ui(index)
	local edit_homework_title = uikits.child(self._release,ui.TOPICS_SET_HOMEWORK_TITLE)
	local sel_homework_title = uikits.child(self._release,ui.TOPICS_SELECT)
	local sel_homework_view = uikits.child(self._release,ui.TOPICS_SELECT_UI)
	local edit_homework_view = uikits.child(self._release,ui.TOPICS_EDIT_HOMEWORK_VIEW)
	local add_homework_view = uikits.child(self._release,ui.TOPICS_SELECT_BUTTON)

	if index == 1 then
		sel_homework_title:setVisible(true)
		sel_homework_view:setVisible(true)
		edit_homework_title:setVisible(false)
		edit_homework_view:setVisible(false)
		add_homework_view:setVisible(false)
	elseif index == 2 then
		sel_homework_title:setVisible(false)
		sel_homework_view:setVisible(false)
		edit_homework_title:setVisible(true)
		edit_homework_view:setVisible(false)
		add_homework_view:setVisible(true)
	elseif index == 3 then
		sel_homework_title:setVisible(false)
		sel_homework_view:setVisible(false)
		edit_homework_title:setVisible(true)
		edit_homework_view:setVisible(true)
		add_homework_view:setVisible(true)				
	end
	local but_confirm = uikits.child(self._release,ui.TOPICS_SELECT_QUEREN)
	local but_edit = uikits.child(self._release,ui.TOPICS_SET_HOMEWORK_XIUGAI)

	uikits.event(but_confirm,
		function(sender,eventType)
		self:set_homework_view()
		self.temp_items = {}
		self.edit_type = 0
	end,"click")
	uikits.event(but_edit,
		function(sender,eventType)
		self:set_homework_ui(1)
	end,"click")
end

local space_title = 50

function TeacherList:set_homework_view( )
	self:set_homework_ui(2)
		
	local label_course = uikits.child(self._release,ui.TOPICS_SELECT_TITLE_COURSE)
	local label_bv = uikits.child(self._release,ui.TOPICS_SELECT_TITLE_BV)
	local label_vol = uikits.child(self._release,ui.TOPICS_SELECT_TITLE_VOL)
	local label_unit = uikits.child(self._release,ui.TOPICS_SELECT_TITLE_UNIT)
	local label_section = uikits.child(self._release,ui.TOPICS_SELECT_TITLE_SECTION)
	local set_title_view = uikits.child(self._release,ui.TOPICS_SET_HOMEWORK_TITLE)
	label_course:setVisible(false)
	label_bv:setVisible(false)
	label_vol:setVisible(false)
	label_unit:setVisible(false)
	label_section:setVisible(false)
	--local scrollview = uikits.child(set_title_view,10000)
	--if scrollview == nil then
		set_title_view:removeChildByTag(10000)
		scrollView = ccui.ScrollView:create()
		scrollView:setTouchEnabled(true)      
		scrollView:setPosition(cc.p(0,0))			
		scrollView:setDirection(ccui.ScrollViewDir.horizontal)	
		set_title_view:addChild(scrollView,1,10000)
	--end
	local pos_x_src = label_course:getPositionX()
	local size_title_view = set_title_view:getContentSize()
	local but_xiugai = uikits.child(self._release,ui.TOPICS_SET_HOMEWORK_XIUGAI)
	local size_xiugai = but_xiugai:getContentSize()
	size_title_view.width = size_title_view.width - size_xiugai.width*2 
	scrollView:setContentSize(size_title_view) 
	
	local label_course_scroll = label_course:clone()
	if self._selector[1] then
		label_course_scroll:setString(self._selector[1].name)
		label_course_scroll:setVisible(true)
		scrollView:addChild(label_course_scroll)
		local label_size = label_course_scroll:getContentSize()
		pos_x_src = pos_x_src+label_size.width+space_title
	else
		label_course_scroll:setString("")
	end
	
	local label_bv_scroll = label_course:clone()
	if self._selector[2] then
		label_bv_scroll:setString(self._selector[2].name)
		label_bv_scroll:setVisible(true)
		scrollView:addChild(label_bv_scroll)
		label_bv_scroll:setPositionX(pos_x_src)
		local label_size = label_bv_scroll:getContentSize()
		pos_x_src = pos_x_src+label_size.width+space_title
	else
		label_bv_scroll:setString("")
	end

	local label_vol_scroll = label_course:clone()
	if self._selector[3] then
		label_vol_scroll:setString(self._selector[3].name)
		label_vol_scroll:setVisible(true)
		scrollView:addChild(label_vol_scroll)
		label_vol_scroll:setPositionX(pos_x_src)
		local label_size = label_vol_scroll:getContentSize()
		pos_x_src = pos_x_src+label_size.width+space_title
	else
		label_vol_scroll:setString("")
	end
		
	local label_unit_scroll = label_course:clone()
	if self._selector[4] then
		label_unit_scroll:setString(self._selector[4].name)
		label_unit_scroll:setVisible(true)
		scrollView:addChild(label_unit_scroll)
		label_unit_scroll:setPositionX(pos_x_src)
		local label_size = label_unit_scroll:getContentSize()
		pos_x_src = pos_x_src+label_size.width+space_title
	else
		label_unit_scroll:setString("")
	end
	
	local label_section_scroll = label_course:clone()
	if self._selector[5] then
		label_section_scroll:setString(self._selector[5].name)
		label_section_scroll:setVisible(true)
		scrollView:addChild(label_section_scroll)
		label_section_scroll:setPositionX(pos_x_src)
		local label_size = label_section_scroll:getContentSize()
		pos_x_src = pos_x_src+label_size.width+space_title
	else
		label_section_scroll:setString("")
	end
	size_title_view.width = pos_x_src
	scrollView:setInnerContainerSize(size_title_view)
--[[	
	if self._selector[1] then
		local str_show = string.sub(self._selector[1].name,1,21)
		label_course:setString(str_show)
	else
		label_course:setString("")
	end
	if self._selector[2] then
		local str_show = string.sub(self._selector[2].name,1,21)
		label_bv:setString(str_show)
	else
		label_bv:setString("")
	end
	if self._selector[3] then
		local str_show = string.sub(self._selector[3].name,1,21)
		label_vol:setString(str_show)
	else
		label_vol:setString("")
	end
	if self._selector[4] then
		local str_show = string.sub(self._selector[4].name,1,21)
		label_unit:setString(str_show)
	else
		label_unit:setString("")
	end
	if self._selector[5] then
		local str_show = string.sub(self._selector[5].name,1,21)
		label_section:setString(str_show)
	else
		label_section:setString("")
	end--]]
	
	local set_button_by_les = uikits.child(self._release,ui.TOPICS_SET_BUTTON_BY_LES)
	local set_button_by_err = uikits.child(self._release,ui.TOPICS_SET_BUTTON_BY_ERR)
	local set_label_by_err = uikits.child(self._release,ui.TOPICS_SET_LABEL_BY_ERR)
	set_label_by_err:setVisible(false)
	set_button_by_err:setVisible(false)
	uikits.event(set_button_by_les,
		function(sender,eventType)
		self.edit_type = 1 --添加模式
		is_need_update = false
		uikits.pushScene(Sethwbyles.create(self))
	end,"click")
	uikits.event(set_button_by_err,
		function(sender,eventType)
		is_need_update = false
		self.edit_type = 1 --添加模式
		uikits.pushScene(Sethwbyerr.create(self))
	end,"click")
	
	local label_obj_num = uikits.child(self._release,ui.TOPICS_EDIT_OBJ_NUM)
	local but_obj_edit = uikits.child(self._release,ui.TOPICS_EDIT_OBJ_BUT)
	local item_obj_pic = uikits.child(self._release,ui.TOPICS_EDIT_OBJ_PIC)
	local publish_but = uikits.child(self._release,ui.TOPICS_EDIT_PUBLISH_BUT)

	item_obj_pic:setVisible(false)
	
	label_obj_num:setString(#self._confirm_item)
	uikits.event(but_obj_edit,
		function(sender,eventType)
		is_need_update = false
		self.edit_type = 2 --取消模式
		uikits.pushScene(Edithwbyobj.create(self))
	end,"click")
	
	uikits.event(publish_but,
		function(sender,eventType)
		is_need_update = false
		uikits.pushScene(Publishhw.create(self))
	end,"click")
end

function TeacherList:init()
	if self._issubjectiveedit then
		self._issubjectiveedit = nil
		local set_label_empty = uikits.child(self._release,ui.TOPICS_SET_LABEL_EMPTY)
		local edit_homework_view = uikits.child(self._release,ui.TOPICS_EDIT_HOMEWORK_VIEW)
		local num = uikits.child(self._release,ui.SUBJECTIVE_EDIT_NUMBER)
		edit_homework_view:setVisible(true)
		set_label_empty:setVisible(false)
		local n = 0
		if self._subjective_data then
			n = #self._subjective_data
		end
		num:setString( tostring(n) )
		return
	end
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	
	if is_need_update == true then
		if not self._root then
			self:init_gui()
		end
		self:init_ready_batch()
	else
		local set_label_empty = uikits.child(self._release,ui.TOPICS_SET_LABEL_EMPTY)
		local edit_homework_view = uikits.child(self._release,ui.TOPICS_EDIT_HOMEWORK_VIEW)
		if self.temp_items ~= {} then
			for i,obj in pairs(self.temp_items) do
				if obj.item_id_num ~= nil then
					if self.edit_type == 1 then
						self._confirm_item[obj.item_id_num] = obj
					elseif self.edit_type == 2 then
						self._confirm_item[obj.item_id_num] = nil
					end
				end
			end
			self.edit_type = 0
			self.temp_items = {}
		end
		local is_show_edit_view = false
		for i,obj in pairs(self._confirm_item) do
			if obj ~= nil then
				is_show_edit_view = true
				break
			end
		end
		if is_show_edit_view == false then
			edit_homework_view:setVisible(false)
			set_label_empty:setVisible(true)
		else
			set_label_empty:setVisible(false)
			edit_homework_view:setVisible(true)
			local edit_homework_view = uikits.child(self._release,ui.TOPICS_EDIT_HOMEWORK_KEGUAN)
			for i=1 , 3 do
				local cur_obj_pic = edit_homework_view:getChildByTag(10000+i)
				if cur_obj_pic ~= nil then
					edit_homework_view:removeChildByTag(10000+i)
				end
			end
			local label_obj_num = uikits.child(self._release,ui.TOPICS_EDIT_OBJ_NUM)
			local num = 0
			local num_show_pic = 1
			topics.set_scale(0.3)
			for i,obj in pairs(self._confirm_item) do
				num = num+1
				if num_show_pic < 4 and obj.item_type then
					self:add_homewrk_exp(num_show_pic,obj)
					num_show_pic = num_show_pic +1
				end
			end
			label_obj_num:setString(num)
		end
		is_need_update = true
	end
end

function TeacherList:add_homewrk_exp(index,item_data)
	local item_obj_pic_src = uikits.child(self._release,ui.TOPICS_EDIT_OBJ_PIC)
	local edit_homework_view = uikits.child(self._release,ui.TOPICS_EDIT_HOMEWORK_KEGUAN)
	local size_view = item_obj_pic_src:getContentSize()
	local view_space = item_obj_pic_src:getPositionX()
	local cur_obj_pic = item_obj_pic_src:clone()
	cur_obj_pic:setPositionX(view_space*index+size_view.width*(index-1))
	cur_obj_pic:setVisible(true)
	edit_homework_view:addChild(cur_obj_pic,1,10000+index)
	
	local scrollView = ccui.ScrollView:create()
    scrollView:setTouchEnabled(true)
    scrollView:setContentSize(size_view)        
    scrollView:setPosition(cc.p(0,0))
	
    cur_obj_pic:addChild(scrollView)
	local data = {}

	if item_data.item_type > 0 and item_data.item_type < 13 then
		if topics.types[item_data.item_type].conv(item_data,data) then
			data.eventInitComplate = function(layout,data)
				local arraychildren = scrollView:getChildren()
				for i=1,#arraychildren do 
					arraychildren[i]:setEnabled(false)
				end
			end
			cur_obj_pic:setEnabled(false)
			topics.types[item_data.item_type].init(scrollView,data)
		end		
	end	
	
end

function TeacherList:release()
	local default_scale = topics.get_default_scale()
	topics.set_scale(default_scale)
end

return TeacherList