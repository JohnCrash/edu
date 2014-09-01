local uikits = require "uikits"
local cache = require "cache"
local kits = require "kits"
local login = require "login"
local json = require "json-c"
local loadingbox = require "homework/loadingbox"
local TeacherBatch = require "homework/teacherbatch"
local topics = require "homework/topics"

local topics_course = topics.course_icon
local res_local = "homework/"

local ui = {
	FILE = 'homework/laoshizuoye/daiyue.json',
	FILE_3_4 = 'homework/laoshizuoye/daiyue43.json',
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
}

local exam_list_url="http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx"
local get_class_url = "http://new.www.lejiaolexue.com/exam/handler/examhandler.ashx"

local TeacherList = class("TeacherList")
TeacherList.__index = TeacherList

function TeacherList.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),TeacherList)
	
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
	
	self._scrollview:setVisible(true)
	return true
end
--历史
function TeacherList:init_ready_history()
	cache.request_cancel()
	
	self._scrollview:setVisible(true)
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
	return true
end
--设置
function TeacherList:init_ready_setting()
	cache.request_cancel()
	
	self._scrollview:setVisible(false)
	return true
end

function TeacherList:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
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

function TeacherList:init()
	if uikits.get_factor() == uikits.FACTOR_9_16 then
		uikits.initDR{width=1920,height=1080}
	else
		uikits.initDR{width=1440,height=1080}
	end
	
	if not self._root then
		self:init_gui()
	end
	self:init_ready_batch()
end

function TeacherList:release()
	
end

return TeacherList