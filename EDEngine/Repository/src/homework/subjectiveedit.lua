local kits = require "kits"
local uikits = require "uikits"
local cache = require "cache"
local loadingbox = require "loadingbox"
local messagebox_ = require "messagebox"
local RecordVoice = require "recordvoice"

local FileUtils = cc.FileUtils:getInstance()
local ui = {
	FILE = 'homework/laoshizuoye/gexinghua.json',
	FILE_3_4 = 'homework/laoshizuoye/gexinghua43.json',
	BACK = 'ding/back',
	OK = 'ding/qr',
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
	AUDIO_ITEM = 'leirong/chat',
	IMG_ITEM = 'leirong/pic',
}
local INDEX_SPACE = 8
local SubjectiveEdit = class("SubjectiveEdit")
SubjectiveEdit.__index = SubjectiveEdit

local function stopSound()
	uikits.delay_call( nil,uikits.stopAllSound,1.5 )
end

function SubjectiveEdit.create( arg )
	local scene = cc.Scene:create()
	local layer = uikits.extend(cc.Layer:create(),SubjectiveEdit)
	
	scene:addChild(layer)
	
	local function onNodeEvent(event)
		if "enter" == event then
			layer._data = arg
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
		stopSound()
		self._input_text:setText(self._data[self._current].text)
		for i,v in pairs(self._items) do
			v:removeFromParent()
		end
		self._items = {}
		if self._data[self._current].items then
			for i,v in pairs(self._data[self._current].items) do
				if v.type==1 then
					self:addsound(v.file)
				elseif v.type==2 then
					self:addphoto(v.file)
				end
			end
		end
		self:scroll_relayout()
		self._scroll:scrollToTop(0.5,true)
	end
end

function SubjectiveEdit:index_add( b )
	local item = self._index_item_current:clone()
	item:setVisible(true)
	self._indexs:addChild(item)
	table.insert(self._list,item)
	if not b then
		table.insert(self._data,{})
	end
	self:set_current( #self._list )
	self._delete_button:setVisible(true)
	self._tops:setVisible(true)
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
		else
			self._input_text:setText('')
			for i,v in pairs(self._items) do
				v:removeFromParent()
			end
			self._items = {}
			self._delete_button:setVisible(false)
			self._tops:setVisible(false)
		end
		self:index_relayout()
	end
end

function SubjectiveEdit:addsound( name,length )
	local item = self._audio_item:clone()
	if item then
		item:setVisible(true)
		uikits.event(item,function(sender)
			uikits.playSound(name)
		end,"click")
		local delbut = uikits.child(item,'sc1')
		if delbut then
			uikits.event( delbut,function(sender)
				item:setVisible(false)
				self:delsound_todata( name )
				self:scroll_relayout()
			end,"click" )
		else
			kits.log("ERROR : SubjectiveEdit:addsound delete button no found")
		end
		local timetxt = uikits.child(item,'shijian')
		if timetxt then
			if not length then
				length = cc_getVoiceLength(name)
			end
			if length then
				timetxt:setString( kits.time_to_string_simple(math.floor(length)))
			else
				timetxt:setString("-" )
			end
			--timetxt:setVisible(false)
		else
			kits.log("ERROR : SubjectiveEdit:addsound time label no found")
		end
		table.insert( self._items,item)
		self._scroll:addChild(item)
	end
end

function SubjectiveEdit:addsound_todata( name,length )
	if name and self._current and self._data[self._current] then
		self._data[self._current].items = self._data[self._current].items or {}
		table.insert(self._data[self._current].items,{file=name,type=1})
	end	
end

function SubjectiveEdit:delsound_todata( name )
	if name and self._current and self._data[self._current] and self._data[self._current].items then
		for k,v in pairs(self._data[self._current].items) do
			if v.file == name and v.type==1 then
				table.remove(self._data[self._current].items,k)
				return
			end
		end
	end
end

function SubjectiveEdit:addphoto( name )
	local item = self._img_item:clone()
	if item then
		item:setVisible(true)
		if FileUtils:isFileExist(name) then
			item:loadTexture(name)
		else
			kits.log("ERROR : SubjectiveEdit:addphoto "..tostring(name).." is not exist")
		end
		local delbut = uikits.child(item,'sc2')
		if delbut then
			local s = item:getContentSize()
			local bs = delbut:getContentSize()
			if s.width > 1280 then
				local v = 1280/s.width
				item:setScaleX(v)
				item:setScaleY(v)
			end
			delbut:setPosition(cc.p(s.width+16+bs.width/2,s.height/2))
			uikits.event( delbut,function(sender)
				item:setVisible(false)
				self:delphoto_todata( name )
				self:scroll_relayout()
			end,"click" )
		else
			kits.log("ERROR : SubjectiveEdit:addphoto delete button no found")
		end
		table.insert( self._items,item)
		self._scroll:addChild(item)
	end
end

function SubjectiveEdit:addphote_todata( name )
	if name and self._current and self._data[self._current] then
		self._data[self._current].items = self._data[self._current].items or {}
		table.insert(self._data[self._current].items,{file=name,type=2})
	end	
end

function SubjectiveEdit:delphoto_todata( name )
	if name and self._current and self._data[self._current] and self._data[self._current].items then
		for k,v in pairs(self._data[self._current].items) do
			if v.file == name and v.type==2 then
				table.remove(self._data[self._current].items,k)
				return
			end
		end
	end
end

function SubjectiveEdit:scroll_relayout()
	--计算高度
	local uis = {}
	local ts = self._tops:getContentSize()
	local cs = self._scroll:getContentSize()
	local ds = self._delete_button:getContentSize()
	local x,y = self._delete_button:getPosition()
	y = self._space
	self._delete_button:setPosition(cc.p(x,y))
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
	table.insert(uis,self._delete_button)
	if y < cs.height then
		uikits.move( uis,0,cs.height-y)
	end
end

function SubjectiveEdit:init()
	self._root = uikits.fromJson{file_9_16=ui.FILE,file_3_4=ui.FILE_3_4}
	self:addChild(self._root)
	local back = uikits.child(self._root,ui.BACK)
	uikits.event(back,function(sender)
		self:savepage()
		cache.request_cancel()
		uikits.popScene()end)
	local ok = uikits.child(self._root,ui.OK)
	uikits.event(ok,function(sender)
		self:savepage()
		cache.request_cancel()
		uikits.popScene()		
	end)
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
	self._audio_item = uikits.child(self._root,ui.AUDIO_ITEM)
	self._img_item = uikits.child(self._root,ui.IMG_ITEM)
	self._audio_item:setVisible(false)
	self._img_item:setVisible(false)
	self._scroll_list = {}
	self._items = {}
	self._remove_items = {}
	self._tops = uikits.child(self._root,ui.INPUT_AREANA)
	local cs = self._scroll:getContentSize()
	local ts = self._tops:getContentSize()
	local tx,ty = self._tops:getPosition()
	self._space = cs.height-ty-ts.height
	self._input_text = uikits.child(self._tops,ui.INPUT_TEXT)
	local x,y = self._tops:getPosition()
	self._tops_space = y-self._tops:getContentSize().height
	self._tops_ox = x
	uikits.event(self._index_item_add,function(sender)
			stopSound()
			self:index_add()
		end)
	self._delete_button = uikits.child(self._root,ui.DELETE_BUTTON)
	uikits.event(self._delete_button,function()
		stopSound()
		self:index_delete(self._current)
	end)
	self._delete_button:setVisible(false)
	self._tops:setVisible(false)		
	self._current = 0
	self._list = {}
	self._list_deletes = {}
	self:index_clear()
	self:scroll_relayout()
	self:init_event()
	if #self._data == 0 then
		self:index_add()
	else
		for i=1,#self._data do
			self:index_add(true)
		end
		self:initpage()
	end
end

local function messagebox(parent,title,text )
	messagebox_.open(parent,function()end,messagebox_.MESSAGE,tostring(title),tostring(text) )
end

function SubjectiveEdit:init_event()
	if self._record_button then --插入录音
	uikits.event( self._record_button,function(sender)
			stopSound()
			if not self._recording then
				self._recording = true
				RecordVoice.open(
						self,
						function(b,file)
							self._recording = nil
							if b then
								local tlen = cc_getVoiceLength(file)
								self:addsound( file,tlen )
								self:addsound_todata( file,tlen )
								self:scroll_relayout()	
							end
						end
					)
			end
		end)
	end
	if self._cam_button then --插入照片
		uikits.event(self._cam_button,function(sender)
			stopSound()
			cc_takeResource(TAKE_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						--file = res
						local b,res = cc_adjustPhoto(res,1024)
						if b then
							self:addphoto( res )
							self:addphote_todata( res )
							self:scroll_relayout()
						else
							messagebox(self,"错误","图像调整失败")
						end
					end
				end)			
		end)	
	end
	if self._photo_button then --从图库插入照片
		uikits.event(self._photo_button,function(sender)
			stopSound()
			cc_takeResource(PICK_PICTURE,function(t,result,res)
					kits.log('type ='..tostring(t)..' result='..tostring(result)..' res='..tostring(res))
					if result == RESULT_OK then
						local b,res = cc_adjustPhoto(res,1024)
						if b then
							self:addphoto( res )
							self:addphote_todata( res )
							self:scroll_relayout()
						else
							messagebox(self,"错误","图像调整失败")
						end
					end					
				end)			
		end)	
	end	
end

function SubjectiveEdit:release()
	stopSound()
	for i,v in pairs(self._items) do
		v:removeFromParent()
	end
	self._items = {}
end

return SubjectiveEdit