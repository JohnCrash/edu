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

crash.open("teacher",1)

local ui = {
	FILE = 'homework/laoshizuoye/daiyue.json',
	FILE_3_4 = 'homework/laoshizuoye/daiyue43.json',
	MORE = 'homework/laoshizuoye/gengduo.json',
	MORE_3_4 = 'homework/laoshizuoye/gengduo43.json',	
	RELEASEPAGE = 'homework/laoshizuoye/buzhi.json',
	RELEASE_3_4 = 'homework/laoshizuoye/buzhi43.json',
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
	TOPICS_SELECT_VERSION = 'xuan/banben',
	TOPICS_SELECT_VOLUME = 'xuan/nianji',
	TOPICS_SELECT_UNIT = 'xuan/danyuan',
	TOPICS_SELECT_SECTION = 'xuan/kewen', 
	TOPICS_SET_HOMEWORK_TITLE = 'ys1',
	TOPICS_SELECT_HOMEWORK_TITLE = 'ys3',
	TOPICS_SELECT_QUEREN = 'ys3/queren',
	TOPICS_SET_BUTTON_BY_LES = 'xuanze/zz',
	TOPICS_SET_BUTTON_BY_ERR = 'xuanze/ct',
	TOPICS_SET_LABEL_EMPTY = 'xuanze/wen1',
	TOPICS_EDIT_HOMEWORK_VIEW = 'zuoye',
	TOPICS_EDIT_OBJ_NUM = 'zuoye/keguang/shul',
	TOPICS_EDIT_OBJ_BUT = 'zuoye/keguang/bianji',
	TOPICS_EDIT_OBJ_PIC = 'zuoye/keguang/ti1',
	TOPICS_EDIT_PUBLISH_BUT = 'zuoye/fabu',
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
			[ui.ITEM_TOPICS_NUM] = v.items,
			[ui.ITEM_CLOSE_TIME] = function(child,item)
				if v.finish_time and type(v.finish_time)=='string' then
					local end_time = kits.unix_date_by_string( v.finish_time )
					local dt = end_time - os.time()
					if dt > 0 then
						child:setString( kits.time_to_string(dt) )
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
	self:release_select_list()
	return true
end
--历史
function TeacherList:init_ready_history()
	cache.request_cancel()
	
	self._scrollview:setVisible(true)
	self._setting:setVisible(false)
	self._release:setVisible(false)
	self._scrollview:clear()
	if not self._scID and not self._busy then
		self._mode = ui.HISTORY
		self._busy = true
		self:init_batch_list(3)--完成批阅
	end
	return true
end
--统计
function TeacherList:init_ready_statistics()
	cache.request_cancel()
	
	self._scrollview:setVisible(false)
	self._setting:setVisible(false)
	self._release:setVisible(false)
	return true
end
--设置
function TeacherList:init_ready_setting()
	cache.request_cancel()
	
	self._scrollview:setVisible(false)
	self._setting:setVisible(true)
	self._release:setVisible(false)
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
	
	--发布页
	self._release = uikits.fromJson{file_9_16=ui.RELEASEPAGE,file_3_4=ui.RELEASE_3_4}
	self._root:addChild(self._release)
	
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
function TeacherList:release_select_list( level )
--[[	level = level or 1
	self._selector = self._selector or {}
	local url = "http://api.lejiaolexue.com/resource/coursehandler.ashx?limit=1"
	for i = 1,level do
		if self._selector[i-1] and selevel[i-1] then
			url = url..'&'..selevel[i-1]..'='..self._selector[i-1].id
		end
	end
	url = '&item='..selevel[level]
	local loadbox = loadingbox.open(self)
	cache.request(url,function(b)
			loadbox:removeFromParent()
			if b then
				local s = cache.get_data(url)
				if s and string.sub(s,1,1)=='(' then
					local js = string.sub(s,2,-2)
					local t = json.decode(js)
					if t then
						local course = uikits.child(self._release,ui.uilevel[level])
						course:removeAllItems()
						for k,v in pairs(t) do
							if v and v.name then
								local item = uikits.text{caption=v.name,color=cc.c3b(0,0,0),fontSize=48}
								item._data = v
								course:addChild( item )
							end
						end
					end
				end
			end
		end)--]]
	self._confirm_item = {}	
	local button = uikits.child(self._release,ui.TOPICS_SELECT_QUEREN)
	uikits.event(button,
		function(sender,eventType)
		self:set_homework_view()
		self.temp_items = {}
		self.edit_type = 0
	end,"click")
end

function TeacherList:set_homework_view( )
	local set_title = uikits.child(self._release,ui.TOPICS_SET_HOMEWORK_TITLE)
	local set_button_view = uikits.child(self._release,ui.TOPICS_SELECT_BUTTON)
	set_title:setVisible(true)	
	set_button_view:setVisible(true)	
	local select_title = uikits.child(self._release,ui.TOPICS_SELECT_HOMEWORK_TITLE)
	local select_view = uikits.child(self._release,ui.TOPICS_SELECT_UI)
	select_title:setVisible(false)	
	select_view:setVisible(false)	
	local set_button_by_les = uikits.child(self._release,ui.TOPICS_SET_BUTTON_BY_LES)
	local set_button_by_err = uikits.child(self._release,ui.TOPICS_SET_BUTTON_BY_ERR)
	uikits.event(set_button_by_les,
		function(sender,eventType)
		is_need_update = false
		uikits.pushScene(Sethwbyles.create())
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
	
--[[	if self._confirm_item ~= {} then
		item_obj_pic
	end --]]
	
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
				if self.edit_type == 1 then
					self._confirm_item[obj.item_id_num] = obj
				elseif self.edit_type == 2 then
					self._confirm_item[obj.item_id_num] = nil
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
			local label_obj_num = uikits.child(self._release,ui.TOPICS_EDIT_OBJ_NUM)
			local num = 0
			for i,obj in pairs(self._confirm_item) do
				num = num +1
			end
			label_obj_num:setString(num)
		end
		is_need_update = true
	end
end

function TeacherList:release()
	
end

return TeacherList