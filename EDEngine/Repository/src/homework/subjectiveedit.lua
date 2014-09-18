local uikits = require "uikits"

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
		end
		self._index_item_add:setPosition( cc.p(x,y) )
	end
end

function SubjectiveEdit:set_current( i )
	if self._current ~= i then
		local current = self._list[self._current]
		for k,v in pairs(self._list_deletes) do
			v:removeFromParent()
		end
		self._list_deletes = {}
		--current:removeFromParent()
		table.insert(self._list_delete,self._list[self._current])
		table.insert(self._list_delete,self._list[i])
		
		self._list[self._current] = self._index_item:clone()
		uikits.child(self._list[self._current],'sz'):setString(tostring(self._current))
		self._list[i] = self._index_item_current:clone()
		uikits.child(self._list[self._current],'sz'):setString(tostring(i))
		self._current = i
	end
end

function SubjectiveEdit:index_add()
	local item = self._index_item_current:clone()
	table.insert(self._list,item)
	self:set_current( #self._list )
end

function SubjectiveEdit:init()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	--返回按钮
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
	uikits.event(self._index_item_add,function(sender)
			self:index_add()
		end)
	self._current = 0
	self._list = {}
	self._list_deletes = {}
	self:index_clear()
end

function SubjectiveEdit:release()
	
end

return SubjectiveEdit