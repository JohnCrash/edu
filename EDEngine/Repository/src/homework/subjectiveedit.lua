local uikits = require "uikits"
local cache = require "cache"
local ui = {
	FILE = 'homework/laoshizuoye/gexinghua.json',
	FILE_3_4 = 'homework/laoshizuoye/gexinghua43.json',
	BACK = 'ding/back',
	LIST = 'leirong',
	TEXT = 'leirong/ys/wenzi',
	INDEX_LIST = 'sl',
	INDEX_ITEM = 'ti1',
	INDEX_ITEM_CURRENT = 'ti2',
	INDEX_ADD_BUTTON = 'tianjia',
	RECORD_BUTTON = 'leirong/ys/luyin',
	CAM_BUTTON = 'leirong/ys/paizhao',
	PHOTO_BUTTON = 'leirong/ys/tupian',
	SOUND_BUTTON = 'leirong/chat',
	SOUND_DELTE_TEXT = 'shijian',
	SOUND_DELTE_BUTTON = 'sc1',
	DELETE_BUTTON = 'leirong/shancu',
	INPUT_AREANA = 'leirong/ys',
	INPUT_TEXT = 'wenzi',
}
local INDEX_SPACE = 8
local SubjectiveEdit = class("SubjectiveEdit")
SubjectiveEdit.__index = SubjectiveEdit

function SubjectiveEdit.create()
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),SubjectiveEdit)
	
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

function SubjectiveEdit:index_clear()
	if self._list then
		for i,v in pairs(self._list) do
			v:removeFromParent()
		end
		self._list = {}
	end
	self:index_relayout()
end

function SubjectiveEdit:index_relayout()
	if self._list then
		local x,y = self._index_item_ox,self._index_item_oy
		for i,v in pairs(self._list) do
			v:setPosition(cc.p(x,y))
			local size = v:getContentSize()
			x = x + size.width + INDEX_SPACE
			uikits.child(v,'sz'):setString(tostring(i))
			uikits.event(v,function()
					self:set_current(i)
				end)			
		end
		self._index_item_add:setPosition( cc.p(x,y) )
	end
end

function SubjectiveEdit:set_current( i )
	if self._current ~= i then
		local current = self._list[self._current]
		self:savepage()
		for k,v in pairs(self._list_deletes) do
			v:removeFromParent()
		end
		self._list_deletes = {}
		if self._current and self._list[self._current] then
			table.insert(self._list_deletes,self._list[self._current])
			self._list[self._current]:setVisible(false)
		end
		if i and self._list[i] then
			table.insert(self._list_deletes,self._list[i])
			self._list[i]:setVisible(false)
		end
		if self._current and self._current ~= 0 then
			self._list[self._current] = self._index_item:clone()
			self._list[self._current]:setVisible(true)
			self._indexs:addChild(self._list[self._current])
			local cur = self._current
		end
		self._list[i] = self._index_item_current:clone()
		self._list[i]:setVisible(true)
		self._indexs:addChild(self._list[i])
		self._current = i
		self:initpage()
	end
	self:index_relayout()
end

function SubjectiveEdit:savepage()
	if self._current and self._data[self._current] then
		self._data[self._current].text = self._input_text:getStringValue()
	end
end

function SubjectiveEdit:initpage()
	if self._current and self._data[self._current] then
		self._input_text:setText(self._data[self._current].text)
	end
end

function SubjectiveEdit:index_add()
	local item = self._index_item_current:clone()
	item:setVisible(true)
	self._indexs:addChild(item)
	table.insert(self._list,item)
	table.insert(self._data,{})
	self:set_current( #self._list )
end

function SubjectiveEdit:index_delete(i)
	if i and self._list[i] then
		table.insert(self._list_deletes,self._list[i])
		self._list[i]:setVisible(false)
		table.remove(self._list,i)
		table.remove(self._data,i)
		self._current = 0
		if self._list[i] then
			self:set_current(i)
		elseif self._list[i-1] then
			self:set_current(i-1)
		end
		self:index_relayout()
	end
end

function SubjectiveEdit:addsound( name )
	if name and self._current and self._data[self._current] then
		self._data[self._current].imags = self._data[self._current].imags or {}
		table.insert(self._data[self._current].imags,name)
	end
end

function SubjectiveEdit:addphoto( name )
	if name and self._current and self._data[self._current] then
		self._data[self._current].imags = self._data[self._current].imags or {}
		for i,v in pairs(self._data[self._current].imags) do
			if v then
				
			end
		end
		table.insert(self._data[self._current].imags,name)
	end
end

function SubjectiveEdit:scroll_relayout()
	local width,height
	width = self._scroll:getContentSize().width
	height = 2*self._tops_space + self._tops:getContentSize().height +
		self._tops_space + self._delete_button:getContentSize().height
	self._scroll:setInnerContainerSize(cc.size(width,height))
	self._tops:setPosition(cc.p(self._tops_ox,
		height-self._tops_space-self._tops:getContentSize().height))
end

function SubjectiveEdit:init()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)
		cache.request_cancel()
		uikits.popScene()end)
	self._indexs = uikits.child(self._root,ui.INDEX_LIST)
	self._index_item = uikits.child(self._indexs,ui.INDEX_ITEM)
	self._index_item_current = uikits.child(self._indexs,ui.INDEX_ITEM_CURRENT)
	self._index_item_add = uikits.child(self._indexs,ui.INDEX_ADD_BUTTON)
	self._index_item:setVisible(false)
	self._index_item_current:setVisible(false)
	self._index_item_ox,self._index_item_oy = self._index_item_current:getPosition()
	self._record_button = uikits.child(self._root,ui.RECORD_BUTTON)
	self._cam_button = uikits.child(self._root,ui.CAM_BUTTON)
	self._photo_button = uikits.child(self._root,ui.PHOTO_BUTTON)
	self._scroll = uikits.child(self._root,ui.LIST)
	self._scroll_list = {}
	self._data = {}
	self._tops = uikits.child(self._root,ui.INPUT_AREANA)
	self._input_text = uikits.child(self._tops,ui.INPUT_TEXT)
	local x,y = self._tops:getPosition()
	self._tops_space = y-self._tops:getContentSize().height
	self._tops_ox = x
	uikits.event(self._index_item_add,function(sender)
			self:index_add()
		end)
	self._delete_button = uikits.child(self._root,ui.DELETE_BUTTON)
	uikits.event(self._delete_button,function()
		self:index_delete(self._current)
	end)
	self._current = 0
	self._list = {}
	self._list_deletes = {}
	self:index_clear()
	self:scroll_relayout()
	self:init_event()
end

function SubjectiveEdit:init_event()
	if self._record_button then --插入录音
		uikits.event(self._record_button,function(sender)
			
		end)
	end
	if self._cam_button then --插入照片
		uikits.event(self._cam_button,function(sender)
			
		end)	
	end
	if self._photo_button then --从图库插入照片
		uikits.event(self._photo_button,function(sender)
			
		end)	
	end	
end

function SubjectiveEdit:release()
	
end

return SubjectiveEdit