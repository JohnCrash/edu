local uikits = require "uikits"
local cache = require "cache"
local login = require 'login'
local kits = require "kits"
local json = require "json-c"
local loadingbox = require "homework/loadingbox"

local ui = {
	FILE = 'laoshizuoye/daiyue.json',
	FILE_3_4 = 'laoshizuoye/daiyue43.json',
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

function TeacherList:SwapButton(s)
	self._scrollview:setVisible(false)
	if s == ui.READYBATCH then
		self._scrollview:setVisible(true)
		self._redline:setPosition(cc.p(self._ready_batch_x,self._redline_y))
	elseif s == ui.RELEASE then
		self._redline:setPosition(cc.p(self._release_x,self._redline_y))
	elseif s == ui.HISTORY then
		self._redline:setPosition(cc.p(self._history_x,self._redline_y))
	elseif s == ui.STATIST then
		self._redline:setPosition(cc.p(self._statist_x,self._redline_y))
	elseif s == ui.SETTING then
		self._redline:setPosition(cc.p(self._setting_x,self._redline_y))		
	end
end

function TeacherList:add_batch_item( v )
	self._scrollview:additem{
		[ui.ITEM_CAPTION] = v.exam_name,
		[ui.ITEM_TOPICS_NUM] = v.items
	}
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
--待阅
function TeacherList:init_ready_batch()
	self:SwapButton(ui.READYBATCH)
	
	if not self._scID and not self._busy then
		self._mode = ui.READYBATCH
		self._scrollview:clear()
		local loadbox = loadingbox.open(self)
		local total_page = 1
		function down_page( page )
			local url = exam_list_url..'?'..'action=search'..
				'&exam-type=0'.. --全部
				'&exam-status=2'.. --待批阅
				'&exam-tag=0'..
				'&in-time=0'..
				'&sort=0'..
				'&page='..page
			cache.download(url,login.cookie(),
				function(b)
					if b then
						local data = cache.get_data(url)
						if data then
							local t = json.decode( data )
							if t.total_page then total_page = t.total_page end
							local retb = self:add_ready_batch_from_table(t)
							if page<total_page and retb then
								down_page( page+1 )
							else
								loadbox:removeFromParent()
							end
						else
							kits.log('ERROR TeacherList:init_ready_batch data=nil')
						end
					else
						loadbox:removeFromParent()
						kits.log('Connect faild : '..url )
					end				
				end)
		end
		down_page(1)
	end	
end
--布置
function TeacherList:init_ready_release()
	self:SwapButton(ui.RELEASE)
end
--历史
function TeacherList:init_ready_history()
	self:SwapButton(ui.HISTORY)
end
--统计
function TeacherList:init_ready_statistics()
	self:SwapButton(ui.STATIST)
end
--设置
function TeacherList:init_ready_setting()
	self:SwapButton(ui.SETTING)
end

function TeacherList:init_gui()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	--返回按钮
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)uikits.popScene()end)
	--列表视图
	self._scrollview = uikits.scroll(self._root,ui.LIST,ui.ITEM)
	--切换标签
	self._redline = uikits.child(self._root,ui.BUTTON_LINE)
	self._ready_batch_button = uikits.child(self._root,ui.TAB_BUTTON_1)
	self._release_button = uikits.child(self._root,ui.TAB_BUTTON_2)
	self._history_button = uikits.child(self._root,ui.TAB_BUTTON_3)
	self._statist_button = uikits.child(self._root,ui.TAB_BUTTON_4)
	self._setting_button = uikits.child(self._root,ui.TAB_BUTTON_5)
	self._ready_batch_x,self._redline_y = self._redline:getPosition()
	self._release_x = self._ready_batch_x + self._release_button:getContentSize().width
	self._history_x = self._release_x + self._release_button:getContentSize().width
	self._statist_x = self._history_x + self._release_button:getContentSize().width
	self._setting_x = self._statist_x + self._release_button:getContentSize().width
	uikits.event(self._ready_batch_button,function(sender)self:init_ready_batch()end)
	uikits.event(self._release_button,function(sender)self:init_ready_release()end)
	uikits.event(self._history_button,function(sender)self:init_ready_history()end)
	uikits.event(self._statist_button,function(sender)self:init_ready_statistics()end)
	uikits.event(self._setting_button,function(sender)self:init_ready_setting() end)
end

function TeacherList:init()
	login.set_selector(1) --现在鲍老师
	if not self._root then
		self:init_gui()
	end
	self:init_ready_batch()
end

function TeacherList:release()
	
end

return TeacherList